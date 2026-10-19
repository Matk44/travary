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

  /// Remote offering metadata (or the store product title). The app names
  /// the two plans itself ([displayTitle]), whatever the store calls them.
  final String? title;
  final String? scope;
  final String? packageId;
  final String? offeringId;

  /// "Annual Pass" (the yearly plan) or "Holiday Pass" (one holiday):
  /// the same two names everywhere in the app.
  String get displayTitle => kind == OfferKind.tripPass ? 'Holiday Pass' : 'Annual Pass';
  String get displayScope => scope ?? (kind == OfferKind.tripPass ? 'This holiday' : 'Every holiday for a year');
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

  /// Smart Imports on the free plan, lifetime. Each one keeps its source file
  /// as the booking's ticket, so this matches [freeTicketFiles].
  static const freeSmartImports = 2;

  /// Files (photos and PDFs) a holiday keeps on the free plan: the "tickets"
  /// attached to bookings. The ones already attached always stay; only adding
  /// more needs a pass.
  static const freeTicketFiles = 2;

  /// Bookings a holiday takes on the free plan (owner, 20 Oct 2026): adding
  /// more needs a pass until the holiday starts, and from then on nothing
  /// is ever blocked. Notes don't count, and nothing already in is locked.
  /// The live number comes from Firestore's `config/freePlan`
  /// ([FreePlanLimits]); this is the default.
  static const freeBookingsPerHoliday = 12;

  /// The trip page counts a free holiday's bookings once this few are left
  /// ("9 of 12 free bookings used").
  static const bookingCountShownWithin = 3;

  /// A Trip Pass keeps the trip unlocked this long after it ends.
  static const tripPassGraceDays = 7;

  /// The longest trip a Trip Pass covers. Longer trips are offered Plus.
  static const tripPassMaxDays = 30;

  static const defaults = [
    Offer(kind: OfferKind.plusAnnual, productId: plusAnnualProductId, amount: plusAnnualUsd, currencyCode: 'USD'),
    Offer(kind: OfferKind.tripPass, productId: tripPassProductId, amount: tripPassUsd, currencyCode: 'USD'),
  ];
}

/// The free plan's numbers that can change without a release, from
/// Firestore's `config/freePlan` (`{bookingsPerHoliday: 12}`).
class FreePlanLimits {
  const FreePlanLimits({this.bookingsPerHoliday = Pricing.freeBookingsPerHoliday});

  /// What `config/freePlan` says. A missing number, or one outside
  /// [minBookings] to [maxBookings] (a typo, most likely), keeps the
  /// default.
  factory FreePlanLimits.fromJson(Map<String, Object?>? json) {
    final bookings = json?['bookingsPerHoliday'];
    final whole = bookings is num && bookings.isFinite && bookings == bookings.roundToDouble()
        ? bookings.toInt()
        : null;
    return FreePlanLimits(
      bookingsPerHoliday: whole != null && whole >= minBookings && whole <= maxBookings
          ? whole
          : Pricing.freeBookingsPerHoliday,
    );
  }

  static const defaults = FreePlanLimits();

  /// The numbers `config/freePlan` may set the cap to.
  static const minBookings = 5;
  static const maxBookings = 1000;

  /// Bookings a free holiday takes before adding more needs a pass.
  final int bookingsPerHoliday;

  @override
  bool operator ==(Object other) => other is FreePlanLimits && other.bookingsPerHoliday == bookingsPerHoliday;

  @override
  int get hashCode => bookingsPerHoliday.hashCode;
}
