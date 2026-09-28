import 'dart:convert';

import 'package:travary/data/art_pack_catalog.dart';

import 'pack_builder.dart';

/// Reads a catalog the publisher is about to change. Stricter than the app:
/// a catalog with any invalid pack is refused rather than silently dropping
/// that pack on the next write. Throws [PublishException].
ArtPackCatalog readCatalogStrict(List<int> bytes) {
  final ArtPackCatalog catalog;
  try {
    // Every build: publishing must keep packs for newer apps too.
    catalog = ArtPackCatalog.parse(bytes, appBuild: 1 << 31);
  } on ArtPackFormatException catch (e) {
    throw PublishException('catalog.json: ${e.message}');
  }
  if (catalog.ignored.isNotEmpty) {
    throw PublishException('catalog.json has invalid packs: ${catalog.ignored.join(' ')}');
  }
  return catalog;
}

/// The catalog with [built] added or updated.
class CatalogChange {
  const CatalogChange(this.catalog, {required this.changed, required this.summary});

  final ArtPackCatalog catalog;

  /// False when [built] was already published exactly like this.
  final bool changed;
  final String summary;
}

/// Adds [built] to [current] (null: a first catalog). A pack's versions only
/// go up, and a published version never changes: the same version with
/// different contents is refused. Each change bumps `catalogVersion`.
CatalogChange addToCatalog(ArtPackCatalog? current, BuiltPack built, {required DateTime now}) {
  final entry = built.entry;
  final existing = current?.pack(entry.id);
  if (existing != null) {
    if (entry.version < existing.version) {
      throw PublishException('${entry.id} v${entry.version} is older than the published v${existing.version}.');
    }
    if (entry.version == existing.version) {
      if (existing.archive.sha256 == entry.archive.sha256 && _sameEntry(existing, entry)) {
        return CatalogChange(current!, changed: false, summary: '${entry.id} v${entry.version} is already published.');
      }
      throw PublishException(
        '${entry.id} v${entry.version} is already published with different contents; bump its version.',
      );
    }
  }
  final packs = [
    for (final pack in current?.packs ?? const <CatalogPack>[])
      if (pack.id != entry.id) pack,
    entry,
  ]..sort((a, b) => a.id.compareTo(b.id));
  final catalog = ArtPackCatalog(
    catalogVersion: (current?.catalogVersion ?? 0) + 1,
    generatedAt: now.toUtc(),
    packs: packs,
  );
  return CatalogChange(
    catalog,
    changed: true,
    summary: existing == null
        ? 'Added ${entry.id} v${entry.version}; catalog v${catalog.catalogVersion}.'
        : 'Updated ${entry.id} v${existing.version} → v${entry.version}; catalog v${catalog.catalogVersion}.',
  );
}

bool _sameEntry(CatalogPack a, CatalogPack b) => jsonEncode(a.toJson()) == jsonEncode(b.toJson());

/// The catalog as written to disk and uploaded: stable order, indented.
List<int> encodeCatalog(ArtPackCatalog catalog) =>
    utf8.encode('${const JsonEncoder.withIndent('  ').convert(catalog.toJson())}\n');
