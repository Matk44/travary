import '../domain/domain.dart';
import 'destinations.dart';
import 'formatters.dart';
import 'trip_plan.dart';

/// The luggage tag on a trip's own postcard (the trip screen): its name,
/// dates and where it stands: "6 days to go", "Day 3 of 20", "Trip over".
class TripHeroText {
  const TripHeroText({
    this.place,
    required this.title,
    required this.dates,
    required this.status,
    required this.semanticLabel,
  });

  /// Where it goes, when the name doesn't say: "JAPAN" over "Our Japanese
  /// adventure". Null when it does ("Japan holiday"), or nobody said.
  final String? place;

  /// "Japan".
  final String title;

  /// "11–30 Oct 2026", or "No dates yet".
  final String dates;

  /// "6 days to go", "Tomorrow", "Starts today", "Day 3 of 20", "Last day",
  /// "Trip over".
  final String status;

  /// The tag for screen readers: "Japan, 11 to 30 October 2026, 6 days to go."
  final String semanticLabel;
}

TripHeroText tripHeroTextFor(TripPlan plan, LocalDate today) {
  final name = plan.trip.title.trim();
  final title = name.isEmpty ? 'Your trip' : name;
  final destination = plan.trip.destination;
  // Said already when the name has the place as a whole word ("Japan
  // holiday"), not inside another ("Our Japanese adventure").
  final said =
      destination != null &&
      RegExp(
        '(^|[^a-z0-9])${RegExp.escape(foldPlaceText(destination.name))}(\$|[^a-z0-9])',
      ).hasMatch(foldPlaceText(title));
  final place = destination == null || said ? null : destination.label.toUpperCase();
  final start = plan.start;
  final end = plan.end;
  if (start == null || end == null) {
    return TripHeroText(
      place: place,
      title: title,
      dates: 'No dates yet',
      status: 'Add dates or a booking',
      semanticLabel: '$title, no dates yet.',
    );
  }
  final String status;
  switch (plan.phaseOn(today)) {
    case TripPhase.upcoming:
      final days = today.daysUntil(start);
      status = days == 1 ? 'Tomorrow' : '$days days to go';
    case TripPhase.active:
      final day = plan.dayNumber(today)!;
      if (day == 1) {
        status = 'Starts today';
      } else if (today == end) {
        status = 'Last day';
      } else {
        status = 'Day $day of ${plan.dayCount}';
      }
    case TripPhase.past:
      status = 'Trip over';
  }
  return TripHeroText(
    place: place,
    title: title,
    dates: formatDateRange(start, end),
    status: status,
    semanticLabel: '$title, ${formatDateRangeLong(start, end)}, ${status.toLowerCase()}.',
  );
}
