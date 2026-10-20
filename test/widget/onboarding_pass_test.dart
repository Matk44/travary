import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/onboarding_pass_desk.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/onboarding/onboarding_pass_screen.dart';
import 'package:travary/logic/destinations.dart';
import 'package:travary/logic/price_text.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

class _Purchases extends TestPurchaseService {
  _Purchases() : super(clock: () => DateTime(2026, 10, 6));
  final calls = <({Offer offer, TripPass? pass})>[];
  PurchaseOutcome outcome = PurchaseOutcome.purchased;
  Completer<void>? waiting;
  Entitlements? restored;
  bool restoreFails = false;
  List<Offer> catalog = const [
    Offer(kind: OfferKind.tripPass, productId: 'holiday-live', amount: 19.25, currencyCode: 'USD'),
    Offer(kind: OfferKind.plusAnnual, productId: 'annual-live', amount: 49.50, currencyCode: 'USD'),
  ];

  @override
  Future<List<Offer>> loadOffers() async => catalog;

  @override
  Future<PurchaseOutcome> purchase(Offer offer, {TripPass? tripPass}) async {
    calls.add((offer: offer, pass: tripPass));
    await waiting?.future;
    return outcome == PurchaseOutcome.purchased ? super.purchase(offer, tripPass: tripPass) : outcome;
  }

  @override
  Future<void> restore() async {
    if (restoreFails) throw StateError('Offline');
    if (restored != null) set(restored!);
  }
}

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);
  late MemoryTravelRepository repository;
  late _Purchases purchases;
  OnboardingPassOutcome? result;

  Trip holiday({LocalDate? end, TripPremium? premium}) => Trip(
    id: 'holiday',
    title: 'Bali holiday',
    destination: detectPlace('Bali')!.destination,
    plannedStart: d(11, 8),
    plannedEnd: end ?? d(11, 15),
    ownerId: 'me',
    memberIds: const ['me'],
    premium: premium,
    createdAt: DateTime(2026, 10, 6),
    updatedAt: DateTime(2026, 10, 6),
  );

  Future<void> pump(
    WidgetTester tester, {
    Trip? plan,
    bool proof = true,
    bool withoutBooking = false,
    bool noHoliday = false,
    Size size = const Size(390, 844),
    double scale = 1,
    bool reduced = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    result = null;
    purchases = _Purchases();
    repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [if (!noHoliday) plan ?? holiday()],
        [
          if (proof && !withoutBooking && !noHoliday)
            booking(
              'first',
              BookingKind.stay,
              d(11, 8),
              title: 'Lagoon Retreat',
              tripId: 'holiday',
              endDate: d(11, 17),
            ),
        ],
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(
              repository: repository,
              artCatalog: const ArtCatalog.empty(),
              clock: () => DateTime(2026, 10, 6),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => PremiumStore(purchases: purchases, clock: () => DateTime(2026, 10, 6)),
          ),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced, textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await Navigator.of(context).push<OnboardingPassOutcome>(
                  MaterialPageRoute(
                    builder: (_) => OnboardingPassScreen(
                      tripId: noHoliday ? null : 'holiday',
                      bookingId: withoutBooking || noHoliday ? null : 'first',
                    ),
                  ),
                ),
                child: const Text('Open desk'),
              ),
            ),
          ),
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await purchases.dispose();
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open desk'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        250,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('onboarding-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// A pass just bought: the desk confirms it (its badge, what it covers)
  /// and hands back only when asked.
  Future<void> carryOn(WidgetTester tester) async {
    expect(result, isNull, reason: 'the desk confirms the pass before handing back');
    expect(find.byKey(const ValueKey('pass-confirmed-badge')), findsOneWidget);
    expect(find.byType(OnboardingPaperPass), findsNothing);
    await tap(tester, 'pass-confirmed-done');
  }

  testWidgets('live offers and selected Holiday Pass purchase cover the actual saved holiday', (tester) async {
    await pump(tester);
    expect(find.text(r'$19.25 once'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('onboarding-pass-annual')));
    expect(find.text(r'$49.50 / year'), findsOneWidget);
    expect(tester.widget<OnboardingPaperPass>(find.byKey(const ValueKey('onboarding-pass-holiday'))).selected, isTrue);
    expect(find.textContaining('Flight alerts'), findsNothing);
    expect(find.text('Test store: nothing is charged.'), findsOneWidget);
    await tap(tester, 'onboarding-pass-buy');
    expect(find.text('Enjoy your\nholiday!', findRichText: true), findsOneWidget);
    expect(find.text('8–17 Nov · covered until 24 Nov 2026'), findsOneWidget);
    await carryOn(tester);
    expect(result, OnboardingPassOutcome.upgraded);
    expect(purchases.calls.single.offer.productId, 'holiday-live');
    expect(purchases.calls.single.pass, TripPass(tripId: 'holiday', start: d(11, 8), end: d(11, 17)));
    expect(repository.bookings.single.title, 'Lagoon Retreat');
    expect(repository.trips, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('free and Back have separate outcomes and preserve the booking', (tester) async {
    await pump(tester);
    await tap(tester, 'onboarding-pass-back');
    expect(result, isNull);
    expect(find.text('Open desk'), findsOneWidget);
    await tester.tap(find.text('Open desk'));
    await tester.pumpAndSettle();
    await tap(tester, 'onboarding-pass-free');
    expect(result, OnboardingPassOutcome.free);
    expect(purchases.calls, isEmpty);
    expect(repository.bookings, hasLength(1));
  });

  testWidgets('Annual Pass uses annual billing and prevents duplicate taps while buying', (tester) async {
    await pump(tester);
    await tap(tester, 'onboarding-pass-annual');
    expect(find.textContaining('renews at \$49.50 each year'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('onboarding-pass-buy')));
    await tester.pumpAndSettle();
    purchases.waiting = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('onboarding-pass-buy')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding-pass-buy')));
    await tester.pump();
    expect(purchases.calls, hasLength(1));
    expect(purchases.calls.single.offer.kind, OfferKind.plusAnnual);
    expect(purchases.calls.single.pass, isNull);
    expect(tester.widget<TextButton>(find.byKey(const ValueKey('onboarding-pass-free'))).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byKey(const ValueKey('onboarding-pass-back'))).onPressed, isNull);
    expect(tester.widget<OnboardingPaperPass>(find.byKey(const ValueKey('onboarding-pass-annual'))).onTap, isNull);
    purchases.waiting!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Every holiday,\nsorted!', findRichText: true), findsOneWidget);
    await carryOn(tester);
    expect(result, OnboardingPassOutcome.upgraded);
  });

  testWidgets('remote copy and localized price refresh without an artwork or product-code change', (tester) async {
    await pump(tester);
    purchases.catalog = const [
      Offer(
        kind: OfferKind.tripPass,
        productId: 'new-holiday-product',
        amount: 22.49,
        currencyCode: 'EUR',
        localizedPrice: '22,49 €',
        title: 'Adventure Pass',
        scope: 'Your upcoming escape',
        packageId: 'new-holiday-package',
        offeringId: 'summer',
      ),
    ];
    await tester.element(find.byType(OnboardingPassScreen)).read<PremiumStore>().refreshOffers();
    await tester.pumpAndSettle();
    // The price and scope come from the store; the name is always the app's.
    expect(find.text('HOLIDAY PASS'), findsOneWidget);
    expect(find.text('ADVENTURE PASS'), findsNothing);
    expect(find.text('Your upcoming escape'), findsOneWidget);
    expect(find.text('22,49 € once'), findsOneWidget);
    expect(find.text('Get Holiday Pass'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-pass-annual')), findsNothing);
    expect(find.textContaining('US'), findsNothing);
    await tap(tester, 'onboarding-pass-buy');
    expect(purchases.calls.single.offer.productId, 'new-holiday-product');
    expect(purchases.calls.single.offer.packageId, 'new-holiday-package');
    expect(purchases.calls.single.offer.offeringId, 'summer');
    await carryOn(tester);
    expect(result, OnboardingPassOutcome.upgraded);
  });

  testWidgets('a remotely removed selected pass needs a deliberate new selection', (tester) async {
    await pump(tester);
    purchases.catalog = [purchases.catalog.last];
    await tester.element(find.byType(OnboardingPassScreen)).read<PremiumStore>().refreshOffers();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding-pass-holiday')), findsNothing);
    expect(tester.widget<OnboardingPaperPass>(find.byKey(const ValueKey('onboarding-pass-annual'))).selected, isFalse);
    expect(find.text('Choose a pass'), findsOneWidget);
    await tap(tester, 'onboarding-pass-buy');
    expect(purchases.calls, isEmpty);
    await tap(tester, 'onboarding-pass-annual');
    await tap(tester, 'onboarding-pass-buy');
    expect(purchases.calls.single.offer.productId, 'annual-live');
  });

  testWidgets('cancelled and failed purchases keep a free continuation and saved data', (tester) async {
    await pump(tester);
    purchases.outcome = PurchaseOutcome.cancelled;
    await tap(tester, 'onboarding-pass-buy');
    expect(result, isNull);
    expect(find.byType(OnboardingPassScreen), findsOneWidget);
    purchases.outcome = PurchaseOutcome.failed;
    await tap(tester, 'onboarding-pass-buy');
    await tester.ensureVisible(find.textContaining('That didn’t go through.'));
    expect(find.textContaining('Your holiday is still saved.'), findsOneWidget);
    await tap(tester, 'onboarding-pass-free');
    expect(result, OnboardingPassOutcome.free);
    expect(repository.bookings.single.id, 'first');
  });

  testWidgets('restore checks this holiday rather than another purchased pass', (tester) async {
    await pump(tester);
    purchases.restored = Entitlements(
      tripPasses: {'other': TripPass(tripId: 'other', start: d(11, 8), end: d(11, 17))},
    );
    await tap(tester, 'onboarding-pass-restore');
    expect(find.textContaining('No active pass for this holiday'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-pass-free')), findsOneWidget);
    purchases.restored = Entitlements(
      tripPasses: {'holiday': TripPass(tripId: 'holiday', start: d(11, 8), end: d(11, 17))},
    );
    await tap(tester, 'onboarding-pass-restore');
    // Their own pass for this holiday: confirmed like one just bought.
    expect(find.text('Welcome\nback!', findRichText: true), findsOneWidget);
    await carryOn(tester);
    expect(result, OnboardingPassOutcome.upgraded);
    expect(purchases.calls, isEmpty);
  });

  testWidgets('a payment the server hasn\'t recorded yet is never celebrated as a pass', (tester) async {
    await pump(tester);
    purchases.outcome = PurchaseOutcome.pending;
    await tap(tester, 'onboarding-pass-buy');
    expect(find.byKey(const ValueKey('pass-confirmed-badge')), findsNothing);
    expect(find.text(passPendingText), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-pass-free')), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('once a pass is bought, Back hands back as bought too', (tester) async {
    await pump(tester);
    await tap(tester, 'onboarding-pass-buy');
    expect(find.byKey(const ValueKey('pass-confirmed-badge')), findsOneWidget);
    await tap(tester, 'onboarding-pass-back');
    expect(result, OnboardingPassOutcome.upgraded);
  });

  testWidgets('a restore failure stays actionable', (tester) async {
    await pump(tester);
    purchases.restoreFails = true;
    await tap(tester, 'onboarding-pass-restore');
    expect(find.textContaining('Couldn’t restore purchases.'), findsOneWidget);
    await tap(tester, 'onboarding-pass-free');
    expect(result, OnboardingPassOutcome.free);
  });

  testWidgets('inherited Plus does not sell an unnecessary pass', (tester) async {
    await pump(
      tester,
      plan: holiday(
        premium: TripPremium(grantedBy: 'organiser', until: DateTime(2027)),
      ),
    );
    expect(find.byType(OnboardingPaperPass), findsNothing);
    expect(find.text('This holiday is already covered.'), findsOneWidget);
    await tap(tester, 'onboarding-pass-buy');
    expect(result, OnboardingPassOutcome.upgraded);
    expect(purchases.calls, isEmpty);
  });

  testWidgets('a missing supplied booking identity offers only the free holiday', (tester) async {
    await pump(tester, proof: false);
    expect(find.byType(OnboardingPaperPass), findsNothing);
    await tap(tester, 'onboarding-pass-buy');
    expect(result, OnboardingPassOutcome.free);
    expect(purchases.calls, isEmpty);
  });

  testWidgets('a dated holiday can choose a pass before adding its first booking', (tester) async {
    await pump(tester, withoutBooking: true);
    expect(find.byKey(const ValueKey('onboarding-pass-holiday')), findsOneWidget);
    expect(find.text(r'$19.25 once'), findsOneWidget);
    await tap(tester, 'onboarding-pass-buy');
    await carryOn(tester);
    expect(result, OnboardingPassOutcome.upgraded);
    expect(purchases.calls.single.pass, TripPass(tripId: 'holiday', start: d(11, 8), end: d(11, 15)));
    expect(repository.bookings, isEmpty);
    expect(repository.trips, hasLength(1));
  });

  testWidgets('exploring before a holiday offers Annual without inventing a Holiday Pass', (tester) async {
    await pump(tester, noHoliday: true);
    expect(find.byKey(const ValueKey('onboarding-pass-holiday')), findsNothing);
    expect(find.byKey(const ValueKey('onboarding-pass-annual')), findsOneWidget);
    await tap(tester, 'onboarding-pass-buy');
    await carryOn(tester);
    expect(result, OnboardingPassOutcome.upgraded);
    expect(purchases.calls.single.offer.kind, OfferKind.plusAnnual);
    expect(purchases.calls.single.pass, isNull);
    expect(repository.trips, isEmpty);
    expect(repository.bookings, isEmpty);
  });

  testWidgets('a long trip explains Annual, and changed eligibility never silently upgrades the selection', (
    tester,
  ) async {
    await pump(tester);
    repository.putTrip(holiday(end: d(12, 15)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding-pass-holiday')), findsNothing);
    expect(tester.widget<OnboardingPaperPass>(find.byKey(const ValueKey('onboarding-pass-annual'))).selected, isFalse);
    expect(find.text('Choose a pass'), findsOneWidget);
    expect(tester.widget<TextButton>(find.byKey(const ValueKey('onboarding-pass-free'))).onPressed, isNotNull);
    expect(find.textContaining('Your longer holiday can use the Annual Pass.'), findsOneWidget);
    await tap(tester, 'onboarding-pass-buy');
    expect(purchases.calls, isEmpty);
    await tap(tester, 'onboarding-pass-annual');
    await tap(tester, 'onboarding-pass-buy');
    expect(purchases.calls.single.offer.kind, OfferKind.plusAnnual);
  });

  testWidgets('small phone and doubled type keep prices, terms and free action reachable', (tester) async {
    await pump(tester, size: const Size(320, 568), scale: 2, reduced: false);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('onboarding-pass-annual')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('onboarding-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'onboarding-pass-annual');
    expect(find.text(r'$49.50 / year'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tap(tester, 'onboarding-pass-free');
    expect(result, OnboardingPassOutcome.free);
  });
}
