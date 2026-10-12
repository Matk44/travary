import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

import '../support/open_tab.dart';
import '../support/travel_documents.dart';
import '../support/session.dart';

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
            create: (_) => TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), clock: () => now),
          ),
          ChangeNotifierProvider(
            create: (_) => PremiumStore(
              purchases: TestPurchaseService(initial: entitlements, clock: () => now),
              clock: () => now,
            ),
          ),
          appSessionProvider(),
          travelDocumentsProvider(),
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
    // The hotel you're staying at, with its room and the countdown.
    expect(find.text('Lagoon Resort'), findsOneWidget);
    expect(find.text('Room 2214 · Check-out in 4 days'), findsOneWidget);
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

  testWidgets('choosing another day from the trip calendar shows that day', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 14, 11, 0));

    await tester.tap(find.text('Day 3 of 8 · Orlando'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Day 4 of 8, Thursday 15 October'));
    await tester.pumpAndSettle();

    expect(find.text('Everglades airboat tour'), findsOneWidget);
    expect(find.textContaining('Day 4 of 8'), findsOneWidget);
  });

  testWidgets('Documents search finds a booking by reference', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 14, 11, 0));

    await openTab(tester, 'Documents');
    await tester.enterText(find.byType(TextField), 'CIR-30412');
    await tester.pumpAndSettle();

    expect(find.text('Evening Circus Show'), findsOneWidget);
    expect(find.text('Sunshine Terrace'), findsNothing);
  });

  testWidgets('the add button opens the kind picker', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 14, 11, 0));

    await tester.tap(find.bySemanticsLabel('Add a booking'));
    await tester.pumpAndSettle();

    expect(find.text('Add a booking'), findsOneWidget);
    expect(find.text('Snap a booking'), findsOneWidget);
    expect(find.text('Flight'), findsOneWidget);
    expect(find.text('Passport & documents'), findsOneWidget);
  });

  group('premium', () {
    testWidgets('Smart Import is free to try', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 free to try'), findsOneWidget);

      await tester.tap(find.text('Snap a booking'));
      await tester.pumpAndSettle();
      expect(find.text('What shall we read?'), findsOneWidget);
    });

    testWidgets('after the free imports, the paywall offers Plus and a Trip Pass, and buying unlocks it', (
      tester,
    ) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 3));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Snap a booking'));
      await tester.pumpAndSettle();

      expect(find.text('Skip the typing'), findsOneWidget);
      expect(find.text(r'$34.99/year'), findsOneWidget);
      expect(find.text('Just Orlando'), findsOneWidget);
      expect(find.textContaining('free trial', findRichText: true), findsNothing);
      expect(find.text(r'Get Travary Plus · $34.99/year'), findsOneWidget);

      await tester.tap(find.text(r'Get Travary Plus · $34.99/year'));
      await tester.pumpAndSettle();
      expect(find.text('What shall we read?'), findsOneWidget);
    });

    testWidgets('choosing the Trip Pass explains it and prices it per day', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 3));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Snap a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Just Orlando'));
      await tester.pumpAndSettle();

      // 8-day trip: $14.99 / 8 = $1.87 a day.
      expect(find.textContaining(r'$1.87 a day'), findsOneWidget);
      expect(find.text(r'Get Trip Pass · $14.99'), findsOneWidget);
      // It says which dates it covers: the trip's now, which later edits
      // never move.
      expect(
        find.text(
          'One payment, no subscription. Unlocks Plus on Orlando (12–19 Oct) for everyone on the trip, '
          'until 26 Oct 2026. Only one of you needs to buy it.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(r'Get Trip Pass · $14.99'));
      await tester.pumpAndSettle();
      final premium = Provider.of<PremiumStore>(tester.element(find.byType(HomeShell)), listen: false);
      final pass = premium.entitlements.tripPasses.values.single;
      expect((pass.start, pass.end), (LocalDate(2026, 10, 12), LocalDate(2026, 10, 19)));
    });

    testWidgets('the paywall links to the Terms of Use and Privacy Policy', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 3));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Snap a booking'));
      await tester.pumpAndSettle();

      final opened = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async {
          opened.add((call.arguments as Map)['url']);
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('paywall-terms')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('paywall-privacy')));
      await tester.pumpAndSettle();
      expect(opened, [
        'https://matk44.github.io/travary_support/terms.html',
        'https://matk44.github.io/travary_support/privacy.html',
      ]);
    });

    testWidgets('closing the paywall changes nothing', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 3));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Snap a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('Skip the typing'), findsNothing);
      expect(find.text('What shall we read?'), findsNothing);
    });
  });
}
