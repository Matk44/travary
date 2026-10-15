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
import 'package:travary/features/premium/paywall_screen.dart';
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
    expect(find.text('Smart Import'), findsOneWidget);
    expect(find.text('Flight'), findsOneWidget);
    expect(find.text('Passport & documents'), findsOneWidget);
  });

  group('premium', () {
    testWidgets('Smart Import is free to try', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 free to try'), findsOneWidget);

      await tester.tap(find.text('Smart Import'));
      await tester.pumpAndSettle();
      expect(find.text('What shall we read?'), findsOneWidget);
    });

    /// The pass desk's control [key], scrolled into view and tapped.
    Future<void> tapDesk(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
    }

    testWidgets('after the free imports, the paywall is the pass desk: the Annual Pass or a Holiday Pass', (
      tester,
    ) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 2));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Smart Import'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text('Shall I read\nthe rest?', findRichText: true), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding-pass-holiday')), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding-pass-annual')), findsOneWidget);
      // What they reached for leads the benefits; family follows.
      expect(find.text("I'll read the rest of your confirmations for you"), findsOneWidget);
      expect(find.text('Everyone coming gets the plan and their own tickets'), findsOneWidget);
      expect(find.textContaining('free trial', findRichText: true), findsNothing);

      await tapDesk(tester, 'onboarding-pass-annual');
      expect(find.text('Get Annual Pass'), findsOneWidget);
      await tapDesk(tester, 'onboarding-pass-buy');
      expect(find.byType(PaywallScreen), findsNothing);
      expect(find.text('What shall we read?'), findsOneWidget);
    });

    testWidgets('a Holiday Pass says which holiday and dates it covers, and unlocks that trip', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 3));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Smart Import'));
      await tester.pumpAndSettle();

      // Preselected when there's a holiday to attach it to.
      expect(find.text('Get Holiday Pass'), findsOneWidget);
      expect(find.textContaining('Orlando · 12–19 Oct. It covers this holiday until 26 Oct 2026.'), findsOneWidget);
      expect(find.textContaining('Holiday Pass is one payment of'), findsOneWidget);

      await tapDesk(tester, 'onboarding-pass-buy');
      final premium = Provider.of<PremiumStore>(tester.element(find.byType(HomeShell)), listen: false);
      final pass = premium.entitlements.tripPasses.values.single;
      expect((pass.start, pass.end), (LocalDate(2026, 10, 12), LocalDate(2026, 10, 19)));
    });

    testWidgets('the paywall links to the Terms of Use and Privacy Policy', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 3));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Smart Import'));
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
      await tapDesk(tester, 'onboarding-pass-terms');
      await tapDesk(tester, 'onboarding-pass-privacy');
      expect(opened, ['https://travary.app/terms', 'https://travary.app/privacy']);
    });

    testWidgets('closing the paywall changes nothing', (tester) async {
      await pumpApp(tester, DateTime(2026, 10, 14, 11, 0), entitlements: const Entitlements(smartImportsUsed: 3));

      await tester.tap(find.bySemanticsLabel('Add a booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Smart Import'));
      await tester.pumpAndSettle();
      await tapDesk(tester, 'onboarding-pass-free');

      expect(find.byType(PaywallScreen), findsNothing);
      expect(find.text('What shall we read?'), findsNothing);
    });
  });
}
