import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/logic/price_text.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

/// A Holiday Pass is for one holiday: the pass desk says so, and still
/// offers the Annual Pass to someone who holds one.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  final now = DateTime(2026, 10, 5, 9);
  final japanPass = TripPass(tripId: 'japan', start: d(11, 3), end: d(11, 12));

  Future<void> pump(WidgetTester tester, String tripId, Entitlements entitlements) async {
    tester.view.physicalSize = const Size(430, 932) * 3;
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
          home: PaywallScreen(tripId: tripId, source: 'profile'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder holidayTicket() => find.byKey(const ValueKey('onboarding-pass-holiday'));
  Finder annualTicket() => find.byKey(const ValueKey('onboarding-pass-annual'));

  testWidgets('a holiday covered by its own Holiday Pass offers the Annual Pass, saying why', (tester) async {
    await pump(tester, 'japan', Entitlements(tripPasses: {'japan': japanPass}));
    expect(find.textContaining('already covered. Let'), findsNothing, reason: 'not a dead end');
    expect(holidayTicket(), findsNothing, reason: 'it has one');
    expect(annualTicket(), findsOneWidget);
    expect(find.text(annualUpgradeText('Japan holiday')), findsOneWidget);
    expect(find.text('Get Annual Pass'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('onboarding-pass-buy')));
    await tester.tap(find.byKey(const ValueKey('onboarding-pass-buy')));
    await tester.pumpAndSettle();
    expect(find.text('Every holiday,\nsorted!', findRichText: true), findsOneWidget);
    expect(tester.element(find.byType(PaywallScreen)).read<PremiumStore>().hasPlus, isTrue);
  });

  testWidgets('a holiday without one says which holiday the pass covers, and sells its own', (tester) async {
    await pump(tester, 'lisbon', Entitlements(tripPasses: {'japan': japanPass}));
    expect(find.text(holidayPassElsewhereText('Japan holiday')), findsOneWidget);
    expect(holidayTicket(), findsOneWidget);
    expect(annualTicket(), findsOneWidget);
  });

  testWidgets('nothing to sell with the Annual Pass', (tester) async {
    await pump(tester, 'lisbon', Entitlements(plus: PlusSubscription(expiresAt: DateTime(2027, 10, 5))));
    expect(holidayTicket(), findsNothing);
    expect(annualTicket(), findsNothing);
    expect(find.text('Open my holiday'), findsOneWidget);
  });
}
