import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../domain/pricing.dart';
import 'revenuecat_identity.dart';

/// Remote catalog only. Billing/verified trip-pass claims remain owned by
/// PurchaseService; fetching an offering cannot grant an entitlement.
class RevenueCatOfferCatalog {
  const RevenueCatOfferCatalog({required this.publicSdkKey, required this.userId, this.offeringId});
  final String publicSdkKey;
  final String userId;
  final String? offeringId;

  Future<List<Offer>> load() => RevenueCatIdentity.run(publicSdkKey, userId, () async {
    final offerings = await rc.Purchases.getOfferings();
    final offering = offeringId == null || offeringId!.isEmpty ? offerings.current : offerings.all[offeringId];
    return offering == null ? const <Offer>[] : offersFromRevenueCat(offering);
  });
}

/// Package availability and binding come from the selected offering. The
/// semantic roles stay fixed: a one-off holiday and an annual subscription.
/// Metadata cannot relabel monthly billing as annual or lifetime as a holiday.
List<Offer> offersFromRevenueCat(rc.Offering offering) {
  final raw = offering.metadata['pass_desk'];
  final metadata = raw is Map ? raw : const {};
  final result = <Offer>[];
  for (final entry in const {'holiday': OfferKind.tripPass, 'annual': OfferKind.plusAnnual}.entries) {
    final config = metadata[entry.key];
    final data = config is Map ? config : const {};
    if (data['enabled'] == false) continue;
    final identifier = data['package'];
    rc.Package? package;
    if (identifier is String) {
      package = offering.getPackage(identifier);
    } else if (entry.value == OfferKind.plusAnnual && config == null) {
      package = offering.annual;
    }
    if (package == null) continue;
    final product = package.storeProduct;
    final validBilling = entry.value == OfferKind.tripPass
        ? product.productCategory == rc.ProductCategory.nonSubscription && product.subscriptionPeriod == null
        : product.productCategory == rc.ProductCategory.subscription && product.subscriptionPeriod == 'P1Y';
    if (!validBilling || !product.price.isFinite || product.price < 0 || product.priceString.trim().isEmpty) continue;
    String? copy(String key) =>
        data[key] is String && (data[key] as String).trim().isNotEmpty ? (data[key] as String).trim() : null;
    result.add(
      Offer(
        kind: entry.value,
        productId: product.identifier,
        amount: product.price,
        currencyCode: product.currencyCode,
        localizedPrice: product.priceString,
        title: copy('title') ?? product.title,
        scope: copy('scope'),
        packageId: package.identifier,
        offeringId: offering.identifier,
      ),
    );
  }
  return result;
}
