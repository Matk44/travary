import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/image_header.dart';

import '../../tool/src/bundled_art_converter.dart';
import '../../tool/src/pack_builder.dart';
import '../support/png_fixture.dart';

void main() {
  final hasCwebp = Process.runSync('which', ['cwebp']).exitCode == 0;

  late Directory project;
  late Directory masters;

  File put(String path, List<int> bytes) => File(p.join(project.path, path))
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  setUp(() {
    project = Directory.systemTemp.createTempSync('bundled_webp_');
    masters = Directory(p.join(project.path, 'art_masters', 'bundled'));
    File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync('''
name: example
flutter:
  uses-material-design: true
  # Card artwork.
  assets:
    - assets/onboarding/
    - assets/art/common/
    - assets/art/icons/
    - assets/art/lone.png
  fonts:
    - family: Example
''');
    put('assets/art/common/linen.png', windowedPng());
    put('assets/art/icons/dining.png', windowedPng(width: 32, height: 32));
    put('assets/art/lone.png', windowedPng(width: 16, height: 16));
    put('assets/art/common/kept.webp', [1, 2, 3]); // already WebP: left alone
    put('assets/branding/app_icon.png', windowedPng()); // not bundled: left alone
  });

  tearDown(() => project.deleteSync(recursive: true));

  test('the pubspec says what is bundled', () {
    expect(bundledAssetEntries(File(p.join(project.path, 'pubspec.yaml'))), [
      'assets/onboarding/',
      'assets/art/common/',
      'assets/art/icons/',
      'assets/art/lone.png',
    ]);
  });

  test(
    'bundled PNGs become same-size WebPs with their transparency exact; the masters move aside',
    () async {
      final before = windowedPng().length;
      final report = await convertBundledArtToWebp(project: project, masters: masters);
      expect(report.files, ['assets/art/common/linen.png', 'assets/art/icons/dining.png', 'assets/art/lone.png']);
      expect(
        report.bytesBefore,
        before + windowedPng(width: 32, height: 32).length + windowedPng(width: 16, height: 16).length,
      );

      final linen = File(p.join(project.path, 'assets', 'art', 'common', 'linen.webp'));
      final info = readImageInfo(linen.readAsBytesSync())!;
      expect((info.type, info.width, info.height), (ImageType.webp, 64, 48));
      expect(File(p.join(project.path, 'assets', 'art', 'lone.webp')).existsSync(), isTrue);

      // The window is still see-through, the shadow still half, the paper still solid.
      final alpha = webpAlpha(linen);
      for (var y = 0; y < 48; y++) {
        for (var x = 0; x < 64; x++) {
          expect(alpha[y * 64 + x], pixelAt(x, y, 64, 48).$4, reason: 'alpha at $x,$y');
        }
      }

      // Nothing bundles a PNG any more; the masters are where the command says.
      expect(File(p.join(project.path, 'assets', 'art', 'common', 'linen.png')).existsSync(), isFalse);
      expect(File(p.join(masters.path, 'art', 'common', 'linen.png')).readAsBytesSync(), windowedPng());
      expect(File(p.join(masters.path, 'art', 'icons', 'dining.png')).existsSync(), isTrue);
      expect(File(p.join(masters.path, 'art', 'lone.png')).existsSync(), isTrue);

      // Left alone: a picture that is already WebP, and a PNG that isn't bundled.
      expect(File(p.join(project.path, 'assets', 'art', 'common', 'kept.webp')).readAsBytesSync(), [1, 2, 3]);
      expect(File(p.join(project.path, 'assets', 'branding', 'app_icon.png')).existsSync(), isTrue);
      expect(File(p.join(project.path, 'assets', 'branding', 'app_icon.webp')).existsSync(), isFalse);
    },
    skip: hasCwebp ? false : 'cwebp is not installed',
  );

  test('a second run has nothing left to do', () async {
    if (!hasCwebp) return;
    await convertBundledArtToWebp(project: project, masters: masters);
    final again = await convertBundledArtToWebp(project: project, masters: masters);
    expect(again.files, isEmpty);
  });

  test('a dry run changes nothing', () async {
    final report = await convertBundledArtToWebp(project: project, masters: masters, dryRun: true);
    expect(report.files, hasLength(3));
    expect(File(p.join(project.path, 'assets', 'art', 'common', 'linen.png')).existsSync(), isTrue);
    expect(File(p.join(project.path, 'assets', 'art', 'common', 'linen.webp')).existsSync(), isFalse);
    expect(masters.existsSync(), isFalse);
  });

  test('a WebP already beside a PNG, or a master already in place, stops it', () async {
    put('assets/art/icons/dining.webp', [1]);
    await expectLater(convertBundledArtToWebp(project: project, masters: masters), throwsA(isA<PublishException>()));
    // Refused before anything was converted.
    expect(File(p.join(project.path, 'assets', 'art', 'common', 'linen.png')).existsSync(), isTrue);
    expect(File(p.join(project.path, 'assets', 'art', 'common', 'linen.webp')).existsSync(), isFalse);
    File(p.join(project.path, 'assets', 'art', 'icons', 'dining.webp')).deleteSync();

    File(p.join(masters.path, 'art', 'lone.png'))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync([1]);
    await expectLater(convertBundledArtToWebp(project: project, masters: masters), throwsA(isA<PublishException>()));
  });

  test(
    'a revised PNG dropped beside its picture is refused, unless it is to replace it',
    () async {
      await convertBundledArtToWebp(project: project, masters: masters);
      final revised = windowedPng(width: 32, height: 32);
      put('assets/art/common/linen.png', revised);
      await expectLater(convertBundledArtToWebp(project: project, masters: masters), throwsA(isA<PublishException>()));

      final report = await convertBundledArtToWebp(project: project, masters: masters, replace: true);
      expect(report.files, ['assets/art/common/linen.png']);
      final linen = File(p.join(project.path, 'assets', 'art', 'common', 'linen.webp'));
      final info = readImageInfo(linen.readAsBytesSync())!;
      expect((info.width, info.height), (32, 32));
      expect(File(p.join(masters.path, 'art', 'common', 'linen.png')).readAsBytesSync(), revised);
      expect(File(p.join(project.path, 'assets', 'art', 'common', 'linen.png')).existsSync(), isFalse);
    },
    skip: hasCwebp ? false : 'cwebp is not installed',
  );

  group('the app\'s real bundled art', () {
    test('has no PNG: new art goes through `dart run tool/art_packs.dart bundled-webp`', () {
      final pngs = <String>[];
      for (final entry in bundledAssetEntries(File('pubspec.yaml'))) {
        if (entry.endsWith('/')) {
          final folder = Directory(entry);
          if (!folder.existsSync()) continue;
          pngs.addAll([
            for (final file in folder.listSync().whereType<File>())
              if (file.path.toLowerCase().endsWith('.png')) file.path,
          ]);
        } else if (entry.toLowerCase().endsWith('.png')) {
          pngs.add(entry);
        }
      }
      expect(pngs, isEmpty, reason: 'bundled art ships as WebP (assets/art/README.md)');
    });

    test('every master has its WebP, the same size', () {
      final masters = Directory('art_masters/bundled');
      expect(masters.existsSync(), isTrue);
      var count = 0;
      for (final master in masters.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.png'))) {
        final relative = p.relative(master.path, from: masters.path);
        final webp = File(p.join('assets', '${relative.substring(0, relative.length - 4)}.webp'));
        expect(webp.existsSync(), isTrue, reason: '$relative has no bundled WebP');
        final was = readImageInfo(master.readAsBytesSync())!;
        final now = readImageInfo(webp.readAsBytesSync())!;
        expect((now.type, now.width, now.height), (ImageType.webp, was.width, was.height), reason: relative);
        count++;
      }
      expect(count, greaterThan(90));
    });
  });
}
