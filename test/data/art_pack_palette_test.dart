import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/data/art_pack_store.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';
import 'package:travary/state/art_catalog_controller.dart';

import '../../tool/src/pack_builder.dart';
import '../support/art_pack_fixtures.dart';
import '../support/raw_zip.dart';

Map<String, Object?> _copy(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;

void main() {
  group('palette validation', () {
    test('parses the handoff example', () {
      final palette = DestinationPalette.parse(kyotoPalette);
      expect(palette.id, 'kyoto_autumn');
      expect(palette.ink, 0xFF1C2A47);
      expect(palette.paper, 0xFFF8F4EC);
      expect(palette.accents, [0xFF9B4F3F, 0xFFC58A3A, 0xFF647A5E, 0xFF6A3F5F]);
      expect(
        (palette.primary, palette.secondary, palette.highlight, palette.onPrimary),
        (0xFF6A3F5F, 0xFF647A5E, 0xFFC58A3A, 0xFFF8F4EC),
      );
      expect(DestinationPalette.parse(palette.toJson()), palette, reason: 'round-trips');
    });

    test('the bundled palette is valid and accessible', () {
      final bundled = DestinationPalette.bundled;
      expect(DestinationPalette.parse(bundled.toJson()), bundled);
      expect(contrastRatio(bundled.primary, bundled.onPrimary), greaterThanOrEqualTo(4.5));
      expect(hexOf(bundled.ink), '#1C2A47');
      expect(hexOf(bundled.paper), '#F8F4EC');
    });

    test('contrast follows WCAG 2', () {
      expect(contrastRatio(0xFF000000, 0xFFFFFFFF), closeTo(21, 0.01));
      expect(contrastRatio(0xFF777777, 0xFFFFFFFF), closeTo(4.48, 0.01));
      expect(contrastRatio(0xFF1C2A47, 0xFF1C2A47), 1);
    });

    Map<String, Object?> palette(void Function(Map<String, Object?> json) change) {
      final json = _copy(kyotoPalette);
      change(json);
      return json;
    }

    final invalid = <String, Map<String, Object?>>{
      'lowercase hex': palette((j) => (j['anchors'] as Map)['ink'] = '#1c2a47'),
      'short hex': palette((j) => (j['anchors'] as Map)['paper'] = '#FFF'),
      'no hash': palette((j) => (j['ui'] as Map)['primary'] = '6A3F5F'),
      'a colour name': palette((j) => (j['accents'] as List)[0] = 'red'),
      'an unknown top-level key': palette((j) => j['gradient'] = ['#000000']),
      'an unknown anchor': palette((j) => (j['anchors'] as Map)['sky'] = '#88AACC'),
      'an unknown ui token': palette((j) => (j['ui'] as Map)['error'] = '#CC0000'),
      'a missing anchor': palette((j) => (j['anchors'] as Map).remove('paper')),
      'a missing ui token': palette((j) => (j['ui'] as Map).remove('highlight')),
      'one accent': palette((j) => j['accents'] = ['#9B4F3F']),
      'five accents': palette((j) => j['accents'] = ['#9B4F3F', '#C58A3A', '#647A5E', '#6A3F5F', '#123456']),
      'a repeated accent': palette((j) => j['accents'] = ['#9B4F3F', '#9B4F3F']),
      'repeated anchors': palette((j) => (j['anchors'] as Map)['paper'] = '#1C2A47'),
      'repeated ui tokens': palette((j) => (j['ui'] as Map)['secondary'] = '#6A3F5F'),
      'low contrast on primary': palette((j) => (j['ui'] as Map)['onPrimary'] = '#9B7F8F'),
      'a bad id': palette((j) => j['id'] = 'Kyoto Autumn'),
      'no id': palette((j) => j.remove('id')),
      'not an object': {'palette': 'kyoto'},
    };
    for (final entry in invalid.entries) {
      test('rejects ${entry.key}', () {
        final json = entry.key == 'not an object' ? 'kyoto' : entry.value;
        expect(() => DestinationPalette.parse(json), throwsFormatException);
        expect(DestinationPalette.tryParse(json), isNull);
      });
    }

    test('colours may repeat across groups, as in the handoff example', () {
      // ui.primary is also an accent; ui.onPrimary is the paper anchor.
      expect(DestinationPalette.tryParse(kyotoPalette), isNotNull);
    });
  });

  group('pack.json', () {
    Map<String, Object?> manifest({Object? palette}) => {
      'schemaVersion': 1,
      'packId': 'city_jp_kyoto',
      'version': 3,
      'palette': ?palette,
      'assets': [
        {'file': 'icons/dining.png', 'kind': 'icon', 'name': 'dining', 'width': 16, 'height': 16},
      ],
    };

    test('carries a valid palette, and writes it back out', () {
      final parsed = PackManifest.parse(utf8.encode(jsonEncode(manifest(palette: kyotoPalette))));
      expect(parsed.palette?.id, 'kyoto_autumn');
      final again = PackManifest.parse(utf8.encode(jsonEncode(parsed.toJson())));
      expect(again.palette, parsed.palette);
    });

    test('legacy packs without a palette stay valid', () {
      final parsed = PackManifest.parse(utf8.encode(jsonEncode(manifest())));
      expect(parsed.palette, isNull);
      expect(parsed.toJson().containsKey('palette'), isFalse);
    });

    test('an invalid palette rejects the whole pack', () {
      final bad = _copy(kyotoPalette)..['accents'] = ['#9B4F3F'];
      expect(
        () => PackManifest.parse(utf8.encode(jsonEncode(manifest(palette: bad)))),
        throwsA(isA<ArtPackFormatException>().having((e) => e.message, 'message', contains('city_jp_kyoto'))),
      );
      expect(
        () => PackManifest.parse(utf8.encode(jsonEncode(manifest(palette: null)..['palette'] = null))),
        throwsA(isA<ArtPackFormatException>()),
        reason: 'a present but empty palette is not "missing"',
      );
    });
  });

  group('archives and installed packs', () {
    late Directory temp;
    late Directory root;
    late ArtPackStore store;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('travary_palette');
      root = Directory(p.join(temp.path, 'art-packs'))..createSync();
      store = ArtPackStore.at(root);
      await store.loadInstalled();
    });
    tearDown(() => temp.delete(recursive: true));

    Future<InstalledArtPack> install(CatalogPack pack, List<int> bytes) async {
      final part = store.archivePartFile(pack);
      await part.parent.create(recursive: true);
      await part.writeAsBytes(bytes);
      return store.install(pack, archive: part);
    }

    test('the publisher puts the palette in the zip, and the installed pack keeps it after a restart', () async {
      final built = await buildTestPack(
        temp,
        id: 'city_jp_kyoto',
        palette: kyotoPalette,
        selectors: const {
          'countryCodes': ['JP'],
          'cities': ['kyoto'],
        },
      );
      final zipped = ZipDecoder().decodeBytes(built.archive).findFile('pack.json')!;
      expect((jsonDecode(utf8.decode(zipped.content)) as Map)['palette'], kyotoPalette);

      await install(built.entry, built.archive);
      final restarted = ArtPackStore.at(root);
      final loaded = (await restarted.loadInstalled()).single;
      expect(loaded.manifest.palette?.id, 'kyoto_autumn');
      expect(artPackContentOf(loaded).palette, loaded.manifest.palette);
    });

    test('the publisher refuses an invalid palette', () async {
      final bad = _copy(kyotoPalette);
      (bad['ui'] as Map)['onPrimary'] = '#7A5F6F';
      await expectLater(
        buildTestPack(temp, id: 'theme_bad', palette: bad),
        throwsA(isA<PublishException>().having((e) => e.message, 'message', contains('WCAG'))),
      );
    });

    test('an archive with an invalid palette never becomes active', () async {
      final bad = _copy(kyotoPalette)..['id'] = 'BAD';
      final png = solidPng(4, 4);
      final manifest = utf8.encode(
        jsonEncode({
          'schemaVersion': 1,
          'packId': 'theme_bad',
          'version': 1,
          'palette': bad,
          'assets': [
            {
              'file': 'dining/x.png',
              'kind': 'dining',
              'theme': 'any',
              'subject': 'generic',
              'group': 'x',
              'format': 'both',
              'width': 4,
              'height': 4,
            },
          ],
        }),
      );
      final zip = rawZip([RawEntry('pack.json', manifest), RawEntry('dining/x.png', png)]);
      final entry = CatalogPack(
        ref: const ArtPackRef(
          id: 'theme_bad',
          version: 1,
          priority: 1,
          selectors: ArtPackSelectors(themes: [ExperienceTheme.themepark]),
        ),
        archive: ArtPackArchive(
          storagePath: artPackStoragePath('theme_bad', 1),
          sha256: sha256.convert(zip).toString(),
          compressedBytes: zip.length,
          uncompressedBytes: manifest.length + png.length,
          fileCount: 2,
        ),
        minAppBuild: 1,
      );
      await expectLater(install(entry, zip), throwsA(isA<ArtPackFormatException>()));
      expect(store.installed, isEmpty);
    });
  });

  group('choosing a trip\'s palette', () {
    ArtPackRef pack(String id, ArtPackSelectors selectors, {int priority = 100}) =>
        ArtPackRef(id: id, version: 1, priority: priority, selectors: selectors);
    DestinationPalette named(String id, int primary) => DestinationPalette(
      id: id,
      ink: 0xFF1C2A47,
      paper: 0xFFF8F4EC,
      accents: const [0xFF111111, 0xFF222222],
      primary: primary,
      secondary: 0xFF333333,
      highlight: 0xFF444444,
      onPrimary: 0xFFFFFFFF,
    );

    final city = pack('city_jp_kyoto', const ArtPackSelectors(countryCodes: ['JP'], cities: ['kyoto']));
    final region = pack('region_jp_kansai', const ArtPackSelectors(countryCodes: ['JP'], regions: ['kansai']));
    final country = pack('country_jp', const ArtPackSelectors(countryCodes: ['JP']));
    final primary = pack('theme_heritage', const ArtPackSelectors(themes: [ExperienceTheme.urbanHeritage]));
    final secondary = pack('theme_modern', const ArtPackSelectors(themes: [ExperienceTheme.urbanModern]));
    final elsewhere = pack('country_fr', const ArtPackSelectors(countryCodes: ['FR']));
    final palettes = {
      city: named('kyoto', 0xFF010101),
      region: named('kansai', 0xFF020202),
      country: named('japan', 0xFF030303),
      primary: named('heritage', 0xFF040404),
      secondary: named('modern', 0xFF050505),
      elsewhere: named('france', 0xFF060606),
    };

    ArtCatalog catalogWith(Set<ArtPackRef> withPalette) => const ArtCatalog.empty().withPacks([
      for (final entry in palettes.entries)
        ArtPackContent(
          pack: entry.key,
          assets: const [],
          palette: withPalette.contains(entry.key) ? entry.value : null,
        ),
    ]);

    TripArtContext kyoto({List<ArtRank> order = TripArtContext.standardRankOrder}) => TripArtContext(
      theme: ExperienceTheme.urbanHeritage,
      secondaryThemes: const [ExperienceTheme.urbanModern],
      packRanks: const {
        'city_jp_kyoto': ArtRank.city,
        'region_jp_kansai': ArtRank.region,
        'country_jp': ArtRank.country,
        'theme_heritage': ArtRank.primary,
        'theme_modern': ArtRank.secondary,
      },
      rankOrder: order,
    );

    test('city, region, country, look, secondary look, then Travary\'s own', () {
      final all = palettes.keys.toSet();
      expect(catalogWith(all).palette(context: kyoto()).id, 'kyoto');
      expect(catalogWith(all..remove(city)).palette(context: kyoto()).id, 'kansai');
      expect(catalogWith(all..remove(region)).palette(context: kyoto()).id, 'japan');
      expect(catalogWith(all..remove(country)).palette(context: kyoto()).id, 'heritage');
      expect(catalogWith(all..remove(primary)).palette(context: kyoto()).id, 'modern');
      expect(
        catalogWith(all..remove(secondary)).palette(context: kyoto()),
        DestinationPalette.bundled,
        reason: "another destination's palette is never used",
      );
    });

    test('legacy packs without a palette fall through to the next rank', () {
      // The city and region packs are installed but have no palette.
      expect(catalogWith({country, primary}).palette(context: kyoto()).id, 'japan');
    });

    test('an unverified destination ranks after the look, as its art does', () {
      final context = kyoto(order: TripArtContext.experienceFirstRankOrder);
      expect(catalogWith({country, primary}).palette(context: context).id, 'heritage');
    });

    test('without a trip, and with no packs, the bundled palette', () {
      expect(catalogWith(palettes.keys.toSet()).palette(), DestinationPalette.bundled);
      expect(const ArtCatalog.empty().palette(context: kyoto()), DestinationPalette.bundled);
    });

    test('the higher catalog priority wins between packs of the same rank', () {
      final a = pack('theme_a', const ArtPackSelectors(themes: [ExperienceTheme.urbanHeritage]), priority: 100);
      final b = pack('theme_b', const ArtPackSelectors(themes: [ExperienceTheme.urbanHeritage]), priority: 300);
      final catalog = const ArtCatalog.empty().withPacks([
        ArtPackContent(pack: a, assets: const [], palette: named('a', 0xFF0A0A0A)),
        ArtPackContent(pack: b, assets: const [], palette: named('b', 0xFF0B0B0B)),
      ]);
      final context = TripArtContext(
        theme: ExperienceTheme.urbanHeritage,
        packRanks: const {'theme_a': ArtRank.primary, 'theme_b': ArtRank.primary},
      );
      expect(catalog.palette(context: context).id, 'b');
    });
  });
}
