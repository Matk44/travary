import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/date_range_selection.dart';

void main() {
  const nov8 = LocalDate(2026, 11, 8);
  const nov15 = LocalDate(2026, 11, 15);
  const nov3 = LocalDate(2026, 11, 3);

  test('the first tap leaves, the next comes home', () {
    final first = tapHolidayDay(nov8);
    expect(first, (start: nov8, end: null));
    expect(tapHolidayDay(nov15, start: first.start, end: first.end), (start: nov8, end: nov15));
  });

  test('a day before the first starts again from there', () {
    expect(tapHolidayDay(nov3, start: nov8), (start: nov3, end: null));
  });

  test('once both are chosen, a tap starts a new holiday', () {
    expect(tapHolidayDay(nov3, start: nov8, end: nov15), (start: nov3, end: null));
    expect(tapHolidayDay(nov15, start: nov8, end: nov15), (start: nov15, end: null));
  });

  test('the same day twice is a day trip', () {
    expect(tapHolidayDay(nov8, start: nov8), (start: nov8, end: nov8));
    expect(holidayDatesHint(start: nov8, end: nov8), 'A day trip');
  });

  test('the hint guides each tap, then counts the nights', () {
    expect(holidayDatesHint(), 'Tap the day you leave');
    expect(holidayDatesHint(start: nov8), 'Now the day you come home');
    expect(holidayDatesHint(start: nov8, end: nov15), '7 nights');
    expect(holidayDatesHint(start: nov8, end: const LocalDate(2026, 11, 9)), '1 night');
  });

  test('months run across the year end, each ending on its last day', () {
    final months = monthsBetween(const LocalDate(2026, 11, 20), const LocalDate(2027, 2, 3));
    expect(months, [
      const LocalDate(2026, 11, 1),
      const LocalDate(2026, 12, 1),
      const LocalDate(2027, 1, 1),
      const LocalDate(2027, 2, 1),
    ]);
    expect(lastDayOfMonth(const LocalDate(2028, 2, 1)), const LocalDate(2028, 2, 29));
    expect(lastDayOfMonth(const LocalDate(2026, 12, 1)), const LocalDate(2026, 12, 31));
  });
}
