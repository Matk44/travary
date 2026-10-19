import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A camera photo as a phone saves one: a JPEG of [width] × [height]
/// stored pixels, grainy enough to be several megabytes, with a GPS
/// location and the EXIF orientation that says to turn it 90° clockwise
/// (so it's seen [height] wide). Its stored left half is red and its right
/// half blue: seen the right way up, red is at the top.
Uint8List cameraPhoto({int width = 3200, int height = 2400}) {
  final random = Random(7);
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    final grain = random.nextInt(48);
    final left = pixel.x < width ~/ 2;
    pixel
      ..r = left ? 200 + grain : grain
      ..g = grain
      ..b = left ? grain : 200 + grain;
  }
  image.exif.imageIfd.orientation = 6;
  image.exif.gpsIfd
    ..gpsLatitudeRef = 'N'
    ..gpsLatitude = 51.4700
    ..gpsLongitudeRef = 'W'
    ..gpsLongitude = 0.4543;
  return img.encodeJpg(image, quality: 92);
}
