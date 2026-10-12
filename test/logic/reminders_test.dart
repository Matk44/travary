import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/day_plan.dart';
import 'package:travary/logic/reminders.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  DateTime at(int month, int day, int hour, [int minute = 0]) => DateTime(2026, month, day, hour, minute);

  // Orlando, 14–16 October: a hotel throughout, a park, lunch, dinner, a
  // reminder written for the fireworks.
  final hotel = booking(
    'hotel',
    BookingKind.stay,
    d(10, 14),
    title: 'Lagoon Resort',
    at: const ClockTime(16, 0),
    endDate: d(10, 16),
    until: const ClockTime(11, 0),
  );
  final park = booking('park', BookingKind.attraction, d(10, 15), title: 'Sunshine Park', at: const ClockTime(9, 30));
  final lunch = booking(
    'lunch',
    BookingKind.dining,
    d(10, 15),
    title: 'Sunshine Terrace',
    at: const ClockTime(12, 30),
    location: '1 Park Way',
  );
  final dinner = booking('dinner', BookingKind.dining, d(10, 15), title: 'Lagoon Grill', at: const ClockTime(19, 15));
  final fireworks = booking('fireworks', BookingKind.note, d(10, 15), title: 'Fireworks', at: const ClockTime(21, 0));
  TripPlan orlando([List<Booking> more = const []]) =>
      TripPlan(trip('trip', title: 'Orlando'), [hotel, park, lunch, dinner, fireworks, ...more]);

  test('each trip day with something on it gets its plan in the morning', () {
    final reminders = remindersFor([orlando()], at(10, 13, 20));
    final mornings = reminders.where((r) => r.opens.startsWith('day:')).toList();
    expect(
      [for (final r in mornings) (r.at, r.title)],
      [(at(10, 14, 8), 'Orlando starts today'), (at(10, 15, 8), 'Orlando, day 2'), (at(10, 16, 8), 'Orlando, day 3')],
    );
    expect(mornings[0].body, '4:00pm Check-in, Lagoon Resort');
    expect(
      mornings[1].body,
      '9:30am Sunshine Park · 12:30pm Sunshine Terrace · 7:15pm Lagoon Grill · and 1 more',
      reason: 'the hotel in between is on its key card, not in the plan',
    );
    expect(mornings[2].body, '11:00am Check-out, Lagoon Resort');
    expect(mornings[1].opens, 'day:2026-10-15');
  });

  test('a day that starts early gets its plan an hour before, never before 6:00', () {
    final early = booking('early', BookingKind.activity, d(10, 15), at: const ClockTime(7, 30));
    final dawn = booking('dawn', BookingKind.activity, d(10, 15), at: const ClockTime(5, 0));
    DateTime morning(Booking first) => morningAt(buildDayPlan(d(10, 15), [first, dinner], at(10, 13, 20)));
    expect(morning(early), at(10, 15, 6, 30));
    expect(morning(dawn), at(10, 15, 6));
    expect(morning(park), at(10, 15, 8));
  });

  test('a nudge before each timed booking, by kind; stays and the ends of things have none', () {
    final car = booking(
      'car',
      BookingKind.transport,
      d(10, 14),
      title: 'Car hire',
      at: const ClockTime(10, 0),
      endDate: d(10, 16),
      until: const ClockTime(9, 0),
    );
    final nudges = {
      for (final r in remindersFor([
        orlando([car]),
      ], at(10, 13, 20)).where((r) => r.opens.startsWith('booking:')))
        r.opens: r,
    };
    expect(
      nudges.keys,
      unorderedEquals(['booking:car', 'booking:park', 'booking:lunch', 'booking:dinner', 'booking:fireworks']),
    );
    expect((nudges['booking:park']!.at, nudges['booking:park']!.body), (at(10, 15, 8, 30), 'In an hour, at 9:30am.'));
    expect(nudges['booking:lunch']!.body, 'In an hour, at 12:30pm. 1 Park Way');
    expect(
      (nudges['booking:car']!.at, nudges['booking:car']!.body),
      (at(10, 14, 9), 'Pick-up in an hour, at 10:00am.'),
    );
    // What they wrote, at the time they gave.
    expect((nudges['booking:fireworks']!.at, nudges['booking:fireworks']!.body), (at(10, 15, 21), '9:00pm'));
  });

  test('a flight is nudged three hours before it leaves', () {
    final flight = booking(
      'out',
      BookingKind.flight,
      d(10, 14),
      title: 'London to Orlando',
      at: const ClockTime(10, 30),
      until: const ClockTime(14, 55),
    );
    final nudge = remindersFor([
      orlando([flight]),
    ], at(10, 13, 20)).firstWhere((r) => r.opens == 'booking:out');
    expect(nudge.at, at(10, 14, 7, 30));
    expect(nudge.title, 'London to Orlando');
    expect(nudge.body, 'Departs at 10:30am, in 3 hours.');
  });

  test('nothing is set past the next flight\'s landing: the phone may be on a new clock by then', () {
    final flight = booking(
      'out',
      BookingKind.flight,
      d(10, 14),
      at: const ClockTime(10, 30),
      until: const ClockTime(14, 55),
    );
    final reminders = remindersFor([
      orlando([flight]),
    ], at(10, 13, 20));
    expect(reminders.every((r) => !r.at.isAfter(at(10, 14, 14, 55))), isTrue);
    expect(reminders.map((r) => r.opens), ['booking:out', 'day:2026-10-14']);
    // Opened again after landing, the rest of the holiday is set.
    final later = remindersFor([
      orlando([flight]),
    ], at(10, 14, 16));
    expect(later.first.opens, 'day:2026-10-15');
  });

  test('only what is still to come, soonest first, within two weeks and the limit', () {
    final reminders = remindersFor([orlando()], at(10, 15, 10));
    expect(reminders.first.at, at(10, 15, 11, 30), reason: 'the morning and the park have passed');
    expect(reminders.map((r) => r.at).toList(), orderedEquals([...reminders.map((r) => r.at)]..sort()));

    final far = TripPlan(trip('far', title: 'Far'), [
      booking('x', BookingKind.dining, d(11, 30), at: const ClockTime(19, 0)),
    ]);
    expect(remindersFor([far], at(10, 13, 20)), isEmpty);

    final busy = TripPlan(trip('busy', title: 'Busy'), [
      for (var i = 0; i < 80; i++)
        booking('b$i', BookingKind.activity, d(10, 14).addDays(i % 10), at: ClockTime(9 + i ~/ 10, 0)),
    ]);
    expect(remindersFor([busy], at(10, 13, 20)), hasLength(reminderLimit));
  });

  test('past trips and undated ones are left alone', () {
    final past = TripPlan(trip('past'), [booking('p', BookingKind.dining, d(9, 1), at: const ClockTime(19, 0))]);
    final undated = TripPlan(trip('undated'), const []);
    expect(remindersFor([past, undated], at(10, 13, 20)), isEmpty);
  });

  test('when the next flight lands', () {
    final red = booking(
      'red',
      BookingKind.flight,
      d(10, 14),
      at: const ClockTime(22, 0),
      endDate: d(10, 15),
      until: const ClockTime(6, 0),
    );
    final noLanding = booking('nl', BookingKind.flight, d(10, 20), at: const ClockTime(9, 0));
    final noTimes = booking('nt', BookingKind.flight, d(10, 25));
    expect(nextLanding([red, noLanding, noTimes], at(10, 13, 20)), at(10, 15, 6));
    expect(nextLanding([noLanding, noTimes], at(10, 13, 20)), at(10, 20, 12));
    expect(nextLanding([noTimes], at(10, 13, 20)), DateTime(2026, 10, 26));
    expect(nextLanding([red], at(10, 16, 9)), isNull);
  });
}
