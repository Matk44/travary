import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/trip_calendar.dart';

import '../helpers.dart';

void main() {
  test('whole weeks from the trip\'s first week to its last, starting on Monday', () {
    // Mon 12 to Sun 18 October 2026: exactly one week.
    final weeks = calendarWeeks(d(10, 12), d(10, 18));
    expect(weeks, [
      [for (var day = 12; day <= 18; day++) d(10, day)],
    ]);

    // Wed 14 to Tue 20: two weeks, filled out either side.
    final two = calendarWeeks(d(10, 14), d(10, 20));
    expect(two.length, 2);
    expect(two.first.first, d(10, 12));
    expect(two.last.last, d(10, 25));
    for (final week in two) {
      expect(week.length, 7);
      expect(week.first.weekday, DateTime.monday);
    }
  });

  test('weeks can start on Sunday', () {
    final weeks = calendarWeeks(d(10, 14), d(10, 17), firstWeekday: DateTime.sunday);
    expect(weeks.single.first, d(10, 11));
    expect(weeks.single.first.weekday, DateTime.sunday);
    expect(weeks.single.last, d(10, 17));
  });

  test('a trip across months and years runs on without a break', () {
    final weeks = calendarWeeks(const LocalDate(2026, 12, 29), const LocalDate(2027, 1, 3));
    expect(weeks.length, 1);
    expect(weeks.single.first, const LocalDate(2026, 12, 28));
    expect(weeks.single.last, const LocalDate(2027, 1, 3));
  });

  test('a one-day trip is its one week', () {
    final weeks = calendarWeeks(d(10, 14), d(10, 14));
    expect(weeks.single, contains(d(10, 14)));
  });
}
