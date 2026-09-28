import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';

import 'bucket.dart';
import 'catalog_editor.dart';
import 'pack_builder.dart';

/// Builds a pack source into `<out>/art-packs/<id>/<version>/pack.zip` and
/// adds it to the catalog at [catalogFile]. With [dryRun], validates and
/// reports without writing anything.
Future<CatalogChange> buildAndRecord({
  required Directory source,
  required File catalogFile,
  required Directory outDir,
  required bool dryRun,
  required DateTime now,
  void Function(String) log = print,
}) async {
  final built = await buildArtPack(source);
  final current = await catalogFile.exists() ? readCatalogStrict(await catalogFile.readAsBytes()) : null;
  final change = addToCatalog(current, built, now: now);
  final archive = built.entry.archive;
  log(
    '${built.entry.id} v${built.entry.version}: ${archive.fileCount} files, '
    '${archive.compressedBytes} bytes, sha256 ${archive.sha256}',
  );
  log(change.summary);
  if (dryRun) {
    log('Dry run: nothing written.');
    return change;
  }
  final zip = File(p.join(outDir.path, archive.storagePath));
  await zip.parent.create(recursive: true);
  await zip.writeAsBytes(built.archive, flush: true);
  if (change.changed) {
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsBytes(encodeCatalog(change.catalog), flush: true);
  }
  log('Wrote ${zip.path}${change.changed ? ' and ${catalogFile.path}' : ''}.');
  return change;
}

/// What a publish uploads.
class PublishPlan {
  const PublishPlan({required this.archives, required this.catalog});

  final List<CatalogPack> archives;

  /// Whether catalog.json is uploaded (always last).
  final bool catalog;
}

/// Publishes the catalog at [catalogFile] and the archives it lists that the
/// bucket doesn't have yet. Every local archive is checked against the
/// catalog's size and SHA-256 first. Archives go up before the catalog, so
/// the app never sees a catalog pointing at a missing archive. A bucket
/// whose catalog is newer than [catalogFile] is refused (someone published
/// without committing).
///
/// With [dryRun] (or no [bucket]), everything local is validated and
/// nothing is read from or written to the bucket.
Future<PublishPlan> publishArtPacks({
  required File catalogFile,
  required Directory outDir,
  required ArtPackBucket? bucket,
  required bool dryRun,
  void Function(String) log = print,
}) async {
  if (!await catalogFile.exists()) throw PublishException('No catalog at ${catalogFile.path}. Build a pack first.');
  final catalogBytes = await catalogFile.readAsBytes();
  final catalog = readCatalogStrict(catalogBytes);
  final local = <String, Uint8List>{};
  for (final pack in catalog.packs) {
    final file = File(p.join(outDir.path, pack.archive.storagePath));
    if (!await file.exists()) continue;
    final bytes = await file.readAsBytes();
    if (bytes.length != pack.archive.compressedBytes || sha256.convert(bytes).toString() != pack.archive.sha256) {
      throw PublishException('${file.path} doesn\'t match the catalog (size or SHA-256). Rebuild it.');
    }
    local[pack.id] = bytes;
  }

  if (dryRun || bucket == null) {
    log('Dry run: catalog v${catalog.catalogVersion} with ${catalog.packs.length} packs is valid.');
    for (final pack in catalog.packs) {
      log(
        '  ${pack.id} v${pack.version}: ${local.containsKey(pack.id) ? 'archive ready' : 'no local archive (must already be uploaded)'}',
      );
    }
    log('Nothing uploaded.');
    return PublishPlan(
      archives: [
        for (final pack in catalog.packs)
          if (local.containsKey(pack.id)) pack,
      ],
      catalog: true,
    );
  }

  final remoteBytes = await bucket.read(artPackCatalogPath);
  var catalogChanged = true;
  if (remoteBytes != null) {
    final remote = readCatalogStrict(remoteBytes);
    if (remote.catalogVersion > catalog.catalogVersion) {
      throw PublishException(
        '${bucket.label} has catalog v${remote.catalogVersion}, newer than local '
        'v${catalog.catalogVersion}. Pull the published catalog first.',
      );
    }
    catalogChanged = !_sameBytes(remoteBytes, catalogBytes);
    if (remote.catalogVersion == catalog.catalogVersion && catalogChanged) {
      throw PublishException(
        '${bucket.label} has a different catalog v${catalog.catalogVersion}. Bump the catalog by building a pack.',
      );
    }
  }

  final uploads = <CatalogPack>[];
  for (final pack in catalog.packs) {
    if (await bucket.exists(pack.archive.storagePath)) continue;
    if (!local.containsKey(pack.id)) {
      throw PublishException('${pack.archive.storagePath} is in neither ${bucket.label} nor ${outDir.path}.');
    }
    uploads.add(pack);
  }
  for (final pack in uploads) {
    await bucket.write(pack.archive.storagePath, local[pack.id]!, contentType: 'application/zip');
    log('Uploaded ${pack.archive.storagePath}.');
  }
  if (catalogChanged) {
    await bucket.write(artPackCatalogPath, catalogBytes, contentType: 'application/json');
    log('Uploaded $artPackCatalogPath (v${catalog.catalogVersion}).');
  } else {
    log('${bucket.label} already has catalog v${catalog.catalogVersion}.');
  }
  return PublishPlan(archives: uploads, catalog: catalogChanged);
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
