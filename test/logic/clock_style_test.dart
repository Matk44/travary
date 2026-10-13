import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/formatters.dart';

void main() {
  tearDown(() => ClockStyle.use24Hour = false);

  test('twelve-hour by default', () {
    expect(formatClock(const ClockTime(9, 0)), '9:00am');
    expect(formatClock(const ClockTime(19, 15)), '7:15pm');
    expect((formatClockShort(const ClockTime(0, 5)), formatClockPeriod(const ClockTime(0, 5))), ('12:05', 'am'));
  });

  test('a twenty-four-hour phone gets twenty-four-hour times everywhere', () {
    ClockStyle.use24Hour = true;
    expect(formatClock(const ClockTime(9, 0)), '09:00');
    expect(formatClock(const ClockTime(19, 15)), '19:15');
    expect(formatClock(const ClockTime(0, 5)), '00:05');
    // The time rail's two lines: the time, and nothing under it.
    expect((formatClockShort(const ClockTime(19, 15)), formatClockPeriod(const ClockTime(19, 15))), ('19:15', ''));
  });
}
