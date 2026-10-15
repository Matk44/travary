import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/card_shells.dart';
import 'package:travary/design/cards/card_parts.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';

import 'canonical_today.dart';

/// What the city-card visual tests share: the canonical Today screen at the
/// reference size, drawn on a place pack's own shells (the United States'
/// and the world's cities, `test/visual_qa/*_city_cards_test.dart`).
///
/// With `TRAVARY_VISUAL_QA=1` (run by `tool/visual_qa.sh`) the app's real
/// fonts load and each screen is written to `build/visual_qa/`.
class CityCardsQa {
  CityCardsQa._();

  static const outDir = 'build/visual_qa';
  static const size = Size(813, 1933);
  static const dpr = 813 / 390;
  static final qa = Platform.environment['TRAVARY_VISUAL_QA'] == '1';

  /// Loads the real fonts for the file's tests (when rendering for review).
  static void useFonts() {
    setUpAll(() async {
      TravaryText.useGoogleFonts = false;
      if (qa) await _loadFonts(p.join(outDir, 'fonts'));
    });
    tearDownAll(() {
      TravaryText.serifFamily = null;
      TravaryText.sansFamily = null;
    });
  }

  /// Today for a trip titled [title] with [profile], on [catalog], with its
  /// pictures decoded; the key is on the screen's repaint boundary.
  static Future<GlobalKey> openToday(
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

  /// Writes the screen to `build/visual_qa/[name]` (only when rendering for
  /// review).
  static Future<void> save(WidgetTester tester, GlobalKey boundary, String name) async {
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
  static void expectInZone(
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
}

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
