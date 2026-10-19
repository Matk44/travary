import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// How large each of the countdown widget's pictures is written, as the
/// longest side in pixels: a little under the most the largest widget draws
/// it at on a 3x phone (`ios/CountdownWidget/CountdownStage.swift`).
///
/// The widget lives in a process the phone stops when it uses too much
/// memory, about 30 MB. Drawing a picture costs three to four times its
/// decoded size, and a bundled postcard is 1122 × 1402: copied as it is,
/// one render peaked at 43 MB on the simulator, which never stops it, and a
/// phone leaves the widget blank. Written at these sizes the same render
/// takes far less (the numbers are in `docs/COUNTDOWN_WIDGET.md`).
abstract final class CountdownWidgetArtSize {
  /// The large widget's postcard (portrait) is drawn about 1000 pixels tall
  /// at 3x; written at 800 it's enlarged by about a quarter, which its grain
  /// hides. At 1100 the widget's render peaked near the limit.
  static const portrait = 800;

  /// The medium widget's postcard (landscape), drawn about 1000 wide at 3x.
  static const landscape = 900;

  /// The luggage tag, drawn up to 800 pixels tall on the large widget; its
  /// words are live text, so only the paper and the rope are enlarged.
  static const tag = 600;

  /// The linen tile. It's drawn at a fixed 341 points however many pixels it
  /// has, so a smaller one is a little softer, never denser.
  static const linen = 512;

  /// Travi's stills are already about this size.
  static const travi = 480;
}

/// [bytes] (any picture the engine reads) as a PNG whose longest side is at
/// most [longestSide], the way the widget draws it cheaply: a PNG of the
/// size drawn decodes in a fraction of the memory of a larger one. Pictures
/// already smaller are written at their own size. Null when it can't be
/// read, and the caller keeps the original.
Future<Uint8List?> shrinkForWidget(Uint8List bytes, {required int longestSide}) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final width = descriptor.width;
    final height = descriptor.height;
    if (width <= 0 || height <= 0) return null;
    // Decoded at the size it's kept at, not decoded whole and then reduced.
    // Only the longer side is given, so the other follows the picture's shape.
    final shrinks = (width > height ? width : height) > longestSide;
    codec = await descriptor.instantiateCodec(
      targetWidth: shrinks && width >= height ? longestSide : null,
      targetHeight: shrinks && height > width ? longestSide : null,
    );
    image = (await codec.getNextFrame()).image;
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png?.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
  } catch (error) {
    if (kDebugMode) debugPrint('Countdown widget art not shrunk: $error');
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}
