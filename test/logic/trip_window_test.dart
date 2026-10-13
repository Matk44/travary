import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/trip_assignment.dart';
import 'package:travary/logic/trip_plan.dart';
import 'package:travary/logic/trip_window.dart';

import '../helpers.dart';

void main() {
  /// Japan holiday: planned for 11–23 Oct.
  TripPlan japan([List<Booking> bookings = const []]) =>
      TripPlan(trip('japan', title: 'Japan holiday', plannedStart: d(10, 11), plannedEnd: d(10, 23)), bookings);

  /// Tokyo: formed on its own from a flight out on 11 Oct and a hotel.
  TripPlan tokyo([List<Booking>? bookings]) => TripPlan(
    trip('tokyo', title: 'Tokyo'),
    bookings ??
        [
          booking('out', BookingKind.flight, d(10, 11), tripId: 'tokyo'),
          booking('hotel', BookingKind.stay, d(10, 11), tripId: 'tokyo', endDate: d(10, 15)),
        ],
  );

  group('the days a booking may use', () {
    test('a trip with planned dates keeps to them, with travel days either side', () {
      expect(bookingWindowFor(japan()), DateWindow(d(10, 9), d(10, 25)));
      expect(travelDayMargin, tripMarginDays);
    });

    test('never shuts out what is already booked', () {
      final early = booking('tour', BookingKind.activity, d(10, 2), tripId: 'japan');
      expect(bookingWindowFor(japan([early])), DateWindow(d(10, 2), d(10, 25)));
    });

    test('a trip that formed from its bookings has no window', () {
      expect(bookingWindowFor(tokyo()), isNull);
    });

    test('windows contain, cover and clamp', () {
      final window = DateWindow(d(10, 9), d(10, 25));
      expect(window.contains(d(10, 9)), isTrue);
      expect(window.contains(d(10, 26)), isFalse);
      expect(window.covers(d(10, 20), d(10, 25)), isTrue);
      expect(window.covers(d(10, 20), d(10, 26)), isFalse);
      expect(window.clamp(d(11, 11)), d(10, 25));
      expect(window.clamp(d(9, 1)), d(10, 9));
      expect(window.clamp(d(10, 15)), d(10, 15));
    });
  });

  group('whether dates fit a trip', () {
    test('a planned trip: inside its window, start to end', () {
      expect(fitsTrip(d(10, 14), d(10, 16), japan()), isTrue);
      expect(fitsTrip(d(10, 10), d(10, 10), japan()), isTrue);
      expect(fitsTrip(d(11, 11), d(11, 23), japan()), isFalse);
      expect(fitsTrip(d(10, 20), d(11, 5), japan()), isFalse);
    });

    test('a formed trip: near what it has booked', () {
      expect(fitsTrip(d(10, 16), d(10, 16), tokyo()), isTrue);
      expect(fitsTrip(d(10, 17), d(10, 17), tokyo()), isTrue);
      expect(fitsTrip(d(10, 20), d(10, 20), tokyo()), isFalse);
      expect(fitsTrip(d(10, 20), d(10, 20), tokyo(), looseMarginDays: sameSourceMarginDays), isTrue);
    });

    test('a trip with nothing to go by takes anything', () {
      expect(fitsTrip(d(3, 1), d(3, 2), TripPlan(trip('empty'), const [])), isTrue);
    });
  });

  test('a trip without the booking being edited', () {
    final plan = tokyo();
    expect(withoutBooking(plan, 'hotel').bookings.map((b) => b.id), ['out']);
    expect(withoutBooking(plan, 'hotel').end, d(10, 11));
    expect(identical(withoutBooking(plan, 'nope'), plan), isTrue);
  });

  group('where a booking goes', () {
    test('by its dates when no trip is asked for', () {
      final plans = [japan(), tokyo()];
      expect(placeBooking(start: d(10, 14), end: d(10, 14), plans: plans).plan?.id, 'japan');
      expect(placeBooking(start: d(12, 1), end: d(12, 1), plans: plans).plan, isNull);
    });

    test('into the trip it was added from while its dates fit', () {
      final placement = placeBooking(start: d(10, 14), end: d(10, 16), plans: [japan()], tripId: 'japan');
      expect(placement.plan?.id, 'japan');
      expect(placement.stretches, isFalse);
    });

    test('out of a planned trip when its dates leave it (a schedule, a ticket)', () {
      final bali = TripPlan(trip('bali', title: 'Bali'), [
        booking('villa', BookingKind.stay, LocalDate(2027, 3, 1), tripId: 'bali', endDate: LocalDate(2027, 3, 8)),
      ]);
      final plans = [japan(), bali];
      expect(
        placeBooking(start: LocalDate(2027, 3, 2), end: LocalDate(2027, 3, 2), plans: plans, tripId: 'japan').plan?.id,
        'bali',
      );
      expect(placeBooking(start: d(12, 1), end: d(12, 1), plans: plans, tripId: 'japan').plan, isNull);
    });

    test('a formed trip keeps it but asks first, saying where else it would go', () {
      final paris = TripPlan(trip('paris', title: 'Paris', plannedStart: d(11, 10), plannedEnd: d(11, 14)), const []);
      final placement = placeBooking(start: d(11, 11), end: d(11, 11), plans: [tokyo(), paris], tripId: 'tokyo');
      expect(placement.plan?.id, 'tokyo');
      expect(placement.stretches, isTrue);
      expect(placement.alternative?.id, 'paris');
      final nowhere = placeBooking(start: d(12, 11), end: d(12, 11), plans: [tokyo(), paris], tripId: 'tokyo');
      expect(nowhere.stretches, isTrue);
      expect(nowhere.alternative, isNull);
    });

    test('Smart Import keeps what is within a few weeks of a formed trip', () {
      final placement = placeBooking(
        start: d(10, 25),
        end: d(10, 25),
        plans: [tokyo()],
        tripId: 'tokyo',
        looseMarginDays: sameSourceMarginDays,
      );
      expect(placement.plan?.id, 'tokyo');
      expect(placement.stretches, isFalse);
    });

    test('a trip the traveller chose on the form, whatever the dates', () {
      final placement = placeBooking(start: d(12, 1), end: d(12, 1), plans: [tokyo()], tripId: 'tokyo', chosen: true);
      expect(placement.plan?.id, 'tokyo');
      expect(placement.stretches, isFalse);
    });

    test('an edit that leaves the dates alone stays put', () {
      final plans = [tokyo()];
      final placement = placeBooking(
        start: d(10, 11),
        end: d(10, 15),
        plans: plans,
        tripId: 'tokyo',
        editing: 'hotel',
        datesChanged: false,
      );
      expect(placement.plan?.id, 'tokyo');
      expect(placement.stretches, isFalse);
    });

    test('an edit is judged without its own old dates', () {
      // The hotel moved to November: Tokyo is just the flight out now.
      final placement = placeBooking(
        start: d(11, 11),
        end: d(11, 15),
        plans: [tokyo()],
        tripId: 'tokyo',
        editing: 'hotel',
      );
      expect(placement.stretches, isTrue);
    });

    test('fixing a typed month brings a stray trip\'s booking home', () {
      // A hotel typed for November formed "Shinjuku"; corrected to October,
      // it joins Japan and Shinjuku empties (and removes itself).
      final shinjuku = TripPlan(trip('shinjuku', title: 'Shinjuku'), [
        booking('gracery', BookingKind.stay, d(11, 11), tripId: 'shinjuku', endDate: d(11, 23)),
      ]);
      final plans = [japan(), shinjuku];
      final fixed = placeBooking(
        start: d(10, 11),
        end: d(10, 23),
        plans: plans,
        tripId: 'shinjuku',
        editing: 'gracery',
      );
      expect(fixed.plan?.id, 'japan');
      // Moved somewhere no other trip is: it keeps its own trip.
      final alone = placeBooking(start: d(12, 1), end: d(12, 3), plans: plans, tripId: 'shinjuku', editing: 'gracery');
      expect(alone.plan?.id, 'shinjuku');
      expect(alone.stretches, isFalse);
    });

    test('a trip that no longer exists goes by the dates', () {
      expect(placeBooking(start: d(10, 14), end: d(10, 14), plans: [japan()], tripId: 'gone').plan?.id, 'japan');
    });
  });

  group('moving dates into a chosen trip', () {
    final window = DateWindow(d(10, 9), d(10, 25));

    test('dates inside stay as they are', () {
      final moved = moveInto(window, d(10, 14), d(10, 16), preferredStart: d(10, 11));
      expect((moved.start, moved.end), (d(10, 14), d(10, 16)));
    });

    test('dates outside start on the trip\'s day, keeping their length', () {
      final moved = moveInto(window, d(11, 11), d(11, 14), preferredStart: d(10, 11));
      expect((moved.start, moved.end), (d(10, 11), d(10, 14)));
      final single = moveInto(window, d(12, 1), null, preferredStart: d(10, 11));
      expect((single.start, single.end), (d(10, 11), null));
    });

    test('a stay too long for the trip ends with it', () {
      final moved = moveInto(window, d(11, 1), d(11, 30), preferredStart: d(10, 11));
      expect((moved.start, moved.end), (d(10, 11), d(10, 25)));
    });

    test('an end past the trip is pulled back in', () {
      final moved = moveInto(window, d(10, 20), d(10, 28), preferredStart: d(10, 11));
      expect((moved.start, moved.end), (d(10, 20), d(10, 25)));
    });
  });

  group('trip dates that would leave bookings out', () {
    final bookings = [
      booking('out', BookingKind.flight, d(10, 10), tripId: 'japan', title: 'London to Tokyo'),
      booking('gracery', BookingKind.stay, d(10, 14), tripId: 'japan', endDate: d(10, 16), title: 'Hotel Gracery'),
      booking('home', BookingKind.flight, d(10, 23), tripId: 'japan', title: 'Tokyo to London'),
    ];

    test('a travel day either side is fine', () {
      expect(bookingsLeftOut(bookings, d(10, 11), d(10, 23)), isEmpty);
      expect(bookingsLeftOut(bookings, d(10, 12), d(10, 21)), isEmpty);
    });

    test('anything further out is left out', () {
      expect(bookingsLeftOut(bookings, d(10, 17), d(10, 23)).map((b) => b.id), ['out', 'gracery']);
      expect(bookingsLeftOut(bookings, LocalDate(2027, 3, 1), LocalDate(2027, 3, 10)), hasLength(3));
    });

    test('says which, and what to do', () {
      expect(
        leftOutText([bookings[1]]),
        'Hotel Gracery (14–16 Oct) would be left out. Choose dates that include it, or change the booking first.',
      );
      expect(
        leftOutText(bookings),
        '3 bookings would be left out (10–23 Oct). Choose dates that include them, or change those bookings first.',
      );
    });
  });

  test('trips whose dates overlap', () {
    final plans = [japan(), TripPlan(trip('undated'), const [])];
    expect(overlappingTrip(d(10, 15), d(10, 20), plans)?.id, 'japan');
    expect(overlappingTrip(d(10, 24), d(10, 30), plans), isNull);
    expect(overlappingTrip(d(10, 15), d(10, 20), plans, except: 'japan'), isNull);
    expect(overlapText(japan()), 'These dates overlap Japan holiday (11–23 Oct).');
  });

  group('a flight home on the form', () {
    test('finds the trip it ends, as saving it will', () {
      final home = booking('home', BookingKind.flight, d(10, 24), tripId: '', title: 'Osaka to London');
      final trips = [
        TripPlan(trip('tokyo', title: 'Tokyo'), [
          booking('out', BookingKind.flight, d(10, 11), tripId: 'tokyo', title: 'London to Tokyo'),
          booking('hotel', BookingKind.stay, d(10, 11), tripId: 'tokyo', endDate: d(10, 15)),
        ]),
      ];
      expect(placeBooking(start: home.startDate, end: home.lastDate, plans: trips).plan, isNull);
      expect(placeBooking(start: home.startDate, end: home.lastDate, plans: trips, booking: home).plan?.id, 'tokyo');
    });
  });

  group('one file\'s bookings', () {
    Booking item(String id, LocalDate date, {String tripId = '', String title = 'Booking', LocalDate? until}) =>
        booking(id, BookingKind.activity, date, tripId: tripId, title: title, endDate: until);

    test('a new trip for bookings near no trip, shared within a few weeks', () {
      final places = placeImport([item('a', d(11, 1)), item('b', d(11, 20)), item('c', d(12, 31))], const []);
      expect(places.map((p) => p.key), ['new:0', 'new:0', 'new:1']);
    });

    test('the trip they belong to; then the rest of the file follows it', () {
      final places = placeImport([item('a', d(10, 14)), item('b', d(10, 26))], [tokyo()]);
      expect(places.map((p) => p.key), ['tokyo', 'tokyo']);
    });

    test('but never outside a trip\'s planned dates', () {
      final places = placeImport([item('a', d(10, 20)), item('b', d(11, 5))], [japan()]);
      expect(places.map((p) => p.key), ['japan', 'new:0']);
    });

    test('a booking with a trip keeps it; a flight home finds the trip it ends', () {
      final home = booking('home', BookingKind.flight, d(10, 24), tripId: '', title: 'Osaka to London');
      final trips = [
        TripPlan(trip('tokyo', title: 'Tokyo'), [
          booking('out', BookingKind.flight, d(10, 11), tripId: 'tokyo', title: 'London to Tokyo'),
        ]),
        TripPlan(trip('winter', title: 'Winter', plannedStart: d(12, 1), plannedEnd: d(12, 5)), const []),
      ];
      expect(placeImport([item('x', d(12, 1), tripId: 'winter'), home], trips).map((p) => p.key), ['winter', 'tokyo']);
    });
  });
}
