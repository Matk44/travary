import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/destinations.dart';
import 'package:travary/logic/trip_assignment.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  group('LocalDate', () {
    test('adds days across months and years', () {
      expect(d(1, 31).addDays(1), d(2, 1));
      expect(const LocalDate(2026, 12, 31).addDays(1), const LocalDate(2027, 1, 1));
      expect(d(3, 1).addDays(-1), d(2, 28));
    });

    test('counts days across a daylight-saving change', () {
      expect(d(3, 28).daysUntil(d(3, 30)), 2);
      expect(d(10, 24).daysUntil(d(10, 26)), 2);
    });

    test('round-trips through ISO strings', () {
      expect(LocalDate.parse(d(10, 4).toIso()), d(10, 4));
      expect(ClockTime.parse('07:05'), const ClockTime(7, 5));
    });
  });

  group('TripPlan', () {
    final orlando = TripPlan(trip('orlando'), [
      booking('hotel', BookingKind.stay, d(10, 12), endDate: d(10, 18)),
      booking('flight', BookingKind.flight, d(10, 12), at: const ClockTime(10, 30)),
      booking('home', BookingKind.flight, d(10, 18), endDate: d(10, 19)),
    ]);

    test('spans from the first booking to the last day of the last one', () {
      expect(orlando.start, d(10, 12));
      expect(orlando.end, d(10, 19));
      expect(orlando.dayCount, 8);
      expect(orlando.dayNumber(d(10, 14)), 3);
      expect(orlando.dayNumber(d(10, 20)), isNull);
    });

    test('sorts bookings by start', () {
      expect(orlando.bookings.first.id, 'hotel');
    });

    test('phase', () {
      expect(orlando.phaseOn(d(10, 1)), TripPhase.upcoming);
      expect(orlando.phaseOn(d(10, 14)), TripPhase.active);
      expect(orlando.phaseOn(d(10, 20)), TripPhase.past);
    });

    test('a trip with only planned dates', () {
      final plan = TripPlan(trip('x', plannedStart: d(12, 1), plannedEnd: d(12, 3)), const []);
      expect(plan.dayCount, 3);
    });

    test('planned dates widen a trip but never cut a booking out', () {
      final plan = TripPlan(trip('x', plannedStart: d(10, 14), plannedEnd: d(10, 22)), orlando.bookings);
      expect(plan.start, d(10, 12));
      expect(plan.end, d(10, 22));
    });

    test('booked span and dates that leave bookings out', () {
      expect(bookedSpan(const []), isNull);
      expect(bookedSpan(orlando.bookings), (start: d(10, 12), end: d(10, 19)));
      expect(leavesOutBookings(orlando.bookings, d(10, 12), d(10, 19)), isFalse);
      expect(leavesOutBookings(orlando.bookings, d(10, 10), d(10, 25)), isFalse);
      expect(leavesOutBookings(orlando.bookings, d(10, 13), d(10, 19)), isTrue);
      expect(leavesOutBookings(orlando.bookings, d(10, 12), d(10, 18)), isTrue);
      expect(leavesOutBookings(const [], d(10, 13), d(10, 14)), isFalse);
    });
  });

  group('focus', () {
    final active = TripPlan(trip('a'), [booking('a1', BookingKind.stay, d(10, 12), tripId: 'a', endDate: d(10, 18))]);
    final next = TripPlan(trip('b'), [booking('b1', BookingKind.stay, d(12, 1), tripId: 'b')]);

    test('opens on today during a trip', () {
      final focus = focusFor([active, next], d(10, 14));
      expect(focus.plan?.id, 'a');
      expect(focus.day, d(10, 14));
      expect(focus.isCountdown, isFalse);
    });

    test('counts down to the next trip otherwise', () {
      final focus = focusFor([active, next], d(11, 21));
      expect(focus.plan?.id, 'b');
      expect(focus.day, d(12, 1));
      expect(focus.daysUntilStart, 10);
    });

    test('nothing coming up', () {
      final focus = focusFor([active], d(11, 21));
      expect(focus.plan, isNull);
      expect(focus.day, d(11, 21));
      expect(focus.undated, isNull);
    });

    test('a holiday with no dates yet stays in view, the newest first', () {
      Trip undated(String id, int day) => Trip(
        id: id,
        title: id,
        ownerId: 'me',
        memberIds: const ['me'],
        createdAt: DateTime(2026, 10, day),
        updatedAt: DateTime(2026, 10, day),
      );
      final older = TripPlan(undated('japan', 1), const []);
      final newer = TripPlan(undated('bali', 5), const []);
      final focus = focusFor([active, older, newer], d(11, 21));
      expect(focus.plan, isNull);
      expect(focus.undated?.id, 'bali');
      // A dated trip on or coming still comes first.
      expect(focusFor([active, newer], d(10, 14)).undated, isNull);
      expect(focusFor([next, newer], d(11, 21)).plan?.id, 'b');
    });
  });

  group('trip assignment', () {
    final plans = buildTripPlans(
      [trip('orlando'), trip('paris')],
      [
        booking('o', BookingKind.stay, d(10, 12), tripId: 'orlando', endDate: d(10, 18)),
        booking('p', BookingKind.stay, d(6, 1), tripId: 'paris', endDate: d(6, 4)),
      ],
    );

    test('a booking inside a trip joins it', () {
      expect(findTripFor(d(10, 14), d(10, 14), plans)?.id, 'orlando');
    });

    test('a booking just before or after joins it', () {
      expect(findTripFor(d(10, 10), d(10, 10), plans)?.id, 'orlando');
      expect(findTripFor(d(10, 20), d(10, 20), plans)?.id, 'orlando');
    });

    test('a booking far from any trip needs a new one', () {
      expect(findTripFor(d(8, 1), d(8, 2), plans), isNull);
    });

    test('suggests a title from a flight destination', () {
      expect(suggestTripTitle(booking('f', BookingKind.flight, d(10, 12), title: 'London to orlando')), 'Orlando');
    });

    test('suggests a title from a short location', () {
      expect(suggestTripTitle(booking('h', BookingKind.stay, d(10, 12), location: 'Lisbon')), 'Lisbon');
    });

    test('a return flight joins the trip its outbound flight started', () {
      final lisbon = buildTripPlans(
        [trip('lisbon')],
        [booking('out', BookingKind.flight, d(11, 3), tripId: 'lisbon', title: 'London to Lisbon')],
      );
      final back = booking('back', BookingKind.flight, d(11, 12), title: 'Lisbon to London');
      expect(findTripFor(back.startDate, back.lastDate, lisbon), isNull);
      expect(findReturnFlightTrip(back, lisbon)?.id, 'lisbon');
      expect(
        findReturnFlightTrip(booking('x', BookingKind.flight, d(11, 12), title: 'Lisbon to Porto'), lisbon),
        isNull,
      );
      expect(
        findReturnFlightTrip(booking('y', BookingKind.flight, d(12, 30), title: 'Lisbon to London'), lisbon),
        isNull,
      );
    });

    test('falls back to the month', () {
      expect(suggestTripTitle(booking('h', BookingKind.stay, d(10, 12))), 'October trip');
    });

    test('a flight home from another city of the trip joins it too', () {
      final japan = buildTripPlans(
        [trip('japan')],
        [
          booking('out', BookingKind.flight, d(11, 1), tripId: 'japan', title: 'London to Osaka'),
          booking('stay', BookingKind.stay, d(11, 2), tripId: 'japan', endDate: d(11, 5), location: 'Osaka'),
        ],
      );
      Booking flight(String title) => booking('home', BookingKind.flight, d(11, 14), title: title);
      expect(
        findReturnFlightTrip(flight('Tokyo to London'), japan)?.id,
        'japan',
        reason: 'in to Osaka, home from Tokyo',
      );
      expect(findReturnFlightTrip(flight('Paris to London'), japan), isNull, reason: 'another trip');
      expect(findReturnFlightTrip(flight('Manchester to London'), japan), isNull, reason: 'home\'s own country');
    });

    test('so does the first leg home by way of the stopover', () {
      final japan = buildTripPlans(
        [trip('japan')],
        [
          booking('a', BookingKind.flight, d(11, 1), tripId: 'japan', title: 'London to Dubai'),
          booking('b', BookingKind.flight, d(11, 1), tripId: 'japan', title: 'Dubai to Osaka'),
        ],
      );
      final first = booking('c', BookingKind.flight, d(11, 14), title: 'Tokyo to Dubai');
      expect(findReturnFlightTrip(first, japan)?.id, 'japan');
    });
  });

  group('naming a trip', () {
    final viaDubai = [
      booking('a', BookingKind.flight, d(11, 1), title: 'London to Dubai', at: const ClockTime(9, 0)),
      booking('b', BookingKind.flight, d(11, 1), title: 'Dubai to Osaka', at: const ClockTime(21, 0)),
    ];

    test('after where its bookings go, with that place', () {
      final name = suggestTripName(viaDubai);
      expect(name.title, 'Osaka');
      expect(name.destination, detectPlace('Osaka')!.destination);
      expect(
        suggestTripName([booking('f', BookingKind.flight, d(10, 12), title: 'London to orlando')]).title,
        'Orlando',
      );
    });

    test('somewhere the app doesn\'t know: the old way, with no place', () {
      final name = suggestTripName([booking('h', BookingKind.stay, d(10, 12), location: 'Grandma\'s')]);
      expect((name.title, name.destination), ('Grandma\'s', null));
    });

    group('an automatic name follows the bookings', () {
      final dubai = Trip(
        id: 't',
        title: 'Dubai',
        destination: detectPlace('Dubai')!.destination,
        autoName: true,
        ownerId: 'me',
        memberIds: const ['me'],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      test('to where they go now', () {
        final renamed = followBookings(dubai, viaDubai)!;
        expect((renamed.title, renamed.destination?.name, renamed.autoName), ('Osaka', 'Osaka', true));
        final kyoto = booking('k', BookingKind.stay, d(11, 2), title: 'Hotel Granvia Kyoto', endDate: d(11, 5));
        final tokyo = booking('t', BookingKind.stay, d(11, 5), endDate: d(11, 9), location: 'Minato, Tokyo');
        expect(followBookings(renamed, [...viaDubai, kyoto, tokyo])?.title, 'Japan');
      });

      test('nothing when they still say the same', () {
        expect(followBookings(dubai, [viaDubai.first]), isNull);
      });

      test('several countries: the name stays, the place goes', () {
        final europe = [
          booking('p', BookingKind.stay, d(6, 1), endDate: d(6, 5), location: 'Paris'),
          booking('r', BookingKind.stay, d(6, 5), endDate: d(6, 8), location: 'Rome'),
        ];
        final mixed = followBookings(dubai, europe)!;
        expect((mixed.title, mixed.destination), ('Dubai', null));
      });

      test('bookings that name nowhere change nothing', () {
        expect(followBookings(dubai, [booking('l', BookingKind.dining, d(11, 3), title: 'Lunch')]), isNull);
      });

      test('a name the traveller gave never changes', () {
        expect(followBookings(dubai.copyWith(autoName: false), viaDubai), isNull);
      });
    });
  });
}
