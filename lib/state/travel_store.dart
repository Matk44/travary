import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/art_pack_catalog.dart';
import '../data/art_pack_service.dart';
import '../data/attachment_backup.dart';
import '../data/attachment_store.dart';
import '../data/demo_data.dart';
import '../data/memory_travel_repository.dart';
import '../data/sharing_service.dart';
import '../data/travel_repository.dart';
import '../data/visual_profile_service.dart';
import '../design/art/art_catalog.dart';
import '../design/art/art_resolver.dart';
import '../design/art/art_slots.dart';
import '../domain/domain.dart';
import '../logic/art_pack_selection.dart';
import '../logic/art_subjects.dart';
import '../logic/day_plan.dart';
import '../logic/destinations.dart';
import '../logic/trip_assignment.dart';
import '../logic/trip_plan.dart';
import '../logic/visual_profile_request.dart';
import 'art_catalog_controller.dart';
import 'visual_profile_coordinator.dart';

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
    this.artPacks,
    VisualProfileService? visualProfiles,
    Duration classificationDebounce = const Duration(seconds: 4),
    this.attachments,
    this.backup,
    this.sharing,
    DateTime Function()? clock,
  }) : _artCatalogs = ArtCatalogController(bundled: artCatalog, packs: artPacks),
       _clock = clock ?? DateTime.now {
    _art = ArtResolver(_artCatalogs.catalog);
    _artCatalogs.addListener(_artCatalogChanged);
    artPacks?.addListener(_syncArtPacks);
    if (visualProfiles != null) {
      _classifier = VisualProfileCoordinator(
        service: visualProfiles,
        debounce: classificationDebounce,
        snapshot: (tripId) {
          final plan = this.plan(tripId);
          return plan == null ? null : (trip: plan.trip, bookings: plan.bookings);
        },
      );
    }
    _subscriptions.addAll([
      repository.watchTrips().listen(
        (trips) {
          _trips = trips;
          _tripsLoaded = true;
          _tripsReceived = true;
          _rebuild();
        },
        onError: (Object error) {
          // Show whatever we have rather than a spinner forever.
          _tripsLoaded = true;
          _reportError(error);
        },
      ),
      repository.watchBookings().listen(
        (bookings) {
          _bookings = bookings;
          _bookingsLoaded = true;
          _bookingsReceived = true;
          _rebuild();
        },
        onError: (Object error) {
          _bookingsLoaded = true;
          _reportError(error);
        },
      ),
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

  /// Downloadable art packs; null leaves just the bundled art.
  final ArtPackManager? artPacks;
  final ArtCatalogController _artCatalogs;
  late ArtResolver _art;
  final _artContexts = <String, TripArtContext>{};

  /// Automatic looks (cloud mode only: the server classifies saved trips).
  VisualProfileCoordinator? _classifier;

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

  /// Real data from both streams (not just a failed load): only then do the
  /// trips say which art packs to keep.
  bool _tripsReceived = false;
  bool _bookingsReceived = false;
  DateTime? _previewNow;
  String? _error;

  // ---------------------------------------------------------------- reading

  bool get isLoading => !(_tripsLoaded && _bookingsLoaded);
  bool get isDemo => repository is MemoryTravelRepository;
  String get userId => repository.userId;
  bool get sharingAvailable => sharing != null;
  bool get automaticLooksAvailable => _classifier != null;

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

  /// The look [booking]'s cards use: its trip's, or classic outside a trip.
  ExperienceTheme themeOf(Booking booking) =>
      plan(booking.tripId)?.trip.effectiveTheme ?? ExperienceTheme.classicTravel;

  DayPlan dayPlan(LocalDate date) => buildDayPlan(date, _bookings, now);

  /// Picks card artwork from the bundled art and installed packs. Replaced
  /// whenever packs are installed or evicted.
  ArtResolver get art => _art;

  /// What [booking]'s trip means for its artwork: look, secondary themes and
  /// the installed packs that suit it.
  TripArtContext artContextOf(Booking booking) {
    final plan = this.plan(booking.tripId);
    if (plan == null) return TripArtContext.forTheme(ExperienceTheme.classicTravel);
    return artContextForPlan(plan);
  }

  /// [plan]'s art context (cached until the trip or the installed packs
  /// change).
  TripArtContext artContextForPlan(TripPlan plan) =>
      _artContexts.putIfAbsent(plan.id, () => artContextFor(plan.trip, _art.catalog.packs));

  /// The interface palette for [plan]: the best-ranked installed pack's,
  /// else Travary's own. One palette per trip screen.
  DestinationPalette paletteFor(TripPlan? plan) =>
      _art.catalog.palette(context: plan == null ? null : artContextForPlan(plan));

  /// Tabs, textures and icons for [plan]'s screens, ranked like its cards.
  ArtSlots chromeArtFor(TripPlan? plan) => ArtSlots(
    _art.catalog,
    plan == null ? TripArtContext.forTheme(ExperienceTheme.classicTravel) : artContextForPlan(plan),
  );

  /// The destination postcard for [plan]'s countdown (Today between
  /// trips). Postcards are place-specific, so they stay hidden until the
  /// trip's location has been verified. Once verified, resolution follows
  /// the normal city, region, country, look and core ranks.
  SharedArtRef? countdownPostcardFor(TripPlan plan) {
    if (!_hasVerifiedLocation(plan)) return null;
    return _art.catalog.commonArt(countdownPostcardArt, context: artContextForPlan(plan));
  }

  /// The bundled, place-neutral postcard for a countdown whose trip has no
  /// postcard of its own ([countdownPostcardFor] is null). Null if the app
  /// doesn't carry one.
  SharedArtRef? get neutralCountdownPostcard => _art.catalog.commonArt(countdownPostcardAnywhereArt);

  /// The landscape postcard for [plan] on the Trips tab, ranked and
  /// guarded exactly like [countdownPostcardFor]: null rather than another
  /// place's postcard.
  SharedArtRef? tripPostcardFor(TripPlan plan) {
    if (!_hasVerifiedLocation(plan)) return null;
    return _art.catalog.commonArt(tripPostcardArt, context: artContextForPlan(plan));
  }

  /// The destination stamp beside the Documents heading for [plan], and
  /// the place to print on its label. Only the trip's own city, region or
  /// country pack supplies one, for a verified place; never a look pack or
  /// bundled art, so null rather than another place's stamp.
  ({SharedArtRef art, String place})? destinationStampFor(TripPlan plan) {
    final location = plan.trip.effectiveLocation;
    if (location == null || !_hasVerifiedLocation(plan)) return null;
    final context = artContextForPlan(plan);
    final own = TripArtContext(
      theme: context.theme,
      packRanks: {
        for (final entry in context.packRanks.entries)
          if (destinationRanks.contains(entry.value)) entry.key: entry.value,
      },
      rankOrder: destinationRanks,
    );
    final art = _art.catalog.commonArt(documentsDestinationStampArt, context: own);
    final pack = art?.pack;
    if (art == null || pack == null) return null;
    return (art: art, place: destinationName(location, own.packRanks[pack.id]!) ?? plan.trip.title);
  }

  /// The traveller's own destination counts: they confirmed it.
  bool _hasVerifiedLocation(TripPlan plan) =>
      plan.trip.effectiveLocation?.verification == LocationVerification.verified;

  /// A look's context without a trip (design tools): its experience packs
  /// count, destination packs don't.
  TripArtContext artContextForLook(ExperienceTheme theme) => TripArtContext(
    theme: theme,
    packRanks: {
      for (final pack in _art.catalog.packs)
        if (packRankFor(pack, theme: theme) case final rank?) pack.id: rank,
    },
  );

  ArtChoice artFor(Booking booking) => _art.resolve(booking, artContextOf(booking));

  List<ArtChoice> artForAll(List<Booking> bookings) => _art.resolveAll(bookings, artContextOf);

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
      final match = findTripFor(saved.startDate, saved.lastDate, _plans) ?? findReturnFlightTrip(saved, _plans);
      if (match != null) {
        saved = saved.copyWith(tripId: match.id);
        tripTitle = match.trip.title;
      } else {
        final title = suggestTripTitle(saved);
        final trip = await createTrip(title, destination: detectPlace(title)?.destination);
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

    // A new trip was scheduled when it was created.
    if (previous == null || changesClassification(previous, saved)) {
      _classifier?.schedule(saved.tripId);
      if (previous != null && previous.tripId != saved.tripId) _classifier?.schedule(previous.tripId);
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
    // Classify each trip once, after the whole batch is saved.
    _classifier?.pause();
    try {
      return await _saveBatch(bookings);
    } finally {
      _classifier?.resume();
    }
  }

  Future<List<SaveResult>> _saveBatch(List<Booking> bookings) async {
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
    _classifier?.schedule(booking.tripId);
    for (final attachment in booking.attachments) {
      await _deleteFiles(attachment);
    }
  }

  /// Creates a trip. Its look is automatic unless a [theme] is given.
  Future<Trip> createTrip(
    String title, {
    ExperienceTheme? theme,
    LocalDate? start,
    LocalDate? end,
    TripDestination? destination,
  }) async {
    final stamp = DateTime.now();
    final trip = Trip(
      id: repository.newId(),
      title: title,
      theme: theme ?? ExperienceTheme.classicTravel,
      themeSource: theme == null ? ThemeSource.auto : ThemeSource.manual,
      plannedStart: start,
      plannedEnd: end,
      destination: destination,
      ownerId: repository.userId,
      memberIds: [repository.userId],
      createdAt: stamp,
      updatedAt: stamp,
    );
    await repository.createTrip(trip);
    // Waits for enough to go on (a telling name, or a first booking).
    _classifier?.schedule(trip.id);
    return trip;
  }

  Future<void> updateTrip(Trip trip) async {
    final before = plan(trip.id)?.trip;
    await repository.updateTrip(trip.copyWith(updatedAt: DateTime.now()));
    if (before != null && before.title.trim() != trip.title.trim()) _classifier?.schedule(trip.id);
  }

  /// The traveller picks [theme] for [plan]: a manual look the classifier
  /// never changes.
  Future<void> chooseLook(TripPlan plan, ExperienceTheme theme) =>
      updateTrip(plan.trip.copyWith(theme: theme, themeSource: ThemeSource.manual));

  /// Back to the automatic look: the stored profile's theme at once, and a
  /// fresh classification. Throws [VisualProfileException] (with a friendly
  /// message) if that can't happen now; the trip is automatic regardless.
  Future<void> useAutomaticLook(TripPlan plan) async {
    final trip = plan.trip;
    await updateTrip(trip.copyWith(themeSource: ThemeSource.auto, theme: trip.visualProfile?.primaryTheme));
    final classifier = _classifier;
    if (classifier == null) {
      throw const VisualProfileException(
        VisualProfileFailure.failed,
        'Automatic looks work with trips saved to the cloud. This is the demo version.',
      );
    }
    if (!hasEnoughToClassify(trip, plan.bookings)) return;
    await classifier.classifyNow(trip.id);
  }

  /// Checks for new art packs if it's been a while (e.g. back from the
  /// background). Never throws.
  Future<void> refreshArtPacksIfStale() async {
    await artPacks?.refreshIfStale();
  }

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
      await repository.saveBooking(
        latest.copyWith(
          attachments: [
            for (final a in latest.attachments)
              uploaded.containsKey(a.id) && a.remotePath == null ? a.withRemotePath(uploaded[a.id]!) : a,
          ],
        ),
      );
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

  Future<TripInvite> createInvite(TripPlan plan, {String? name}) => _sharing.createInvite(plan.id, name: name);

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
    _artContexts.clear();
    _syncArtPacks();
    notifyListeners();
    if (backup != null) {
      // Settle, then back up and fetch tickets in the background.
      _syncTimer?.cancel();
      _syncTimer = Timer(const Duration(seconds: 2), () => unawaited(syncTickets()));
    }
  }

  /// Packs were installed or evicted: new resolver, fresh contexts, redraw.
  void _artCatalogChanged() {
    _art = ArtResolver(_artCatalogs.catalog);
    _artContexts.clear();
    notifyListeners();
  }

  /// Tells the art-pack manager what the trips need: the smallest set of
  /// packs for each current or coming trip, which packs to keep (pinned)
  /// and which were used. Not before trips and bookings have arrived:
  /// "nothing pinned" would let eviction remove packs they need.
  void _syncArtPacks() {
    final packs = artPacks;
    if (packs == null || !_tripsReceived || !_bookingsReceived) return;
    final catalog = packs.catalog;
    final available = [for (final pack in catalog?.packs ?? const <CatalogPack>[]) pack.ref];
    final installed = [for (final pack in packs.installed) pack.ref];
    final today = this.today;
    final wanted = <String, CatalogPack>{};
    final pinned = <String>{};
    final used = <String>{};
    for (final plan in _plans) {
      final context = artContextFor(plan.trip, installed);
      used.addAll(context.packRanks.keys);
      if (plan.phaseOn(today) == TripPhase.past) continue;
      pinned.addAll(context.packRanks.keys);
      for (final booking in plan.bookings) {
        final key = booking.artKey;
        if (key != null && key.contains(':')) pinned.add(key.substring(0, key.indexOf(':')));
      }
      final subjects = {for (final booking in plan.bookings) ?artSubjectFor(booking)};
      for (final ref in packsToDownload(plan.trip, available, subjects: subjects)) {
        final pack = catalog?.pack(ref.id);
        if (pack != null) wanted[pack.id] = pack;
      }
    }
    pinned.addAll(wanted.keys);
    unawaited(packs.request(wanted: wanted.values.toList(), pinned: pinned, used: used));
  }

  void _reportError(Object error) {
    _error = error is String ? error : 'Something went wrong: $error';
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _syncTimer?.cancel();
    _classifier?.dispose();
    artPacks?.removeListener(_syncArtPacks);
    _artCatalogs
      ..removeListener(_artCatalogChanged)
      ..dispose();
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
