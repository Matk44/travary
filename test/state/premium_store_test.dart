import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/premium_store.dart';

void main() {
  final now = DateTime(2026, 10, 14, 10);
  late TestPurchaseService purchases;
  late PremiumStore store;

  setUp(() async {
    purchases = TestPurchaseService(clock: () => now);
    store = PremiumStore(purchases: purchases, clock: () => now);
    await pumpEventQueue();
  });

  tearDown(() => store.dispose());

  test('starts free with the launch offers', () {
    expect(store.hasPlus, isFalse);
    expect(store.offer(OfferKind.plusAnnual)?.amount, 34.99);
    expect(store.offer(OfferKind.tripPass)?.amount, 14.99);
  });

  test('buying Plus unlocks it for a year straight away: there is no free trial', () async {
    final outcome = await store.purchase(store.offer(OfferKind.plusAnnual)!, source: 'test');
    await pumpEventQueue();
    expect(outcome, PurchaseOutcome.purchased);
    expect(store.hasPlus, isTrue);
    expect(store.entitlements.plus!.expiresAt, now.add(const Duration(days: 365)));
  });

  test('a Trip Pass needs a trip, and keeps the dates it was bought for', () async {
    final pass = store.offer(OfferKind.tripPass)!;
    final orlando = TripPass(tripId: 'orlando', start: LocalDate(2026, 10, 12), end: LocalDate(2026, 10, 18));
    expect(await store.purchase(pass, source: 'test'), PurchaseOutcome.failed);
    expect(await store.purchase(pass, tripPass: orlando, source: 'test'), PurchaseOutcome.purchased);
    await pumpEventQueue();
    expect(store.entitlements.tripPasses, {'orlando': orlando});
  });

  test('only free Smart Imports are counted', () async {
    await store.countSmartImport(store.decide(PremiumFeature.smartImport));
    await pumpEventQueue();
    expect(store.policy.freeSmartImportsLeft, 1);

    purchases.set(store.entitlements.copyWith(plus: PlusSubscription(expiresAt: now.add(const Duration(days: 30)))));
    await pumpEventQueue();
    await store.countSmartImport(store.decide(PremiumFeature.smartImport));
    await pumpEventQueue();
    expect(store.entitlements.smartImportsUsed, 1);
  });

  test('a configured remote catalog never displays fallback USD prices when loading or failed', () async {
    final response = Completer<List<Offer>>();
    final remote = PremiumStore(purchases: purchases, offerLoader: () => response.future);
    addTearDown(remote.dispose);
    expect(remote.offersLoading, isTrue);
    expect(remote.offer(OfferKind.tripPass), isNull);
    response.completeError(StateError('Offline'));
    await pumpEventQueue();
    expect(remote.offersLoading, isFalse);
    expect(remote.offersError, isNotNull);
    expect(remote.offer(OfferKind.tripPass), isNull);
    expect(remote.hasPlus, isFalse);
  });

  test('later catalog refresh wins and a disposed account ignores late offer responses', () async {
    final first = Completer<List<Offer>>();
    final second = Completer<List<Offer>>();
    var calls = 0;
    final remote = PremiumStore(purchases: purchases, offerLoader: () => ++calls == 1 ? first.future : second.future);
    final refresh = remote.refreshOffers();
    second.complete(const [
      Offer(
        kind: OfferKind.tripPass,
        productId: 'new',
        amount: 18.49,
        currencyCode: 'EUR',
        localizedPrice: '18,49 €',
        title: 'New Holiday Pass',
      ),
    ]);
    await refresh;
    expect(remote.offer(OfferKind.tripPass)?.title, 'New Holiday Pass');
    first.complete(Pricing.defaults);
    await pumpEventQueue();
    expect(remote.offer(OfferKind.tripPass)?.productId, 'new');
    remote.dispose();
    final late = Completer<List<Offer>>();
    final disposed = PremiumStore(purchases: purchases, offerLoader: () => late.future)..dispose();
    late.complete(Pricing.defaults);
    await pumpEventQueue();
    expect(disposed.offer(OfferKind.tripPass), isNull);
  });
}
