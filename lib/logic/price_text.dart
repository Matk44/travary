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
/// paywall: family first, then every ticket, then Smart Import, and flight
/// alerts once they're on sale. [first]: the one they just reached for,
/// moved to the top.
List<String> passBenefits({PremiumFeature? first, bool flightAlerts = false}) {
  final lines = <PremiumFeature, String>{
    PremiumFeature.familySharing: 'Everyone coming gets the plan and their own tickets',
    PremiumFeature.ticketBackup:
        'Every ticket and confirmation kept and backed up (free keeps ${Pricing.freeTicketFiles})',
    PremiumFeature.smartImport: 'I\'ll read the rest of your confirmations for you',
    if (flightAlerts) PremiumFeature.flightAlerts: 'Delays and new times on everyone\'s phone',
  };
  final top = lines[first];
  return [
    ?top,
    for (final entry in lines.entries)
      if (entry.key != first) entry.value,
  ];
}
