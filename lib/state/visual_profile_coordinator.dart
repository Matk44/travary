import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/visual_profile_service.dart';
import '../domain/domain.dart';
import '../logic/visual_profile_request.dart';
import 'analytics.dart';

/// A trip as it is right now, for classification.
typedef TripSnapshot = ({Trip trip, List<Booking> bookings});

/// Decides when trips are (re)classified, so the server is asked only after
/// meaningful changes, and never while a batch import is still saving.
///
/// - Edits are debounced per trip; the payload is taken when the timer
///   fires, and skipped if it's the same as the last one sent.
/// - The server's source hash is the final guard against duplicates.
/// - Failures never block anything: the trip keeps its look. A trip that
///   hasn't reached the server yet, or is cooling down, is retried a few
///   times; anything else waits for the next meaningful edit.
/// - Nothing is sent until the traveller has [allowed] Google's AI
///   (`logic/ai_consent.dart`); the owner schedules every trip once they do.
class VisualProfileCoordinator {
  VisualProfileCoordinator({
    required this.service,
    required this.snapshot,
    this.allowed,
    this.debounce = const Duration(seconds: 4),
    this.notSyncedRetries = const [Duration(seconds: 5), Duration(seconds: 20)],
  });

  final VisualProfileService service;

  /// Whether trips may go to the classifier (Google's Gemini) now. Null:
  /// always (tests of the classifier itself).
  final bool Function()? allowed;
  bool get _allowed => allowed?.call() ?? true;

  /// The trip and its bookings now, or null if the trip is gone.
  final TripSnapshot? Function(String tripId) snapshot;
  final Duration debounce;
  final List<Duration> notSyncedRetries;

  final _timers = <String, Timer>{};
  final _lastSent = <String, String>{};
  final _running = <String>{};
  final _dirty = <String>{};
  final _notSyncedAttempts = <String, int>{};
  final _paused = <String>{};
  int _pauseDepth = 0;
  bool _disposed = false;

  /// Classifies [tripId] once edits settle.
  void schedule(String tripId, {Duration? after}) {
    if (_disposed || tripId.isEmpty) return;
    if (_pauseDepth > 0) {
      _paused.add(tripId);
      return;
    }
    _timers.remove(tripId)?.cancel();
    _timers[tripId] = Timer(after ?? debounce, () {
      _timers.remove(tripId);
      unawaited(_run(tripId));
    });
  }

  /// Holds classification while several bookings save together.
  void pause() => _pauseDepth++;

  /// Resumes, scheduling every trip touched while paused.
  void resume() {
    if (_pauseDepth == 0) return;
    _pauseDepth--;
    if (_pauseDepth > 0) return;
    final trips = [..._paused];
    _paused.clear();
    trips.forEach(schedule);
  }

  /// Classifies [tripId] now (the traveller asked for the automatic look).
  /// Throws [VisualProfileException] with a friendly message on failure.
  Future<TripVisualProfile> classifyNow(String tripId) async {
    _timers.remove(tripId)?.cancel();
    if (!_allowed) {
      throw const VisualProfileException(
        VisualProfileFailure.failed,
        'Automatic looks use Google’s AI. You can allow it in Profile.',
      );
    }
    final current = snapshot(tripId);
    if (current == null) {
      throw const VisualProfileException(VisualProfileFailure.failed, 'This trip has been deleted.');
    }
    final payload = jsonEncode(classifierPayload(current.trip, current.bookings));
    final profile = await service.classify(current.trip, current.bookings);
    _lastSent[tripId] = payload;
    return profile;
  }

  Future<void> _run(String tripId) async {
    if (_disposed || !_allowed) return;
    if (_running.contains(tripId)) {
      _dirty.add(tripId);
      return;
    }
    final current = snapshot(tripId);
    if (current == null || !hasEnoughToClassify(current.trip, current.bookings)) return;
    final payload = jsonEncode(classifierPayload(current.trip, current.bookings));
    if (_lastSent[tripId] == payload) return;

    _running.add(tripId);
    try {
      final profile = await service.classify(current.trip, current.bookings);
      _lastSent[tripId] = payload;
      _notSyncedAttempts.remove(tripId);
      track('visual_profile_classified', {'theme': profile.primaryTheme.wireName});
    } on VisualProfileException catch (e) {
      track('visual_profile_failed', {'reason': e.failure.name});
      switch (e.failure) {
        case VisualProfileFailure.cooldown:
          schedule(tripId, after: e.retryAfter);
        case VisualProfileFailure.notSynced:
          final attempt = _notSyncedAttempts[tripId] ?? 0;
          if (attempt < notSyncedRetries.length) {
            _notSyncedAttempts[tripId] = attempt + 1;
            schedule(tripId, after: notSyncedRetries[attempt]);
          } else {
            _notSyncedAttempts.remove(tripId);
          }
        default:
          // Try again after the next meaningful edit or explicit request.
          break;
      }
    } catch (error) {
      // Never let a background classification surface as an app error.
      if (kDebugMode) debugPrint('Trip classification failed: $error');
      track('visual_profile_failed', {'reason': 'unexpected'});
    } finally {
      _running.remove(tripId);
      if (_dirty.remove(tripId)) schedule(tripId);
    }
  }

  void dispose() {
    _disposed = true;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
