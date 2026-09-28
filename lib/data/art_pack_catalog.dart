import 'dart:convert';

import '../domain/domain.dart';
import '../logic/art_subjects.dart';

/// The formats of downloadable art packs, and their validation. Shared by
/// the app (downloads) and `tool/art_packs.dart` (publishing), so both
/// accept exactly the same packs. Pure Dart: no Flutter imports.
///
///     art-packs/catalog.json                  the only discovery point
///     art-packs/<pack-id>/<version>/pack.zip  pack.json + images
///
/// Nothing here comes from Gemini: the app matches validated catalog
/// entries to a trip's normalised profile.

/// Hard limits, independent of what a catalog claims.
abstract final class ArtPackLimits {
  static const catalogSchemaVersion = 1;
  static const manifestSchemaVersion = 1;
  static const maxCatalogBytes = 2 * 1024 * 1024;
  static const maxPacksInCatalog = 2000;
  static const maxCompressedBytes = 100 * 1024 * 1024;
  static const maxUncompressedBytes = 300 * 1024 * 1024;
  static const maxFileCount = 500;
  static const maxManifestBytes = 1024 * 1024;
  static const maxSelectorValues = 64;
  static const maxVersion = 1000000;
  static const maxPriority = 10000;
  static const maxImageSide = 8192;

  /// Downloaded packs no current or upcoming trip needs are evicted, least
  /// recently used first, beyond this total.
  static const unpinnedCacheBudgetBytes = 200 * 1024 * 1024;
}

/// A catalog, manifest or archive that must not be used.
class ArtPackFormatException implements Exception {
  const ArtPackFormatException(this.message);

  final String message;

  @override
  String toString() => 'ArtPackFormatException: $message';
}

final _idPattern = RegExp(r'^[a-z0-9_]{1,64}$');
final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

/// Pack IDs, slugs and names: lowercase ASCII letters, digits, `_`.
bool isArtPackId(Object? value) => value is String && _idPattern.hasMatch(value);

/// The one place a pack's archive may live.
String artPackStoragePath(String id, int version) => 'art-packs/$id/$version/pack.zip';

const artPackCatalogPath = 'art-packs/catalog.json';

/// Every subject any booking kind may show, plus [genericSubject].
final Set<String> knownArtSubjects = {genericSubject, for (final subjects in artSubjects.values) ...subjects.keys};

// ------------------------------------------------------------------ catalog

/// Size, hash and contents of a pack's archive, as the catalog states them.
class ArtPackArchive {
  const ArtPackArchive({
    required this.storagePath,
    required this.sha256,
    required this.compressedBytes,
    required this.uncompressedBytes,
    required this.fileCount,
  });

  final String storagePath;

  /// Lowercase hex.
  final String sha256;
  final int compressedBytes;
  final int uncompressedBytes;

  /// Every entry in the zip, `pack.json` included.
  final int fileCount;

  Map<String, Object?> toJson() => {
    'storagePath': storagePath,
    'sha256': sha256,
    'compressedBytes': compressedBytes,
    'uncompressedBytes': uncompressedBytes,
    'fileCount': fileCount,
  };
}

/// One pack in the catalog.
class CatalogPack {
  const CatalogPack({required this.ref, required this.archive, required this.minAppBuild});

  final ArtPackRef ref;
  final ArtPackArchive archive;

  /// Older app builds ignore the pack.
  final int minAppBuild;

  String get id => ref.id;
  int get version => ref.version;

  Map<String, Object?> toJson() => {
    'id': ref.id,
    'version': ref.version,
    'priority': ref.priority,
    'selectors': ref.selectors.toJson(),
    'archive': archive.toJson(),
    'minAppBuild': minAppBuild,
  };

  /// A pack entry, or null (with the reason in [problems]) when invalid.
  static CatalogPack? tryParse(Object? json, {List<String>? problems}) {
    try {
      return _parsePack(json);
    } on ArtPackFormatException catch (e) {
      problems?.add(e.message);
      return null;
    }
  }
}

/// The remote list of art packs (`art-packs/catalog.json`).
class ArtPackCatalog {
  const ArtPackCatalog({
    required this.catalogVersion,
    required this.generatedAt,
    required this.packs,
    this.ignored = const [],
  });

  final int catalogVersion;
  final DateTime generatedAt;

  /// Valid packs this app build can use.
  final List<CatalogPack> packs;

  /// Why individual packs were left out (diagnostics).
  final List<String> ignored;

  CatalogPack? pack(String id) {
    for (final pack in packs) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  /// Validates [bytes]. Throws [ArtPackFormatException] when the catalog as
  /// a whole can't be trusted (too big, not JSON, unknown schema, bad core
  /// fields, duplicate IDs); an individual invalid pack is only skipped, as
  /// is one that needs a newer app than [appBuild].
  static ArtPackCatalog parse(List<int> bytes, {required int appBuild}) {
    if (bytes.length > ArtPackLimits.maxCatalogBytes) {
      throw const ArtPackFormatException('Catalog is larger than 2 MiB.');
    }
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const ArtPackFormatException('Catalog is not UTF-8 JSON.');
    }
    if (json is! Map) throw const ArtPackFormatException('Catalog is not an object.');
    if (json['schemaVersion'] != ArtPackLimits.catalogSchemaVersion) {
      throw const ArtPackFormatException('Unknown catalog schema version.');
    }
    final catalogVersion = _positiveInt(json['catalogVersion'], max: 1 << 31, what: 'catalogVersion');
    final generatedAtRaw = json['generatedAt'];
    final generatedAt = generatedAtRaw is String ? DateTime.tryParse(generatedAtRaw) : null;
    if (generatedAt == null) throw const ArtPackFormatException('Catalog generatedAt is not a date.');
    final rawPacks = json['packs'];
    if (rawPacks is! List) throw const ArtPackFormatException('Catalog packs is not a list.');
    if (rawPacks.length > ArtPackLimits.maxPacksInCatalog) {
      throw const ArtPackFormatException('Catalog lists too many packs.');
    }
    final ids = <String>{};
    for (final raw in rawPacks) {
      final id = raw is Map ? raw['id'] : null;
      if (id is String && !ids.add(id)) throw ArtPackFormatException('Pack "$id" is listed twice.');
    }

    final packs = <CatalogPack>[];
    final ignored = <String>[];
    for (final raw in rawPacks) {
      final pack = CatalogPack.tryParse(raw, problems: ignored);
      if (pack == null) continue;
      if (pack.minAppBuild > appBuild) {
        ignored.add('${pack.id}: needs app build ${pack.minAppBuild}.');
        continue;
      }
      packs.add(pack);
    }
    return ArtPackCatalog(
      catalogVersion: catalogVersion,
      generatedAt: generatedAt.toUtc(),
      packs: List.unmodifiable(packs),
      ignored: List.unmodifiable(ignored),
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': ArtPackLimits.catalogSchemaVersion,
    'catalogVersion': catalogVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'packs': [for (final pack in packs) pack.toJson()],
  };
}

CatalogPack _parsePack(Object? json) {
  if (json is! Map) throw const ArtPackFormatException('A pack is not an object.');
  final id = json['id'];
  if (!isArtPackId(id)) throw ArtPackFormatException('Invalid pack id "$id".');
  id as String;
  final version = _positiveInt(json['version'], max: ArtPackLimits.maxVersion, what: '$id version');
  final priority = json['priority'];
  if (priority is! int || priority < 0 || priority > ArtPackLimits.maxPriority) {
    throw ArtPackFormatException('$id: priority must be 0–${ArtPackLimits.maxPriority}.');
  }
  final selectors = parseArtPackSelectors(json['selectors'], packId: id);

  final archive = json['archive'];
  if (archive is! Map) throw ArtPackFormatException('$id: archive is missing.');
  final storagePath = archive['storagePath'];
  if (storagePath != artPackStoragePath(id, version)) {
    throw ArtPackFormatException('$id: archive must be at ${artPackStoragePath(id, version)}.');
  }
  final sha256 = archive['sha256'];
  if (sha256 is! String || !_sha256Pattern.hasMatch(sha256)) {
    throw ArtPackFormatException('$id: sha256 must be 64 lowercase hex characters.');
  }
  final compressed = _positiveInt(
    archive['compressedBytes'],
    max: ArtPackLimits.maxCompressedBytes,
    what: '$id compressedBytes',
  );
  final uncompressed = _positiveInt(
    archive['uncompressedBytes'],
    max: ArtPackLimits.maxUncompressedBytes,
    what: '$id uncompressedBytes',
  );
  final fileCount = _positiveInt(archive['fileCount'], max: ArtPackLimits.maxFileCount, what: '$id fileCount');
  if (fileCount < 2) throw ArtPackFormatException('$id: a pack holds pack.json and at least one image.');
  final minAppBuild = _positiveInt(json['minAppBuild'], max: 1 << 31, what: '$id minAppBuild');

  return CatalogPack(
    ref: ArtPackRef(id: id, version: version, priority: priority, selectors: selectors),
    archive: ArtPackArchive(
      storagePath: storagePath as String,
      sha256: sha256,
      compressedBytes: compressed,
      uncompressedBytes: uncompressed,
      fileCount: fileCount,
    ),
    minAppBuild: minAppBuild,
  );
}

/// Validates a `selectors` object: known country codes, slugs, themes and
/// subjects only, a sensible scope (city and region packs name their
/// country; a pack with no place has themes).
ArtPackSelectors parseArtPackSelectors(Object? json, {required String packId}) {
  if (json is! Map) throw ArtPackFormatException('$packId: selectors are missing.');
  List<String> strings(String key, bool Function(String) valid, String what) {
    final raw = json[key];
    if (raw == null) return const [];
    if (raw is! List || raw.length > ArtPackLimits.maxSelectorValues) {
      throw ArtPackFormatException('$packId: $key must be a list of at most ${ArtPackLimits.maxSelectorValues}.');
    }
    final values = <String>[];
    for (final value in raw) {
      if (value is! String || !valid(value)) throw ArtPackFormatException('$packId: "$value" is not a known $what.');
      if (!values.contains(value)) values.add(value);
    }
    return List.unmodifiable(values);
  }

  final selectors = ArtPackSelectors(
    countryCodes: strings('countryCodes', isoCountryCodes.contains, 'ISO country code'),
    regions: strings('regions', isSlug, 'region slug'),
    cities: strings('cities', isSlug, 'city slug'),
    themes: [
      for (final name in strings('themes', (v) => ExperienceTheme.values.any((t) => t.wireName == v), 'theme'))
        ExperienceTheme.values.firstWhere((t) => t.wireName == name),
    ],
    subjects: strings('subjects', knownArtSubjects.contains, 'subject'),
  );
  final scope = selectors.scope;
  if ((scope == ArtPackScope.city || scope == ArtPackScope.region) && selectors.countryCodes.isEmpty) {
    throw ArtPackFormatException('$packId: city and region packs must name their country.');
  }
  if (scope == ArtPackScope.experience && selectors.themes.isEmpty) {
    throw ArtPackFormatException('$packId: a pack needs a place or a theme.');
  }
  return selectors;
}

int _positiveInt(Object? value, {required int max, required String what}) {
  if (value is! int || value < 1 || value > max) throw ArtPackFormatException('$what must be 1–$max.');
  return value;
}

// ----------------------------------------------------------------- pack.json

/// The folders a pack may contain: one per booking kind, plus shared art.
const artPackFolders = {
  'common',
  'icons',
  'flight',
  'stay',
  'attraction',
  'dining',
  'transport',
  'activity',
  'event',
  'note',
};

/// Raster formats only: no SVG, HTML, scripts, fonts or binaries.
const artPackImageExtensions = {'png', 'webp', 'jpg', 'jpeg'};

const artPackManifestName = 'pack.json';

final _fileNamePattern = RegExp(r'^[a-z0-9][a-z0-9_-]{0,99}\.(png|webp|jpg|jpeg)$');

/// Validates a path inside a pack: exactly `pack.json` or
/// `<folder>/<name>.<png|webp|jpg|jpeg>`. Relative and normalised (no
/// absolute path, backslash, empty, `.` or `..` segment), lowercase ASCII.
/// Throws [ArtPackFormatException].
String validateArtPackPath(String path) {
  if (path.isEmpty) throw const ArtPackFormatException('Empty path.');
  if (path.startsWith('/') || path.contains('\\') || RegExp(r'^[A-Za-z]:').hasMatch(path)) {
    throw ArtPackFormatException('"$path" is not a relative path.');
  }
  final segments = path.split('/');
  if (segments.any((s) => s.isEmpty || s == '.' || s == '..')) {
    throw ArtPackFormatException('"$path" is not a normalised path.');
  }
  if (path == artPackManifestName) return path;
  if (segments.length != 2 || !artPackFolders.contains(segments.first)) {
    throw ArtPackFormatException('"$path" is not in an art folder.');
  }
  if (!_fileNamePattern.hasMatch(segments.last)) {
    throw ArtPackFormatException('"$path" is not a PNG, WebP or JPEG with a plain name.');
  }
  return path;
}

/// One image a pack declares.
sealed class PackAssetEntry {
  const PackAssetEntry({required this.file, required this.width, required this.height});

  /// Path inside the pack, e.g. `transport/urban_heritage_train_01_scene.webp`.
  final String file;
  final int width;
  final int height;

  Map<String, Object?> toJson();
}

/// Card artwork for one booking kind.
class PackCardArt extends PackAssetEntry {
  const PackCardArt({
    required super.file,
    required this.kind,
    required this.theme,
    required this.subject,
    required this.group,
    required this.format,
    required super.width,
    required super.height,
  });

  final BookingKind kind;

  /// Null: suits any look.
  final ExperienceTheme? theme;
  final String subject;
  final String group;

  /// `scene`, `vignette`, or null for one image serving both.
  final String? format;

  @override
  Map<String, Object?> toJson() => {
    'file': file,
    'kind': kind.name,
    'theme': theme?.wireName ?? 'any',
    'subject': subject,
    'group': group,
    'format': format ?? 'both',
    'width': width,
    'height': height,
  };
}

/// A shared texture/object (`common`) or an icon (`icon`).
class PackSharedArt extends PackAssetEntry {
  const PackSharedArt({
    required super.file,
    required this.role,
    required this.name,
    required super.width,
    required super.height,
    this.themes = const [],
  });

  /// `common` or `icon`.
  final String role;
  final String name;

  /// The looks this picture is for; empty means every trip the pack suits.
  /// A country pack's featured ticket drawn for historic cities shouldn't
  /// dress a beach trip in the same country.
  final List<ExperienceTheme> themes;

  @override
  Map<String, Object?> toJson() => {
    'file': file,
    'kind': role,
    'name': name,
    if (themes.isNotEmpty) 'themes': [for (final theme in themes) theme.wireName],
    'width': width,
    'height': height,
  };
}

/// A pack's `pack.json`: its identity, its optional interface palette and
/// explicit metadata for every image.
class PackManifest {
  const PackManifest({required this.packId, required this.version, required this.assets, this.palette});

  final String packId;
  final int version;
  final List<PackAssetEntry> assets;

  /// The destination's UI colours. Optional: packs made before palettes
  /// existed have none, and the next-ranked palette is used instead.
  final DestinationPalette? palette;

  Iterable<String> get files => assets.map((a) => a.file);

  Map<String, Object?> toJson() => {
    'schemaVersion': ArtPackLimits.manifestSchemaVersion,
    'packId': packId,
    'version': version,
    if (palette != null) 'palette': palette!.toJson(),
    'assets': [for (final asset in assets) asset.toJson()],
  };

  /// Validates [bytes]. With [expectedId]/[expectedVersion], they must
  /// match exactly. Throws [ArtPackFormatException].
  static PackManifest parse(List<int> bytes, {String? expectedId, int? expectedVersion}) {
    if (bytes.length > ArtPackLimits.maxManifestBytes) throw const ArtPackFormatException('pack.json is too big.');
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const ArtPackFormatException('pack.json is not UTF-8 JSON.');
    }
    if (json is! Map) throw const ArtPackFormatException('pack.json is not an object.');
    if (json['schemaVersion'] != ArtPackLimits.manifestSchemaVersion) {
      throw const ArtPackFormatException('Unknown pack.json schema version.');
    }
    final packId = json['packId'];
    if (!isArtPackId(packId)) throw const ArtPackFormatException('pack.json has an invalid packId.');
    packId as String;
    final version = _positiveInt(json['version'], max: ArtPackLimits.maxVersion, what: 'pack.json version');
    if (expectedId != null && packId != expectedId) {
      throw ArtPackFormatException('pack.json is for "$packId", not "$expectedId".');
    }
    if (expectedVersion != null && version != expectedVersion) {
      throw ArtPackFormatException('pack.json is version $version, not $expectedVersion.');
    }
    // A palette that is present must be entirely valid; a bad one rejects
    // the whole pack rather than silently falling back.
    final palette = json.containsKey('palette') ? parseArtPackPalette(json['palette'], packId: packId) : null;
    final rawAssets = json['assets'];
    if (rawAssets is! List || rawAssets.isEmpty || rawAssets.length >= ArtPackLimits.maxFileCount) {
      throw const ArtPackFormatException('pack.json must list at least one image, within the file limit.');
    }

    final assets = <PackAssetEntry>[];
    final files = <String>{};
    final cardSlots = <String>{};
    final sharedNames = <String>{};
    for (final raw in rawAssets) {
      final asset = _parseAsset(raw);
      if (!files.add(asset.file)) throw ArtPackFormatException('"${asset.file}" is declared twice.');
      switch (asset) {
        case PackCardArt():
          // One scene and one vignette per group, or one image for both.
          final slots = asset.format == null
              ? ['${asset.kind.name}/${asset.group}/scene', '${asset.kind.name}/${asset.group}/vignette']
              : ['${asset.kind.name}/${asset.group}/${asset.format}'];
          for (final slot in slots) {
            if (!cardSlots.add(slot)) {
              throw ArtPackFormatException('Group "${asset.group}" has two ${slot.split('/').last}s.');
            }
          }
        case PackSharedArt():
          if (!sharedNames.add('${asset.role}/${asset.name}')) {
            throw ArtPackFormatException('${asset.role} "${asset.name}" is declared twice.');
          }
      }
      assets.add(asset);
    }
    return PackManifest(packId: packId, version: version, assets: List.unmodifiable(assets), palette: palette);
  }
}

/// Validates a pack's `palette` (see [DestinationPalette.parse]). Throws
/// [ArtPackFormatException].
DestinationPalette parseArtPackPalette(Object? json, {required String packId}) {
  try {
    return DestinationPalette.parse(json);
  } on FormatException catch (e) {
    throw ArtPackFormatException('$packId: ${e.message}');
  }
}

PackAssetEntry _parseAsset(Object? raw) {
  if (raw is! Map) throw const ArtPackFormatException('An asset is not an object.');
  final file = raw['file'];
  if (file is! String || file == artPackManifestName) throw const ArtPackFormatException('An asset has no image file.');
  validateArtPackPath(file);
  final folder = file.split('/').first;
  final width = _positiveInt(raw['width'], max: ArtPackLimits.maxImageSide, what: '$file width');
  final height = _positiveInt(raw['height'], max: ArtPackLimits.maxImageSide, what: '$file height');
  final kindName = raw['kind'];

  if (kindName == 'common' || kindName == 'icon') {
    final expectedFolder = kindName == 'common' ? 'common' : 'icons';
    if (folder != expectedFolder) throw ArtPackFormatException('$file: $kindName art belongs in $expectedFolder/.');
    final name = raw['name'];
    if (!isArtPackId(name)) throw ArtPackFormatException('$file: invalid name.');
    final rawThemes = raw['themes'];
    final themes = <ExperienceTheme>[];
    if (rawThemes != null) {
      if (rawThemes is! List || rawThemes.isEmpty) {
        throw ArtPackFormatException('$file: themes must be a non-empty list (leave it out for every look).');
      }
      for (final value in rawThemes) {
        final theme = ExperienceTheme.values.where((t) => t.wireName == value).firstOrNull;
        if (theme == null) throw ArtPackFormatException('$file: unknown theme "$value".');
        if (!themes.contains(theme)) themes.add(theme);
      }
    }
    return PackSharedArt(
      file: file,
      role: kindName as String,
      name: name as String,
      width: width,
      height: height,
      themes: List.unmodifiable(themes),
    );
  }

  final kind = BookingKind.values.where((k) => k.name == kindName).firstOrNull;
  if (kind == null) throw ArtPackFormatException('$file: unknown kind "$kindName".');
  if (folder != kind.name) throw ArtPackFormatException('$file: ${kind.name} art belongs in ${kind.name}/.');

  final themeName = raw['theme'];
  final ExperienceTheme? theme;
  if (themeName == 'any') {
    theme = null;
  } else {
    theme = ExperienceTheme.values.where((t) => t.wireName == themeName).firstOrNull;
    if (theme == null) throw ArtPackFormatException('$file: unknown theme "$themeName".');
  }
  final subject = raw['subject'];
  if (subject is! String || !isArtSubject(kind, subject)) {
    throw ArtPackFormatException('$file: "$subject" is not a ${kind.name} subject.');
  }
  final group = raw['group'];
  if (!isArtPackId(group)) throw ArtPackFormatException('$file: invalid group.');
  final format = raw['format'];
  if (format != 'scene' && format != 'vignette' && format != 'both') {
    throw ArtPackFormatException('$file: format must be scene, vignette or both.');
  }
  return PackCardArt(
    file: file,
    kind: kind,
    theme: theme,
    subject: subject,
    group: group as String,
    format: format == 'both' ? null : format as String,
    width: width,
    height: height,
  );
}
