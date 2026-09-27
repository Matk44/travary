import 'package:intl/intl.dart';

import '../domain/domain.dart';
import 'trip_plan.dart';

/// Bookings within this many days of a trip are assumed to belong to it.
const tripMarginDays = 2;

/// Finds the trip a booking dated [start]–[end] belongs to, or null when it
/// needs a new trip. Prefers a trip the dates actually fall inside, then the
/// nearest one within [tripMarginDays].
TripPlan? findTripFor(
  LocalDate start,
  LocalDate end,
  List<TripPlan> plans, {
  int marginDays = tripMarginDays,
}) {
  TripPlan? best;
  var bestGap = marginDays + 1;
  for (final plan in plans.where((p) => p.hasDates)) {
    final gap = gapBetween(start, end, plan.start!, plan.end!);
    if (gap < bestGap) {
      best = plan;
      bestGap = gap;
    }
  }
  return best;
}

/// Bookings read from one file (a confirmation email, an itinerary PDF)
/// belong together when they're this close.
const sameSourceMarginDays = 30;

/// A return flight joins the trip its outbound flight started, even days
/// later: "Lisbon to London" on the 8th goes with "London to Lisbon" on the
/// 3rd. Returns null when [booking] isn't such a flight.
TripPlan? findReturnFlightTrip(Booking booking, List<TripPlan> plans) {
  final route = _route(booking);
  if (route == null) return null;
  TripPlan? best;
  for (final plan in plans.where((p) => p.hasDates)) {
    final daysAfterStart = plan.start!.daysUntil(booking.startDate);
    if (daysAfterStart < 0 || daysAfterStart > sameSourceMarginDays) continue;
    final isReturn = plan.bookings.any((b) {
      final outbound = _route(b);
      return outbound != null && outbound.from == route.to && outbound.to == route.from;
    });
    if (isReturn && (best == null || plan.start!.isAfter(best.start!))) best = plan;
  }
  return best;
}

({String from, String to})? _route(Booking booking) {
  if (booking.kind != BookingKind.flight) return null;
  final match = RegExp(r'^\s*(.+?)\s+to\s+(.+?)\s*$', caseSensitive: false).firstMatch(booking.title);
  if (match == null) return null;
  return (from: match.group(1)!.toLowerCase(), to: match.group(2)!.toLowerCase());
}

/// Days between two date ranges; 0 when they overlap.
int gapBetween(LocalDate aStart, LocalDate aEnd, LocalDate bStart, LocalDate bEnd) {
  if (aEnd.isBefore(bStart)) return aEnd.daysUntil(bStart);
  if (bEnd.isBefore(aStart)) return bEnd.daysUntil(aStart);
  return 0;
}

/// A sensible name for a trip created automatically from [booking].
/// The traveller can rename it later.
String suggestTripTitle(Booking booking) {
  final title = booking.title.trim();
  if (booking.kind == BookingKind.flight) {
    final match = RegExp(r'\bto\s+(.+)$', caseSensitive: false).firstMatch(title);
    if (match != null) return _capitalise(match.group(1)!.trim());
  }
  final location = booking.location?.trim() ?? '';
  if (location.isNotEmpty && location.length <= 24) return location;
  return '${DateFormat('MMMM').format(booking.startDate.toDateTime())} trip';
}

String _capitalise(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
