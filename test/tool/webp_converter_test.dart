import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/image_header.dart';

import '../../tool/src/pack_builder.dart';
import '../../tool/src/webp_converter.dart';
import '../support/png_fixture.dart';

void main() {
  final hasCwebp = Process.runSync('which', ['cwebp']).exitCode == 0;

  late Directory temp;
  late Directory source;
  late Directory originals;
  const manifest = '''{
  "schemaVersion": 1,
  "packId": "country_xx",
  "version": 1,
  "assets": [
    { "file": "icons/calendar.png", "kind": "icon", "name": "calendar", "width": 1024, "height": 1024 },
    { "file": "common/kept.webp", "kind": "common", "name": "pill", "width": 10, "height": 10 }
  ]
}
''';

  setUp(() {
    temp = Directory.systemTemp.createTempSync('webp_');
    source = Directory(p.join(temp.path, 'country_xx'))..createSync();
    originals = Directory(p.join(temp.path, 'originals'));
    File(p.join(source.path, 'pack.json')).writeAsStringSync(manifest);
    File(p.join(source.path, 'icons', 'calendar.png'))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(windowedPng(width: 1024, height: 1024));
  });

  tearDown(() => temp.deleteSync(recursive: true));

  test(
    'PNGs become same-size WebPs; the manifest changes only their names; originals move aside',
    () async {
      final report = await convertSourceToWebp(source: source, originals: originals);
      expect(report.converted, 1);
      expect(report.bytesAfter, lessThan(report.bytesBefore));

      final webp = File(p.join(source.path, 'icons', 'calendar.webp'));
      final info = readImageInfo(webp.readAsBytesSync())!;
      expect((info.type, info.width, info.height), (ImageType.webp, 1024, 1024));
      expect(File(p.join(source.path, 'icons', 'calendar.png')).existsSync(), isFalse);
      expect(File(p.join(originals.path, 'country_xx', 'icons', 'calendar.png')).existsSync(), isTrue);
      expect(
        File(p.join(source.path, 'pack.json')).readAsStringSync(),
        manifest.replaceAll('"icons/calendar.png"', '"icons/calendar.webp"'),
      );
    },
    skip: hasCwebp ? false : 'cwebp is not installed',
  );

  test('a dry run changes nothing', () async {
    final report = await convertSourceToWebp(source: source, originals: originals, dryRun: true);
    expect(report.converted, 1);
    expect(File(p.join(source.path, 'icons', 'calendar.png')).existsSync(), isTrue);
    expect(File(p.join(source.path, 'pack.json')).readAsStringSync(), manifest);
  });

  test('a declared picture that is missing stops it', () async {
    File(p.join(source.path, 'icons', 'calendar.png')).deleteSync();
    expect(() => convertSourceToWebp(source: source, originals: originals), throwsA(isA<PublishException>()));
  });
}
