import 'dart:async';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../domain/domain.dart';
import 'latest_stream.dart';
import 'pending_pass_claims.dart';
import 'purchase_server.dart';
import 'purchase_service.dart';
import 'revenuecat_identity.dart';

/// A purchase the store has charged for.
class StorePurchase {
  const StorePurchase({required this.transactionId, this.plus});

  final String transactionId;

  /// The Annual Pass as the store reports it after the purchase.
  final PlusSubscription? plus;
}

/// The traveller closed the store's sheet without buying.
class StorePurchaseCancelled implements Exception {
  const StorePurchaseCancelled();
}

/// The store, as Travary uses it: RevenueCat's SDK in the app, a fake in
/// tests.
abstract interface class StoreClient {
  /// The Annual Pass (RevenueCat's `plus` entitlement) on every change; null
  /// when it isn't active.
  Stream<PlusSubscription?> watchPlus();

  /// Shows the store's purchase sheet for [offer]'s package.
  Future<StorePurchase> buy(Offer offer);

  Future<void> restore();
}

/// Real App Store and Google Play purchases through RevenueCat, for one
/// account (a new account gets a new service).
///
/// - The Annual Pass is RevenueCat's `plus` entitlement, read live from the
///   SDK. The server mirrors it to `users/{uid}` and stamps the trips this
///   traveller organises, so family on them get Plus too.
/// - A Holiday Pass is a consumable. Once the store has charged, the server
///   checks the transaction with RevenueCat and records the pass for the
///   trip's dates, which it reads itself (`claimTripPass`).
/// - Trip Passes and Smart Imports used come from `users/{uid}`, which only
///   the server writes. The app never records a purchase itself.
class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService({
    required StoreClient store,
    required PurchaseServer server,
    required Stream<Map<String, Object?>?> userRecord,
    required Future<List<Offer>> Function() offers,
    PendingPassClaims? pending,
    Duration claimRetryDelay = const Duration(seconds: 2),
  }) : _store = store,
       _server = server,
       _offers = offers,
       _pending = pending ?? MemoryPendingPassClaims(),
       _claimRetryDelay = claimRetryDelay {
    _plusSubscription = store.watchPlus().listen((plus) {
      _storePlus = plus;
      _storePlusKnown = true;
      _emit();
    }, onError: (Object _) {});
    _recordSubscription = userRecord.listen((record) {
      _mirror = Entitlements.fromUserRecord(record);
      _emit();
    }, onError: (Object _) {});
    // Passes paid for when the app last ran but never recorded.
    _loaded = _loadUnclaimed();
  }

  final StoreClient _store;
  final PurchaseServer _server;
  final Future<List<Offer>> Function() _offers;
  final PendingPassClaims _pending;
  final Duration _claimRetryDelay;
  late final Future<void> _loaded;
  late final StreamSubscription<PlusSubscription?> _plusSubscription;
  late final StreamSubscription<Map<String, Object?>?> _recordSubscription;
  final _controller = StreamController<Entitlements>.broadcast();

  /// What the server has mirrored (Trip Passes, Smart Imports, Plus).
  Entitlements _mirror = Entitlements.none;

  /// The store's own answer for the Annual Pass, which wins once known.
  PlusSubscription? _storePlus;
  bool _storePlusKnown = false;

  /// Holiday Passes paid for but not yet recorded: transaction → trip,
  /// also kept on the phone ([PendingPassClaims]) until they are.
  final _unclaimed = <String, String>{};

  Entitlements get current =>
      _storePlusKnown ? _mirror.copyWith(plus: _storePlus, clearPlus: _storePlus == null) : _mirror;

  @override
  String get label => 'Store purchases';

  @override
  Stream<Entitlements> watchEntitlements() => startWith(() => current, _controller.stream);

  @override
  Future<List<Offer>> loadOffers() => _offers();

  @override
  Future<PurchaseOutcome> purchase(Offer offer, {TripPass? tripPass}) async {
    if (offer.kind == OfferKind.tripPass && tripPass == null) return PurchaseOutcome.failed;
    final StorePurchase bought;
    try {
      bought = await _store.buy(offer);
    } on StorePurchaseCancelled {
      return PurchaseOutcome.cancelled;
    }
    switch (offer.kind) {
      case OfferKind.plusAnnual:
        _storePlus = bought.plus ?? _storePlus;
        _storePlusKnown = true;
        _emit();
        // Stamps their trips now; RevenueCat's webhook would catch up anyway.
        unawaited(_server.syncPurchases().catchError((Object _) {}));
        return PurchaseOutcome.purchased;
      case OfferKind.tripPass:
        // Charged: from here it's never "failed". Written down first, so
        // closing the app before the server records it loses nothing.
        await _loaded;
        _unclaimed[bought.transactionId] = tripPass!.tripId;
        await _pending.save(_unclaimed);
        return await _claimUnclaimed(attempts: 3) ? PurchaseOutcome.purchased : PurchaseOutcome.pending;
    }
  }

  Future<void> _loadUnclaimed() async {
    final saved = await _pending.load();
    if (saved.isEmpty) return;
    _unclaimed.addAll(saved);
    unawaited(_claimUnclaimed(attempts: 1));
  }

  /// The claims being sent now, so two runs never send the same one twice.
  Future<void>? _claiming;

  /// Records every pass paid for but not yet claimed, retrying briefly.
  /// True when none are left.
  Future<bool> _claimUnclaimed({required int attempts}) async {
    for (var attempt = 1; ; attempt++) {
      // One run at a time: wait for any already sending.
      for (var running = _claiming; running != null; running = _claiming) {
        await running;
      }
      final run = _claimEach();
      _claiming = run;
      await run;
      if (identical(_claiming, run)) _claiming = null;
      if (_unclaimed.isEmpty) return true;
      if (attempt >= attempts) return false;
      await Future<void>.delayed(_claimRetryDelay * attempt);
    }
  }

  Future<void> _claimEach() async {
    for (final MapEntry(key: transactionId, value: tripId) in [..._unclaimed.entries]) {
      try {
        await _server.claimTripPass(tripId: tripId, transactionId: transactionId);
        _unclaimed.remove(transactionId);
        await _pending.save(_unclaimed);
      } catch (_) {
        // Kept for the next attempt, the next launch or the next restore.
      }
    }
  }

  @override
  Future<void> restore() async {
    await _loaded;
    await _store.restore();
    await _claimUnclaimed(attempts: 1);
    await _server.syncPurchases();
  }

  /// The server counts Smart Imports as it runs them (`smartImport.total`).
  @override
  Future<void> recordSmartImport() async {}

  void _emit() {
    if (!_controller.isClosed) _controller.add(current);
  }

  @override
  Future<void> dispose() async {
    await _plusSubscription.cancel();
    await _recordSubscription.cancel();
    await _controller.close();
  }
}

/// RevenueCat's SDK as Travary's store.
class RevenueCatStoreClient implements StoreClient {
  RevenueCatStoreClient({required this.publicSdkKey, required this.userId});

  final String publicSdkKey;
  final String userId;

  Future<void> _ready() => RevenueCatIdentity.ensure(publicSdkKey, userId);

  @override
  Stream<PlusSubscription?> watchPlus() {
    late final StreamController<PlusSubscription?> controller;
    var cancelled = false;
    void onUpdate(rc.CustomerInfo info) {
      if (!cancelled) controller.add(plusFromCustomerInfo(info));
    }

    controller = StreamController<PlusSubscription?>(
      onListen: () async {
        try {
          await _ready();
          if (cancelled) return;
          rc.Purchases.addCustomerInfoUpdateListener(onUpdate);
          onUpdate(await rc.Purchases.getCustomerInfo());
        } catch (_) {
          // Offline or the store isn't reachable: the server's mirror stands in.
        }
      },
      onCancel: () {
        cancelled = true;
        rc.Purchases.removeCustomerInfoUpdateListener(onUpdate);
      },
    );
    return controller.stream;
  }

  @override
  Future<StorePurchase> buy(Offer offer) async {
    await _ready();
    final offerings = await rc.Purchases.getOfferings();
    final offering = offer.offeringId == null ? offerings.current : offerings.all[offer.offeringId];
    final package = offer.packageId == null ? null : offering?.getPackage(offer.packageId!);
    if (package == null) throw StateError('${offer.productId} isn\'t on sale in this offering');
    try {
      final result = await rc.Purchases.purchase(rc.PurchaseParams.package(package));
      return StorePurchase(
        transactionId: result.storeTransaction.transactionIdentifier,
        plus: plusFromCustomerInfo(result.customerInfo),
      );
    } on PlatformException catch (e) {
      if (rc.PurchasesErrorHelper.getErrorCode(e) == rc.PurchasesErrorCode.purchaseCancelledError) {
        throw const StorePurchaseCancelled();
      }
      rethrow;
    }
  }

  @override
  Future<void> restore() async {
    await _ready();
    await rc.Purchases.restorePurchases();
  }
}

/// RevenueCat's `plus` entitlement as the Annual Pass; null when inactive.
PlusSubscription? plusFromCustomerInfo(rc.CustomerInfo info) {
  final plus = info.entitlements.all[Pricing.plusEntitlement];
  if (plus == null || !plus.isActive) return null;
  return PlusSubscription(
    expiresAt: DateTime.tryParse(plus.expirationDate ?? '') ?? DateTime.utc(9999),
    willRenew: plus.willRenew,
  );
}
