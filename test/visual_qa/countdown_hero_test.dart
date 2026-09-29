import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/countdown_trip_hero.dart';
import 'package:travary/design/widgets/nav_bar.dart';

import '../support/countdown_today.dart';

/// Today between trips, rendered like the canonical Today screen (a
/// 390-point phone at 813 × 1933 pixels) with the pending Lake District
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
    await tester.runAsync(() => _preloadFiles(pendingPostcardPacks().map((pack) => pack.common.values.first.path)));
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
      find.text('4 days'),
      find.text('View trip'),
    ];
    var previous = -1.0;
    for (final finder in order) {
      expect(finder, findsOneWidget);
      final top = tester.getTopLeft(finder).dy;
      expect(top, greaterThan(previous), reason: '$finder should be below the one before');
      previous = top;
    }
    expect(find.text('Mon 28 Sep'), findsOneWidget);
    expect(find.text('3 bookings'), findsOneWidget);
    expect(find.text('Opens 25 Nov'), findsOneWidget);
    expect(find.byType(CountdownTripHero), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on a 390 × 844 phone with a status bar, all of it fits above the tabs', (tester) async {
    const dpr = 3.0;
    tester.view.physicalSize = const Size(390 * dpr, 844 * dpr);
    tester.view.devicePixelRatio = dpr;
    tester.view.padding = const FakeViewPadding(top: 47 * dpr, bottom: 34 * dpr);
    tester.view.viewPadding = const FakeViewPadding(top: 47 * dpr, bottom: 34 * dpr);
    addTearDown(tester.view.reset);

    await tester.runAsync(() => _preloadFiles(pendingPostcardPacks().map((pack) => pack.common.values.first.path)));
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: countdownTodayApp()));
    await tester.pumpAndSettle();
    await _precacheImages(tester);

    final card = tester.getRect(find.byKey(const ValueKey('countdown-postcard')));
    expect(card.height, lessThanOrEqualTo(844 * CountdownLayout.postcardMaxHeight + 0.5));
    if (qa) {
      final actual = await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        return render.toImage(pixelRatio: 813 / 390);
      });
      await tester.runAsync(() async {
        final png = await actual!.toByteData(format: ui.ImageByteFormat.png);
        await File(p.join(outDir, 'countdown_844_actual.png')).writeAsBytes(png!.buffer.asUint8List());
      });
      // Only with the app's real fonts: the test font's wide squares wrap
      // every label.
      final tabs = tester.getRect(find.byType(TravaryNavBar));
      expect(tester.getRect(find.byKey(const ValueKey('countdown-view-trip'))).bottom, lessThan(tabs.top));
    }
    expect(tester.takeException(), isNull);
  });
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
