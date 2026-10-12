import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../domain/domain.dart';

/// A flight alert, as the server sent it (`functions/src/flightAlerts.ts`).
class FlightPush {
  const FlightPush({required this.tripId, required this.bookingId, this.title, this.body});

  static FlightPush? fromMessage(RemoteMessage message) {
    final data = message.data;
    final tripId = data['tripId'];
    final bookingId = data['bookingId'];
    if (data['type'] != 'flight' || tripId is! String || bookingId is! String) return null;
    return FlightPush(
      tripId: tripId,
      bookingId: bookingId,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  final String tripId;
  final String bookingId;
  final String? title;
  final String? body;
}

/// Notifications on this phone: whether they're allowed, where the server
/// sends flight alerts (this phone, for the signed-in account), and alerts
/// tapped or arriving while the app is open. Cloud mode only.
abstract interface class PushService {
  Future<NotificationPermission> permission();

  /// The system's prompt (it shows once per phone). Returns the answer.
  Future<NotificationPermission> requestPermission();

  /// Tells the server this phone takes [userId]'s pushes, when allowed.
  /// Safe to call often: it only calls the server when something changed.
  Future<void> register(String userId);

  /// An alert tapped to open the app from a cold start, once.
  Future<FlightPush?> takeLaunchPush();

  /// Alerts tapped while the app was in the background.
  Stream<FlightPush> get opened;

  /// Alerts that arrived while the app was open and the system didn't
  /// show (Android shows nothing then; iOS shows its own banner).
  Stream<FlightPush> get unseen;
}

class FirebasePushService implements PushService {
  FirebasePushService({required this.ensureSignedIn, FirebaseFunctions? functions}) : _functions = functions;

  final Future<void> Function() ensureSignedIn;
  final FirebaseFunctions? _functions;

  FirebaseMessaging? _messaging;
  String? _registered;
  StreamSubscription<String>? _refresh;

  Future<FirebaseMessaging> _ready() async {
    if (_messaging case final messaging?) return messaging;
    await ensureSignedIn();
    final messaging = FirebaseMessaging.instance;
    // iOS shows alerts as banners even while Travary is open.
    await messaging.setForegroundNotificationPresentationOptions(alert: true, sound: true);
    return _messaging = messaging;
  }

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  /// Android before 13 is always allowed; from 13 it's not asked until the
  /// prompt has shown (the plugin keeps track).
  NotificationPermission _read(AuthorizationStatus status) => switch (status) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => NotificationPermission.allowed,
    AuthorizationStatus.notDetermined => NotificationPermission.notAsked,
    AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => NotificationPermission.denied,
  };

  @override
  Future<NotificationPermission> permission() async {
    try {
      final settings = await (await _ready()).getNotificationSettings();
      return _read(settings.authorizationStatus);
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
      return NotificationPermission.denied;
    }
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    try {
      final settings = await (await _ready()).requestPermission(alert: true, sound: true, badge: false);
      return _read(settings.authorizationStatus);
    } catch (e) {
      debugPrint('Couldn\'t ask for notifications: $e');
      return NotificationPermission.denied;
    }
  }

  @override
  Future<void> register(String userId) async {
    try {
      final messaging = await _ready();
      if (await permission() != NotificationPermission.allowed) return;
      final token = await _token(messaging);
      if (token == null) return;
      await _send(userId, token);
      _refresh ??= messaging.onTokenRefresh.listen((token) => unawaited(_send(userId, token).catchError((_) {})));
    } catch (e) {
      // Tried again at the next launch or flight page.
      debugPrint('Couldn\'t register for flight alerts: $e');
    }
  }

  /// iOS hands out a push token only once Apple's has arrived.
  Future<String?> _token(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await messaging.getToken();
      } on FirebaseException catch (e) {
        if (e.code != 'apns-token-not-set') rethrow;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  Future<void> _send(String userId, String token) async {
    if (_registered == '$userId/$token') return;
    await (_functions ?? FirebaseFunctions.instance).httpsCallable('registerPushToken').call<dynamic>({
      'token': token,
      'platform': _android ? 'android' : 'ios',
    });
    _registered = '$userId/$token';
  }

  @override
  Future<FlightPush?> takeLaunchPush() async {
    try {
      final message = await (await _ready()).getInitialMessage();
      return message == null ? null : FlightPush.fromMessage(message);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<FlightPush> get opened =>
      FirebaseMessaging.onMessageOpenedApp.map(FlightPush.fromMessage).where((p) => p != null).cast<FlightPush>();

  @override
  Stream<FlightPush> get unseen => FirebaseMessaging.onMessage
      .where((_) => _android)
      .map(FlightPush.fromMessage)
      .where((p) => p != null)
      .cast<FlightPush>();
}
