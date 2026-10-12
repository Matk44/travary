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
  final hotel = booking(
    'hotel',
    BookingKind.stay,
    d(10, 12),
    at: const ClockTime(16, 0),
    endDate: d(10, 18),
    until: const ClockTime(11, 0),
  );
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
      final tour = booking(
        'tour',
        BookingKind.activity,
        today,
        at: const ClockTime(9, 0),
        until: const ClockTime(16, 0),
      );
      final plan = buildDayPlan(today, [tour], at(15));
      expect(plan.entries.single.status, EntryStatus.now);
    });

    test('a timed reminder stays up for an hour once it is due', () {
      final medicine = booking('medicine', BookingKind.note, today, at: const ClockTime(8, 0));
      expect(buildDayPlan(today, [medicine], at(8)).highlight?.status, EntryStatus.now);
      expect(buildDayPlan(today, [medicine], at(8, 45)).highlight?.booking.id, 'medicine');
      expect(buildDayPlan(today, [medicine], at(9)).entries.single.status, EntryStatus.done);
    });

    test('all-day entries are never the highlight', () {
      final plan = buildDayPlan(today, [note], at(8));
      expect(plan.entries.single.status, EntryStatus.now);
      expect(plan.highlight, isNull);
    });

    test('other days have no highlight', () {
      expect(
        buildDayPlan(d(10, 15), [
          booking('x', BookingKind.dining, d(10, 15), at: const ClockTime(12, 0)),
        ], at(8)).highlight,
        isNull,
      );
    });

    test('past days are all done, future days all upcoming', () {
      final past = buildDayPlan(d(10, 12), [hotel], at(8));
      final future = buildDayPlan(d(10, 18), [hotel], at(8));
      expect(past.entries.single.status, EntryStatus.done);
      expect(future.entries.single.status, EntryStatus.upcoming);
    });
  });

  group('ending before it starts', () {
    test('lands the next morning: a red-eye saved without the form', () {
      final redEye = booking(
        'f',
        BookingKind.flight,
        d(10, 12),
        at: const ClockTime(22, 40),
        until: const ClockTime(6, 10),
      );
      final fixed = withOvernightEnd(redEye);
      expect(fixed.endDate, d(10, 13));
      expect(buildDayPlan(d(10, 13), [fixed], DateTime(2026, 10, 13, 5)).entries.single.role, EntryRole.end);
    });

    test('east across the date line: landing on the day it left, earlier by the clock', () {
      // Sydney 11:00 on the 12th, Los Angeles 06:00 on the 12th.
      final transpacific = booking(
        'f',
        BookingKind.flight,
        d(10, 12),
        at: const ClockTime(11, 0),
        endDate: d(10, 12),
        until: const ClockTime(6, 0),
      );
      expect(withOvernightEnd(transpacific).endDate, d(10, 12));
      expect(buildDayPlan(d(10, 12), [transpacific], DateTime(2026, 10, 12, 8)).entries.single.role, EntryRole.single);
      expect(buildDayPlan(d(10, 13), [transpacific], DateTime(2026, 10, 12, 8)).entries, isEmpty);
    });

    test('the end date a form, found flight or import keeps', () {
      const departs = ClockTime(11, 0);
      expect(keptEndDate(d(10, 12), null, startTime: departs, endTime: const ClockTime(6, 0)), isNull);
      expect(keptEndDate(d(10, 12), d(10, 12), startTime: departs, endTime: const ClockTime(14, 0)), isNull);
      expect(keptEndDate(d(10, 12), d(10, 12)), isNull);
      expect(keptEndDate(d(10, 12), d(10, 12), startTime: departs, endTime: const ClockTime(6, 0)), d(10, 12));
      expect(keptEndDate(d(10, 12), d(10, 14), startTime: departs, endTime: const ClockTime(6, 0)), d(10, 14));
    });

    test('leaves everything else as it is', () {
      final lunch = booking(
        'l',
        BookingKind.dining,
        d(10, 12),
        at: const ClockTime(12, 0),
        until: const ClockTime(14, 0),
      );
      final stay = booking(
        's',
        BookingKind.stay,
        d(10, 12),
        at: const ClockTime(15, 0),
        endDate: d(10, 14),
        until: const ClockTime(11, 0),
      );
      final untimed = booking('u', BookingKind.activity, d(10, 12), until: const ClockTime(9, 0));
      for (final b in [lunch, stay, untimed]) {
        expect(withOvernightEnd(b).endDate, b.endDate, reason: b.id);
      }
    });
  });

  group('multi-day bookings', () {
    test('check-in on the first day', () {
      final entry = buildDayPlan(d(10, 12), [hotel], at(8)).entries.single;
      expect(entry.role, EntryRole.start);
      expect(entry.time, const ClockTime(16, 0));
    });

    test('on its first day, the hotel is checked in, not finished, from check-in on', () {
      final arrival = d(10, 12);
      DateTime on(int hour) => arrival.toDateTime(ClockTime(hour, 0));
      final before = buildDayPlan(arrival, [hotel], on(14));
      expect(before.entries.single.status, EntryStatus.upcoming);
      expect(before.ongoing, isEmpty);
      for (final hour in [16, 21, 23]) {
        final after = buildDayPlan(arrival, [hotel], on(hour));
        expect(after.entries, isEmpty, reason: '$hour:00');
        expect(after.ongoing.single.id, 'hotel', reason: '$hour:00');
      }
    });

    test('a hire car is the pick-up for its first hour, then a car you have', () {
      final car = booking(
        'car',
        BookingKind.transport,
        today,
        at: const ClockTime(10, 0),
        endDate: d(10, 18),
        until: const ClockTime(9, 0),
      );
      final pickingUp = buildDayPlan(today, [car], at(10, 30));
      expect(pickingUp.entries.single.status, EntryStatus.now);
      expect(pickingUp.highlight?.booking.id, 'car');
      final driving = buildDayPlan(today, [car, dinner], at(14));
      expect(driving.ongoing.single.id, 'car');
      expect(driving.highlight?.booking.id, 'dinner');
    });

    test('looking back at a first day, check-in is an entry like any other', () {
      final entry = buildDayPlan(d(10, 12), [hotel], at(8)).entries.single;
      expect((entry.role, entry.status), (EntryRole.start, EntryStatus.done));
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
      final flight = booking(
        'flight',
        BookingKind.flight,
        today,
        at: const ClockTime(18, 40),
        endDate: d(10, 15),
        until: const ClockTime(7, 10),
      );
      expect(buildDayPlan(today, [flight], at(8)).entries.single.role, EntryRole.start);
      expect(buildDayPlan(d(10, 15), [flight], at(8)).entries.single.time, const ClockTime(7, 10));
    });
  });

  group('a booking as a whole, for a trip\'s plan', () {
    test('a stay is happening from check-in until check-out, then done', () {
      final stay = booking('kyoto', BookingKind.stay, d(10, 12), endDate: d(10, 14), until: const ClockTime(10, 0));
      expect(bookingStatus(stay, DateTime(2026, 10, 11, 12)), EntryStatus.upcoming);
      expect(bookingStatus(stay, DateTime(2026, 10, 13, 12)), EntryStatus.now);
      expect(bookingStatus(stay, DateTime(2026, 10, 14, 9)), EntryStatus.now);
      expect(bookingStatus(stay, DateTime(2026, 10, 14, 11)), EntryStatus.done);
    });

    test('a timed booking is done once its time has passed', () {
      final lunch = booking('lunch', BookingKind.dining, d(10, 12), at: const ClockTime(12, 30));
      expect(bookingStatus(lunch, DateTime(2026, 10, 12, 9)), EntryStatus.upcoming);
      expect(bookingStatus(lunch, DateTime(2026, 10, 12, 13)), EntryStatus.now);
      expect(bookingStatus(lunch, DateTime(2026, 10, 13, 9)), EntryStatus.done);
    });
  });
}
