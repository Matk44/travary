import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'art_pack_catalog.dart';
import 'art_pack_store.dart';

/// A failed download. [transient] ones (network, busy server) are worth
/// retrying; not-found, unauthorised or cancelled ones aren't.
class ArtPackRemoteException implements Exception {
  const ArtPackRemoteException(this.message, {required this.transient});

  final String message;
  final bool transient;

  @override
  String toString() => 'ArtPackRemoteException: $message';
}

/// Where art packs come from.
abstract interface class ArtPackRemote {
  /// `art-packs/catalog.json`, refusing anything over [maxBytes].
  Future<Uint8List> fetchCatalog({required int maxBytes});

  /// Downloads the archive at [storagePath] into [target].
  Future<void> downloadArchive(String storagePath, File target);

  /// Stops downloads in progress.
  void cancelAll();
}

/// Firebase Storage (read-only for signed-in travellers; see storage.rules).
class FirebaseArtPackRemote implements ArtPackRemote {
  FirebaseArtPackRemote({required this.ensureSignedIn, FirebaseStorage? storage}) : _storage = storage;

  final Future<void> Function() ensureSignedIn;
  final FirebaseStorage? _storage;
  final _tasks = <DownloadTask>{};

  FirebaseStorage get _bucket => _storage ?? FirebaseStorage.instance;

  @override
  Future<Uint8List> fetchCatalog({required int maxBytes}) => _guard(() async {
    await ensureSignedIn();
    final ref = _bucket.ref(artPackCatalogPath);
    // Check the size first, so an oversized catalog is never downloaded.
    final metadata = await ref.getMetadata();
    if ((metadata.size ?? 0) > maxBytes) throw const ArtPackFormatException('Catalog is larger than 2 MiB.');
    final data = await ref.getData(maxBytes);
    if (data == null) throw const ArtPackRemoteException('The catalog is empty.', transient: false);
    if (data.length > maxBytes) throw const ArtPackFormatException('Catalog is larger than 2 MiB.');
    return data;
  });

  @override
  Future<void> downloadArchive(String storagePath, File target) => _guard(() async {
    await ensureSignedIn();
    await target.parent.create(recursive: true);
    final task = _bucket.ref(storagePath).writeToFile(target);
    _tasks.add(task);
    try {
      await task;
    } finally {
      _tasks.remove(task);
    }
  });

  @override
  void cancelAll() {
    for (final task in [..._tasks]) {
      unawaited(task.cancel().then((_) {}, onError: (Object _) {}));
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'object-not-found' ||
        'bucket-not-found' ||
        'project-not-found' => ArtPackRemoteException('Not found (${e.code}).', transient: false),
        'unauthorized' || 'unauthenticated' => ArtPackRemoteException('Not allowed (${e.code}).', transient: false),
        'canceled' || 'cancelled' => const ArtPackRemoteException('Cancelled.', transient: false),
        'download-size-exceeded' => const ArtPackFormatException('Catalog is larger than 2 MiB.'),
        _ => ArtPackRemoteException('Storage error (${e.code}).', transient: true),
      };
    } on SocketException catch (e) {
      throw ArtPackRemoteException('Offline (${e.message}).', transient: true);
    } on TimeoutException {
      throw const ArtPackRemoteException('Timed out.', transient: true);
    } on HttpException catch (e) {
      throw ArtPackRemoteException('Network error (${e.message}).', transient: true);
    }
  }
}

/// Keeps this phone's art packs: loads installed packs offline at startup,
/// refreshes the remote catalog in the background, installs the packs the
/// app asks for, and evicts unneeded ones.
///
/// Never a startup dependency and never blocking: every failure leaves the
/// bundled art and previously installed packs in place. Listeners hear when
/// the catalog or the installed set changes.
class ArtPackManager extends ChangeNotifier {
  ArtPackManager({
    required this.store,
    required this.remote,
    required this.appBuild,
    DateTime Function()? clock,
    Future<void> Function(Duration)? wait,
    this.retryDelays = const [Duration(seconds: 2), Duration(seconds: 4)],
    this.transientCooldown = const Duration(minutes: 10),
    this.staleAfter = const Duration(hours: 6),
    this.cacheBudgetBytes = ArtPackLimits.unpinnedCacheBudgetBytes,
  }) : _clock = clock ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  final ArtPackStore store;
  final ArtPackRemote remote;

  /// This app's build number (`minAppBuild` in the catalog).
  final int appBuild;

  /// Pauses between download attempts after transient failures.
  final List<Duration> retryDelays;

  /// How long a pack rests after its retries ran out.
  final Duration transientCooldown;

  /// A catalog this old is refreshed when the app comes back.
  final Duration staleAfter;

  /// Space unpinned packs may take before the least recently used go.
  final int cacheBudgetBytes;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _wait;

  ArtPackCatalog? _catalog;
  DateTime? _refreshedAt;
  Future<bool>? _refreshing;
  final _inFlight = <String, Future<InstalledArtPack?>>{};
  final _blocked = <String>{};
  final _restingUntil = <String, DateTime>{};
  Set<String> _pinned = const {};
  bool _pinsKnown = false;
  bool _disposed = false;

  List<InstalledArtPack> get installed => store.installed;

  /// The last valid catalog (from disk until a refresh succeeds).
  ArtPackCatalog? get catalog => _catalog;

  /// Whether a download for [id] is under way.
  bool isInstalling(String id) => _inFlight.keys.any((key) => key.startsWith('$id@'));

  /// Startup, offline: validated installed packs and the saved catalog.
  Future<void> loadInstalled() async {
    await store.loadInstalled();
    _catalog = await store.loadCatalog(appBuild: appBuild);
    _notify();
  }

  /// Fetches and validates `catalog.json`. A malformed, oversized or older
  /// catalog is rejected and the last valid one kept. Never throws.
  Future<bool> refreshCatalog() => _refreshing ??= _refresh().whenComplete(() {
    _refreshing = null;
  });

  /// Refreshes if the catalog hasn't been fetched for [staleAfter].
  Future<bool> refreshIfStale() async {
    final last = _refreshedAt;
    if (last != null && _clock().difference(last) < staleAfter) return true;
    return refreshCatalog();
  }

  Future<bool> _refresh() async {
    try {
      final bytes = await remote.fetchCatalog(maxBytes: ArtPackLimits.maxCatalogBytes);
      final fresh = ArtPackCatalog.parse(bytes, appBuild: appBuild);
      final current = _catalog;
      if (current != null && fresh.catalogVersion < current.catalogVersion) {
        throw ArtPackFormatException('Catalog ${fresh.catalogVersion} is older than ${current.catalogVersion}.');
      }
      await store.saveCatalog(bytes);
      if (_disposed) return false;
      _catalog = fresh;
      _refreshedAt = _clock();
      _notify();
      await _evictIfReady();
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('Art catalog not refreshed (keeping the last one): $error');
      return false;
    }
  }

  /// What the app's trips need right now: [wanted] packs are installed if
  /// missing or older (in the background); [pinned] packs (current and
  /// coming trips) are never evicted; [used] packs count as recently used.
  /// The returned future completes once usage is recorded and any eviction
  /// is done; installs carry on after it.
  Future<void> request({required List<CatalogPack> wanted, required Set<String> pinned, required Set<String> used}) {
    if (_disposed) return Future.value();
    _pinned = pinned;
    _pinsKnown = true;
    for (final pack in wanted) {
      final current = store.installedPack(pack.id);
      if (current != null && current.version >= pack.version) continue;
      unawaited(install(pack));
    }
    final now = _clock();
    final stale = [
      for (final pack in installed)
        if (used.contains(pack.id) && now.difference(pack.lastUsedAt) > const Duration(hours: 1)) pack.id,
    ];
    return _touchThenEvict(stale, now);
  }

  /// Records use first, so eviction never picks a pack that was just used.
  Future<void> _touchThenEvict(List<String> stale, DateTime now) async {
    if (stale.isNotEmpty) {
      try {
        await store.markUsed(stale, now);
      } on FileSystemException catch (error) {
        if (kDebugMode) debugPrint('Couldn\'t record art pack use: $error');
      }
    }
    await _evictIfReady();
  }

  /// Downloads and installs [pack]. One download per pack version at a time:
  /// concurrent calls share it. Transient failures are retried with
  /// growing pauses; integrity, format, permission and not-found failures
  /// aren't retried in this session. Returns null when it didn't install.
  Future<InstalledArtPack?> install(CatalogPack pack) {
    final key = '${pack.id}@${pack.version}';
    // A block body: `=> _inFlight.remove(key)` would return this very
    // future, and whenComplete would wait for it forever.
    return _inFlight[key] ??= _install(pack, key).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<InstalledArtPack?> _install(CatalogPack pack, String key) async {
    if (_blocked.contains(key)) return null;
    final resting = _restingUntil[key];
    if (resting != null && _clock().isBefore(resting)) return null;
    for (var attempt = 0; !_disposed; attempt++) {
      try {
        await remote.downloadArchive(pack.archive.storagePath, store.archivePartFile(pack));
        if (_disposed) {
          await store.discardPart(pack);
          return null;
        }
        final installed = await store.install(pack, archive: store.archivePartFile(pack));
        _notify();
        unawaited(_evictIfReady());
        return installed;
      } on ArtPackRemoteException catch (error) {
        await store.discardPart(pack);
        if (!error.transient) {
          _blocked.add(key);
          _log(pack, error);
          return null;
        }
        if (attempt >= retryDelays.length) {
          _restingUntil[key] = _clock().add(transientCooldown);
          _log(pack, error);
          return null;
        }
        await _wait(retryDelays[attempt]);
      } on ArtPackFormatException catch (error) {
        // Integrity or schema: a retry would fetch the same bytes.
        _blocked.add(key);
        _log(pack, error);
        return null;
      } catch (error) {
        await store.discardPart(pack).catchError((Object _) {});
        _restingUntil[key] = _clock().add(transientCooldown);
        _log(pack, error);
        return null;
      }
    }
    return null;
  }

  /// Evicts least recently used packs beyond the budget, but only once the
  /// catalog has loaded this session and the app has said which packs its
  /// trips use. Pinned packs are never evicted; bundled art isn't here.
  Future<void> _evictIfReady() async {
    if (_disposed || !_pinsKnown || _refreshedAt == null) return;
    final unpinned =
        [
          for (final pack in installed)
            if (!_pinned.contains(pack.id) && !isInstalling(pack.id)) pack,
        ]..sort((a, b) {
          final byUse = a.lastUsedAt.compareTo(b.lastUsedAt);
          return byUse != 0 ? byUse : a.id.compareTo(b.id);
        });
    var total = unpinned.fold(0, (sum, pack) => sum + pack.totalBytes);
    var removed = false;
    for (final pack in unpinned) {
      if (total <= cacheBudgetBytes) break;
      try {
        await store.remove(pack.id);
        total -= pack.totalBytes;
        removed = true;
      } on FileSystemException catch (error) {
        if (kDebugMode) debugPrint('Couldn\'t evict ${pack.id}: $error');
      }
    }
    if (removed) _notify();
  }

  void _log(CatalogPack pack, Object error) {
    if (kDebugMode) debugPrint('Art pack ${pack.id} v${pack.version} not installed: $error');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    remote.cancelAll();
    super.dispose();
  }
}
