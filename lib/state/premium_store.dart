import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/purchase_service.dart';
import '../domain/domain.dart';
import '../logic/access.dart';
import '../logic/trip_plan.dart';
import 'analytics.dart';

/// What the traveller has unlocked, and buying more. Screens ask
/// [decide] before using a premium feature; the rules live in
/// [AccessPolicy].
class PremiumStore extends ChangeNotifier {
  PremiumStore({required this.purchases, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _subscription = purchases.watchEntitlements().listen((entitlements) {
      _entitlements = entitlements;
      notifyListeners();
    });
    unawaited(_loadOffers());
  }

  final PurchaseService purchases;
  final DateTime Function() _clock;
  late final StreamSubscription<Entitlements> _subscription;

  Entitlements _entitlements = Entitlements.none;
  List<Offer> _offers = Pricing.defaults;
  bool _busy = false;

  Entitlements get entitlements => _entitlements;
  AccessPolicy get policy => AccessPolicy(_entitlements, _clock());
  bool get hasPlus => policy.hasPlus;
  bool get busy => _busy;
  bool get isTestStore => purchases is TestPurchaseService;

  Offer? offer(OfferKind kind) {
    for (final offer in _offers) {
      if (offer.kind == kind) return offer;
    }
    return null;
  }

  AccessDecision decide(PremiumFeature feature, {TripPlan? trip}) =>
      policy.decide(feature, trip: trip);

  AccessDecision forTrip(TripPlan? trip) => policy.forTrip(trip);

  Future<PurchaseOutcome> purchase(Offer offer, {String? tripId, required String source}) async {
    _setBusy(true);
    track('purchase_started', {'product': offer.productId, 'source': source});
    try {
      final outcome = await purchases.purchase(offer, tripId: tripId);
      track('purchase_${outcome.name}', {'product': offer.productId, 'source': source});
      await _loadOffers();
      return outcome;
    } catch (error) {
      track('purchase_failed', {'product': offer.productId, 'error': error});
      return PurchaseOutcome.failed;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> restore() async {
    _setBusy(true);
    try {
      await purchases.restore();
      await _loadOffers();
    } finally {
      _setBusy(false);
    }
  }

  /// Call after a Smart Import succeeds. Only free uses are counted.
  Future<void> countSmartImport(AccessDecision decision) async {
    if (decision.isFreeUse) await purchases.recordSmartImport();
  }

  /// Debug plan switcher (test store only).
  void debugSetEntitlements(Entitlements entitlements) {
    final store = purchases;
    if (store is TestPurchaseService) store.set(entitlements);
  }

  Future<void> _loadOffers() async {
    try {
      _offers = await purchases.loadOffers();
      notifyListeners();
    } catch (_) {
      // Keep the defaults; the paywall still works with them.
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
