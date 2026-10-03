import '../domain/domain.dart';

/// The weeks a trip's calendar shows: from the week [first] falls in to
/// the week [last] falls in, seven days each, starting on [firstWeekday]
/// ([DateTime.monday] to [DateTime.sunday]). Days either side of the trip
/// fill out its first and last weeks.
List<List<LocalDate>> calendarWeeks(LocalDate first, LocalDate last, {int firstWeekday = DateTime.monday}) {
  assert(firstWeekday >= DateTime.monday && firstWeekday <= DateTime.sunday);
  assert(!last.isBefore(first));
  final start = first.addDays(-((first.weekday - firstWeekday) % 7));
  final end = last.addDays((firstWeekday + 6 - last.weekday) % 7);
  return [
    for (var week = start; !week.isAfter(end); week = week.addDays(7)) [for (var d = 0; d < 7; d++) week.addDays(d)],
  ];
}
