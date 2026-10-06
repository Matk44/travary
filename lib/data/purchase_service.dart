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

  /// Products with store prices (localised).
  Future<List<Offer>> loadOffers();

  /// [tripPass] (the trip and its dates now) is required for a Trip Pass.
  Future<PurchaseOutcome> purchase(Offer offer, {TripPass? tripPass});

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
  Future<List<Offer>> loadOffers() async => Pricing.defaults;

  @override
  Future<PurchaseOutcome> purchase(Offer offer, {TripPass? tripPass}) async {
    final now = _clock();
    switch (offer.kind) {
      case OfferKind.plusAnnual:
        set(_entitlements.copyWith(plus: PlusSubscription(expiresAt: now.add(const Duration(days: 365)))));
      case OfferKind.tripPass:
        if (tripPass == null) return PurchaseOutcome.failed;
        set(_entitlements.copyWith(tripPasses: {..._entitlements.tripPasses, tripPass.tripId: tripPass}));
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
