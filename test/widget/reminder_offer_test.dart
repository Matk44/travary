import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/reminder_scheduler.dart';
import 'package:travary/data/reminder_settings.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/reminders/reminder_offer.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/reminders_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  late MemoryReminderScheduler scheduler;
  late MemoryReminderSettings settings;

  Future<void> pump(
    WidgetTester tester, {
    bool grants = true,
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    scheduler = MemoryReminderScheduler(grants: grants);
    settings = MemoryReminderSettings();
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [trip('jp', title: 'Japan', plannedStart: d(10, 11), plannedEnd: d(10, 16))],
        [booking('museum', BookingKind.attraction, d(10, 12), tripId: 'jp', at: const ClockTime(15, 0))],
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(
              repository: repository,
              artCatalog: const ArtCatalog.empty(),
              clock: () => DateTime(2026, 10, 5, 9),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
          ChangeNotifierProvider(
            create: (context) =>
                RemindersStore(scheduler: scheduler, settings: settings, travel: context.read<TravelStore>())..start(),
          ),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const TripScreen(tripId: 'jp'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The trip's list builds as it scrolls: down to the offer.
  Future<void> reach(WidgetTester tester, String key) async {
    await tester.scrollUntilVisible(
      find.byKey(ValueKey(key)),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapOffer(WidgetTester tester, String key) async {
    await reach(tester, key);
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('a trip with a booking offers a nudge each morning; yes asks once and sets them', (tester) async {
    await pump(tester);
    await reach(tester, 'reminders-yes');
    expect(find.byType(ReminderOffer), findsOneWidget);
    expect(scheduler.asked, 0, reason: 'only the yes asks the phone');

    await tapOffer(tester, 'reminders-yes');
    expect(scheduler.asked, 1);
    expect(scheduler.set, isNotEmpty);
    expect(find.byType(ReminderOffer), findsNothing);
  });

  testWidgets('not now puts it away for good', (tester) async {
    await pump(tester);
    await tapOffer(tester, 'reminders-not-now');
    expect(find.byType(ReminderOffer), findsNothing);
    expect(settings.choice.declined, isTrue);
    expect(scheduler.asked, 0);
  });

  testWidgets('refused at the phone\'s prompt: says where to turn them on', (tester) async {
    await pump(tester, grants: false);
    await tapOffer(tester, 'reminders-yes');
    expect(find.textContaining('turn them on in Settings'), findsOneWidget);
    expect(scheduler.set, isEmpty);
  });

  testWidgets('a small phone with large text fits the offer', (tester) async {
    await pump(tester, size: const Size(320, 568), scale: 1.6);
    await reach(tester, 'reminders-yes');
    expect(tester.takeException(), isNull);
  });
}
