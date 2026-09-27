import 'dart:math';

import '../domain/domain.dart';
import 'trip_plan.dart';

/// The answer to "can I use this?".
class AccessDecision {
  const AccessDecision._(this.allowed, {this.freeUsesLeft, this.viaTripPremium = false});

  const AccessDecision.locked() : this._(false);
  const AccessDecision.unlocked({bool viaTrip = false}) : this._(true, viaTripPremium: viaTrip);
  const AccessDecision.freeUse(int left) : this._(true, freeUsesLeft: left);

  final bool allowed;

  /// Set when allowed only thanks to the free allowance: how many free uses
  /// remain *before* this one.
  final int? freeUsesLeft;

  /// Allowed because someone else's Plus or Trip Pass covers the trip.
  final bool viaTripPremium;

  bool get isFreeUse => freeUsesLeft != null;
}

/// Who gets what. Pure rules, so they're easy to test and the same
/// everywhere in the app.
///
/// - Plus unlocks every premium feature on every trip.
/// - A Trip Pass unlocks them on one trip, until a week after it ends.
/// - "Plus travels with the trip": a trip stamped premium by the server
///   (its organiser has Plus or a pass) unlocks them for everyone on it.
/// - Free: a few Smart Imports to try it, nothing else premium.
/// - Never gated: bookings, tickets, Today, Wallet, sharing a read-only view.
class AccessPolicy {
  const AccessPolicy(this.entitlements, this.now);

  final Entitlements entitlements;
  final DateTime now;

  bool get hasPlus => entitlements.plus?.activeAt(now) ?? false;

  bool get inTrial => hasPlus && (entitlements.plus?.inTrial ?? false);

  int get freeSmartImportsLeft =>
      max(0, Pricing.freeSmartImports - entitlements.smartImportsUsed);

  bool hasTripPass(TripPlan plan) {
    if (!entitlements.tripPasses.contains(plan.id)) return false;
    final end = plan.end;
    if (end == null) return true;
    return !now.isAfter(end.addDays(Pricing.tripPassGraceDays + 1).toDateTime());
  }

  /// Whether premium features are on for [plan], and why.
  AccessDecision forTrip(TripPlan? plan) {
    if (hasPlus) return const AccessDecision.unlocked();
    if (plan == null) return const AccessDecision.locked();
    if (hasTripPass(plan)) return const AccessDecision.unlocked();
    if (plan.trip.premium?.activeAt(now) ?? false) {
      return const AccessDecision.unlocked(viaTrip: true);
    }
    return const AccessDecision.locked();
  }

  AccessDecision decide(PremiumFeature feature, {TripPlan? trip}) {
    final forTrip = this.forTrip(trip);
    if (forTrip.allowed) return forTrip;
    return switch (feature) {
      PremiumFeature.smartImport =>
        freeSmartImportsLeft > 0
            ? AccessDecision.freeUse(freeSmartImportsLeft)
            : const AccessDecision.locked(),
      PremiumFeature.familySharing ||
      PremiumFeature.ticketBackup ||
      PremiumFeature.flightAlerts => const AccessDecision.locked(),
    };
  }

  /// A Trip Pass only makes sense for a trip with dates that hasn't ended.
  bool canBuyTripPassFor(TripPlan? plan) {
    if (plan == null || !plan.hasDates || hasPlus) return false;
    if (hasTripPass(plan)) return false;
    return !plan.end!.isBefore(LocalDate.fromDateTime(now));
  }
}
