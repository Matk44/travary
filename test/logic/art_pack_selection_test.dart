import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';
import 'package:travary/logic/destinations.dart';

import '../support/art_pack_fixtures.dart';

ArtPackRef pack(
  String id, {
  List<String> countries = const [],
  List<String> regions = const [],
  List<String> cities = const [],
  List<ExperienceTheme> themes = const [],
  List<String> subjects = const [],
  int priority = 100,
}) => ArtPackRef(
  id: id,
  version: 1,
  priority: priority,
  selectors: ArtPackSelectors(
    countryCodes: countries,
    regions: regions,
    cities: cities,
    themes: themes,
    subjects: subjects,
  ),
);

Trip kyotoTrip({
  LocationVerification verification = LocationVerification.verified,
  double locationConfidence = 0.91,
  ThemeSource source = ThemeSource.auto,
  ExperienceTheme theme = ExperienceTheme.classicTravel,
  List<ExperienceTheme> secondary = const [ExperienceTheme.urbanModern],
  bool withProfile = true,
}) => Trip(
  id: 'kyoto',
  title: 'Kyoto',
  theme: theme,
  themeSource: source,
  visualProfile: withProfile
      ? TripVisualProfile(
          primaryTheme: ExperienceTheme.urbanHeritage,
          secondaryThemes: secondary,
          location: TripLocationHint(
            countryCode: 'JP',
            region: 'Kansai',
            regionSlug: 'kansai',
            city: 'Kyoto',
            citySlug: 'kyoto',
            confidence: locationConfidence,
            verification: verification,
          ),
          confidence: 0.88,
          sourceHash: 'a' * 64,
        )
      : null,
  ownerId: 'me',
  memberIds: const ['me'],
  createdAt: DateTime(2027),
  updatedAt: DateTime(2027),
);

void main() {
  final city = pack(
    'city_jp_kyoto',
    countries: ['JP'],
    regions: ['kansai'],
    cities: ['kyoto'],
    themes: [ExperienceTheme.urbanHeritage],
  );
  final otherCity = pack('city_jp_tokyo', countries: ['JP'], cities: ['tokyo']);
  final wrongCountryKyoto = pack('city_us_kyoto', countries: ['US'], cities: ['kyoto']);
  final region = pack('region_jp_kansai', countries: ['JP'], regions: ['kansai']);
  final country = pack('country_jp', countries: ['JP']);
  final heritage = pack('theme_urban_heritage', themes: [ExperienceTheme.urbanHeritage]);
  final modern = pack('theme_urban_modern', themes: [ExperienceTheme.urbanModern]);
  final classic = pack('theme_classic', themes: [ExperienceTheme.classicTravel]);
  final alpine = pack('theme_alpine', themes: [ExperienceTheme.alpine]);
  final all = [city, otherCity, wrongCountryKyoto, region, country, heritage, modern, classic, alpine];

  group('what a destination may choose', () {
    test('verified: city, region and country', () {
      final trusted = trustedDestinationOf(kyotoTrip());
      expect((trusted.countryCode, trusted.regionSlug, trusted.citySlug), ('JP', 'kansai', 'kyoto'));
      expect(trusted.experienceFirst, isFalse);
    });

    test('unverified: a confident country only, after experience art', () {
      final trusted = trustedDestinationOf(kyotoTrip(verification: LocationVerification.unverified));
      expect((trusted.countryCode, trusted.regionSlug, trusted.citySlug), ('JP', null, null));
      expect(trusted.experienceFirst, isTrue);
      expect(
        trustedDestinationOf(kyotoTrip(verification: LocationVerification.unverified, locationConfidence: 0.7)).isEmpty,
        isTrue,
      );
    });

    test('the traveller\'s own destination: city, region and country, over the classifier\'s', () {
      final chosen = kyotoTrip(verification: LocationVerification.conflict).copyWith(
        destination: const TripDestination(
          countryCode: 'JP',
          countryName: 'Japan',
          region: 'Kansai',
          regionSlug: 'kansai',
          city: 'Osaka',
          citySlug: 'osaka',
        ),
      );
      final trusted = trustedDestinationOf(chosen);
      expect((trusted.countryCode, trusted.regionSlug, trusted.citySlug), ('JP', 'kansai', 'osaka'));
      expect(trusted.experienceFirst, isFalse);
      expect(artContextFor(chosen, all).packRanks['region_jp_kansai'], ArtRank.region);
      expect(artContextFor(chosen, all).packRanks.containsKey('city_jp_kyoto'), isFalse);
    });

    test('conflict, skipped or no profile: nothing', () {
      expect(trustedDestinationOf(kyotoTrip(verification: LocationVerification.conflict)).isEmpty, isTrue);
      expect(trustedDestinationOf(kyotoTrip(verification: LocationVerification.skipped)).isEmpty, isTrue);
      expect(trustedDestinationOf(kyotoTrip(withProfile: false)).isEmpty, isTrue);
    });
  });

  group('ranking installed packs for a trip', () {
    test('each pack matches at its own scope only', () {
      final context = artContextFor(kyotoTrip(), all);
      expect(context.theme, ExperienceTheme.urbanHeritage);
      expect(context.packRanks, {
        'city_jp_kyoto': ArtRank.city,
        'region_jp_kansai': ArtRank.region,
        'country_jp': ArtRank.country,
        'theme_urban_heritage': ArtRank.primary,
        'theme_urban_modern': ArtRank.secondary,
        'theme_classic': ArtRank.core,
      });
      expect(context.rankOrder, TripArtContext.standardRankOrder);
    });

    test('a conflicting destination uses no destination packs', () {
      final context = artContextFor(kyotoTrip(verification: LocationVerification.conflict), all);
      expect(context.packRanks.keys, unorderedEquals(['theme_urban_heritage', 'theme_urban_modern', 'theme_classic']));
    });

    test('an unverified destination prefers experience art over its country', () {
      final context = artContextFor(kyotoTrip(verification: LocationVerification.unverified), all);
      expect(context.packRanks['country_jp'], ArtRank.country);
      expect(context.packRanks.containsKey('city_jp_kyoto'), isFalse);
      expect(context.packRanks.containsKey('region_jp_kansai'), isFalse);
      expect(context.rankOrder.indexOf(ArtRank.primary), lessThan(context.rankOrder.indexOf(ArtRank.country)));
    });

    test('a manual look drops the classifier\'s secondary themes but keeps the place', () {
      final context = artContextFor(kyotoTrip(source: ThemeSource.manual, theme: ExperienceTheme.alpine), all);
      expect(context.theme, ExperienceTheme.alpine);
      expect(context.secondaryThemes, isEmpty);
      expect(context.packRanks['theme_alpine'], ArtRank.primary);
      expect(context.packRanks.containsKey('theme_urban_modern'), isFalse);
      expect(context.packRanks['city_jp_kyoto'], ArtRank.city);
    });

    test('bundled art ranks by its theme', () {
      final context = artContextFor(kyotoTrip(), const []);
      expect(context.rankOfBundledTheme(ExperienceTheme.urbanHeritage), ArtRank.primary);
      expect(context.rankOfBundledTheme(ExperienceTheme.urbanModern), ArtRank.secondary);
      expect(context.rankOfBundledTheme(null), ArtRank.core);
      expect(context.rankOfBundledTheme(ExperienceTheme.classicTravel), ArtRank.core);
      expect(context.rankOfBundledTheme(ExperienceTheme.cruise), isNull);
    });
  });

  group('a trip through several cities', () {
    // The traveller's "Japan holiday", through Osaka, Kyoto and Tokyo.
    final japan = kyotoTrip(withProfile: false).copyWith(destination: detectPlace('Japan')!.destination);
    TripLocationHint at(String place) => detectPlace(place)!.destination.location;

    test('each city takes its own pack, then the country\'s; never another city\'s', () {
      final kyoto = artContextFor(japan, all, location: at('Kyoto'));
      expect(kyoto.packRanks['city_jp_kyoto'], ArtRank.city);
      expect(kyoto.packRanks['region_jp_kansai'], ArtRank.region);
      expect(kyoto.packRanks['country_jp'], ArtRank.country);
      expect(kyoto.packRanks.containsKey('city_jp_tokyo'), isFalse);

      final osaka = artContextFor(japan, all, location: at('Osaka'));
      expect(osaka.packRanks.containsKey('city_jp_kyoto'), isFalse);
      expect(osaka.packRanks['region_jp_kansai'], ArtRank.region, reason: 'Osaka is in Kansai too');
      expect(osaka.packRanks['country_jp'], ArtRank.country);

      expect(artContextFor(japan, all).packRanks.keys, isNot(contains('city_jp_kyoto')), reason: 'the trip: Japan');
    });

    test('downloads the trip\'s pack and look, then each city\'s, then the country\'s', () {
      final stops = [at('Osaka'), at('Kyoto'), at('Tokyo')];
      expect(
        packsToDownload(japan, [city, otherCity, country, heritage], stops: stops).map((p) => p.id),
        ['country_jp', 'city_jp_kyoto', 'city_jp_tokyo'],
        reason: 'Osaka has no pack of its own: Japan\'s is its',
      );
      expect(packsToDownload(japan, [city, country], location: at('Kyoto'), stops: [at('Tokyo')]).map((p) => p.id), [
        'city_jp_kyoto',
        'country_jp',
      ]);
    });
  });

  group('what to download', () {
    test('the most specific destination pack, one experience pack, then the country\'s to fall back on', () {
      expect(packsToDownload(kyotoTrip(), all).map((p) => p.id), [
        'city_jp_kyoto',
        'theme_urban_heritage',
        'country_jp',
      ]);
      expect(packsToDownload(kyotoTrip(), [region, country, heritage]).map((p) => p.id), [
        'region_jp_kansai',
        'theme_urban_heritage',
        'country_jp',
      ]);
      expect(packsToDownload(kyotoTrip(), [city, heritage]).map((p) => p.id), [
        'city_jp_kyoto',
        'theme_urban_heritage',
      ], reason: 'no country pack to fall back on');
      expect(packsToDownload(kyotoTrip(), [country, modern]).map((p) => p.id), [
        'country_jp',
      ], reason: 'secondary packs aren\'t downloaded');
    });

    test('conflict: no destination pack; unverified: experience first, then a country', () {
      expect(packsToDownload(kyotoTrip(verification: LocationVerification.conflict), all).map((p) => p.id), [
        'theme_urban_heritage',
      ]);
      expect(packsToDownload(kyotoTrip(verification: LocationVerification.unverified), all).map((p) => p.id), [
        'theme_urban_heritage',
        'country_jp',
      ]);
      expect(packsToDownload(kyotoTrip(verification: LocationVerification.skipped), all).map((p) => p.id), [
        'theme_urban_heritage',
      ]);
    });

    test('ties go to the trip\'s look, then priority, then subjects covered, then ID', () {
      final plainKyoto = pack('city_jp_kyoto_b', countries: ['JP'], cities: ['kyoto'], priority: 900);
      expect(
        packsToDownload(kyotoTrip(), [plainKyoto, city]).first.id,
        'city_jp_kyoto',
        reason: 'drawn for urban heritage',
      );
      final low = pack('theme_a', themes: [ExperienceTheme.urbanHeritage], priority: 10);
      final high = pack('theme_b', themes: [ExperienceTheme.urbanHeritage], priority: 20);
      expect(packsToDownload(kyotoTrip(), [low, high]).single.id, 'theme_b');
      final trains = pack('theme_c', themes: [ExperienceTheme.urbanHeritage], priority: 20, subjects: ['train']);
      expect(packsToDownload(kyotoTrip(), [high, trains], subjects: {'train'}).single.id, 'theme_c');
      final twin = pack('theme_0', themes: [ExperienceTheme.urbanHeritage], priority: 20);
      expect(packsToDownload(kyotoTrip(), [high, twin]).single.id, 'theme_0');
    });

    test('bundled classic art is never downloaded, but a classic trip may take a classic pack', () {
      expect(packsToDownload(kyotoTrip(withProfile: false), [heritage]).isEmpty, isTrue);
      expect(packsToDownload(kyotoTrip(withProfile: false), [classic]).single.id, 'theme_classic');
    });
  });

  test('a valid remote catalog parses and ranks the expected packs', () {
    final catalog = ArtPackCatalog.parse(
      catalogBytes([
        for (final ref in all)
          CatalogPack(
            ref: ref,
            archive: ArtPackArchive(
              storagePath: artPackStoragePath(ref.id, ref.version),
              sha256: 'b' * 64,
              compressedBytes: 1000,
              uncompressedBytes: 2000,
              fileCount: 3,
            ),
            minAppBuild: 1,
          ),
      ]),
      appBuild: 1,
    );
    expect(catalog.packs, hasLength(all.length));
    final refs = [for (final p in catalog.packs) p.ref];
    expect(packsToDownload(kyotoTrip(), refs).map((p) => p.id), [
      'city_jp_kyoto',
      'theme_urban_heritage',
      'country_jp',
    ]);
    expect(artContextFor(kyotoTrip(), refs).packRanks['region_jp_kansai'], ArtRank.region);
  });
}
