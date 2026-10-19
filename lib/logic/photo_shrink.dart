import 'dart:math';

/// Camera photos are shrunk once, as they're added (`AttachmentStore.import`),
/// and that one file is what opens on the phone, backs up to the cloud and
/// reaches the family's phones: there's never a second, lesser copy. Only
/// camera photos (JPEG, HEIC and HEIF): PDFs, PNG screenshots, WebP and GIF
/// are kept byte for byte, so a barcode stays as sharp as it came.
abstract final class PhotoShrink {
  /// The longest a stored photo's long edge gets, in pixels: a ticket's
  /// barcode and small print stay sharp at this size.
  static const maxLongEdge = 2500;

  /// A JPEG larger than this (about 1.5 MB) is shrunk even if it's no
  /// wider than [maxLongEdge].
  static const largeBytes = 1500000;

  /// The JPEG quality a shrunk photo is saved at.
  static const jpegQuality = 85;
}

/// The kinds of camera photo that are shrunk.
enum CameraPhoto { jpeg, heif }

typedef PhotoSize = ({int width, int height});

/// The file names that may be camera photos, by extension: only these are
/// read to find out ([cameraPhotoOf]).
bool mayBeCameraPhoto(String fileName) => _photoExtensions.contains(_extensionOf(fileName));

const _photoExtensions = {'jpg', 'jpeg', 'heic', 'heif'};

/// The camera photo a file named [fileName] holds, by its name and its
/// first bytes ([head]), or null for anything else: a file only counts when
/// both agree, so a PNG screenshot is never taken for a photo.
CameraPhoto? cameraPhotoOf(String fileName, List<int> head) => switch (_extensionOf(fileName)) {
  'jpg' || 'jpeg' when _startsJpeg(head) => CameraPhoto.jpeg,
  'heic' || 'heif' when _startsHeif(head) => CameraPhoto.heif,
  _ => null,
};

bool _startsJpeg(List<int> head) => head.length >= 3 && head[0] == 0xFF && head[1] == 0xD8 && head[2] == 0xFF;

/// An ISO media file whose brand says HEIF: `....ftypheic` and the like.
bool _startsHeif(List<int> head) =>
    head.length >= 12 &&
    String.fromCharCodes(head.sublist(4, 8)) == 'ftyp' &&
    _heifBrands.contains(String.fromCharCodes(head.sublist(8, 12)));

const _heifBrands = {'heic', 'heix', 'heim', 'heis', 'hevc', 'hevx', 'hevm', 'hevs', 'mif1', 'msf1'};

/// The pixel size a JPEG's frame header gives, before any turn its EXIF
/// asks for (the long edge is the same either way), or null if [bytes] has
/// no frame header. Reads only up to the header.
PhotoSize? jpegSizeOf(List<int> bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
  var i = 2;
  while (i + 3 < bytes.length) {
    if (bytes[i] != 0xFF) return null;
    final marker = bytes[i + 1];
    // Fill bytes, then markers that stand alone.
    if (marker == 0xFF) {
      i++;
      continue;
    }
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD8)) {
      i += 2;
      continue;
    }
    // The end, or the picture itself, before any frame header.
    if (marker == 0xD9 || marker == 0xDA) return null;
    final length = (bytes[i + 2] << 8) | bytes[i + 3];
    if (length < 2) return null;
    // SOF0–SOF15, leaving out DHT, JPG and DAC, which share the range.
    final frame = marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC;
    if (frame) {
      if (i + 8 >= bytes.length) return null;
      final height = (bytes[i + 5] << 8) | bytes[i + 6];
      final width = (bytes[i + 7] << 8) | bytes[i + 8];
      return width > 0 && height > 0 ? (width: width, height: height) : null;
    }
    i += 2 + length;
  }
  return null;
}

/// Whether a camera photo of [sizeBytes], [size] pixels across (null when
/// it can't be told yet), is shrunk. A HEIC or HEIF always is, into a JPEG,
/// so a family member's phone can show it (Android shows HEIC only from
/// Android 9); a JPEG when it's over [PhotoShrink.largeBytes] or its long
/// edge is over [PhotoShrink.maxLongEdge].
bool shrinksPhoto(CameraPhoto photo, {required int sizeBytes, PhotoSize? size}) => switch (photo) {
  CameraPhoto.heif => true,
  CameraPhoto.jpeg => sizeBytes > PhotoShrink.largeBytes || size == null || _longEdge(size) > PhotoShrink.maxLongEdge,
};

/// The size a photo seen at [size] (turned the way it was taken) is stored
/// at: the same shape, its long edge at most [PhotoShrink.maxLongEdge],
/// never bigger than it came.
PhotoSize shrunkSize(PhotoSize size) => _fit(size, PhotoShrink.maxLongEdge);

/// The size the phone decodes a photo seen at [size] at, before it's scaled
/// down to [shrunkSize]: the phone's decoder scales bilinearly, which stays
/// smooth only down to half, so it stops at twice the stored size and an
/// average over each stored pixel's area does the rest.
PhotoSize decodeSize(PhotoSize size) => _fit(size, 2 * PhotoShrink.maxLongEdge);

PhotoSize _fit(PhotoSize size, int longEdge) {
  final long = _longEdge(size);
  if (long <= longEdge) return size;
  final scale = longEdge / long;
  return (width: max(1, (size.width * scale).round()), height: max(1, (size.height * scale).round()));
}

int _longEdge(PhotoSize size) => max(size.width, size.height);

/// Whether the shrunk JPEG ([shrunkBytes]) is kept in place of the original
/// ([originalBytes]): a JPEG only when it's smaller (a photo is never made
/// bigger); a HEIC or HEIF always, as only the JPEG opens on every phone.
bool keepsShrunk(CameraPhoto photo, {required int originalBytes, required int shrunkBytes}) =>
    photo == CameraPhoto.heif || shrunkBytes < originalBytes;

/// The extension a shrunk [photo] is stored with: a HEIC or HEIF becomes a
/// `.jpg`; a JPEG keeps [extension] (`.jpeg` or `.jpg`).
String shrunkExtension(CameraPhoto photo, String extension) => photo == CameraPhoto.heif ? '.jpg' : extension;

/// The name a shrunk photo goes by: "IMG_0412.HEIC" becomes "IMG_0412.jpg",
/// as that's what it is now; a JPEG keeps its name.
String shrunkPhotoName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot == -1) return name;
  final extension = name.substring(dot + 1).toLowerCase();
  return extension == 'heic' || extension == 'heif' ? '${name.substring(0, dot)}.jpg' : name;
}

String _extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
}
