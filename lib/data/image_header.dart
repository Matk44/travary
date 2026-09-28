import 'dart:typed_data';

/// Raster formats art packs may contain.
enum ImageType {
  png('png'),
  jpeg('jpg'),
  webp('webp');

  const ImageType(this.extension);

  final String extension;

  /// The type a file extension promises (`jpeg` counts as `jpg`).
  static ImageType? forExtension(String extension) => switch (extension.toLowerCase()) {
    'png' => png,
    'jpg' || 'jpeg' => jpeg,
    'webp' => webp,
    _ => null,
  };
}

/// What an image file says about itself.
class ImageInfo {
  const ImageInfo(this.type, this.width, this.height);

  final ImageType type;
  final int width;
  final int height;

  @override
  String toString() => '${type.name} ${width}x$height';
}

/// The format [bytes] (the start of a file, 12 bytes is enough) really is,
/// judged by its signature rather than its name. Null for anything else.
ImageType? sniffImageType(List<int> bytes) {
  bool at(int offset, List<int> expected) {
    if (bytes.length < offset + expected.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (bytes[offset + i] != expected[i]) return false;
    }
    return true;
  }

  if (at(0, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return ImageType.png;
  if (at(0, const [0xFF, 0xD8, 0xFF])) return ImageType.jpeg;
  if (at(0, const [0x52, 0x49, 0x46, 0x46]) && at(8, const [0x57, 0x45, 0x42, 0x50])) return ImageType.webp;
  return null;
}

/// Type and pixel size of a whole image file, or null if it isn't a
/// well-formed PNG, JPEG or WebP header.
ImageInfo? readImageInfo(Uint8List bytes) {
  final type = sniffImageType(bytes);
  final data = ByteData.sublistView(bytes);
  try {
    return switch (type) {
      ImageType.png => _png(bytes, data),
      ImageType.jpeg => _jpeg(bytes, data),
      ImageType.webp => _webp(bytes, data),
      null => null,
    };
  } on RangeError {
    return null;
  }
}

ImageInfo? _png(Uint8List bytes, ByteData data) {
  // Signature, then the IHDR chunk: length, "IHDR", width, height.
  if (bytes.length < 24 || String.fromCharCodes(bytes, 12, 16) != 'IHDR') return null;
  return _sized(ImageType.png, data.getUint32(16), data.getUint32(20));
}

ImageInfo? _jpeg(Uint8List bytes, ByteData data) {
  var offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] != 0xFF) return null;
    final marker = bytes[offset + 1];
    if (marker == 0xFF) {
      offset++; // fill byte
      continue;
    }
    // Markers without a length.
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD9)) {
      if (marker == 0xD9) return null; // end of image before a frame
      offset += 2;
      continue;
    }
    final length = data.getUint16(offset + 2);
    if (length < 2) return null;
    // Start of frame (baseline, progressive, lossless...), not DHT/JPG/DAC.
    final isFrame = marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC;
    if (isFrame) {
      if (offset + 9 > bytes.length) return null;
      return _sized(ImageType.jpeg, data.getUint16(offset + 7), data.getUint16(offset + 5));
    }
    offset += 2 + length;
  }
  return null;
}

ImageInfo? _webp(Uint8List bytes, ByteData data) {
  if (bytes.length < 30) return null;
  final chunk = String.fromCharCodes(bytes, 12, 16);
  switch (chunk) {
    case 'VP8 ':
      // Key frame start code, then 14-bit width and height.
      if (bytes[23] != 0x9D || bytes[24] != 0x01 || bytes[25] != 0x2A) return null;
      return _sized(
        ImageType.webp,
        data.getUint16(26, Endian.little) & 0x3FFF,
        data.getUint16(28, Endian.little) & 0x3FFF,
      );
    case 'VP8L':
      if (bytes[20] != 0x2F) return null;
      final bits = data.getUint32(21, Endian.little);
      return _sized(ImageType.webp, (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1);
    case 'VP8X':
      final width = (bytes[24] | bytes[25] << 8 | bytes[26] << 16) + 1;
      final height = (bytes[27] | bytes[28] << 8 | bytes[29] << 16) + 1;
      return _sized(ImageType.webp, width, height);
    default:
      return null;
  }
}

ImageInfo? _sized(ImageType type, int width, int height) =>
    width > 0 && height > 0 ? ImageInfo(type, width, height) : null;
