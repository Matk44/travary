import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/card_text.dart';
import 'package:travary/logic/flight_status_text.dart';

void main() {
  test('a trip reads its flights\' live state, as the server writes it', () {
    final trip = Trip.fromJson('orlando', {
      'title': 'Orlando',
      'ownerId': 'alice',
      'memberIds': ['alice'],
      'liveFlights': {
        'out': {
          'number': 'BA 2037',
          'status': 'Delayed',
          'departure': {'airport': 'LGW', 'scheduled': '2026-10-14T09:30', 'revised': '2026-10-14T10:15', 'gate': '12'},
          'arrival': {'airport': 'MCO', 'scheduled': '2026-10-14T14:30'},
          'checkedAt': DateTime(2026, 10, 14, 7).millisecondsSinceEpoch,
        },
        'junk': 'not a flight',
        'unchecked': {'number': 'BA 1'},
      },
    });
    expect(trip.liveFlights.keys, ['out']);
    final out = trip.liveFlights['out']!;
    expect(out.state, FlightState.delayed);
    expect(out.departure.gate, '12');
    expect(out.checkedAt, DateTime(2026, 10, 14, 7));
    expect(trip.copyWith(title: 'Florida').liveFlights, same(trip.liveFlights), reason: 'kept through edits');
    expect(trip.toJson().containsKey('liveFlights'), isFalse, reason: 'the app never writes it');
    expect(trip.toEditableJson().containsKey('liveFlights'), isFalse);
  });

  test('a card\'s wording keeps everything when a live line is added', () {
    const text = CardText(
      eyebrow: 'NEXT UP',
      title: 'London to Orlando',
      when: '9:30am',
      detail: 'BA 2037',
      place: 'Gatwick',
      stub: 'SEAT 14A',
      reference: 'ABC123',
      footnote: 'F',
      action: 'Show tickets',
      badge: '4',
      badgeCaption: 'C',
      day: '14',
      month: 'Oct',
    );
    const live = LiveFlightLine(text: 'Delayed 45 min', tone: FlightTone.bad);
    final withLive = text.withLive(live);
    expect(withLive.live, live);
    expect(
      [
        withLive.eyebrow,
        withLive.title,
        withLive.when,
        withLive.detail,
        withLive.place,
        withLive.stub,
        withLive.reference,
        withLive.footnote,
        withLive.action,
        withLive.badge,
        withLive.badgeCaption,
        withLive.day,
        withLive.month,
      ],
      [
        'NEXT UP',
        'London to Orlando',
        '9:30am',
        'BA 2037',
        'Gatwick',
        'SEAT 14A',
        'ABC123',
        'F',
        'Show tickets',
        '4',
        'C',
        '14',
        'Oct',
      ],
    );
  });
}
