import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/pass_badge.dart';
import 'package:travary/design/widgets/trip_hero.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

/// The traveller's pass is tucked onto the postcard of the trip it's on.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  final now = DateTime(2026, 10, 5, 9);
  final japanPass = TripPass(tripId: 'japan', start: d(11, 3), end: d(11, 12));

  Future<void> pump(WidgetTester tester, String tripId, Entitlements entitlements, {DateTime? at}) async {
    final clock = at ?? now;
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll([
        trip('japan', title: 'Japan holiday', plannedStart: d(11, 3), plannedEnd: d(11, 12)),
        trip('lisbon', title: 'Lisbon', plannedStart: d(12, 1), plannedEnd: d(12, 5)),
      ], const []);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), clock: () => clock),
          ),
          ChangeNotifierProvider(
            create: (_) => PremiumStore(
              purchases: TestPurchaseService(clock: () => clock, initial: entitlements),
              clock: () => clock,
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: TripScreen(tripId: tripId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder badge() => find.byKey(const ValueKey('trip-hero-badge'));

  testWidgets('a Holiday Pass sits on the corner of its own trip\'s postcard', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, 'japan', Entitlements(tripPasses: {'japan': japanPass}));
    expect(find.descendant(of: find.byType(TripHero), matching: find.byType(PassBadge)), findsOneWidget);
    expect(tester.widget<PassBadge>(find.byType(PassBadge)).kind, OfferKind.tripPass);
    // Read out with the trip: "Japan holiday, 3 to 12 November 2026, … Holiday Pass active".
    expect(find.bySemanticsLabel(RegExp(r'^Japan holiday,.*\nHoliday Pass active$', dotAll: true)), findsOneWidget);
    // Over the card's top-left corner, not on a row of its own.
    final card = tester.getRect(find.byType(TripHero));
    final pass = tester.getRect(badge());
    expect(pass.left, lessThan(card.left + 24));
    expect(pass.top, lessThan(card.top + 28 + 8));
    expect(pass.bottom, greaterThan(card.top + 28));
    semantics.dispose();
  });

  testWidgets('never on another trip', (tester) async {
    await pump(tester, 'lisbon', Entitlements(tripPasses: {'japan': japanPass}));
    expect(badge(), findsNothing);
  });

  testWidgets('the Annual Pass on every trip', (tester) async {
    await pump(tester, 'lisbon', Entitlements(plus: PlusSubscription(expiresAt: DateTime(2027, 10, 5))));
    expect(tester.widget<PassBadge>(find.byType(PassBadge)).kind, OfferKind.plusAnnual);
  });

  Finder offer() => find.byKey(const ValueKey('trip-holiday-pass'));

  testWidgets('a holiday that can take a Holiday Pass offers its own, and opens its desk', (tester) async {
    await pump(tester, 'lisbon', Entitlements(tripPasses: {'japan': japanPass}));
    await tester.scrollUntilVisible(offer(), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Holiday Pass for Lisbon'), findsOneWidget);
    expect(find.text(r'Unlimited bookings and files, for everyone on it · $14.99 once'), findsOneWidget);
    await tester.tap(offer());
    await tester.pumpAndSettle();
    final paywall = tester.widget<PaywallScreen>(find.byType(PaywallScreen));
    expect((paywall.tripId, paywall.source), ('lisbon', 'trip_page'));
    expect(
      find.descendant(of: find.byKey(const ValueKey('onboarding-pass-holiday')), matching: find.text('Lisbon')),
      findsOneWidget,
      reason: 'the pass names its holiday',
    );
    expect(find.text(' · 1–5 Dec'), findsOneWidget);
  });

  /// The whole trip page built, scrolled to its end, so a missing row is
  /// really missing (the list builds as it scrolls).
  Future<void> toTheEnd(WidgetTester tester) async {
    final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    await tester.drag(list, const Offset(0, -4000));
    await tester.pumpAndSettle();
    final position = tester.state<ScrollableState>(list).position;
    expect(position.pixels, position.maxScrollExtent);
  }

  testWidgets('no offer on a holiday its pass covers', (tester) async {
    await pump(tester, 'japan', Entitlements(tripPasses: {'japan': japanPass}));
    await toTheEnd(tester);
    expect(offer(), findsNothing);
  });

  testWidgets('no offer under the Annual Pass', (tester) async {
    await pump(tester, 'lisbon', Entitlements(plus: PlusSubscription(expiresAt: DateTime(2027, 10, 5))));
    await toTheEnd(tester);
    expect(offer(), findsNothing);
  });

  testWidgets('no offer once the holiday is over', (tester) async {
    await pump(tester, 'lisbon', Entitlements.none, at: DateTime(2026, 12, 6, 9));
    await toTheEnd(tester);
    expect(offer(), findsNothing);
  });

  testWidgets('a free holiday still to come offers one', (tester) async {
    await pump(tester, 'lisbon', Entitlements.none);
    await toTheEnd(tester);
    expect(offer(), findsOneWidget);
  });

  testWidgets('nothing on a free trip', (tester) async {
    await pump(tester, 'lisbon', Entitlements.none);
    expect(badge(), findsNothing);
  });
}
