import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/attachment_store.dart';
import '../data/demo_data.dart';
import '../data/memory_travel_repository.dart';
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
  final ArtResolver art;
  final DateTime Function() _clock;

  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _ticker;
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
        await attachments?.delete(removed);
      }
    }
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
      results.add(result);
      final saved = result.booking;
      final known = createdHere.where((t) => t.id == saved.tripId).firstOrNull;
      if (result.newTrip) {
        createdHere.add(_NewTrip(saved.tripId, saved.startDate, saved.lastDate));
      } else if (known != null) {
        known.stretch(saved.startDate, saved.lastDate);
      }
    }
    return results;
  }

  Future<void> deleteBooking(Booking booking) async {
    await repository.deleteBooking(booking);
    await _dropTripIfEmptied(booking.tripId, removing: booking.id);
    for (final attachment in booking.attachments) {
      await attachments?.delete(attachment);
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
    await repository.saveTrip(trip);
    return trip;
  }

  Future<void> updateTrip(Trip trip) =>
      repository.saveTrip(trip.copyWith(updatedAt: DateTime.now()));

  Future<void> deleteTrip(TripPlan plan) async {
    await repository.deleteTrip(plan.trip, plan.bookings);
    for (final booking in plan.bookings) {
      for (final attachment in booking.attachments) {
        await attachments?.delete(attachment);
      }
    }
  }

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
    if (plan == null || plan.trip.plannedStart != null) return;
    if (plan.bookings.every((b) => b.id == removing)) {
      await repository.deleteTrip(plan.trip, const []);
    }
  }

  void _rebuild() {
    _plans = buildTripPlans(_trips, _bookings);
    notifyListeners();
  }

  void _reportError(Object error) {
    _error = error is String ? error : 'Something went wrong: $error';
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

/// A trip created during a batch save, before the repository echoes it back.
class _NewTrip {
  _NewTrip(this.id, this.start, this.end);

  final String id;
  LocalDate start;
  LocalDate end;

  void stretch(LocalDate from, LocalDate to) {
    start = LocalDate.min(start, from);
    end = LocalDate.max(end, to);
  }
}
