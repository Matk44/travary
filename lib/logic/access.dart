import 'dart:math';

import '../domain/domain.dart';
import 'trip_assignment.dart';
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
/// - A Trip Pass unlocks them on one trip of at most 30 days, until a week
///   after it ends. It grows with its trip (the flight home added later)
///   but never moves to another holiday ([tripPassLastDay]).
/// - "Plus travels with the trip": a trip stamped premium by the server
///   (its organiser has Plus or a pass) unlocks them for everyone on it.
/// - Free: a few Smart Imports to try it, nothing else premium.
/// - Never gated: bookings, tickets, Today, Wallet, sharing a read-only view.
class AccessPolicy {
  const AccessPolicy(this.entitlements, this.now);

  final Entitlements entitlements;
  final DateTime now;

  bool get hasPlus => entitlements.plus?.activeAt(now) ?? false;

  int get freeSmartImportsLeft => max(0, Pricing.freeSmartImports - entitlements.smartImportsUsed);

  /// The Trip Pass bought for [plan], on or not.
  TripPass? tripPassFor(TripPlan plan) => entitlements.tripPasses[plan.id];

  /// Whether a Trip Pass covers [plan] now ([tripPassLastDay]).
  bool hasTripPass(TripPlan plan) {
    final pass = tripPassFor(plan);
    if (pass == null) return false;
    return now.isBefore(tripPassLastDay(pass, plan.start, plan.end).addDays(1).toDateTime());
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
        freeSmartImportsLeft > 0 ? AccessDecision.freeUse(freeSmartImportsLeft) : const AccessDecision.locked(),
      PremiumFeature.familySharing ||
      PremiumFeature.ticketBackup ||
      PremiumFeature.flightAlerts => const AccessDecision.locked(),
    };
  }

  /// A Trip Pass only makes sense for a trip with dates that hasn't ended,
  /// of at most [Pricing.tripPassMaxDays].
  bool canBuyTripPassFor(TripPlan? plan) {
    if (plan == null || !plan.hasDates || hasPlus) return false;
    if (hasTripPass(plan) || isTooLongForTripPass(plan)) return false;
    return !plan.end!.isBefore(LocalDate.fromDateTime(now));
  }

  /// A trip longer than a Trip Pass covers: it's offered Plus instead.
  bool isTooLongForTripPass(TripPlan? plan) => plan != null && plan.dayCount > Pricing.tripPassMaxDays;
}

/// The last day [pass] keeps Plus on its trip, which now runs [start] to
/// [end]: a week after the trip ends while it's still the holiday the pass
/// was bought for (overlapping those dates, at most
/// [Pricing.tripPassMaxDays] long), so adding the flight home or a few more
/// days stays covered. Otherwise a week after the dates it was bought for:
/// moving the trip to another time, or making it another holiday, never
/// takes the pass along.
LocalDate tripPassLastDay(TripPass pass, LocalDate? start, LocalDate? end) {
  if (start == null || end == null || !end.isAfter(pass.end)) return pass.lastDay;
  final sameHoliday =
      gapBetween(start, end, pass.start, pass.end) == 0 && start.daysUntil(end) + 1 <= Pricing.tripPassMaxDays;
  return sameHoliday ? end.addDays(Pricing.tripPassGraceDays) : pass.lastDay;
}

/// The Trip Pass to buy for [plan]: the dates it has now. [plan] must have
/// dates.
TripPass newTripPassFor(TripPlan plan) => TripPass(tripId: plan.id, start: plan.start!, end: plan.end!);
