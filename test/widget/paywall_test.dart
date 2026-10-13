import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  testWidgets('a trip longer than a Holiday Pass covers is offered the Annual Pass only, and told why', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 10, 5, 9);
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll([trip('gap', title: 'Gap year', plannedStart: d(11, 1), plannedEnd: d(12, 31))], const []);
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
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: const PaywallScreen(feature: PremiumFeature.familySharing, tripId: 'gap', source: 'test'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The pass desk, on the paywall: family sharing leads its benefits.
    expect(find.text('Bring everyone\nalong?', findRichText: true), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-pass-annual')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-pass-holiday')), findsNothing);
    expect(
      find.text('Holiday Pass covers trips of up to 30 days. Your longer holiday can use the Annual Pass.'),
      findsOneWidget,
    );
    expect(find.text('Not now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
