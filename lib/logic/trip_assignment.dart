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
    final gap = _gapBetween(start, end, plan.start!, plan.end!);
    if (gap < bestGap) {
      best = plan;
      bestGap = gap;
    }
  }
  return best;
}

/// Days between two date ranges; 0 when they overlap.
int _gapBetween(LocalDate aStart, LocalDate aEnd, LocalDate bStart, LocalDate bEnd) {
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
