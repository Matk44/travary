import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/trip_hero_text.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  final japan = TripPlan(trip('jp', title: 'Japan', plannedStart: d(10, 11), plannedEnd: d(10, 30)), const []);

  test('before, during and after the trip', () {
    String status(int month, int day) => tripHeroTextFor(japan, d(month, day)).status;
    expect(status(10, 5), '6 days to go');
    expect(status(10, 10), 'Tomorrow');
    expect(status(10, 11), 'Starts today');
    expect(status(10, 13), 'Day 3 of 20');
    expect(status(10, 30), 'Last day');
    expect(status(11, 2), 'Trip over');
  });

  test('names and dates the trip', () {
    final text = tripHeroTextFor(japan, d(10, 5));
    expect(text.title, 'Japan');
    expect(text.dates, '11–30 Oct 2026');
    expect(text.semanticLabel, 'Japan, 11 to 30 October 2026, 6 days to go.');
  });

  test('a trip without dates says so', () {
    final text = tripHeroTextFor(TripPlan(trip('x', title: ' '), const []), d(10, 5));
    expect(text.title, 'Your trip');
    expect(text.dates, 'No dates yet');
  });

  test('says where it goes when the name doesn\'t', () {
    TripPlan named(String title) => TripPlan(
      trip('x', title: title, plannedStart: d(10, 11), plannedEnd: d(10, 30)).copyWith(
        destination: const TripDestination(countryCode: 'JP', countryName: 'Japan'),
      ),
      const [],
    );
    expect(tripHeroTextFor(named('Our Japanese adventure'), d(10, 5)).place, 'JAPAN');
    expect(tripHeroTextFor(named('Japan holiday'), d(10, 5)).place, isNull);
    expect(tripHeroTextFor(japan, d(10, 5)).place, isNull, reason: 'no destination');
  });
}
