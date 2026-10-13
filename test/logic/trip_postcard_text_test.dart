import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/trip_plan.dart';
import 'package:travary/logic/trip_postcard_text.dart';

import '../helpers.dart';

void main() {
  TripPlan lakes({int bookings = 3, String title = 'Lake District'}) => TripPlan(
    trip('lakes', title: title, plannedStart: d(11, 25), plannedEnd: d(11, 28)),
    [for (var i = 0; i < bookings; i++) booking('b$i', BookingKind.activity, d(11, 25 + i), tripId: 'lakes')],
  );

  test("a coming trip's tag, already worded", () {
    final text = tripPostcardTextFor(lakes(), d(9, 28))!;
    expect(text.days, '58');
    expect(text.daysLabel, 'DAYS TO GO');
    expect(text.place, 'Lake District');
    expect(text.dates, '25–28 Nov 2026');
    expect(text.facts, ['4 days', '3 bookings']);
    expect(text.factsLine, '4 days · 3 bookings');
    expect(text.semanticLabel, 'Lake District, 58 days to go, 25 to 28 November 2026. 4 days, 3 bookings.');
  });

  test('tomorrow is 1 DAY; one booking; nothing booked yet', () {
    final tomorrow = tripPostcardTextFor(lakes(bookings: 1), d(11, 24))!;
    expect(tomorrow.days, '1');
    expect(tomorrow.daysLabel, 'DAY TO GO');
    expect(tomorrow.factsLine, '4 days · 1 booking');
    expect(tomorrow.semanticLabel, startsWith('Lake District, 1 day to go, '));

    final planned = tripPostcardTextFor(lakes(bookings: 0), d(9, 28))!;
    expect(planned.facts, ['4 days']);
    expect(planned.semanticLabel, 'Lake District, 58 days to go, 25 to 28 November 2026. 4 days.');
  });

  test('a trip you are on counts the days left, today included, and says which day it is', () {
    final first = tripPostcardTextFor(lakes(), d(11, 25))!;
    expect((first.days, first.daysLabel), ('4', 'DAYS LEFT'));
    expect(first.facts, ['Day 1 of 4', '3 bookings']);
    expect(first.semanticLabel, 'Lake District, 4 days left, 25 to 28 November 2026. Day 1 of 4, 3 bookings.');

    final last = tripPostcardTextFor(lakes(bookings: 1), d(11, 28))!;
    expect((last.days, last.daysLabel), ('1', 'DAY LEFT'));
    expect(last.factsLine, 'Day 4 of 4 · 1 booking');
    expect(last.semanticLabel, startsWith('Lake District, 1 day left, '));

    expect(tripPostcardTextFor(lakes(bookings: 0), d(11, 26))!.facts, ['Day 2 of 4']);
  });

  test('none once the trip is over, or without dates', () {
    expect(tripPostcardTextFor(lakes(), d(11, 29)), isNull);
    expect(tripPostcardTextFor(lakes(), d(12, 1)), isNull);
    expect(tripPostcardTextFor(TripPlan(trip('undated'), const []), d(9, 28)), isNull);
  });

  test('counts calendar dates across daylight-saving changes and years', () {
    // UK clocks go back on 25 October 2026 (a 25-hour day) and forward on
    // 28 March 2027 (23 hours); either way it's one day.
    expect(tripPostcardTextFor(lakes(), d(10, 24))!.days, '32');
    expect(tripPostcardTextFor(lakes(), d(10, 25))!.days, '31');
    expect(tripPostcardTextFor(lakes(), d(10, 26))!.days, '30');
    final spring = TripPlan(
      trip('kyoto', plannedStart: LocalDate(2027, 4, 10), plannedEnd: LocalDate(2027, 4, 16)),
      const [],
    );
    expect(tripPostcardTextFor(spring, d(9, 28))!.days, '194');
    expect(tripPostcardTextFor(spring, LocalDate(2027, 3, 27))!.days, '14');
    expect(tripPostcardTextFor(spring, LocalDate(2027, 3, 28))!.days, '13');
    for (final now in [DateTime(2026, 10, 25, 0, 1), DateTime(2026, 10, 25, 23, 59)]) {
      expect(tripPostcardTextFor(lakes(), LocalDate.fromDateTime(now))!.days, '31', reason: '$now');
    }
  });
}
