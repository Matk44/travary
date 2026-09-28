import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/domain/domain.dart';

/// Every pack source in the repository must be one the app accepts, palette
/// included, so a publish never fails on metadata.
void main() {
  final sources =
      Directory('art_packs/sources')
          .listSync()
          .whereType<Directory>()
          .where((dir) => File(p.join(dir.path, artPackManifestName)).existsSync())
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('there are pack sources to check', () => expect(sources, isNotEmpty));

  for (final source in sources) {
    final id = p.basename(source.path);
    test('$id: pack.json validates, palette included', () {
      final manifest = PackManifest.parse(File(p.join(source.path, artPackManifestName)).readAsBytesSync());
      expect(manifest.packId, id);
      final palette = manifest.palette;
      if (palette != null) {
        expect(
          contrastRatio(palette.primary, palette.onPrimary),
          greaterThanOrEqualTo(DestinationPalette.minimumContrast),
        );
        // What's written into the zip reads back the same.
        expect(DestinationPalette.parse(palette.toJson()), palette);
      }
    });
  }
}
