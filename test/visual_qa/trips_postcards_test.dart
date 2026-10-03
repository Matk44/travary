import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/upcoming_trip_postcard.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';
import '../support/open_tab.dart';
import '../support/trip_postcards.dart';

/// The Trips tab with three coming trips on their destination postcards,
/// rendered like the canonical Today screen (a 390-point phone at 813 ×
/// 1933 pixels), for comparison with
/// docs/mockups/trips-postcards-v2/02-hanging-tag-postcards.png.
///
/// Always checks the order. With `TRAVARY_VISUAL_QA=1` (run by
/// `tool/visual_qa.sh`) it loads the app's real fonts and writes
/// `build/visual_qa/trips_actual.png`.
void main() {
  const outDir = 'build/visual_qa';
  final qa = Platform.environment['TRAVARY_VISUAL_QA'] == '1';
  const dpr = 813 / 390;

  setUpAll(() async {
    TravaryText.useGoogleFonts = false;
    if (qa) await _loadFonts(p.join(outDir, 'fonts'));
  });
  tearDownAll(() {
    TravaryText.serifFamily = null;
    TravaryText.sansFamily = null;
  });

  testWidgets('three coming trips on their postcards at the reference size', (tester) async {
    tester.view.physicalSize = const Size(813, 1933);
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
          child: countdownTodayApp(
            catalog: bundledArtCatalog().withPacks(tripPostcardSourcePacks()),
            data: upcomingTripsData(activeAndPast: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'Trips');
    }

    await open();
    await _decodePictures(tester);
    await open();

    if (qa) {
      final actual = await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        return render.toImage(pixelRatio: dpr);
      });
      await tester.runAsync(() async {
        await Directory(outDir).create(recursive: true);
        final png = await actual!.toByteData(format: ui.ImageByteFormat.png);
        await File(p.join(outDir, 'trips_actual.png')).writeAsBytes(png!.buffer.asUint8List());
      });
    }

    expect(find.byType(UpcomingTripPostcard), findsNWidgets(3));
    var previous = -1.0;
    for (final text in ['Trips', 'COMING UP', '58', 'Lake District', '194', 'Kyoto']) {
      // The first "Trips" is the heading; the other is its tab.
      final top = tester.getTopLeft(find.text(text).first).dy;
      expect(top, greaterThan(previous), reason: text);
      previous = top;
    }
    expect(tester.takeException(), isNull);
  });
}

/// Decodes every picture the screen asked for for real (pack files never
/// finish loading under the test clock), so the next build finds them in
/// the image cache.
Future<void> _decodePictures(WidgetTester tester) async {
  final wanted = [
    for (final element in find.byType(Image, skipOffstage: false).evaluate())
      ((element.widget as Image).image, createLocalImageConfiguration(element)),
  ];
  imageCache
    ..clear()
    ..clearLiveImages();
  await tester.runAsync(() async {
    for (final (provider, configuration) in wanted) {
      final done = Completer<void>();
      final stream = provider.resolve(configuration);
      final listener = ImageStreamListener(
        (image, synchronousCall) => done.isCompleted ? null : done.complete(),
        onError: (error, stackTrace) => done.isCompleted ? null : done.complete(),
      );
      stream.addListener(listener);
      await done.future;
      stream.removeListener(listener);
    }
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
