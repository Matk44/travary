import 'dart:async';

import 'package:travary/data/push_service.dart';
import 'package:travary/domain/domain.dart';

/// Notifications from memory: the system's answer is [answer], and every
/// ask and registration is recorded.
class FakePushService implements PushService {
  FakePushService({this.current = NotificationPermission.notAsked, this.answer = NotificationPermission.allowed});

  NotificationPermission current;
  NotificationPermission answer;
  int asks = 0;
  final registered = <String>[];
  FlightPush? launch;
  final _opened = StreamController<FlightPush>.broadcast();
  final _unseen = StreamController<FlightPush>.broadcast();

  void tap(FlightPush push) => _opened.add(push);
  void arrive(FlightPush push) => _unseen.add(push);

  @override
  Future<NotificationPermission> permission() async => current;

  @override
  Future<NotificationPermission> requestPermission() async {
    asks++;
    return current = answer;
  }

  @override
  Future<void> register(String userId) async => registered.add(userId);

  @override
  Future<FlightPush?> takeLaunchPush() async {
    final push = launch;
    launch = null;
    return push;
  }

  @override
  Stream<FlightPush> get opened => _opened.stream;

  @override
  Stream<FlightPush> get unseen => _unseen.stream;
}
