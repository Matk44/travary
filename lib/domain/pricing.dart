/// What can be bought. The store (via RevenueCat) is the source of truth for
/// prices; these are the product IDs and the launch defaults.
enum OfferKind { plusAnnual, tripPass }

/// A product as the store sells it, with a localised price.
class Offer {
  const Offer({
    required this.kind,
    required this.productId,
    required this.amount,
    required this.currencyCode,
    this.trialDays,
  });

  final OfferKind kind;
  final String productId;

  /// Price in the store's currency, e.g. 34.99.
  final double amount;

  /// ISO 4217, e.g. "USD", "GBP", "AUD".
  final String currencyCode;

  /// Free trial length for subscriptions, if the traveller is eligible.
  final int? trialDays;
}

/// Launch pricing (USD). Stores localise it per country.
abstract final class Pricing {
  static const plusAnnualProductId = 'travary_plus_annual';
  static const tripPassProductId = 'travary_trip_pass';

  static const plusAnnualUsd = 34.99;
  static const tripPassUsd = 7.99;
  static const trialDays = 14;

  /// Everyone on a Plus organiser's trips, including them.
  static const familySize = 6;

  /// Smart Imports on the free plan, lifetime.
  static const freeSmartImports = 3;

  /// A Trip Pass keeps the trip unlocked this long after it ends.
  static const tripPassGraceDays = 7;

  static const defaults = [
    Offer(
      kind: OfferKind.plusAnnual,
      productId: plusAnnualProductId,
      amount: plusAnnualUsd,
      currencyCode: 'USD',
      trialDays: trialDays,
    ),
    Offer(
      kind: OfferKind.tripPass,
      productId: tripPassProductId,
      amount: tripPassUsd,
      currencyCode: 'USD',
    ),
  ];
}
