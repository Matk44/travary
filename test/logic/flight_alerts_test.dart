import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/flight_alerts.dart';

import '../helpers.dart';

void main() {
  final flight = booking('out', BookingKind.flight, d(10, 14), details: {DetailKeys.flightNumber: 'BA 2037'});

  test('alerts cover flights with a number until they land, up to a year ahead', () {
    expect(flightAlertsCover(flight, d(10, 12)), isTrue);
    expect(flightAlertsCover(flight, d(10, 14)), isTrue, reason: 'on the day');
    expect(flightAlertsCover(flight, d(10, 15)), isFalse, reason: 'landed');
    final overnight = booking('red-eye', BookingKind.flight, d(10, 14), endDate: d(10, 15), details: flight.details);
    expect(flightAlertsCover(overnight, d(10, 15)), isTrue, reason: 'still flying');
    expect(flightAlertsCover(flight, d(10, 14).addDays(-366)), isFalse, reason: 'past the airline\'s schedules');
    expect(flightAlertsCover(booking('no-number', BookingKind.flight, d(10, 14)), d(10, 12)), isFalse);
    expect(
      flightAlertsCover(
        booking('typo', BookingKind.flight, d(10, 14), details: {DetailKeys.flightNumber: 'the 9am'}),
        d(10, 12),
      ),
      isFalse,
    );
    expect(
      flightAlertsCover(booking('train', BookingKind.transport, d(10, 14), details: flight.details), d(10, 12)),
      isFalse,
    );
  });

  test('notifications are asked for once, on a paid trip\'s flight', () {
    bool ask({
      bool allowed = true,
      bool covered = true,
      NotificationPermission permission = NotificationPermission.notAsked,
    }) => shouldAskForNotifications(allowed: allowed, covered: covered, permission: permission);
    expect(ask(), isTrue);
    expect(ask(allowed: false), isFalse, reason: 'a free trip: the row sells it instead');
    expect(ask(covered: false), isFalse, reason: 'a flight already flown');
    expect(ask(permission: NotificationPermission.allowed), isFalse);
    expect(ask(permission: NotificationPermission.denied), isFalse, reason: 'never nag');
  });

  test('where alerts stand on this phone', () {
    expect(flightAlertsStateFor(allowed: false, permission: NotificationPermission.allowed), FlightAlertsState.locked);
    expect(flightAlertsStateFor(allowed: true, permission: NotificationPermission.allowed), FlightAlertsState.on);
    expect(flightAlertsStateFor(allowed: true, permission: NotificationPermission.denied), FlightAlertsState.blocked);
    expect(flightAlertsStateFor(allowed: true, permission: NotificationPermission.notAsked), FlightAlertsState.ask);
  });

  test('the row sells flight changes: never gates, never a trial', () {
    for (final state in FlightAlertsState.values) {
      for (final everyone in [true, false]) {
        final text = flightAlertsTextFor(state, flightNumber: 'ba 2037', everyone: everyone, shared: true);
        final words = '${text.title} ${text.subtitle}'.toLowerCase();
        expect(words, isNot(contains('gate')));
        expect(words, isNot(contains('trial')));
        expect(words, isNot(contains('free')));
        expect(text.subtitle, contains('BA\u00A02037'), reason: 'the number stays on one line');
      }
    }
    expect(
      flightAlertsTextFor(FlightAlertsState.on, flightNumber: 'BA 2037', everyone: true, shared: true).subtitle,
      'Everyone on this trip hears the moment BA\u00A02037 is delayed, moved or cancelled.',
    );
    expect(
      flightAlertsTextFor(FlightAlertsState.on, flightNumber: 'BA 2037', everyone: false, shared: true).subtitle,
      'You\'ll hear the moment BA\u00A02037 is delayed, moved or cancelled.',
      reason: 'only their own Plus covers it',
    );
    expect(
      flightAlertsTextFor(FlightAlertsState.on, flightNumber: 'BA 2037', everyone: true, shared: false).subtitle,
      startsWith('You\'ll hear'),
      reason: 'nobody else on the trip yet',
    );
  });
}
