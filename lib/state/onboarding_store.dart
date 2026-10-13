import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/onboarding_record.dart';
import '../data/onboarding_repository.dart';
import '../domain/domain.dart';
import '../domain/onboarding.dart';
import '../logic/destinations.dart';
import '../logic/onboarding_rules.dart';
import 'travel_store.dart';

class OnboardingStore extends ChangeNotifier {
  OnboardingStore({required this.repository, this.record, this.userId});
  final OnboardingRepository repository;

  /// The account's onboarding, across phones (`users/{uid}`); null in demo.
  final OnboardingRecord? record;
  final String? userId;
  OnboardingDraft _draft = const OnboardingDraft();
  bool? _completedElsewhere;
  bool _loading = true;
  String? _error;
  bool _disposed = false;
  Trip? _createdTrip;
  Future<Trip>? _creating;
  int _run = 0;
  bool _replaying = false;

  OnboardingDraft get draft => _draft;

  /// Bumped by [restart]: a new run of onboarding, from the roll-in.
  int get run => _run;

  /// Restarted from Design tools: onboarding shows until it's finished,
  /// even for an account that has plans.
  bool get replaying => _replaying;

  /// This account finished onboarding (or signed in) on some phone; null
  /// when it couldn't be checked.
  bool? get completedElsewhere => _completedElsewhere;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    final remote = record == null || userId == null ? null : record!.isCompleted(userId!);
    try {
      _draft = await repository.load();
      _completedElsewhere = await remote;
    } catch (_) {
      _error = 'We couldn’t restore your holiday setup. Your saved bookings are still available.';
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> save(OnboardingDraft draft) async {
    await repository.save(draft);
    _draft = draft;
    _error = null;
    if (!_disposed) notifyListeners();
  }

  /// Reserve and persist the identity before creation. Retrying or relaunching
  /// creates the same holiday, including when its dates are still unknown.
  Future<Trip> ensureHoliday(TravelStore travel) {
    final inFlight = _creating;
    if (inFlight != null) return inFlight;
    final future = _ensureHoliday(travel);
    _creating = future;
    return future.whenComplete(() => _creating = null);
  }

  Future<Trip> _ensureHoliday(TravelStore travel) async {
    final known = _draft.tripId;
    final existing = known == null ? null : travel.plan(known)?.trip;
    if (existing != null) return existing;
    if (_createdTrip != null && _createdTrip!.id == known) return _createdTrip!;
    final destination = _draft.destination;
    if (destination == null) throw StateError('Choose a destination first');
    final id = known ?? travel.repository.newId();
    await save(_draft.copyWith(step: OnboardingStep.booking, tripId: id));
    return _createdTrip = await travel.createTrip(
      '${destination.name} holiday',
      id: id,
      destination: destination,
      start: _draft.start,
      end: _draft.end,
    );
  }

  /// The phone's Back button: one step toward the start. Going back from
  /// the booking step lets go of the holiday made for it, so the new dates
  /// make a fresh one; a holiday that already has bookings stays. False:
  /// nowhere to go back to.
  Future<bool> stepBack(TravelStore travel) async {
    final to = stepBackFrom(_draft.step);
    if (to == null) return false;
    var next = _draft.copyWith(step: to);
    final known = _draft.tripId;
    if (_draft.step == OnboardingStep.booking && known != null) {
      final plan = travel.plan(known);
      if (plan != null && plan.bookings.isNotEmpty) return false;
      if (plan != null) await travel.deleteTrip(plan);
      _createdTrip = null;
      next = next.copyWith(clearTripId: true);
    }
    await save(next);
    return true;
  }

  Future<void> recordBooking(SaveResult result, TravelStore travel, {OnboardingBookingSource? source}) async {
    final trip = travel.plan(result.booking.tripId)?.trip;
    final destination = trip?.destination ?? detectPlace(result.tripTitle)?.destination;
    final changedHoliday = _draft.tripId != null && result.booking.tripId != _draft.tripId;
    await save(
      _draft.copyWith(
        step: OnboardingStep.booking,
        tripId: result.booking.tripId,
        bookingId: result.booking.id,
        bookingSource: source,
        destination: destination,
        clearDestination: changedHoliday && destination == null,
        clearDates: changedHoliday,
      ),
    );
  }

  /// Design tools (debug builds): start onboarding again from the very
  /// beginning on this phone. Holidays it made before are kept.
  Future<void> restart() async {
    _createdTrip = null;
    _run += 1;
    _replaying = true;
    await save(const OnboardingDraft());
  }

  Future<void> complete() async {
    _replaying = false;
    await save(_draft.copyWith(completed: true));
    if (userId != null) unawaited(record?.markCompleted(userId!));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
