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
    this.localizedPrice,
    this.title,
    this.scope,
    this.packageId,
    this.offeringId,
  });

  final OfferKind kind;
  final String productId;

  /// Price in the store's currency, e.g. 34.99.
  final double amount;

  /// ISO 4217, e.g. "USD", "GBP", "AUD".
  final String currencyCode;

  /// Store-formatted price, never reconstructed with a hard-coded "$" or prefix.
  final String? localizedPrice;

  /// Remote offering metadata (or the store product title).
  final String? title;
  final String? scope;
  final String? packageId;
  final String? offeringId;
  String get displayTitle => title ?? (kind == OfferKind.tripPass ? 'Holiday Pass' : 'Annual Pass');
  String get displayScope => scope ?? (kind == OfferKind.tripPass ? 'This holiday' : 'Holidays through the year');
}

/// Launch pricing (USD). Stores localise it per country.
abstract final class Pricing {
  /// The same IDs in App Store Connect and Google Play (base plan
  /// `travary-annual-pass`). RevenueCat's `plus` entitlement is the Annual
  /// Pass; the Holiday Pass is a consumable, claimed for a trip by the server.
  static const plusAnnualProductId = 'travary_annual_pass';
  static const tripPassProductId = 'holiday_pass';

  /// RevenueCat's entitlement for the Annual Pass.
  static const plusEntitlement = 'plus';

  static const plusAnnualUsd = 34.99;
  static const tripPassUsd = 14.99;

  /// Everyone on a Plus organiser's trips, including them.
  static const familySize = 6;

  /// Smart Imports on the free plan, lifetime.
  static const freeSmartImports = 3;

  /// Ticket files (photos and PDFs) a holiday keeps on the free plan. The
  /// ones already attached always stay; only adding more needs a pass.
  static const freeTicketFiles = 2;

  /// A Trip Pass keeps the trip unlocked this long after it ends.
  static const tripPassGraceDays = 7;

  /// The longest trip a Trip Pass covers. Longer trips are offered Plus.
  static const tripPassMaxDays = 30;

  static const defaults = [
    Offer(kind: OfferKind.plusAnnual, productId: plusAnnualProductId, amount: plusAnnualUsd, currencyCode: 'USD'),
    Offer(kind: OfferKind.tripPass, productId: tripPassProductId, amount: tripPassUsd, currencyCode: 'USD'),
  ];
}
