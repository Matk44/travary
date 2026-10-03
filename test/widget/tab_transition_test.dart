import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/data/demo_data.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/nav_bar.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/wallet/wallet_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';
import '../support/travel_documents.dart';

/// Tabs are pages of one PageView: nav taps slide through every tab in
/// between with a slight overshoot, swiping is off, and each tab keeps its
/// state.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  Future<void> pumpApp(WidgetTester tester) async {
    // The slide paints the Trips rows on the way past; their fixed height
    // needs a wide screen for the test font's wide glyphs (see
    // trips_postcards_test).
    tester.view.physicalSize = const Size(640 * 3, 1000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = MemoryTravelRepository();
    final now = DateTime(2026, 10, 14, 11, 0);
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
              purchases: TestPurchaseService(clock: () => now),
              clock: () => now,
            ),
          ),
          travelDocumentsProvider(),
        ],
        child: MaterialApp(theme: buildTravaryTheme(), home: const HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  PageController pages(WidgetTester tester) => tester.widget<PageView>(find.byType(PageView)).controller!;

  Finder tab(String label) => find.descendant(of: find.byType(TravaryNavBar), matching: find.bySemanticsLabel(label));

  /// Taps [label] and returns the page position at every frame until it settles.
  Future<List<double>> slideTo(WidgetTester tester, String label) async {
    final controller = pages(tester);
    final seen = <double>[];
    await tester.tap(tab(label));
    await tester.pump();
    for (var ms = 0; ms <= 700; ms += 16) {
      seen.add(controller.page!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    seen.add(controller.page!);
    return seen;
  }

  testWidgets('one PageView holds the four tabs, and swiping between them does nothing', (tester) async {
    await pumpApp(tester);
    expect(find.byType(PageView), findsOneWidget);

    await tester.tap(tab('Trips'));
    await tester.pumpAndSettle();
    expect(pages(tester).page, 1);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(pages(tester).page, 1, reason: 'no swipe forward');
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    expect(pages(tester).page, 1, reason: 'no swipe back');
  });

  testWidgets('a far tab sweeps through the ones in between, overshoots, and settles', (tester) async {
    await pumpApp(tester);

    final forward = await slideTo(tester, 'Documents');
    expect(forward.first, 0);
    expect(forward.any((page) => page > 0.9 && page < 1.1), isTrue, reason: 'passes Trips on the way');
    expect(forward.reduce((a, b) => a > b ? a : b), greaterThan(2), reason: 'the bobble overshoots the target');
    expect(forward.last, 2);

    final backward = await slideTo(tester, 'Today');
    expect(backward.first, 2);
    expect(backward.any((page) => page > 0.9 && page < 1.1), isTrue, reason: 'and reverses through Trips');
    expect(backward.last, 0);
  });

  testWidgets('the nav bar highlights the chosen tab at once and does not move with the pages', (tester) async {
    await pumpApp(tester);
    final handle = tester.ensureSemantics();
    final rest = tester.getRect(find.byType(TravaryNavBar));

    await tester.tap(tab('Documents'));
    await tester.pump();
    expect(tester.getSemantics(tab('Documents')), containsSemantics(isSelected: true));
    expect(pages(tester).page, lessThan(0.5), reason: 'the pages have only just started');

    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getRect(find.byType(TravaryNavBar)), rest);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TravaryNavBar)), rest);
    handle.dispose();
  });

  testWidgets('the last tab stops at the edge without a bobble', (tester) async {
    await pumpApp(tester);
    final seen = await slideTo(tester, 'Profile');
    expect(seen.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(3));
    expect(seen.last, 3);
  });

  testWidgets('each tab keeps its scroll position and what was typed while it is away', (tester) async {
    await pumpApp(tester);
    await tester.tap(tab('Documents'));
    await tester.pumpAndSettle();

    final scrollable = find.descendant(of: find.byType(WalletScreen), matching: find.byType(Scrollable)).first;
    ScrollPosition position() => tester.state<ScrollableState>(scrollable).position;
    await tester.drag(scrollable, const Offset(0, -120));
    await tester.pumpAndSettle();
    final scrolled = position().pixels;
    expect(scrolled, greaterThan(0));

    await tester.tap(tab('Today'));
    await tester.pumpAndSettle();
    await tester.tap(tab('Documents'));
    await tester.pumpAndSettle();
    expect(position().pixels, scrolled);

    await tester.enterText(find.byType(TextField), 'sunshine');
    await tester.pumpAndSettle();
    await tester.tap(tab('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(tab('Documents'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'sunshine'), findsOneWidget);
  });

  testWidgets('rapid taps interrupt the slide and nothing jams', (tester) async {
    await pumpApp(tester);
    await tester.tap(tab('Documents'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(tab('Profile'));
    await tester.pump(const Duration(milliseconds: 90));
    await tester.tap(tab('Trips'));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(tab('Today'));
    await tester.pumpAndSettle();

    expect(pages(tester).page, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with reduced motion the tabs change at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester);

    await tester.tap(tab('Documents'));
    await tester.pump();
    expect(pages(tester).page, 2);
  });
}
