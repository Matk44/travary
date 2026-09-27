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
    expect(store.offer(OfferKind.plusAnnual)?.trialDays, 14);
    expect(store.offer(OfferKind.tripPass)?.amount, 7.99);
  });

  test('buying Plus starts a 14-day trial, and no second trial is offered', () async {
    final outcome = await store.purchase(store.offer(OfferKind.plusAnnual)!, source: 'test');
    await pumpEventQueue();
    expect(outcome, PurchaseOutcome.purchased);
    expect(store.hasPlus, isTrue);
    expect(store.policy.inTrial, isTrue);
    expect(store.entitlements.plus!.expiresAt, now.add(const Duration(days: 14)));
    expect(store.offer(OfferKind.plusAnnual)?.trialDays, isNull);
  });

  test('a Trip Pass needs a trip', () async {
    final pass = store.offer(OfferKind.tripPass)!;
    expect(await store.purchase(pass, source: 'test'), PurchaseOutcome.failed);
    expect(await store.purchase(pass, tripId: 'orlando', source: 'test'), PurchaseOutcome.purchased);
    await pumpEventQueue();
    expect(store.entitlements.tripPasses, {'orlando'});
  });

  test('only free Smart Imports are counted', () async {
    await store.countSmartImport(store.decide(PremiumFeature.smartImport));
    await pumpEventQueue();
    expect(store.policy.freeSmartImportsLeft, 2);

    purchases.set(store.entitlements.copyWith(
      plus: PlusSubscription(expiresAt: now.add(const Duration(days: 30))),
    ));
    await pumpEventQueue();
    await store.countSmartImport(store.decide(PremiumFeature.smartImport));
    await pumpEventQueue();
    expect(store.entitlements.smartImportsUsed, 1);
  });
}
