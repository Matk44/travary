import 'dart:math';

import '../domain/domain.dart';
import 'trip_assignment.dart';
import 'trip_plan.dart';

/// The answer to "can I use this?".
class AccessDecision {
  const AccessDecision._(this.allowed, {this.freeUsesLeft, this.viaTripPremium = false, this.tripId});

  const AccessDecision.locked() : this._(false);
  const AccessDecision.unlocked({bool viaTrip = false, String? tripId})
    : this._(true, viaTripPremium: viaTrip, tripId: tripId);
  const AccessDecision.freeUse(int left) : this._(true, freeUsesLeft: left);

  final bool allowed;

  /// Set when allowed only thanks to the free allowance: how many free uses
  /// remain *before* this one.
  final int? freeUsesLeft;

  /// Allowed because someone else's Plus or Trip Pass covers the trip.
  final bool viaTripPremium;

  /// The trip whose Trip Pass (or Plus travelling with it) allowed it: the
  /// server checks the same trip (Smart Import sends it).
  final String? tripId;

  bool get isFreeUse => freeUsesLeft != null;
}

/// Who gets what. Pure rules, so they're easy to test and the same
/// everywhere in the app.
///
/// - Plus unlocks every premium feature on every trip.
/// - A Trip Pass unlocks them on one trip of at most 30 days, until a week
///   after it ends. It grows with its trip (the flight home added later)
///   but never moves to another holiday, and a trip moved or stretched to
///   before the dates it was bought for loses it ([tripPassLastDay]).
/// - "Plus travels with the trip": a trip stamped premium by the server
///   (its organiser has Plus or a pass) unlocks them for everyone on it.
/// - Free: a few Smart Imports to try it, 2 ticket files and
///   [FreePlanLimits.bookingsPerHoliday] bookings a holiday until it starts
///   ([bookingsLeft]), nothing else premium.
/// - Never gated: what's already in (bookings and tickets open, edit and
///   delete), Today, Wallet, sharing a read-only view.
class AccessPolicy {
  const AccessPolicy(this.entitlements, this.now, {this.limits = FreePlanLimits.defaults});

  final Entitlements entitlements;
  final DateTime now;

  /// The free plan's numbers, from `config/freePlan`.
  final FreePlanLimits limits;

  bool get hasPlus => entitlements.plus?.activeAt(now) ?? false;

  /// The traveller's active purchased pass to display. A shared trip's
  /// premium stamp grants access but doesn't say which product was bought.
  OfferKind? purchasedPassFor(TripPlan? plan) {
    if (hasPlus) return OfferKind.plusAnnual;
    if (plan != null && hasTripPass(plan)) return OfferKind.tripPass;
    return null;
  }

  int get freeSmartImportsLeft => max(0, Pricing.freeSmartImports - entitlements.smartImportsUsed);

  /// The Trip Pass bought for [plan], on or not.
  TripPass? tripPassFor(TripPlan plan) => entitlements.tripPasses[plan.id];

  /// Whether a Trip Pass covers [plan] now ([tripPassLastDay]).
  bool hasTripPass(TripPlan plan) {
    final pass = tripPassFor(plan);
    if (pass == null) return false;
    final lastDay = tripPassLastDay(pass, plan.start, plan.end);
    return lastDay != null && now.isBefore(lastDay.addDays(1).toDateTime());
  }

  /// Whether premium features are on for [plan], and why.
  AccessDecision forTrip(TripPlan? plan) {
    if (hasPlus) return const AccessDecision.unlocked();
    if (plan == null) return const AccessDecision.locked();
    if (hasTripPass(plan)) return AccessDecision.unlocked(tripId: plan.id);
    if (plan.trip.premium?.activeAt(now) ?? false) {
      return AccessDecision.unlocked(viaTrip: true, tripId: plan.id);
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
      PremiumFeature.everyBooking ||
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

  /// Ticket files still to add to [plan], which keeps [kept] already
  /// ([ticketFilesIn]): null when there's no limit (a pass, Plus, or Plus
  /// travelling with the trip), else what's left of
  /// [Pricing.freeTicketFiles].
  int? ticketFilesLeft(TripPlan? plan, {required int kept}) =>
      forTrip(plan).allowed ? null : max(0, Pricing.freeTicketFiles - kept);

  /// Whether [adding] more ticket files fit [plan], which keeps [kept].
  bool canAttachTickets(TripPlan? plan, {required int kept, int adding = 1}) {
    final left = ticketFilesLeft(plan, kept: kept);
    return left == null || adding <= left;
  }

  /// Bookings still to add to [plan] on the free plan: null when there's
  /// no limit (a pass, Plus or Plus travelling with the trip; a new
  /// holiday; one that has started, where adding is never blocked), else
  /// what's left of [FreePlanLimits.bookingsPerHoliday] after the ones it
  /// has ([bookingsCountedIn]).
  int? bookingsLeft(TripPlan? plan) {
    if (plan == null || hasStarted(plan) || forTrip(plan).allowed) return null;
    return max(0, limits.bookingsPerHoliday - bookingsCountedIn(plan));
  }

  /// Whether [adding] more bookings fit [plan]. Notes always do
  /// ([countsTowardsFreePlan]): leave them out of [adding].
  bool canAddBookings(TripPlan? plan, {int adding = 1}) {
    final left = bookingsLeft(plan);
    return left == null || adding <= left;
  }

  /// The bookings to count on the trip page ("9 of 12 free bookings
  /// used"): on a free holiday with [Pricing.bookingCountShownWithin] or
  /// fewer left, else null.
  int? bookingCountShown(TripPlan plan) {
    final left = bookingsLeft(plan);
    if (left == null || left > Pricing.bookingCountShownWithin) return null;
    return bookingsCountedIn(plan);
  }

  /// [plan]'s first day has come, by the phone's clock.
  bool hasStarted(TripPlan plan) => plan.start != null && !LocalDate.fromDateTime(now).isBefore(plan.start!);

  /// The holiday the traveller's own Holiday Pass covers while [plan] isn't
  /// covered at all, so the pass desk can say a pass is for its one
  /// holiday: the soonest of [plans] with one on, else null.
  TripPlan? holidayPassElsewhere(TripPlan? plan, Iterable<TripPlan> plans) {
    if (hasPlus || forTrip(plan).allowed) return null;
    final others = [
      for (final other in plans)
        if (other.id != plan?.id && hasTripPass(other)) other,
    ]..sort((a, b) => (a.start ?? LocalDate(9999, 1, 1)).compareTo(b.start ?? LocalDate(9999, 1, 1)));
    return others.firstOrNull;
  }

  /// The Holiday Passes the traveller holds that are still on, soonest
  /// holiday first, with the last day each covers.
  List<({TripPlan plan, LocalDate lastDay})> activeHolidayPasses(Iterable<TripPlan> plans) {
    final out = [
      for (final plan in plans)
        if (hasTripPass(plan))
          (
            plan: plan,
            lastDay: tripPassLastDay(tripPassFor(plan)!, plan.start, plan.end) ?? tripPassFor(plan)!.lastDay,
          ),
    ]..sort((a, b) => a.lastDay.compareTo(b.lastDay));
    return out;
  }
}

/// The bookings on [plan] that count towards a free holiday's
/// [FreePlanLimits.bookingsPerHoliday].
int bookingsCountedIn(TripPlan? plan) =>
    plan == null ? 0 : plan.bookings.where((booking) => countsTowardsFreePlan(booking.kind)).length;

/// Every kind of booking counts towards a free holiday's
/// [FreePlanLimits.bookingsPerHoliday] but notes, which are always free to
/// add (as are the checklist, the packing list and travel documents, which
/// aren't bookings).
bool countsTowardsFreePlan(BookingKind kind) => kind != BookingKind.note;

/// The ticket files [plan]'s bookings keep, leaving out booking [except]
/// (one being edited) and adding [also] (the form's own). One file kept on
/// several bookings (a confirmation read into three) counts once.
int ticketFilesIn(TripPlan? plan, {String? except, Iterable<Attachment> also = const []}) => {
  if (plan != null)
    for (final booking in plan.bookings)
      if (booking.id != except)
        for (final attachment in booking.attachments) _sameFile(attachment),
  for (final attachment in also) _sameFile(attachment),
}.length;

/// Copies of one file share its name and size.
(String, int) _sameFile(Attachment attachment) => (attachment.name, attachment.sizeBytes);

/// The last day [pass] keeps Plus on its trip, which now runs [start] to
/// [end]: a week after the trip ends while it's still the holiday the pass
/// was bought for (overlapping those dates, at most
/// [Pricing.tripPassMaxDays] long), so adding the flight home or a few more
/// days stays covered. Otherwise a week after the dates it was bought for:
/// moving the trip later, or making it another holiday, never takes the
/// pass along.
///
/// Null when the trip now covers other holidays while the pass is on:
/// moved to before the dates bought for, or stretched back more than
/// [Pricing.tripPassMaxDays] before them. Without that, a pass bought for a
/// far-off date would cover every trip until then.
LocalDate? tripPassLastDay(TripPass pass, LocalDate? start, LocalDate? end) {
  if (start == null || end == null) return pass.lastDay;
  if (end.isBefore(pass.start) || start.isBefore(pass.start.addDays(-Pricing.tripPassMaxDays))) return null;
  if (!end.isAfter(pass.end)) return pass.lastDay;
  final sameHoliday =
      gapBetween(start, end, pass.start, pass.end) == 0 && start.daysUntil(end) + 1 <= Pricing.tripPassMaxDays;
  return sameHoliday ? end.addDays(Pricing.tripPassGraceDays) : pass.lastDay;
}

/// The Trip Pass to buy for [plan]: the dates it has now. [plan] must have
/// dates.
TripPass newTripPassFor(TripPlan plan) => TripPass(tripId: plan.id, start: plan.start!, end: plan.end!);
