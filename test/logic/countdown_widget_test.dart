import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/countdown_widget.dart';
import 'package:travary/logic/travi_cameos.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  TripPlan lakes() => TripPlan(trip('lakes', title: 'Lake District', plannedStart: d(11, 25), plannedEnd: d(11, 28)), [
    booking('b1', BookingKind.stay, d(11, 25), tripId: 'lakes'),
  ]);
  TripPlan paris() =>
      TripPlan(trip('paris', title: 'Paris', plannedStart: d(12, 28), plannedEnd: LocalDate(2027, 1, 2)), const []);

  test('counts down every day to the trip, then the days left on it, then stops', () {
    final days = countdownWidgetDays([lakes()], d(11, 20));
    expect(days.map((day) => day.date), [for (var i = 20; i <= 28; i++) d(11, i)]);

    final first = days.first;
    expect(first.tripId, 'lakes');
    expect((first.heading, first.eyebrow), ('NEXT ADVENTURE', 'NEXT TRIP'));
    expect((first.days, first.daysLabel), ('5', 'DAYS TO GO'));
    expect((first.place, first.dates, first.shortDates), ('Lake District', '25–28 Nov 2026', '25–28 Nov'));
    expect(first.semanticLabel, 'Lake District, 5 days to go, 25 to 28 November 2026. 4 days, 1 booking.');

    final tomorrow = days[4];
    expect((tomorrow.days, tomorrow.daysLabel), ('1', 'DAY TO GO'));

    final on = days[6];
    expect((on.heading, on.eyebrow), ('ON YOUR TRIP', 'DAY 2 OF 4'));
    expect((on.days, on.daysLabel), ('3', 'DAYS LEFT'));
    expect(on.semanticLabel, 'Lake District, 3 days left, 25 to 28 November 2026. Day 2 of 4, 1 booking.');
    expect(days.last.daysLabel, 'DAY LEFT');
  });

  test("Travi's morning: how he feels about the days left, and a wave on the trip", () {
    final days = countdownWidgetDays([lakes()], d(11, 1));
    TraviPeek on(int month, int day) => days.firstWhere((x) => x.date == d(month, day)).travi;
    expect(on(11, 1), TraviPeek.cheer);
    expect(on(11, 15), TraviPeek.packing);
    expect(on(11, 22), TraviPeek.ready);
    expect(on(11, 24), TraviPeek.today);
    expect(on(11, 25), TraviPeek.wave);
    for (final day in days) {
      if (day.daysLabel.endsWith('TO GO')) expect(day.travi, countdownReactionFor(int.parse(day.days)));
    }
  });

  test("moves on to the next trip the day after one ends, as Today does", () {
    final days = countdownWidgetDays([lakes(), paris()], d(11, 27));
    expect(days.first.tripId, 'lakes');
    final after = days.firstWhere((day) => day.date == d(11, 29));
    expect((after.tripId, after.days, after.daysLabel), ('paris', '29', 'DAYS TO GO'));
    expect(days.last.date, LocalDate(2027, 1, 2));
    // A span across the new year keeps both years even without them.
    expect(after.shortDates, '28 Dec 2026 – 2 Jan 2027');
  });

  test('nothing for past or undated trips, and never past the horizon', () {
    expect(countdownWidgetDays([lakes()], d(11, 29)), isEmpty);
    expect(countdownWidgetDays([TripPlan(trip('someday', title: 'Japan'), const [])], d(11, 1)), isEmpty);
    expect(countdownWidgetDays([paris()], d(1, 1), horizon: 30), hasLength(30));
  });

  test('idle: a holiday waiting for its dates, else an invitation', () {
    final undated = TripPlan(trip('japan', title: 'Japan'), const []);
    final waiting = countdownWidgetIdle([lakes(), undated], d(12, 1));
    expect((waiting.title, waiting.message, waiting.tripId), ('Japan', 'Dates to come', 'japan'));

    final nothing = countdownWidgetIdle([lakes()], d(12, 1));
    expect((nothing.title, nothing.message, nothing.tripId), ('Where to next?', 'Plan a trip', null));
    expect(nothing.semanticLabel, 'No trips coming up. Plan your next trip in Travary.');
  });

  test("the widget's file: days by date, art by trip, Travi's stills where he stands", () {
    final days = countdownWidgetDays([lakes()], d(11, 27));
    const art = (
      portrait: 'art/p.webp',
      landscape: null,
      tag: 'art/t.webp',
      linen: null,
      ink: 0xFF1D2B45,
      paper: 0xFFF8F4EC,
    );
    final json = countdownWidgetJson(
      days: days,
      idle: countdownWidgetIdle(const [], d(11, 27)),
      trips: {'lakes': art},
      idleArt: art,
      travi: {TraviPeek.cheer: 'travi/peek-cheer.webp'},
      fonts: {'serif': 'fonts/serif.ttf'},
      generated: DateTime(2026, 11, 27, 9),
    );
    expect(json['version'], countdownWidgetVersion);
    expect((json['days']! as Map).keys, ['2026-11-27', '2026-11-28']);
    expect((json['days']! as Map)['2026-11-27'], containsPair('travi', 'wave'));
    expect((json['trips']! as Map)['lakes'], {
      'portrait': 'art/p.webp',
      'landscape': null,
      'tag': 'art/t.webp',
      'linen': null,
      'ink': '#1D2B45',
      'paper': '#F8F4EC',
    });
    expect((json['idle']! as Map)['title'], 'Where to next?');
    expect((json['travi']! as Map)['cheer'], {
      'file': 'travi/peek-cheer.webp',
      'box': [12, 88, 464, 392],
    });
    expect(json['traviCanvas'], traviCameoCanvas);
    expect(json['traviUntilHour'], countdownWidgetTraviUntilHour);
  });

  test('a tap opens the trip shown, or Today', () {
    expect(countdownWidgetLink('lakes').toString(), 'travary://trip/lakes');
    expect(countdownWidgetLink(null).toString(), 'travary://today');
    expect(countdownWidgetTarget(Uri.parse('travary://trip/lakes')), 'lakes');
    expect(countdownWidgetTarget(Uri.parse('travary://today')), '');
    expect(countdownWidgetTarget(Uri.parse('https://travary.app/join/ABC234')), isNull);
    expect(countdownWidgetTarget(Uri.parse('travary://trip')), isNull);
  });
}
