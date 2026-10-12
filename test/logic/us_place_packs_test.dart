import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';
import 'package:travary/logic/destinations.dart';

/// Which United States pack a trip gets, using the selectors of the real pack
/// sources (the same `catalog-entry.json` files the catalog is built from):
/// a city's pack beats its region's, a region's covers the cities without
/// their own, and everything else stays on the country's.
void main() {
  final usPacks = <ArtPackRef>[
    for (final dir in Directory('art_packs/sources').listSync().whereType<Directory>())
      if (p.basename(dir.path) == 'country_us' ||
          p.basename(dir.path).startsWith('city_us_') ||
          p.basename(dir.path).startsWith('region_us_'))
        _ref(dir),
  ];
  final all = [
    ...usPacks,
    // Other countries' packs never answer for a US trip, and the reverse.
    const ArtPackRef(
      id: 'country_gb',
      version: 3,
      priority: 500,
      selectors: ArtPackSelectors(countryCodes: ['GB']),
    ),
    const ArtPackRef(
      id: 'city_fr_paris',
      version: 1,
      priority: 500,
      selectors: ArtPackSelectors(countryCodes: ['FR'], cities: ['paris']),
    ),
  ];

  Trip trip({
    String country = 'US',
    String? region,
    String? city,
    LocationVerification verification = LocationVerification.verified,
    double confidence = 0.95,
  }) => Trip(
    id: 'trip',
    title: 'Trip',
    theme: ExperienceTheme.classicTravel,
    themeSource: ThemeSource.auto,
    visualProfile: TripVisualProfile(
      primaryTheme: ExperienceTheme.classicTravel,
      location: TripLocationHint(
        countryCode: country,
        regionSlug: region,
        citySlug: city,
        confidence: confidence,
        verification: verification,
      ),
      confidence: 0.9,
      sourceHash: 'a' * 64,
    ),
    ownerId: 'me',
    memberIds: const ['me'],
    createdAt: DateTime(2027),
    updatedAt: DateTime(2027),
  );

  String? packFor(Trip trip) => packsToDownload(trip, all).map((pack) => pack.id).firstOrNull;

  test('every United States pack is one the catalog accepts, once', () {
    expect(usPacks.map((pack) => pack.id).toSet().length, usPacks.length);
    expect(usPacks.map((pack) => pack.id), containsAll(_cityPacks.values.toSet()));
    expect(usPacks.map((pack) => pack.id), containsAll(_regionPacks.values.toSet()));
    expect(usPacks.map((pack) => pack.id), contains('country_us'));
  });

  group('a verified city gets its own pack', () {
    for (final MapEntry(key: slug, value: id) in _cityPacks.entries) {
      test(slug, () => expect(packFor(trip(city: slug)), id));
    }

    test('with the region it sits in as well', () {
      expect(packFor(trip(region: 'new_york', city: 'new_york')), 'city_us_new_york');
      expect(packFor(trip(region: 'washington', city: 'seattle')), 'city_us_seattle');
      expect(packFor(trip(region: 'tennessee', city: 'nashville')), 'city_us_nashville');
      expect(packFor(trip(region: 'nevada', city: 'las_vegas')), 'city_us_las_vegas');
    });
  });

  group('a verified region covers the cities without a pack of their own', () {
    for (final MapEntry(key: slug, value: id) in _regionPacks.entries) {
      test(slug, () => expect(packFor(trip(region: slug)), id));
    }

    test('Orlando\'s pack beats Florida\'s; Florida\'s serves every other Florida city', () {
      expect(packFor(trip(region: 'florida', city: 'orlando')), 'city_us_orlando');
      expect(packFor(trip(region: 'florida', city: 'miami')), 'region_us_florida');
      expect(packFor(trip(region: 'florida', city: 'tampa')), 'region_us_florida');
      expect(packFor(trip(region: 'florida')), 'region_us_florida');
      // Offered with Orlando's pack but not its own: still Orlando's first.
      expect(packsToDownload(trip(region: 'florida', city: 'orlando'), all).first.id, 'city_us_orlando');
    });

    test('the cities of California and Hawaii, San Francisco included', () {
      for (final city in ['los_angeles', 'san_francisco', 'san_diego', 'anaheim', 'san_jose']) {
        expect(
          packFor(trip(region: 'california', city: city)),
          'region_us_california',
          reason: city,
        );
      }
      for (final city in ['honolulu', 'kailua', 'lahaina']) {
        expect(
          packFor(trip(region: 'hawaii', city: city)),
          'region_us_hawaii',
          reason: city,
        );
      }
      expect(packFor(trip(region: 'arizona', city: 'phoenix')), 'region_us_arizona');
      expect(packFor(trip(region: 'arizona', city: 'sedona')), 'region_us_arizona');
      expect(packFor(trip(region: 'alaska', city: 'anchorage')), 'region_us_alaska');
    });

    test('a city with a pack in a region with one gets the city\'s (Las Vegas is Nevada, not Arizona)', () {
      expect(packFor(trip(region: 'arizona', city: 'las_vegas')), 'city_us_las_vegas');
    });
  });

  group('everything else in the United States stays on the country\'s cards', () {
    test('places with no pack of their own', () {
      expect(packFor(trip()), 'country_us');
      expect(packFor(trip(region: 'texas')), 'country_us');
      expect(packFor(trip(region: 'texas', city: 'austin')), 'country_us');
      expect(packFor(trip(region: 'new_york', city: 'buffalo')), 'country_us');
      expect(packFor(trip(region: 'colorado', city: 'denver')), 'country_us');
      expect(packFor(trip(region: 'utah')), 'country_us');
    });

    test('an unverified or conflicting place never takes a city or region pack', () {
      expect(
        packFor(trip(region: 'florida', city: 'orlando', verification: LocationVerification.unverified)),
        'country_us',
        reason: 'a confident country only',
      );
      expect(
        packFor(trip(region: 'california', verification: LocationVerification.unverified, confidence: 0.5)),
        isNull,
      );
      expect(packFor(trip(city: 'chicago', verification: LocationVerification.conflict)), isNull);
      expect(packFor(trip(city: 'chicago', verification: LocationVerification.skipped)), isNull);
    });

    test('a same-named place in another country never gets a US pack, nor a US trip another country\'s', () {
      expect(packFor(trip(country: 'GB', city: 'boston')), 'country_gb');
      expect(packFor(trip(country: 'CA', region: 'alaska')), isNull);
      expect(packFor(trip(country: 'US', city: 'paris')), 'country_us');
      expect(packFor(trip(country: 'FR', city: 'paris')), 'city_fr_paris');
    });
  });

  group('the places "Where to?" offers', () {
    Trip chosen(Place place) => Trip(
      id: 'chosen',
      title: place.name,
      theme: ExperienceTheme.classicTravel,
      destination: place.destination,
      ownerId: 'me',
      memberIds: const ['me'],
      createdAt: DateTime(2027),
      updatedAt: DateTime(2027),
    );

    Place place(String name) => places.singleWhere((place) => place.countryCode == 'US' && place.name == name);

    test('every United States city and region that has its own pack gets it', () {
      const expected = {
        'Orlando': 'city_us_orlando',
        'New York': 'city_us_new_york',
        'Las Vegas': 'city_us_las_vegas',
        'Washington DC': 'city_us_washington_dc',
        'Chicago': 'city_us_chicago',
        'Boston': 'city_us_boston',
        'New Orleans': 'city_us_new_orleans',
        'Nashville': 'city_us_nashville',
        'Seattle': 'city_us_seattle',
        'Florida': 'region_us_florida',
        'California': 'region_us_california',
        'Hawaii': 'region_us_hawaii',
        'Arizona': 'region_us_arizona',
        'Alaska': 'region_us_alaska',
      };
      for (final MapEntry(key: name, value: id) in expected.entries) {
        expect(packFor(chosen(place(name))), id, reason: name);
      }
    });

    test('their cities and sub-regions take the region\'s pack', () {
      expect(packFor(chosen(place('Miami'))), 'region_us_florida');
      expect(packFor(chosen(place('Florida Keys'))), 'region_us_florida');
      expect(packFor(chosen(place('Los Angeles'))), 'region_us_california');
      expect(packFor(chosen(place('San Francisco'))), 'region_us_california');
      expect(packFor(chosen(place('San Diego'))), 'region_us_california');
      expect(packFor(chosen(place('Anaheim'))), 'region_us_california');
      expect(packFor(chosen(place('Maui'))), 'region_us_hawaii');
    });

    test('the rest stay on the country\'s', () {
      for (final name in ['Texas', 'Utah', 'Colorado', 'Yellowstone', 'New Mexico', 'New Jersey', 'New England']) {
        expect(packFor(chosen(place(name))), 'country_us', reason: name);
      }
      expect(packFor(chosen(countryPlace('US'))), 'country_us');
    });

    test('a trip named for a place detects the same pack', () {
      expect(packFor(chosen(detectPlace('Disney World 2027')!)), 'city_us_orlando');
      expect(packFor(chosen(detectPlace('NYC long weekend')!)), 'city_us_new_york');
      expect(packFor(chosen(detectPlace('Washington D C in spring')!)), 'city_us_washington_dc');
      expect(packFor(chosen(detectPlace('Waikiki honeymoon')!)), 'region_us_hawaii');
      expect(packFor(chosen(detectPlace('Grand Canyon road trip')!)), 'region_us_arizona');
    });
  });
}

const _cityPacks = {
  'new_york': 'city_us_new_york',
  'las_vegas': 'city_us_las_vegas',
  'washington_dc': 'city_us_washington_dc',
  'chicago': 'city_us_chicago',
  'boston': 'city_us_boston',
  'new_orleans': 'city_us_new_orleans',
  'nashville': 'city_us_nashville',
  'seattle': 'city_us_seattle',
  'orlando': 'city_us_orlando',
};

const _regionPacks = {
  'florida': 'region_us_florida',
  'florida_keys': 'region_us_florida',
  'california': 'region_us_california',
  'hawaii': 'region_us_hawaii',
  'maui': 'region_us_hawaii',
  'arizona': 'region_us_arizona',
  'alaska': 'region_us_alaska',
};

ArtPackRef _ref(Directory source) {
  final id = p.basename(source.path);
  final entry = jsonDecode(File(p.join(source.path, 'catalog-entry.json')).readAsStringSync()) as Map<String, Object?>;
  final manifest = PackManifest.parse(File(p.join(source.path, artPackManifestName)).readAsBytesSync());
  return ArtPackRef(
    id: id,
    version: manifest.version,
    priority: entry['priority']! as int,
    selectors: parseArtPackSelectors(entry['selectors'], packId: id),
  );
}
