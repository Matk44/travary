import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:travary/data/pending_pass_claims.dart';
import 'package:travary/data/purchase_server.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/revenuecat_purchase_service.dart';
import 'package:travary/domain/domain.dart';

class FakeStore implements StoreClient {
  final plus = StreamController<PlusSubscription?>.broadcast();
  final bought = <Offer>[];
  StorePurchase Function(Offer offer) onBuy = (_) => const StorePurchase(transactionId: 'tx1');
  var restores = 0;

  @override
  Stream<PlusSubscription?> watchPlus() => plus.stream;

  @override
  Future<StorePurchase> buy(Offer offer) async {
    bought.add(offer);
    return onBuy(offer);
  }

  @override
  Future<void> restore() async => restores++;
}

class FakeServer implements PurchaseServer {
  final claims = <({String tripId, String transactionId})>[];
  var syncs = 0;
  var failClaims = 0;

  @override
  Future<void> claimTripPass({required String tripId, required String transactionId}) async {
    claims.add((tripId: tripId, transactionId: transactionId));
    if (failClaims > 0) {
      failClaims--;
      throw const PurchaseServerException('Offline');
    }
  }

  @override
  Future<void> syncPurchases() async => syncs++;
}

void main() {
  const annual = Offer(
    kind: OfferKind.plusAnnual,
    productId: 'travary_annual_pass',
    amount: 34.99,
    currencyCode: 'USD',
    packageId: r'$rc_annual',
  );
  const holiday = Offer(
    kind: OfferKind.tripPass,
    productId: 'holiday_pass',
    amount: 14.99,
    currencyCode: 'USD',
    packageId: 'holiday_pass',
  );
  final japan = TripPass(tripId: 'japan', start: LocalDate(2026, 11, 2), end: LocalDate(2026, 11, 12));

  late FakeStore store;
  late FakeServer server;
  late StreamController<Map<String, Object?>?> record;
  late RevenueCatPurchaseService service;
  late List<Entitlements> seen;

  setUp(() {
    store = FakeStore();
    server = FakeServer();
    record = StreamController.broadcast();
    service = RevenueCatPurchaseService(
      store: store,
      server: server,
      userRecord: record.stream,
      offers: () async => const [annual, holiday],
      claimRetryDelay: Duration.zero,
    );
    seen = [];
    service.watchEntitlements().listen(seen.add);
  });

  tearDown(() => service.dispose());

  test('starts from the server mirror; the store\'s own Annual Pass wins once known', () async {
    record.add({
      'plus': {'expiresAt': DateTime(2027, 1, 1).millisecondsSinceEpoch, 'willRenew': true},
      'tripPasses': {
        'japan': {'start': '2026-11-02', 'end': '2026-11-12'},
      },
      'smartImport': {'total': 2},
    });
    await pumpEventQueue();
    expect(service.current.plus?.expiresAt, DateTime(2027, 1, 1));
    expect(service.current.tripPasses['japan'], japan);
    expect(service.current.smartImportsUsed, 2);

    // Lapsed at the store, before the webhook has caught up.
    store.plus.add(null);
    await pumpEventQueue();
    expect(service.current.plus, isNull);
    expect(service.current.tripPasses, contains('japan'));
    expect(seen.last.plus, isNull);
  });

  test('buying the Annual Pass unlocks it at once and asks the server to stamp trips', () async {
    store.onBuy = (_) => StorePurchase(
      transactionId: 'tx-annual',
      plus: PlusSubscription(expiresAt: DateTime(2027, 10, 7)),
    );
    expect(await service.purchase(annual), PurchaseOutcome.purchased);
    await pumpEventQueue();
    expect(service.current.plus?.expiresAt, DateTime(2027, 10, 7));
    expect(server.syncs, 1);
    expect(server.claims, isEmpty);
  });

  test('a Holiday Pass is claimed for its trip with the store transaction', () async {
    store.onBuy = (_) => const StorePurchase(transactionId: 'GPA.1234');
    expect(await service.purchase(holiday, tripPass: japan), PurchaseOutcome.purchased);
    expect(server.claims, [(tripId: 'japan', transactionId: 'GPA.1234')]);
  });

  test('a Holiday Pass needs its trip, and a cancelled sheet buys nothing', () async {
    expect(await service.purchase(holiday), PurchaseOutcome.failed);
    expect(store.bought, isEmpty);

    store.onBuy = (_) => throw const StorePurchaseCancelled();
    expect(await service.purchase(holiday, tripPass: japan), PurchaseOutcome.cancelled);
    expect(server.claims, isEmpty);
  });

  test('a claim is retried, and one that keeps failing is claimed again on restore', () async {
    server.failClaims = 1;
    expect(await service.purchase(holiday, tripPass: japan), PurchaseOutcome.purchased);
    expect(server.claims, hasLength(2));

    // Charged but not recorded yet: pending, never "failed".
    server.failClaims = 3;
    store.onBuy = (_) => const StorePurchase(transactionId: 'tx2');
    expect(await service.purchase(holiday, tripPass: japan), PurchaseOutcome.pending);
    expect(server.claims, hasLength(5));

    await service.restore();
    expect(store.restores, 1);
    expect(server.claims.last, (tripId: 'japan', transactionId: 'tx2'));
    expect(server.syncs, 1);

    // Nothing left to claim.
    await service.restore();
    expect(server.claims, hasLength(6));
  });

  test('a pass paid for but not recorded is kept on the phone and claimed when the app next opens', () async {
    final pending = MemoryPendingPassClaims();
    final first = RevenueCatPurchaseService(
      store: store,
      server: server,
      userRecord: record.stream,
      offers: () async => const [holiday],
      pending: pending,
      claimRetryDelay: Duration.zero,
    );
    server.failClaims = 3;
    store.onBuy = (_) => const StorePurchase(transactionId: 'tx9');
    expect(await first.purchase(holiday, tripPass: japan), PurchaseOutcome.pending);
    expect(pending.claims, {'tx9': 'japan'});
    await first.dispose();

    // The app closed; next time it opens (back online), it's claimed.
    final next = RevenueCatPurchaseService(
      store: store,
      server: server,
      userRecord: record.stream,
      offers: () async => const [holiday],
      pending: pending,
      claimRetryDelay: Duration.zero,
    );
    addTearDown(next.dispose);
    await pumpEventQueue();
    expect(server.claims.last, (tripId: 'japan', transactionId: 'tx9'));
    expect(pending.claims, isEmpty);
  });

  test('Smart Imports are counted by the server, not the app', () async {
    await service.recordSmartImport();
    expect(service.current.smartImportsUsed, 0);
  });

  test('the plus entitlement is the Annual Pass; anything inactive is not', () {
    rc.CustomerInfo info(Map<String, rc.EntitlementInfo> all) => rc.CustomerInfo(
      rc.EntitlementInfos(all, const {}),
      const {},
      const [],
      const [],
      const [],
      '',
      'u1',
      const {},
      '',
    );
    rc.EntitlementInfo plus({required bool active, String? expires}) => rc.EntitlementInfo(
      'plus',
      active,
      false,
      '2026-10-07T00:00:00Z',
      '2026-10-07T00:00:00Z',
      'travary_annual_pass',
      true,
      expirationDate: expires,
    );

    final active = plusFromCustomerInfo(info({'plus': plus(active: true, expires: '2027-10-07T09:00:00Z')}));
    expect(active?.expiresAt, DateTime.utc(2027, 10, 7, 9));
    expect(active?.willRenew, isFalse);
    expect(plusFromCustomerInfo(info({'plus': plus(active: false, expires: '2026-01-01T00:00:00Z')})), isNull);
    expect(plusFromCustomerInfo(info(const {})), isNull);
  });

  test('the server mirror skips anything malformed', () {
    final entitlements = Entitlements.fromUserRecord({
      'plus': {'expiresAt': 'soon'},
      'tripPasses': {
        'ok': {'start': '2026-11-02', 'end': '2026-11-12'},
        'backwards': {'start': '2026-11-12', 'end': '2026-11-02'},
        'missing': {'start': '2026-11-02'},
        'odd': 'pass',
      },
      'smartImport': {'today': 1},
    });
    expect(entitlements.plus, isNull);
    expect(entitlements.tripPasses.keys, ['ok']);
    expect(entitlements.smartImportsUsed, 0);
    expect(Entitlements.fromUserRecord(null).tripPasses, isEmpty);
  });
}
