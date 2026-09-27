import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/data/demo_data.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  Future<void> pumpApp(WidgetTester tester, DateTime now, {Entitlements entitlements = Entitlements.none}) async {
    // An iPhone-sized screen.
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = MemoryTravelRepository();
    final demo = buildDemoData(LocalDate.fromDateTime(now), userId: repository.userId);
    repository.replaceAll(demo.trips, demo.bookings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(
              repository: repository,
              artCatalog: const ArtCatalog.empty(),
              clock: () => now,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => PremiumStore(
              purchases: TestPurchaseService(initial: entitlements, clock: () => now),
              clock: () => now,
            ),
          ),
        ],
        child: MaterialApp(theme: buildTravaryTheme(), home: const HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Today shows day 3 of the demo trip with the park happening now', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 14, 11, 0));

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Day 3 of 8 · Orlando'), findsOneWidget);
    expect(find.text('HAPPENING NOW'), findsOneWidget);
    expect(find.text('Sunshine Park'), findsOneWidget);
    expect(find.text('Lagoon Resort · Room 2214'), findsOneWidget);
  });

  testWidgets('in the afternoon dinner is next up and earlier items are done', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 14, 14, 30));

    expect(find.text('Good afternoon'), findsOneWidget);
    expect(find.text('NEXT UP'), findsOneWidget);
    expect(find.text('Lagoon Grill'), findsOneWidget);
    expect(find.text('EARLIER (2)'), findsOneWidget);
    expect(find.text('Sunshine Park'), findsNothing);

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('Sunshine Park'), findsOneWidget);
  });

  testWidgets('tapping another day in the strip shows that day', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 14, 11, 0));

    await tester.tap(find.bySemanticsLabel('Thursday 15 October'));
    await tester.pumpAndSettle();

    expect(find.text('Everglades airboat tour'), findsOneWidget);
    expect(find.textContaining('Day 4 of 8'), findsOneWidget);
  });

  testWidgets('Wallet search finds a booking by reference', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 14, 11, 0));

    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'CIR-30412');
    await tester.pumpAndSettle();

    expect(find.text('Evening Circus Show'), findsOneWidget);
    expect(find.text('Sunshine Terrace'), findsNothing);
  });

  testWidgets('the add button opens the kind picker', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 14, 11, 0));

    await tester.tap(find.bySemanticsLabel('Add a booking'));
    await tester.pumpAndSettle();

    expect(find.text('What have you booked?'), findsOneWidget);
    expect(find.text('Flight'), findsOneWidget);
  });

  group('premium', () {
    testWidgets('Smart Import is free to try', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      expect(find.text('3 free to try'), findsOneWidget);

      await tester.tap(find.text('Import a screenshot or PDF'));
      await tester.pumpAndSettle();
      expect(find.text('Smart Import is on its way'), findsOneWidget);
    });

    testWidgets('after the free imports, the paywall offers Plus and a Trip Pass, and buying unlocks it', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 3));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import a screenshot or PDF'));
      await tester.pumpAndSettle();

      expect(find.text('Skip the typing'), findsOneWidget);
      expect(find.text(r'Free for 14 days, then $34.99/year'), findsOneWidget);
      expect(find.text('Just Orlando'), findsOneWidget);
      expect(find.text('HOW YOUR FREE TRIAL WORKS'), findsOneWidget);
      expect(find.text('Start my free 14 days'), findsOneWidget);

      await tester.tap(find.text('Start my free 14 days'));
      await tester.pumpAndSettle();
      expect(find.text('Smart Import is on its way'), findsOneWidget);
    });

    testWidgets('choosing the Trip Pass explains it and prices it per day', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 3));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import a screenshot or PDF'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Just Orlando'));
      await tester.pumpAndSettle();

      // 8-day trip: $7.99 / 8 = $1.00 a day.
      expect(find.textContaining(r'$1.00 a day'), findsOneWidget);
      expect(find.text(r'Get Trip Pass · $7.99'), findsOneWidget);
      expect(find.textContaining('One payment, no subscription.'), findsOneWidget);
    });

    testWidgets('closing the paywall changes nothing', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 3));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import a screenshot or PDF'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('Skip the typing'), findsNothing);
      expect(find.text('Smart Import is on its way'), findsNothing);
    });
  });
}
