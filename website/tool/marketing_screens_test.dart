import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/design/tokens.dart';

import '../../test/support/documents_stamps.dart';
import '../../test/support/open_tab.dart';

/// Screens for travary.app, rendered from the shipping demo data (generic
/// names: Lagoon Resort, Sunshine Park) with the app's real fonts, so the
/// website shows the real app and no real brand's names.
///
/// Run `tool/visual_qa.sh` once (it collects the fonts), then from the
/// project root:
///
///   TRAVARY_VISUAL_QA=1 flutter test website/tool/marketing_screens_test.dart
///
/// Writes `build/marketing_screens/*.png` (390 × 844 points at 2×), which
/// `website/build.py` picks up when present.
void main() {
  const outDir = 'build/marketing_screens';
  const dpr = 2.0;
  const points = Size(390, 844);
  final catalog = catalogWithStamps();

  setUpAll(() async {
    TravaryText.useGoogleFonts = false;
    await _loadFonts('build/visual_qa/fonts');
  });
  tearDownAll(() {
    TravaryText.serifFamily = null;
    TravaryText.sansFamily = null;
  });

  Future<void> render(WidgetTester tester, String name, DateTime now, {String? tab}) async {
    tester.view.physicalSize = points * dpr;
    tester.view.devicePixelRatio = dpr;
    tester.view.padding = const FakeViewPadding(top: 47 * dpr, bottom: 34 * dpr);
    tester.view.viewPadding = const FakeViewPadding(top: 47 * dpr, bottom: 34 * dpr);
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();
    Future<void> open() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: documentsApp(catalog: catalog, now: now),
        ),
      );
      await tester.pumpAndSettle();
      if (tab != null) await openTab(tester, tab);
    }

    await open();
    await decodePictures(tester);
    await open();
    final image = await tester.runAsync(() async {
      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return render.toImage(pixelRatio: dpr);
    });
    await tester.runAsync(() async {
      await Directory(outDir).create(recursive: true);
      final png = await image!.toByteData(format: ui.ImageByteFormat.png);
      await File(p.join(outDir, '$name.png')).writeAsBytes(png!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  }

  final betweenTrips = DateTime(2026, 10, 10, 8, 0);

  testWidgets('Today during the Orlando trip', (tester) => render(tester, 'today_orlando', documentsNow));
  testWidgets('Today in the Lake District', (tester) => render(tester, 'today_lakes', lakesNow));
  testWidgets('Today counting down', (tester) => render(tester, 'countdown', betweenTrips));
  testWidgets('Trips', (tester) => render(tester, 'trips', betweenTrips, tab: 'Trips'));
  testWidgets('Documents', (tester) => render(tester, 'documents', documentsNow, tab: 'Documents'));
}

Future<void> _loadFonts(String dir) async {
  final folder = Directory(dir);
  if (!folder.existsSync()) {
    // ignore: avoid_print
    print('No fonts in $dir: run tool/visual_qa.sh first. Rendering with the test font.');
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
