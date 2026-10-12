import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_slots.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/trip_chrome.dart';
import 'package:travary/design/widgets/common.dart';
import 'package:travary/design/widgets/countdown_trip_hero.dart';
import 'package:travary/design/widgets/nav_bar.dart';
import 'package:travary/design/widgets/time_rail.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/logic/art_pack_selection.dart';
import 'package:travary/logic/countdown_text.dart';
import 'package:travary/logic/travi_cameos.dart';
import 'package:travary/logic/trip_plan.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';
import '../support/travi.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);
  final bundled = bundledArtCatalog();
  final withPostcards = bundled.withPacks(countdownPostcardSourcePacks());

  Future<void> pump(
    WidgetTester tester,
    Widget app, {
    double width = 390,
    double height = 844,
    bool settle = true,
  }) async {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * 3);
    addTearDown(tester.view.reset);
    // A fresh store (with its clock and catalog) for every app.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app);
    if (settle) await tester.pumpAndSettle();
  }

  /// [text]'s box in the tag image's own (unturned) frame.
  Rect onTag(WidgetTester tester, Finder text) {
    final tag = tester.renderObject<RenderBox>(find.byKey(const ValueKey('countdown-tag-raster')));
    final box = tester.renderObject<RenderBox>(text);
    return Rect.fromPoints(
      tag.globalToLocal(box.localToGlobal(Offset.zero)),
      tag.globalToLocal(box.localToGlobal(box.size.bottomRight(Offset.zero))),
    );
  }

  /// The tag's card (without cord and shadow) in the same frame.
  Rect tagCard(WidgetTester tester) {
    final size = tester.getSize(find.byKey(const ValueKey('countdown-tag-raster')));
    final body = SurfaceSlot.countdownTag.body!;
    return Rect.fromLTRB(
      body.left * size.width,
      body.top * size.height,
      body.right * size.width,
      body.bottom * size.height,
    );
  }

  void expectOnTagCard(WidgetTester tester) {
    final card = tagCard(tester);
    for (final text in ['NEXT TRIP', '58', 'DAYS TO GO', '25–28 Nov 2026']) {
      final box = onTag(tester, find.text(text));
      expect(card.contains(box.topLeft) && card.contains(box.bottomRight), isTrue, reason: '$text on the card');
      // Below the eyelet and cord.
      expect(box.top, greaterThan(card.top + card.height * 0.2), reason: text);
    }
  }

  /// Every line of text on screen, top to bottom.
  List<String> screenText(WidgetTester tester) => [
    for (final element in find.byType(Text).evaluate()) ?(element.widget as Text).data,
  ];

  const lakesLabel = 'Lake District, 58 days to go, 25 to 28 November 2026.';

  group('between trips', () {
    testWidgets('counts down to the earliest coming trip on its postcard', (tester) async {
      await pump(tester, countdownTodayApp());

      expect(find.byType(CountdownTripHero), findsOneWidget);
      expect(find.text('Nothing planned today'), findsOneWidget);
      expect(find.text('Mon 28 Sep'), findsOneWidget, reason: 'the pill shows the date; the tag has the count');
      for (final text in ['NEXT ADVENTURE', 'NEXT TRIP', '58', 'DAYS TO GO', 'Lake District', '25–28 Nov 2026']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // Just the postcard and its tag: no facts or button under it.
      for (final text in ['4 days', '3 bookings', 'Opens 25 Nov', 'View trip']) {
        expect(find.text(text), findsNothing, reason: text);
      }
      // Lake District comes before Paris; the past Orlando trip is gone.
      expect(find.text('Paris'), findsNothing);
      expect(find.text('Orlando'), findsNothing);
      // The Lake District's own postcard, whole; the shared blank tag.
      final postcard = tester.widget<Image>(find.byKey(const ValueKey('countdown-postcard')));
      expect(postcard.image, isA<FileImage>());
      expect((postcard.image as FileImage).file.path, countdownPostcardSource('region_gb_lake_district'));
      expect(postcard.fit, BoxFit.contain, reason: 'never crop the deckled edge');
      expect(
        tester.widget<Image>(find.byKey(const ValueKey('countdown-tag-raster'))).image,
        const AssetImage('assets/art/common/countdown_luggage_tag.png'),
      );
      // No itinerary preview, day chooser or swipe while counting down.
      expect(find.text('Lakeside Cottage'), findsNothing);
      expect(find.byType(TimeRailRow), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Choose a day')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the postcard sits in its own proportions, with the tag over its lower right corner', (tester) async {
      await pump(tester, countdownTodayApp());
      final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
      expect(card.width / card.height, closeTo(1122 / 1402, 0.001));
      expect(card.width, closeTo(CountdownTripHero.postcardWidth(390, 844), 0.5));
      final hero = tester.getRect(find.byKey(const ValueKey('countdown-hero')));
      expect(hero.height, lessThanOrEqualTo(844 * CountdownLayout.stageMaxHeight + 0.5));

      // The tag stack turns as one, clockwise, from the eyelet.
      final swing = tester.widget<Transform>(find.byKey(const ValueKey('countdown-tag-swing')));
      expect(_degrees(swing), closeTo(CountdownLayout.tagAngleDegrees, 0.01));
      for (final text in ['NEXT TRIP', '58', 'Lake District', '25–28 Nov 2026']) {
        expect(
          find.ancestor(of: find.text(text), matching: find.byKey(const ValueKey('countdown-tag-swing'))),
          findsOneWidget,
          reason: '$text turns with the tag',
        );
      }
      // The tag's card is about a third of the postcard wide, over its
      // lower right corner, with about half of it below the card; the hero
      // takes in the part that hangs below, so it can be tapped too.
      final tag = tester.getRect(find.byKey(const ValueKey('countdown-tag-raster')));
      expect(tagCard(tester).width / card.width, closeTo(CountdownLayout.tagWidth, 0.005));
      expect(tag.center.dx, greaterThan(card.center.dx));
      // The tag's card corners where they're drawn, hanging at an angle.
      final raster = tester.renderObject<RenderBox>(find.byKey(const ValueKey('countdown-tag-raster')));
      final c = tagCard(tester);
      final corners = [
        for (final corner in [c.topLeft, c.topRight, c.bottomLeft, c.bottomRight]) raster.localToGlobal(corner),
      ];
      final tagTop = corners.map((p) => p.dy).reduce(math.min);
      final tagBottom = corners.map((p) => p.dy).reduce(math.max);
      final drawnCardBottom = card.top + card.height * CountdownGeometry.postcardCardBottom;
      expect(tagTop, lessThan(drawnCardBottom));
      expect(tagBottom, greaterThan(drawnCardBottom));
      expect((tagBottom - drawnCardBottom) / (tagBottom - tagTop), closeTo(CountdownLayout.tagBelow, 0.08));
      expect(hero.bottom, greaterThanOrEqualTo(tagBottom), reason: 'the part below can be tapped too');
      expectOnTagCard(tester);
      final stage = find.ancestor(of: find.byKey(const ValueKey('countdown-tag-swing')), matching: find.byType(Stack));
      expect(tester.widget<Stack>(stage.first).clipBehavior, Clip.none);
      expect(tester.getCenter(find.text('58')).dx, greaterThan(card.center.dx));
      expect(tester.getCenter(find.text('58')).dy, greaterThan(card.center.dy), reason: 'in the lower half');
    });

    testWidgets('one summary for screen readers, on the one button', (tester) async {
      await pump(tester, countdownTodayApp());
      final handle = tester.ensureSemantics();
      final hero = find.bySemanticsLabel(lakesLabel);
      expect(hero, findsOneWidget);
      expect(tester.getSemantics(hero), containsSemantics(isButton: true, hasTapAction: true));
      expect(tester.getSize(hero).height, greaterThanOrEqualTo(48));
      expect(find.bySemanticsLabel('View trip'), findsNothing);
      handle.dispose();
    });

    testWidgets('tapping the postcard opens the trip; its tag brings Travi up instead', (tester) async {
      await pump(tester, countdownTodayApp());

      // The picture itself, left of the tag.
      final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
      await tester.tapAt(Offset(card.left + card.width * 0.2, card.top + card.height * 0.6));
      await tester.pumpAndSettle();
      expect(tester.widget<TripScreen>(find.byType(TripScreen)).tripId, 'lakes');
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 58 days to go: he pops up from behind the card, cheering, and ducks.
      Finder travi(String still) => find.descendant(
        of: find.byKey(const ValueKey('countdown-travi')),
        matching: find.byKey(ValueKey('travi-still-$still')),
      );
      expect(travi('peek-cheer'), findsNothing);
      await tester.tap(find.text('58'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(travi('peek-cheer'), findsOneWidget);
      expect(find.byType(TripScreen), findsNothing);
      await tester.pump(traviPeekHold);
      await tester.pumpAndSettle();
      expect(travi('peek-cheer'), findsNothing);
      expect(find.byType(TripScreen), findsNothing);
    });

    testWidgets('Travi sits behind the postcard\'s top right, under the card', (tester) async {
      await pump(tester, countdownTodayApp());
      final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
      final travi = tester.getRect(find.byKey(const ValueKey('countdown-travi')));
      // Cut off just below the card's top edge, in its right half.
      final cardTop = card.top + card.height * CountdownGeometry.postcardCardTop;
      expect(travi.bottom, greaterThan(cardTop));
      expect(travi.bottom, lessThan(cardTop + 10));
      expect(travi.center.dx, greaterThan(card.center.dx));
      expect(travi.right, lessThan(card.right));
    });

    testWidgets('it gives a little under a finger', (tester) async {
      await pump(tester, countdownTodayApp());
      double scale() => tester.widget<AnimatedScale>(find.byKey(const ValueKey('countdown-press'))).scale;
      expect(scale(), 1);
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('countdown-postcard'))));
      // A press registers after a moment, so a scroll isn't taken for one.
      await tester.pump(kPressTimeout + const Duration(milliseconds: 20));
      expect(scale(), CountdownLayout.pressScale);
      await gesture.cancel();
      await tester.pump();
      expect(scale(), 1);
    });

    testWidgets('the count comes from calendar dates, whatever the time of day', (tester) async {
      // 25 October 2026: UK clocks go back at 2am, a 25-hour day.
      for (final now in [DateTime(2026, 10, 25, 0, 5), DateTime(2026, 10, 25, 23, 55)]) {
        await pump(tester, countdownTodayApp(now: now));
        expect(find.text('31'), findsOneWidget, reason: '$now');
        expect(find.text('DAYS TO GO'), findsOneWidget);
      }
      await pump(tester, countdownTodayApp(now: DateTime(2026, 11, 24, 21, 0)));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('DAY TO GO'), findsOneWidget);
      expect(find.bySemanticsLabel('Lake District, 1 day to go, 25 to 28 November 2026.'), findsOneWidget);
    });

    testWidgets('a forecast still shows in the pill', (tester) async {
      await pump(
        tester,
        countdownTodayApp(weather: const WeatherReport(temperature: 14, condition: WeatherCondition.cloudy)),
      );
      expect(find.text('14° Cloudy'), findsOneWidget);
      expect(find.byType(CountdownTripHero), findsOneWidget);
    });

    testWidgets('a postcard file that cannot load leaves a plain card under the same tag', (tester) async {
      final broken = bundled.withPacks([
        postcardPack(
          'region_gb_lake_district',
          country: 'GB',
          region: 'lake_district',
          postcard: '/nowhere/countdown_postcard.png',
        ),
      ]);
      await pump(tester, countdownTodayApp(catalog: broken));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('countdown-postcard-fallback')), findsOneWidget);
      expect(find.text('58'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('everything else stays as it was', () {
    testWidgets('during a trip Today is its itinerary, postcards or not', (tester) async {
      final orlando = verifiedProfile(ExperienceTheme.themepark, country: 'US', region: 'florida', city: 'orlando');
      await pump(tester, canonicalTodayApp(catalog: bundled, profile: orlando));
      final without = screenText(tester);

      await pump(tester, canonicalTodayApp(catalog: withPostcards, profile: orlando));
      expect(find.byType(CountdownTripHero), findsNothing);
      expect(find.text('Day 3 of 7 · Orlando'), findsOneWidget);
      expect(find.text('Magic Kingdom'), findsOneWidget);
      expect(screenText(tester), without);
    });

    testWidgets('a free day during a trip stays a free day', (tester) async {
      final data = countdownTodayData();
      final cornwall = countdownTrip('cornwall', 'Cornwall');
      await pump(
        tester,
        countdownTodayApp(
          catalog: withPostcards,
          data: (
            trips: [...data.trips, cornwall],
            bookings: [
              ...data.bookings,
              countdownBooking('surf', 'cornwall', BookingKind.activity, 'Surf lesson', LocalDate(2026, 9, 26)),
              countdownBooking('train', 'cornwall', BookingKind.transport, 'Train home', LocalDate(2026, 9, 30)),
            ],
          ),
        ),
      );
      expect(find.byType(CountdownTripHero), findsNothing);
      expect(find.text('A free day'), findsOneWidget);
      expect(find.text('Day 3 of 5 · Cornwall'), findsOneWidget);
      // Travi lounges in his deckchair; a tap and he sips (no films in tests).
      final lounge = find.byKey(const ValueKey('travi-lounge'));
      expect(find.descendant(of: lounge, matching: find.byKey(const ValueKey('travi-still-lounge'))), findsOneWidget);
      await tester.tap(lounge);
      await tester.pumpAndSettle();
      expect(find.descendant(of: lounge, matching: find.byKey(const ValueKey('travi-still-lounge'))), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    String postcardShown(WidgetTester tester) {
      final image = tester.widget<Image>(find.byKey(const ValueKey('countdown-postcard'))).image;
      return switch (image) {
        FileImage(:final file) => file.path,
        AssetImage(:final assetName) => assetName,
        _ => '$image',
      };
    }

    testWidgets('no postcard for the trip\'s place: the countdown on the neutral postcard', (tester) async {
      await pump(tester, countdownTodayApp(catalog: bundled));
      expect(find.byType(CountdownTripHero), findsOneWidget);
      expect(postcardShown(tester), 'assets/art/common/countdown_postcard_anywhere.webp');
      expect(find.text('Lake District'), findsOneWidget, reason: 'the tag still names the trip');
    });

    testWidgets("never another place's postcard: Tokyo gets the neutral one, not the five destination cards", (
      tester,
    ) async {
      final tokyo = verifiedProfile(ExperienceTheme.urbanModern, country: 'JP', region: 'kanto', city: 'tokyo');
      await pump(
        tester,
        countdownTodayApp(
          catalog: withPostcards,
          data: countdownTodayData(lakesTitle: 'Tokyo', lakesProfile: tokyo),
        ),
      );
      expect(postcardShown(tester), 'assets/art/common/countdown_postcard_anywhere.webp');
      expect(find.text('Tokyo'), findsOneWidget);
    });

    testWidgets('without the neutral postcard either, the usual view of the first day', (tester) async {
      final withoutNeutral = ArtCatalog.fromAssetPaths(
        bundledArtPaths().where((path) => !path.contains('countdown_postcard_anywhere')),
      );
      await pump(tester, countdownTodayApp(catalog: withoutNeutral));
      expect(find.byType(CountdownTripHero), findsNothing);
      expect(find.text('Lake District in 58 days'), findsOneWidget);
      expect(find.text('Lakeside Cottage'), findsOneWidget);
    });

    testWidgets('with no trip ahead, the empty states', (tester) async {
      final data = countdownTodayData();
      await pump(
        tester,
        countdownTodayApp(
          catalog: withPostcards,
          data: (
            trips: data.trips.where((t) => t.id == 'orlando').toList(),
            bookings: data.bookings.where((b) => b.tripId == 'orlando').toList(),
          ),
        ),
      );
      expect(find.byType(CountdownTripHero), findsNothing);
      expect(find.text('Nothing coming up'), findsOneWidget);
      expect(traviCameo(TraviMoment.waiting), findsOneWidget);

      await pump(tester, countdownTodayApp(catalog: withPostcards, data: (trips: const [], bookings: const [])));
      expect(find.byType(CountdownTripHero), findsNothing);
      expect(find.text('Where are you off to?'), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(traviCameo(TraviMoment.waiting), findsOneWidget);
    });
  });

  group('motion', () {
    Future<void> untilHero(WidgetTester tester) async {
      for (var i = 0; i < 5 && find.byType(CountdownTripHero).evaluate().isEmpty; i++) {
        await tester.pump();
      }
      expect(find.byType(CountdownTripHero), findsOneWidget);
    }

    double postcardOpacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find.ancestor(of: find.byKey(const ValueKey('countdown-postcard-motion')), matching: find.byType(Opacity)),
        )
        .opacity;

    double tagOpacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find.ancestor(of: find.byKey(const ValueKey('countdown-tag-swing')), matching: find.byType(Opacity)).first,
        )
        .opacity;

    double tagAngle(WidgetTester tester) =>
        _degrees(tester.widget<Transform>(find.byKey(const ValueKey('countdown-tag-swing'))));

    double tagScale(WidgetTester tester) =>
        tester.widget<Transform>(find.byKey(const ValueKey('countdown-tag-slap'))).transform.getMaxScaleOnAxis();

    testWidgets('the postcard lifts in, the tag is slapped on, swings both ways and comes to rest', (tester) async {
      await pump(tester, countdownTodayApp(), settle: false);
      await untilHero(tester);
      const rest = CountdownLayout.tagAngleDegrees;

      await tester.pump(const Duration(milliseconds: 150));
      expect(postcardOpacity(tester), inExclusiveRange(0, 1), reason: 'the postcard is fading in');
      expect(tagOpacity(tester), 0, reason: 'the tag waits for the postcard');

      // 620 ms in, mid-slap: the tag is coming down, larger than life.
      await tester.pump(const Duration(milliseconds: 470));
      expect(postcardOpacity(tester), 1);
      expect(tagOpacity(tester), greaterThan(0));
      expect(tagScale(tester), greaterThan(1.05));

      // Then it swings either side of where it will hang.
      final angles = <double>[];
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        angles.add(tagAngle(tester));
      }
      expect(tagScale(tester), closeTo(1, 0.001), reason: 'landed');
      expect(angles.any((a) => a > rest + 1), isTrue, reason: 'swings one way');
      expect(angles.any((a) => a < rest - 1), isTrue, reason: 'and the other');
      expect(angles.every((a) => (a - rest).abs() < CountdownLayout.tagSwingDegrees), isTrue, reason: 'only a little');

      await tester.pumpAndSettle();
      expect(tagAngle(tester), closeTo(rest, 0.01));
      expect(tagOpacity(tester), 1);
      expect(tagScale(tester), closeTo(1, 0.001));
    });

    testWidgets('it plays again whenever Today comes back into view', (tester) async {
      await pump(tester, countdownTodayApp());
      expect(postcardOpacity(tester), 1);
      Finder tab(String label) =>
          find.descendant(of: find.byType(TravaryNavBar), matching: find.bySemanticsLabel(label));

      // Its tab, chosen again.
      await tester.tap(tab('Trips'));
      await tester.pumpAndSettle();
      await tester.tap(tab('Today'));
      // Partway through the page's slide back in, the entry is under way.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(postcardOpacity(tester), lessThan(1), reason: 'the entry restarted');
      await tester.pumpAndSettle();
      expect(postcardOpacity(tester), 1);

      // Back from the background (not merely interrupted).
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));
      expect(postcardOpacity(tester), 1, reason: 'Control Centre and the like don\'t replay it');
      for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(postcardOpacity(tester), lessThan(1));
      await tester.pumpAndSettle();

      // A screen opened from it, closed again.
      await tester.tap(find.byKey(const ValueKey('countdown-postcard')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(postcardOpacity(tester), lessThan(1));
      await tester.pumpAndSettle();
      expect(tagAngle(tester), closeTo(CountdownLayout.tagAngleDegrees, 0.01));
    });

    testWidgets('once the entry settles, Travi pops up to wave, if it\'s his first today', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      var asked = 0;
      Widget hero(bool firstToday) => heroAlone(
        ArtCatalog.fromAssetPaths(bundledArtPaths()),
        greet: () async {
          asked++;
          return firstToday;
        },
      );
      Finder wave() => find.byKey(const ValueKey('travi-still-peek-wave'));
      // Through the entry, then a frame for him to come up.
      Future<void> entry() async {
        for (var t = Duration.zero; t <= CountdownLayout.entryDuration; t += const Duration(milliseconds: 100)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pump();
        await tester.pump();
      }

      await tester.pumpWidget(hero(true));
      await entry();
      expect(asked, 1);
      expect(wave(), findsOneWidget);
      await tester.pump(traviPeekHold);
      await tester.pump();
      expect(wave(), findsNothing, reason: 'he ducks back down');

      // Already greeted today: the entry plays, he stays hidden.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(hero(false));
      await entry();
      expect(asked, 2);
      expect(wave(), findsNothing);
    });

    testWidgets('with reduced motion everything is in place at once', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pump(tester, countdownTodayApp(), settle: false);
      await untilHero(tester);

      expect(postcardOpacity(tester), 1);
      expect(tagOpacity(tester), 1);
      expect(tagAngle(tester), closeTo(CountdownLayout.tagAngleDegrees, 0.01));
      expect(tagScale(tester), closeTo(1, 0.001));
      expect(
        tester.widget<Transform>(find.byKey(const ValueKey('countdown-postcard-motion'))).transform.getTranslation().y,
        0,
      );
    });
  });

  group('small, large and enlarged', () {
    for (final width in [320.0, 390.0, 430.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('${width.toInt()} points wide at text scale $scale: no overflow', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pump(tester, countdownTodayApp(), width: width, height: 640);
          expect(tester.takeException(), isNull);
          expectOnTagCard(tester);

          await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expectPostcardFits(tester, width);
        });
      }
    }

    // The hero alone, past what the rest of Today is tested at: a tablet,
    // and double-size text.
    for (final (width, scale) in [(768.0, 1.0), (768.0, 2.0), (320.0, 2.0), (320.0, 3.0)]) {
      testWidgets('the hero alone, ${width.toInt()} points at text scale $scale: no overflow', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester, heroAlone(bundled), width: width, height: 1024);
        expect(tester.takeException(), isNull);
        expectOnTagCard(tester);
        final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
        expect(card.width, lessThanOrEqualTo(CountdownLayout.postcardMaxWidth));
        expect(card.center.dx, closeTo(width / 2, 0.5));
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expectPostcardFits(tester, width);
      });
    }

    testWidgets('a long destination name shrinks, never cut short', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const name = 'Santiago de Compostela and the Rías Baixas';
      await pump(
        tester,
        countdownTodayApp(
          data: countdownTodayData(lakesTitle: name),
          now: countdownNow,
        ),
        width: 320,
        height: 640,
      );
      expect(tester.takeException(), isNull);
      final place = find.text(name);
      expect(place, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(place);
      expect(paragraph.maxLines, isNull);
      expect(paragraph.overflow, TextOverflow.clip);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.widget<Text>(place).style!.fontSize, lessThan(TravaryText.tagPlace.fontSize!));
      expect(find.bySemanticsLabel(RegExp('^$name, 58 days to go')), findsOneWidget);
    });
  });
}

void expectPostcardFits(WidgetTester tester, double width) {
  final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
  expect(card.left, greaterThanOrEqualTo(0));
  expect(card.right, lessThanOrEqualTo(width));
}

/// Just the hero for the Lake District, on the bundled tag.
Widget heroAlone(ArtCatalog catalog, {Future<bool> Function()? greet}) {
  final data = countdownTodayData();
  final plan = TripPlan(data.trips.first, data.bookings.where((b) => b.tripId == 'lakes'));
  return MaterialApp(
    theme: buildTravaryTheme(),
    home: TravaryChrome(
      colors: TripColors.bundled,
      slots: ArtSlots(catalog, TripArtContext.forTheme(ExperienceTheme.countryside)),
      child: Scaffold(
        body: SingleChildScrollView(
          child: CountdownTripHero(
            text: countdownTextFor(plan, LocalDate.fromDateTime(countdownNow))!,
            postcard: FileArtImage(countdownPostcardSource('region_gb_lake_district')),
            onOpen: () {},
            greet: greet,
          ),
        ),
      ),
    ),
  );
}

/// A 2D rotation's angle in degrees.
double _degrees(Transform transform) {
  final m = transform.transform;
  return math.atan2(m.entry(1, 0), m.entry(0, 0)) * 180 / math.pi;
}
