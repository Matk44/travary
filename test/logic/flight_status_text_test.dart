import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/flight_status_text.dart';

import '../helpers.dart';

void main() {
  final now = DateTime(2026, 10, 4, 9, 10);

  FlightStatus status({
    FlightState state = FlightState.expected,
    String? revised = '2026-10-04T11:05',
    String? gate = 'B32',
    int? arrivalDelay,
    DateTime? checkedAt,
  }) => FlightStatus.fromJson({
    'number': 'BA 283',
    'airline': 'British Airways',
    'status': state.wireName,
    'departure': {
      'airport': 'LHR',
      'airportName': 'Heathrow',
      'scheduled': '2026-10-04T10:30',
      'revised': ?revised,
      'delayMinutes': revised == null ? null : _minutesBetween('2026-10-04T10:30', revised),
      'terminal': '5',
      'gate': ?gate,
      'checkInDesk': 'D',
    },
    'arrival': {
      'airport': 'LAX',
      'airportName': 'Los Angeles',
      'scheduled': '2026-10-04T13:45',
      'delayMinutes': arrivalDelay,
      'terminal': 'B',
      'baggageBelt': '7',
    },
    'updatedAt': '2026-10-04T09:19:00.000Z',
  }, checkedAt: checkedAt ?? now);

  group('when live status shows', () {
    final flight = booking(
      'out',
      BookingKind.flight,
      d(10, 10),
      location: 'London Heathrow (LHR)',
      details: {DetailKeys.flightNumber: 'BA 283'},
    );

    test('from three days before take-off until the day after landing', () {
      expect(flightLookupFor(flight, d(10, 6)), isNull);
      expect(flightStatusComesLater(flight, d(10, 6)), isTrue);
      expect(flightLookupFor(flight, d(10, 7)), FlightLookup(flightNumber: 'BA 283', date: d(10, 10), from: 'LHR'));
      expect(flightStatusComesLater(flight, d(10, 7)), isFalse);
      expect(flightLookupFor(flight, d(10, 11)), isNotNull);
      expect(flightLookupFor(flight, d(10, 12)), isNull);
    });

    test('only for flights with a number', () {
      expect(flightLookupFor(booking('no-number', BookingKind.flight, d(10, 10)), d(10, 10)), isNull);
      expect(
        flightLookupFor(
          booking('train', BookingKind.transport, d(10, 10), details: {DetailKeys.flightNumber: 'BA 283'}),
          d(10, 10),
        ),
        isNull,
      );
      expect(flightStatusComesLater(booking('no-number', BookingKind.flight, d(10, 20)), d(10, 1)), isFalse);
    });

    test('the departure airport is read from the booking when it names one', () {
      expect(airportCodeIn('London Heathrow (LHR)'), 'LHR');
      expect(airportCodeIn('LHR Terminal 5'), 'LHR');
      expect(airportCodeIn('Heathrow'), isNull);
      expect(airportCodeIn('lhr'), isNull);
      expect(airportCodeIn('LHR to LAX'), isNull, reason: 'two codes: no telling which');
      expect(airportCodeIn(null), isNull);
    });
  });

  group('wording', () {
    test('a late flight says how late, with the old time crossed out', () {
      final text = describeFlightStatus(status(), now);
      expect(text.title, 'Live status · BA 283');
      expect(text.headline, 'Delayed 35 min');
      expect(text.tone, FlightTone.bad);
      expect(text.departure.title, 'Departs Heathrow');
      expect(text.departure.time, '11:05am');
      expect(text.departure.was, '10:30am');
      expect(text.departure.details, 'Terminal 5 · Gate B32 · Check-in D');
      expect(text.arrival.title, 'Arrives Los Angeles');
      expect(text.arrival.time, '1:45pm');
      expect(text.arrival.was, isNull);
      expect(text.arrival.details, 'Terminal B · Baggage belt 7');
      expect(text.checked, 'Checked just now');
    });

    test('on time only when the airline has confirmed a time', () {
      expect(describeFlightStatus(status(revised: '2026-10-04T10:35'), now).headline, 'On time');
      final scheduled = describeFlightStatus(status(revised: null, gate: null), now);
      expect(scheduled.headline, 'Scheduled');
      expect(scheduled.tone, FlightTone.neutral);
      expect(scheduled.departure.was, isNull);
      expect(scheduled.departure.details, 'Terminal 5 · Check-in D');
    });

    test('what is happening right now comes first', () {
      String headline(FlightState state, {int? arrivalDelay}) =>
          describeFlightStatus(status(state: state, arrivalDelay: arrivalDelay), now).headline;
      expect(headline(FlightState.boarding), 'Boarding');
      expect(headline(FlightState.gateClosed), 'Gate closed');
      expect(headline(FlightState.enRoute), 'In the air');
      expect(headline(FlightState.approaching), 'Landing soon');
      expect(headline(FlightState.arrived), 'Landed');
      expect(headline(FlightState.arrived, arrivalDelay: 80), 'Landed 1 hr 20 min late');
      expect(headline(FlightState.canceled), 'Cancelled');
      expect(headline(FlightState.canceledUncertain), 'May be cancelled');
      expect(headline(FlightState.diverted), 'Diverted');
    });

    test('a delay into the next day names the day', () {
      final text = describeFlightStatus(status(revised: '2026-10-05T00:40'), now);
      expect(text.departure.time, '12:40am Mon 5 Oct');
      expect(text.headline, 'Delayed 14 hr 10 min');
    });

    test('says how fresh it is', () {
      expect(
        describeFlightStatus(status(checkedAt: now.subtract(const Duration(minutes: 5))), now).checked,
        'Checked 5 min ago',
      );
      expect(describeFlightStatus(status(checkedAt: DateTime(2026, 10, 4, 7, 5)), now).checked, 'Checked at 7:05am');
    });

    test('delays read naturally', () {
      expect(formatDelay(35), '35 min');
      expect(formatDelay(60), '1 hr');
      expect(formatDelay(80), '1 hr 20 min');
    });

    test('statuses the app doesn\'t know read as unknown', () {
      expect(FlightState.fromWire('Teleported'), FlightState.unknown);
      expect(FlightState.fromWire('EnRoute'), FlightState.enRoute);
    });
  });

  group('the live line under a flight\'s card on Today', () {
    final flight = booking(
      'out',
      BookingKind.flight,
      d(10, 4),
      location: 'London Heathrow (LHR)',
      details: {DetailKeys.flightNumber: 'BA 283'},
    );

    String? line(FlightStatus status, {DateTime? at}) => liveFlightLineFor(flight, status, at ?? now)?.text;

    test('before take-off: how it stands, a new time, then the gate (or terminal)', () {
      final delayed = liveFlightLineFor(flight, status(), now)!;
      expect(delayed.text, 'Delayed 35 min · Leaves 11:05am · Gate B32');
      expect(delayed.tone, FlightTone.bad);
      expect(line(status(revised: '2026-10-04T10:30', gate: null)), 'On time · Terminal 5');
      expect(line(status(state: FlightState.boarding, revised: '2026-10-04T10:30')), 'Boarding · Gate B32');
      expect(line(status(revised: '2026-10-05T00:40')), 'Delayed 14 hr 10 min · Leaves 12:40am Mon 5 Oct · Gate B32');
    });

    test('in the air, when it lands; after, the belt', () {
      expect(line(status(state: FlightState.enRoute)), 'In the air · Lands 1:45pm');
      expect(line(status(state: FlightState.arrived)), 'Landed · Belt 7');
      expect(line(status(state: FlightState.canceled)), 'Cancelled');
      expect(liveFlightLineFor(flight, status(state: FlightState.canceled), now)!.tone, FlightTone.bad);
    });

    test('says when it was last checked once that\'s over an hour ago', () {
      final old = status(revised: '2026-10-04T10:30', gate: null, checkedAt: DateTime(2026, 10, 4, 7, 5));
      expect(line(old), 'On time · Terminal 5 · checked 7:05am');
      expect(
        line(status(state: FlightState.arrived, checkedAt: DateTime(2026, 10, 4, 7, 5))),
        'Landed · Belt 7',
        reason: 'a landed flight is done: no need to say',
      );
    });

    test('only on the flight\'s days, and only with something to say', () {
      expect(liveFlightLineFor(flight, null, now), isNull);
      expect(liveFlightLineFor(flight, status(), DateTime(2026, 9, 20)), isNull);
      final quiet = FlightStatus.fromJson({
        'number': 'BA 283',
        'status': 'Expected',
        'departure': {'scheduled': '2026-10-04T10:30'},
        'arrival': {'scheduled': '2026-10-04T13:45'},
      }, checkedAt: now);
      expect(liveFlightLineFor(flight, quiet, now), isNull, reason: '"Scheduled" alone says nothing new');
    });
  });
}

int _minutesBetween(String a, String b) => DateTime.parse(b).difference(DateTime.parse(a)).inMinutes;
