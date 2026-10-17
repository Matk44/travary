import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:travary/data/countdown_widget_settings.dart';
import 'package:travary/design/art/art_slots.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/countdown_trip_hero.dart';
import 'package:travary/design/widgets/nav_bar.dart';
import 'package:travary/state/countdown_widget_store.dart';

import '../support/countdown_today.dart';
import '../support/home_widget.dart';

/// Today between trips, rendered like the canonical Today screen (a
/// 390-point phone at 813 × 1933 pixels) with the Lake District pack's
/// postcard, for comparison with
/// docs/mockups/today-empty/02-hanging-luggage-tag.png.
///
/// Always checks the hierarchy. With `TRAVARY_VISUAL_QA=1` (run by
/// `tool/visual_qa.sh`) it loads the app's real fonts and writes
/// `build/visual_qa/countdown_actual.png`.
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

  testWidgets('the countdown to the Lake District at the reference size', (tester) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = dpr;
    tester.view.padding = const FakeViewPadding(bottom: 34 * dpr);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * dpr);
    addTearDown(tester.view.reset);

    // Pack pictures are files: decode them for real before the screen asks
    // for them (a load started under the test clock never finishes).
    await tester.runAsync(
      () => _preloadFiles(countdownPostcardSourcePacks().map((pack) => pack.common.values.first.path)),
    );
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: countdownTodayApp()));
    await tester.pumpAndSettle();
    await _precacheImages(tester);

    if (qa) {
      final actual = await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        return render.toImage(pixelRatio: dpr);
      });
      await tester.runAsync(() async {
        await Directory(outDir).create(recursive: true);
        final png = await actual!.toByteData(format: ui.ImageByteFormat.png);
        await File(p.join(outDir, 'countdown_actual.png')).writeAsBytes(png!.buffer.asUint8List());
      });
    }

    final order = [
      find.text('Good morning'),
      find.text('Nothing planned today'),
      find.text('NEXT ADVENTURE'),
      find.text('NEXT TRIP'),
      find.text('58'),
      find.text('DAYS TO GO'),
      find.text('Lake District'),
      find.text('25–28 Nov 2026'),
    ];
    var previous = -1.0;
    for (final finder in order) {
      expect(finder, findsOneWidget);
      final top = tester.getTopLeft(finder).dy;
      expect(top, greaterThan(previous), reason: '$finder should be below the one before');
      previous = top;
    }
    expect(find.text('Mon 28 Sep'), findsOneWidget);
    expect(find.byType(CountdownTripHero), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'on a 390 × 844 phone with a status bar, the postcard spans the width; it and its tag fit above the tabs',
    (tester) async {
      const dpr = 3.0;
      tester.view.physicalSize = const Size(390 * dpr, 844 * dpr);
      tester.view.devicePixelRatio = dpr;
      tester.view.padding = const FakeViewPadding(top: 47 * dpr, bottom: 34 * dpr);
      tester.view.viewPadding = const FakeViewPadding(top: 47 * dpr, bottom: 34 * dpr);
      addTearDown(tester.view.reset);

      await tester.runAsync(
        () => _preloadFiles(countdownPostcardSourcePacks().map((pack) => pack.common.values.first.path)),
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: boundary, child: countdownTodayApp()));
      await tester.pumpAndSettle();
      await _precacheImages(tester);

      final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
      expect(card.width, closeTo(390 - 2 * CountdownLayout.postcardInset, 0.5), reason: 'as wide as the phone allows');
      final tabs = tester.getRect(find.byType(TravaryNavBar)).top;
      expect(card.bottom, lessThan(tabs), reason: 'no scrolling to see it');
      // The tag's card (not its transparent margin), hanging at an angle.
      final raster = tester.renderObject<RenderBox>(find.byKey(const ValueKey('countdown-tag-raster')));
      final body = SurfaceSlot.countdownTag.body!;
      final size = raster.size;
      final tagBottom = [
        for (final x in [body.left, body.right])
          raster.localToGlobal(Offset(x * size.width, body.bottom * size.height)).dy,
      ].reduce(math.max);
      expect(tagBottom, lessThan(tabs), reason: 'the tag hanging below it too');
      if (qa) {
        final actual = await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          return render.toImage(pixelRatio: 813 / 390);
        });
        await tester.runAsync(() async {
          final png = await actual!.toByteData(format: ui.ImageByteFormat.png);
          await File(p.join(outDir, 'countdown_844_actual.png')).writeAsBytes(png!.buffer.asUint8List());
        });
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final (width, height) in [(320.0, 568.0), (390.0, 844.0), (430.0, 932.0)]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('the packing note fits under the postcard beside the tag: $width × $height at ${scale}x text', (
        tester,
      ) async {
        const dpr = 3.0;
        tester.view.physicalSize = Size(width * dpr, height * dpr);
        tester.view.devicePixelRatio = dpr;
        tester.view.padding = const FakeViewPadding(top: 47 * dpr, bottom: 34 * dpr);
        tester.view.viewPadding = const FakeViewPadding(top: 47 * dpr, bottom: 34 * dpr);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.runAsync(
          () => _preloadFiles(countdownPostcardSourcePacks().map((pack) => pack.common.values.first.path)),
        );
        final boundary = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key: boundary, child: countdownTodayApp()));
        await tester.pumpAndSettle();
        await _precacheImages(tester);

        final note = tester.getRect(find.byKey(const ValueKey('countdown-note')));
        final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
        expect(note.left, greaterThanOrEqualTo(card.left), reason: 'under the postcard');
        final raster = tester.renderObject<RenderBox>(find.byKey(const ValueKey('countdown-tag-raster')));
        final body = SurfaceSlot.countdownTag.body!;
        final tagLeft = [
          for (final y in [body.top, body.bottom])
            raster.localToGlobal(Offset(body.left * raster.size.width, y * raster.size.height)).dx,
        ].reduce(math.min);
        expect(note.right, lessThanOrEqualTo(tagLeft), reason: 'clear of the tag');
        // Inside the countdown, so it scrolls into view with it; on a
        // phone tall enough for the countdown, above the tabs.
        final hero = tester.getRect(find.byType(CountdownTripHero));
        expect(note.bottom, lessThanOrEqualTo(hero.bottom), reason: 'inside the countdown');
        if (height >= 844 && scale == 1) {
          expect(note.bottom, lessThan(tester.getRect(find.byType(TravaryNavBar)).top), reason: 'above the tabs');
        }
        expect(find.text('Packing list'), findsOneWidget);

        if (qa) {
          final actual = await tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            return render.toImage(pixelRatio: 2);
          });
          await tester.runAsync(() async {
            final png = await actual!.toByteData(format: ui.ImageByteFormat.png);
            await File(
              p.join(outDir, 'countdown_note_${width.round()}_${scale}x.png'),
            ).writeAsBytes(png!.buffer.asUint8List());
          });
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  // The home screen widget's note sits under the packing list, in the same
  // room beside the tag.
  for (final (width, height) in [(320.0, 568.0), (390.0, 844.0), (430.0, 932.0)]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('the widget note sits under the packing note, clear of the tag: $width × $height at ${scale}x text', (
        tester,
      ) async {
        const dpr = 3.0;
        tester.view.physicalSize = Size(width * dpr, height * dpr);
        tester.view.devicePixelRatio = dpr;
        tester.view.padding = const FakeViewPadding(top: 47 * dpr, bottom: 34 * dpr);
        tester.view.viewPadding = const FakeViewPadding(top: 47 * dpr, bottom: 34 * dpr);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.runAsync(
          () => _preloadFiles(countdownPostcardSourcePacks().map((pack) => pack.common.values.first.path)),
        );
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: countdownTodayApp(
              extraProviders: [
                ChangeNotifierProvider(
                  create: (_) => CountdownWidgetStore(
                    bridge: FakeHomeWidget(androidPhone),
                    settings: MemoryCountdownWidgetSettings(),
                  )..start(),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _precacheImages(tester);

        final packing = tester.getRect(find.byKey(const ValueKey('countdown-note')));
        final widget = tester.getRect(find.byKey(const ValueKey('countdown-widget-note')));
        final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
        expect(widget.left, greaterThanOrEqualTo(card.left), reason: 'under the postcard');
        expect(widget.top, greaterThanOrEqualTo(packing.bottom - 0.5), reason: 'under the packing list, not over it');
        final raster = tester.renderObject<RenderBox>(find.byKey(const ValueKey('countdown-tag-raster')));
        final body = SurfaceSlot.countdownTag.body!;
        final tagLeft = [
          for (final y in [body.top, body.bottom])
            raster.localToGlobal(Offset(body.left * raster.size.width, y * raster.size.height)).dx,
        ].reduce(math.min);
        expect(widget.right, lessThanOrEqualTo(tagLeft), reason: 'clear of the tag');
        // Inside the countdown, so it scrolls into view with it, and the
        // postcard keeps the size the phone gives it.
        final hero = tester.getRect(find.byType(CountdownTripHero));
        expect(widget.bottom, lessThanOrEqualTo(hero.bottom + 0.5), reason: 'inside the countdown');
        if (height >= 844 && scale == 1) {
          final words = tester.getRect(
            find.descendant(
              of: find.byKey(const ValueKey('countdown-widget-note')),
              matching: find.text('Home screen'),
            ),
          );
          expect(words.bottom, lessThan(tester.getRect(find.byType(TravaryNavBar)).top), reason: 'above the tabs');
        }
        expect(find.text('Home screen'), findsOneWidget);
        expect(find.text('Packing list'), findsOneWidget);
        if (qa && width >= 390 && scale == 1) {
          // With the real fonts, the room beside the tag fits both words whole on these phones.
          for (final text in ['Home screen', 'Add this countdown ›']) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(
                of: find.byKey(const ValueKey('countdown-widget-note')),
                matching: find.text(text, findRichText: true),
              ),
            );
            expect(paragraph.didExceedMaxLines, isFalse, reason: '$text is cut off');
          }
        }

        if (qa) {
          final actual = await tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            return render.toImage(pixelRatio: 2);
          });
          await tester.runAsync(() async {
            final png = await actual!.toByteData(format: ui.ImageByteFormat.png);
            await File(
              p.join(outDir, 'countdown_widget_note_${width.round()}_${scale}x.png'),
            ).writeAsBytes(png!.buffer.asUint8List());
          });
        }
        expect(tester.takeException(), isNull);
      });
    }
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

/// Puts the files at [paths] in the image cache, decoded.
Future<void> _preloadFiles(Iterable<String> paths) async {
  for (final path in paths) {
    final done = Completer<void>();
    final stream = FileImage(File(path)).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (image, synchronousCall) => done.isCompleted ? null : done.complete(),
      onError: (error, stackTrace) => done.isCompleted ? null : done.completeError(error, stackTrace),
    );
    stream.addListener(listener);
    await done.future;
    stream.removeListener(listener);
  }
}

/// Decodes every bundled picture on screen, so the render shows real art.
/// (Pack files are preloaded.)
Future<void> _precacheImages(WidgetTester tester) async {
  for (var pass = 0; pass < 2; pass++) {
    final elements = find.byType(Image).evaluate().where((e) => (e.widget as Image).image is! FileImage).toList();
    await tester.runAsync(() async {
      for (final element in elements) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();
  }
}
