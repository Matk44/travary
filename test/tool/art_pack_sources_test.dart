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

  test('the world\'s 30 most-visited cities have their six pictures each, and their country\'s colours', () {
    PackManifest manifest(String id) =>
        PackManifest.parse(File(p.join('art_packs', 'sources', id, artPackManifestName)).readAsBytesSync());

    // Each pack's own country pack (a downloaded fallback beside it), or
    // null where the country has none: those four bring their own palette.
    const worldPacks = {
      'city_gb_london': 'country_gb',
      'city_jp_tokyo': 'country_jp',
      'city_jp_osaka': 'country_jp',
      'city_th_bangkok': 'country_th',
      'region_th_phuket': 'country_th',
      'city_it_rome': 'country_it',
      'city_it_venice': 'country_it',
      'city_it_milan': 'country_it',
      'city_es_barcelona': 'country_es',
      'city_es_madrid': 'country_es',
      'city_ae_dubai': 'country_ae',
      'city_tr_istanbul': 'country_tr',
      'city_tr_antalya': 'country_tr',
      'city_nl_amsterdam': 'country_nl',
      'city_kr_seoul': 'country_kr',
      'city_pt_lisbon': 'country_pt',
      'city_mx_cancun': 'country_mx',
      'country_hk': null,
      'city_cz_prague': 'country_cz',
      'city_my_kuala_lumpur': 'country_my',
      'city_tw_taipei': 'country_tw',
      'city_gb_edinburgh': 'country_gb',
      'city_au_sydney': 'country_au',
      'city_au_melbourne': 'country_au',
      'city_it_florence': 'country_it',
      'city_gr_athens': 'country_gr',
      'city_ca_vancouver': 'country_ca',
      'city_za_cape_town': 'country_za',
      'city_nz_queenstown': 'country_nz',
      'city_us_san_francisco': 'country_us',
    };
    const six = [
      'common/featured_ticket.webp',
      'common/room_card.webp',
      'common/reservation_card.webp',
      'common/countdown_postcard.webp',
      'common/trip_postcard.webp',
      'common/documents_destination_stamp.webp',
    ];
    final palettes = <String>{};
    for (final MapEntry(key: id, value: countryId) in worldPacks.entries) {
      final pack = manifest(id);
      expect(pack.files, unorderedEquals(six), reason: '$id: the six pictures, nothing else');
      expect(pack.palette, isNotNull, reason: id);
      if (countryId != null) {
        expect(pack.palette, manifest(countryId).palette, reason: '$id keeps its country\'s colours');
      } else {
        palettes.add(pack.palette!.id);
      }
    }
    expect(palettes, hasLength(1), reason: 'only Hong Kong, a country itself, has a palette of its own here');
  });

  test('every country pack has the six pictures, a Documents stamp included', () {
    PackManifest manifest(String id) =>
        PackManifest.parse(File(p.join('art_packs', 'sources', id, artPackManifestName)).readAsBytesSync());

    const six = [
      'common/featured_ticket.webp',
      'common/room_card.webp',
      'common/reservation_card.webp',
      'common/countdown_postcard.webp',
      'common/trip_postcard.webp',
      'common/documents_destination_stamp.webp',
    ];
    final countryPacks = [
      for (final dir in Directory('art_packs/sources').listSync().whereType<Directory>())
        if (p.basename(dir.path).startsWith('country_')) p.basename(dir.path),
    ]..sort();
    expect(countryPacks, hasLength(36), reason: '25 older countries, Hong Kong and the 10 drawn on 14 Oct 2026');
    final ownPalettes = <String>{};
    for (final id in countryPacks) {
      expect(manifest(id).files, containsAll(six), reason: id);
      ownPalettes.add(manifest(id).palette!.id);
    }
    expect(ownPalettes, hasLength(countryPacks.length), reason: 'one palette each');
  });

  test('United States city and region packs keep the country pack and both postcards, and bring their own shells', () {
    PackManifest manifest(String id) =>
        PackManifest.parse(File(p.join('art_packs', 'sources', id, artPackManifestName)).readAsBytesSync());

    // A trip downloads one destination pack, so each stands in for the
    // country's: its postcards and palette stay, its three shells are new.
    const shells = ['common/featured_ticket.webp', 'common/room_card.webp', 'common/reservation_card.webp'];
    final country = manifest('country_us');
    final usPlacePacks = [
      for (final dir in Directory('art_packs/sources').listSync().whereType<Directory>())
        if (p.basename(dir.path).startsWith('city_us_') || p.basename(dir.path).startsWith('region_us_'))
          p.basename(dir.path),
    ]..sort();
    expect(usPlacePacks, hasLength(15));

    for (final id in usPlacePacks) {
      final place = manifest(id);
      expect(place.files.toSet(), containsAll(country.files), reason: '$id must not be a sparse pack');
      expect(place.files, containsAll(shells), reason: id);
      expect(place.palette, country.palette, reason: '$id keeps the trip\'s interface colours');

      final entry =
          jsonDecode(File(p.join('art_packs', 'sources', id, 'catalog-entry.json')).readAsStringSync())
              as Map<String, Object?>;
      final selectors = entry['selectors']! as Map<String, Object?>;
      expect(selectors['countryCodes'], ['US'], reason: id);
      expect(selectors[id.startsWith('city_') ? 'cities' : 'regions'], isNotEmpty, reason: id);
      expect(selectors[id.startsWith('city_') ? 'regions' : 'cities'], isNull, reason: '$id is one scope only');
    }
  });
}
