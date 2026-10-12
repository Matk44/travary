import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/reminder_scheduler.dart';
import '../data/reminder_settings.dart';
import '../domain/domain.dart';
import '../logic/reminders.dart';
import '../logic/trip_plan.dart';
import 'analytics.dart';
import 'travel_store.dart';

/// Reminders (`logic/reminders.dart`), free for everyone: on or off on this
/// phone, the offer to turn them on (on a trip's page once it has a
/// booking, never at launch), and keeping what's set in step with the
/// trips and the phone's clock. Without a scheduler (tests) nothing offers.
class RemindersStore extends ChangeNotifier {
  RemindersStore({
    required ReminderScheduler? scheduler,
    required ReminderSettings settings,
    required TravelStore travel,
  }) : _scheduler = scheduler,
       _settings = settings,
       _travel = travel {
    _travel.addListener(_travelChanged);
  }

  final ReminderScheduler? _scheduler;
  final ReminderSettings _settings;
  final TravelStore _travel;

  bool _loaded = false;
  bool _chosenOn = false;
  bool _declined = false;
  bool? _allowed;
  bool _disposed = false;
  List<Reminder>? _set;
  Timer? _settle;
  StreamSubscription<String>? _taps;
  String? _toOpen;

  bool get available => _scheduler != null;

  /// Turned on, and the phone lets them show.
  bool get on => _chosenOn && _allowed == true;

  /// Turned on here, but notifications are off for Travary in Settings.
  bool get blocked => _chosenOn && _allowed == false;

  Future<void> start() async {
    final scheduler = _scheduler;
    if (scheduler == null) return;
    final choice = await _settings.load();
    final allowed = await scheduler.allowed();
    if (_disposed) return;
    _chosenOn = choice.on;
    _declined = choice.declined;
    _allowed = allowed;
    _loaded = true;
    _taps = scheduler.tapped.listen(_open);
    if (await scheduler.takeLaunch() case final opens?) _open(opens);
    _changed();
    await _apply();
  }

  /// Whether [plan]'s page offers reminders: a holiday on now or still to
  /// come, with a booking, and the traveller hasn't turned them on or down.
  bool offersFor(TripPlan plan) =>
      _loaded && !_chosenOn && !_declined && plan.bookings.isNotEmpty && plan.phaseOn(_travel.today) != TripPhase.past;

  /// "Yes, remind me" (or Profile's switch): the system's prompt if it
  /// hasn't been answered, then on. Returns whether they'll show.
  Future<bool> turnOn() async {
    final scheduler = _scheduler;
    if (scheduler == null) return false;
    var allowed = await scheduler.allowed();
    if (!allowed) allowed = await scheduler.ask();
    if (_disposed) return allowed;
    _allowed = allowed;
    _chosenOn = true;
    _declined = false;
    await _settings.save((on: true, declined: false));
    track('reminders_on', {'allowed': allowed});
    _changed();
    await _apply();
    return allowed;
  }

  Future<void> turnOff() async {
    _chosenOn = false;
    await _settings.save((on: false, declined: _declined));
    track('reminders_off');
    _changed();
    await _apply();
  }

  /// "Not now" on the offer: it isn't shown again (Profile still has it).
  Future<void> decline() async {
    _declined = true;
    await _settings.save((on: _chosenOn, declined: true));
    track('reminders_declined');
    _changed();
  }

  /// Back from the background: Settings may have changed, or the phone
  /// may be in another time zone, so everything is set again.
  Future<void> refresh() async {
    final scheduler = _scheduler;
    if (scheduler == null || !_loaded) return;
    final allowed = await scheduler.allowed();
    if (_disposed) return;
    if (allowed != _allowed) {
      _allowed = allowed;
      _changed();
    }
    _set = null;
    await _apply();
  }

  /// Design tools (debug builds): the next morning's plan as it would
  /// read, shown in five seconds, so a real notification can be checked.
  /// The reminders set before are set again after it.
  Future<void> sendTest() async {
    final scheduler = _scheduler;
    if (scheduler == null || !on) return;
    final next = remindersFor(_travel.plans, _travel.now).where((r) => r.opens.startsWith('day:')).firstOrNull;
    final now = DateTime.now();
    final still = [...?_set?.where((r) => r.at.isAfter(now))];
    await scheduler.setAll([
      Reminder(
        at: now.add(const Duration(seconds: 5)),
        title: next?.title ?? 'Travary reminders are on',
        body: next?.body ?? 'Your day’s plan comes each morning of a trip.',
        opens: next?.opens ?? 'day:${LocalDate.fromDateTime(now).toIso()}',
      ),
      ...still,
    ]);
  }

  /// A reminder tapped: `booking:<id>` or `day:<date>`, for the home screen
  /// to open. Once.
  String? takeToOpen() {
    final opens = _toOpen;
    _toOpen = null;
    return opens;
  }

  void _open(String opens) {
    track('reminder_opened', {'kind': opens.split(':').first});
    _toOpen = opens;
    _changed();
  }

  /// Trips change in bursts (a sync, a Smart Import batch), and the clock
  /// ticks every minute: set them again once things settle.
  void _travelChanged() {
    _settle?.cancel();
    _settle = Timer(const Duration(seconds: 2), _apply);
  }

  Future<void> _apply() async {
    final scheduler = _scheduler;
    // "Preview a different time" (Design tools) isn't the phone's clock.
    if (scheduler == null || !_loaded || _disposed || _travel.isLoading || _travel.previewNow != null) return;
    final wanted = on ? remindersFor(_travel.plans, _travel.now) : const <Reminder>[];
    if (_set != null && listEquals(wanted, _set)) return;
    _set = wanted;
    try {
      await scheduler.setAll(wanted);
    } catch (error) {
      // Tried again on the next change or return to the app.
      _set = null;
      if (kDebugMode) debugPrint('Reminders not set: $error');
    }
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settle?.cancel();
    unawaited(_taps?.cancel());
    _travel.removeListener(_travelChanged);
    super.dispose();
  }
}
