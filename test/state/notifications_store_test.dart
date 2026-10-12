import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/push_service.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/notifications_store.dart';

import '../support/push.dart';

void main() {
  const alert = FlightPush(tripId: 'orlando', bookingId: 'out', title: 'BA 2037 is delayed');

  test('starting never asks; a phone that already allows them is registered', () async {
    final push = FakePushService(current: NotificationPermission.allowed);
    final store = NotificationsStore(push: push, userId: 'alice');
    await store.start();
    expect(push.asks, 0);
    expect(store.permission, NotificationPermission.allowed);
    expect(push.registered, ['alice']);

    final notAsked = FakePushService();
    final other = NotificationsStore(push: notAsked, userId: 'bob');
    await other.start();
    expect(notAsked.asks, 0, reason: 'never at launch');
    expect(notAsked.registered, isEmpty);
    expect(other.permission, NotificationPermission.notAsked);
  });

  test('asking registers this phone once allowed; a no is kept', () async {
    final push = FakePushService();
    final store = NotificationsStore(push: push, userId: 'alice');
    await store.start();
    expect(await store.ask(), NotificationPermission.allowed);
    expect(push.registered, ['alice']);

    final declined = FakePushService(answer: NotificationPermission.denied);
    final other = NotificationsStore(push: declined, userId: 'bob');
    await other.start();
    await other.ask();
    expect(other.permission, NotificationPermission.denied);
    expect(declined.registered, isEmpty);
  });

  test('turned on in Settings: seen on the way back', () async {
    final push = FakePushService(current: NotificationPermission.denied);
    final store = NotificationsStore(push: push, userId: 'alice');
    await store.start();
    push.current = NotificationPermission.allowed;
    await store.refresh();
    expect(store.permission, NotificationPermission.allowed);
    expect(push.registered, ['alice']);
  });

  test('alerts tapped (even the one that opened the app) wait to be opened, once', () async {
    final push = FakePushService()..launch = alert;
    final store = NotificationsStore(push: push, userId: 'alice');
    await store.start();
    expect(store.takeToOpen()?.bookingId, 'out');
    expect(store.takeToOpen(), isNull);

    push.tap(const FlightPush(tripId: 'orlando', bookingId: 'home'));
    push.arrive(alert);
    await Future<void>.delayed(Duration.zero);
    expect(store.takeToOpen()?.bookingId, 'home');
    expect(store.takeUnseen()?.title, 'BA 2037 is delayed');
    expect(store.takeUnseen(), isNull);
    store.dispose();
  });

  test('without push (demo mode) nothing is available or asked', () async {
    final store = NotificationsStore(push: null, userId: 'demo');
    await store.start();
    expect(store.available, isFalse);
    expect(store.permission, isNull);
    expect(await store.ask(), isNull);
  });
}
