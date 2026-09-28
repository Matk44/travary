import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/data/art_pack_service.dart';
import 'package:travary/data/art_pack_store.dart';

import '../../tool/src/pack_builder.dart';
import '../support/art_pack_fixtures.dart';

void main() {
  late Directory temp;
  late Directory root;
  late FakeArtPackRemote remote;
  late List<Duration> waits;
  late DateTime now;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('travary_manager');
    root = Directory(p.join(temp.path, 'art-packs'))..createSync();
    remote = FakeArtPackRemote();
    waits = [];
    now = DateTime(2027, 4, 1, 9);
  });

  tearDown(() => temp.delete(recursive: true));

  Future<ArtPackManager> manager({int budget = ArtPackLimits.unpinnedCacheBudgetBytes, int appBuild = 1}) async {
    final m = ArtPackManager(
      store: ArtPackStore.at(root),
      remote: remote,
      appBuild: appBuild,
      clock: () => now,
      wait: (delay) async => waits.add(delay),
      cacheBudgetBytes: budget,
    );
    addTearDown(m.dispose);
    await m.loadInstalled();
    return m;
  }

  Future<BuiltPack> publish(String id, {int version = 1}) async {
    final built = await buildTestPack(Directory(p.join(temp.path, 'sources')), id: id, version: version);
    remote.serve(built);
    return built;
  }

  group('catalog', () {
    test('a valid catalog is kept for offline starts', () async {
      final built = await publish('theme_themepark');
      remote.catalog = catalogBytes([built.entry], version: 3);
      final first = await manager();
      expect(await first.refreshCatalog(), isTrue);
      expect(first.catalog!.catalogVersion, 3);

      remote.catalog = null; // offline
      final offline = await manager();
      expect(offline.catalog!.catalogVersion, 3, reason: 'loaded from disk before any network');
      expect(await offline.refreshCatalog(), isFalse);
      expect(offline.catalog!.catalogVersion, 3);
    });

    test('a malformed, oversized or older catalog is rejected without losing the last valid one', () async {
      final built = await publish('theme_themepark');
      remote.catalog = catalogBytes([built.entry], version: 5);
      final m = await manager();
      await m.refreshCatalog();

      for (final bad in [
        [...'{"schemaVersion": 1, "catalogVersion": '.codeUnits],
        catalogBytes([built.entry, built.entry], version: 6),
        [
          ...catalogBytes([built.entry], version: 7),
          ...List.filled(ArtPackLimits.maxCatalogBytes, 0x20),
        ],
        catalogBytes([built.entry], version: 4),
      ]) {
        remote.catalog = Uint8List.fromList(bad);
        expect(await m.refreshCatalog(), isFalse);
        expect(m.catalog!.catalogVersion, 5);
      }
      expect((await manager()).catalog!.catalogVersion, 5, reason: 'the saved copy is the last valid one');
    });

    test('concurrent refreshes share one fetch', () async {
      remote.catalog = catalogBytes(const []);
      final m = await manager();
      await Future.wait([m.refreshCatalog(), m.refreshCatalog(), m.refreshCatalog()]);
      expect(remote.catalogFetches, 1);
      expect(await m.refreshIfStale(), isTrue);
      expect(remote.catalogFetches, 1, reason: 'fresh enough');
      now = now.add(const Duration(hours: 7));
      await m.refreshIfStale();
      expect(remote.catalogFetches, 2);
    });
  });

  group('downloads', () {
    test('are deduplicated by pack ID and version', () async {
      final built = await publish('theme_themepark');
      final m = await manager();
      remote.gate = Completer<void>();
      final first = m.install(built.entry);
      final second = m.install(built.entry);
      expect(identical(first, second), isTrue);
      expect(m.isInstalling('theme_themepark'), isTrue);
      remote.gate!.complete();
      final results = await Future.wait([first, second]);
      expect(remote.downloads, [built.entry.archive.storagePath]);
      expect(results.every((r) => r?.id == 'theme_themepark'), isTrue);
      expect(m.installed.single.id, 'theme_themepark');
    });

    test('request() installs what trips want and tells listeners', () async {
      final built = await publish('theme_themepark');
      final m = await manager();
      var notified = 0;
      m.addListener(() => notified++);
      unawaited(m.request(wanted: [built.entry], pinned: {'theme_themepark'}, used: const {}));
      unawaited(m.request(wanted: [built.entry], pinned: {'theme_themepark'}, used: const {}));
      await m.install(built.entry);
      expect(remote.downloads, hasLength(1));
      expect(m.installed.single.version, 1);
      expect(notified, greaterThan(0));
      await m.request(wanted: [built.entry], pinned: const {}, used: const {});
      expect(remote.downloads, hasLength(1), reason: 'already installed');
    });

    test('transient failures retry with growing pauses, then rest', () async {
      final built = await publish('theme_themepark');
      final m = await manager();
      remote.failures.addAll([
        const ArtPackRemoteException('Offline.', transient: true),
        const ArtPackRemoteException('Busy.', transient: true),
      ]);
      expect((await m.install(built.entry))?.id, 'theme_themepark');
      expect(waits, const [Duration(seconds: 2), Duration(seconds: 4)]);

      final other = await publish('theme_alpine');
      remote.failures.addAll(List.filled(3, const ArtPackRemoteException('Offline.', transient: true)));
      expect(await m.install(other.entry), isNull);
      expect(remote.downloads.where((d) => d.contains('theme_alpine')), hasLength(3));
      expect(await m.install(other.entry), isNull, reason: 'resting');
      expect(remote.downloads.where((d) => d.contains('theme_alpine')), hasLength(3));
      now = now.add(const Duration(minutes: 11));
      expect((await m.install(other.entry))?.id, 'theme_alpine');
    });

    test('integrity, not-found and permission failures are not retried', () async {
      final built = await publish('theme_themepark');
      final m = await manager();
      remote.archives[built.entry.archive.storagePath] = built.archive.sublist(1);
      expect(await m.install(built.entry), isNull);
      expect(await m.install(built.entry), isNull);
      expect(remote.downloads, hasLength(1), reason: 'a bad checksum is never fetched again this session');

      final missing = await publish('theme_missing');
      remote.archives.remove(missing.entry.archive.storagePath);
      expect(await m.install(missing.entry), isNull);
      expect(await m.install(missing.entry), isNull);
      expect(remote.downloads.where((d) => d.contains('theme_missing')), hasLength(1));

      final denied = await publish('theme_denied');
      remote.failures.add(const ArtPackRemoteException('Not allowed (unauthorized).', transient: false));
      expect(await m.install(denied.entry), isNull);
      expect(waits, isEmpty);
      expect(m.installed, isEmpty);
    });

    test('a failed update keeps the version already installed', () async {
      final v1 = await publish('theme_themepark');
      final m = await manager();
      await m.install(v1.entry);
      final v2 = await publish('theme_themepark', version: 2);
      remote.archives[v2.entry.archive.storagePath] = v2.archive.sublist(0, 100);
      expect(await m.install(v2.entry), isNull);
      expect(m.installed.single.version, 1);
    });
  });

  group('eviction', () {
    Future<ArtPackManager> withThreePacks({required int budget}) async {
      final packs = [
        for (final id in ['pack_a', 'pack_b', 'pack_c']) await publish(id),
      ];
      remote.catalog = catalogBytes([for (final b in packs) b.entry]);
      final m = await manager(budget: budget);
      for (final (index, built) in packs.indexed) {
        now = DateTime(2027, 4, 1, 9 + index);
        await m.install(built.entry);
      }
      return m;
    }

    test('never removes pinned packs, and only after the catalog has loaded', () async {
      final m = await withThreePacks(budget: 0);
      await m.request(wanted: const [], pinned: {'pack_b'}, used: const {});
      expect(m.installed, hasLength(3), reason: 'no catalog refresh yet this session');

      await m.refreshCatalog();
      expect(m.installed.map((p) => p.id), ['pack_b']);
    });

    test('never runs before the app has said which packs are pinned', () async {
      final m = await withThreePacks(budget: 0);
      await m.refreshCatalog();
      expect(m.installed, hasLength(3));
    });

    test('removes the least recently used first, down to the budget', () async {
      final packs = [
        for (final id in ['pack_a', 'pack_b', 'pack_c']) await publish(id),
      ];
      remote.catalog = catalogBytes([for (final b in packs) b.entry]);
      final perPack = packs.first.entry.archive.uncompressedBytes;
      final m = await manager(budget: perPack * 2);
      for (final (index, built) in packs.indexed) {
        now = DateTime(2027, 4, 1, 9 + index); // a at 9:00, b at 10:00, c at 11:00
        await m.install(built.entry);
      }
      await m.refreshCatalog();
      now = DateTime(2027, 4, 1, 12);
      await m.request(wanted: const [], pinned: const {}, used: {'pack_a'});
      expect(m.installed.map((p) => p.id), ['pack_a', 'pack_c'], reason: 'pack_b was least recently used');
      expect((await manager()).installed.firstWhere((p) => p.id == 'pack_a').lastUsedAt, DateTime(2027, 4, 1, 12));
    });
  });
}
