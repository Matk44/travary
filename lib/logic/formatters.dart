import 'package:intl/intl.dart';

import '../domain/domain.dart';

/// How the app writes the time of day: the phone's own choice of a
/// twenty-four-hour clock. Set from the phone's setting at the app's root
/// (`TravaryApp`), so every ticket and card follows it.
abstract final class ClockStyle {
  static bool use24Hour = false;
}

/// "9:00am", "7:15pm", or "09:00", "19:15" on a twenty-four-hour phone.
String formatClock(ClockTime time) => '${formatClockShort(time)}${formatClockPeriod(time)}';

/// "9:00", "7:15": twelve-hour, no am/pm, for the day's time rail (the
/// am/pm goes underneath). "09:00", "19:15" on a twenty-four-hour phone.
String formatClockShort(ClockTime time) {
  if (ClockStyle.use24Hour) return formatClock24(time);
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour:${time.minute.toString().padLeft(2, '0')}';
}

/// "am" or "pm"; nothing on a twenty-four-hour phone.
String formatClockPeriod(ClockTime time) {
  if (ClockStyle.use24Hour) return '';
  return time.hour < 12 ? 'am' : 'pm';
}

/// "28° Sunny": a forecast for the header pill.
String formatWeather(WeatherReport report) => '${report.temperature}° ${report.condition.label}';

/// "Wed 14 Oct".
String formatDayShort(LocalDate date) => DateFormat('EEE d MMM').format(date.toDateTime());

/// "Wednesday 14 October".
String formatDayLong(LocalDate date) => DateFormat('EEEE d MMMM').format(date.toDateTime());

/// "14 Oct".
String formatDayMonth(LocalDate date) => DateFormat('d MMM').format(date.toDateTime());

/// "14" and "Oct", for a date set on two lines.
({String day, String month}) formatDayMonthParts(LocalDate date) {
  final value = date.toDateTime();
  return (day: DateFormat('d').format(value), month: DateFormat('MMM').format(value));
}

/// "14 Oct 2026".
String formatDate(LocalDate date) => DateFormat('d MMM y').format(date.toDateTime());

/// "14 OCT 2026", for a date printed in a ticket's box.
String formatTicketDate(LocalDate date) => DateFormat('d MMM y').format(date.toDateTime()).toUpperCase();

/// "20:55": always twenty-four-hour (a departures board's clock).
String formatClock24(ClockTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

/// "14–16 Oct", "30 Oct – 2 Nov": a span within a trip, whose year the trip
/// already shows. Spans across a new year keep both years.
String formatDayMonthRange(LocalDate start, LocalDate end) {
  if (start == end) return formatDayMonth(start);
  if (start.year != end.year) return formatDateRange(start, end);
  if (start.month != end.month) return '${formatDayMonth(start)} – ${formatDayMonth(end)}';
  return '${start.day}–${formatDayMonth(end)}';
}

/// "November 2026": a calendar month's heading.
String formatMonthYear(LocalDate month) => DateFormat('MMMM y').format(month.toDateTime());

/// "1 night", "4 nights".
String formatNights(int nights) => nights == 1 ? '1 night' : '$nights nights';

/// "12–18 Oct 2026", "28 Sep – 3 Oct 2026", "28 Dec 2026 – 3 Jan 2027".
String formatDateRange(LocalDate start, LocalDate end) {
  final s = start.toDateTime();
  final e = end.toDateTime();
  if (start == end) return DateFormat('d MMM y').format(s);
  if (start.year != end.year) {
    return '${DateFormat('d MMM y').format(s)} – ${DateFormat('d MMM y').format(e)}';
  }
  if (start.month != end.month) {
    return '${DateFormat('d MMM').format(s)} – ${DateFormat('d MMM y').format(e)}';
  }
  return '${start.day}–${DateFormat('d MMM y').format(e)}';
}

/// [formatDateRange] spelled out for screen readers: "25 to 28 November
/// 2026", "28 September to 3 October 2026", "28 December 2026 to 3
/// January 2027".
String formatDateRangeLong(LocalDate start, LocalDate end) {
  final s = start.toDateTime();
  final e = end.toDateTime();
  final full = DateFormat('d MMMM y');
  if (start == end) return full.format(s);
  if (start.year != end.year) return '${full.format(s)} to ${full.format(e)}';
  if (start.month != end.month) return '${DateFormat('d MMMM').format(s)} to ${full.format(e)}';
  return '${start.day} to ${full.format(e)}';
}

/// "Good morning" / "Good afternoon" / "Good evening".
String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// What heads a day that isn't [today] ("Good morning" is for today only):
/// "Tomorrow", "Yesterday", else the weekday, "Thursday".
String dayHeading(LocalDate day, LocalDate today) {
  final days = today.daysUntil(day);
  if (days == 1) return 'Tomorrow';
  if (days == -1) return 'Yesterday';
  return DateFormat('EEEE').format(day.toDateTime());
}

/// "today", "tomorrow", "in 12 days".
String relativeDays(int days) {
  if (days == 0) return 'today';
  if (days == 1) return 'tomorrow';
  if (days == -1) return 'yesterday';
  return days > 0 ? 'in $days days' : '${-days} days ago';
}

/// "ONE", "TWO" ... for ticket stubs ("ADMIT TWO"). Falls back to digits.
String numberWord(int n) {
  const words = [
    'ZERO', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', //
    'SIX', 'SEVEN', 'EIGHT', 'NINE', 'TEN',
  ];
  return n >= 0 && n < words.length ? words[n] : '$n';
}
