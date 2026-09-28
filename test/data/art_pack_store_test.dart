import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/data/art_pack_store.dart';
import 'package:travary/domain/domain.dart';

import '../support/art_pack_fixtures.dart';
import '../support/raw_zip.dart';

void main() {
  late Directory temp;
  late Directory root;
  late ArtPackStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('travary_store');
    root = Directory(p.join(temp.path, 'art-packs'))..createSync();
    store = ArtPackStore.at(root);
    await store.loadInstalled();
  });

  tearDown(() => temp.delete(recursive: true));

  Future<InstalledArtPack> install(CatalogPack pack, List<int> bytes, [ArtPackStore? into]) async {
    final target = into ?? store;
    final part = target.archivePartFile(pack);
    await part.parent.create(recursive: true);
    await part.writeAsBytes(bytes);
    return target.install(pack, archive: part);
  }

  /// A catalog entry that honestly describes [zip].
  CatalogPack describe(
    String id,
    Uint8List zip, {
    int version = 1,
    required int fileCount,
    required int uncompressedBytes,
  }) => CatalogPack(
    ref: ArtPackRef(
      id: id,
      version: version,
      priority: 1,
      selectors: const ArtPackSelectors(themes: [ExperienceTheme.themepark]),
    ),
    archive: ArtPackArchive(
      storagePath: artPackStoragePath(id, version),
      sha256: sha256.convert(zip).toString(),
      compressedBytes: zip.length,
      uncompressedBytes: uncompressedBytes,
      fileCount: fileCount,
    ),
    minAppBuild: 1,
  );

  List<int> manifestFor(String id, List<String> files, {int version = 1}) => utf8.encode(
    jsonEncode({
      'schemaVersion': 1,
      'packId': id,
      'version': version,
      'assets': [
        for (final file in files)
          {
            'file': file,
            'kind': file.split('/').first,
            'theme': 'any',
            'subject': 'generic',
            'group': p.basenameWithoutExtension(file),
            'format': 'both',
            'width': 4,
            'height': 4,
          },
      ],
    }),
  );

  /// Installs a hand-made zip whose catalog entry is truthful, so only the
  /// archive's own content is on trial.
  Future<void> installRaw(
    String id,
    List<RawEntry> entries, {
    bool overlapSecond = false,
    int? fileCount,
    int? uncompressed,
  }) async {
    final zip = rawZip(entries, overlapSecond: overlapSecond);
    await install(
      describe(
        id,
        zip,
        fileCount: fileCount ?? entries.length,
        uncompressedBytes: uncompressed ?? entries.fold(0, (sum, e) => sum + (e.declaredSize ?? e.content.length)),
      ),
      zip,
    );
  }

  final png = solidPng(4, 4);

  void expectNothingLeft() {
    expect(store.installed, isEmpty);
    for (final folder in ['staging', 'archives', 'packs']) {
      final dir = Directory(p.join(root.path, folder));
      if (dir.existsSync()) expect(dir.listSync(), isEmpty, reason: '$folder is clean');
    }
  }

  group('installing', () {
    test('a verified pack becomes visible atomically, and the download is removed', () async {
      final built = await buildTestPack(temp, id: 'theme_themepark');
      final installed = await install(built.entry, built.archive);

      expect(installed.id, 'theme_themepark');
      expect(installed.directory.path, p.join(root.path, 'packs', 'theme_themepark', '1'));
      expect(installed.file('dining/themepark_generic_01_vignette.png').readAsBytesSync(), isNotEmpty);
      expect(store.installed.single.id, 'theme_themepark');
      final record = jsonDecode(File(p.join(root.path, 'installed.json')).readAsStringSync()) as Map;
      expect((record['packs'] as List).single['id'], 'theme_themepark');
      expect(store.archivePartFile(built.entry).existsSync(), isFalse);
      expect(Directory(p.join(root.path, 'staging')).listSync(), isEmpty);
      expect(root.listSync().map((e) => p.basename(e.path)).where((n) => n.contains('.tmp-')), isEmpty);
    });

    test('installed packs load offline after a restart', () async {
      final built = await buildTestPack(temp, id: 'theme_themepark');
      await install(built.entry, built.archive);

      final restarted = ArtPackStore.at(root);
      final loaded = await restarted.loadInstalled();
      expect(loaded.single.id, 'theme_themepark');
      expect(loaded.single.manifest.files, ['dining/themepark_generic_01_vignette.png']);
      expect(loaded.single.ref.selectors.themes, [ExperienceTheme.themepark]);
    });

    test('a wrong compressed size prevents installation', () async {
      final built = await buildTestPack(temp, id: 'theme_themepark');
      final entry = built.entry;
      final lying = CatalogPack(
        ref: entry.ref,
        archive: ArtPackArchive(
          storagePath: entry.archive.storagePath,
          sha256: entry.archive.sha256,
          compressedBytes: entry.archive.compressedBytes + 1,
          uncompressedBytes: entry.archive.uncompressedBytes,
          fileCount: entry.archive.fileCount,
        ),
        minAppBuild: 1,
      );
      await expectLater(install(lying, built.archive), throwsA(isA<ArtPackFormatException>()));
      expectNothingLeft();
    });

    test('a wrong SHA-256 prevents installation', () async {
      final built = await buildTestPack(temp, id: 'theme_themepark');
      final tampered = Uint8List.fromList(built.archive)..[built.archive.length ~/ 2] ^= 0xFF;
      await expectLater(install(built.entry, tampered), throwsA(isA<ArtPackFormatException>()));
      expectNothingLeft();
      expect(constantTimeEquals('abc', 'abc'), isTrue);
      expect(constantTimeEquals('abc', 'abd'), isFalse);
      expect(constantTimeEquals('abc', 'ab'), isFalse);
    });

    test('an upgrade replaces the previous version only once it\'s complete', () async {
      final v1 = await buildTestPack(temp, id: 'theme_themepark');
      await install(v1.entry, v1.archive);
      final v2 = await buildTestPack(temp, id: 'theme_themepark', version: 2);
      await install(v2.entry, v2.archive);
      expect(store.installed.single.version, 2);
      expect(Directory(p.join(root.path, 'packs', 'theme_themepark', '1')).existsSync(), isFalse);
      expect(Directory(p.join(root.path, 'packs', 'theme_themepark', '2')).existsSync(), isTrue);
    });

    test('an interrupted or bad download leaves the prior version intact', () async {
      final v1 = await buildTestPack(temp, id: 'theme_themepark');
      await install(v1.entry, v1.archive);
      final v2 = await buildTestPack(temp, id: 'theme_themepark', version: 2);
      final half = v2.archive.sublist(0, v2.archive.length ~/ 2);
      await expectLater(install(v2.entry, half), throwsA(isA<ArtPackFormatException>()));

      final pack = store.installed.single;
      expect(pack.version, 1);
      expect(pack.file('dining/themepark_generic_01_vignette.png').existsSync(), isTrue);
      expect(Directory(p.join(root.path, 'packs', 'theme_themepark', '2')).existsSync(), isFalse);
      expect((await ArtPackStore.at(root).loadInstalled()).single.version, 1);
    });

    test('leftovers of a crash are cleaned on the next start; the installed pack stays', () async {
      final v1 = await buildTestPack(temp, id: 'theme_themepark');
      await install(v1.entry, v1.archive);
      final leftovers = [
        Directory(p.join(root.path, 'staging', 'theme_themepark-2-0123456789abcdef')),
        Directory(p.join(root.path, 'packs', 'theme_themepark', '2')),
        Directory(p.join(root.path, 'packs', 'orphan_pack', '1')),
        Directory(p.join(root.path, 'quarantine', 'theme_themepark-1-fedcba9876543210')),
      ];
      for (final dir in leftovers) {
        dir.createSync(recursive: true);
        File(p.join(dir.path, 'x.png')).writeAsBytesSync(png);
      }
      final part = File(p.join(root.path, 'archives', 'theme_themepark-2.zip.part'))..writeAsBytesSync([1, 2]);
      final tempRecord = File(p.join(root.path, 'installed.json.tmp-0011223344556677'))..writeAsStringSync('{');
      final notOurs = File(p.join(root.path, 'staging', 'README'))..writeAsStringSync('keep');

      final loaded = await ArtPackStore.at(root).loadInstalled();
      expect(loaded.single.version, 1);
      for (final dir in leftovers) {
        expect(dir.existsSync(), isFalse, reason: dir.path);
      }
      expect(part.existsSync(), isFalse);
      expect(tempRecord.existsSync(), isFalse);
      expect(notOurs.existsSync(), isTrue, reason: 'only names the store makes are removed');
    });
  });

  group('corrupt installed packs', () {
    Future<InstalledArtPack> installed() async {
      final built = await buildTestPack(temp, id: 'theme_themepark');
      return install(built.entry, built.archive);
    }

    test('a deleted image quarantines the pack without crashing', () async {
      final pack = await installed();
      pack.file('dining/themepark_generic_01_vignette.png').deleteSync();
      final restarted = ArtPackStore.at(root);
      expect(await restarted.loadInstalled(), isEmpty);
      expect(pack.directory.existsSync(), isFalse);
      expect(restarted.installed, isEmpty);
      final record = jsonDecode(File(p.join(root.path, 'installed.json')).readAsStringSync()) as Map;
      expect(record['packs'], isEmpty);
    });

    test('a truncated image or damaged pack.json does too', () async {
      final pack = await installed();
      pack.file('dining/themepark_generic_01_vignette.png').writeAsBytesSync([1, 2, 3]);
      store = ArtPackStore.at(root);
      expect(await store.loadInstalled(), isEmpty);

      final again = await installed();
      final manifest = again.file('pack.json');
      manifest.writeAsStringSync(manifest.readAsStringSync().replaceFirst('themepark', 'alpinexx'));
      expect(await ArtPackStore.at(root).loadInstalled(), isEmpty);
    });

    test('an unreadable installed.json falls back to nothing, and the files are cleared', () async {
      final pack = await installed();
      File(p.join(root.path, 'installed.json')).writeAsStringSync('{not json');
      expect(await ArtPackStore.at(root).loadInstalled(), isEmpty);
      expect(pack.directory.existsSync(), isFalse);
    });

    test('a planted symlink is removed without touching its target', () async {
      final outside = Directory(p.join(temp.path, 'outside'))..createSync();
      final precious = File(p.join(outside.path, 'precious.txt'))..writeAsStringSync('keep me');
      Directory(p.join(root.path, 'packs', 'evil')).createSync(recursive: true);
      Link(p.join(root.path, 'packs', 'evil', '1')).createSync(outside.path);
      await ArtPackStore.at(root).loadInstalled();
      expect(Link(p.join(root.path, 'packs', 'evil', '1')).existsSync(), isFalse);
      expect(precious.readAsStringSync(), 'keep me');
    });

    test('removing a pack (eviction) drops its record, then its files', () async {
      final pack = await installed();
      await store.remove(pack.id);
      expect(store.installed, isEmpty);
      expect(pack.directory.existsSync(), isFalse);
      expect(await ArtPackStore.at(root).loadInstalled(), isEmpty);
    });
  });

  group('malicious archives are rejected', () {
    Future<void> rejects(Future<void> Function() install, String why) async {
      await expectLater(install(), throwsA(isA<ArtPackFormatException>()), reason: why);
      expectNothingLeft();
      expect(File(p.join(temp.path, 'evil.png')).existsSync(), isFalse, reason: 'nothing written outside');
    }

    RawEntry manifest(List<String> files) => RawEntry('pack.json', manifestFor('evil', files));

    test('a well-formed hand-made archive does install (control)', () async {
      await installRaw('evil', [
        manifest(['dining/ok.png']),
        RawEntry('dining/ok.png', png, deflate: true),
      ]);
      expect(store.installed.single.id, 'evil');
    });

    test('zip-slip paths', () async {
      for (final name in [
        '../evil.png',
        'dining/../../evil.png',
        '/tmp/evil.png',
        r'dining\..\..\evil.png',
        'dining//evil.png',
        './dining/evil.png',
      ]) {
        await rejects(
          () => installRaw('evil', [
            manifest(['dining/ok.png']),
            RawEntry(name, png),
          ]),
          name,
        );
      }
    });

    test('symlinks and directories', () async {
      final symlink = RawEntry(
        'dining/link.png',
        utf8.encode('/etc/passwd'),
        madeBy: 0x0314,
        externalAttributes: 0xA1FF << 16,
      );
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/link.png']),
          symlink,
        ]),
        'Unix symlink',
      );
      final directory = RawEntry('dining/folder.png', const [], madeBy: 20, externalAttributes: 0x10);
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/folder.png']),
          directory,
        ]),
        'DOS directory',
      );
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/ok.png']),
          RawEntry('dining/', const []),
          RawEntry('dining/ok.png', png),
        ]),
        'directory entry',
      );
    });

    test('unsupported files', () async {
      for (final name in [
        'dining/evil.svg',
        'dining/evil.html',
        'fonts/evil.png',
        'dining/evil.ttf',
        'dining/sub/evil.png',
        'run.sh',
      ]) {
        await rejects(
          () => installRaw('evil', [
            manifest(['dining/ok.png']),
            RawEntry('dining/ok.png', png),
            RawEntry(name, png),
          ]),
          name,
        );
      }
      final svg = utf8.encode('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>');
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/fake.png']),
          RawEntry('dining/fake.png', svg),
        ]),
        'SVG named .png',
      );
    });

    test('zip bombs', () async {
      final zeros = List.filled(5 * 1024 * 1024, 0);
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/bomb.png']),
          RawEntry('dining/bomb.png', [...png, ...zeros], deflate: true, declaredSize: png.length),
        ]),
        'inflates past its declared size',
      );
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/a.png', 'dining/b.png']),
          RawEntry('dining/a.png', png),
          RawEntry('dining/b.png', png),
        ], overlapSecond: true),
        'overlapping entries',
      );
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/ok.png']),
          RawEntry('dining/ok.png', png),
        ], uncompressed: 10),
        'bigger than the catalog says',
      );
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/ok.png']),
          RawEntry('dining/ok.png', png),
        ], fileCount: 1),
        'more files than the catalog says',
      );
    });

    test('encryption, odd compression, mismatched headers and corruption', () async {
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/ok.png']),
          RawEntry('dining/ok.png', png, flags: 1),
        ]),
        'encrypted',
      );
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/ok.png']),
          RawEntry('dining/ok.png', png, method: 12),
        ]),
        'bzip2',
      );
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/ok.png']),
          RawEntry('dining/ok.png', png, localName: 'dining/no.png'),
        ]),
        'local name differs',
      );
      final zip = rawZip([
        manifest(['dining/ok.png']),
        RawEntry('dining/ok.png', png),
      ]);
      final corrupt = Uint8List.fromList(zip);
      // Past pack.json's header, name and data and the image's header and
      // name, into the image's pixels.
      final at =
          30 + 'pack.json'.length + manifestFor('evil', ['dining/ok.png']).length + 30 + 'dining/ok.png'.length + 40;
      corrupt[at] ^= 0xFF;
      await rejects(
        () => install(
          describe(
            'evil',
            corrupt,
            fileCount: 2,
            uncompressedBytes: manifestFor('evil', ['dining/ok.png']).length + png.length,
          ),
          corrupt,
        ),
        'CRC mismatch',
      );
    });

    test('files and pack.json must agree exactly', () async {
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/ok.png']),
          RawEntry('dining/ok.png', png),
          RawEntry('dining/extra.png', png),
        ]),
        'undeclared file',
      );
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/ok.png', 'dining/missing.png']),
          RawEntry('dining/ok.png', png),
        ]),
        'declared file missing',
      );
      await rejects(() => installRaw('evil', [RawEntry('dining/ok.png', png)]), 'no pack.json');
      await rejects(
        () => installRaw('evil', [
          manifest(['dining/ok.png']),
          RawEntry('dining/ok.png', png),
          RawEntry('dining/ok.png', png),
        ]),
        'duplicate entry',
      );
      await rejects(
        () => installRaw('evil', [
          RawEntry('pack.json', manifestFor('someone_else', ['dining/ok.png'])),
          RawEntry('dining/ok.png', png),
        ]),
        'pack.json for another pack',
      );
    });
  });
}
