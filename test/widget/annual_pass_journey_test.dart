import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/pass_badge.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/features/premium/premium_gate.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/logic/price_text.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

/// The Annual Pass bought on its own, and bought over a Holiday Pass: the
/// desk confirms it, every holiday wears its badge, and nothing is lost.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  final now = DateTime(2026, 10, 5, 9);
  final japanPass = TripPass(tripId: 'japan', start: d(11, 3), end: d(11, 12));
  late PremiumStore premium;
  late TravelStore travel;

  /// Japan (3–12 Nov) and Lisbon (1–5 Dec, its 12 free bookings used), on
  /// [tripId]'s page.
  Future<void> pump(WidgetTester tester, Entitlements entitlements, {String tripId = 'japan'}) async {
    tester.view.physicalSize = const Size(430, 932) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [
          trip('japan', title: 'Japan holiday', plannedStart: d(11, 3), plannedEnd: d(11, 12)),
          trip('lisbon', title: 'Lisbon', plannedStart: d(12, 1), plannedEnd: d(12, 5)),
        ],
        [for (var i = 0; i < 12; i++) booking('b$i', BookingKind.dining, d(12, 1 + i % 5), tripId: 'lisbon')],
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                travel = TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), clock: () => now),
          ),
          ChangeNotifierProvider(
            create: (_) => premium = PremiumStore(
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

  /// Profile's "See the Annual Pass" opens the desk for the trip on show.
  Future<void> openDesk(WidgetTester tester, String tripId) async {
    showPaywall(tester.element(find.byType(TripScreen)), tripId: tripId, source: 'profile');
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsOneWidget);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  OfferKind? badgeOnTrip(WidgetTester tester) {
    final badge = find.descendant(of: find.byType(TripScreen), matching: find.byType(PassBadge));
    return badge.evaluate().isEmpty ? null : tester.widget<PassBadge>(badge).kind;
  }

  void expectEveryHolidayUnlimited() {
    for (final id in ['japan', 'lisbon']) {
      final plan = travel.plan(id)!;
      expect(premium.policy.bookingsLeft(plan), isNull, reason: id);
      expect(premium.policy.canAttachTickets(plan, kept: 9), isTrue, reason: id);
      expect(premium.policy.purchasedPassFor(plan), OfferKind.plusAnnual, reason: id);
    }
  }

  testWidgets('bought on its own: confirmed, and every holiday wears it', (tester) async {
    await pump(tester, Entitlements.none);
    expect(badgeOnTrip(tester), isNull);
    await openDesk(tester, 'japan');
    expect(find.byKey(const ValueKey('onboarding-pass-holiday')), findsOneWidget, reason: 'both on offer');
    await tap(tester, 'onboarding-pass-annual');
    await tap(tester, 'onboarding-pass-buy');

    expect(find.text('Every holiday,\nsorted!', findRichText: true), findsOneWidget);
    expect(tester.widget<PassBadge>(find.byKey(const ValueKey('pass-confirmed-badge'))).kind, OfferKind.plusAnnual);
    expect(find.text('Every holiday'), findsOneWidget);
    expect(find.text('Renews on 5 Oct 2027 · cancel anytime'), findsOneWidget);
    await tap(tester, 'pass-confirmed-done');

    expect(find.byType(PaywallScreen), findsNothing);
    expect(badgeOnTrip(tester), OfferKind.plusAnnual);
    expectEveryHolidayUnlimited();
    expect(premium.entitlements.tripPasses, isEmpty);
  });

  testWidgets('bought over a Holiday Pass: offered as the upgrade, then every holiday wears it', (tester) async {
    await pump(tester, Entitlements(tripPasses: {'japan': japanPass}));
    expect(badgeOnTrip(tester), OfferKind.tripPass);
    expect(premium.policy.bookingsLeft(travel.plan('lisbon')!), 0, reason: 'the pass is for Japan only');

    await openDesk(tester, 'japan');
    expect(find.byKey(const ValueKey('onboarding-pass-holiday')), findsNothing, reason: 'it has one');
    expect(find.text(annualUpgradeText('Japan holiday')), findsOneWidget);
    await tap(tester, 'onboarding-pass-buy');

    expect(find.text('Every holiday,\nsorted!', findRichText: true), findsOneWidget);
    expect(tester.widget<PassBadge>(find.byKey(const ValueKey('pass-confirmed-badge'))).kind, OfferKind.plusAnnual);
    await tap(tester, 'pass-confirmed-done');

    // The Annual Pass leads wherever both cover a holiday; the Holiday Pass
    // is kept, and would show again should the Annual Pass end first.
    expect(badgeOnTrip(tester), OfferKind.plusAnnual);
    expectEveryHolidayUnlimited();
    expect(premium.entitlements.tripPasses.keys, ['japan']);
  });

  testWidgets('bought over a Holiday Pass from another holiday, the one that needed it', (tester) async {
    await pump(tester, Entitlements(tripPasses: {'japan': japanPass}), tripId: 'lisbon');
    expect(badgeOnTrip(tester), isNull);
    await openDesk(tester, 'lisbon');
    expect(find.text(holidayPassElsewhereText('Japan holiday')), findsOneWidget);
    await tap(tester, 'onboarding-pass-annual');
    await tap(tester, 'onboarding-pass-buy');
    expect(find.text('Every holiday,\nsorted!', findRichText: true), findsOneWidget);
    await tap(tester, 'pass-confirmed-done');
    expect(badgeOnTrip(tester), OfferKind.plusAnnual);
    expectEveryHolidayUnlimited();
  });
}
