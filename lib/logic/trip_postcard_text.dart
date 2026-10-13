import '../domain/domain.dart';
import 'countdown_text.dart';
import 'formatters.dart';
import 'trip_plan.dart';

/// Everything a trip's postcard on the Trips tab says, already worded: the
/// countdown (or the days left, on a trip you're on), place, dates and facts
/// on its hanging tag.
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

  /// Under it: "DAYS TO GO" ("DAY TO GO" for tomorrow), or "DAYS LEFT" on a
  /// trip you're on.
  final String daysLabel;

  /// "Lake District".
  final String place;

  /// "25–28 Nov 2026".
  final String dates;

  /// "4 days", "3 bookings" (just the days before anything is booked); on
  /// a trip you're on, "Day 3 of 4" in place of its length.
  final List<String> facts;

  /// [facts] on one line: "4 days · 3 bookings".
  String get factsLine => facts.join(' · ');

  /// The whole postcard for screen readers: "Lake District, 58 days to
  /// go, 25 to 28 November 2026. 4 days, 3 bookings."
  final String semanticLabel;
}

/// The postcard wording for [plan] as seen on [today], or null if it has
/// no dates or is over. Built on [countdownTextFor], so the count is
/// between calendar dates, never a clock duration.
TripPostcardText? tripPostcardTextFor(TripPlan plan, LocalDate today) {
  if (plan.hasDates && plan.phaseOn(today) == TripPhase.active) return _underway(plan, today);
  final countdown = countdownTextFor(plan, today);
  if (countdown == null) return null;
  final days = today.daysUntil(plan.start!);
  final facts = [countdown.duration, if (plan.bookings.isNotEmpty) countdown.bookings];
  return TripPostcardText(
    days: countdown.days,
    daysLabel: countdown.daysLabel,
    place: countdown.place,
    dates: countdown.dates,
    facts: List.unmodifiable(facts),
    semanticLabel:
        '${countdown.place}, ${days == 1 ? '1 day to go' : '$days days to go'}, '
        '${formatDateRangeLong(plan.start!, plan.end!)}. ${facts.join(', ')}.',
  );
}

/// A trip you're on: the days left, today counted ("1 DAY LEFT" on the last
/// day), and which day it is.
TripPostcardText _underway(TripPlan plan, LocalDate today) {
  final day = plan.dayNumber(today)!;
  final left = plan.dayCount - day + 1;
  final place = plan.trip.title.trim().isEmpty ? 'Your trip' : plan.trip.title.trim();
  final facts = ['Day $day of ${plan.dayCount}', if (plan.bookings.isNotEmpty) _bookings(plan.bookings.length)];
  return TripPostcardText(
    days: '$left',
    daysLabel: left == 1 ? 'DAY LEFT' : 'DAYS LEFT',
    place: place,
    dates: formatDateRange(plan.start!, plan.end!),
    facts: List.unmodifiable(facts),
    semanticLabel:
        '$place, ${left == 1 ? '1 day' : '$left days'} left, '
        '${formatDateRangeLong(plan.start!, plan.end!)}. ${facts.join(', ')}.',
  );
}

String _bookings(int n) => n == 1 ? '1 booking' : '$n bookings';
