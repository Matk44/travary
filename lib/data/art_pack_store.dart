import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/domain.dart';
import 'art_pack_archive.dart';
import 'art_pack_catalog.dart';

/// A downloaded art pack on this phone: verified, complete, ready to draw.
class InstalledArtPack {
  const InstalledArtPack({
    required this.ref,
    required this.directory,
    required this.manifest,
    required this.sha256,
    required this.files,
    required this.installedAt,
    required this.lastUsedAt,
  });

  final ArtPackRef ref;

  /// `packs/<id>/<version>`.
  final Directory directory;
  final PackManifest manifest;
  final String sha256;

  /// Every file (pack.json included) and its size in bytes.
  final Map<String, int> files;
  final DateTime installedAt;
  final DateTime lastUsedAt;

  String get id => ref.id;
  int get version => ref.version;
  int get totalBytes => files.values.fold(0, (sum, size) => sum + size);

  File file(String relativePath) => File(p.join(directory.path, relativePath));

  InstalledArtPack usedAt(DateTime time) => InstalledArtPack(
    ref: ref,
    directory: directory,
    manifest: manifest,
    sha256: sha256,
    files: files,
    installedAt: installedAt,
    lastUsedAt: time,
  );

  Map<String, Object?> toJson() => {
    'id': ref.id,
    'version': ref.version,
    'priority': ref.priority,
    'selectors': ref.selectors.toJson(),
    'sha256': sha256,
    'installedAt': installedAt.millisecondsSinceEpoch,
    'lastUsedAt': lastUsedAt.millisecondsSinceEpoch,
    'files': files,
  };
}

/// Downloaded art packs on disk, under the application support folder (not
/// documents: they're a cache the app can rebuild, not the traveller's).
///
///     <application-support>/art-packs/
///       catalog.json                             last valid remote catalog
///       installed.json                           what's installed, written atomically
///       archives/<id>-<version>.zip.part         a download in progress
///       packs/<id>/<version>/...                 installed packs
///       staging/<id>-<version>-<nonce>/...       an install being checked
///       quarantine/<id>-<version>-<nonce>/...    a corrupt pack on its way out
///
/// A pack becomes visible only by an atomic rename of its fully checked
/// staging folder, followed by an atomic rewrite of `installed.json`; the
/// previous version stays until then. Only specific, validated paths inside
/// the root are ever deleted; never the root or an unresolved path.
class ArtPackStore {
  ArtPackStore.at(this.root, {DateTime Function()? clock, Random? random})
    : _rootPath = p.normalize(p.absolute(root.path)),
      _clock = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  /// The store in the app's support folder.
  static Future<ArtPackStore> open() async {
    final support = await getApplicationSupportDirectory();
    final root = Directory(p.join(support.path, 'art-packs'));
    await root.create(recursive: true);
    return ArtPackStore.at(root);
  }

  final Directory root;
  final String _rootPath;
  final DateTime Function() _clock;
  final Random _random;

  Map<String, InstalledArtPack> _installed = const {};
  Future<void> _lock = Future.value();

  Directory get _packs => Directory(p.join(_rootPath, 'packs'));
  Directory get _staging => Directory(p.join(_rootPath, 'staging'));
  Directory get _archives => Directory(p.join(_rootPath, 'archives'));
  Directory get _quarantine => Directory(p.join(_rootPath, 'quarantine'));
  File get _installedFile => File(p.join(_rootPath, 'installed.json'));
  File get _catalogFile => File(p.join(_rootPath, 'catalog.json'));

  Directory _packDirectory(String id, int version) => Directory(p.join(_packs.path, id, '$version'));

  /// Installed packs, by ID.
  List<InstalledArtPack> get installed => [..._installed.values]..sort((a, b) => a.id.compareTo(b.id));

  InstalledArtPack? installedPack(String id) => _installed[id];

  // ------------------------------------------------------------- startup

  /// Loads and checks every installed pack (offline). A pack whose files are
  /// missing, resized or whose `pack.json` no longer validates is
  /// quarantined and left for the manager to download again. Leftovers of
  /// interrupted installs are removed.
  Future<List<InstalledArtPack>> loadInstalled() => _locked(() async {
    await _removeLeftovers();
    final records = await _readInstalledRecords();
    final valid = <String, InstalledArtPack>{};
    for (final record in records) {
      final pack = await _verify(record);
      if (pack != null) {
        valid[pack.id] = pack;
      } else if (isArtPackId(record['id']) && record['version'] is int) {
        await _quarantineDirectory(_packDirectory(record['id'] as String, record['version'] as int));
      }
    }
    _installed = valid;
    await _removeOrphans();
    if (valid.length != records.length || !await _installedFile.exists()) await _writeInstalled();
    return installed;
  });

  Future<List<Map<String, Object?>>> _readInstalledRecords() async {
    try {
      final json = jsonDecode(await _installedFile.readAsString());
      if (json is! Map || json['schemaVersion'] != 1 || json['packs'] is! List) return const [];
      return [
        for (final record in json['packs'] as List)
          if (record is Map) Map<String, Object?>.from(record),
      ];
    } on FileSystemException {
      return const [];
    } on FormatException {
      return const [];
    }
  }

  /// A pack as recorded, if everything on disk still matches.
  Future<InstalledArtPack?> _verify(Map<String, Object?> record) async {
    try {
      final id = record['id'];
      final version = record['version'];
      final priority = record['priority'];
      final sha = record['sha256'];
      final rawFiles = record['files'];
      if (!isArtPackId(id) ||
          version is! int ||
          version < 1 ||
          priority is! int ||
          sha is! String ||
          rawFiles is! Map) {
        return null;
      }
      id as String;
      final files = <String, int>{};
      for (final entry in rawFiles.entries) {
        final size = entry.value;
        if (entry.key is! String || size is! int || size < 0) return null;
        files[validateArtPackPath(entry.key as String)] = size;
      }
      final directory = _packDirectory(id, version);
      if (await FileSystemEntity.type(directory.path, followLinks: false) != FileSystemEntityType.directory) {
        return null;
      }
      for (final entry in files.entries) {
        final path = p.join(directory.path, entry.key);
        if (await FileSystemEntity.type(path, followLinks: false) != FileSystemEntityType.file) return null;
        if (await File(path).length() != entry.value) return null;
      }
      final manifest = PackManifest.parse(
        await File(p.join(directory.path, artPackManifestName)).readAsBytes(),
        expectedId: id,
        expectedVersion: version,
      );
      if (!_sameFiles(manifest, files.keys)) return null;
      return InstalledArtPack(
        ref: ArtPackRef(
          id: id,
          version: version,
          priority: priority,
          selectors: parseArtPackSelectors(record['selectors'], packId: id),
        ),
        directory: directory,
        manifest: manifest,
        sha256: sha,
        files: Map.unmodifiable(files),
        installedAt: _time(record['installedAt']),
        lastUsedAt: _time(record['lastUsedAt']),
      );
    } on ArtPackFormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  // ------------------------------------------------------------- catalog

  /// The last valid catalog saved on this phone, or null.
  Future<ArtPackCatalog?> loadCatalog({required int appBuild}) async {
    try {
      final file = _catalogFile;
      if (!await file.exists() || await file.length() > ArtPackLimits.maxCatalogBytes) return null;
      return ArtPackCatalog.parse(await file.readAsBytes(), appBuild: appBuild);
    } on ArtPackFormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  /// Keeps a validated catalog for offline starts.
  Future<void> saveCatalog(List<int> bytes) => _locked(() => _writeAtomically(_catalogFile, bytes));

  // ------------------------------------------------------------- install

  /// Where [pack]'s archive downloads to.
  File archivePartFile(CatalogPack pack) => File(p.join(_archives.path, '${pack.id}-${pack.version}.zip.part'));

  /// Removes [pack]'s partial download, if any.
  Future<void> discardPart(CatalogPack pack) => _deleteWithin(archivePartFile(pack));

  /// Verifies [archive] (the downloaded `.part` file) against [pack] and
  /// installs it: exact size, SHA-256 (compared in constant time), safe
  /// extraction into a unique staging folder, `pack.json` matching the
  /// catalog exactly, every declared file present exactly once. Then an
  /// atomic rename makes it visible, and the previous version is removed.
  ///
  /// The archive is deleted either way; on failure only this install's
  /// staging folder is removed and any previous version stays installed.
  /// Throws [ArtPackFormatException] for anything untrustworthy.
  Future<InstalledArtPack> install(CatalogPack pack, {required File archive}) async {
    final staging = Directory(p.join(_staging.path, '${pack.id}-${pack.version}-${_nonce()}'));
    try {
      if (await archive.length() != pack.archive.compressedBytes) {
        throw const ArtPackFormatException('The download has the wrong size.');
      }
      final digest = await sha256.bind(archive.openRead()).first;
      if (!constantTimeEquals(digest.toString(), pack.archive.sha256)) {
        throw const ArtPackFormatException('The download doesn\'t match its checksum.');
      }
      await staging.create(recursive: true);
      final files = await extractArtPackArchive(
        archive,
        staging,
        expectedFileCount: pack.archive.fileCount,
        expectedUncompressedBytes: pack.archive.uncompressedBytes,
      );
      final manifest = PackManifest.parse(
        await File(p.join(staging.path, artPackManifestName)).readAsBytes(),
        expectedId: pack.id,
        expectedVersion: pack.version,
      );
      if (!_sameFiles(manifest, files.keys)) {
        throw const ArtPackFormatException('The pack\'s files don\'t match its pack.json.');
      }
      return await _locked(() => _activate(pack, staging, manifest, files));
    } catch (_) {
      await _deleteWithin(staging);
      rethrow;
    } finally {
      await _deleteWithin(archive);
    }
  }

  Future<InstalledArtPack> _activate(
    CatalogPack pack,
    Directory staging,
    PackManifest manifest,
    Map<String, int> files,
  ) async {
    final target = _packDirectory(pack.id, pack.version);
    final previous = _installed[pack.id];
    if (previous != null && previous.version == pack.version) {
      throw StateError('${pack.id} v${pack.version} is already installed.');
    }
    // Left behind by an interrupted install of this version.
    await _deleteWithin(target);
    await target.parent.create(recursive: true);
    await staging.rename(target.path);

    final now = _clock();
    final fresh = InstalledArtPack(
      ref: pack.ref,
      directory: target,
      manifest: manifest,
      sha256: pack.archive.sha256,
      files: Map.unmodifiable(files),
      installedAt: now,
      lastUsedAt: now,
    );
    final before = _installed;
    _installed = {..._installed, pack.id: fresh};
    try {
      await _writeInstalled();
    } catch (_) {
      _installed = before;
      await _deleteWithin(target);
      rethrow;
    }
    if (previous != null) await _deleteWithin(previous.directory);
    return fresh;
  }

  // ------------------------------------------------------------- removal

  /// Removes an installed pack (cache eviction). The record goes first, so
  /// a crash never leaves a recorded pack without its files.
  Future<void> remove(String id) => _locked(() async {
    final pack = _installed[id];
    if (pack == null) return;
    _installed = {..._installed}..remove(id);
    await _writeInstalled();
    await _deleteWithin(pack.directory);
  });

  /// Marks [ids] as used [at], for least-recently-used eviction.
  Future<void> markUsed(Iterable<String> ids, DateTime at) => _locked(() async {
    var changed = false;
    final next = {..._installed};
    for (final id in ids) {
      final pack = next[id];
      if (pack == null || !pack.lastUsedAt.isBefore(at)) continue;
      next[id] = pack.usedAt(at);
      changed = true;
    }
    if (!changed) return;
    _installed = next;
    await _writeInstalled();
  });

  // ------------------------------------------------------------- internals

  Future<void> _writeInstalled() => _writeAtomically(
    _installedFile,
    utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'packs': [for (final pack in installed) pack.toJson()],
      }),
    ),
  );

  /// Writes a temporary sibling, then renames it over [file].
  Future<void> _writeAtomically(File file, List<int> bytes) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp-${_nonce()}');
    try {
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);
    } catch (_) {
      await _deleteWithin(temp);
      rethrow;
    }
  }

  Future<void> _quarantineDirectory(Directory directory) async {
    if (await FileSystemEntity.type(directory.path, followLinks: false) == FileSystemEntityType.notFound) return;
    final parts = p.split(p.relative(directory.path, from: _packs.path));
    final destination = Directory(p.join(_quarantine.path, '${parts.join('-')}-${_nonce()}'));
    await _quarantine.create(recursive: true);
    try {
      await directory.rename(destination.path);
      await _deleteWithin(destination);
    } on FileSystemException {
      await _deleteWithin(directory);
    }
  }

  static final _stagingName = RegExp(r'^[a-z0-9_]{1,64}-\d+-[0-9a-f]{16}$');
  static final _partName = RegExp(r'^[a-z0-9_]{1,64}-\d+\.zip\.part$');
  static final _tempName = RegExp(r'^(installed|catalog)\.json\.tmp-[0-9a-f]{16}$');

  /// Staging folders, partial downloads, quarantined packs and temporary
  /// files from a run that stopped part-way. Only names this store makes.
  Future<void> _removeLeftovers() async {
    Future<void> sweep(Directory directory, RegExp name) async {
      if (!await directory.exists()) return;
      await for (final entity in directory.list(followLinks: false)) {
        if (name.hasMatch(p.basename(entity.path))) await _deleteWithin(entity);
      }
    }

    await sweep(_staging, _stagingName);
    await sweep(_archives, _partName);
    await sweep(_quarantine, _stagingName);
    await sweep(root, _tempName);
  }

  /// Pack folders no record points to (e.g. a crash between installing a
  /// new version and removing the old).
  Future<void> _removeOrphans() async {
    if (!await _packs.exists()) return;
    await for (final idEntity in _packs.list(followLinks: false)) {
      final id = p.basename(idEntity.path);
      if (!isArtPackId(id)) continue;
      if (idEntity is! Directory) {
        await _deleteWithin(idEntity);
        continue;
      }
      var remaining = 0;
      await for (final versionEntity in idEntity.list(followLinks: false)) {
        final name = p.basename(versionEntity.path);
        final keep = versionEntity is Directory && _installed[id]?.version.toString() == name;
        if (keep) {
          remaining++;
        } else if (RegExp(r'^\d+$').hasMatch(name)) {
          await _deleteWithin(versionEntity);
        } else {
          remaining++;
        }
      }
      if (remaining == 0) await _deleteWithin(idEntity);
    }
  }

  /// Deletes [entity] only if it's strictly inside the store, and never the
  /// store's own top-level folders. Symlinks are removed themselves, never
  /// followed.
  Future<void> _deleteWithin(FileSystemEntity entity) async {
    final path = p.normalize(p.absolute(entity.path));
    final type = await FileSystemEntity.type(path, followLinks: false);
    final depth = p.split(p.relative(path, from: _rootPath)).length;
    if (!p.isWithin(_rootPath, path) || (depth < 2 && type == FileSystemEntityType.directory)) {
      throw StateError('Refusing to delete $path: not a file or folder inside the art-pack store.');
    }
    switch (type) {
      case FileSystemEntityType.link:
        await Link(path).delete();
      case FileSystemEntityType.directory:
        await Directory(path).delete(recursive: true);
      case FileSystemEntityType.notFound:
        return;
      default:
        await File(path).delete();
    }
  }

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  String _nonce() => [for (var i = 0; i < 8; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();

  DateTime _time(Object? millis) => millis is int ? DateTime.fromMillisecondsSinceEpoch(millis) : _clock();
}

/// Compares two strings in time that doesn't depend on where they differ.
bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return difference == 0;
}

/// Whether [present] (pack.json included) is exactly what [manifest] declares.
bool _sameFiles(PackManifest manifest, Iterable<String> present) {
  final declared = manifest.files.toSet();
  final images = present.where((file) => file != artPackManifestName).toSet();
  return present.contains(artPackManifestName) &&
      declared.length == images.length &&
      declared.containsAll(images) &&
      images.length == present.length - 1;
}
