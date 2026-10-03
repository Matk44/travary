import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/countdown_text.dart';
import 'package:travary/logic/formatters.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  TripPlan lakes({int bookings = 3, String title = 'Lake District'}) => TripPlan(
    trip('lakes', title: title, plannedStart: d(11, 25), plannedEnd: d(11, 28)),
    [for (var i = 0; i < bookings; i++) booking('b$i', BookingKind.activity, d(11, 25 + i), tripId: 'lakes')],
  );

  group('the countdown to the next trip', () {
    test('says everything the hero shows, already worded', () {
      final text = countdownTextFor(lakes(), d(9, 28))!;
      expect(text.heading, 'NEXT ADVENTURE');
      expect(text.eyebrow, 'NEXT TRIP');
      expect(text.days, '58');
      expect(text.daysLabel, 'DAYS TO GO');
      expect(text.place, 'Lake District');
      expect(text.dates, '25–28 Nov 2026');
      expect(text.duration, '4 days');
      expect(text.bookings, '3 bookings');
      expect(text.semanticLabel, 'Lake District, 58 days to go, 25 to 28 November 2026.');
    });

    test('one day, one booking, none yet', () {
      final tomorrow = countdownTextFor(lakes(bookings: 1), d(11, 24))!;
      expect(tomorrow.days, '1');
      expect(tomorrow.daysLabel, 'DAY TO GO');
      expect(tomorrow.bookings, '1 booking');
      expect(tomorrow.semanticLabel, 'Lake District, 1 day to go, 25 to 28 November 2026.');
      expect(countdownTextFor(lakes(bookings: 0), d(11, 24))!.bookings, 'No bookings yet');

      final dayTrip = TripPlan(trip('day', title: 'Bath'), [booking('spa', BookingKind.activity, d(10, 3))]);
      final text = countdownTextFor(dayTrip, d(10, 1))!;
      expect(text.duration, '1 day');
      expect(text.dates, '3 Oct 2026');
      expect(text.semanticLabel, 'Bath, 2 days to go, 3 October 2026.');
    });

    test('only before the trip starts, and only with dates', () {
      expect(countdownTextFor(lakes(), d(11, 25)), isNull, reason: 'it has started');
      expect(countdownTextFor(lakes(), d(11, 30)), isNull, reason: 'it is over');
      expect(countdownTextFor(TripPlan(trip('undated'), const []), d(9, 28)), isNull);
    });

    test('a nameless trip still reads', () {
      expect(countdownTextFor(lakes(title: '  '), d(9, 28))!.place, 'Your trip');
    });

    test('counts calendar dates, so daylight saving never moves the number', () {
      // Clocks go forward on 29 March 2026 and back on 25 October 2026 in
      // the UK (8 and 1 November in the US). A 23- or 25-hour day still
      // counts as one day.
      final spring = TripPlan(trip('spring', plannedStart: d(3, 30), plannedEnd: d(4, 2)), const []);
      expect(countdownTextFor(spring, d(3, 28))!.days, '2');
      expect(countdownTextFor(spring, d(3, 29))!.days, '1');
      final autumn = TripPlan(trip('autumn', plannedStart: d(11, 2), plannedEnd: d(11, 9)), const []);
      expect(countdownTextFor(autumn, d(10, 24))!.days, '9');
      expect(countdownTextFor(autumn, d(10, 31))!.days, '2');
      // Any time of day on the same date is the same count, whatever the
      // clock or zone: Today reads the date, never a duration.
      for (final now in [
        DateTime(2026, 10, 25, 0, 1),
        DateTime(2026, 10, 25, 23, 59),
        DateTime.utc(2026, 10, 25, 12),
      ]) {
        expect(countdownTextFor(lakes(), LocalDate.fromDateTime(now))!.days, '31', reason: '$now');
      }
      // Across the year boundary and a leap day.
      final newYear = TripPlan(
        trip('ny', plannedStart: LocalDate(2028, 3, 1), plannedEnd: LocalDate(2028, 3, 2)),
        const [],
      );
      expect(countdownTextFor(newYear, LocalDate(2027, 12, 31))!.days, '61');
    });
  });

  group('long date ranges for screen readers', () {
    test('same month, two months, two years, one day', () {
      expect(formatDateRangeLong(d(11, 25), d(11, 28)), '25 to 28 November 2026');
      expect(formatDateRangeLong(d(9, 28), d(10, 3)), '28 September to 3 October 2026');
      expect(formatDateRangeLong(d(12, 28), LocalDate(2027, 1, 3)), '28 December 2026 to 3 January 2027');
      expect(formatDateRangeLong(d(11, 25), d(11, 25)), '25 November 2026');
    });
  });
}
