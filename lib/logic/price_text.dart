import 'package:intl/intl.dart';

import '../domain/domain.dart';
import 'access.dart';
import 'formatters.dart';

/// Price wording for the paywall. Prices are framed the way people weigh
/// them on holiday: per month, per person, per day of the trip.

String formatPrice(double amount, String currencyCode) =>
    NumberFormat.simpleCurrency(name: currencyCode).format(amount);

/// "$34.99".
String priceOf(Offer offer) => offer.localizedPrice ?? formatPrice(offer.amount, offer.currencyCode);

/// "$2.92" a month for an annual plan.
String perMonth(Offer offer) => formatPrice(offer.amount / 12, offer.currencyCode);

/// "$0.49" a person a month, for the whole family on an annual plan.
String perPersonPerMonth(Offer offer) => formatPrice(offer.amount / 12 / Pricing.familySize, offer.currencyCode);

/// "$1.14" a day for a Trip Pass on a trip of [days] days.
String perDay(Offer offer, int days) => formatPrice(offer.amount / (days < 1 ? 1 : days), offer.currencyCode);

/// After paying for a Holiday Pass the server couldn't record yet (no
/// signal, or it's busy). It's never "failed": they've been charged.
const passPendingText =
    'Payment received. Your Holiday Pass switches on for this trip as soon as Travary is back online. '
    'There\'s no need to buy it again.';

/// Under "Attach your ticket" on a free holiday ([left] of
/// [Pricing.freeTicketFiles] to add), or the usual line when there's no
/// limit (null).
String attachTicketHint(int? left) => switch (left) {
  null => 'A photo or PDF, ready even offline',
  0 => 'Free holidays keep ${Pricing.freeTicketFiles} tickets. Add every one with a pass',
  1 => 'A photo or PDF, ready offline · 1 more free on this holiday',
  _ => 'A photo or PDF, ready offline · $left free on this holiday',
};

/// After Smart Import saved bookings without their file: the holiday had
/// no free ticket files left.
String ticketsNotKeptText(int bookings) =>
    'The file wasn\'t kept on ${bookings == 1 ? '1 booking' : '$bookings bookings'}: free holidays keep '
    '${Pricing.freeTicketFiles} tickets. A pass keeps every one.';

/// Above a free holiday's "Add a booking" once few are left
/// (`AccessPolicy.bookingCountShown`): [used] of the [cap] bookings it
/// takes before it starts. Full, the offer of a pass is held together and
/// to the dot before it, so a wrapped line never starts with the dot or
/// leaves a word alone.
String bookingCountText(int used, int cap) => used < cap
    ? '$used of $cap free bookings used'
    : '$cap of $cap free bookings used\u00a0· A\u00a0pass\u00a0adds\u00a0more';

/// Smart Import's review list, when the bookings ticked don't fit a free
/// holiday: [left] more of its [cap] fit.
String bookingsOverText(int left, int cap) => left == 0
    ? 'This holiday has its $cap free bookings. A pass makes room for these.'
    : 'Only $left more fit on this free holiday ($cap bookings). Untick some, or get a pass for every one.';

/// On the pass desk for a holiday with no pass, when the traveller's
/// Holiday Pass is for another one ([title]): a pass covers one holiday.
String holidayPassElsewhereText(String title) => 'Your Holiday Pass covers $title only.';

/// On the pass desk (from Profile or a paywall) for a holiday that's
/// covered already, by the traveller's own Holiday Pass for [title], or
/// (null) by someone else's: the Annual Pass is the one left to offer.
String annualUpgradeText(String? title) => title == null
    ? 'This holiday is covered already. The Annual Pass covers every holiday of yours for a year.'
    : 'Your Holiday Pass covers $title. The Annual Pass covers every holiday for a year.';

/// Profile's pass card, under "Annual Pass": the Annual Pass's renewal
/// ([plus] on), else the Holiday Passes on ([passes]: titles, soonest
/// first), else an invitation.
String profilePassLead({PlusSubscription? plus, required List<String> passes}) {
  if (plus != null) {
    return '${plus.willRenew ? 'Renews' : 'Ends'} on ${formatDate(LocalDate.fromDateTime(plus.expiresAt))}.';
  }
  return switch (passes) {
    [] => 'A little help for every holiday.',
    [final one] => 'Your Holiday Pass covers $one. The Annual Pass covers every holiday.',
    _ => 'Your Holiday Passes cover ${passes.length} holidays. The Annual Pass covers every one.',
  };
}

/// A Holiday Pass on Profile's card: its holiday and its last day.
String profileHolidayPassText(String title, LocalDate lastDay) =>
    'Holiday Pass · $title, until ${formatDayMonth(lastDay)}';

/// What a Trip Pass covers, on the trip's details: "Trip Pass, until 30
/// Oct 2026" ([lastDay] from `tripPassLastDay`).
String tripPassCoversText(LocalDate lastDay) => 'Holiday Pass, until ${formatDate(lastDay)}';

/// Under a trip's new dates, [start] to [end], when its Trip Pass won't
/// stretch to them (too long a trip, or another time altogether): when Plus
/// ends instead. Null when the pass covers them.
String? tripPassEndsText(TripPass pass, LocalDate start, LocalDate end) {
  final lastDay = tripPassLastDay(pass, start, end);
  if (lastDay == null) {
    return 'Your Holiday Pass is for ${formatDayMonthRange(pass.start, pass.end)}, so it won\'t cover a trip on these dates.';
  }
  if (!end.addDays(Pricing.tripPassGraceDays).isAfter(lastDay)) return null;
  final ends = 'so it covers this trip until ${formatDate(lastDay)}.';
  if (start.daysUntil(end) + 1 > Pricing.tripPassMaxDays) {
    return 'A Holiday Pass covers trips of up to ${Pricing.tripPassMaxDays} days, $ends';
  }
  return 'Your Holiday Pass is for ${formatDayMonthRange(pass.start, pass.end)}, $ends';
}

/// What the Annual Pass or a Holiday Pass adds, on the pass desk and the
/// paywall: unlimited bookings and the family's plan first, then every
/// ticket, Smart Import, and flight alerts once they're on sale. [first]:
/// the one they just reached for, moved to the top.
///
/// The first line is all most phones have room for (the desk fits, never
/// scrolls), so it carries both of what a pass is bought for: room for
/// every booking ([PremiumFeature.everyBooking] shares it) and everyone
/// on the plan. Keep it short enough for one line on an iPhone 13 mini.
List<String> passBenefits({PremiumFeature? first, bool flightAlerts = false}) {
  final lines = <PremiumFeature, String>{
    PremiumFeature.familySharing: 'Unlimited bookings, and the plan on every phone',
    PremiumFeature.ticketBackup:
        'Every ticket and confirmation kept and backed up (free keeps ${Pricing.freeTicketFiles})',
    PremiumFeature.smartImport: 'I\'ll read the rest of your confirmations for you',
    if (flightAlerts) PremiumFeature.flightAlerts: 'Delays and new times on everyone\'s phone',
  };
  final lead = first == PremiumFeature.everyBooking ? PremiumFeature.familySharing : first;
  final top = lines[lead];
  return [
    ?top,
    for (final entry in lines.entries)
      if (entry.key != lead) entry.value,
  ];
}
