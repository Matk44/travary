import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/countdown_trip_hero.dart';
import 'package:travary/design/widgets/today_header.dart';
import 'package:travary/design/widgets/travi_cameo.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/today/today_screen.dart';
import 'package:travary/state/travel_store.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';

/// Today is one sheet of pages that follows the finger: the trip's days,
/// each trip to come counting down before its first day, and where to next
/// at the end.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  Future<void> pump(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  final sheet = find.descendant(of: find.byType(TodayScreen), matching: find.byType(PageView));
  PageController pages(WidgetTester tester) => tester.widget<PageView>(sheet).controller!;

  /// The day line of the page on screen (the only page built once settled).
  String dayLine(WidgetTester tester) => tester.widget<TodayHeader>(find.byType(TodayHeader)).subtitle;

  Future<void> swipe(WidgetTester tester, {required bool forward}) async {
    await tester.fling(sheet, Offset(forward ? -300 : 300, 0), 1200);
    await tester.pumpAndSettle();
  }

  /// Every page position from now until the sheet settles.
  Future<List<double>> positions(WidgetTester tester) async {
    final seen = <double>[pages(tester).page!];
    for (var ms = 0; ms <= 800; ms += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(pages(tester).page!);
    }
    await tester.pumpAndSettle();
    return seen..add(pages(tester).page!);
  }

  Future<void> chooseDay(WidgetTester tester, String label) async {
    await tester.tap(find.byType(HeaderPill));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(label));
  }

  group('during a trip (Orlando, day 3 of 7)', () {
    testWidgets('the days follow the finger, side by side, and spring back when let go short of halfway', (
      tester,
    ) async {
      await pump(tester, canonicalTodayApp());
      expect(pages(tester).page, 2, reason: 'days 1 and 2 are a swipe back');

      final gesture = await tester.startGesture(tester.getCenter(sheet));
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(pages(tester).page, inExclusiveRange(2.2, 2.5), reason: 'the sheet moves with the finger');
      // Today's cards slide out as the next day's header slides in.
      expect(find.text('Magic Kingdom'), findsOneWidget);
      expect(find.text('Thu 15 Oct · Day 4 of 7 · Orlando'), findsOneWidget);
      final today = tester.getTopLeft(find.text('Day 3 of 7 · Orlando'));
      final next = tester.getTopLeft(find.text('Thu 15 Oct · Day 4 of 7 · Orlando'));
      expect(next.dx - today.dx, closeTo(390, 0.5), reason: 'one sheet: the next day joins on, a screen along');
      expect(next.dy, today.dy);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(pages(tester).page, 2);
      expect(dayLine(tester), 'Day 3 of 7 · Orlando');
    });

    testWidgets('let go past halfway, the next day settles in', (tester) async {
      await pump(tester, canonicalTodayApp());
      final gesture = await tester.startGesture(tester.getCenter(sheet));
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-220, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(pages(tester).page, 3);
      expect(dayLine(tester), 'Thu 15 Oct · Day 4 of 7 · Orlando');
    });

    testWidgets('a flick settles with a little bobble, like the tabs', (tester) async {
      await pump(tester, canonicalTodayApp());
      await tester.fling(sheet, const Offset(-200, 0), 1500);
      final seen = await positions(tester);
      final furthest = seen.reduce(math.max);
      expect(furthest, greaterThan(3.005), reason: 'it overshoots the day');
      expect(furthest, lessThan(3.1), reason: 'by only a few points');
      expect(seen.last, 3);
      expect(dayLine(tester), 'Thu 15 Oct · Day 4 of 7 · Orlando');

      await tester.fling(sheet, const Offset(200, 0), 1500);
      final back = await positions(tester);
      expect(back.reduce(math.min), lessThan(1.995), reason: 'the same bobble on the way back');
      expect(back.last, 2);
    });

    testWidgets('a day picked in the calendar slides in from the one beside it, with the tabs\' bobble', (
      tester,
    ) async {
      await pump(tester, canonicalTodayApp());
      await chooseDay(tester, 'Day 6 of 7, Saturday 17 October');
      await tester.pump();
      final seen = await positions(tester);
      expect(seen.first, greaterThanOrEqualTo(4), reason: 'from the day beside it, not through every day');
      expect(seen.every((page) => page >= 4), isTrue);
      expect(seen.reduce(math.max), greaterThan(5), reason: 'overshoots a little');
      expect(seen.last, 5);
      expect(dayLine(tester), 'Sat 17 Oct · Day 6 of 7 · Orlando');
    });

    testWidgets('with reduced motion a picked day is there at once', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pump(tester, canonicalTodayApp());
      await chooseDay(tester, 'Day 6 of 7, Saturday 17 October');
      await tester.pump();
      expect(pages(tester).page, 5);

      // A flick still follows the finger, and settles without the bobble.
      await tester.fling(sheet, const Offset(200, 0), 1500);
      final seen = await positions(tester);
      expect(seen.reduce(math.min), greaterThanOrEqualTo(4), reason: 'no overshoot');
      expect(seen.last, 4);
    });

    testWidgets('before the first day the sheet stops: past trips live on the Trips tab', (tester) async {
      await pump(tester, canonicalTodayApp());
      await swipe(tester, forward: false);
      await swipe(tester, forward: false);
      expect(dayLine(tester), 'Mon 12 Oct · Day 1 of 7 · Orlando');
      await swipe(tester, forward: false);
      expect(pages(tester).page, 0);
      expect(dayLine(tester), 'Mon 12 Oct · Day 1 of 7 · Orlando');
      expect(tester.takeException(), isNull);
    });

    testWidgets('after the last day of the last trip: where to next, then the sheet stops', (tester) async {
      await pump(tester, canonicalTodayApp());
      await chooseDay(tester, 'Day 7 of 7, Sunday 18 October');
      await tester.pumpAndSettle();
      await swipe(tester, forward: true);
      expect(dayLine(tester), 'After Orlando');
      expect(find.text('Where to next?'), findsOneWidget);
      expect(find.byType(TraviCameo), findsOneWidget, reason: 'Travi, folio open for the next one');
      expect(find.text('New trip'), findsOneWidget);
      expect(find.byType(HeaderPill), findsNothing, reason: 'no day to show or choose');

      await swipe(tester, forward: true);
      expect(find.text('Where to next?'), findsOneWidget, reason: 'nothing further');
      await swipe(tester, forward: false);
      expect(dayLine(tester), 'Sun 18 Oct · Day 7 of 7 · Orlando');
    });
  });

  group('between trips (Lake District in 58 days, then Paris)', () {
    testWidgets('the countdown opens the sheet, before the trip\'s first day', (tester) async {
      await pump(tester, countdownTodayApp());
      expect(find.byType(CountdownTripHero), findsOneWidget);
      expect(dayLine(tester), 'Nothing planned today');
      await swipe(tester, forward: false);
      expect(find.byType(CountdownTripHero), findsOneWidget, reason: 'nothing before it: the past is on Trips');

      await swipe(tester, forward: true);
      expect(dayLine(tester), 'Lake District in 58 days');
      expect(find.text('Lakeside Cottage'), findsOneWidget);
      expect(find.text('58 days'), findsOneWidget, reason: 'the pill counts down on its first day');
      expect(find.byType(CountdownTripHero), findsNothing);

      await swipe(tester, forward: false);
      expect(find.byType(CountdownTripHero), findsOneWidget);
    });

    testWidgets('past the last day of a trip, the next one counts down, then its days, then where to next', (
      tester,
    ) async {
      await pump(tester, countdownTodayApp());
      for (var day = 0; day < 4; day++) {
        await swipe(tester, forward: true);
      }
      expect(dayLine(tester), 'Sat 28 Nov · Day 4 of 4 · Lake District');

      await swipe(tester, forward: true);
      expect(dayLine(tester), 'After Lake District');
      expect(find.byType(CountdownTripHero), findsOneWidget);
      for (final text in ['NEXT ADVENTURE', 'NEXT TRIP', '73', 'DAYS TO GO', 'Paris']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      final postcard = tester.widget<Image>(find.byKey(const ValueKey('countdown-postcard')));
      expect((postcard.image as FileImage).file.path, countdownPostcardSource('city_fr_paris'));
      expect(find.byType(HeaderPill), findsNothing, reason: 'the tag has the count; the page isn\'t today');

      await swipe(tester, forward: true);
      expect(dayLine(tester), 'Paris in 73 days');
      expect(find.text('Hotel Le Marais'), findsOneWidget);

      await swipe(tester, forward: true);
      expect(dayLine(tester), 'After Paris');
      expect(find.text('Where to next?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without a postcard, a trip goes straight from the one before to its first day', (tester) async {
      await pump(tester, countdownTodayApp(catalog: const ArtCatalog.empty()));
      expect(find.byType(CountdownTripHero), findsNothing);
      expect(dayLine(tester), 'Lake District in 58 days');
      for (var day = 0; day < 4; day++) {
        await swipe(tester, forward: true);
      }
      expect(dayLine(tester), 'Paris in 73 days');
    });
  });

  testWidgets('the page on screen stays put when its trip gains an earlier day', (tester) async {
    final created = DateTime(2026, 10, 1);
    Booking on(String id, String title, int day) => Booking(
      id: id,
      tripId: 'trip',
      kind: BookingKind.activity,
      title: title,
      startDate: LocalDate(2026, 10, day),
      startTime: const ClockTime(10, 0),
      createdAt: created,
      updatedAt: created,
    );
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [
          Trip(
            id: 'trip',
            title: 'Test holiday',
            ownerId: 'me',
            memberIds: const ['me'],
            createdAt: created,
            updatedAt: created,
          ),
        ],
        [on('mon', 'Monday booking', 12), on('tue', 'Tuesday booking', 13), on('wed', 'Wednesday booking', 14)],
      );
    final store = TravelStore(
      repository: repository,
      artCatalog: const ArtCatalog.empty(),
      clock: () => DateTime(2026, 10, 12, 8),
    );
    await pump(
      tester,
      ChangeNotifierProvider.value(
        value: store,
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: const Scaffold(body: TodayScreen()),
        ),
      ),
    );
    await swipe(tester, forward: true);
    await swipe(tester, forward: true);
    expect(find.text('Wednesday booking'), findsOneWidget);
    expect(pages(tester).page, 2);

    // A day before the trip is booked: Wednesday is a page further on, and
    // stays on screen.
    await repository.saveBooking(on('sun', 'Sunday booking', 11));
    await tester.pumpAndSettle();
    expect(find.text('Wednesday booking'), findsOneWidget);
    expect(pages(tester).page, 3);
    expect(dayLine(tester), 'Wed 14 Oct · Day 4 of 4 · Test holiday');
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
