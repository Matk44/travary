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

/// A Holiday Pass over time, with three holidays coming: it goes on the
/// holiday the desk was opened for (from Profile, the one on now or coming
/// next), never a later or past one; once it ends, the next holiday can
/// have its own.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  // Japan 3–12 Nov, Lisbon 1–5 Dec, Rome 10–14 Jan.
  late DateTime now;
  late TravelStore travel;
  late PremiumStore premium;

  Future<void> pump(WidgetTester tester, Entitlements entitlements) async {
    tester.view.physicalSize = const Size(430, 932) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll([
        trip('japan', title: 'Japan holiday', plannedStart: d(11, 3), plannedEnd: d(11, 12)),
        trip('lisbon', title: 'Lisbon', plannedStart: d(12, 1), plannedEnd: d(12, 5)),
        trip('rome', title: 'Rome', plannedStart: LocalDate(2027, 1, 10), plannedEnd: LocalDate(2027, 1, 14)),
      ], const []);
    travel = TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), clock: () => now);
    premium = PremiumStore(
      purchases: TestPurchaseService(clock: () => now, initial: entitlements),
      clock: () => now,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  /// Profile's "See the Annual Pass": the desk for the holiday on now or next.
  Future<String> openFromProfile(WidgetTester tester) async {
    final tripId = travel.focus.plan!.id;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: travel),
          ChangeNotifierProvider.value(value: premium),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: PaywallScreen(tripId: tripId, source: 'profile'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tripId;
  }

  Finder holidayTicket() => find.byKey(const ValueKey('onboarding-pass-holiday'));

  Future<void> buyHolidayPass(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('onboarding-pass-buy')));
    await tester.tap(find.byKey(const ValueKey('onboarding-pass-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pass-confirmed-badge')), findsOneWidget);
  }

  bool covered(String id) => premium.policy.forTrip(travel.plan(id)).allowed;

  /// Off the screen, and the stores (and their timers) gone.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    travel.dispose();
    premium.dispose();
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets('bought from Profile it goes on the holiday coming next, never a later one', (tester) async {
    now = DateTime(2026, 10, 5, 9);
    await pump(tester, Entitlements.none);
    expect(await openFromProfile(tester), 'japan');
    expect(holidayTicket(), findsOneWidget);
    await buyHolidayPass(tester);
    expect(premium.entitlements.tripPasses.keys, ['japan']);
    expect(premium.entitlements.tripPasses['japan'], TripPass(tripId: 'japan', start: d(11, 3), end: d(11, 12)));
    expect([covered('japan'), covered('lisbon'), covered('rome')], [true, false, false]);
    await finish(tester);
  });

  testWidgets('while it\'s on, Profile offers the Annual Pass; a later holiday can still have its own', (tester) async {
    now = DateTime(2026, 10, 5, 9);
    await pump(
      tester,
      Entitlements(
        tripPasses: {'japan': TripPass(tripId: 'japan', start: d(11, 3), end: d(11, 12))},
      ),
    );
    await openFromProfile(tester);
    expect(holidayTicket(), findsNothing, reason: 'Japan has one: the Annual Pass is the upgrade');
    expect(premium.policy.canBuyTripPassFor(travel.plan('lisbon')), isTrue, reason: 'from Lisbon\'s own desk');
    expect(premium.policy.canBuyTripPassFor(travel.plan('rome')), isTrue);
    await finish(tester);
  });

  testWidgets('a week after the holiday ends the pass is over, and the next holiday can have one', (tester) async {
    final japanPass = TripPass(tripId: 'japan', start: d(11, 3), end: d(11, 12));
    now = DateTime(2026, 11, 19, 20);
    await pump(tester, Entitlements(tripPasses: {'japan': japanPass}));
    expect(covered('japan'), isTrue, reason: 'still on until the end of the 19th');
    await finish(tester);

    now = DateTime(2026, 11, 20, 9);
    await pump(tester, Entitlements(tripPasses: {'japan': japanPass}));
    expect(covered('japan'), isFalse);
    expect(premium.policy.canBuyTripPassFor(travel.plan('japan')), isFalse, reason: 'a holiday that has ended');
    expect(await openFromProfile(tester), 'lisbon', reason: 'Profile moves on to the next holiday');
    expect(holidayTicket(), findsOneWidget);
    await buyHolidayPass(tester);
    expect(premium.entitlements.tripPasses.keys, unorderedEquals(['japan', 'lisbon']));
    expect([covered('lisbon'), covered('rome')], [true, false]);
    await finish(tester);
  });
}
