import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/reminder_scheduler.dart';
import 'package:travary/data/reminder_settings.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/reminders_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

void main() {
  late MemoryTravelRepository repository;
  late TravelStore travel;
  late MemoryReminderScheduler scheduler;
  late MemoryReminderSettings settings;
  late RemindersStore reminders;

  Future<void> start({bool permitted = false, bool grants = true, ReminderChoice? choice}) async {
    scheduler = MemoryReminderScheduler(permitted: permitted, grants: grants);
    settings = MemoryReminderSettings(choice ?? (on: false, declined: false));
    reminders = RemindersStore(scheduler: scheduler, settings: settings, travel: travel);
    await reminders.start();
  }

  setUp(() async {
    repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [trip('orlando', title: 'Orlando')],
        [
          booking('park', BookingKind.attraction, d(10, 15), tripId: 'orlando', at: const ClockTime(9, 30)),
          booking('dinner', BookingKind.dining, d(10, 15), tripId: 'orlando', at: const ClockTime(19, 0)),
        ],
      );
    travel = TravelStore(
      repository: repository,
      artCatalog: const ArtCatalog.empty(),
      clock: () => DateTime(2026, 10, 13, 20),
    );
    await pumpEventQueue();
  });

  tearDown(() {
    reminders.dispose();
    travel.dispose();
  });

  test('a trip with a booking offers reminders; nothing is set until they are on', () async {
    await start();
    expect(reminders.offersFor(travel.plan('orlando')!), isTrue);
    expect(reminders.on, isFalse);
    expect(scheduler.set, isEmpty);
    expect(scheduler.asked, 0, reason: 'never asked at launch');
  });

  test('yes asks the phone once, then sets the trip\'s reminders', () async {
    await start();
    expect(await reminders.turnOn(), isTrue);
    expect(scheduler.asked, 1);
    expect(reminders.on, isTrue);
    expect(reminders.offersFor(travel.plan('orlando')!), isFalse);
    expect(settings.choice, (on: true, declined: false));
    expect(scheduler.set.map((r) => r.opens), ['day:2026-10-15', 'booking:park', 'booking:dinner']);
  });

  test('a phone that already allows notifications isn\'t asked again', () async {
    await start(permitted: true);
    await reminders.turnOn();
    expect(scheduler.asked, 0);
    expect(reminders.on, isTrue);
  });

  test('a refusal at the phone\'s prompt leaves them blocked, and nothing set', () async {
    await start(grants: false);
    expect(await reminders.turnOn(), isFalse);
    expect(reminders.on, isFalse);
    expect(reminders.blocked, isTrue);
    expect(scheduler.set, isEmpty);
    // Turned on in Settings later: back in the app, they're set.
    scheduler.permitted = true;
    await reminders.refresh();
    expect(reminders.on, isTrue);
    expect(scheduler.set, isNotEmpty);
  });

  test('"Not now" puts the offer away for good; turning off clears what was set', () async {
    await start();
    await reminders.decline();
    expect(reminders.offersFor(travel.plan('orlando')!), isFalse);
    expect(settings.choice.declined, isTrue);

    await reminders.turnOn();
    expect(scheduler.set, isNotEmpty);
    await reminders.turnOff();
    expect(scheduler.set, isEmpty);
    expect(settings.choice.on, isFalse);
  });

  test('on from before: set at start; a tapped reminder is opened once', () async {
    scheduler = MemoryReminderScheduler(permitted: true)..launch = 'booking:park';
    settings = MemoryReminderSettings((on: true, declined: false));
    reminders = RemindersStore(scheduler: scheduler, settings: settings, travel: travel);
    await reminders.start();
    expect(scheduler.set, hasLength(3));
    expect(reminders.takeToOpen(), 'booking:park');
    expect(reminders.takeToOpen(), isNull);
    scheduler.tap('day:2026-10-15');
    await pumpEventQueue();
    expect(reminders.takeToOpen(), 'day:2026-10-15');
  });

  test('previewing a different time never sets reminders for it', () async {
    await start(permitted: true, choice: (on: true, declined: false));
    final before = scheduler.set;
    travel.previewNow = DateTime(2026, 10, 15, 12);
    await reminders.refresh();
    expect(scheduler.set, same(before));
  });
}
