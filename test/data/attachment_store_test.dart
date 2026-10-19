import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:travary/data/attachment_store.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/access.dart';
import 'package:travary/logic/photo_shrink.dart';

import '../support/photo_fixture.dart';

/// Ticket files as they're added, with the real decoder, isolate and disk.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late AttachmentStore store;
  late Uint8List photo;

  setUpAll(() => photo = cameraPhoto());

  setUp(() {
    dir = Directory.systemTemp.createTempSync('travary_files');
    store = AttachmentStore.at(Directory('${dir.path}/attachments')..createSync());
  });

  tearDown(() => dir.deleteSync(recursive: true));

  String source(String name, List<int> bytes) => (File('${dir.path}/$name')..writeAsBytesSync(bytes)).path;

  Uint8List stored(Attachment attachment) => store.fileFor(attachment).readAsBytesSync();

  test('a camera photo is stored smaller: upright, 2,500 pixels long, without its location', () async {
    expect(photo.length, greaterThan(PhotoShrink.largeBytes));
    expect(img.decodeJpgExif(photo)!.gpsIfd.hasGPSLatitude, isTrue, reason: 'the photo says where it was taken');

    final attachment = await store.import(source('IMG_0412.JPG', photo));

    final bytes = stored(attachment);
    expect(attachment.name, 'IMG_0412.JPG');
    expect(attachment.fileName, endsWith('.jpg'));
    expect(attachment.sizeBytes, bytes.length, reason: 'the size of the file kept, for the free-file count');
    expect(bytes.length, lessThan(photo.length ~/ 2));
    final image = img.decodeJpg(bytes)!;
    expect((image.width, image.height), (1875, 2500), reason: 'turned the way it was taken');
    expect(image.getPixel(image.width ~/ 2, 10).r, greaterThan(150), reason: 'red at the top');
    expect(image.getPixel(image.width ~/ 2, image.height - 10).b, greaterThan(150), reason: 'blue at the bottom');
    expect(image.exif.imageIfd.hasOrientation, isFalse, reason: 'nothing to turn it again');
    expect(img.decodeJpgExif(bytes)?.gpsIfd.hasGPSLatitude ?? false, isFalse, reason: 'no location');
  });

  test('PDFs, PNG screenshots, GIFs and small photos come in byte for byte', () async {
    final pdf = [...'%PDF-1.7\n'.codeUnits, ...List.filled(2000000, 0x41)];
    final screenshot = img.encodePng(img.Image(width: 1290, height: 2796, numChannels: 3));
    final wide = img.encodePng(img.Image(width: 3000, height: 1200, numChannels: 3));
    final gif = img.encodeGif(img.Image(width: 64, height: 64));
    final small = img.encodeJpg(img.Image(width: 1600, height: 1200), quality: 100);
    final files = {
      'Park tickets.pdf': pdf,
      'IMG_0413.PNG': screenshot,
      'Panorama.png': wide,
      'map.gif': gif,
      'From the chat.jpg': small,
    };
    expect(small.length, lessThan(PhotoShrink.largeBytes));

    for (final MapEntry(key: name, value: bytes) in files.entries) {
      final attachment = await store.import(source(name, bytes));
      expect(stored(attachment), bytes, reason: name);
      expect(attachment.name, name);
      expect(attachment.sizeBytes, bytes.length, reason: name);
      expect(attachment.extension, name.split('.').last.toLowerCase(), reason: name);
    }
  });

  test('a photo that can\'t be read is kept as it came', () async {
    final broken = [0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(PhotoShrink.largeBytes + 1, 0)];

    final attachment = await store.import(source('IMG_0414.jpg', broken));

    expect(stored(attachment), broken);
    expect(attachment.sizeBytes, broken.length);
  });

  test('one photo kept on several bookings is the same file, so it counts once', () async {
    final path = source('Confirmation.jpg', photo);

    final copies = [for (var i = 0; i < 3; i++) await store.import(path)];

    expect(copies.map((a) => a.fileName).toSet(), hasLength(3), reason: 'a file for each booking');
    expect(copies.map((a) => (a.name, a.sizeBytes)).toSet(), hasLength(1));
    expect(stored(copies[2]), stored(copies[0]));
    expect(ticketFilesIn(null, also: copies), 1);
  });

  test(
    'a HEIC becomes a JPEG, so every phone can show it',
    () async {
      final heic = File('test/fixtures/photo_4032x3024.heic').readAsBytesSync();

      final attachment = await store.import(source('IMG_0415.HEIC', heic), name: 'IMG_0415.HEIC');

      expect(attachment.name, 'IMG_0415.jpg');
      expect(attachment.fileName, endsWith('.jpg'));
      expect(attachment.isImage, isTrue);
      final image = img.decodeJpg(stored(attachment))!;
      expect((image.width, image.height), (2500, 1875));
      expect(attachment.sizeBytes, stored(attachment).length);
    },
    skip: Platform.isMacOS ? false : 'HEIC is read by the platform: ImageIO here, as on an iPhone',
  );
}
