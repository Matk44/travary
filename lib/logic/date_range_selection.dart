import '../domain/domain.dart';
import 'formatters.dart';

/// Choosing a holiday's dates by tapping days: the first tap is the day
/// they leave, the next the day they come home. A day before the first one
/// starts again from there, as does any tap once both are chosen. The same
/// day twice is a day trip.
({LocalDate? start, LocalDate? end}) tapHolidayDay(LocalDate day, {LocalDate? start, LocalDate? end}) {
  if (start == null || end != null || day.isBefore(start)) return (start: day, end: null);
  return (start: start, end: day);
}

/// What the dates sheet says under the two dates.
String holidayDatesHint({LocalDate? start, LocalDate? end}) {
  if (start == null) return 'Tap the day you leave';
  if (end == null) return 'Now the day you come home';
  final nights = start.daysUntil(end);
  return nights == 0 ? 'A day trip' : formatNights(nights);
}

/// The first of each month from [first]'s to [last]'s.
List<LocalDate> monthsBetween(LocalDate first, LocalDate last) => [
  for (
    var m = LocalDate(first.year, first.month, 1);
    !m.isAfter(last);
    m = LocalDate.fromDateTime(DateTime(m.year, m.month + 1))
  )
    m,
];

/// The last day of [month]'s month.
LocalDate lastDayOfMonth(LocalDate month) => LocalDate.fromDateTime(DateTime(month.year, month.month + 1, 0));
