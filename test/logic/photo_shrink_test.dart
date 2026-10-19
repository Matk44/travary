import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:travary/logic/photo_shrink.dart';

/// The start of an ISO media file with [brand]: `....ftyp<brand>`.
List<int> isoMedia(String brand) => [0, 0, 0, 24, ...'ftyp'.codeUnits, ...brand.codeUnits, 0, 0, 0, 0];

/// A JPEG's markers up to its frame header, [width] × [height], after an
/// EXIF block holding a small thumbnail with a frame header of its own.
List<int> jpegHeader(int width, int height) {
  final thumbnail = [0xFF, 0xD8, 0xFF, 0xC0, 0, 11, 8, 0, 120, 0, 160, 3, 1, 0x22, 0, 0xFF, 0xD9];
  final exif = [...'Exif'.codeUnits, 0, 0, ...thumbnail];
  return [
    0xFF, 0xD8, // start of image
    0xFF, 0xE1, (exif.length + 2) >> 8, (exif.length + 2) & 0xFF, ...exif, // APP1
    0xFF, 0xDB, 0, 4, 0, 0, // a quantisation table
    0xFF, 0xC2, 0, 11, 8, height >> 8, height & 0xFF, width >> 8, width & 0xFF, 3, 1, 0x22, 0, // SOF2
    0xFF, 0xDA, 0, 2, // the picture
  ];
}

void main() {
  group('which files are camera photos', () {
    final jpeg = img.encodeJpg(img.Image(width: 8, height: 8));
    final png = img.encodePng(img.Image(width: 8, height: 8));

    test('a JPEG, HEIC or HEIF by both its name and its first bytes', () {
      expect(cameraPhotoOf('IMG_0412.JPG', jpeg), CameraPhoto.jpeg);
      expect(cameraPhotoOf('ticket.jpeg', jpeg), CameraPhoto.jpeg);
      expect(cameraPhotoOf('IMG_0412.HEIC', isoMedia('heic')), CameraPhoto.heif);
      expect(cameraPhotoOf('photo.heif', isoMedia('mif1')), CameraPhoto.heif);
    });

    test('never a PDF, a PNG screenshot, WebP or GIF', () {
      expect(cameraPhotoOf('Park tickets.pdf', '%PDF-1.7'.codeUnits), isNull);
      expect(cameraPhotoOf('Screenshot.png', png), isNull);
      expect(cameraPhotoOf('boarding.webp', 'RIFF....WEBPVP8 '.codeUnits), isNull);
      expect(cameraPhotoOf('map.gif', 'GIF89a'.codeUnits), isNull);
      expect(mayBeCameraPhoto('Park tickets.pdf'), isFalse);
      expect(mayBeCameraPhoto('Screenshot.PNG'), isFalse);
      expect(mayBeCameraPhoto('IMG_0412.HEIC'), isTrue);
    });

    test('a name and contents that disagree are left as they are', () {
      expect(cameraPhotoOf('Screenshot.jpg', png), isNull, reason: 'a PNG named .jpg');
      expect(cameraPhotoOf('photo.png', jpeg), isNull, reason: 'a JPEG named .png');
      expect(cameraPhotoOf('photo.heic', isoMedia('avif')), isNull, reason: 'AVIF is not HEIF');
      expect(cameraPhotoOf('photo.heic', isoMedia('qt  ')), isNull, reason: 'a video');
      expect(cameraPhotoOf('photo.jpg', const []), isNull);
      expect(cameraPhotoOf('photo', jpeg), isNull);
    });
  });

  group('a JPEG\'s size from its header', () {
    test('the frame header, past the EXIF thumbnail\'s', () {
      expect(jpegSizeOf(jpegHeader(4032, 3024)), (width: 4032, height: 3024));
      expect(jpegSizeOf(jpegHeader(3024, 4032)), (width: 3024, height: 4032));
    });

    test('a real JPEG', () {
      expect(jpegSizeOf(img.encodeJpg(img.Image(width: 640, height: 480))), (width: 640, height: 480));
    });

    test('nothing to read is no size', () {
      expect(jpegSizeOf(const []), isNull);
      expect(jpegSizeOf('%PDF-1.7'.codeUnits), isNull);
      expect(jpegSizeOf(jpegHeader(4032, 3024).sublist(0, 30)), isNull, reason: 'cut short');
      expect(jpegSizeOf([0xFF, 0xD8, 0xFF, 0xDA, 0, 2, 0xFF, 0xD9]), isNull, reason: 'a picture with no frame');
    });
  });

  group('whether a photo is shrunk', () {
    const small = (width: 1600, height: 1200);
    const wide = (width: 4032, height: 3024);

    test('a JPEG over about 1.5 MB, or over 2,500 pixels long', () {
      expect(shrinksPhoto(CameraPhoto.jpeg, sizeBytes: 4200000, size: small), isTrue);
      expect(shrinksPhoto(CameraPhoto.jpeg, sizeBytes: 900000, size: wide), isTrue);
      expect(shrinksPhoto(CameraPhoto.jpeg, sizeBytes: 900000, size: (width: 1875, height: 2501)), isTrue);
      expect(shrinksPhoto(CameraPhoto.jpeg, sizeBytes: 900000), isTrue, reason: 'its size is read when decoding');
    });

    test('not a small JPEG: a photo sent on from a chat stays as it came', () {
      expect(shrinksPhoto(CameraPhoto.jpeg, sizeBytes: 900000, size: small), isFalse);
      expect(
        shrinksPhoto(CameraPhoto.jpeg, sizeBytes: PhotoShrink.largeBytes, size: (width: 2500, height: 1875)),
        isFalse,
      );
    });

    test('every HEIC, so the family\'s phones can show it', () {
      expect(shrinksPhoto(CameraPhoto.heif, sizeBytes: 300000, size: small), isTrue);
      expect(shrinksPhoto(CameraPhoto.heif, sizeBytes: 2600000, size: wide), isTrue);
    });
  });

  group('the size it\'s stored at', () {
    test('the long edge at 2,500 pixels, the same shape', () {
      expect(shrunkSize((width: 4032, height: 3024)), (width: 2500, height: 1875));
      expect(shrunkSize((width: 3024, height: 4032)), (width: 1875, height: 2500));
      expect(shrunkSize((width: 8064, height: 6048)), (width: 2500, height: 1875));
      expect(shrunkSize((width: 4000, height: 1800)), (width: 2500, height: 1125));
    });

    test('never bigger than it came', () {
      expect(shrunkSize((width: 1600, height: 1200)), (width: 1600, height: 1200));
      expect(shrunkSize((width: 2500, height: 2500)), (width: 2500, height: 2500));
    });

    test('a long strip keeps a pixel across', () {
      expect(shrunkSize((width: 10000, height: 2)), (width: 2500, height: 1));
    });

    test('decoded at no more than twice that, the average doing the rest', () {
      expect(decodeSize((width: 4032, height: 3024)), (width: 4032, height: 3024));
      expect(decodeSize((width: 8064, height: 6048)), (width: 5000, height: 3750));
      expect(decodeSize((width: 6048, height: 8064)), (width: 3750, height: 5000));
      expect(decodeSize((width: 1600, height: 1200)), (width: 1600, height: 1200));
    });
  });

  group('what\'s kept', () {
    test('a shrunk JPEG only when it\'s smaller', () {
      expect(keepsShrunk(CameraPhoto.jpeg, originalBytes: 4200000, shrunkBytes: 1100000), isTrue);
      expect(keepsShrunk(CameraPhoto.jpeg, originalBytes: 1600000, shrunkBytes: 1600000), isFalse);
      expect(keepsShrunk(CameraPhoto.jpeg, originalBytes: 1600000, shrunkBytes: 1700000), isFalse);
    });

    test('a HEIC\'s JPEG always, as only a JPEG opens on every phone', () {
      expect(keepsShrunk(CameraPhoto.heif, originalBytes: 2600000, shrunkBytes: 1200000), isTrue);
      expect(keepsShrunk(CameraPhoto.heif, originalBytes: 300000, shrunkBytes: 420000), isTrue);
    });

    test('a HEIC becomes a .jpg, name and file; a JPEG keeps both', () {
      expect(shrunkPhotoName('IMG_0412.HEIC'), 'IMG_0412.jpg');
      expect(shrunkPhotoName('Hotel key.heif'), 'Hotel key.jpg');
      expect(shrunkPhotoName('IMG_0412.JPG'), 'IMG_0412.JPG');
      expect(shrunkPhotoName('ticket'), 'ticket');
      expect(shrunkExtension(CameraPhoto.heif, '.heic'), '.jpg');
      expect(shrunkExtension(CameraPhoto.jpeg, '.jpeg'), '.jpeg');
    });
  });
}
