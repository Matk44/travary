import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/day_layout.dart';
import 'package:travary/logic/day_plan.dart';

import '../helpers.dart';

void main() {
  final today = d(10, 14);
  final hotel = booking(
    'hotel',
    BookingKind.stay,
    d(10, 12),
    at: const ClockTime(15, 0),
    endDate: d(10, 18),
    until: const ClockTime(11, 0),
  );
  final park = booking('park', BookingKind.attraction, today, at: const ClockTime(9, 0));
  final lunch = booking('lunch', BookingKind.dining, today, at: const ClockTime(12, 30));
  final dinner = booking('dinner', BookingKind.dining, today, at: const ClockTime(19, 15));
  final day = [hotel, park, lunch, dinner];

  /// Each row as its booking's id, a star when featured, and its rail:
  /// "●" a stop, "|" the line passing behind, "" nothing; with "↑"/"↓" for
  /// a stop's line coming from above and carrying on below.
  List<String> describe(DayPlan plan, DayLayout layout) => [
    for (final row in layout.rows)
      [
        switch (row) {
          EntryRow(:final index, :final featured) => '${plan.entries[index].booking.id}${featured ? '*' : ''}',
          OngoingRow(:final booking) => booking.id,
        },
        _rail(row.rail),
      ].where((part) => part.isNotEmpty).join(' '),
  ];

  List<String> ids(DayPlan plan, List<int> indexes) => [for (final i in indexes) plan.entries[i].booking.id];

  test('the reference morning: next up on the rail first, the hotel after it, the rest in time order', () {
    final plan = buildDayPlan(today, day, DateTime(2026, 10, 14, 8));
    final layout = layOutDay(plan, today);
    expect(describe(plan, layout), ['park* ●↓', 'hotel |', 'lunch ↑●↓', 'dinner ↑●']);
    expect(layout.earlier, isEmpty);
    expect(layout.hasRail, isTrue);
  });

  test('the featured card keeps its place in time when something earlier is still happening', () {
    // 12:45: the park (from 9:00) is still on, lunch (12:30) is what's
    // happening now and featured.
    final plan = buildDayPlan(today, day, DateTime(2026, 10, 14, 12, 45));
    final layout = layOutDay(plan, today);
    expect(describe(plan, layout), ['park ●↓', 'lunch* ↑●↓', 'hotel |', 'dinner ↑●']);
  });

  test('the evening you arrive, the hotel stays after check-in, never under Earlier', () {
    final arrival = d(10, 12);
    final flight = booking(
      'flight',
      BookingKind.flight,
      arrival,
      at: const ClockTime(10, 0),
      until: const ClockTime(14, 30),
    );
    final supper = booking('supper', BookingKind.dining, arrival, at: const ClockTime(20, 0));
    final plan = buildDayPlan(arrival, [flight, hotel, supper], DateTime(2026, 10, 12, 18));
    final layout = layOutDay(plan, arrival);
    expect(describe(plan, layout), ['supper* ●', 'hotel']);
    expect(ids(plan, layout.earlier), ['flight']);
  });

  test('finished entries fold away under Earlier, off the rail', () {
    final plan = buildDayPlan(today, day, DateTime(2026, 10, 14, 15));
    final layout = layOutDay(plan, today);
    expect(describe(plan, layout), ['dinner* ●', 'hotel']);
    expect(ids(plan, layout.earlier), ['park', 'lunch']);
  });

  test('once everything timed is over there is no rail', () {
    final plan = buildDayPlan(today, day, DateTime(2026, 10, 14, 22));
    final layout = layOutDay(plan, today);
    expect(describe(plan, layout), ['hotel']);
    expect(ids(plan, layout.earlier), ['park', 'lunch', 'dinner']);
    expect(layout.hasRail, isFalse);
  });

  test('all-day entries follow the featured card with the hotel, the line passing behind them', () {
    final water = booking('water', BookingKind.attraction, today, title: 'Water park');
    final plan = buildDayPlan(today, [...day, water], DateTime(2026, 10, 14, 8));
    final layout = layOutDay(plan, today);
    expect(describe(plan, layout), ['park* ●↓', 'hotel |', 'water |', 'lunch ↑●↓', 'dinner ↑●']);
  });

  test('a day still to come opens with what has no time, then its stops, with nothing featured', () {
    final water = booking('water', BookingKind.attraction, d(10, 16), title: 'Water park');
    final show = booking('show', BookingKind.event, d(10, 16), at: const ClockTime(20, 0));
    final breakfast = booking('breakfast', BookingKind.dining, d(10, 16), at: const ClockTime(8, 30));
    final plan = buildDayPlan(d(10, 16), [hotel, water, show, breakfast], DateTime(2026, 10, 14, 8));
    final layout = layOutDay(plan, today);
    expect(describe(plan, layout), ['hotel', 'water', 'breakfast ●↓', 'show ↑●']);
    expect(layout.earlier, isEmpty);
  });

  test('a past day is rows in time order, off the rail and unfolded', () {
    final breakfast = booking('breakfast', BookingKind.dining, d(10, 13), at: const ClockTime(8, 30));
    final show = booking('show', BookingKind.event, d(10, 13), at: const ClockTime(20, 0));
    final plan = buildDayPlan(d(10, 13), [hotel, show, breakfast], DateTime(2026, 10, 14, 8));
    final layout = layOutDay(plan, today);
    expect(describe(plan, layout), ['hotel', 'breakfast', 'show']);
    expect(layout.earlier, isEmpty);
    expect(layout.hasRail, isFalse);
  });

  test('a lone stop has no line; check-in and check-out are stops at their times', () {
    final checkIn = buildDayPlan(d(10, 12), [hotel], DateTime(2026, 10, 11, 8));
    expect(describe(checkIn, layOutDay(checkIn, d(10, 11))), ['hotel ●']);

    final flight = booking('flight', BookingKind.flight, d(10, 18), at: const ClockTime(18, 40));
    final lastDay = buildDayPlan(d(10, 18), [hotel, flight], DateTime(2026, 10, 18, 8));
    expect(describe(lastDay, layOutDay(lastDay, d(10, 18))), ['hotel* ●↓', 'flight ↑●']);
  });
}

String _rail(RailMark rail) {
  if (rail.stop) return '${rail.lineAbove ? '↑' : ''}●${rail.lineBelow ? '↓' : ''}';
  expect(rail.lineAbove, rail.lineBelow, reason: 'the line passes behind a row, or not at all');
  return rail.lineAbove ? '|' : '';
}
