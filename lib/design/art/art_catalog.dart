import 'package:flutter/services.dart';

import '../../domain/domain.dart';
import '../../logic/art_subjects.dart';

/// The two shapes a picture comes in.
enum ArtFormat {
  /// Full-bleed scene for the featured ticket (landscape, left side calm).
  scene,

  /// Small transparent corner decoration for normal cards.
  vignette,
}

/// One piece of card artwork found in `assets/art/<kind>/`.
class ArtAsset {
  const ArtAsset({
    required this.path,
    required this.kind,
    required this.theme,
    required this.subject,
    required this.group,
    this.format,
  });

  final String path;
  final BookingKind kind;

  /// Null means the picture suits every trip theme (`any_…`).
  final TripTheme? theme;

  /// A word from [artSubjects], or [genericSubject].
  final String subject;

  /// The picture's name without its format, so a scene and its vignette
  /// pair up: `themepark_castle_01`.
  final String group;

  /// Null when one image serves both formats.
  final ArtFormat? format;

  /// The key stored on a booking when the traveller picks this artwork.
  String get key => group;
}

/// All card artwork bundled with the app, discovered by file name:
///
///     assets/art/<kind>/<theme>_<subject>_<number>_<format>.png
///
/// e.g. `assets/art/dining/tropical_grill_01_scene.png`. Everything after the
/// theme is optional: `tropical_01.png` is a generic tropical picture used
/// for both formats. See docs/ART_BRIEF.md.
class ArtCatalog {
  ArtCatalog._(this._assets, this._common, this._icons);

  factory ArtCatalog.fromAssetPaths(Iterable<String> paths) {
    final assets = <BookingKind, List<ArtAsset>>{};
    final common = <String, String>{};
    final icons = <String, String>{};
    for (final path in paths) {
      final match = _artPath.firstMatch(path);
      if (match == null) continue;
      final folder = match.group(1)!;
      final fileName = match.group(2)!;
      final baseName = fileName.substring(0, fileName.lastIndexOf('.')).toLowerCase();
      if (folder == 'common') {
        common[baseName] = path;
        continue;
      }
      if (folder == 'icons') {
        icons[baseName] = path;
        continue;
      }
      final kind = BookingKind.values.where((k) => k.name == folder).firstOrNull;
      if (kind == null) continue;
      assets.putIfAbsent(kind, () => []).add(_parse(path, kind, baseName));
    }
    for (final list in assets.values) {
      list.sort((a, b) => a.path.compareTo(b.path));
    }
    return ArtCatalog._(assets, common, icons);
  }

  const ArtCatalog.empty() : _assets = const {}, _common = const {}, _icons = const {};

  static Future<ArtCatalog> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return ArtCatalog.fromAssetPaths(manifest.listAssets());
  }

  final Map<BookingKind, List<ArtAsset>> _assets;
  final Map<String, String> _common;
  final Map<String, String> _icons;

  bool get isEmpty => _assets.isEmpty;

  /// Every picture for [kind].
  List<ArtAsset> allFor(BookingKind kind) => _assets[kind] ?? const [];

  /// All pictures in [group] (a scene and/or its vignette).
  List<ArtAsset> group(BookingKind kind, String group) =>
      [for (final a in allFor(kind)) if (a.group == group) a];

  /// Shared textures and objects by name, e.g. `common('linen')`.
  String? common(String name) => _common[name];

  /// Icons by name, e.g. `icon('dining')`, `icon('nav_today')`.
  String? icon(String name) => _icons[name];
}

final _artPath = RegExp(r'^assets/art/([a-z]+)/([^/]+\.(?:png|jpe?g|webp))$', caseSensitive: false);

ArtAsset _parse(String path, BookingKind kind, String baseName) {
  final parts = baseName.split(RegExp(r'[_\-\s]+')).where((p) => p.isNotEmpty).toList();

  ArtFormat? format;
  if (parts.isNotEmpty) {
    format = ArtFormat.values.where((f) => f.name == parts.last).firstOrNull;
    if (format != null) parts.removeLast();
  }
  final group = parts.join('_');

  TripTheme? theme = TripTheme.classic;
  if (parts.isNotEmpty && parts.first == 'any') {
    theme = null;
    parts.removeAt(0);
  } else if (parts.isNotEmpty) {
    final named = TripTheme.values.where((t) => t.name == parts.first).firstOrNull;
    if (named != null) {
      theme = named;
      parts.removeAt(0);
    }
  }

  final subject = parts.isNotEmpty && isArtSubject(kind, parts.first) ? parts.first : genericSubject;
  return ArtAsset(path: path, kind: kind, theme: theme, subject: subject, group: group, format: format);
}
