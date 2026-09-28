import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/data/demo_data.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/cards/featured_ticket_card.dart';
import 'package:travary/design/cards/room_key_card.dart';
import 'package:travary/design/cards/tagged_reservation_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/day_timeline.dart';
import 'package:travary/design/widgets/nav_bar.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/booking_detail_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../support/canonical_today.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);
  final bundled = bundledArtCatalog();

  Future<void> pump(
    WidgetTester tester, {
    ArtCatalog? catalog,
    double width = 390,
    double height = 927,
    TripVisualProfile? profile,
  }) async {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * 3);
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(canonicalTodayApp(catalog: catalog ?? bundled, profile: profile));
    await tester.pumpAndSettle();
  }

  ImageProvider imageIn(WidgetTester tester, Finder card) =>
      tester.widget<Image>(find.descendant(of: card, matching: find.byType(Image)).first).image;

  group('the canonical Today composition', () {
    testWidgets('shows every part of the reference with real text, in order', (tester) async {
      await pump(tester);

      final tops = [
        for (final text in [
          'Good morning',
          'Day 3 of 7 · Orlando',
          'Magic Kingdom',
          "Disney's Polynesian Resort",
          'Be Our Guest Restaurant',
          'Ohana',
          'Lunch',
        ])
          tester.getTopLeft(find.text(text)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(find.text('28° Sunny'), findsOneWidget);
      expect(find.text('NEXT UP'), findsOneWidget);
      expect(find.text('ADMIT TWO'), findsOneWidget);
      expect(find.text('HOTEL'), findsOneWidget);
      expect(find.text('Room 2214'), findsOneWidget);
      expect(find.text('LUNCH'), findsOneWidget);
      expect(find.text('DINNER'), findsOneWidget);
      // No boxed day strip and no section headers in the composition.
      expect(find.text('TODAY'), findsNothing);
      expect(find.text('STILL TO COME'), findsNothing);
      expect(find.byType(DayTimeline), findsOneWidget);
    });

    testWidgets('cards draw the supplied raster shells, icons and vignettes', (tester) async {
      await pump(tester);

      expect(
        imageIn(tester, find.byType(FeaturedTicketCard)),
        const AssetImage('assets/art/common/featured_ticket.png'),
      );
      expect(imageIn(tester, find.byType(RoomKeyCard)), const AssetImage('assets/art/common/room_card.png'));
      final lunch = find.byType(TaggedReservationCard).first;
      expect(imageIn(tester, lunch), const AssetImage('assets/art/common/reservation_card_blank.png'));
      final vignette = tester.widget<Image>(
        find.descendant(of: lunch, matching: find.byKey(const ValueKey('card-vignette'))),
      );
      expect(vignette.image, const AssetImage('assets/art/dining/any_bistro_01_vignette.png'));
      expect(find.descendant(of: lunch, matching: find.byKey(const ValueKey('icon-raster-dining'))), findsOneWidget);
      // Nav icons: raster where supplied, the documented stand-in otherwise.
      expect(find.byKey(const ValueKey('icon-raster-nav_today')), findsOneWidget);
      expect(find.byKey(const ValueKey('icon-raster-nav_trips')), findsOneWidget);
      expect(find.byKey(const ValueKey('icon-fallback-nav_wallet')), findsOneWidget);
      expect(find.byKey(const ValueKey('icon-fallback-nav_profile')), findsOneWidget);
      // No drawn stand-ins where rasters exist.
      expect(find.byKey(const ValueKey('plain-card')), findsNothing);
      expect(
        find.byKey(const ValueKey('stamp-fallback')),
        findsNothing,
        reason: 'the ticket prints its own stamp frame',
      );
    });

    testWidgets('a missing picture only affects its own element', (tester) async {
      // The dining icon and the room card are missing; everything else is there.
      final partial = ArtCatalog.fromAssetPaths([
        for (final path in bundledArtPaths())
          if (!path.endsWith('icons/dining.png') && !path.endsWith('common/room_card.png')) path,
      ]);
      await pump(tester, catalog: partial);

      final lunch = find.byType(TaggedReservationCard).first;
      expect(find.descendant(of: lunch, matching: find.byKey(const ValueKey('icon-fallback-dining'))), findsOneWidget);
      expect(
        imageIn(tester, find.byType(FeaturedTicketCard)),
        const AssetImage('assets/art/common/featured_ticket.png'),
      );
      expect(find.byKey(const ValueKey('icon-raster-nav_today')), findsOneWidget);
      // The theme-park key card is gone: just that stay drops to a plain row.
      expect(find.byType(RoomKeyCard), findsNothing);
      expect(find.text("Disney's Polynesian Resort"), findsOneWidget);
      expect(find.text('Room 2214 · Check-out in 4 days'), findsOneWidget);
      expect(find.byType(TaggedReservationCard), findsNWidgets(2));
    });

    testWidgets('a shell file that cannot load shows a plain panel under the same text', (tester) async {
      final broken = bundled.withPacks([
        ArtPackContent(
          pack: const ArtPackRef(
            id: 'theme_themepark',
            version: 1,
            priority: 1,
            selectors: ArtPackSelectors(themes: [ExperienceTheme.themepark]),
          ),
          assets: const [],
          common: const {'featured_ticket': FileArtImage('/nowhere/featured_ticket.png')},
          sizes: const {'common/featured_ticket': (width: 1774, height: 887)},
        ),
      ]);
      await pump(tester, catalog: broken);
      // Let the real file read fail.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(FeaturedTicketCard), matching: find.byKey(const ValueKey('shell-fallback'))),
        findsOneWidget,
      );
      expect(find.text('Magic Kingdom'), findsOneWidget);
      expect(imageIn(tester, find.byType(RoomKeyCard)), const AssetImage('assets/art/common/room_card.png'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('with no shells at all the day still reads, on plain panels', (tester) async {
      await pump(tester, catalog: const ArtCatalog.empty());
      expect(find.byKey(const ValueKey('plain-card')), findsNWidgets(3));
      expect(find.text('Magic Kingdom'), findsOneWidget);
      expect(find.text('Room 2214 · Check-out in 4 days'), findsOneWidget);
      expect(find.byKey(const ValueKey('tab-fallback')), findsNWidgets(5), reason: 'four tabs and the add tab');
    });
  });

  group('taps', () {
    testWidgets('the card opens the booking; Show tickets opens the tickets', (tester) async {
      await pump(tester);
      await tester.tap(find.byType(RoomKeyCard));
      await tester.pumpAndSettle();
      expect(find.byType(BookingDetailScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      final button = find.bySemanticsLabel('Show tickets');
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48), reason: 'a full-size tap target');
      await tester.tap(button);
      await tester.pumpAndSettle();
      // No ticket file: the booking with its reference.
      expect(find.text('MK-448120'), findsWidgets);
    });

    testWidgets('the day line opens a chooser; a swipe moves a day', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Day 3 of 7 · Orlando'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Wednesday 14 October'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Friday 16 October'));
      await tester.pumpAndSettle();
      expect(find.text('Fri 16 Oct · Day 5 of 7 · Orlando'), findsOneWidget);
      expect(find.text('Magic Kingdom'), findsNothing);

      await tester.fling(find.byType(CustomScrollView).first, const Offset(300, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('Thu 15 Oct · Day 4 of 7 · Orlando'), findsOneWidget);
    });
  });

  group('home tabs', () {
    Finder tab(String label) => find.descendant(of: find.byType(TravaryNavBar), matching: find.bySemanticsLabel(label));

    testWidgets('five parts with selected semantics and 48-point targets', (tester) async {
      await pump(tester);
      final handle = tester.ensureSemantics();
      for (final label in ['Today', 'Trips', 'Documents', 'Profile', 'Add a booking']) {
        final tab = find.descendant(of: find.byType(TravaryNavBar), matching: find.bySemanticsLabel(label));
        expect(tab, findsOneWidget, reason: label);
        final size = tester.getSize(tab);
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
      expect(tester.getSemantics(tab('Today')), containsSemantics(isSelected: true, isButton: true));
      expect(tester.getSemantics(tab('Trips')), containsSemantics(isSelected: false, isButton: true));

      await tester.tap(tab('Trips'));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(tab('Trips')), containsSemantics(isSelected: true));
      expect(tester.getSemantics(tab('Today')), containsSemantics(isSelected: false));
      handle.dispose();
    });

    Finder label(String text) => find.descendant(of: find.byType(TravaryNavBar), matching: find.text(text));

    double rise(WidgetTester tester, String text) {
      final transform = tester.widget<Transform>(
        find.ancestor(of: label(text), matching: find.byType(Transform)).first,
      );
      return transform.transform.getTranslation().y;
    }

    testWidgets('the chosen tab pops up with a spring; the others settle', (tester) async {
      await pump(tester);
      expect(rise(tester, 'Today'), 0);
      expect(rise(tester, 'Trips'), NavLayout.rise);

      await tester.tap(find.descendant(of: find.byType(TravaryNavBar), matching: find.bySemanticsLabel('Trips')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final early = rise(tester, 'Trips');
      expect(early, inExclusiveRange(0, NavLayout.rise), reason: 'on its way up');
      await tester.pump(const Duration(milliseconds: 220));
      expect(rise(tester, 'Trips'), lessThan(0), reason: 'ease-out-back overshoots, like a spring');
      await tester.pumpAndSettle();
      expect(rise(tester, 'Trips'), 0);
      expect(rise(tester, 'Today'), NavLayout.rise);
    });

    testWidgets('with reduced motion the change is immediate', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pump(tester);

      await tester.tap(find.descendant(of: find.byType(TravaryNavBar), matching: find.bySemanticsLabel('Trips')));
      await tester.pump();
      await tester.pump();
      expect(rise(tester, 'Trips'), 0);
      expect(rise(tester, 'Today'), NavLayout.rise);
    });
  });

  testWidgets('the trip palette colours the chrome, never the artwork', (tester) async {
    const palette = DestinationPalette(
      id: 'orlando_citrus',
      ink: 0xFF1C2A47,
      paper: 0xFFF8F4EC,
      accents: [0xFF2D6A4F, 0xFFF4A259],
      primary: 0xFF2D6A4F,
      secondary: 0xFF3A506B,
      highlight: 0xFFD1603D,
      onPrimary: 0xFFFFFFFF,
    );
    final catalog = bundled.withPacks([
      ArtPackContent(
        pack: const ArtPackRef(
          id: 'country_us',
          version: 1,
          priority: 500,
          selectors: ArtPackSelectors(countryCodes: ['US']),
        ),
        assets: const [],
        palette: palette,
      ),
    ]);
    const profile = TripVisualProfile(
      primaryTheme: ExperienceTheme.themepark,
      confidence: 0.9,
      sourceHash: 'hash',
      location: TripLocationHint(countryCode: 'US', confidence: 0.9, verification: LocationVerification.verified),
    );
    await pump(tester, catalog: catalog, profile: profile);

    final selectedTab = tester.widget<DecoratedBox>(find.byKey(const ValueKey('tab-fallback')).first);
    expect((selectedTab.decoration as BoxDecoration).color, const Color(0xFF2D6A4F));
    final line = tester.widget<ColoredBox>(
      find.descendant(of: find.byType(DayTimeline), matching: find.byType(ColoredBox)).first,
    );
    expect(line.color, const Color(0xFF3A506B));
    expect(tester.widget<Text>(find.text('LUNCH')).style?.color, const Color(0xFFD1603D));
    // Full-colour art keeps its own colours.
    final ticketImage = tester.widget<Image>(
      find.descendant(of: find.byType(FeaturedTicketCard), matching: find.byType(Image)).first,
    );
    expect(ticketImage.color, isNull);
  });

  testWidgets('the demo trip, all kinds of card, at 320 points and large text: no overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = MemoryTravelRepository();
    final demo = buildDemoData(LocalDate(2026, 10, 14), userId: repository.userId);
    repository.replaceAll(demo.trips, demo.bookings);
    final now = DateTime(2026, 10, 14, 14, 30);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(repository: repository, artCatalog: bundled, clock: () => now),
          ),
          ChangeNotifierProvider(
            create: (_) => PremiumStore(
              purchases: TestPurchaseService(clock: () => now),
              clock: () => now,
            ),
          ),
        ],
        child: MaterialApp(theme: buildTravaryTheme(), home: const HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Car hire'), findsOneWidget, reason: 'a hire car in progress');
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Show'), 200, scrollable: list);
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    // Every other day of the trip too.
    for (var day = 0; day < 7; day++) {
      await tester.fling(find.byType(CustomScrollView).first, const Offset(-300, 0), 1200);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  group('small, large and enlarged', () {
    for (final width in [320.0, 390.0, 430.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('${width.toInt()} points wide at text scale $scale: no overflow', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pump(tester, width: width, height: 700);
          expect(tester.takeException(), isNull);
          expect(find.text('Magic Kingdom'), findsOneWidget);
          // Scroll to the end of the day: nothing overflows there either.
          await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(DayTimeline), findsOneWidget);
        });
      }
    }
  });
}
