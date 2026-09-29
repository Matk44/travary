import '../domain/domain.dart';
import 'countdown_text.dart';
import 'formatters.dart';
import 'trip_plan.dart';

/// Everything a coming trip's postcard on the Trips tab says, already
/// worded: the countdown, place, dates and facts on its hanging tag.
class TripPostcardText {
  const TripPostcardText({
    required this.days,
    required this.daysLabel,
    required this.place,
    required this.dates,
    required this.facts,
    required this.semanticLabel,
  });

  /// The large number: "58".
  final String days;

  /// Under it: "DAYS", or "DAY" for tomorrow.
  final String daysLabel;

  /// "Lake District".
  final String place;

  /// "25–28 Nov 2026".
  final String dates;

  /// "4 days", "3 bookings" (just the days before anything is booked).
  final List<String> facts;

  /// [facts] on one line: "4 days · 3 bookings".
  String get factsLine => facts.join(' · ');

  /// The whole postcard for screen readers: "Lake District, 58 days to
  /// go, 25 to 28 November 2026. 4 days, 3 bookings."
  final String semanticLabel;
}

/// The postcard wording for [plan] as seen on [today], or null if it has
/// no dates or has already started. Built on [countdownTextFor], so the
/// count is between calendar dates, never a clock duration.
TripPostcardText? tripPostcardTextFor(TripPlan plan, LocalDate today) {
  final countdown = countdownTextFor(plan, today);
  if (countdown == null) return null;
  final days = today.daysUntil(plan.start!);
  final facts = [countdown.duration, if (plan.bookings.isNotEmpty) countdown.bookings];
  return TripPostcardText(
    days: countdown.days,
    daysLabel: days == 1 ? 'DAY' : 'DAYS',
    place: countdown.place,
    dates: countdown.dates,
    facts: List.unmodifiable(facts),
    semanticLabel:
        '${countdown.place}, ${days == 1 ? '1 day to go' : '$days days to go'}, '
        '${formatDateRangeLong(plan.start!, plan.end!)}. ${facts.join(', ')}.',
  );
}
