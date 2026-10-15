import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/flight_fill.dart';

import '../helpers.dart';
import '../support/flight_status.dart';

void main() {
  test('the schedule is only asked about as far ahead as the plan reaches', () {
    final today = LocalDate(2026, 10, 4);
    expect(flightLookupDaysAhead, 180, reason: 'mirrors FLIGHT_LOOKUP_DAYS_AHEAD on the server');
    expect(flightLookupReaches(today, today: today), isTrue);
    expect(flightLookupReaches(LocalDate(2027, 4, 2), today: today), isTrue, reason: 'the 180th day');
    expect(flightLookupReaches(LocalDate(2027, 4, 3), today: today), isFalse);
    expect(
      flightLookupReaches(LocalDate(2026, 9, 30), today: today),
      isTrue,
      reason: 'a past day is the server\'s call',
    );
    expect(
      flightTooFarAheadText('BA283', 'Sat 3 Apr'),
      contains('about six months ahead, so BA283 on Sat 3 Apr isn\'t on the board yet'),
    );
  });

  test('only a whole flight number is looked up', () {
    expect(cleanFlightNumber('ba 283'), 'BA283');
    expect(cleanFlightNumber('EZY 8123'), 'EZY8123');
    expect(cleanFlightNumber('U2-8123'), 'U28123');
    expect(cleanFlightNumber('BA'), isNull);
    expect(cleanFlightNumber('B'), isNull);
    expect(cleanFlightNumber('London'), isNull);
  });

  test('a found flight fills in the route, airport and the ticket\'s times', () {
    final fill = flightFill(ba283(), typedNumber: 'ba283')!;
    expect(fill.title, 'London to Los Angeles');
    expect(fill.startDate, d(11, 8));
    expect(fill.startTime, const ClockTime(10, 5));
    expect(fill.endDate, isNull, reason: 'lands the same day');
    expect(fill.endTime, const ClockTime(13, 25));
    expect(fill.location, 'London Heathrow (LHR)', reason: 'the code lets live status find the right leg');
    expect(fill.flightNumber, 'BA 283');
  });

  test('an overnight flight lands on the next day; a delay doesn\'t change the ticket', () {
    final fill = flightFill(
      ba283(departs: '2026-11-08T21:40', lands: '2026-11-09T06:10', revised: '2026-11-08T23:00', delayMinutes: 80),
      typedNumber: 'BA283',
    )!;
    expect(fill.startTime, const ClockTime(21, 40));
    expect(fill.endDate, d(11, 9));
    expect(fill.endTime, const ClockTime(6, 10));
  });

  test('east across the date line it lands the day it left, earlier by the clock', () {
    final fill = flightFill(
      ba283(departs: '2026-11-08T17:00', lands: '2026-11-08T06:00'),
      typedNumber: 'BA283',
    )!;
    expect(fill.endDate, d(11, 8), reason: 'kept, or it would read as the next morning');
    expect(fill.endTime, const ClockTime(6, 0));
  });

  test('"Is this your flight?" wording', () {
    final text = describeFoundFlight(ba283());
    expect(text.heading, 'BA 283 · British Airways');
    expect(text.route, 'London Heathrow (LHR) → Los Angeles (LAX)');
    expect(text.times, '10:05am → 1:25pm');
    expect(
      describeFoundFlight(ba283(departs: '2026-11-08T21:40', lands: '2026-11-09T06:10')).times,
      '9:40pm → 6:10am Mon 9 Nov',
    );
  });

  test('the departures board: number, cities, twenty-four-hour time, and when it lands', () {
    final board = boardTextFor(
      ba283(departs: '2026-11-08T21:40', lands: '2026-11-09T06:10'),
      typedNumber: 'ba283',
    );
    expect(board.flight, 'BA 283');
    expect(board.from, 'London');
    expect(board.to, 'Los Angeles');
    expect(board.departs, '21:40');
    expect(board.lands, 'Lands 6:10am Mon 9 Nov');
    expect(boardTextFor(ba283(), typedNumber: 'ba283').lands, 'Lands 1:25pm');
  });

  group('the board fills the ticket around what the traveller typed', () {
    final ba = flightFill(ba283(), typedNumber: 'BA283')!;
    final overnight = flightFill(
      ba283(departs: '2026-11-08T21:40', lands: '2026-11-09T06:10'),
      typedNumber: 'BA283',
    )!;

    test('an empty ticket takes the whole flight', () {
      final form = refillFlight(
        FlightFields(startDate: d(11, 8)),
        fill: ba,
        searchDate: d(11, 8),
      );
      expect(form.title, 'London to Los Angeles');
      expect(form.location, 'London Heathrow (LHR)');
      expect(form.arrival, ba.arrival);
      expect(form.startTime, const ClockTime(10, 5));
      expect(form.endTime, const ClockTime(13, 25));
      expect(form.endDate, isNull);
    });

    test('what was typed by hand is kept', () {
      final typed = FlightFields(startDate: d(11, 8), title: 'Off to LA', startTime: const ClockTime(10, 0));
      final form = refillFlight(typed, fill: ba, searchDate: d(11, 8));
      expect(form.title, 'Off to LA');
      expect(form.startTime, const ClockTime(10, 0));
      expect(form.location, 'London Heathrow (LHR)', reason: 'empty fields still fill');
    });

    test('another flight replaces the last one\'s details, never the traveller\'s', () {
      var form = refillFlight(
        FlightFields(startDate: d(11, 8), arrival: 'LAX, gate side'),
        fill: ba,
        searchDate: d(11, 8),
      );
      form = refillFlight(form, previous: ba, fill: overnight, searchDate: d(11, 8));
      expect(form.startTime, const ClockTime(21, 40));
      expect(form.endDate, d(11, 9));
      expect(form.endTime, const ClockTime(6, 10));
      expect(form.arrival, 'LAX, gate side');
    });

    test('when the flight leaves the board its details go, and the day goes back to the one searched', () {
      final later = FlightFill(title: 'Singapore to London', startDate: d(11, 9), flightNumber: 'QF 1');
      var form = refillFlight(
        FlightFields(startDate: d(11, 8)),
        fill: later,
        searchDate: d(11, 8),
      );
      expect(form.startDate, d(11, 9), reason: 'a later leg leaves the next day');
      form = refillFlight(
        FlightFields(startDate: form.startDate, title: form.title, location: 'Changi T1'),
        previous: later,
        searchDate: d(11, 8),
      );
      expect(form.startDate, d(11, 8));
      expect(form.title, isEmpty);
      expect(form.location, 'Changi T1');
    });
  });
}
