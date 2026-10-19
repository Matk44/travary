import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../logic/photo_shrink.dart';

/// Shrinks a camera photo as it's added (when, and to what size:
/// `logic/photo_shrink.dart`).
///
/// The phone's own decoder reads it off the UI thread, turned the way it
/// was taken (its EXIF orientation), HEIC included: ImageIO on iPhone,
/// ImageDecoder on Android 9 and later. An isolate then averages it down to
/// [shrunkSize] and writes a JPEG at [PhotoShrink.jpegQuality]. Only the
/// pixels go across, so nothing of the original's metadata (its EXIF, the
/// GPS location with it) is in the JPEG.
///
/// Returns the JPEG, or null when [bytes] is kept as it is; throws when the
/// phone can't read it (then the original is kept too).
Future<Uint8List?> shrinkPhoto(Uint8List bytes, CameraPhoto photo) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size = (width: descriptor.width, height: descriptor.height);
    if (!shrinksPhoto(photo, sizeBytes: bytes.length, size: size)) return null;
    final decoded = decodeSize(size);
    codec = await descriptor.instantiateCodec(targetWidth: decoded.width, targetHeight: decoded.height);
    image = (await codec.getNextFrame()).image;
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (pixels == null) return null;
    final jpeg = await _encodeApart(pixels, image.width, image.height, shrunkSize(size));
    return keepsShrunk(photo, originalBytes: bytes.length, shrunkBytes: jpeg.length) ? jpeg : null;
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}

/// [_encode] in an isolate of its own, given only plain data to take along.
Future<Uint8List> _encodeApart(ByteData pixels, int width, int height, PhotoSize size) =>
    Isolate.run(() => _encode(pixels, width, height, size));

/// RGBA [pixels], [width] × [height], as a JPEG [size] across.
Uint8List _encode(ByteData pixels, int width, int height, PhotoSize size) {
  var image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: pixels.buffer,
    bytesOffset: pixels.offsetInBytes,
    numChannels: 4,
  );
  if (width != size.width || height != size.height) {
    image = img.copyResize(image, width: size.width, height: size.height, interpolation: img.Interpolation.average);
  }
  // Colour at half resolution, as cameras write it; the detail a barcode
  // needs is all in the brightness.
  return img.encodeJpg(image, quality: PhotoShrink.jpegQuality, chroma: img.JpegChroma.yuv420);
}
