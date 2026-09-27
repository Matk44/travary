import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/attachment_backup.dart';
import '../data/attachment_store.dart';
import '../data/demo_data.dart';
import '../data/memory_travel_repository.dart';
import '../data/sharing_service.dart';
import '../data/travel_repository.dart';
import '../design/art/art_catalog.dart';
import '../design/art/art_resolver.dart';
import '../domain/domain.dart';
import '../logic/day_plan.dart';
import '../logic/trip_assignment.dart';
import '../logic/trip_plan.dart';

/// The result of saving a booking, for the "Added to Orlando" message.
class SaveResult {
  const SaveResult(this.booking, this.tripTitle, {required this.newTrip});

  final Booking booking;
  final String tripTitle;
  final bool newTrip;
}

/// App state: every trip and booking, kept live from the repository, plus
/// the derived plans the screens show. All business rules live here or in
/// `lib/logic/`; screens only read and call methods.
class TravelStore extends ChangeNotifier {
  TravelStore({
    required this.repository,
    required ArtCatalog artCatalog,
    this.attachments,
    this.backup,
    this.sharing,
    DateTime Function()? clock,
  }) : art = ArtResolver(artCatalog),
       _clock = clock ?? DateTime.now {
    _subscriptions.addAll([
      repository.watchTrips().listen((trips) {
        _trips = trips;
        _tripsLoaded = true;
        _rebuild();
      }, onError: (Object error) {
        // Show whatever we have rather than a spinner forever.
        _tripsLoaded = true;
        _reportError(error);
      }),
      repository.watchBookings().listen((bookings) {
        _bookings = bookings;
        _bookingsLoaded = true;
        _rebuild();
      }, onError: (Object error) {
        _bookingsLoaded = true;
        _reportError(error);
      }),
      repository.errors.listen(_reportError),
    ]);
    // Keeps "happening now" / "next up" current while the app is open.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => notifyListeners());
  }

  final TravelRepository repository;
  final AttachmentStore? attachments;

  /// Cloud copies of ticket files (cloud mode only).
  final AttachmentBackup? backup;

  /// Family sharing (cloud mode only).
  final SharingService? sharing;
  final ArtResolver art;

  /// Which trips get their tickets backed up. The app sets this from
  /// Travary Plus; shared trips always do, so everyone has the tickets.
  bool Function(TripPlan plan) shouldBackUp = (plan) => plan.trip.isShared;
  final DateTime Function() _clock;

  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _ticker;
  Timer? _syncTimer;
  final _syncing = <String>{};
  List<Trip> _trips = const [];
  List<Booking> _bookings = const [];
  List<TripPlan> _plans = const [];
  bool _tripsLoaded = false;
  bool _bookingsLoaded = false;
  DateTime? _previewNow;
  String? _error;

  // ---------------------------------------------------------------- reading

  bool get isLoading => !(_tripsLoaded && _bookingsLoaded);
  bool get isDemo => repository is MemoryTravelRepository;
  String get userId => repository.userId;
  bool get sharingAvailable => sharing != null;

  bool isOwner(TripPlan plan) => plan.trip.ownerId == userId;

  /// "You", the member's name, or "Traveller".
  String memberName(TripPlan plan, String memberId) =>
      memberId == userId ? 'You' : (plan.trip.memberNames[memberId] ?? 'Traveller');

  /// The current time, or the preview time set from Profile (debug builds).
  DateTime get now => _previewNow ?? _clock();
  LocalDate get today => LocalDate.fromDateTime(now);
  DateTime? get previewNow => _previewNow;

  String? get error => _error;

  List<TripPlan> get plans => _plans;
  List<Booking> get bookings => _bookings;
  bool get hasAnything => _trips.isNotEmpty || _bookings.isNotEmpty;

  TodayFocus get focus => focusFor(_plans, today);

  TripPlan? plan(String tripId) {
    for (final plan in _plans) {
      if (plan.id == tripId) return plan;
    }
    return null;
  }

  Booking? booking(String id) {
    for (final booking in _bookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  TripTheme themeOf(Booking booking) =>
      plan(booking.tripId)?.trip.theme ?? TripTheme.classic;

  DayPlan dayPlan(LocalDate date) => buildDayPlan(date, _bookings, now);

  ArtChoice artFor(Booking booking) => art.resolve(booking, themeOf(booking));

  List<ArtChoice> artForAll(List<Booking> bookings) =>
      art.resolveAll(bookings, themeOf);

  /// Bookings matching [query] (title, place, reference, notes, trip name,
  /// details), optionally of one [kind]. Unsorted.
  List<Booking> search(String query, {BookingKind? kind}) {
    final needle = query.trim().toLowerCase();
    return _bookings.where((booking) {
      if (kind != null && booking.kind != kind) return false;
      if (needle.isEmpty) return true;
      final haystack = [
        booking.title,
        booking.location,
        booking.reference,
        booking.notes,
        plan(booking.tripId)?.trip.title,
        ...booking.details.values,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(needle);
    }).toList();
  }

  // ---------------------------------------------------------------- writing

  /// Saves [booking]. If it has no trip yet, it joins the trip it overlaps
  /// or a new trip is created for it. Pass [previous] when editing.
  Future<SaveResult> saveBooking(Booking booking, {Booking? previous}) async {
    var saved = booking.copyWith(updatedAt: DateTime.now());
    var newTrip = false;
    String tripTitle;

    if (saved.tripId.isEmpty) {
      final match = findTripFor(saved.startDate, saved.lastDate, _plans) ??
          findReturnFlightTrip(saved, _plans);
      if (match != null) {
        saved = saved.copyWith(tripId: match.id);
        tripTitle = match.trip.title;
      } else {
        final trip = await createTrip(suggestTripTitle(saved));
        saved = saved.copyWith(tripId: trip.id);
        tripTitle = trip.title;
        newTrip = true;
      }
    } else {
      tripTitle = plan(saved.tripId)?.trip.title ?? 'your trip';
    }

    if (previous != null && previous.tripId != saved.tripId) {
      await repository.moveBooking(saved, previous.tripId);
      await _dropTripIfEmptied(previous.tripId, removing: saved.id);
    } else {
      await repository.saveBooking(saved);
    }

    if (previous != null) {
      final kept = {for (final a in saved.attachments) a.id};
      for (final removed in previous.attachments.where((a) => !kept.contains(a.id))) {
        await _deleteFiles(removed);
      }
    }
    unawaited(_backUp(saved.id));
    return SaveResult(saved, tripTitle, newTrip: newTrip);
  }

  /// Saves several new bookings at once (everything Smart Import found in
  /// one file). Bookings from one file land in the same trip when they're
  /// within a few weeks, including a trip created earlier in this batch.
  Future<List<SaveResult>> saveBookings(List<Booking> bookings) async {
    final ordered = [...bookings]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final createdHere = <_NewTrip>[];
    final results = <SaveResult>[];
    for (var booking in ordered) {
      if (booking.tripId.isEmpty &&
          findTripFor(booking.startDate, booking.lastDate, _plans) == null &&
          findReturnFlightTrip(booking, _plans) == null) {
        for (final trip in createdHere) {
          if (gapBetween(booking.startDate, booking.lastDate, trip.start, trip.end) <= sameSourceMarginDays) {
            booking = booking.copyWith(tripId: trip.id);
            break;
          }
        }
      }
      final result = await saveBooking(booking);
      final saved = result.booking;
      final known = createdHere.where((t) => t.id == saved.tripId).firstOrNull;
      if (result.newTrip) {
        createdHere.add(_NewTrip(saved.tripId, result.tripTitle, saved.startDate, saved.lastDate));
        results.add(result);
      } else if (known != null) {
        known.stretch(saved.startDate, saved.lastDate);
        // The new trip may not have come back from the cloud yet, so use
        // the title it was created with.
        results.add(SaveResult(saved, known.title, newTrip: false));
      } else {
        results.add(result);
      }
    }
    return results;
  }

  Future<void> deleteBooking(Booking booking) async {
    await repository.deleteBooking(booking);
    await _dropTripIfEmptied(booking.tripId, removing: booking.id);
    for (final attachment in booking.attachments) {
      await _deleteFiles(attachment);
    }
  }

  Future<Trip> createTrip(
    String title, {
    TripTheme theme = TripTheme.classic,
    LocalDate? start,
    LocalDate? end,
  }) async {
    final stamp = DateTime.now();
    final trip = Trip(
      id: repository.newId(),
      title: title,
      theme: theme,
      plannedStart: start,
      plannedEnd: end,
      ownerId: repository.userId,
      memberIds: [repository.userId],
      createdAt: stamp,
      updatedAt: stamp,
    );
    await repository.createTrip(trip);
    return trip;
  }

  Future<void> updateTrip(Trip trip) =>
      repository.updateTrip(trip.copyWith(updatedAt: DateTime.now()));

  Future<void> deleteTrip(TripPlan plan) async {
    await repository.deleteTrip(plan.trip, plan.bookings);
    for (final booking in plan.bookings) {
      for (final attachment in booking.attachments) {
        await _deleteFiles(attachment);
      }
    }
  }

  // --------------------------------------------------------------- tickets

  /// The ticket file on this phone, downloading the family's cloud copy
  /// first if it isn't here yet. Null if there's no copy anywhere.
  Future<File?> ticketFile(Attachment attachment) async {
    final store = attachments;
    if (store == null) return null;
    final file = store.fileFor(attachment);
    if (await file.exists()) return file;
    final backup = this.backup;
    if (backup == null || attachment.remotePath == null) return null;
    try {
      await backup.download(attachment, file);
      return file;
    } catch (error) {
      if (kDebugMode) debugPrint('Ticket download failed: $error');
      return null;
    }
  }

  /// Backs up tickets that should be and fetches the family's tickets for
  /// current and coming trips, so they open offline. Safe to call often.
  Future<void> syncTickets() async {
    for (final booking in [..._bookings]) {
      await _backUp(booking.id);
    }
    final today = this.today;
    for (final plan in _plans.where((p) => p.phaseOn(today) != TripPhase.past)) {
      for (final booking in plan.bookings) {
        for (final attachment in booking.attachments.where((a) => a.remotePath != null)) {
          await ticketFile(attachment);
        }
      }
    }
  }

  /// Uploads [bookingId]'s tickets that aren't backed up yet, if its trip
  /// should be. Failures are left for the next sync.
  Future<void> _backUp(String bookingId) async {
    final backup = this.backup;
    final store = attachments;
    final booking = this.booking(bookingId);
    if (backup == null || store == null || booking == null) return;
    final plan = this.plan(booking.tripId);
    if (plan == null || !shouldBackUp(plan)) return;
    final pending = booking.attachments.where((a) => a.remotePath == null).toList();
    if (pending.isEmpty || !_syncing.add(bookingId)) return;
    try {
      final uploaded = <String, String>{};
      for (final attachment in pending) {
        final file = store.fileFor(attachment);
        if (!await file.exists()) continue;
        try {
          uploaded[attachment.id] = await backup.upload(booking.tripId, attachment, file);
        } catch (error) {
          // Offline or not allowed yet: the next sync tries again.
          if (kDebugMode) debugPrint('Ticket backup failed (will retry): $error');
        }
      }
      if (uploaded.isEmpty) return;
      // Re-read: the traveller may have edited the booking meanwhile.
      final latest = this.booking(bookingId);
      if (latest == null) return;
      await repository.saveBooking(latest.copyWith(attachments: [
        for (final a in latest.attachments)
          uploaded.containsKey(a.id) && a.remotePath == null ? a.withRemotePath(uploaded[a.id]!) : a,
      ]));
    } finally {
      _syncing.remove(bookingId);
    }
  }

  Future<void> _deleteFiles(Attachment attachment) async {
    await attachments?.delete(attachment);
    if (attachment.remotePath != null) {
      try {
        await backup?.delete(attachment);
      } catch (_) {
        // A stray cloud copy is harmless; members can still delete it.
      }
    }
  }

  // ---------------------------------------------------------------- sharing

  SharingService get _sharing =>
      sharing ?? (throw const SharingException('Family sharing needs your trips saved to the cloud.'));

  Future<TripInvite> createInvite(TripPlan plan, {String? name}) =>
      _sharing.createInvite(plan.id, name: name);

  Future<({String tripId, String title})> joinTrip(String code, {required String name}) =>
      _sharing.join(code, name: name);

  Future<void> removeMember(TripPlan plan, String memberId) => _sharing.removeMember(plan.id, memberId);

  Future<void> leaveTrip(TripPlan plan) => _sharing.removeMember(plan.id, userId);

  // ------------------------------------------------------- design & testing

  /// Pretend it's [time] so you can see cards in every state. Null resets.
  set previewNow(DateTime? time) {
    _previewNow = time;
    notifyListeners();
  }

  /// Puts the sample trips back (demo mode only).
  void resetDemoData() {
    final repo = repository;
    if (repo is! MemoryTravelRepository) return;
    final demo = buildDemoData(today, userId: repo.userId);
    repo.replaceAll(demo.trips, demo.bookings);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // --------------------------------------------------------------- internal

  /// Trips form automatically, so they should also go away on their own:
  /// once the last booking leaves a trip that has no planned dates, the
  /// empty trip is removed.
  Future<void> _dropTripIfEmptied(String tripId, {required String removing}) async {
    final plan = this.plan(tripId);
    if (plan == null || plan.trip.plannedStart != null || !isOwner(plan)) return;
    if (plan.bookings.every((b) => b.id == removing)) {
      await repository.deleteTrip(plan.trip, const []);
    }
  }

  void _rebuild() {
    _plans = buildTripPlans(_trips, _bookings);
    notifyListeners();
    if (backup != null) {
      // Settle, then back up and fetch tickets in the background.
      _syncTimer?.cancel();
      _syncTimer = Timer(const Duration(seconds: 2), () => unawaited(syncTickets()));
    }
  }

  void _reportError(Object error) {
    _error = error is String ? error : 'Something went wrong: $error';
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _syncTimer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

/// A trip created during a batch save, before the repository echoes it back.
class _NewTrip {
  _NewTrip(this.id, this.title, this.start, this.end);

  final String id;
  final String title;
  LocalDate start;
  LocalDate end;

  void stretch(LocalDate from, LocalDate to) {
    start = LocalDate.min(start, from);
    end = LocalDate.max(end, to);
  }
}
