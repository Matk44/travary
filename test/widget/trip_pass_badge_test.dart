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
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

/// The traveller's pass is tucked onto the postcard of the trip it's on.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  final now = DateTime(2026, 10, 5, 9);
  final japanPass = TripPass(tripId: 'japan', start: d(11, 3), end: d(11, 12));

  Future<void> pump(WidgetTester tester, String tripId, Entitlements entitlements) async {
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
            create: (_) => TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), clock: () => now),
          ),
          ChangeNotifierProvider(
            create: (_) => PremiumStore(
              purchases: TestPurchaseService(clock: () => now, initial: entitlements),
              clock: () => now,
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

  testWidgets('nothing on a free trip', (tester) async {
    await pump(tester, 'lisbon', Entitlements.none);
    expect(badge(), findsNothing);
  });
}
