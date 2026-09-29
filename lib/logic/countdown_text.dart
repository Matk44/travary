import '../domain/domain.dart';
import 'formatters.dart';
import 'trip_plan.dart';

/// Everything the countdown to the next trip says (Today between trips),
/// already worded, like `CardText` for booking cards. The hero only lays
/// these out.
class CountdownText {
  const CountdownText({
    required this.heading,
    required this.eyebrow,
    required this.days,
    required this.daysLabel,
    required this.place,
    required this.dates,
    required this.duration,
    required this.bookings,
    required this.opens,
    required this.action,
    required this.semanticLabel,
  });

  /// Above the postcard: "NEXT ADVENTURE".
  final String heading;

  /// The tag's first line: "NEXT TRIP".
  final String eyebrow;

  /// The large number on the tag: "58".
  final String days;

  /// Under it: "DAYS TO GO", or "DAY TO GO" for tomorrow.
  final String daysLabel;

  /// The trip's name: "Lake District".
  final String place;

  /// "25–28 Nov 2026".
  final String dates;

  /// The three facts below the postcard: "4 days", "3 bookings",
  /// "Opens 25 Nov".
  final String duration;
  final String bookings;
  final String opens;

  /// The button: "View trip".
  final String action;

  /// The whole hero for screen readers: "Lake District, 58 days to go,
  /// 25 to 28 November 2026."
  final String semanticLabel;
}

/// The countdown to [plan] as seen on [today], or null if it has no dates
/// or has already started.
///
/// Days are counted between calendar dates (`LocalDate.daysUntil`), never
/// from a clock duration, so a daylight-saving change or a new time zone
/// can't move the number.
CountdownText? countdownTextFor(TripPlan plan, LocalDate today) {
  final start = plan.start;
  final end = plan.end;
  if (start == null || end == null || !start.isAfter(today)) return null;
  final days = today.daysUntil(start);
  final place = plan.trip.title.trim().isEmpty ? 'Your trip' : plan.trip.title.trim();
  final toGo = days == 1 ? '1 day to go' : '$days days to go';
  return CountdownText(
    heading: 'NEXT ADVENTURE',
    eyebrow: 'NEXT TRIP',
    days: '$days',
    daysLabel: days == 1 ? 'DAY TO GO' : 'DAYS TO GO',
    place: place,
    dates: formatDateRange(start, end),
    duration: _count(plan.dayCount, 'day'),
    bookings: plan.bookings.isEmpty ? 'No bookings yet' : _count(plan.bookings.length, 'booking'),
    opens: 'Opens ${formatDayMonth(start)}',
    action: 'View trip',
    semanticLabel: '$place, $toGo, ${formatDateRangeLong(start, end)}.',
  );
}

String _count(int n, String noun) => n == 1 ? '1 $noun' : '$n ${noun}s';
