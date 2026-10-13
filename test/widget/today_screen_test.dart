import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/data/demo_data.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/cards/card_parts.dart';
import 'package:travary/design/cards/featured_ticket_card.dart';
import 'package:travary/design/cards/ongoing_tag_card.dart';
import 'package:travary/design/cards/room_key_card.dart';
import 'package:travary/design/cards/shell_frame.dart';
import 'package:travary/design/cards/tagged_reservation_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/nav_bar.dart';
import 'package:travary/design/widgets/time_rail.dart';
import 'package:travary/design/widgets/today_header.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/booking_detail_screen.dart';
import 'package:travary/features/today/today_screen.dart';
import 'package:travary/features/trips/trip_details_sheet.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../support/canonical_today.dart';
import '../support/travel_documents.dart';
import '../support/session.dart';

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
      expect(find.byType(TimeRailRow), findsNWidgets(4));
    });

    testWidgets("the time rail: each stop's time beside its card, in time order, joined by one line", (tester) async {
      await pump(tester);
      Rect card(String title) =>
          tester.getRect(find.ancestor(of: find.text(title), matching: find.byType(ShellFrame)).first);
      Finder onRail(String text) => find.descendant(of: find.byType(TimeRailRow), matching: find.text(text));

      // 9:00am next up, the hotel with no time, 12:30pm lunch, 7:15pm dinner.
      final stops = [('9:00', 'Magic Kingdom'), ('12:30', 'Be Our Guest Restaurant'), ('7:15', 'Ohana')];
      final times = <Rect>[];
      for (final (time, title) in stops) {
        expect(onRail(time), findsOneWidget, reason: time);
        final rect = tester.getRect(onRail(time));
        final beside = card(title);
        expect(rect.right, lessThan(beside.left), reason: '$time sits left of its card');
        expect(
          rect.top,
          inInclusiveRange(beside.top + 8, beside.top + 24),
          reason: '$time is level with the top of its card',
        );
        times.add(rect);
      }
      expect(onRail('am'), findsOneWidget);
      expect(onRail('pm'), findsNWidgets(2));
      expect(times.map((r) => r.top), orderedEquals([...times.map((r) => r.top)]..sort()));
      expect(find.byKey(const ValueKey('rail-dot')), findsNWidgets(3), reason: 'nothing is happening yet at 8am');

      // One line down the middle of the rail: from the first stop's dot to
      // just above the last stop's time, passing behind the hotel.
      final lines = [
        for (final element in find.byKey(const ValueKey('rail-line')).evaluate())
          tester.getRect(find.byWidget(element.widget)),
      ]..sort((a, b) => a.top.compareTo(b.top));
      expect(lines.map((r) => r.center.dx).toSet(), hasLength(1));
      expect(lines.first.center.dx, closeTo(times.first.center.dx, 0.5));
      expect(lines.first.top, greaterThan(times.first.bottom), reason: 'no line above the first stop');
      expect(lines.last.bottom, lessThan(times.last.top), reason: 'none below the last stop');
      final hotel = card("Disney's Polynesian Resort");
      expect(lines.any((line) => line.top <= hotel.top && line.bottom >= hotel.bottom), isTrue);
      for (final title in ['Magic Kingdom', "Disney's Polynesian Resort", 'Be Our Guest Restaurant', 'Ohana']) {
        expect(card(title).left, greaterThan(lines.first.right + 20), reason: '$title is clear of the rail');
      }
    });

    testWidgets('the featured card keeps its place in time; what is happening now is marked', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 927 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      // 12:45: the park (from 9:00) is still on and lunch (12:30) is featured.
      await tester.pumpWidget(canonicalTodayApp(catalog: bundled, now: DateTime(2026, 10, 14, 12, 45)));
      await tester.pumpAndSettle();

      expect(find.text('HAPPENING NOW'), findsOneWidget);
      final lunchTop = tester.getTopLeft(find.text('Be Our Guest Restaurant')).dy;
      expect(tester.getTopLeft(find.text('Magic Kingdom')).dy, lessThan(lunchTop));
      expect(tester.getTopLeft(find.text("Disney's Polynesian Resort")).dy, greaterThan(lunchTop));
      expect(find.byType(FeaturedTicketCard), findsOneWidget);
      expect(
        find.ancestor(of: find.text('Be Our Guest Restaurant'), matching: find.byType(FeaturedTicketCard)),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('rail-dot-now')), findsNWidgets(2), reason: 'the park and lunch are both on');
      expect(find.byKey(const ValueKey('rail-dot')), findsOneWidget, reason: 'dinner is still to come');
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
      final vignette = tester.widget<TrimmedArt>(
        find.descendant(of: lunch, matching: find.byKey(const ValueKey('card-vignette'))),
      );
      // Lunch is at Castle Square: the theme park's castle dining picture.
      expect(vignette.image, const BundledArtImage('assets/art/dining/themepark_castle_01_vignette.png'));
      expect(find.descendant(of: lunch, matching: find.byKey(const ValueKey('icon-raster-dining'))), findsOneWidget);
      // Nav icons: every tab's raster is supplied.
      for (final key in ['nav_today', 'nav_trips', 'nav_wallet', 'nav_profile']) {
        expect(find.byKey(ValueKey('icon-raster-$key')), findsOneWidget, reason: key);
        expect(find.byKey(ValueKey('icon-fallback-$key')), findsNothing, reason: key);
      }
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
      // The theme-park key card is gone: just that stay moves to the key tag.
      expect(find.byType(RoomKeyCard), findsNothing);
      final tag = find.byType(OngoingTagCard);
      expect(find.descendant(of: tag, matching: find.text("Disney's Polynesian Resort")), findsOneWidget);
      expect(find.descendant(of: tag, matching: find.textContaining('Room 2214', findRichText: true)), findsOneWidget);
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

    testWidgets('the day line opens the trip calendar; a swipe moves a day', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Day 3 of 7 · Orlando'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Day 3 of 7, Wednesday 14 October, today'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Day 5 of 7, Friday 16 October'));
      await tester.pumpAndSettle();
      expect(find.text('Fri 16 Oct · Day 5 of 7 · Orlando'), findsOneWidget);
      expect(find.text('Magic Kingdom'), findsNothing);

      await tester.fling(find.byType(CustomScrollView).first, const Offset(300, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('Thu 15 Oct · Day 4 of 7 · Orlando'), findsOneWidget);
    });

    testWidgets('the date pill opens the same calendar, then shows the day on screen', (tester) async {
      await pump(tester);
      final handle = tester.ensureSemantics();
      final pill = find.ancestor(of: find.byType(HeaderPill), matching: find.byType(InkWell)).first;
      expect(tester.getSize(pill).height, greaterThanOrEqualTo(48), reason: 'a full-size tap target');
      expect(tester.getSemantics(pill), containsSemantics(isButton: true, hint: 'Choose a day', label: '28° Sunny'));

      await tester.tap(pill);
      await tester.pumpAndSettle();
      // Sun 11 to Sat 24 October (en_US weeks start on Sunday): the trip's
      // seven days can be chosen, the rest are faint.
      expect(find.text('12–18 Oct 2026'), findsOneWidget);
      for (var day = 12; day <= 18; day++) {
        expect(find.bySemanticsLabel(RegExp('Day ${day - 11} of 7, .* $day October')), findsOneWidget);
      }
      expect(find.bySemanticsLabel(RegExp('11 October|19 October')), findsNothing);
      expect(find.text('11'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      // Check-in, the park day and check-out have bookings; the days
      // between only have the hotel.
      expect(find.byKey(const ValueKey('calendar-booked')), findsNWidgets(3));
      expect(find.text('Back to today'), findsNothing, reason: 'today is on screen');

      await tester.tap(find.text('11'));
      await tester.pumpAndSettle();
      expect(find.text('12–18 Oct 2026'), findsOneWidget, reason: 'a day outside the trip does nothing');

      await tester.tap(find.bySemanticsLabel('Day 6 of 7, Saturday 17 October'));
      await tester.pumpAndSettle();
      expect(find.text('Sat 17 Oct · Day 6 of 7 · Orlando'), findsOneWidget);
      expect(find.text('Sat 17 Oct'), findsOneWidget, reason: 'the pill shows the day on screen');
      expect(find.text('28° Sunny'), findsNothing, reason: "the forecast is today's");

      await tester.tap(find.byType(HeaderPill));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Day 6 of 7, Saturday 17 October')),
        containsSemantics(isSelected: true),
      );
      await tester.tap(find.text('Back to today'));
      await tester.pumpAndSettle();
      expect(find.text('Day 3 of 7 · Orlando'), findsOneWidget);
      expect(find.text('28° Sunny'), findsOneWidget);
      expect(find.text('Magic Kingdom'), findsOneWidget);
      handle.dispose();
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

    testWidgets('tabs are the supplied rasters, and choosing one crossfades cream into teal', (tester) async {
      await pump(tester);
      final nav = find.byType(TravaryNavBar);
      Finder inTab(String label, String key) => find.descendant(
        of: find
            .ancestor(
              of: label == '+'
                  ? find.bySemanticsLabel('Add a booking')
                  : find.descendant(of: nav, matching: find.text(label)),
              matching: find.byType(Stack),
            )
            .first,
        matching: find.byKey(ValueKey(key)),
      );
      final images = [
        for (final element in find.descendant(of: nav, matching: find.byType(Image)).evaluate())
          ((element.widget as Image).image as AssetImage).assetName,
      ];
      expect(
        images,
        containsAll([
          'assets/art/common/tab.png',
          'assets/art/common/tab_selected.png',
          'assets/art/common/tab_add.png',
        ]),
      );
      expect(find.descendant(of: nav, matching: find.byKey(const ValueKey('tab-fallback'))), findsNothing);
      expect(inTab('Today', 'tab-selected-raster'), findsOneWidget);

      await tester.tap(find.descendant(of: nav, matching: find.bySemanticsLabel('Trips')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      // Mid-pop: both fabrics are there, fading across.
      expect(inTab('Trips', 'tab-raster'), findsOneWidget);
      expect(inTab('Trips', 'tab-selected-raster'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(inTab('Trips', 'tab-raster'), findsNothing);
      expect(inTab('Today', 'tab-selected-raster'), findsNothing);
      expect(
        find.descendant(of: nav, matching: find.byType(ColorFiltered)),
        findsNothing,
        reason: 'never tinted',
      );
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
    const usPack = ArtPackContent(
      pack: ArtPackRef(
        id: 'country_us',
        version: 1,
        priority: 500,
        selectors: ArtPackSelectors(countryCodes: ['US']),
      ),
      assets: [],
      palette: palette,
    );
    final catalog = bundled.withPacks([usPack]);
    const profile = TripVisualProfile(
      primaryTheme: ExperienceTheme.themepark,
      confidence: 0.9,
      sourceHash: 'hash',
      location: TripLocationHint(countryCode: 'US', confidence: 0.9, verification: LocationVerification.verified),
    );
    await pump(tester, catalog: catalog, profile: profile);

    // The selected tab is its finished teal raster, never recoloured; the
    // palette reaches its icon and label ink instead.
    final nav = find.byType(TravaryNavBar);
    expect(find.descendant(of: nav, matching: find.byKey(const ValueKey('tab-selected-raster'))), findsOneWidget);
    expect(find.descendant(of: nav, matching: find.byType(ColorFiltered)), findsNothing);
    expect(
      tester.widget<Image>(find.descendant(of: nav, matching: find.byKey(const ValueKey('tab-selected-raster')))).color,
      isNull,
    );
    expect(
      tester.widget<Text>(find.descendant(of: nav, matching: find.text('Today'))).style?.color,
      const Color(0xFFFFFFFF),
    );
    // The rail is in the palette's ink, never its (often red) secondary.
    final line = tester.widget<ColoredBox>(find.byKey(const ValueKey('rail-line')).first);
    expect(line.color, const Color(0xFF1C2A47));
    final dot = tester.widget<Container>(find.byKey(const ValueKey('rail-dot')).first);
    expect((dot.decoration! as BoxDecoration).color, const Color(0xFF1C2A47));
    expect(tester.widget<Text>(find.text('LUNCH')).style?.color, const Color(0xFFD1603D));
    // Full-colour art keeps its own colours.
    final ticketImage = tester.widget<Image>(
      find.descendant(of: find.byType(FeaturedTicketCard), matching: find.byType(Image)).first,
    );
    expect(ticketImage.color, isNull);
  });

  testWidgets('without tab files the flat stand-in tab takes the palette colour', (tester) async {
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
    final noTabs =
        ArtCatalog.fromAssetPaths([
          for (final path in bundledArtPaths())
            if (!path.contains('/common/tab')) path,
        ]).withPacks([
          const ArtPackContent(
            pack: ArtPackRef(
              id: 'country_us',
              version: 1,
              priority: 500,
              selectors: ArtPackSelectors(countryCodes: ['US']),
            ),
            assets: [],
            palette: palette,
          ),
        ]);
    const profile = TripVisualProfile(
      primaryTheme: ExperienceTheme.themepark,
      confidence: 0.9,
      sourceHash: 'hash',
      location: TripLocationHint(countryCode: 'US', confidence: 0.9, verification: LocationVerification.verified),
    );
    await pump(tester, catalog: noTabs, profile: profile);

    final selectedTab = tester.widget<DecoratedBox>(find.byKey(const ValueKey('tab-fallback')).first);
    expect((selectedTab.decoration as BoxDecoration).color, const Color(0xFF2D6A4F));
  });

  testWidgets('a holiday with no dates yet stays on Today, a booking or its dates away', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = MemoryTravelRepository(userId: 'me')
      ..putTrip(
        Trip(
          id: 'bali',
          title: 'Bali holiday',
          ownerId: 'me',
          memberIds: const ['me'],
          createdAt: DateTime(2026, 10, 6),
          updatedAt: DateTime(2026, 10, 6),
        ),
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(
              repository: repository,
              artCatalog: const ArtCatalog.empty(),
              clock: () => DateTime(2026, 10, 12, 9),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: const Scaffold(body: TodayScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nothing coming up'), findsNothing);
    expect(find.text('Bali holiday · dates to come'), findsOneWidget);
    expect(find.text('Bali holiday'), findsOneWidget);
    expect(find.text('Add a booking'), findsOneWidget);
    await tester.tap(find.text('Set the dates'));
    await tester.pumpAndSettle();
    expect(find.byType(TripDetailsSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a day browsed to is forgotten once the real day moves on', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Booking on(String title, int day) => Booking(
      id: title,
      tripId: 'trip',
      kind: BookingKind.dining,
      title: title,
      startDate: LocalDate(2026, 10, day),
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    );
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [
          Trip(
            id: 'trip',
            title: 'Test holiday',
            plannedStart: const LocalDate(2026, 10, 12),
            plannedEnd: const LocalDate(2026, 10, 16),
            ownerId: 'me',
            memberIds: const ['me'],
            createdAt: DateTime(2026, 10, 1),
            updatedAt: DateTime(2026, 10, 1),
          ),
        ],
        [on('Monday booking', 12), on('Tuesday booking', 13), on('Wednesday booking', 14)],
      );
    final store = TravelStore(
      repository: repository,
      artCatalog: const ArtCatalog.empty(),
      clock: () => DateTime(2026, 10, 12, 8),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: const Scaffold(body: TodayScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.fling(find.byType(CustomScrollView), const Offset(-350, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Tuesday booking'), findsOneWidget);
    // Left open overnight: by Wednesday morning, Today is Wednesday again.
    store.previewNow = DateTime(2026, 10, 14, 8);
    await tester.pumpAndSettle();
    expect(find.text('Wednesday booking'), findsOneWidget);
    expect(find.text('Tuesday booking'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
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
          appSessionProvider(),
          travelDocumentsProvider(),
        ],
        child: MaterialApp(theme: buildTravaryTheme(), home: const HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Car hire'), findsOneWidget, reason: 'a hire car in progress');
    final list = find.descendant(of: find.byType(TodayScreen), matching: find.byType(Scrollable)).first;
    // Built isn't enough: scroll until the button is on screen to tap.
    await tester.scrollUntilVisible(find.text('Show').hitTestable(), 200, scrollable: list);
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('Hide'), findsOneWidget, reason: 'the finished items are showing');
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
          expect(find.byType(TimeRailRow), findsWidgets);
        });
      }
    }
  });
}
