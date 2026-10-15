import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_slots.dart';
import 'package:travary/design/art/card_shells.dart' show FractionRect;
import 'package:travary/design/art/document_stamps.dart';
import 'package:travary/design/cards/document_stamp_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';

import '../support/canonical_today.dart';
import '../support/documents_stamps.dart';

/// Decoded RGBA pixels of a PNG, with helpers to read fractions of it.
class _Pixels {
  _Pixels(this.width, this.height, this.bytes);

  final int width;
  final int height;
  final ByteData bytes;

  static Future<_Pixels> of(String path) async {
    final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
    final image = (await codec.getNextFrame()).image;
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final pixels = _Pixels(image.width, image.height, bytes);
    image.dispose();
    return pixels;
  }

  int _i(double fx, double fy) =>
      ((fy * height).floor().clamp(0, height - 1) * width + (fx * width).floor().clamp(0, width - 1)) * 4;
  int alpha(double fx, double fy) => bytes.getUint8(_i(fx, fy) + 3);
  (int, int, int) rgb(double fx, double fy) {
    final i = _i(fx, fy);
    return (bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bundled = bundledArtCatalog();

  group('stamp frames', () {
    test('each design\'s window is clear and its frame solid, where the geometry says', () async {
      for (final design in StampDesign.values) {
        final path = 'assets/art/common/${design.key}.webp';
        final pixels = await _Pixels.of(path);
        expect((pixels.width, pixels.height), (StampDesign.width, StampDesign.height), reason: path);
        final g = design.geometry;
        final window = g.window;
        final body = g.body;
        // Inside the window, clear; just outside it (the lip), solid paper.
        for (final (fx, fy) in [
          (window.left + 0.02, window.top + 0.02),
          ((window.left + window.right) / 2, (window.top + window.bottom) / 2),
          (window.right - 0.02, window.bottom - 0.02),
        ]) {
          expect(pixels.alpha(fx, fy), lessThan(8), reason: '$path window at $fx, $fy');
        }
        final middleY = (window.top + window.bottom) / 2;
        final middleX = (window.left + window.right) / 2;
        for (final (fx, fy) in [
          (window.left - 0.02, middleY),
          (window.right + 0.02, middleY),
          (middleX, window.top - 0.02),
          (middleX, window.bottom + 0.02),
        ]) {
          expect(pixels.alpha(fx, fy), greaterThan(250), reason: '$path frame at $fx, $fy');
        }
        // Outside the body, transparent (bar a faint shadow).
        expect(pixels.alpha(body.left / 2, middleY), lessThan(64), reason: path);
        expect(pixels.alpha(middleX, body.top / 2), lessThan(64), reason: path);
        // The scene reaches just under the lip, never past the frame.
        final scene = g.scene;
        expect(scene.left, lessThan(window.left));
        expect(scene.right, greaterThan(window.right));
        expect(scene.left, greaterThan(body.left));
        expect(scene.bottom, lessThan(body.bottom));
      }
    });

    test('a booking always gets the same design: its variant, modulo three', () {
      for (final variant in [0, 1, 2, 3, 4, 5, 2147483646]) {
        expect(StampDesign.forVariant(variant), StampDesign.values[variant % 3], reason: '$variant');
      }
    });

    test('every look gets all three frames, the postmark and its lines', () {
      for (final look in ExperienceTheme.values) {
        final art = ArtSlots(bundled, TripArtContext(theme: look)).documentArt();
        expect(art.stamps.keys, StampDesign.values, reason: look.wireName);
        expect(art.postmark, const BundledArtImage('assets/art/common/documents_postmark.webp'));
        expect(art.cancelLines, const BundledArtImage('assets/art/common/documents_cancel_lines.webp'));
        for (var variant = 0; variant < 6; variant++) {
          expect(art.stampFor(variant)!.design, StampDesign.forVariant(variant));
        }
      }
    });

    test('a missing frame falls back to the first there is, the same every time', () {
      const vintageOnly = DocumentArt(stamps: {StampDesign.vintage: BundledArtImage('v.png')});
      for (var variant = 0; variant < 6; variant++) {
        expect(vintageOnly.stampFor(variant)!.design, StampDesign.vintage);
      }
      const noClassic = DocumentArt(
        stamps: {StampDesign.airmail: BundledArtImage('a.png'), StampDesign.vintage: BundledArtImage('v.png')},
      );
      expect(noClassic.stampFor(0)!.design, StampDesign.airmail);
      expect(noClassic.stampFor(2)!.design, StampDesign.vintage);
      expect(DocumentArt.none.stampFor(1), isNull);
    });

    test('the postmark and its lines are one flat ink, and their measured bodies hold it', () async {
      for (final slot in [SurfaceSlot.documentsPostmark, SurfaceSlot.documentsCancelLines]) {
        final pixels = await _Pixels.of('assets/art/common/${slot.key}.webp');
        final body = slot.body!;
        expect(pixels.alpha(body.left / 2, 0.5), 0, reason: slot.key);
        expect(pixels.alpha(0.5, body.top / 2), 0, reason: slot.key);
        // The ring's middle is empty for the live date.
        if (slot == SurfaceSlot.documentsPostmark) expect(pixels.alpha(0.5, 0.5), 0);
      }
    });
  });

  group('destination stamps', () {
    test('every pack\'s stamp is its template size, with the label area blank ivory', () async {
      const label = DestinationStampGeometry.label;
      for (final id in stampPackIds) {
        final art = sourcePack(id).common[documentsDestinationStampArt]!;
        final pixels = await _Pixels.of(art.path);
        expect(
          (pixels.width, pixels.height),
          (DestinationStampGeometry.width, DestinationStampGeometry.height),
          reason: id,
        );
        for (var fy = label.top; fy <= label.bottom; fy += 0.01) {
          for (var fx = label.left; fx <= label.right; fx += 0.02) {
            final (r, g, b) = pixels.rgb(fx, fy);
            final ivory = pixels.alpha(fx, fy) > 250 && r > 200 && g > 190 && b > 170 && (r - b) < 60;
            expect(ivory, isTrue, reason: '$id label at $fx, $fy is ($r, $g, $b)');
          }
        }
        const body = DestinationStampGeometry.body;
        expect(pixels.alpha(body.left / 2, 0.5), lessThan(64), reason: id);
        expect(pixels.alpha(0.5, 0.5), greaterThan(245), reason: id);
      }
    });

    test('a destination pack\'s stamp is named for its city, region or country', () {
      const location = TripLocationHint(
        countryName: 'Japan',
        region: 'Kansai',
        city: 'Kyoto',
        confidence: 1,
        verification: LocationVerification.verified,
      );
      expect(destinationName(location, ArtRank.city), 'Kyoto');
      expect(destinationName(location, ArtRank.region), 'Kansai');
      expect(destinationName(location, ArtRank.country), 'Japan');
      for (final look in [ArtRank.primary, ArtRank.secondary, ArtRank.core]) {
        expect(destinationName(location, look), isNull, reason: look.name);
      }
    });
  });

  group('fitting a row', () {
    const chrome =
        DocumentStampLayout.paddingStart +
        DocumentStampLayout.paddingEnd +
        DocumentStampLayout.stampGap +
        DocumentStampLayout.chevron;
    double textWidth(double width) {
      final fit = fitDocumentRow(width);
      final gap = fit.lines ? DocumentStampLayout.ringGap * fit.scale : DocumentStampLayout.ringGapTight;
      return width - chrome - gap - (DocumentStampLayout.ringDiameter + DocumentStampLayout.stampWidth) * fit.scale;
    }

    test('full size, with its lines, from a 375-point phone up', () {
      for (final phone in [375.0, 390, 402, 430, 768]) {
        final width = phone - 2 * DocumentStampLayout.inset;
        expect(fitDocumentRow(width), (scale: 1.0, lines: true), reason: '$phone');
        expect(textWidth(width), greaterThanOrEqualTo(DocumentStampLayout.minTextWidth), reason: '$phone');
      }
    });

    test('on a narrower phone the lines go, then the art shrinks, before the text does', () {
      final fit = fitDocumentRow(320 - 2 * DocumentStampLayout.inset);
      expect(fit.lines, isFalse);
      expect(fit.scale, lessThan(1));
      expect(fit.scale, greaterThanOrEqualTo(DocumentStampLayout.minArtScale));
      for (var width = 200.0; width <= 800; width += 3) {
        final fit = fitDocumentRow(width);
        expect(fit.scale, inInclusiveRange(DocumentStampLayout.minArtScale, 1.0), reason: '$width');
        if (fit.scale < DocumentStampLayout.linesMinScale) expect(fit.lines, isFalse, reason: '$width');
        if (fit.scale > DocumentStampLayout.minArtScale) {
          expect(textWidth(width), greaterThanOrEqualTo(DocumentStampLayout.minTextWidth - 0.01), reason: '$width');
        }
      }
    });

    test('a wider "Show tickets" button takes its room from the art first, not the text', () {
      const width = 375 - 2 * DocumentStampLayout.inset;
      final withButton = fitDocumentRow(width, trailing: DocumentStampLayout.ticketsButton);
      expect(withButton.scale, lessThanOrEqualTo(fitDocumentRow(width).scale));
    });
  });

  test('scene windows are proportioned for the right-leaning crop of 3:2 scenes', () {
    for (final design in StampDesign.values) {
      final FractionRect w = design.geometry.window;
      final aspect = (w.width * StampDesign.width) / (w.height * StampDesign.height);
      expect(aspect, inInclusiveRange(1.1, 1.3), reason: design.name);
    }
  });
}
