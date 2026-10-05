import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/flight_fill.dart';

import '../helpers.dart';
import '../support/flight_status.dart';

void main() {
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
}
