import 'dart:async';

import '../domain/domain.dart';
import 'latest_stream.dart';

enum PurchaseOutcome { purchased, cancelled, failed }

/// Buying and knowing what's been bought.
///
/// Implementations:
/// - [TestPurchaseService]: simulated store, used until RevenueCat is wired
///   up and in tests.
/// - RevenueCat (step 4): real App Store / Google Play purchases. Its
///   webhook also stamps `premium` on trips so invited family inherit Plus.
abstract interface class PurchaseService {
  /// A short label for Profile, e.g. "Test purchases".
  String get label;

  /// Live entitlements for the signed-in traveller.
  Stream<Entitlements> watchEntitlements();

  /// Products with store prices (localised, trial eligibility applied).
  Future<List<Offer>> loadOffers();

  /// [tripId] is required for a Trip Pass.
  Future<PurchaseOutcome> purchase(Offer offer, {String? tripId});

  Future<void> restore();

  /// Counts one free Smart Import. (The import service will also count
  /// server-side; this keeps the app's display in step.)
  Future<void> recordSmartImport();

  Future<void> dispose();
}

/// A pretend store: purchases succeed instantly and last until restart.
///
/// Shows the whole flow (paywall → purchase → unlocked) without store
/// accounts, and lets you switch plans from Profile in debug builds.
class TestPurchaseService implements PurchaseService {
  TestPurchaseService({Entitlements initial = Entitlements.none, DateTime Function()? clock})
    : _entitlements = initial,
      _clock = clock ?? DateTime.now;

  Entitlements _entitlements;
  final DateTime Function() _clock;
  final _controller = StreamController<Entitlements>.broadcast();

  Entitlements get current => _entitlements;

  @override
  String get label => 'Test purchases';

  @override
  Stream<Entitlements> watchEntitlements() => startWith(() => _entitlements, _controller.stream);

  @override
  Future<List<Offer>> loadOffers() async {
    // A traveller who already had a trial isn't offered another.
    final trialUsed = _entitlements.plus != null;
    return [
      for (final offer in Pricing.defaults)
        offer.kind == OfferKind.plusAnnual && trialUsed
            ? Offer(
                kind: offer.kind,
                productId: offer.productId,
                amount: offer.amount,
                currencyCode: offer.currencyCode,
              )
            : offer,
    ];
  }

  @override
  Future<PurchaseOutcome> purchase(Offer offer, {String? tripId}) async {
    final now = _clock();
    switch (offer.kind) {
      case OfferKind.plusAnnual:
        final trial = offer.trialDays;
        set(_entitlements.copyWith(
          plus: PlusSubscription(
            expiresAt: now.add(Duration(days: trial ?? 365)),
            inTrial: trial != null,
          ),
        ));
      case OfferKind.tripPass:
        if (tripId == null) return PurchaseOutcome.failed;
        set(_entitlements.copyWith(tripPasses: {..._entitlements.tripPasses, tripId}));
    }
    return PurchaseOutcome.purchased;
  }

  @override
  Future<void> restore() async {}

  @override
  Future<void> recordSmartImport() async =>
      set(_entitlements.copyWith(smartImportsUsed: _entitlements.smartImportsUsed + 1));

  /// Replaces the entitlements (debug plan switcher, tests).
  void set(Entitlements entitlements) {
    _entitlements = entitlements;
    _controller.add(entitlements);
  }

  @override
  Future<void> dispose() => _controller.close();
}
