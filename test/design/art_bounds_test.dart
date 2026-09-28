import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/design/art/art_bounds.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/cards/card_parts.dart';

/// A 200×200 transparent canvas with one solid block at [block] (pixels),
/// like a vignette gathered in its corner.
Future<ui.Image> _vignette(Rect block) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(block, Paint()..color = const Color(0xFF1C2A47));
  return recorder.endRecording().toImage(200, 200);
}

void main() {
  setUp(ArtContentBounds.clear);

  testWidgets('the visible part of a transparent picture, as fractions', (tester) async {
    final bounds = await tester.runAsync(() async {
      final image = await _vignette(const Rect.fromLTRB(120, 80, 190, 196));
      return ArtContentBounds.measure('corner', image);
    });
    // Within one sampling step (4 px of 200) of the true edges.
    expect(bounds!.left, closeTo(0.60, 0.03));
    expect(bounds.top, closeTo(0.40, 0.03));
    expect(bounds.right, closeTo(0.95, 0.03));
    expect(bounds.bottom, closeTo(0.98, 0.03));
    expect(ArtContentBounds.cached('corner'), bounds, reason: 'measured once per picture');
  });

  testWidgets('a fully transparent picture keeps its whole canvas', (tester) async {
    final bounds = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder);
      final image = await recorder.endRecording().toImage(64, 64);
      return ArtContentBounds.measure('empty', image);
    });
    expect(bounds, const Rect.fromLTRB(0, 0, 1, 1));
  });

  testWidgets('TrimmedArt fits only the visible part into its panel', (tester) async {
    final temp = Directory.systemTemp.createTempSync('travary_trim');
    addTearDown(() => temp.deleteSync(recursive: true));
    final file = File(p.join(temp.path, 'corner_vignette.png'));
    await tester.runAsync(() async {
      final image = await _vignette(const Rect.fromLTRB(100, 150, 200, 200));
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(png!.buffer.asUint8List());
    });
    final ref = FileArtImage(file.path);

    // Decode for real first (a load started inside the test's fake clock
    // would never finish while we wait in real time).
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => precacheImage(artImageProvider(ref), tester.element(find.byType(SizedBox))));
    await tester.pumpWidget(
      Center(
        child: SizedBox(width: 60, height: 100, child: TrimmedArt(image: ref)),
      ),
    );
    // Let the measurement run, then show its result.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    final bounds = ArtContentBounds.cached(ref)!;
    expect(bounds.width, closeTo(0.5, 0.05), reason: 'the empty left half is trimmed');
    expect(bounds.height, closeTo(0.25, 0.05), reason: 'the empty top three quarters are trimmed');
    expect(find.descendant(of: find.byType(TrimmedArt), matching: find.byType(CustomPaint)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a picture that cannot load leaves the panel empty', (tester) async {
    await tester.pumpWidget(
      const Center(
        child: SizedBox(width: 60, height: 100, child: TrimmedArt(image: FileArtImage('/nowhere/vignette.png'))),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.descendant(of: find.byType(TrimmedArt), matching: find.byType(CustomPaint)), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
