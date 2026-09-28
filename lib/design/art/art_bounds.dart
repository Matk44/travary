import 'dart:ui' as ui;

/// The visible part of a transparent picture. Vignettes are drawn on a
/// square canvas with the art gathered in one corner, so fitting the whole
/// canvas into a small panel wastes much of it on empty margin. Cards fit
/// the visible part instead.
///
/// Measured once per picture from its transparency and remembered for the
/// session (bundled and pack art alike, no metadata needed). This only
/// finds where the pixels are; it never reads their colours.
abstract final class ArtContentBounds {
  static final _cache = <Object, ui.Rect>{};

  /// Alpha above this counts as visible (soft shadows and grain below it
  /// don't).
  static const _threshold = 24;

  /// The bounds already measured for [key], as fractions of the image.
  static ui.Rect? cached(Object key) => _cache[key];

  /// The visible part of [image], as fractions of its size (the whole image
  /// if it's fully transparent). Remembered under [key].
  static Future<ui.Rect> measure(Object key, ui.Image image, {int stride = 4}) async {
    final known = _cache[key];
    if (known != null) return known;
    final bounds = await _scan(image, stride);
    _cache[key] = bounds;
    return bounds;
  }

  static Future<ui.Rect> _scan(ui.Image image, int stride) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    final width = image.width;
    final height = image.height;
    if (data == null || width == 0 || height == 0) return const ui.Rect.fromLTRB(0, 0, 1, 1);
    var left = width, top = height, right = -1, bottom = -1;
    for (var y = 0; y < height; y += stride) {
      final row = y * width;
      for (var x = 0; x < width; x += stride) {
        if (data.getUint8((row + x) * 4 + 3) > _threshold) {
          if (x < left) left = x;
          if (x > right) right = x;
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
    }
    if (right < 0) return const ui.Rect.fromLTRB(0, 0, 1, 1);
    // The sampling grid can miss up to one stride on each side.
    return ui.Rect.fromLTRB(
      (left - stride).clamp(0, width) / width,
      (top - stride).clamp(0, height) / height,
      (right + stride).clamp(0, width) / width,
      (bottom + stride).clamp(0, height) / height,
    );
  }

  /// Forgets everything measured (tests).
  static void clear() => _cache.clear();
}
