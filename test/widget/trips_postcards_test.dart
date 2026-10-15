import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_slots.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/upcoming_trip_postcard.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/features/trips/trips_screen.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';
import '../support/open_tab.dart';
import '../support/trip_postcards.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);
  final bundled = bundledArtCatalog();
  final withPostcards = bundled.withPacks(tripPostcardSourcePacks());

  /// The Trips tab on the mockup's day (28 September 2026), with just the
  /// three coming trips unless [data] says otherwise.
  Future<void> pumpTrips(
    WidgetTester tester, {
    ArtCatalog? catalog,
    ({List<Trip> trips, List<Booking> bookings})? data,
    DateTime? now,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * 3);
    addTearDown(tester.view.reset);
    // A fresh store (with its clock and catalog) for every app.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      countdownTodayApp(
        catalog: catalog ?? withPostcards,
        data: data ?? upcomingTripsData(activeAndPast: false),
        now: now,
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'Trips');
  }

  Finder postcard(String tripId) => find.byKey(ValueKey('trip-postcard-$tripId'));
  Finder inPostcard(String tripId, Finder finder) => find.descendant(of: postcard(tripId), matching: finder);
  final tiles = find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_TripTile');
  Finder tile(String title) => find.ancestor(of: find.text(title), matching: tiles);

  /// The tag's facts: on one line where they fit ("4 days · 3 bookings",
  /// as with the app's fonts), else one per line (the test font is wider).
  void expectFacts(String tripId, List<String> facts) {
    final oneLine = inPostcard(tripId, find.text(facts.join(' · ')));
    if (oneLine.evaluate().isNotEmpty) return;
    for (final fact in facts) {
      expect(inPostcard(tripId, find.text(fact)), findsOneWidget, reason: '$tripId: $fact');
    }
  }

  // Plain rows have a fixed height: the test font's wide glyphs need a wide
  // screen to keep their lines from wrapping.
  const rowWidth = 640.0;
  final everything = upcomingTripsData();

  const lakesLabel = 'Lake District, 58 days to go, 25 to 28 November 2026. 4 days, 3 bookings.';

  group('coming up', () {
    testWidgets('each coming trip on its own postcard, with its countdown on the tag', (tester) async {
      await pumpTrips(tester);

      expect(find.byType(UpcomingTripPostcard), findsNWidgets(3));
      for (final (trip, lines, facts) in [
        ('lakes', ['58', 'DAYS TO GO', 'Lake District', '25–28 Nov 2026'], ['4 days', '3 bookings']),
        ('kyoto', ['194', 'DAYS TO GO', 'Kyoto', '10–16 Apr 2027'], ['7 days', '2 bookings']),
      ]) {
        for (final line in lines) {
          expect(inPostcard(trip, find.text(line)), findsOneWidget, reason: '$trip: $line');
        }
        expectFacts(trip, facts);
      }
      // Soonest first.
      expect(tester.getTopLeft(postcard('lakes')).dy, lessThan(tester.getTopLeft(postcard('kyoto')).dy));

      // Each trip's own postcard: the Lake District's region pack, Kyoto's city pack.
      FileImage art(String trip) {
        final image = tester.widget<Image>(inPostcard(trip, find.byKey(const ValueKey('trip-postcard-art')))).image;
        return (image as ResizeImage).imageProvider as FileImage;
      }

      expect(art('lakes').file.path, tripPostcardSource('region_gb_lake_district'));
      expect(art('kyoto').file.path, tripPostcardSource('city_jp_kyoto'));
      await tester.scrollUntilVisible(
        postcard('orlando'),
        300,
        scrollable: find.descendant(of: find.byType(TripsScreen), matching: find.byType(Scrollable)).first,
      );
      await tester.pumpAndSettle();
      expect(art('orlando').file.path, tripPostcardSource('city_us_orlando'));
      expectFacts('orlando', ['8 days', '1 booking']);
      // The shared blank countdown tag, not a copy.
      final tag = tester.widget<Image>(inPostcard('lakes', find.byKey(const ValueKey('trip-tag-raster')))).image;
      expect((tag as ResizeImage).imageProvider, const AssetImage('assets/art/common/countdown_luggage_tag.webp'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the whole postcard, never cropped, with the tag over its right edge', (tester) async {
      await pumpTrips(tester);
      final art = inPostcard('lakes', find.byKey(const ValueKey('trip-postcard-art')));
      expect(tester.widget<Image>(art).fit, BoxFit.contain);
      final card = tester.getRect(art);
      expect(card.width / card.height, closeTo(1536 / 1024, 0.001), reason: 'its own proportions: nothing cut off');
      expect(card.width, closeTo(390 - 2 * TripPostcardLayout.inset, 0.5));

      // The tag's card is about 31% of the postcard wide, at its right edge.
      final tagImage = inPostcard('lakes', find.byKey(const ValueKey('trip-tag-raster')));
      final body = SurfaceSlot.countdownTag.body!;
      final tagCard = tester.getSize(tagImage).width * body.width;
      expect(tagCard / card.width, inInclusiveRange(0.29, 0.32));
      final tagBox = tester.getRect(tagImage);
      expect(tagBox.center.dx, greaterThan(card.left + card.width * 0.75));
      expect(tagBox.top, lessThan(card.top), reason: 'the cord runs up past the postcard');
      for (final stack in tester.widgetList<Stack>(inPostcard('lakes', find.byType(Stack)))) {
        expect(stack.clipBehavior, Clip.none, reason: 'nothing clips the cord');
      }

      // Turned 3–5° clockwise as one: shell and words.
      for (final trip in ['lakes', 'kyoto']) {
        final swing = tester.widget<Transform>(inPostcard(trip, find.byKey(const ValueKey('trip-tag-swing'))));
        expect(_degrees(swing), inInclusiveRange(3, 5), reason: trip);
      }
      expect(
        find.ancestor(of: find.text('Lake District'), matching: find.byKey(const ValueKey('trip-tag-swing'))),
        findsOneWidget,
      );
      _expectOnTagCard(tester, 'lakes');
    });

    testWidgets('one button per postcard for screen readers, and it opens the trip', (tester) async {
      await pumpTrips(tester);
      final handle = tester.ensureSemantics();
      final lakes = find.bySemanticsLabel(lakesLabel);
      expect(lakes, findsOneWidget);
      expect(tester.getSemantics(lakes), containsSemantics(isButton: true, hasTapAction: true));
      expect(find.bySemanticsLabel(RegExp(r'^Kyoto, 194 days to go, 10 to 16 April 2027\.')), findsOneWidget);
      // The tag's words and the pictures aren't read twice.
      expect(find.bySemanticsLabel('58'), findsNothing);
      expect(find.bySemanticsLabel('Lake District'), findsNothing);
      handle.dispose();

      // The picture, away from the tag.
      final card = tester.getRect(inPostcard('lakes', find.byKey(const ValueKey('trip-postcard-art'))));
      await tester.tapAt(Offset(card.left + card.width * 0.25, card.center.dy));
      await tester.pumpAndSettle();
      expect(tester.widget<TripScreen>(find.byType(TripScreen)).tripId, 'lakes');
      await tester.pageBack();
      await tester.pumpAndSettle();

      // The tag is part of the postcard.
      await tester.tap(find.text('194'));
      await tester.pumpAndSettle();
      expect(tester.widget<TripScreen>(find.byType(TripScreen)).tripId, 'kyoto');
    });

    testWidgets('tomorrow reads 1 DAY TO GO, counted by the calendar at any hour', (tester) async {
      for (final now in [DateTime(2026, 11, 24, 0, 5), DateTime(2026, 11, 24, 23, 55)]) {
        await pumpTrips(tester, now: now);
        expect(inPostcard('lakes', find.text('1')), findsOneWidget, reason: '$now');
        expect(inPostcard('lakes', find.text('DAY TO GO')), findsOneWidget);
      }
      // 25 October 2026: UK clocks go back, a 25-hour day.
      await pumpTrips(tester, now: DateTime(2026, 10, 25, 23, 30));
      expect(inPostcard('lakes', find.text('31')), findsOneWidget);
      expect(inPostcard('lakes', find.text('DAYS TO GO')), findsOneWidget);
    });
  });

  group('happening now', () {
    testWidgets('the trip you are on is on its postcard too, with the days left and which day it is', (tester) async {
      // The Lake District's second day: the 26th of 25–28 November.
      await pumpTrips(tester, now: DateTime(2026, 11, 26, 9));

      expect(postcard('lakes'), findsOneWidget);
      for (final line in ['3', 'DAYS LEFT', 'Lake District', '25–28 Nov 2026']) {
        expect(inPostcard('lakes', find.text(line)), findsOneWidget, reason: line);
      }
      expectFacts('lakes', ['Day 2 of 4', '3 bookings']);
      expect(find.text('HAPPENING NOW'), findsOneWidget);
      expect(find.text('COMING UP'), findsOneWidget, reason: 'Kyoto and the rest are still ahead');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the last day says 1 DAY LEFT', (tester) async {
      await pumpTrips(tester, now: DateTime(2026, 11, 28, 20));
      expect(inPostcard('lakes', find.text('1')), findsOneWidget);
      expect(inPostcard('lakes', find.text('DAY LEFT')), findsOneWidget);
      expectFacts('lakes', ['Day 4 of 4', '3 bookings']);
    });
  });

  group('everything else stays as it was', () {
    testWidgets('a demo trip without a verified location keeps its plain row', (tester) async {
      final data = (
        trips: [countdownTrip('demo', 'Demo getaway')],
        bookings: [countdownBooking('demo-stay', 'demo', BookingKind.stay, 'Demo hotel', LocalDate(2026, 11, 25))],
      );

      await pumpTrips(tester, data: data, width: rowWidth);
      expect(postcard('demo'), findsNothing);
      expect(tile('Demo getaway'), findsOneWidget);
      expect(find.textContaining('Starts in 58 days'), findsOneWidget);
    });

    testWidgets('happening now and past trips keep their rows, word for word', (tester) async {
      /// Cornwall's and Rome's rows, scrolling down to Rome's.
      Future<Map<String, List<String>>> rows() async {
        List<String> row(String title) => [
          for (final element in find.descendant(of: tile(title), matching: find.byType(Text)).evaluate())
            ?(element.widget as Text).data,
        ];
        final cornwall = row('Cornwall');
        await tester.scrollUntilVisible(
          find.text('Rome'),
          300,
          scrollable: find.descendant(of: find.byType(TripsScreen), matching: find.byType(Scrollable)).first,
        );
        await tester.pumpAndSettle();
        return {'Cornwall': cornwall, 'Rome': row('Rome')};
      }

      await pumpTrips(tester, catalog: bundled, data: everything, width: rowWidth);
      expect(postcard('lakes'), findsNothing, reason: 'no postcards installed');
      final before = await rows();

      await pumpTrips(tester, data: everything, width: rowWidth);
      expect(postcard('lakes'), findsOneWidget);
      expect(tile('Cornwall'), findsOneWidget);
      expect(tile('Lake District'), findsNothing);
      final after = await rows();
      expect(after, before);
      expect(after['Cornwall'], contains('2 bookings · Day 3 of 5'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the heading, New trip and the sections stay in order', (tester) async {
      await pumpTrips(tester, data: everything, width: rowWidth);
      expect(find.text('New trip'), findsOneWidget);
      final labels = ['HAPPENING NOW', 'COMING UP', 'PAST TRIPS'];
      var previous = tester.getTopLeft(find.text('Trips').first).dy;
      for (final label in labels) {
        await tester.scrollUntilVisible(
          find.text(label),
          300,
          scrollable: find.descendant(of: find.byType(TripsScreen), matching: find.byType(Scrollable)).first,
        );
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // Back at the top: each section below the one before.
      await tester.drag(
        find.descendant(of: find.byType(TripsScreen), matching: find.byType(Scrollable)).first,
        const Offset(0, 5000),
      );
      await tester.pumpAndSettle();
      for (final label in labels.take(2)) {
        final top = tester.getTopLeft(find.text(label)).dy;
        expect(top, greaterThan(previous), reason: label);
        previous = top;
      }
    });

    testWidgets('no postcard for a trip: its plain row, never another place', (tester) async {
      final tokyo = verifiedProfile(ExperienceTheme.urbanModern, country: 'JP', region: 'kanto', city: 'tokyo');
      await pumpTrips(
        tester,
        data: upcomingTripsData(lakesTitle: 'Tokyo', lakesProfile: tokyo),
        width: rowWidth,
      );
      expect(postcard('lakes'), findsNothing);
      expect(tile('Tokyo'), findsOneWidget);
      expect(find.textContaining('Starts in 58 days'), findsOneWidget);
      // Kyoto and Orlando still have theirs.
      expect(postcard('kyoto'), findsOneWidget);
      expect(postcard('orlando'), findsOneWidget);
    });

    testWidgets('a trip without dates keeps its row', (tester) async {
      final data = upcomingTripsData(activeAndPast: false);
      await pumpTrips(
        tester,
        data: (
          trips: [
            ...data.trips,
            countdownTrip(
              'someday',
              'Someday in Paris',
              profile: verifiedProfile(ExperienceTheme.urbanHeritage, country: 'FR', city: 'paris'),
            ),
          ],
          bookings: data.bookings,
        ),
      );
      expect(postcard('someday'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Someday in Paris'),
        300,
        scrollable: find.descendant(of: find.byType(TripsScreen), matching: find.byType(Scrollable)).first,
      );
      expect(tile('Someday in Paris'), findsOneWidget);
    });

    testWidgets('a postcard file that cannot load leaves a plain card under the same tag', (tester) async {
      final broken = bundled.withPacks([
        tripPostcardPack(
          'region_gb_lake_district',
          country: 'GB',
          region: 'lake_district',
          postcard: '/nowhere/trip_postcard.png',
        ),
      ]);
      await pumpTrips(tester, catalog: broken, width: rowWidth);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
      expect(inPostcard('lakes', find.byKey(const ValueKey('trip-postcard-fallback'))), findsOneWidget);
      expect(inPostcard('lakes', find.text('58')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('small, large and enlarged', () {
    for (final width in [320.0, 390.0, 430.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('${width.toInt()} points wide at text scale $scale: no overflow', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpTrips(tester, width: width, height: 700);
          expect(tester.takeException(), isNull);
          _expectOnTagCard(tester, 'lakes');
          await tester.drag(
            find.descendant(of: find.byType(TripsScreen), matching: find.byType(CustomScrollView)).first,
            const Offset(0, -3000),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('a tablet centres the postcards at their widest', (tester) async {
      await pumpTrips(tester, width: 768, height: 1024);
      final card = tester.getRect(inPostcard('lakes', find.byKey(const ValueKey('trip-postcard-art'))));
      expect(card.width, TripPostcardLayout.maxWidth);
      expect(card.center.dx, closeTo(384, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long name shrinks or wraps, never cut short', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const name = 'Santiago de Compostela and the Rías Baixas';
      await pumpTrips(tester, data: upcomingTripsData(lakesTitle: name, activeAndPast: false), width: 320, height: 640);
      expect(tester.takeException(), isNull);
      final place = inPostcard('lakes', find.text(name));
      expect(place, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(place);
      expect(paragraph.maxLines, isNull);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.widget<Text>(place).style!.fontSize, lessThan(TravaryText.tripTagPlace.fontSize!));
      _expectOnTagCard(tester, 'lakes', lines: [name, '25–28 Nov 2026']);
      expect(find.bySemanticsLabel(RegExp('^$name, 58 days to go')), findsOneWidget);
    });
  });
}

/// The tag's words sit on its card, below the eyelet (measured in the
/// tag's own, unturned frame).
void _expectOnTagCard(
  WidgetTester tester,
  String tripId, {
  List<String> lines = const ['58', 'DAYS TO GO', 'Lake District', '25–28 Nov 2026'],
}) {
  final row = find.byKey(ValueKey('trip-postcard-$tripId'));
  final tagFinder = find.descendant(of: row, matching: find.byKey(const ValueKey('trip-tag-raster')));
  final tag = tester.renderObject<RenderBox>(tagFinder);
  final body = SurfaceSlot.countdownTag.body!;
  final card = Rect.fromLTRB(
    body.left * tag.size.width,
    body.top * tag.size.height,
    body.right * tag.size.width,
    body.bottom * tag.size.height,
  );
  for (final line in lines) {
    final box = tester.renderObject<RenderBox>(find.descendant(of: row, matching: find.text(line)));
    final rect = Rect.fromPoints(
      tag.globalToLocal(box.localToGlobal(Offset.zero)),
      tag.globalToLocal(box.localToGlobal(box.size.bottomRight(Offset.zero))),
    );
    expect(card.contains(rect.topLeft) && card.contains(rect.bottomRight), isTrue, reason: '$line on the card');
    expect(rect.top, greaterThan(card.top + card.height * 0.2), reason: '$line below the eyelet');
  }
}

/// A 2D rotation's angle in degrees.
double _degrees(Transform transform) {
  final m = transform.transform;
  return math.atan2(m.entry(1, 0), m.entry(0, 0)) * 180 / math.pi;
}
