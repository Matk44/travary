import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/formatters.dart';

void main() {
  // Wednesday 14 October 2026.
  final today = LocalDate(2026, 10, 14);

  test('the days either side of today are named by how near they are', () {
    expect(dayHeading(today.addDays(1), today), 'Tomorrow');
    expect(dayHeading(today.addDays(-1), today), 'Yesterday');
  });

  test('any other day is its weekday', () {
    expect(dayHeading(today.addDays(2), today), 'Friday');
    expect(dayHeading(today.addDays(-2), today), 'Monday');
    expect(dayHeading(today.addDays(7), today), 'Wednesday');
    expect(dayHeading(today.addDays(58), today), 'Friday');
  });
}
