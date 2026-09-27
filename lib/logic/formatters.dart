import 'package:intl/intl.dart';

import '../domain/domain.dart';

/// "9:00am", "7:15pm".
String formatClock(ClockTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final suffix = time.hour < 12 ? 'am' : 'pm';
  return '$hour:${time.minute.toString().padLeft(2, '0')}$suffix';
}

/// "Wed 14 Oct".
String formatDayShort(LocalDate date) =>
    DateFormat('EEE d MMM').format(date.toDateTime());

/// "Wednesday 14 October".
String formatDayLong(LocalDate date) =>
    DateFormat('EEEE d MMMM').format(date.toDateTime());

/// "14 Oct".
String formatDayMonth(LocalDate date) =>
    DateFormat('d MMM').format(date.toDateTime());

/// "14 Oct 2026".
String formatDate(LocalDate date) =>
    DateFormat('d MMM y').format(date.toDateTime());

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

/// "Good morning" / "Good afternoon" / "Good evening".
String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
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
