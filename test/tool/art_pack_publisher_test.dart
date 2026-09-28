import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';

import '../../tool/src/bucket.dart';
import '../../tool/src/catalog_editor.dart';
import '../../tool/src/pack_builder.dart';
import '../../tool/src/publisher.dart';
import '../support/art_pack_fixtures.dart';

/// Records every bucket call.
class FakeBucket implements ArtPackBucket {
  final objects = <String, Uint8List>{};
  final calls = <String>[];

  @override
  String get label => 'fake';

  @override
  Future<Uint8List?> read(String path) async {
    calls.add('read $path');
    return objects[path];
  }

  @override
  Future<bool> exists(String path) async {
    calls.add('exists $path');
    return objects.containsKey(path);
  }

  @override
  Future<void> write(String path, List<int> bytes, {required String contentType}) async {
    calls.add('write $path');
    objects[path] = Uint8List.fromList(bytes);
  }
}

void main() {
  late Directory temp;
  final now = DateTime.utc(2027, 4, 1);

  setUp(() async => temp = await Directory.systemTemp.createTemp('travary_publisher'));
  tearDown(() => temp.delete(recursive: true));

  Future<Directory> source({
    String id = 'theme_themepark',
    int version = 1,
    String parent = 'src',
    List<TestAsset>? assets,
  }) => writePackSource(
    Directory(p.join(temp.path, parent)),
    id: id,
    version: version,
    assets:
        assets ??
        const [
          TestAsset.card(
            'dining/themepark_grill_01_scene.png',
            kind: 'dining',
            theme: 'themepark',
            subject: 'grill',
            group: 'themepark_grill_01',
            format: 'scene',
          ),
          TestAsset.card(
            'dining/themepark_grill_01_vignette.png',
            kind: 'dining',
            theme: 'themepark',
            subject: 'grill',
            group: 'themepark_grill_01',
            format: 'vignette',
            width: 16,
            height: 16,
          ),
          TestAsset.shared('icons/dining.png', role: 'icon', name: 'dining'),
        ],
  );

  Future<void> refuses(Future<Object?> Function() action, Pattern message) =>
      expectLater(action(), throwsA(isA<PublishException>().having((e) => e.message, 'message', contains(message))));

  group('building', () {
    test('archives are deterministic and hashes reproducible', () async {
      final one = await buildArtPack(await source(parent: 'a'));
      final two = await buildArtPack(await source(parent: 'b'));
      expect(two.archive, one.archive);
      expect(two.entry.archive.sha256, one.entry.archive.sha256);
      expect(one.entry.archive.sha256, sha256.convert(one.archive).toString());
      expect(one.entry.archive.compressedBytes, one.archive.length);
      expect(one.entry.archive.fileCount, 4, reason: 'pack.json and three images');
      expect(one.entry.archive.storagePath, 'art-packs/theme_themepark/1/pack.zip');
      // Touching the files changes nothing: no timestamps in the archive.
      final dir = Directory(p.join(temp.path, 'a', 'theme_themepark-1'));
      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        file.setLastModifiedSync(DateTime(2031));
      }
      expect((await buildArtPack(dir)).entry.archive.sha256, one.entry.archive.sha256);
    });

    test('the seed pack builds', () async {
      final seed = await buildArtPack(Directory('art_packs/sources/seed_themepark'));
      expect(seed.entry.id, 'seed_themepark');
      expect(seed.manifest.assets, hasLength(4));
      expect(seed.entry.ref.selectors.themes.single.wireName, 'themepark');
    });

    test('refuses undeclared, unexpected or linked files', () async {
      final extra = await source(parent: 'extra');
      File(p.join(extra.path, 'dining', 'stray.png')).writeAsBytesSync(solidPng(4, 4));
      await refuses(() => buildArtPack(extra), 'dining/stray.png is not declared');

      final dsStore = await source(parent: 'ds');
      File(p.join(dsStore.path, '.DS_Store')).writeAsBytesSync([0]);
      await refuses(() => buildArtPack(dsStore), 'delete .DS_Store');

      final folder = await source(parent: 'folder');
      Directory(p.join(folder.path, 'fonts')).createSync();
      await refuses(() => buildArtPack(folder), 'Unexpected folder fonts/');

      final linked = await source(parent: 'linked');
      final real = File(p.join(temp.path, 'outside.png'))..writeAsBytesSync(solidPng(16, 16));
      File(p.join(linked.path, 'dining', 'themepark_grill_01_vignette.png')).deleteSync();
      Link(p.join(linked.path, 'dining', 'themepark_grill_01_vignette.png')).createSync(real.path);
      await refuses(() => buildArtPack(linked), 'symlink');
    });

    test('inspects every image\'s real format and size', () async {
      final wrongSize = await source(parent: 'size');
      File(p.join(wrongSize.path, 'icons', 'dining.png')).writeAsBytesSync(solidPng(20, 16));
      await refuses(() => buildArtPack(wrongSize), '20x16; pack.json says 16x16');

      final fake = await source(parent: 'fake');
      File(p.join(fake.path, 'icons', 'dining.png')).writeAsStringSync('<svg xmlns="http://www.w3.org/2000/svg"/>');
      await refuses(() => buildArtPack(fake), 'not a valid png');

      final portrait = await source(
        parent: 'portrait',
        assets: const [
          TestAsset.card(
            'dining/tall_01_scene.png',
            kind: 'dining',
            group: 'tall_01',
            format: 'scene',
            width: 10,
            height: 20,
          ),
        ],
      );
      await refuses(() => buildArtPack(portrait), 'must be landscape');

      final missing = await source(parent: 'missing');
      File(p.join(missing.path, 'icons', 'dining.png')).deleteSync();
      await refuses(() => buildArtPack(missing), 'declared but missing');
    });

    test('validates pack.json and catalog-entry.json with the app\'s vocabulary', () async {
      final badTheme = await source(
        parent: 'theme',
        assets: const [TestAsset.card('dining/x_01.png', kind: 'dining', theme: 'vaporwave', group: 'x_01')],
      );
      await refuses(() => buildArtPack(badTheme), 'unknown theme');

      final entry = await source(parent: 'entry');
      File(p.join(entry.path, catalogEntryName)).writeAsStringSync(
        jsonEncode({
          'priority': 1,
          'selectors': {
            'themes': ['themepark'],
          },
          'owner': 'me',
        }),
      );
      await refuses(() => buildArtPack(entry), 'unknown fields owner');

      File(p.join(entry.path, catalogEntryName)).writeAsStringSync(
        jsonEncode({
          'priority': 1,
          'selectors': {
            'cities': ['kyoto'],
          },
        }),
      );
      await refuses(() => buildArtPack(entry), 'must name their country');
    });
  });

  group('the catalog', () {
    test('adds packs, bumps versions and keeps IDs unique', () async {
      final v1 = await buildArtPack(await source(parent: 'v1'));
      final first = addToCatalog(null, v1, now: now);
      expect(first.catalog.catalogVersion, 1);
      expect(first.catalog.packs.single.id, 'theme_themepark');

      final again = addToCatalog(first.catalog, v1, now: now);
      expect(again.changed, isFalse);

      final v2 = await buildArtPack(await source(version: 2, parent: 'v2'));
      final second = addToCatalog(first.catalog, v2, now: now);
      expect(second.catalog.catalogVersion, 2);
      expect(second.catalog.packs.single.version, 2);

      final other = await buildArtPack(await source(id: 'theme_alpine_extra', parent: 'other'));
      final third = addToCatalog(second.catalog, other, now: now);
      expect(third.catalog.packs.map((p) => p.id), ['theme_alpine_extra', 'theme_themepark']);
      final reread = readCatalogStrict(encodeCatalog(third.catalog));
      expect(reread.packs.map((p) => p.toJson()), third.catalog.packs.map((p) => p.toJson()));
    });

    test('refuses decreasing versions and changed contents under the same version', () async {
      final v2 = await buildArtPack(await source(version: 2, parent: 'v2'));
      final catalog = addToCatalog(null, v2, now: now).catalog;
      final v1 = await buildArtPack(await source(parent: 'v1'));
      expect(
        () => addToCatalog(catalog, v1, now: now),
        throwsA(isA<PublishException>().having((e) => e.message, 'm', contains('older'))),
      );

      final changed = await buildArtPack(
        await source(
          version: 2,
          parent: 'changed',
          assets: const [TestAsset.shared('icons/flight.png', role: 'icon', name: 'flight')],
        ),
      );
      expect(
        () => addToCatalog(catalog, changed, now: now),
        throwsA(isA<PublishException>().having((e) => e.message, 'm', contains('bump its version'))),
      );
    });

    test('refuses a catalog with duplicate IDs or invalid packs', () async {
      final built = await buildArtPack(await source());
      final duplicated = catalogBytes([built.entry, built.entry]);
      expect(
        () => readCatalogStrict(duplicated),
        throwsA(isA<PublishException>().having((e) => e.message, 'm', contains('twice'))),
      );
      final json = jsonDecode(utf8.decode(catalogBytes([built.entry]))) as Map<String, Object?>;
      ((json['packs']! as List).single as Map)['priority'] = -5;
      expect(
        () => readCatalogStrict(utf8.encode(jsonEncode(json))),
        throwsA(isA<PublishException>().having((e) => e.message, 'm', contains('invalid packs'))),
      );
    });
  });

  group('publishing', () {
    late File catalogFile;
    late Directory out;

    setUp(() async {
      catalogFile = File(p.join(temp.path, 'catalog.json'));
      out = Directory(p.join(temp.path, 'out'));
      await buildAndRecord(
        source: await source(),
        catalogFile: catalogFile,
        outDir: out,
        dryRun: false,
        now: now,
        log: (_) {},
      );
    });

    test('a dry run validates without uploading, or even reading the bucket', () async {
      final bucket = FakeBucket();
      final plan = await publishArtPacks(
        catalogFile: catalogFile,
        outDir: out,
        bucket: bucket,
        dryRun: true,
        log: (_) {},
      );
      expect(bucket.calls, isEmpty);
      expect(plan.archives.single.id, 'theme_themepark');

      // A dry build writes nothing either.
      final dryCatalog = File(p.join(temp.path, 'dry.json'));
      final dryOut = Directory(p.join(temp.path, 'dry-out'));
      await buildAndRecord(
        source: await source(parent: 'dry'),
        catalogFile: dryCatalog,
        outDir: dryOut,
        dryRun: true,
        now: now,
        log: (_) {},
      );
      expect(dryCatalog.existsSync(), isFalse);
      expect(dryOut.existsSync(), isFalse);
    });

    test('uploads archives before the catalog, once', () async {
      final bucket = FakeBucket();
      await publishArtPacks(catalogFile: catalogFile, outDir: out, bucket: bucket, dryRun: false, log: (_) {});
      final writes = bucket.calls.where((c) => c.startsWith('write')).toList();
      expect(writes, ['write art-packs/theme_themepark/1/pack.zip', 'write art-packs/catalog.json']);
      expect(bucket.objects['art-packs/catalog.json'], catalogFile.readAsBytesSync());

      bucket.calls.clear();
      final plan = await publishArtPacks(
        catalogFile: catalogFile,
        outDir: out,
        bucket: bucket,
        dryRun: false,
        log: (_) {},
      );
      expect(bucket.calls.where((c) => c.startsWith('write')), isEmpty);
      expect(plan.archives, isEmpty);
      expect(plan.catalog, isFalse);
    });

    test('refuses when the bucket has a newer catalog', () async {
      final bucket = FakeBucket();
      final built = await buildArtPack(await source(parent: 'x'));
      bucket.objects['art-packs/catalog.json'] = Uint8List.fromList(
        encodeCatalog(ArtPackCatalog(catalogVersion: 9, generatedAt: now, packs: [built.entry])),
      );
      await refuses(
        () => publishArtPacks(catalogFile: catalogFile, outDir: out, bucket: bucket, dryRun: false, log: (_) {}),
        'newer than local',
      );
      expect(bucket.calls.where((c) => c.startsWith('write')), isEmpty);
    });

    test('refuses a local archive that doesn\'t match the catalog, or one that\'s missing everywhere', () async {
      final zip = File(p.join(out.path, 'art-packs', 'theme_themepark', '1', 'pack.zip'));
      final bytes = zip.readAsBytesSync();
      zip.writeAsBytesSync([...bytes, 0]);
      await refuses(
        () => publishArtPacks(catalogFile: catalogFile, outDir: out, bucket: FakeBucket(), dryRun: true, log: (_) {}),
        'doesn\'t match',
      );
      zip.deleteSync();
      await refuses(
        () => publishArtPacks(catalogFile: catalogFile, outDir: out, bucket: FakeBucket(), dryRun: false, log: (_) {}),
        'in neither',
      );
    });
  });
}
