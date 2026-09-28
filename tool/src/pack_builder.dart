import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_archive.dart';
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/data/image_header.dart';
import 'package:travary/domain/domain.dart';

import 'zip_writer.dart';

/// Something the publisher refuses, with the reason.
class PublishException implements Exception {
  const PublishException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A pack source folder:
///
///     <source>/
///       pack.json             the archive manifest (schemaVersion, packId,
///                             version, assets with explicit metadata)
///       catalog-entry.json    {"priority": 300, "selectors": {...}, "minAppBuild": 1}
///       <folder>/<image>      every image pack.json declares, nothing else
const catalogEntryName = 'catalog-entry.json';

/// A built, validated pack: its catalog entry and deterministic archive.
class BuiltPack {
  const BuiltPack({required this.entry, required this.archive, required this.manifest});

  final CatalogPack entry;
  final Uint8List archive;
  final PackManifest manifest;
}

/// Validates [source] and builds its archive. Checks, with the same code
/// the app uses: the vocabulary (kinds, themes, subjects, selectors), every
/// path, the real format and pixel size of every image against pack.json,
/// no undeclared, unexpected or symlinked files, and the limits. Finally
/// extracts the archive with the app's own extractor, so an accepted pack
/// is one the app will accept. Throws [PublishException].
Future<BuiltPack> buildArtPack(Directory source) async {
  if (!await source.exists()) throw PublishException('No pack at ${source.path}.');
  final manifest = _read(source, artPackManifestName, (bytes) => PackManifest.parse(bytes));
  final entry = _read(source, catalogEntryName, (bytes) => _parseCatalogEntry(bytes, manifest.packId));

  // Exactly the declared files (plus the two JSON files), all regular.
  final allowed = {artPackManifestName, catalogEntryName, ...manifest.files};
  await for (final entity in source.list(recursive: true, followLinks: false)) {
    final relative = p.posix.joinAll(p.split(p.relative(entity.path, from: source.path)));
    if (entity is Link) throw PublishException('$relative is a symlink; packs contain real files only.');
    if (entity is Directory) {
      if (!artPackFolders.contains(relative)) throw PublishException('Unexpected folder $relative/.');
      continue;
    }
    if (!allowed.contains(relative)) {
      final hint = p.basename(relative) == '.DS_Store' ? ' (delete .DS_Store files first)' : '';
      throw PublishException('$relative is not declared in pack.json$hint.');
    }
  }

  final entries = <ZipSource>[
    ZipSource(artPackManifestName, utf8.encode('${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n')),
  ];
  for (final asset in [...manifest.assets]..sort((a, b) => a.file.compareTo(b.file))) {
    final file = File(p.join(source.path, asset.file));
    if (await FileSystemEntity.type(file.path, followLinks: false) != FileSystemEntityType.file) {
      throw PublishException('${asset.file} is declared but missing.');
    }
    final bytes = await file.readAsBytes();
    final info = readImageInfo(bytes);
    final expected = ImageType.forExtension(p.extension(asset.file).substring(1));
    if (info == null || info.type != expected) {
      throw PublishException('${asset.file} is not a valid ${expected?.name} image.');
    }
    if (info.width != asset.width || info.height != asset.height) {
      throw PublishException(
        '${asset.file} is ${info.width}x${info.height}; pack.json says ${asset.width}x${asset.height}.',
      );
    }
    if (asset is PackCardArt && asset.format == 'scene' && info.width <= info.height) {
      throw PublishException('${asset.file} is a scene, so it must be landscape.');
    }
    entries.add(ZipSource(asset.file, bytes));
  }

  final uncompressed = entries.fold(0, (sum, e) => sum + e.bytes.length);
  if (entries.length > ArtPackLimits.maxFileCount) {
    throw PublishException('${entries.length} files; the limit is ${ArtPackLimits.maxFileCount}.');
  }
  if (uncompressed > ArtPackLimits.maxUncompressedBytes) {
    throw PublishException('$uncompressed bytes expanded; the limit is ${ArtPackLimits.maxUncompressedBytes}.');
  }
  final archive = buildStoredZip(entries);
  if (archive.length > ArtPackLimits.maxCompressedBytes) {
    throw PublishException('${archive.length} bytes compressed; the limit is ${ArtPackLimits.maxCompressedBytes}.');
  }

  final built = BuiltPack(
    entry: CatalogPack(
      ref: ArtPackRef(
        id: manifest.packId,
        version: manifest.version,
        priority: entry.priority,
        selectors: entry.selectors,
      ),
      archive: ArtPackArchive(
        storagePath: artPackStoragePath(manifest.packId, manifest.version),
        sha256: sha256.convert(archive).toString(),
        compressedBytes: archive.length,
        uncompressedBytes: uncompressed,
        fileCount: entries.length,
      ),
      minAppBuild: entry.minAppBuild,
    ),
    archive: archive,
    manifest: manifest,
  );
  await verifyWithAppExtractor(built);
  return built;
}

/// Extracts [built] exactly as the app will, in a temporary folder.
Future<void> verifyWithAppExtractor(BuiltPack built) async {
  final temp = await Directory.systemTemp.createTemp('travary_pack_check');
  try {
    final zip = File(p.join(temp.path, 'pack.zip'));
    await zip.writeAsBytes(built.archive, flush: true);
    final staging = Directory(p.join(temp.path, 'staging'));
    await staging.create();
    await extractArtPackArchive(
      zip,
      staging,
      expectedFileCount: built.entry.archive.fileCount,
      expectedUncompressedBytes: built.entry.archive.uncompressedBytes,
    );
    PackManifest.parse(
      await File(p.join(staging.path, artPackManifestName)).readAsBytes(),
      expectedId: built.entry.id,
      expectedVersion: built.entry.version,
    );
  } on ArtPackFormatException catch (e) {
    throw PublishException('The app would reject this archive: ${e.message}');
  } finally {
    await temp.delete(recursive: true);
  }
}

T _read<T>(Directory source, String name, T Function(List<int>) parse) {
  final file = File(p.join(source.path, name));
  if (!file.existsSync()) throw PublishException('${source.path} has no $name.');
  try {
    return parse(file.readAsBytesSync());
  } on ArtPackFormatException catch (e) {
    throw PublishException('$name: ${e.message}');
  }
}

({int priority, ArtPackSelectors selectors, int minAppBuild}) _parseCatalogEntry(List<int> bytes, String packId) {
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw const ArtPackFormatException('not UTF-8 JSON.');
  }
  if (json is! Map) throw const ArtPackFormatException('not an object.');
  final unknown = json.keys.where((k) => !const {'priority', 'selectors', 'minAppBuild'}.contains(k));
  if (unknown.isNotEmpty) throw ArtPackFormatException('unknown fields ${unknown.join(', ')}.');
  final priority = json['priority'];
  if (priority is! int || priority < 0 || priority > ArtPackLimits.maxPriority) {
    throw ArtPackFormatException('priority must be 0–${ArtPackLimits.maxPriority}.');
  }
  final minAppBuild = json['minAppBuild'] ?? 1;
  if (minAppBuild is! int || minAppBuild < 1) throw const ArtPackFormatException('minAppBuild must be 1 or more.');
  return (
    priority: priority,
    selectors: parseArtPackSelectors(json['selectors'], packId: packId),
    minAppBuild: minAppBuild,
  );
}
