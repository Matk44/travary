import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/design/cards/card_parts.dart';
import 'package:travary/design/cards/featured_ticket_card.dart';
import 'package:travary/design/cards/room_key_card.dart';
import 'package:travary/design/cards/tagged_reservation_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/day_timeline.dart';
import 'package:travary/design/widgets/today_header.dart';

import '../support/canonical_today.dart';

/// The canonical Today screen rendered at the reference's exact size, 813 ×
/// 1933 pixels: a 390-point-wide phone at 813/390 pixels per point with a
/// 34-point home-indicator inset, no status bar (the reference has none).
///
/// Always checks the hierarchy. With `TRAVARY_VISUAL_QA=1` it also loads
/// the app's real fonts (from `build/visual_qa/fonts/`, filled by
/// `tool/visual_qa.sh`) and writes, for comparison with
/// docs/reference/travary_today_reference.png:
///
///   build/visual_qa/today_actual.png    the render
///   build/visual_qa/today_overlay.png   render at 50% over the reference
///   build/visual_qa/today_diff.png      per-pixel difference, ×3
///   build/visual_qa/today_metrics.txt   mean difference, overall and per band
void main() {
  const referencePath = 'docs/reference/travary_today_reference.png';
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

  testWidgets('the canonical Today screen at the reference size', (tester) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = dpr;
    tester.view.padding = const FakeViewPadding(bottom: 34 * dpr);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * dpr);
    addTearDown(tester.view.reset);

    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: canonicalTodayApp()));
    await tester.pumpAndSettle();
    await _precacheImages(tester);

    if (qa) {
      final actual = await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        return render.toImage(pixelRatio: dpr);
      });
      await tester.runAsync(() => _writeComparison(actual!, referencePath, outDir));
      _writeElements(tester, dpr, outDir);
    }

    // The hierarchy, top to bottom.
    final order = [
      find.text('Good morning'),
      find.text('Day 3 of 7 · Orlando'),
      find.text('NEXT UP'),
      find.text('Magic Kingdom'),
      find.text('HOTEL'),
      find.text("Disney's Polynesian Resort"),
      find.text('LUNCH'),
      find.text('Be Our Guest Restaurant'),
      find.text('DINNER'),
      find.text('Ohana'),
      find.text('12:30'),
    ];
    var previous = -1.0;
    for (final finder in order) {
      expect(finder, findsOneWidget);
      final top = tester.getTopLeft(finder).dy;
      expect(top, greaterThan(previous), reason: '$finder should be below the one before');
      previous = top;
    }
    expect(find.text('28° Sunny'), findsOneWidget);
    expect(find.text('9:00am · 2 tickets'), findsOneWidget);
    expect(find.text('ADMIT TWO'), findsOneWidget);
    expect(find.text('Show tickets'), findsOneWidget);
    expect(find.text('Room 2214'), findsOneWidget);
    expect(find.text('12:30pm · Table for 4'), findsOneWidget);
    expect(find.text('7:15pm'), findsOneWidget);
    for (final label in ['Park', 'Lunch', 'Dinner', '9:00', '7:15']) {
      expect(find.text(label), findsOneWidget);
    }
    for (final tab in ['Today', 'Trips', 'Documents', 'Profile']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(find.byType(FeaturedTicketCard), findsOneWidget);
    expect(find.byType(RoomKeyCard), findsOneWidget);
    expect(find.byType(TaggedReservationCard), findsNWidgets(2));
    expect(find.byType(DayTimeline), findsOneWidget);
    // Everything fits on the reference screen without scrolling.
    expect(tester.getBottomLeft(find.text('Dinner')).dy, lessThan(927 - 34 - NavLayout.height - NavLayout.rise));
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
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
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

/// Decodes every picture on screen, so the render shows real art.
Future<void> _precacheImages(WidgetTester tester) async {
  for (var pass = 0; pass < 2; pass++) {
    final elements = find.byType(Image).evaluate().toList();
    final trimmed = find.byType(TrimmedArt).evaluate().toList();
    await tester.runAsync(() async {
      for (final element in elements) {
        await precacheImage((element.widget as Image).image, element);
      }
      for (final element in trimmed) {
        await precacheImage(artImageProvider((element.widget as TrimmedArt).image), element);
      }
      // Trimmed art measures its visible part once decoded.
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
  }
}

Future<void> _writeComparison(ui.Image actual, String referencePath, String outDir) async {
  await Directory(outDir).create(recursive: true);
  final actualPng = await actual.toByteData(format: ui.ImageByteFormat.png);
  await File(p.join(outDir, 'today_actual.png')).writeAsBytes(actualPng!.buffer.asUint8List());

  final codec = await ui.instantiateImageCodec(await File(referencePath).readAsBytes());
  final reference = (await codec.getNextFrame()).image;
  final width = reference.width;
  final height = reference.height;
  final a = (await actual.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  final r = (await reference.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  if (actual.width != width || actual.height != height) {
    throw StateError('Render is ${actual.width}x${actual.height}; the reference is ${width}x$height.');
  }

  final overlay = Uint8List(a.length);
  final diff = Uint8List(a.length);
  var total = 0;
  var changed = 0;
  final bands = List<int>.filled(10, 0);
  for (var i = 0; i < a.length; i += 4) {
    var pixel = 0;
    for (var c = 0; c < 3; c++) {
      overlay[i + c] = (a[i + c] + r[i + c]) >> 1;
      final d = (a[i + c] - r[i + c]).abs();
      pixel += d;
      diff[i + c] = d * 3 > 255 ? 255 : d * 3;
    }
    overlay[i + 3] = 255;
    diff[i + 3] = 255;
    total += pixel;
    bands[((i ~/ 4) ~/ width) * 10 ~/ height] += pixel;
    if (pixel > 3 * 40) changed++;
  }

  Future<void> save(Uint8List pixels, String name) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final image = (await (await descriptor.instantiateCodec()).getNextFrame()).image;
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(p.join(outDir, name)).writeAsBytes(png!.buffer.asUint8List());
  }

  await save(overlay, 'today_overlay.png');
  await save(diff, 'today_diff.png');
  final pixels = width * height;
  final bandPixels = pixels / 10;
  final metrics = StringBuffer()
    ..writeln('Mean absolute difference per channel: ${(total / (pixels * 3)).toStringAsFixed(2)} / 255')
    ..writeln('Pixels differing by more than 40 per channel: ${(100 * changed / pixels).toStringAsFixed(1)}%')
    ..writeln('By tenth of the height (top to bottom):');
  for (var b = 0; b < 10; b++) {
    metrics.writeln('  ${b * 10}–${b * 10 + 10}%: ${(bands[b] / (bandPixels * 3)).toStringAsFixed(2)}');
  }
  await File(p.join(outDir, 'today_metrics.txt')).writeAsString(metrics.toString());
  // ignore: avoid_print
  print(metrics);
}

/// Where each element landed, against where it is in the reference (both in
/// reference pixels; reference boxes measured from the PNG: the physical
/// card, not its shadow or hanging tag).
void _writeElements(WidgetTester tester, double dpr, String outDir) {
  Rect px(Rect r) => Rect.fromLTRB(r.left * dpr, r.top * dpr, r.right * dpr, r.bottom * dpr);
  // Each tab's surface slot (raster or flat stand-in), wherever its rise puts it.
  final tabs = find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_TabSurface');
  final timeline = tester.getRect(find.byType(DayTimeline));
  final elements = <String, (Rect, Rect)>{
    'weather pill': (px(tester.getRect(find.byType(HeaderPill))), const Rect.fromLTRB(565, 78, 787, 150)),
    'featured ticket': (px(tester.getRect(find.byType(FeaturedTicketCard))), const Rect.fromLTRB(22, 240, 795, 625)),
    'room key card': (px(tester.getRect(find.byType(RoomKeyCard))), const Rect.fromLTRB(32, 658, 780, 1028)),
    'lunch card': (
      px(tester.getRect(find.byType(TaggedReservationCard).first)),
      const Rect.fromLTRB(35, 1062, 780, 1297),
    ),
    'dinner card': (
      px(tester.getRect(find.byType(TaggedReservationCard).last)),
      const Rect.fromLTRB(35, 1328, 780, 1562),
    ),
    'timeline line (y)': (
      px(Rect.fromLTWH(timeline.left + 30, timeline.top + 6.5, timeline.width - 60, 0)),
      const Rect.fromLTRB(97, 1623, 715, 1623),
    ),
    'Today tab (selected)': (px(tester.getRect(tabs.at(0))), const Rect.fromLTRB(18, 1742, 170, 1933)),
    'Trips tab': (px(tester.getRect(tabs.at(1))), const Rect.fromLTRB(178, 1765, 330, 1933)),
    'Add tab': (px(tester.getRect(tabs.at(2))), const Rect.fromLTRB(338, 1752, 475, 1933)),
  };
  String f(double v) => v.toStringAsFixed(0);
  final table = StringBuffer('Element positions (reference pixels): ours vs reference, and the difference\n');
  for (final entry in elements.entries) {
    final (ours, ref) = entry.value;
    table.writeln(
      '  ${entry.key.padRight(22)} '
      'x ${f(ours.left)}–${f(ours.right)} (ref ${f(ref.left)}–${f(ref.right)}), '
      'y ${f(ours.top)}–${f(ours.bottom)} (ref ${f(ref.top)}–${f(ref.bottom)}); '
      'height ${f(ours.height)} vs ${f(ref.height)}, centre dy ${f(ours.center.dy - ref.center.dy)}',
    );
  }
  File(p.join(outDir, 'today_metrics.txt')).writeAsStringSync(table.toString(), mode: FileMode.append);
  // ignore: avoid_print
  print(table);
}
