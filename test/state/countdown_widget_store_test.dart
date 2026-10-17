import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/countdown_widget_settings.dart';
import 'package:travary/state/analytics.dart';
import 'package:travary/state/countdown_widget_store.dart';

import '../support/home_widget.dart';

void main() {
  late FakeHomeWidget phone;
  late MemoryCountdownWidgetSettings settings;
  late List<String> events;
  late void Function(String event, Map<String, Object> parameters)? savedSink;

  setUp(() {
    phone = FakeHomeWidget();
    settings = MemoryCountdownWidgetSettings();
    events = [];
    savedSink = analyticsSink;
    analyticsSink = (event, properties) => events.add(properties.isEmpty ? event : '$event $properties');
  });
  tearDown(() => analyticsSink = savedSink);

  Future<CountdownWidgetStore> started() async {
    final store = CountdownWidgetStore(bridge: phone, settings: settings);
    addTearDown(store.dispose);
    await store.start();
    return store;
  }

  test('a phone that can have the widget, and hasn\'t, offers it', () async {
    final store = await started();
    expect(store.available, isTrue);
    expect(store.added, isFalse);
    expect(store.offers, isTrue);
    expect(store.status.canPin, isTrue);
  });

  test('without a bridge (tests, web) there is nothing to offer', () async {
    final store = CountdownWidgetStore(bridge: null, settings: settings);
    addTearDown(store.dispose);
    await store.start();
    expect(store.available, isFalse);
    expect(store.offers, isFalse);
    expect(await store.requestPin(), isFalse);
  });

  test('nothing is offered until the phone has answered', () async {
    final store = CountdownWidgetStore(bridge: phone, settings: settings);
    addTearDown(store.dispose);
    expect(store.offers, isFalse);
    expect(store.available, isFalse);
  });

  test('a phone that can\'t answer offers nothing', () async {
    phone.failing = true;
    final store = await started();
    expect(store.available, isFalse);
    expect(store.offers, isFalse);
  });

  test('iOS 15 and 16 have no widget: not offered, and Profile has no row', () async {
    phone.phone = oldiPhone;
    final store = await started();
    expect(store.available, isFalse);
    expect(store.offers, isFalse);
  });

  test('"Not now" puts the offer away for good, but the widget stays available', () async {
    final store = await started();
    var heard = 0;
    store.addListener(() => heard++);
    await store.decline();
    expect(store.offers, isFalse);
    expect(store.available, isTrue, reason: 'Profile keeps it');
    expect(settings.choice.declined, isTrue);
    expect(heard, 1);
    expect(events, ['countdown_widget_declined']);

    final again = await started();
    expect(again.offers, isFalse, reason: 'remembered on this phone');
  });

  test('seeing the widget on the home screen is counted once and never offered again, even once removed', () async {
    final store = await started();
    phone.add();
    await store.refresh();
    expect(store.added, isTrue);
    expect(store.offers, isFalse);
    expect(settings.choice.everAdded, isTrue);
    expect(events, ['countdown_widget_added']);

    phone.remove();
    await store.refresh();
    expect(store.added, isFalse);
    expect(store.offers, isFalse, reason: 'they know it exists');

    phone.add();
    await store.refresh();
    expect(events, ['countdown_widget_added'], reason: 'counted once');
  });

  test('a widget added while the app was closed is found when it opens', () async {
    phone.add();
    final store = await started();
    expect(store.added, isTrue);
    expect(store.offers, isFalse);
    expect(settings.choice.everAdded, isTrue);
  });

  test('refresh tells listeners only when something changed', () async {
    final store = await started();
    var heard = 0;
    store.addListener(() => heard++);
    await store.refresh();
    expect(heard, 0);
    phone.add();
    await store.refresh();
    expect(heard, 1);
  });

  test('asking the launcher reports whether it showed its dialog', () async {
    final store = await started();
    expect(await store.requestPin(), isTrue);
    phone.launcherAsks = false;
    expect(await store.requestPin(), isFalse);
    expect(phone.pins, 2);
    expect(events, ['countdown_widget_pin_asked {shown: true}', 'countdown_widget_pin_asked {shown: false}']);
  });

  test('analytics carry only the kind of action', () async {
    final store = await started();
    store.opened('today');
    store.opened('profile');
    expect(events, ['countdown_widget_sheet_opened {from: today}', 'countdown_widget_sheet_opened {from: profile}']);
  });
}
