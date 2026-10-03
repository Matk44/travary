import 'dart:convert';
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

  test('postcard destination packs retain their full country pack, both postcard formats and a stamp', () {
    const placePacks = {
      'region_gb_lake_district': 'country_gb',
      'city_us_orlando': 'country_us',
      'city_jp_kyoto': 'country_jp',
      'city_fr_paris': 'country_fr',
      'region_id_bali': 'country_id',
    };

    PackManifest manifest(String id) =>
        PackManifest.parse(File(p.join('art_packs', 'sources', id, artPackManifestName)).readAsBytesSync());

    for (final MapEntry(key: placeId, value: countryId) in placePacks.entries) {
      final place = manifest(placeId);
      final country = manifest(countryId);
      expect(place.files.toSet(), containsAll(country.files), reason: '$placeId must not be a sparse postcard pack');
      expect(
        place.files,
        containsAll(const [
          'common/countdown_postcard.webp',
          'common/trip_postcard.webp',
          'common/documents_destination_stamp.webp',
        ]),
        reason: placeId,
      );

      final entry =
          jsonDecode(File(p.join('art_packs', 'sources', placeId, 'catalog-entry.json')).readAsStringSync())
              as Map<String, Object?>;
      final selectors = entry['selectors']! as Map<String, Object?>;
      expect(selectors['countryCodes'], isNotEmpty, reason: placeId);
      if (placeId.startsWith('city_')) {
        expect(selectors['cities'], isNotEmpty, reason: placeId);
      } else {
        expect(selectors['regions'], isNotEmpty, reason: placeId);
      }
    }
  });
}
