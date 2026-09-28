import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../domain/domain.dart';
import '../logic/visual_profile_request.dart';

/// Why a classification didn't happen. None of these block anything: the
/// trip keeps its current look.
enum VisualProfileFailure {
  /// The trip hasn't reached the server yet (it was just created). Worth
  /// another go in a few seconds.
  notSynced,

  /// The trip was classified moments ago; try after [VisualProfileException.retryAfter].
  cooldown,

  /// The traveller's daily allowance is used up.
  dailyLimit,

  /// A newer change to the trip is being classified instead.
  superseded,

  /// No connection.
  offline,

  /// Gemini is overloaded.
  busy,

  /// Anything else, including the service not being set up.
  failed,
}

/// A classification problem, with a message fit for the traveller.
class VisualProfileException implements Exception {
  const VisualProfileException(this.failure, this.message, {this.retryAfter});

  final VisualProfileFailure failure;
  final String message;
  final Duration? retryAfter;

  @override
  String toString() => message;
}

/// Classifies a trip's itinerary into a visual profile (the server's
/// `classifyTripVisuals` function: Gemini plus Places verification). The
/// server stores the profile on the trip, and updates the trip's theme if
/// its look is automatic.
abstract interface class VisualProfileService {
  Future<TripVisualProfile> classify(Trip trip, List<Booking> bookings);
}

/// Calls a Firebase callable by name; replaced in tests.
typedef CallableInvoker = Future<Object?> Function(String name, Map<String, Object?> data, Duration timeout);

/// The `classifyTripVisuals` Cloud Function. Sends only what
/// [classifierPayload] allows: never references, notes, tickets or details.
class CloudVisualProfileService implements VisualProfileService {
  CloudVisualProfileService({required this.ensureSignedIn, FirebaseFunctions? functions, CallableInvoker? invoke})
    : _invoke = invoke ?? _firebaseInvoker(functions);

  final Future<void> Function() ensureSignedIn;
  final CallableInvoker _invoke;

  static const timeout = Duration(seconds: 120);

  @override
  Future<TripVisualProfile> classify(Trip trip, List<Booking> bookings) async {
    final payload = classifierPayload(trip, bookings);
    try {
      await ensureSignedIn();
      final data = await _invoke('classifyTripVisuals', payload, timeout);
      final profile = data is Map ? TripVisualProfile.tryParse(data['profile']) : null;
      if (profile == null) {
        throw const VisualProfileException(
          VisualProfileFailure.failed,
          'Couldn\'t choose a look for this trip right now.',
        );
      }
      return profile;
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) debugPrint('classifyTripVisuals failed: code=${e.code}');
      throw visualProfileExceptionFor(e.code, e.details);
    } on SocketException {
      throw const VisualProfileException(VisualProfileFailure.offline, 'Automatic looks need an internet connection.');
    } on TimeoutException {
      throw const VisualProfileException(VisualProfileFailure.offline, 'Automatic looks need an internet connection.');
    }
  }
}

CallableInvoker _firebaseInvoker(FirebaseFunctions? functions) => (name, data, timeout) async {
  final callable = (functions ?? FirebaseFunctions.instance).httpsCallable(
    name,
    options: HttpsCallableOptions(timeout: timeout),
  );
  return (await callable.call<Object?>(data)).data;
};

/// The traveller-facing failure for a callable error [code] and [details].
VisualProfileException visualProfileExceptionFor(String code, Object? details) {
  final info = details is Map ? details : const {};
  final reason = info['reason'];
  switch (code) {
    case 'not-found':
      return const VisualProfileException(
        VisualProfileFailure.notSynced,
        'This trip is still saving. Try again in a moment.',
      );
    case 'resource-exhausted':
      if (reason == 'cooldown') {
        final seconds = info['retryAfterSeconds'];
        return VisualProfileException(
          VisualProfileFailure.cooldown,
          'This trip was updated a moment ago. Its look will follow shortly.',
          retryAfter: Duration(seconds: seconds is num && seconds > 0 ? seconds.ceil() : 15),
        );
      }
      return const VisualProfileException(
        VisualProfileFailure.dailyLimit,
        'Automatic looks are resting until tomorrow.',
      );
    case 'aborted':
      return const VisualProfileException(
        VisualProfileFailure.superseded,
        'A newer change to this trip is being styled.',
      );
    case 'unavailable':
      return const VisualProfileException(
        VisualProfileFailure.busy,
        'Automatic looks are busy right now. Try again in a minute.',
      );
    default:
      return const VisualProfileException(
        VisualProfileFailure.failed,
        'Couldn\'t choose a look for this trip right now.',
      );
  }
}
