import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
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

    test('falls back to the month', () {
      expect(suggestTripTitle(booking('h', BookingKind.stay, d(10, 12))), 'October trip');
    });
  });
}
