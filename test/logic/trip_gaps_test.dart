import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/trip_gaps.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  /// Japan, 11–16 Oct: five nights (11, 12, 13, 14, 15).
  TripPlan japan(List<Booking> bookings, {Set<String> hidden = const {}}) => TripPlan(
    trip('jp', title: 'Japan', plannedStart: d(10, 11), plannedEnd: d(10, 16)).copyWith(hiddenGaps: hidden),
    bookings,
  );

  Booking flight(String id, LocalDate date, {LocalDate? lands}) =>
      booking(id, BookingKind.flight, date, tripId: 'jp', endDate: lands);
  Booking stay(String id, LocalDate checkIn, LocalDate checkOut) =>
      booking(id, BookingKind.stay, checkIn, tripId: 'jp', endDate: checkOut);

  test('an empty trip suggests its flight out and somewhere to stay for the whole trip', () {
    expect(planGaps(japan(const [])), [
      PlanGap(kind: PlanGapKind.flightOut, start: d(10, 11)),
      PlanGap(kind: PlanGapKind.stay, start: d(10, 11), end: d(10, 16)),
    ]);
  });

  test('nights without a stay show as one gap per run', () {
    final gaps = planGaps(
      japan([
        flight('out', d(10, 11)),
        stay('kyoto', d(10, 11), d(10, 13)),
        stay('osaka', d(10, 15), d(10, 16)),
        flight('home', d(10, 16)),
      ]),
    );
    expect(gaps, [PlanGap(kind: PlanGapKind.stay, start: d(10, 13), end: d(10, 15))]);
  });

  test('an overnight flight covers the night on the plane', () {
    final gaps = planGaps(
      japan([
        flight('out', d(10, 11), lands: d(10, 12)),
        stay('tokyo', d(10, 12), d(10, 16)),
        flight('home', d(10, 16)),
      ]),
    );
    expect(gaps, isEmpty);
  });

  test('a trip that flies out but not back is missing its flight home, and the other way round', () {
    expect(planGaps(japan([flight('out', d(10, 11)), stay('tokyo', d(10, 11), d(10, 16))])), [
      PlanGap(kind: PlanGapKind.flightHome, start: d(10, 16)),
    ]);
    expect(planGaps(japan([stay('tokyo', d(10, 11), d(10, 16)), flight('home', d(10, 16))])), [
      PlanGap(kind: PlanGapKind.flightOut, start: d(10, 11)),
    ]);
  });

  test('a trip without flights might be a road trip: no flights are suggested', () {
    expect(planGaps(japan([stay('tokyo', d(10, 11), d(10, 16))])), isEmpty);
  });

  test('gaps the travellers said aren\'t needed stay hidden', () {
    final plan = japan([flight('out', d(10, 11))], hidden: {'stay:2026-10-11', 'flight-home'});
    expect(planGaps(plan), isEmpty);
    expect(PlanGap(kind: PlanGapKind.stay, start: d(10, 11)).id, 'stay:2026-10-11');
  });

  test('a trip without dates has no gaps', () {
    expect(planGaps(TripPlan(trip('x'), const [])), isEmpty);
  });

  group('wording', () {
    test('stays say which nights', () {
      final plan = japan([stay('kyoto', d(10, 11), d(10, 13))]);
      expect(describeGap(PlanGap(kind: PlanGapKind.stay, start: d(10, 13), end: d(10, 16)), plan).title, 'Stay needed');
      expect(
        describeGap(PlanGap(kind: PlanGapKind.stay, start: d(10, 13), end: d(10, 16)), plan).when,
        '13–16 Oct · 3 nights',
      );
      expect(
        describeGap(PlanGap(kind: PlanGapKind.stay, start: d(10, 11), end: d(10, 16)), japan(const [])).title,
        'Somewhere to stay',
        reason: 'nothing booked yet: the first thing to sort, not a hole',
      );
    });

    test('flights say which day', () {
      final text = describeGap(PlanGap(kind: PlanGapKind.flightHome, start: d(10, 16)), japan(const []));
      expect(text.title, 'Flight home');
      expect(text.when, '16 Oct');
    });
  });

  test('adding a stay or flight from the trip starts on the first gap it fills', () {
    final plan = japan([flight('out', d(10, 11)), stay('kyoto', d(10, 11), d(10, 13))]);
    expect(firstGapFor(BookingKind.stay, plan), PlanGap(kind: PlanGapKind.stay, start: d(10, 13), end: d(10, 16)));
    expect(firstGapFor(BookingKind.flight, plan), PlanGap(kind: PlanGapKind.flightHome, start: d(10, 16)));
    expect(firstGapFor(BookingKind.dining, plan), isNull);
    expect(firstGapFor(BookingKind.stay, japan([stay('all', d(10, 11), d(10, 16))])), isNull);
  });

  test('during the trip, gaps already behind it are skipped', () {
    final plan = japan([flight('out', d(10, 11)), stay('kyoto', d(10, 12), d(10, 14)), flight('home', d(10, 16))]);
    // Nights of the 11th and of the 14th–15th have nowhere to stay.
    expect(firstGapFor(BookingKind.stay, plan, from: d(10, 11))?.start, d(10, 11));
    expect(firstGapFor(BookingKind.stay, plan, from: d(10, 12))?.start, d(10, 14));
    expect(firstGapFor(BookingKind.stay, plan, from: d(10, 15))?.start, d(10, 14));
    expect(firstGapFor(BookingKind.stay, plan, from: d(10, 16)), isNull);
  });
}
