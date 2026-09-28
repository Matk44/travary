import 'package:flutter/services.dart';

import '../../domain/domain.dart';
import '../../logic/art_pack_selection.dart';
import '../../logic/art_subjects.dart';

/// The two shapes a picture comes in.
enum ArtFormat {
  /// Full-bleed scene for the featured ticket (landscape, left side calm).
  scene,

  /// Small transparent corner decoration for normal cards.
  vignette,
}

/// Where a picture's pixels are: bundled with the app, or a file from a
/// downloaded art pack. Cards draw both the same way (see `ArtPanel`).
sealed class ArtImageRef {
  const ArtImageRef(this.path);

  final String path;
}

/// An image in the app bundle (`assets/art/...`), drawn with `AssetImage`.
final class BundledArtImage extends ArtImageRef {
  const BundledArtImage(super.path);

  @override
  bool operator ==(Object other) => other is BundledArtImage && other.path == path;

  @override
  int get hashCode => Object.hash(BundledArtImage, path);

  @override
  String toString() => 'BundledArtImage($path)';
}

/// An installed art-pack file, drawn with `FileImage`.
final class FileArtImage extends ArtImageRef {
  const FileArtImage(super.path);

  @override
  bool operator ==(Object other) => other is FileArtImage && other.path == path;

  @override
  int get hashCode => Object.hash(FileArtImage, path);

  @override
  String toString() => 'FileArtImage($path)';
}

/// One piece of card artwork: bundled (found in `assets/art/<kind>/`) or from
/// an installed art pack (described by its `pack.json`).
class ArtAsset {
  const ArtAsset({
    required this.image,
    required this.kind,
    required this.theme,
    required this.subject,
    required this.group,
    this.format,
    this.pack,
  });

  final ArtImageRef image;
  final BookingKind kind;

  /// Null means the picture suits every trip theme (`any_…`).
  final ExperienceTheme? theme;

  /// A word from [artSubjects], or [genericSubject].
  final String subject;

  /// The picture's name without its format, so a scene and its vignette
  /// pair up: `themepark_castle_01`. Only unique within its source.
  final String group;

  /// Null when one image serves both formats.
  final ArtFormat? format;

  /// The art pack it came from; null for bundled art.
  final ArtPackRef? pack;

  bool get isBundled => pack == null;

  /// Where the image is (bundle path or file path).
  String get path => image.path;

  /// The picture's globally unique key, also stored on a booking when the
  /// traveller picks it: the group for bundled art (as before packs
  /// existed), `<packId>:<group>` for pack art. Pack IDs contain no colon,
  /// so the two never collide.
  String get key => pack == null ? group : '${pack!.id}:$group';
}

/// An installed art pack's pictures, ready to merge into the catalog.
class ArtPackContent {
  const ArtPackContent({
    required this.pack,
    required this.assets,
    this.common = const {},
    this.icons = const {},
    this.sizes = const {},
    this.palette,
  });

  final ArtPackRef pack;
  final List<ArtAsset> assets;

  /// Shared textures, objects and card shells by name.
  final Map<String, ArtImageRef> common;

  /// Icons by name.
  final Map<String, ArtImageRef> icons;

  /// Pixel sizes from `pack.json`, keyed `common/<name>` or `icons/<name>`.
  final Map<String, ({int width, int height})> sizes;

  /// The pack's interface colours, if it has any.
  final DestinationPalette? palette;
}

/// A shared picture (texture, card shell or icon) and where it came from.
class SharedArtRef {
  const SharedArtRef({required this.image, required this.name, this.theme, this.pack, this.width, this.height});

  final ArtImageRef image;

  /// The name it was asked for (`featured_ticket`).
  final String name;

  /// The look a bundled picture was drawn for (from its file name), or null.
  final ExperienceTheme? theme;

  /// The pack it came from; null for bundled art.
  final ArtPackRef? pack;

  /// Pixel size, when known (pack art declares it).
  final int? width;
  final int? height;

  bool get isBundled => pack == null;

  /// The bundled file's name without extension
  /// (`coastal_resort_featured_ticket`); for pack art, `<packId>:<name>`.
  String get fileKey {
    if (pack != null) return '${pack!.id}:$name';
    final file = image.path.split('/').last;
    return file.substring(0, file.lastIndexOf('.')).toLowerCase();
  }
}

/// All card artwork: the bundled set, discovered by file name, plus any
/// installed art packs.
///
///     assets/art/<kind>/<theme>_<subject>_<number>_<format>.png
///
/// e.g. `assets/art/dining/coastal_resort_grill_01_scene.png`. The theme is
/// a current name (`urban_heritage`), a legacy one (`tropical`), or `any`.
/// Everything after the theme is optional: `tropical_01.png` is a generic
/// coastal picture used for both formats. See docs/ART_BRIEF.md.
///
/// Pack pictures keep their pack (ID, priority, selectors). Two packs may
/// both have a `urban_heritage_train_01`; their keys still differ.
class ArtCatalog {
  const ArtCatalog._(this._bundled, this._common, this._icons, this._packs);

  factory ArtCatalog.fromAssetPaths(Iterable<String> paths) {
    final assets = <BookingKind, List<ArtAsset>>{};
    final common = <String, ArtImageRef>{};
    final icons = <String, ArtImageRef>{};
    for (final path in paths) {
      final match = _artPath.firstMatch(path);
      if (match == null) continue;
      final folder = match.group(1)!;
      final fileName = match.group(2)!;
      final baseName = fileName.substring(0, fileName.lastIndexOf('.')).toLowerCase();
      if (folder == 'common') {
        common[baseName] = BundledArtImage(path);
        continue;
      }
      if (folder == 'icons') {
        icons[baseName] = BundledArtImage(path);
        continue;
      }
      final kind = BookingKind.values.where((k) => k.name == folder).firstOrNull;
      if (kind == null) continue;
      assets.putIfAbsent(kind, () => []).add(_parse(path, kind, baseName));
    }
    for (final list in assets.values) {
      list.sort((a, b) => a.path.compareTo(b.path));
    }
    return ArtCatalog._(assets, common, icons, const []);
  }

  const ArtCatalog.empty() : _bundled = const {}, _common = const {}, _icons = const {}, _packs = const [];

  static Future<ArtCatalog> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return ArtCatalog.fromAssetPaths(manifest.listAssets());
  }

  final Map<BookingKind, List<ArtAsset>> _bundled;
  final Map<String, ArtImageRef> _common;
  final Map<String, ArtImageRef> _icons;
  final List<ArtPackContent> _packs;

  /// The bundled art plus [packs], replacing any packs merged before.
  ArtCatalog withPacks(Iterable<ArtPackContent> packs) {
    final sorted = [...packs]..sort((a, b) => a.pack.id.compareTo(b.pack.id));
    return ArtCatalog._(_bundled, _common, _icons, List.unmodifiable(sorted));
  }

  bool get isEmpty => _bundled.isEmpty && _packs.every((p) => p.assets.isEmpty);

  /// The installed packs merged into this catalog.
  List<ArtPackRef> get packs => [for (final content in _packs) content.pack];

  /// Every picture for [kind]: bundled first, then each pack's.
  List<ArtAsset> allFor(BookingKind kind) => [
    ...?_bundled[kind],
    for (final content in _packs)
      for (final asset in content.assets)
        if (asset.kind == kind) asset,
  ];

  /// All pictures with [key] (a scene and/or its vignette).
  List<ArtAsset> byKey(BookingKind kind, String key) => [
    for (final asset in allFor(kind))
      if (asset.key == key) asset,
  ];

  /// A shared texture, object or card shell by name, e.g. `common('linen')`.
  /// See [commonArt].
  ArtImageRef? common(String name, {TripArtContext? context, List<ExperienceTheme> fallbackThemes = const []}) =>
      commonArt(name, context: context, fallbackThemes: fallbackThemes)?.image;

  /// An icon by name, e.g. `icon('dining')`. See [iconArt].
  ArtImageRef? icon(String name, {TripArtContext? context}) => iconArt(name, context: context)?.image;

  /// A shared picture by [name] and where it came from.
  ///
  /// Without a [context]: the bundled file with exactly that name.
  ///
  /// With one, sources are tried in the trip's rank order, exactly like card
  /// pictures (see `ArtResolver`): the city, region and country packs; the
  /// trip's look (its pack, then the bundled picture drawn for it,
  /// `coastal_resort_featured_ticket`); a secondary look; then the core:
  /// a classic pack, the bundled picture for each of [fallbackThemes]
  /// (stand-ins for looks without art of their own), classic, and finally
  /// the unthemed bundled file (`featured_ticket`). So a downloaded
  /// destination shell overrides the bundled one, and every trip still
  /// gets bundled art offline.
  SharedArtRef? commonArt(String name, {TripArtContext? context, List<ExperienceTheme> fallbackThemes = const []}) =>
      _shared(name, context, _common, (content) => content.common[name], 'common', fallbackThemes);

  /// An icon by name and where it came from, ranked like [commonArt].
  SharedArtRef? iconArt(String name, {TripArtContext? context}) =>
      _shared(name, context, _icons, (content) => content.icons[name], 'icons', const []);

  /// The trip's interface palette: the best-ranked suitable pack that has
  /// one (packs without a palette are skipped), else Travary's own.
  DestinationPalette palette({TripArtContext? context}) {
    if (context == null) return DestinationPalette.bundled;
    for (final rank in context.rankOrder) {
      final content = _bestPack(context, rank, (content) => content.palette);
      if (content != null) return content.palette!;
    }
    return DestinationPalette.bundled;
  }

  SharedArtRef? _shared(
    String name,
    TripArtContext? context,
    Map<String, ArtImageRef> bundled,
    ArtImageRef? Function(ArtPackContent) find,
    String folder,
    List<ExperienceTheme> fallbackThemes,
  ) {
    SharedArtRef? bundledFor(ExperienceTheme? theme) {
      final key = theme == null ? name : _themedName(theme, name, bundled);
      final image = key == null ? null : bundled[key];
      return image == null ? null : SharedArtRef(image: image, name: name, theme: theme);
    }

    if (context == null) return bundledFor(null);
    for (final rank in context.rankOrder) {
      final content = _bestPack(context, rank, find);
      if (content != null) {
        final size = content.sizes['$folder/$name'];
        return SharedArtRef(
          image: find(content)!,
          name: name,
          pack: content.pack,
          width: size?.width,
          height: size?.height,
        );
      }
      final found = switch (rank) {
        ArtRank.primary => bundledFor(context.theme),
        ArtRank.secondary => context.secondaryThemes.map(bundledFor).nonNulls.firstOrNull,
        ArtRank.core => [
          ...fallbackThemes.map(bundledFor),
          bundledFor(ExperienceTheme.classicTravel),
          bundledFor(null),
        ].nonNulls.firstOrNull,
        _ => null,
      };
      if (found != null) return found;
    }
    return null;
  }

  /// The installed pack ranked [rank] for [context] that has what [find]
  /// looks for, preferring the higher catalog priority.
  ArtPackContent? _bestPack(TripArtContext context, ArtRank rank, Object? Function(ArtPackContent) find) {
    ArtPackContent? best;
    for (final content in _packs) {
      if (context.packRanks[content.pack.id] != rank || find(content) == null) continue;
      if (best == null || content.pack.priority > best.pack.priority) best = content;
    }
    return best;
  }
}

/// Bundled shared-art file names may start with a look, so each look can
/// have its own shells: `urban_heritage_room_card`. Besides the current
/// and legacy theme names, the first shell families were named after their
/// look's longer title; these aliases keep those files working as they are.
const bundledThemePrefixAliases = <String, ExperienceTheme>{
  'alpine_adventure': ExperienceTheme.alpine,
  'countryside_escape': ExperienceTheme.countryside,
};

/// The bundled file name for [name] drawn for [theme], if [available] has one.
String? _themedName(ExperienceTheme theme, String name, Map<String, ArtImageRef> available) {
  for (final prefix in [
    theme.wireName,
    for (final entry in bundledThemePrefixAliases.entries)
      if (entry.value == theme) entry.key,
    for (final entry in ExperienceTheme.legacyAliases.entries)
      if (entry.value == theme && entry.key != theme.wireName) entry.key,
  ]) {
    final key = '${prefix}_$name';
    if (available.containsKey(key)) return key;
  }
  return null;
}

final _artPath = RegExp(r'^assets/art/([a-z]+)/([^/]+\.(?:png|jpe?g|webp))$', caseSensitive: false);

/// Theme prefixes a bundled file name may start with: current names (some
/// have two words) and legacy ones. Longest first, so `classic_travel`
/// isn't read as `classic` + a subject called "travel".
final List<(List<String>, ExperienceTheme)> _themePrefixes = [
  for (final theme in ExperienceTheme.values) (theme.wireName.split('_'), theme),
  for (final entry in ExperienceTheme.legacyAliases.entries) ([entry.key], entry.value),
]..sort((a, b) => b.$1.length.compareTo(a.$1.length));

ArtAsset _parse(String path, BookingKind kind, String baseName) {
  final parts = baseName.split(RegExp(r'[_\-\s]+')).where((p) => p.isNotEmpty).toList();

  ArtFormat? format;
  if (parts.isNotEmpty) {
    format = ArtFormat.values.where((f) => f.name == parts.last).firstOrNull;
    if (format != null) parts.removeLast();
  }
  final group = parts.join('_');

  ExperienceTheme? theme = ExperienceTheme.classicTravel;
  if (parts.isNotEmpty && parts.first == 'any') {
    theme = null;
    parts.removeAt(0);
  } else {
    for (final (words, named) in _themePrefixes) {
      if (parts.length >= words.length && _startsWith(parts, words)) {
        theme = named;
        parts.removeRange(0, words.length);
        break;
      }
    }
  }

  final subject = parts.isNotEmpty && isArtSubject(kind, parts.first) ? parts.first : genericSubject;
  return ArtAsset(
    image: BundledArtImage(path),
    kind: kind,
    theme: theme,
    subject: subject,
    group: group,
    format: format,
  );
}

bool _startsWith(List<String> parts, List<String> words) {
  for (var i = 0; i < words.length; i++) {
    if (parts[i] != words[i]) return false;
  }
  return true;
}
