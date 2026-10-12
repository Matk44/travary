import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/push_service.dart';
import '../domain/domain.dart';
import 'analytics.dart';

/// Notifications for flight alerts, for the signed-in account: whether this
/// phone shows them, asking (on a flight's page, never at launch), keeping
/// the server's record of where to send them, and alerts waiting to be
/// opened or shown. Without a push service (demo mode, tests) it stays
/// unavailable and nothing asks.
class NotificationsStore extends ChangeNotifier {
  NotificationsStore({required PushService? push, required this.userId}) : _push = push;

  final PushService? _push;
  final String userId;

  final _subscriptions = <StreamSubscription<FlightPush>>[];
  bool _disposed = false;
  FlightPush? _toOpen;
  FlightPush? _unseen;

  /// Null until known; always null without a push service.
  NotificationPermission? permission;

  bool get available => _push != null;

  /// Listens for alerts and, if this phone already allows notifications,
  /// tells the server where to send them. Never asks.
  Future<void> start() async {
    final push = _push;
    if (push == null) return;
    _subscriptions
      ..add(push.opened.listen(_open))
      ..add(push.unseen.listen((alert) => _set(() => _unseen = alert)));
    if (await push.takeLaunchPush() case final alert?) _open(alert);
    await refresh();
  }

  /// Reads the permission again (back from Settings, or the background),
  /// and registers this phone while it's allowed.
  Future<void> refresh() async {
    final push = _push;
    if (push == null) return;
    final now = await push.permission();
    if (_disposed) return;
    if (now != permission) _set(() => permission = now);
    if (now == NotificationPermission.allowed) unawaited(push.register(userId));
  }

  /// The system's prompt. Returns the answer.
  Future<NotificationPermission?> ask() async {
    final push = _push;
    if (push == null) return null;
    final answer = await push.requestPermission();
    track('notifications_asked', {'result': answer.name});
    if (_disposed) return answer;
    _set(() => permission = answer);
    if (answer == NotificationPermission.allowed) unawaited(push.register(userId));
    return answer;
  }

  /// An alert tapped, for the home screen to open its flight. Once.
  FlightPush? takeToOpen() {
    final alert = _toOpen;
    _toOpen = null;
    return alert;
  }

  /// An alert that arrived while the app was open, to show in the app. Once.
  FlightPush? takeUnseen() {
    final alert = _unseen;
    _unseen = null;
    return alert;
  }

  void _open(FlightPush alert) {
    track('flight_alert_opened');
    _set(() => _toOpen = alert);
  }

  void _set(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
