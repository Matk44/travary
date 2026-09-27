import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/day_plan.dart';

import '../helpers.dart';

void main() {
  final today = d(10, 14);
  DateTime at(int hour, [int minute = 0]) => today.toDateTime(ClockTime(hour, minute));

  final park = booking('park', BookingKind.attraction, today, at: const ClockTime(9, 0));
  final lunch = booking('lunch', BookingKind.dining, today, at: const ClockTime(12, 30));
  final dinner = booking('dinner', BookingKind.dining, today, at: const ClockTime(19, 15));
  final hotel = booking('hotel', BookingKind.stay, d(10, 12),
      at: const ClockTime(16, 0), endDate: d(10, 18), until: const ClockTime(11, 0));
  final note = booking('note', BookingKind.note, today);

  group('ordering', () {
    test('all-day entries first, then by time', () {
      final plan = buildDayPlan(today, [dinner, note, lunch, park], at(8));
      expect(plan.entries.map((e) => e.booking.id), ['note', 'park', 'lunch', 'dinner']);
    });

    test('ignores bookings on other days', () {
      final plan = buildDayPlan(today, [park, booking('x', BookingKind.dining, d(10, 15))], at(8));
      expect(plan.entries.map((e) => e.booking.id), ['park']);
    });
  });

  group('status and highlight on today', () {
    test('before anything starts, the first timed entry is next up', () {
      final plan = buildDayPlan(today, [park, lunch, dinner], at(8));
      expect(plan.entries.map((e) => e.status), everyElement(EntryStatus.upcoming));
      expect(plan.highlight?.booking.id, 'park');
    });

    test('during an entry it is highlighted as now', () {
      final plan = buildDayPlan(today, [park, lunch, dinner], at(10));
      expect(plan.highlight?.booking.id, 'park');
      expect(plan.highlight?.status, EntryStatus.now);
    });

    test('when entries overlap, the one that started last is featured', () {
      // Parks "last" four hours by default, so at 12:45 you're still in the
      // park, but lunch is what's happening.
      final plan = buildDayPlan(today, [park, lunch, dinner], at(12, 45));
      expect(plan.entries.first.status, EntryStatus.now);
      expect(plan.highlight?.booking.id, 'lunch');
    });

    test('an entry is done once its typical duration has passed', () {
      final plan = buildDayPlan(today, [park, lunch, dinner], at(13, 30));
      expect(plan.entries.first.status, EntryStatus.done);
    });

    test('between entries the next one is highlighted', () {
      final plan = buildDayPlan(today, [park, lunch, dinner], at(15));
      expect(plan.highlight?.booking.id, 'dinner');
      expect(plan.highlight?.status, EntryStatus.upcoming);
    });

    test('after everything, nothing is highlighted', () {
      final plan = buildDayPlan(today, [park, lunch, dinner], at(23));
      expect(plan.highlight, isNull);
      expect(plan.entries.map((e) => e.status), everyElement(EntryStatus.done));
    });

    test('an explicit end time wins over the typical duration', () {
      final tour = booking('tour', BookingKind.activity, today,
          at: const ClockTime(9, 0), until: const ClockTime(16, 0));
      final plan = buildDayPlan(today, [tour], at(15));
      expect(plan.entries.single.status, EntryStatus.now);
    });

    test('all-day entries are never the highlight', () {
      final plan = buildDayPlan(today, [note], at(8));
      expect(plan.entries.single.status, EntryStatus.now);
      expect(plan.highlight, isNull);
    });

    test('other days have no highlight', () {
      expect(buildDayPlan(d(10, 15), [booking('x', BookingKind.dining, d(10, 15), at: const ClockTime(12, 0))], at(8)).highlight, isNull);
    });

    test('past days are all done, future days all upcoming', () {
      final past = buildDayPlan(d(10, 12), [hotel], at(8));
      final future = buildDayPlan(d(10, 18), [hotel], at(8));
      expect(past.entries.single.status, EntryStatus.done);
      expect(future.entries.single.status, EntryStatus.upcoming);
    });
  });

  group('multi-day bookings', () {
    test('check-in on the first day', () {
      final entry = buildDayPlan(d(10, 12), [hotel], at(8)).entries.single;
      expect(entry.role, EntryRole.start);
      expect(entry.time, const ClockTime(16, 0));
    });

    test('ongoing strip on the days in between', () {
      final plan = buildDayPlan(today, [hotel], at(8));
      expect(plan.entries, isEmpty);
      expect(plan.ongoing.single.id, 'hotel');
    });

    test('check-out on the last day at the end time', () {
      final entry = buildDayPlan(d(10, 18), [hotel], at(8)).entries.single;
      expect(entry.role, EntryRole.end);
      expect(entry.time, const ClockTime(11, 0));
    });

    test('an overnight flight departs one day and lands the next', () {
      final flight = booking('flight', BookingKind.flight, today,
          at: const ClockTime(18, 40), endDate: d(10, 15), until: const ClockTime(7, 10));
      expect(buildDayPlan(today, [flight], at(8)).entries.single.role, EntryRole.start);
      expect(buildDayPlan(d(10, 15), [flight], at(8)).entries.single.time, const ClockTime(7, 10));
    });
  });
}
