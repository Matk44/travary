import 'package:flutter/foundation.dart';

import '../data/art_pack_catalog.dart';
import '../data/art_pack_service.dart';
import '../data/art_pack_store.dart';
import '../design/art/art_catalog.dart';
import '../domain/domain.dart';

/// The artwork catalog cards resolve against: the bundled art plus every
/// validated installed pack. Rebuilt, and listeners told, whenever a pack is
/// installed, updated or evicted, so visible cards change without a restart.
class ArtCatalogController extends ChangeNotifier {
  ArtCatalogController({required this.bundled, this.packs}) {
    packs?.addListener(_packsChanged);
    _rebuild();
  }

  final ArtCatalog bundled;
  final ArtPackManager? packs;

  late ArtCatalog _catalog;
  String? _installedKey;

  ArtCatalog get catalog => _catalog;

  void _packsChanged() {
    if (_rebuild()) notifyListeners();
  }

  /// Rebuilds the catalog if the installed set changed; returns whether it did.
  /// Without a pack manager the catalog is used exactly as given.
  bool _rebuild() {
    if (packs == null) {
      if (_installedKey != null) return false;
      _installedKey = '';
      _catalog = bundled;
      return true;
    }
    final installed = packs!.installed;
    final key = [for (final pack in installed) '${pack.id}@${pack.version}@${pack.directory.path}'].join('|');
    if (key == _installedKey) return false;
    _installedKey = key;
    _catalog = bundled.withPacks([for (final pack in installed) artPackContentOf(pack)]);
    return true;
  }

  @override
  void dispose() {
    packs?.removeListener(_packsChanged);
    super.dispose();
  }
}

/// An installed pack's `pack.json` as catalog entries, pointing at its files.
ArtPackContent artPackContentOf(InstalledArtPack pack) {
  final assets = <ArtAsset>[];
  final common = <String, ArtImageRef>{};
  final icons = <String, ArtImageRef>{};
  final sizes = <String, ({int width, int height})>{};
  final themes = <String, List<ExperienceTheme>>{};
  for (final entry in pack.manifest.assets) {
    final image = FileArtImage(pack.file(entry.file).path);
    switch (entry) {
      case PackCardArt():
        assets.add(
          ArtAsset(
            image: image,
            kind: entry.kind,
            theme: entry.theme,
            subject: entry.subject,
            group: entry.group,
            format: switch (entry.format) {
              'scene' => ArtFormat.scene,
              'vignette' => ArtFormat.vignette,
              _ => null,
            },
            pack: pack.ref,
          ),
        );
      case PackSharedArt(role: 'common'):
        common[entry.name] = image;
        sizes['common/${entry.name}'] = (width: entry.width, height: entry.height);
        if (entry.themes.isNotEmpty) themes['common/${entry.name}'] = entry.themes;
      case PackSharedArt():
        icons[entry.name] = image;
        sizes['icons/${entry.name}'] = (width: entry.width, height: entry.height);
        if (entry.themes.isNotEmpty) themes['icons/${entry.name}'] = entry.themes;
    }
  }
  assets.sort((a, b) => a.path.compareTo(b.path));
  return ArtPackContent(
    pack: pack.ref,
    assets: assets,
    common: common,
    icons: icons,
    sizes: sizes,
    themes: themes,
    palette: pack.manifest.palette,
  );
}
