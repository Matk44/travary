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
  /// [ownsPurchases]: [purchases] was made for this account alone, so it's
  /// disposed with the store. [limits]: the free plan's numbers as they
  /// change (`config/freePlan`); the defaults until one arrives, or without.
  PremiumStore({
    required this.purchases,
    DateTime Function()? clock,
    Future<List<Offer>> Function()? offerLoader,
    Stream<FreePlanLimits>? limits,
    bool ownsPurchases = false,
  }) : _clock = clock ?? DateTime.now,
       _offerLoader = offerLoader,
       _ownsPurchases = ownsPurchases,
       _offers = offerLoader == null ? Pricing.defaults : const [] {
    _subscription = purchases.watchEntitlements().listen((entitlements) {
      _entitlements = entitlements;
      notifyListeners();
    });
    _limitsSubscription = limits?.listen((limits) {
      if (limits == _limits) return;
      _limits = limits;
      notifyListeners();
    });
    unawaited(_loadOffers());
  }

  final PurchaseService purchases;
  final DateTime Function() _clock;
  final Future<List<Offer>> Function()? _offerLoader;
  final bool _ownsPurchases;
  late final StreamSubscription<Entitlements> _subscription;
  StreamSubscription<FreePlanLimits>? _limitsSubscription;

  Entitlements _entitlements = Entitlements.none;
  FreePlanLimits _limits = FreePlanLimits.defaults;
  List<Offer> _offers;
  bool _busy = false;
  bool _disposed = false;
  int _offerRequest = 0;
  bool _offersLoading = true;
  String? _offersError;

  Entitlements get entitlements => _entitlements;
  FreePlanLimits get limits => _limits;
  AccessPolicy get policy => AccessPolicy(_entitlements, _clock(), limits: _limits);
  bool get hasPlus => policy.hasPlus;
  bool get busy => _busy;
  bool get isTestStore => purchases is TestPurchaseService;
  bool get offersLoading => _offersLoading;
  String? get offersError => _offersError;
  Future<void> refreshOffers() => _loadOffers();

  Offer? offer(OfferKind kind) {
    for (final offer in _offers) {
      if (offer.kind == kind) return offer;
    }
    return null;
  }

  AccessDecision decide(PremiumFeature feature, {TripPlan? trip}) => policy.decide(feature, trip: trip);

  AccessDecision forTrip(TripPlan? trip) => policy.forTrip(trip);

  /// Buys [offer]. A Trip Pass needs [tripPass]: the trip and the dates it
  /// covers ([newTripPassFor]).
  Future<PurchaseOutcome> purchase(Offer offer, {TripPass? tripPass, required String source}) async {
    _setBusy(true);
    track('purchase_started', {'product': offer.productId, 'source': source});
    try {
      final outcome = await purchases.purchase(offer, tripPass: tripPass);
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
    final request = ++_offerRequest;
    _offersLoading = true;
    _offersError = null;
    try {
      final offers = await (_offerLoader?.call() ?? purchases.loadOffers());
      if (_disposed || request != _offerRequest) return;
      _offers = offers;
    } catch (_) {
      if (_disposed || request != _offerRequest) return;
      // A configured remote catalog never invents a USD price after failure.
      if (_offerLoader != null) _offers = const [];
      _offersError = 'Couldn’t load passes. Try again or continue with free.';
    } finally {
      if (!_disposed && request == _offerRequest) {
        _offersLoading = false;
        notifyListeners();
      }
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    _limitsSubscription?.cancel();
    if (_ownsPurchases) unawaited(purchases.dispose());
    super.dispose();
  }
}
