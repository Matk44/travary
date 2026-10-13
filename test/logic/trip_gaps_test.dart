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

  group('flights within the trip', () {
    Booking route(String id, LocalDate date, String title) =>
        booking(id, BookingKind.flight, date, tripId: 'jp', title: title);
    final out = route('out', d(10, 11), 'London to Osaka');
    final stays = [stay('osaka', d(10, 11), d(10, 13)), stay('sapporo', d(10, 13), d(10, 16))];

    test('one the day before the end isn\'t the flight home', () {
      final gaps = planGaps(japan([out, ...stays, route('in', d(10, 15), 'Osaka to Sapporo')]));
      expect(gaps, [PlanGap(kind: PlanGapKind.flightHome, start: d(10, 16))]);
    });

    test('one the day after the start isn\'t the flight out: with only those, both are needed', () {
      final gaps = planGaps(japan([stay('osaka', d(10, 11), d(10, 16)), route('in', d(10, 12), 'Osaka to Tokyo')]));
      expect(gaps, [
        PlanGap(kind: PlanGapKind.flightOut, start: d(10, 11)),
        PlanGap(kind: PlanGapKind.flightHome, start: d(10, 16)),
      ]);
    });

    test('a domestic trip\'s own flights are still its flights out and home', () {
      final uk = [
        route('out', d(10, 11), 'London to Edinburgh'),
        stay('edinburgh', d(10, 11), d(10, 16)),
        route('home', d(10, 16), 'Edinburgh to London'),
      ];
      expect(planGaps(japan(uk)), isEmpty);
      expect(planGaps(japan(uk.sublist(0, 2))), [PlanGap(kind: PlanGapKind.flightHome, start: d(10, 16))]);
    });
  });

  test('a night on a sleeper train or a night ferry needs no stay; a hire car or a pass does', () {
    Booking transport(String id, String title, LocalDate from, LocalDate to) =>
        booking(id, BookingKind.transport, from, tripId: 'jp', title: title, endDate: to);
    final trip = [
      flight('out', d(10, 11)),
      stay('tokyo', d(10, 11), d(10, 13)),
      stay('sapporo', d(10, 14), d(10, 16)),
      flight('home', d(10, 16)),
    ];
    expect(planGaps(japan([...trip, transport('night', 'Tokyo to Sapporo', d(10, 13), d(10, 14))])), isEmpty);
    expect(planGaps(japan([...trip, transport('pass', 'Japan Rail Pass', d(10, 11), d(10, 16))])), [
      PlanGap(kind: PlanGapKind.stay, start: d(10, 13), end: d(10, 14)),
    ]);
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
