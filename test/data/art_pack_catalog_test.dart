import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/data/image_header.dart';
import 'package:travary/domain/domain.dart';

import '../support/art_pack_fixtures.dart';

Map<String, Object?> packJson({
  String id = 'city_jp_kyoto',
  int version = 3,
  Map<String, Object?>? selectors,
  Map<String, Object?>? archive,
  Object? priority = 400,
  Object? minAppBuild = 1,
}) => {
  'id': id,
  'version': version,
  'priority': priority,
  'selectors':
      selectors ??
      {
        'countryCodes': ['JP'],
        'regions': ['kansai'],
        'cities': ['kyoto'],
        'themes': ['urban_heritage'],
        'subjects': ['gardens', 'landmark', 'train', 'bistro'],
      },
  'archive':
      archive ??
      {
        'storagePath': 'art-packs/$id/$version/pack.zip',
        'sha256': 'a' * 64,
        'compressedBytes': 12345678,
        'uncompressedBytes': 34567890,
        'fileCount': 48,
      },
  'minAppBuild': minAppBuild,
};

List<int> catalog({
  List<Object?>? packs,
  Object? schemaVersion = 1,
  Object? catalogVersion = 12,
  Object? generatedAt = '2027-04-01T00:00:00Z',
}) => utf8.encode(
  jsonEncode({
    'schemaVersion': schemaVersion,
    'catalogVersion': catalogVersion,
    'generatedAt': generatedAt,
    'packs': packs ?? [packJson()],
  }),
);

void main() {
  group('catalog', () {
    test('parses the documented example', () {
      final parsed = ArtPackCatalog.parse(catalog(), appBuild: 1);
      expect(parsed.catalogVersion, 12);
      expect(parsed.generatedAt, DateTime.utc(2027, 4, 1));
      final pack = parsed.packs.single;
      expect(pack.id, 'city_jp_kyoto');
      expect(pack.version, 3);
      expect(pack.ref.priority, 400);
      expect(pack.ref.selectors.scope, ArtPackScope.city);
      expect(pack.ref.selectors.themes, [ExperienceTheme.urbanHeritage]);
      expect(pack.archive.storagePath, 'art-packs/city_jp_kyoto/3/pack.zip');
      expect(pack.archive.fileCount, 48);
      expect(
        ArtPackCatalog.parse(utf8.encode(jsonEncode(parsed.toJson())), appBuild: 1).packs.single.toJson(),
        pack.toJson(),
      );
    });

    test('rejects the whole catalog when core fields are malformed', () {
      void rejects(List<int> bytes, String why) =>
          expect(() => ArtPackCatalog.parse(bytes, appBuild: 1), throwsA(isA<ArtPackFormatException>()), reason: why);
      rejects(utf8.encode('not json'), 'not JSON');
      rejects(utf8.encode('[]'), 'not an object');
      rejects(catalog(schemaVersion: 2), 'unknown schema');
      rejects(catalog(schemaVersion: '1'), 'schema as a string');
      rejects(catalog(catalogVersion: 0), 'version not positive');
      rejects(catalog(catalogVersion: 1.5), 'version not an integer');
      rejects(catalog(generatedAt: 'yesterday'), 'bad date');
      rejects(
        utf8.encode(
          jsonEncode({'schemaVersion': 1, 'catalogVersion': 1, 'generatedAt': '2027-01-01T00:00:00Z', 'packs': 'x'}),
        ),
        'packs not a list',
      );
      rejects(catalog(packs: [packJson(), packJson()]), 'duplicate IDs');
      rejects(catalog(packs: [packJson(), packJson(version: 4)]), 'duplicate IDs, different versions');
    });

    test('rejects an oversized catalog', () {
      final padding = List.filled(ArtPackLimits.maxCatalogBytes, 0x20);
      expect(
        () => ArtPackCatalog.parse([...catalog(), ...padding], appBuild: 1),
        throwsA(isA<ArtPackFormatException>().having((e) => e.message, 'message', contains('2 MiB'))),
      );
    });

    test('ignores only the invalid pack', () {
      final invalid = <Map<String, Object?>>[
        packJson(id: 'Bad-ID'),
        packJson(id: 'bad_version', version: 0),
        packJson(id: 'bad_priority', priority: -1),
        packJson(
          id: 'bad_path',
          archive: {
            'storagePath': 'art-packs/other/3/pack.zip',
            'sha256': 'a' * 64,
            'compressedBytes': 1,
            'uncompressedBytes': 1,
            'fileCount': 2,
          },
        ),
        packJson(
          id: 'escape',
          archive: {
            'storagePath': 'art-packs/escape/3/../../x.zip',
            'sha256': 'a' * 64,
            'compressedBytes': 1,
            'uncompressedBytes': 1,
            'fileCount': 2,
          },
        ),
        packJson(
          id: 'upper_sha',
          archive: {
            'storagePath': 'art-packs/upper_sha/3/pack.zip',
            'sha256': 'A' * 64,
            'compressedBytes': 1,
            'uncompressedBytes': 1,
            'fileCount': 2,
          },
        ),
        packJson(
          id: 'short_sha',
          archive: {
            'storagePath': 'art-packs/short_sha/3/pack.zip',
            'sha256': 'a' * 63,
            'compressedBytes': 1,
            'uncompressedBytes': 1,
            'fileCount': 2,
          },
        ),
        packJson(
          id: 'too_big',
          archive: {
            'storagePath': 'art-packs/too_big/3/pack.zip',
            'sha256': 'a' * 64,
            'compressedBytes': ArtPackLimits.maxCompressedBytes + 1,
            'uncompressedBytes': 1,
            'fileCount': 2,
          },
        ),
        packJson(
          id: 'too_wide',
          archive: {
            'storagePath': 'art-packs/too_wide/3/pack.zip',
            'sha256': 'a' * 64,
            'compressedBytes': 1,
            'uncompressedBytes': ArtPackLimits.maxUncompressedBytes + 1,
            'fileCount': 2,
          },
        ),
        packJson(
          id: 'too_many',
          archive: {
            'storagePath': 'art-packs/too_many/3/pack.zip',
            'sha256': 'a' * 64,
            'compressedBytes': 1,
            'uncompressedBytes': 1,
            'fileCount': ArtPackLimits.maxFileCount + 1,
          },
        ),
        packJson(
          id: 'bad_theme',
          selectors: {
            'themes': ['vaporwave'],
          },
        ),
        packJson(
          id: 'bad_subject',
          selectors: {
            'themes': ['alpine'],
            'subjects': ['spaceship'],
          },
        ),
        packJson(
          id: 'bad_country',
          selectors: {
            'countryCodes': ['UK'],
          },
        ),
        packJson(
          id: 'bad_slug',
          selectors: {
            'countryCodes': ['JP'],
            'cities': ['Kyoto'],
          },
        ),
        packJson(
          id: 'city_no_country',
          selectors: {
            'cities': ['kyoto'],
          },
        ),
        packJson(
          id: 'nothing',
          selectors: {
            'subjects': ['train'],
          },
        ),
        packJson(id: 'bad_min_build', minAppBuild: 0),
      ];
      final parsed = ArtPackCatalog.parse(
        catalog(
          packs: [
            ...invalid,
            packJson(id: 'good'),
          ],
        ),
        appBuild: 1,
      );
      expect(parsed.packs.map((p) => p.id), ['good']);
      expect(parsed.ignored, hasLength(invalid.length));
    });

    test('ignores packs that need a newer app build', () {
      final parsed = ArtPackCatalog.parse(
        catalog(
          packs: [
            packJson(id: 'future', minAppBuild: 7),
            packJson(id: 'now'),
          ],
        ),
        appBuild: 6,
      );
      expect(parsed.packs.map((p) => p.id), ['now']);
      expect(
        ArtPackCatalog.parse(catalog(packs: [packJson(id: 'future', minAppBuild: 7)]), appBuild: 7).packs,
        hasLength(1),
      );
    });
  });

  group('pack paths', () {
    test('only plain images in art folders, and pack.json', () {
      for (final ok in [
        'pack.json',
        'dining/grill_01.png',
        'icons/dining.webp',
        'common/linen.jpg',
        'note/a-b_c.jpeg',
      ]) {
        expect(validateArtPackPath(ok), ok);
      }
      for (final bad in [
        '../pack.json',
        'dining/../../etc.png',
        '/abs/dining.png',
        r'dining\grill.png',
        'dining//grill.png',
        './dining/a.png',
        'dining/./a.png',
        'dining/',
        '',
        'fonts/a.png',
        'dining/sub/a.png',
        'dining/a.svg',
        'dining/a.html',
        'dining/a.js',
        'dining/a.ttf',
        'dining/a.so',
        'dining/A.png',
        'dining/.hidden.png',
        'C:/dining/a.png',
        'pack.json/x.png',
        'dining/a b.png',
      ]) {
        expect(() => validateArtPackPath(bad), throwsA(isA<ArtPackFormatException>()), reason: bad);
      }
    });
  });

  group('pack.json', () {
    Map<String, Object?> manifest({List<Object?>? assets, String id = 'city_jp_kyoto', int version = 3}) => {
      'schemaVersion': 1,
      'packId': id,
      'version': version,
      'assets':
          assets ??
          [
            {
              'file': 'transport/urban_heritage_train_01_scene.webp',
              'kind': 'transport',
              'theme': 'urban_heritage',
              'subject': 'train',
              'group': 'urban_heritage_train_01',
              'format': 'scene',
              'width': 1536,
              'height': 1024,
            },
          ],
    };
    PackManifest parse(Map<String, Object?> json, {String? id, int? version}) =>
        PackManifest.parse(utf8.encode(jsonEncode(json)), expectedId: id, expectedVersion: version);
    void rejects(Map<String, Object?> json, String why, {String? id, int? version}) => expect(
      () => parse(json, id: id, version: version),
      throwsA(isA<ArtPackFormatException>()),
      reason: why,
    );

    test('parses the documented example', () {
      final parsed = parse(manifest(), id: 'city_jp_kyoto', version: 3);
      final asset = parsed.assets.single as PackCardArt;
      expect(
        (asset.kind, asset.theme, asset.subject, asset.group, asset.format),
        (BookingKind.transport, ExperienceTheme.urbanHeritage, 'train', 'urban_heritage_train_01', 'scene'),
      );
      expect(
        parse({
          ...manifest(),
          'assets': [
            ...manifest()['assets']! as List,
            {'file': 'icons/train.png', 'kind': 'icon', 'name': 'train', 'width': 64, 'height': 64},
          ],
        }).assets.last,
        isA<PackSharedArt>(),
      );
    });

    test('requires the exact pack ID and version', () {
      rejects(manifest(), 'wrong id', id: 'city_jp_tokyo');
      rejects(manifest(), 'wrong version', version: 4);
    });

    test('checks every asset against the vocabulary', () {
      Map<String, Object?> card(Map<String, Object?> changes) => manifest(
        assets: [
          {
            'file': 'dining/x_01.png',
            'kind': 'dining',
            'theme': 'any',
            'subject': 'pizza',
            'group': 'x_01',
            'format': 'both',
            'width': 10,
            'height': 10,
            ...changes,
          },
        ],
      );
      expect(parse(card({})).assets.single, isA<PackCardArt>().having((a) => a.theme, 'theme', isNull));
      rejects(card({'kind': 'spaceship'}), 'unknown kind');
      rejects(card({'kind': 'stay'}), 'kind vs folder');
      rejects(card({'theme': 'vaporwave'}), 'unknown theme');
      rejects(card({'theme': 'tropical'}), 'legacy names are for bundled files only');
      rejects(card({'subject': 'train'}), 'subject of another kind');
      rejects(card({'group': 'Bad Group'}), 'bad group');
      rejects(card({'format': 'poster'}), 'bad format');
      rejects(card({'width': 0}), 'bad width');
      rejects(card({'height': 9000}), 'too tall');
      rejects(card({'file': 'dining/x.svg'}), 'SVG');
      rejects(card({'file': '../dining/x.png'}), 'zip slip');
      rejects(
        manifest(
          assets: [
            {'file': 'icons/x.png', 'kind': 'common', 'name': 'x', 'width': 1, 'height': 1},
          ],
        ),
        'common outside common/',
      );
      rejects(manifest(assets: []), 'no images');
      rejects(
        manifest(
          assets: [
            {
              'file': 'dining/a.png',
              'kind': 'dining',
              'theme': 'any',
              'subject': 'pizza',
              'group': 'g',
              'format': 'scene',
              'width': 2,
              'height': 1,
            },
            {
              'file': 'dining/a.png',
              'kind': 'dining',
              'theme': 'any',
              'subject': 'pizza',
              'group': 'h',
              'format': 'scene',
              'width': 2,
              'height': 1,
            },
          ],
        ),
        'a file declared twice',
      );
      rejects(
        manifest(
          assets: [
            {
              'file': 'dining/a.png',
              'kind': 'dining',
              'theme': 'any',
              'subject': 'pizza',
              'group': 'g',
              'format': 'scene',
              'width': 2,
              'height': 1,
            },
            {
              'file': 'dining/b.png',
              'kind': 'dining',
              'theme': 'any',
              'subject': 'pizza',
              'group': 'g',
              'format': 'both',
              'width': 2,
              'height': 1,
            },
          ],
        ),
        'two scenes in one group',
      );
    });

    test('rejects the wrong schema or oversize manifests', () {
      rejects({...manifest(), 'schemaVersion': 2}, 'schema');
      expect(
        () => PackManifest.parse(List.filled(ArtPackLimits.maxManifestBytes + 1, 0x20)),
        throwsA(isA<ArtPackFormatException>()),
      );
    });
  });

  group('image headers', () {
    test('reads PNG sizes and sniffs real formats', () {
      final png = solidPng(37, 21);
      expect(readImageInfo(png).toString(), 'png 37x21');
      expect(sniffImageType(png), ImageType.png);
      expect(sniffImageType([0xFF, 0xD8, 0xFF, 0xE0]), ImageType.jpeg);
      expect(sniffImageType(ascii.encode('RIFF\x00\x00\x00\x00WEBPVP8 ')), ImageType.webp);
      expect(sniffImageType(utf8.encode('<svg xmlns="http://www.w3.org/2000/svg"/>')), isNull);
      expect(sniffImageType(utf8.encode('#!/bin/sh')), isNull);
      expect(ImageType.forExtension('JPEG'), ImageType.jpeg);
      expect(ImageType.forExtension('svg'), isNull);
    });

    test('reads JPEG frame sizes past other segments', () {
      final jpeg = Uint8List.fromList([
        0xFF, 0xD8, // SOI
        0xFF, 0xE0, 0x00, 0x06, 0x4A, 0x46, 0x49, 0x46, // APP0, length 6
        0xFF, 0xDB, 0x00, 0x04, 0x00, 0x00, // DQT, length 4
        0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x02, 0x58, 0x03, 0x20, 0x03, 0x01, 0x22, 0x00, // SOF0: 600 high, 800 wide
      ]);
      expect(readImageInfo(jpeg).toString(), 'jpeg 800x600');
      expect(readImageInfo(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9])), isNull);
    });

    test('reads all three WebP variants', () {
      Uint8List webp(String chunk, List<int> body) => Uint8List.fromList([
        ...ascii.encode('RIFF'),
        0,
        0,
        0,
        0,
        ...ascii.encode('WEBP'),
        ...ascii.encode(chunk),
        0,
        0,
        0,
        0,
        ...body,
        ...List.filled(16, 0),
      ]);
      // Lossy: frame tag (3), start code, then 14-bit sizes (1536, 1024).
      expect(
        readImageInfo(webp('VP8 ', [0, 0, 0, 0x9D, 0x01, 0x2A, 0x00, 0x06, 0x00, 0x04])).toString(),
        'webp 1536x1024',
      );
      // Lossless: signature, then width-1 and height-1 in 14 bits each (100x50).
      final bits = (100 - 1) | ((50 - 1) << 14);
      expect(
        readImageInfo(
          webp('VP8L', [0x2F, bits & 0xFF, (bits >> 8) & 0xFF, (bits >> 16) & 0xFF, (bits >> 24) & 0xFF]),
        ).toString(),
        'webp 100x50',
      );
      // Extended: flags (4), then 24-bit width-1 and height-1 (1024x1024).
      expect(
        readImageInfo(webp('VP8X', [0, 0, 0, 0, 0xFF, 0x03, 0x00, 0xFF, 0x03, 0x00])).toString(),
        'webp 1024x1024',
      );
    });
  });
}
