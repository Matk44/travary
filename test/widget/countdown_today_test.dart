import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_slots.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/trip_chrome.dart';
import 'package:travary/design/widgets/common.dart';
import 'package:travary/design/widgets/countdown_trip_hero.dart';
import 'package:travary/design/widgets/day_timeline.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/logic/art_pack_selection.dart';
import 'package:travary/logic/countdown_text.dart';
import 'package:travary/logic/trip_plan.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);
  final bundled = bundledArtCatalog();
  final withPostcards = bundled.withPacks(pendingPostcardPacks());

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
      for (final text in [
        'NEXT ADVENTURE',
        'NEXT TRIP',
        '58',
        'DAYS TO GO',
        'Lake District',
        '25–28 Nov 2026',
        '4 days',
        '3 bookings',
        'Opens 25 Nov',
        'View trip',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // Lake District comes before Paris; the past Orlando trip is gone.
      expect(find.text('Paris'), findsNothing);
      expect(find.text('Orlando'), findsNothing);
      // The Lake District's own postcard, whole; the shared blank tag.
      final postcard = tester.widget<Image>(find.byKey(const ValueKey('countdown-postcard')));
      expect(postcard.image, isA<FileImage>());
      expect((postcard.image as FileImage).file.path, pendingPostcard('region_gb_lake_district'));
      expect(postcard.fit, BoxFit.contain, reason: 'never crop the deckled edge');
      expect(
        tester.widget<Image>(find.byKey(const ValueKey('countdown-tag-raster'))).image,
        const AssetImage('assets/art/common/countdown_luggage_tag.png'),
      );
      // No itinerary preview, day chooser or swipe while counting down.
      expect(find.text('Lakeside Cottage'), findsNothing);
      expect(find.byType(DayTimeline), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Choose a day')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the postcard sits in its own proportions, with the tag over its upper right', (tester) async {
      await pump(tester, countdownTodayApp());
      final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
      expect(card.width / card.height, closeTo(1122 / 1402, 0.001));
      expect(card.width, closeTo(CountdownTripHero.postcardWidth(390, 844), 0.5));
      expect(card.height, lessThanOrEqualTo(844 * CountdownLayout.postcardMaxHeight + 0.5));

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
      // The tag's card is about 46% of the postcard wide, over its upper
      // right, and may reach above it (nothing clips it).
      final tag = tester.getRect(find.byKey(const ValueKey('countdown-tag-raster')));
      expect(tagCard(tester).width / card.width, closeTo(CountdownLayout.tagWidth, 0.005));
      expect(tag.center.dx, greaterThan(card.center.dx));
      expect(tag.top, lessThan(card.top), reason: 'the cord runs up past the postcard');
      expectOnTagCard(tester);
      final stage = find.ancestor(of: find.byKey(const ValueKey('countdown-tag-swing')), matching: find.byType(Stack));
      expect(tester.widget<Stack>(stage.first).clipBehavior, Clip.none);
      expect(tester.getCenter(find.text('58')).dx, greaterThan(card.center.dx));
      expect(tester.getCenter(find.text('58')).dy, lessThan(card.center.dy + card.height * 0.25));
    });

    testWidgets('one summary for screen readers, and real buttons', (tester) async {
      await pump(tester, countdownTodayApp());
      final handle = tester.ensureSemantics();
      final hero = find.bySemanticsLabel(lakesLabel);
      expect(hero, findsOneWidget);
      expect(tester.getSemantics(hero), containsSemantics(isButton: true, hasTapAction: true));
      final button = find.bySemanticsLabel('View trip');
      expect(button, findsOneWidget);
      expect(tester.getSemantics(button), containsSemantics(isButton: true, hasTapAction: true));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
      // The facts are plain text for screen readers too.
      expect(find.bySemanticsLabel('3 bookings'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the postcard and View trip both open the trip', (tester) async {
      await pump(tester, countdownTodayApp());

      // The picture itself, left of the tag.
      final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
      await tester.tapAt(Offset(card.left + card.width * 0.2, card.top + card.height * 0.6));
      await tester.pumpAndSettle();
      expect(tester.widget<TripScreen>(find.byType(TripScreen)).tripId, 'lakes');
      await tester.pageBack();
      await tester.pumpAndSettle();

      // The tag is part of the hero.
      await tester.tap(find.text('58'));
      await tester.pumpAndSettle();
      expect(tester.widget<TripScreen>(find.byType(TripScreen)).tripId, 'lakes');
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('View trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View trip'));
      await tester.pumpAndSettle();
      expect(tester.widget<TripScreen>(find.byType(TripScreen)).tripId, 'lakes');
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

    testWidgets('the fact tags and button use their rasters when a pack has them, text still live', (tester) async {
      await pump(tester, countdownTodayApp());
      expect(find.byKey(const ValueKey('countdown-fact-fallback')), findsNWidgets(3), reason: 'not made yet');
      expect(find.byKey(const ValueKey('countdown-button-fallback')), findsOneWidget);

      final lakes = pendingPostcardPacks().first;
      final dressed = ArtPackContent(
        pack: lakes.pack,
        assets: const [],
        common: {
          ...lakes.common,
          'countdown_fact_tag': const FileArtImage('/packs/lakes/countdown_fact_tag.png'),
          'countdown_button': const FileArtImage('/packs/lakes/countdown_button.png'),
        },
      );
      await pump(tester, countdownTodayApp(catalog: bundled.withPacks([dressed])));
      expect(find.byKey(const ValueKey('countdown-fact-raster')), findsNWidgets(3));
      expect(find.byKey(const ValueKey('countdown-button-raster')), findsOneWidget);
      expect(find.byKey(const ValueKey('countdown-fact-fallback')), findsNothing);
      for (final text in ['4 days', '3 bookings', 'Opens 25 Nov', 'View trip']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
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
    });

    testWidgets('no postcard for the trip: the usual view of its first day', (tester) async {
      await pump(tester, countdownTodayApp(catalog: bundled));
      expect(find.byType(CountdownTripHero), findsNothing);
      expect(find.text('Lake District in 58 days'), findsOneWidget);
      expect(find.text('58 days'), findsOneWidget, reason: 'the countdown pill');
      expect(find.text('Lakeside Cottage'), findsOneWidget);
    });

    testWidgets("never another place's postcard: Tokyo gets none of the pending five", (tester) async {
      final tokyo = verifiedProfile(ExperienceTheme.urbanModern, country: 'JP', region: 'kanto', city: 'tokyo');
      await pump(
        tester,
        countdownTodayApp(
          catalog: withPostcards,
          data: countdownTodayData(lakesTitle: 'Tokyo', lakesProfile: tokyo),
        ),
      );
      expect(find.byType(CountdownTripHero), findsNothing);
      expect(find.byKey(const ValueKey('countdown-postcard')), findsNothing);
      expect(find.text('Tokyo in 58 days'), findsOneWidget);
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

      await pump(tester, countdownTodayApp(catalog: withPostcards, data: (trips: const [], bookings: const [])));
      expect(find.byType(CountdownTripHero), findsNothing);
      expect(find.text('Where are you off to?'), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
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

    testWidgets('the postcard lifts in, then the tag swings and settles', (tester) async {
      await pump(tester, countdownTodayApp(), settle: false);
      await untilHero(tester);
      await tester.pump(const Duration(milliseconds: 150));
      expect(postcardOpacity(tester), inExclusiveRange(0, 1), reason: 'the postcard is fading in');
      expect(tagOpacity(tester), 0, reason: 'the tag waits for the postcard');

      await tester.pump(const Duration(milliseconds: 400));
      expect(postcardOpacity(tester), 1);
      expect(tagAngle(tester), isNot(closeTo(CountdownLayout.tagAngleDegrees, 0.01)), reason: 'still settling');
      expect(
        tagAngle(tester),
        lessThan(CountdownLayout.tagAngleDegrees + CountdownLayout.tagSettleDegrees + 0.01),
        reason: 'only a few degrees',
      );

      await tester.pumpAndSettle();
      expect(tagAngle(tester), closeTo(CountdownLayout.tagAngleDegrees, 0.01));
      expect(tagOpacity(tester), 1);
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
          expectFactsAndButtonFit(tester, width);
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
        expectFactsAndButtonFit(tester, width);
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

void expectFactsAndButtonFit(WidgetTester tester, double width) {
  final button = tester.getRect(find.byKey(const ValueKey('countdown-view-trip')));
  expect(button.height, greaterThanOrEqualTo(48));
  expect(button.left, greaterThanOrEqualTo(0));
  expect(button.right, lessThanOrEqualTo(width));
  for (final fact in ['4 days', '3 bookings', 'Opens 25 Nov']) {
    final box = tester.getRect(find.text(fact));
    expect(box.left, greaterThanOrEqualTo(0), reason: fact);
    expect(box.right, lessThanOrEqualTo(width), reason: fact);
  }
}

/// Just the hero for the Lake District, on the bundled tag.
Widget heroAlone(ArtCatalog catalog) {
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
            postcard: FileArtImage(pendingPostcard('region_gb_lake_district')),
            onOpen: () {},
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
