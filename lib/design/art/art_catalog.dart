import 'package:flutter/services.dart';

import '../../domain/domain.dart';

/// One piece of card artwork found in `assets/art/<kind>/`.
class ArtAsset {
  const ArtAsset({required this.path, required this.kind, required this.theme});

  final String path;
  final BookingKind kind;
  final TripTheme theme;

  /// The key stored on a booking when the traveller picks this artwork.
  String get key => path;
}

/// All card artwork bundled with the app, discovered by naming convention:
///
///     assets/art/<kind>/<theme>_<anything>.png
///
/// e.g. `assets/art/dining/tropical_01.png`. A file with no recognised theme
/// prefix counts as `classic`. See `assets/art/README.md`.
class ArtCatalog {
  ArtCatalog._(this._assets, this._common);

  factory ArtCatalog.fromAssetPaths(Iterable<String> paths) {
    final assets = <BookingKind, Map<TripTheme, List<ArtAsset>>>{};
    final common = <String, String>{};
    for (final path in paths) {
      final match = _artPath.firstMatch(path);
      if (match == null) continue;
      final folder = match.group(1)!;
      final fileName = match.group(2)!;
      final baseName = fileName.substring(0, fileName.lastIndexOf('.'));
      if (folder == 'common') {
        common[baseName] = path;
        continue;
      }
      final kind = BookingKind.values.where((k) => k.name == folder).firstOrNull;
      if (kind == null) continue;
      final theme = _themeOf(baseName);
      assets
          .putIfAbsent(kind, () => {})
          .putIfAbsent(theme, () => [])
          .add(ArtAsset(path: path, kind: kind, theme: theme));
    }
    for (final byTheme in assets.values) {
      for (final list in byTheme.values) {
        list.sort((a, b) => a.path.compareTo(b.path));
      }
    }
    return ArtCatalog._(assets, common);
  }

  const ArtCatalog.empty() : _assets = const {}, _common = const {};

  static Future<ArtCatalog> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return ArtCatalog.fromAssetPaths(manifest.listAssets());
  }

  final Map<BookingKind, Map<TripTheme, List<ArtAsset>>> _assets;
  final Map<String, String> _common;

  bool get isEmpty => _assets.isEmpty;

  /// Artwork for [kind] in [theme], falling back to `classic`, then to any
  /// theme, then to nothing (cards draw a placeholder).
  List<ArtAsset> assetsFor(BookingKind kind, TripTheme theme) {
    final byTheme = _assets[kind];
    if (byTheme == null || byTheme.isEmpty) return const [];
    return byTheme[theme] ??
        byTheme[TripTheme.classic] ??
        byTheme.values.expand((list) => list).toList();
  }

  /// Every piece of artwork for [kind], for an "change artwork" picker.
  List<ArtAsset> allFor(BookingKind kind) => [
    for (final list in (_assets[kind] ?? const {}).values) ...list,
  ];

  ArtAsset? byKey(String? key) {
    if (key == null) return null;
    for (final byTheme in _assets.values) {
      for (final list in byTheme.values) {
        for (final asset in list) {
          if (asset.key == key) return asset;
        }
      }
    }
    return null;
  }

  /// Shared textures by base name, e.g. `common('linen')` for
  /// `assets/art/common/linen.png`.
  String? common(String name) => _common[name];
}

final _artPath = RegExp(
  r'^assets/art/([a-z]+)/([^/]+\.(?:png|jpe?g|webp))$',
  caseSensitive: false,
);

TripTheme _themeOf(String baseName) {
  final prefix = baseName.split(RegExp(r'[_\-\s]')).first.toLowerCase();
  return TripTheme.values.where((t) => t.name == prefix).firstOrNull ??
      TripTheme.classic;
}
