import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/card_shells.dart';
import 'package:travary/design/cards/card_parts.dart';
import 'package:travary/design/cards/featured_ticket_card.dart';
import 'package:travary/design/cards/room_key_card.dart';
import 'package:travary/design/cards/tagged_reservation_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';
import 'package:travary/state/travel_store.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';
import '../support/documents_stamps.dart';

/// Today on the United States city and region shells: for each of the 14
/// places, the canonical Today screen (a featured ticket, a key card and two
/// tagged reservation cards) for a trip in that place, with the place's pack
/// installed beside the country's, as it would be on a phone.
///
/// Always checks that the app picks the place's shells for all three cards,
/// that each card on screen is drawn on them, and that its live text sits
/// inside the shell's text zone. With `TRAVARY_VISUAL_QA=1` (run by
/// `tool/visual_qa.sh`) it loads the app's real fonts and writes
/// `build/visual_qa/us_cards_<place>.png` at the reference size.
void main() {
  const outDir = 'build/visual_qa';
  final qa = Platform.environment['TRAVARY_VISUAL_QA'] == '1';
  const size = Size(813, 1933);
  const dpr = 813 / 390;

  setUpAll(() async {
    TravaryText.useGoogleFonts = false;
    if (qa) await _loadFonts(p.join(outDir, 'fonts'));
  });
  tearDownAll(() {
    TravaryText.serifFamily = null;
    TravaryText.sansFamily = null;
  });

  Future<GlobalKey> openToday(
    WidgetTester tester, {
    required ArtCatalog catalog,
    required String title,
    required TripVisualProfile profile,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = dpr;
    tester.view.padding = const FakeViewPadding(bottom: 34 * dpr);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * dpr);
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();
    Future<void> open() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: canonicalTodayApp(catalog: catalog, title: title, profile: profile),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Pack files never finish loading under the test clock: build once to
    // learn what the screen draws, decode it for real, then build again.
    await open();
    await _decodePictures(tester);
    await open();
    await _decodePictures(tester);
    await open();
    return boundary;
  }

  Future<void> save(WidgetTester tester, GlobalKey boundary, String name) async {
    if (!qa) return;
    await tester.runAsync(() async {
      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: dpr);
      await Directory(outDir).create(recursive: true);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(p.join(outDir, name)).writeAsBytes(png!.buffer.asUint8List());
    });
  }

  /// The text [text] finds sits inside [zone] of the shell drawn on [card].
  /// Zones are fractions of the whole picture; the card shows its `body`
  /// (`ShellFrame` maps them the same way).
  void expectInZone(
    WidgetTester tester,
    Finder card,
    Finder text,
    ShellGeometry geometry,
    FractionRect zone,
    String reason,
  ) {
    final cardRect = tester.getRect(card);
    final textRect = tester.getRect(text);
    final body = geometry.body;
    final imageWidth = cardRect.width / body.width;
    final imageHeight = cardRect.height / body.height;
    final allowed = Rect.fromLTWH(
      cardRect.left + (zone.left - body.left) * imageWidth,
      cardRect.top + (zone.top - body.top) * imageHeight,
      zone.width * imageWidth,
      zone.height * imageHeight,
    ).inflate(1);
    expect(
      allowed.contains(textRect.topLeft) && allowed.contains(textRect.bottomRight),
      isTrue,
      reason: '$reason: $textRect not in $allowed',
    );
  }

  for (final place in _places) {
    testWidgets('${place.name}: Today is drawn on ${place.packId}\'s shells', (tester) async {
      final catalog = bundledArtCatalog().withPacks([sourcePack('country_us'), sourcePack(place.packId)]);
      final boundary = await openToday(
        tester,
        catalog: catalog,
        title: place.name,
        profile: verifiedProfile(place.theme, country: 'US', region: place.region, city: place.city),
      );
      await save(tester, boundary, 'us_cards_${place.file}.png');

      // The pack outranks the country's, and the app resolves to its shells.
      final store = tester.element(find.byType(HomeShell)).read<TravelStore>();
      final context = store.artContextForPlan(store.focus.plan!);
      expect(context.packRanks[place.packId], place.rank);
      expect(context.packRanks['country_us'], ArtRank.country);
      final shells = ShellResolver(catalog).resolve(context);
      for (final (role, shell) in [
        ('featured ticket', shells.featured),
        ('key card', shells.room),
        ('reservation card', shells.reservation),
      ]) {
        expect(shell?.art.pack?.id, place.packId, reason: role);
      }
      expect(shells.reservation!.role, ShellRole.reservationCard, reason: 'a complete tagged card, nothing layered on');
      expect(shells.reservation!.geometry.vignette, isNull);

      // Every card on screen is drawn on them.
      final ticket = find.byType(FeaturedTicketCard);
      final key = find.byType(RoomKeyCard);
      final tagged = find.byType(TaggedReservationCard);
      expect(ticket, findsOneWidget);
      expect(key, findsOneWidget);
      expect(tagged, findsNWidgets(2));
      expect(tester.widget<FeaturedTicketCard>(ticket).shell.art.pack?.id, place.packId);
      expect(tester.widget<RoomKeyCard>(key).shell.art.pack?.id, place.packId);
      for (final card in tagged.evaluate()) {
        expect((card.widget as TaggedReservationCard).shell.art.pack?.id, place.packId);
      }
      expect(find.text(place.name.toUpperCase()), findsNothing, reason: 'the shells print no place name');

      // The live text is inside each shell's text zone.
      expectInZone(
        tester,
        ticket,
        find.descendant(of: ticket, matching: find.text('Magic Kingdom')),
        shells.featured!.geometry,
        shells.featured!.geometry.text,
        'ticket title',
      );
      expectInZone(
        tester,
        key,
        find.descendant(of: key, matching: find.text("Disney's Polynesian Resort")),
        shells.room!.geometry,
        shells.room!.geometry.text,
        'key card title',
      );
      expectInZone(
        tester,
        tagged.first,
        find.descendant(of: tagged.first, matching: find.text('Be Our Guest Restaurant')),
        shells.reservation!.geometry,
        shells.reservation!.geometry.text,
        'reservation title',
      );
      expect(tester.takeException(), isNull);
    });
  }

  group('a city\'s pack outranks its region\'s on screen', () {
    Future<void> expectShellsFrom(WidgetTester tester, String packId, {required String? city}) async {
      final catalog = bundledArtCatalog().withPacks([
        sourcePack('country_us'),
        sourcePack('region_us_florida'),
        sourcePack('city_us_orlando'),
      ]);
      await openToday(
        tester,
        catalog: catalog,
        title: city ?? 'Florida',
        profile: verifiedProfile(ExperienceTheme.themepark, country: 'US', region: 'florida', city: city),
      );
      expect(tester.widget<FeaturedTicketCard>(find.byType(FeaturedTicketCard)).shell.art.pack?.id, packId);
      expect(tester.widget<RoomKeyCard>(find.byType(RoomKeyCard)).shell.art.pack?.id, packId);
      for (final card in find.byType(TaggedReservationCard).evaluate()) {
        expect((card.widget as TaggedReservationCard).shell.art.pack?.id, packId);
      }
      expect(tester.takeException(), isNull);
    }

    testWidgets('Orlando on Orlando\'s, with Florida\'s and the country\'s installed too', (tester) async {
      await expectShellsFrom(tester, 'city_us_orlando', city: 'orlando');
    });

    testWidgets('Miami (Florida, no city pack of its own) on Florida\'s', (tester) async {
      await expectShellsFrom(tester, 'region_us_florida', city: 'miami');
    });

    testWidgets('Florida as a whole on Florida\'s', (tester) async {
      await expectShellsFrom(tester, 'region_us_florida', city: null);
    });
  });

  testWidgets('a US place with no pack of its own stays on the country\'s cards', (tester) async {
    final catalog = bundledArtCatalog().withPacks([
      sourcePack('country_us'),
      sourcePack('city_us_orlando'),
      sourcePack('region_us_california'),
    ]);
    final boundary = await openToday(
      tester,
      catalog: catalog,
      title: 'Austin',
      profile: verifiedProfile(ExperienceTheme.urbanModern, country: 'US', region: 'texas', city: 'austin'),
    );
    await save(tester, boundary, 'us_cards_country_us.png');
    expect(tester.widget<FeaturedTicketCard>(find.byType(FeaturedTicketCard)).shell.art.pack?.id, 'country_us');
    expect(tester.widget<RoomKeyCard>(find.byType(RoomKeyCard)).shell.art.pack?.id, 'country_us');
    for (final card in find.byType(TaggedReservationCard).evaluate()) {
      expect((card.widget as TaggedReservationCard).shell.art.pack?.id, 'country_us');
    }
    expect(tester.takeException(), isNull);
  });
}

class _Place {
  const _Place(this.name, this.file, this.packId, {this.region, this.city, this.theme = ExperienceTheme.urbanHeritage});

  final String name;
  final String file;
  final String packId;
  final String? region;
  final String? city;
  final ExperienceTheme theme;

  ArtRank get rank => city != null ? ArtRank.city : ArtRank.region;
}

const _places = [
  _Place('Orlando', 'orlando', 'city_us_orlando', region: 'florida', city: 'orlando', theme: ExperienceTheme.themepark),
  _Place('New York', 'new_york', 'city_us_new_york', region: 'new_york', city: 'new_york'),
  _Place('Las Vegas', 'las_vegas', 'city_us_las_vegas', region: 'nevada', city: 'las_vegas'),
  _Place('Washington DC', 'washington_dc', 'city_us_washington_dc', city: 'washington_dc'),
  _Place('Chicago', 'chicago', 'city_us_chicago', region: 'illinois', city: 'chicago'),
  _Place('Boston', 'boston', 'city_us_boston', region: 'massachusetts', city: 'boston'),
  _Place('New Orleans', 'new_orleans', 'city_us_new_orleans', region: 'louisiana', city: 'new_orleans'),
  _Place('Nashville', 'nashville', 'city_us_nashville', region: 'tennessee', city: 'nashville'),
  _Place('Seattle', 'seattle', 'city_us_seattle', region: 'washington', city: 'seattle'),
  _Place('Florida', 'florida', 'region_us_florida', region: 'florida', theme: ExperienceTheme.coastalResort),
  _Place(
    'California',
    'california',
    'region_us_california',
    region: 'california',
    theme: ExperienceTheme.coastalResort,
  ),
  _Place('Hawaii', 'hawaii', 'region_us_hawaii', region: 'hawaii', theme: ExperienceTheme.coastalResort),
  _Place('Arizona', 'arizona', 'region_us_arizona', region: 'arizona', theme: ExperienceTheme.countryside),
  _Place('Alaska', 'alaska', 'region_us_alaska', region: 'alaska', theme: ExperienceTheme.alpine),
];

Future<void> _loadFonts(String dir) async {
  final folder = Directory(dir);
  if (!folder.existsSync()) {
    // ignore: avoid_print
    print('No fonts in $dir: run tool/visual_qa.sh. Rendering with the test font.');
    return;
  }
  final files = folder.listSync().whereType<File>().toList();
  Future<void> load(String family, bool Function(String) matches) async {
    final loader = FontLoader(family);
    var any = false;
    for (final file in files.where((f) => matches(p.basename(f.path)))) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      any = true;
    }
    if (any) await loader.load();
  }

  await load('Source Serif 4', (name) => name.startsWith('SourceSerif4'));
  await load('Inter', (name) => name.startsWith('Inter'));
  await load('MaterialIcons', (name) => name.startsWith('MaterialIcons'));
  TravaryText.serifFamily = 'Source Serif 4';
  TravaryText.sansFamily = 'Inter';
}

/// Decodes every picture on screen for real (pack files never finish
/// loading under the test clock), so the next build finds them in the image
/// cache. A picture that doesn't decode within 20 seconds fails the test.
Future<void> _decodePictures(WidgetTester tester) async {
  final wanted = <(ImageProvider, ImageConfiguration)>[
    for (final element in find.byType(Image, skipOffstage: false).evaluate())
      ((element.widget as Image).image, createLocalImageConfiguration(element)),
    for (final element in find.byType(TrimmedArt, skipOffstage: false).evaluate())
      (artImageProvider((element.widget as TrimmedArt).image), createLocalImageConfiguration(element)),
  ];
  imageCache
    ..clear()
    ..clearLiveImages();
  final stuck = <ImageProvider>[];
  await tester.runAsync(() async {
    for (final (provider, configuration) in wanted) {
      final done = Completer<bool>();
      final stream = provider.resolve(configuration);
      final listener = ImageStreamListener(
        (image, synchronousCall) => done.isCompleted ? null : done.complete(true),
        onError: (error, stackTrace) => done.isCompleted ? null : done.complete(false),
      );
      stream.addListener(listener);
      final decoded = await done.future.timeout(const Duration(seconds: 20), onTimeout: () => false);
      stream.removeListener(listener);
      if (!decoded) stuck.add(provider);
    }
    // Trimmed art measures its visible part once decoded.
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });
  expect(stuck, isEmpty, reason: 'pictures that did not decode');
}
