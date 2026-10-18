import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/today_sheet.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  TripPlan plan(String id, LocalDate start, LocalDate end) =>
      TripPlan(trip(id, plannedStart: start, plannedEnd: end), const []);

  final past = plan('past', d(9, 1), d(9, 5));
  final orlando = plan('orlando', d(10, 12), d(10, 18));
  final lakes = plan('lakes', d(11, 25), d(11, 28));
  final paris = plan('paris', d(12, 18), d(12, 21));
  final undated = TripPlan(trip('someday'), const []);
  final plans = [past, orlando, lakes, paris, undated];

  TodaySheet sheetOn(LocalDate today, {bool Function(TripPlan)? countsDown, List<TripPlan>? among}) {
    final all = among ?? plans;
    return todaySheetFor(all, focusFor(all, today), today, countsDown: countsDown ?? (_) => true);
  }

  List<String> named(TodaySheet sheet) => [
    for (final page in sheet.pages)
      switch (page) {
        TripDayPage(:final plan, :final day) => '${plan.id} ${day.day}/${day.month}',
        CountdownPage(:final plan) => 'countdown ${plan.id}',
        EndPage() => 'end',
      },
  ];

  group('during a trip', () {
    final sheet = sheetOn(d(10, 14));

    test('opens on today, with the trip\'s earlier days a swipe back', () {
      expect(sheet.pages[sheet.opening], TripDayPage(orlando, d(10, 14)));
      expect(sheet.opening, 2);
      expect(sheet.pages.first, TripDayPage(orlando, d(10, 12)), reason: 'the trip\'s first day, never the past trip');
    });

    test('runs on through every trip to come, each counting down before its first day, then where to next', () {
      expect(named(sheet), [
        for (var day = 12; day <= 18; day++) 'orlando $day/10',
        'countdown lakes',
        for (var day = 25; day <= 28; day++) 'lakes $day/11',
        'countdown paris',
        for (var day = 18; day <= 21; day++) 'paris $day/12',
        'end',
      ]);
    });

    test('each countdown knows the trip before it; the end knows the last', () {
      expect((sheet.pages[7] as CountdownPage).after?.id, 'orlando');
      expect((sheet.pages[12] as CountdownPage).after?.id, 'lakes');
      expect((sheet.pages.last as EndPage).after.id, 'paris');
    });
  });

  group('between trips', () {
    test('opens on the next trip\'s countdown, which starts the sheet', () {
      final sheet = sheetOn(d(9, 28));
      expect(sheet.opening, 0);
      expect(sheet.pages.first, CountdownPage(orlando));
      expect((sheet.pages.first as CountdownPage).after, isNull, reason: 'nothing before it on the sheet');
      expect(sheet.pages[1], TripDayPage(orlando, d(10, 12)));
    });

    test('without a countdown, opens on the next trip\'s first day', () {
      final sheet = sheetOn(d(9, 28), countsDown: (_) => false);
      expect(sheet.pages[sheet.opening], TripDayPage(orlando, d(10, 12)));
      expect(sheet.opening, 0);
      expect(named(sheet), isNot(contains(startsWith('countdown'))));
      // The next trip follows the last day of the one before.
      expect(sheet.pages[7], TripDayPage(lakes, d(11, 25)));
    });

    test('only the trips that have one count down', () {
      final sheet = sheetOn(d(9, 28), countsDown: (plan) => plan.id != 'lakes');
      expect(
        named(sheet),
        containsAllInOrder(['countdown orlando', 'orlando 18/10', 'lakes 25/11', 'countdown paris']),
      );
      expect(named(sheet), isNot(contains('countdown lakes')));
    });
  });

  test('the last day of the last trip is followed by where to next', () {
    final sheet = sheetOn(d(12, 21));
    expect(named(sheet), ['paris 18/12', 'paris 19/12', 'paris 20/12', 'paris 21/12', 'end']);
    expect(sheet.pages[sheet.opening], TripDayPage(paris, d(12, 21)));
  });

  test('nothing on or coming, or only a trip without dates: no sheet', () {
    expect(sheetOn(d(12, 30)).isEmpty, isTrue);
    expect(sheetOn(d(10, 14), among: [undated]).isEmpty, isTrue);
    expect(sheetOn(d(10, 14), among: const []).isEmpty, isTrue);
  });

  test('pages are found again by what they show, after the dates move', () {
    final sheet = sheetOn(d(10, 14));
    // The trip starts a day earlier: Wednesday is one page further on.
    final earlier = plan('orlando', d(10, 11), d(10, 18));
    final moved = sheetOn(d(10, 14), among: [earlier, lakes]);
    expect(moved.indexOf(sheet.pages[2]), 3);
    expect(moved.indexOf(CountdownPage(lakes)), 8);
    expect(moved.indexOf(EndPage(lakes)), moved.pages.length - 1, reason: 'one end, whichever trip it follows');
    // A day the trip no longer has is gone.
    final shorter = sheetOn(d(10, 14), among: [plan('orlando', d(10, 12), d(10, 16))]);
    expect(shorter.indexOf(TripDayPage(orlando, d(10, 18))), isNull);
  });
}
