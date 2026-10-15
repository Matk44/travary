import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';
import 'package:travary/logic/destinations.dart';

/// Which pack a trip to one of the world's 30 most-visited cities, or to one
/// of ten countries drawn as a whole, gets, using
/// the real pack sources' selectors and the destination list's own places
/// (the slugs a traveller's "Where to?" gives): the city's (or Phuket's
/// region's, or Hong Kong's country's) pack first, with its country's pack
/// beside it to fall back on.
void main() {
  final sources = [
    for (final dir in Directory('art_packs/sources').listSync().whereType<Directory>())
      if (File(p.join(dir.path, 'catalog-entry.json')).existsSync()) _ref(dir),
  ];

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

  Place place(String country, String name) =>
      places.singleWhere((place) => place.countryCode == country && place.name == name);

  List<String> packsFor(Place place) => [for (final pack in packsToDownload(chosen(place), sources)) pack.id];

  /// [country] is the traveller's country; [name] the place's own name.
  const expected = <(String, String), List<String>>{
    // Wave A.
    ('GB', 'London'): ['city_gb_london', 'country_gb'],
    ('JP', 'Tokyo'): ['city_jp_tokyo', 'country_jp'],
    ('TH', 'Bangkok'): ['city_th_bangkok', 'country_th'],
    ('IT', 'Rome'): ['city_it_rome', 'country_it'],
    ('ES', 'Barcelona'): ['city_es_barcelona', 'country_es'],
    ('AE', 'Dubai'): ['city_ae_dubai', 'country_ae'],
    ('TR', 'Istanbul'): ['city_tr_istanbul', 'country_tr'],
    ('NL', 'Amsterdam'): ['city_nl_amsterdam', 'country_nl'],
    ('HK', 'Hong Kong'): ['country_hk'],
    ('KR', 'Seoul'): ['city_kr_seoul', 'country_kr'],
    // Wave B.
    ('JP', 'Osaka'): ['city_jp_osaka', 'country_jp'],
    ('IT', 'Venice'): ['city_it_venice', 'country_it'],
    ('PT', 'Lisbon'): ['city_pt_lisbon', 'country_pt'],
    ('ES', 'Madrid'): ['city_es_madrid', 'country_es'],
    ('CZ', 'Prague'): ['city_cz_prague', 'country_cz'],
    ('MX', 'Cancún'): ['city_mx_cancun', 'country_mx'],
    ('MY', 'Kuala Lumpur'): ['city_my_kuala_lumpur', 'country_my'],
    ('TR', 'Antalya'): ['city_tr_antalya', 'country_tr'],
    ('TH', 'Phuket'): ['region_th_phuket', 'country_th'],
    ('IT', 'Milan'): ['city_it_milan', 'country_it'],
    ('TW', 'Taipei'): ['city_tw_taipei', 'country_tw'],
    // Wave D.
    ('GB', 'Edinburgh'): ['city_gb_edinburgh', 'country_gb'],
    ('AU', 'Sydney'): ['city_au_sydney', 'country_au'],
    ('AU', 'Melbourne'): ['city_au_melbourne', 'country_au'],
    ('IT', 'Florence'): ['city_it_florence', 'country_it'],
    ('GR', 'Athens'): ['city_gr_athens', 'country_gr'],
    ('CA', 'Vancouver'): ['city_ca_vancouver', 'country_ca'],
    ('ZA', 'Cape Town'): ['city_za_cape_town', 'country_za'],
    ('NZ', 'Queenstown'): ['city_nz_queenstown', 'country_nz'],
    ('US', 'San Francisco'): ['city_us_san_francisco', 'country_us'],
  };

  test('every one of the 30 cities gets its own pack, with its country\'s beside it', () {
    for (final MapEntry(key: (country, name), value: packs) in expected.entries) {
      expect(packsFor(place(country, name)), packs, reason: name);
    }
  });

  test('each pack names exactly one place, in the scope the destination list gives it', () {
    for (final MapEntry(key: (country, name), value: packs) in expected.entries) {
      final destination = place(country, name).destination;
      final selectors = sources.singleWhere((pack) => pack.id == packs.first).selectors;
      expect(selectors.countryCodes, [country], reason: name);
      if (destination.citySlug != null) {
        expect(selectors.cities, [destination.citySlug], reason: name);
        expect(selectors.regions, isEmpty, reason: '$name is one scope only');
      } else if (destination.regionSlug != null) {
        expect(selectors.regions, [destination.regionSlug], reason: name);
        expect(selectors.cities, isEmpty, reason: '$name is one scope only');
      } else {
        expect(selectors.cities, isEmpty, reason: '$name is a country');
        expect(selectors.regions, isEmpty, reason: '$name is a country');
      }
    }
  });

  test('a neighbour keeps its own pack, and a sibling falls back on the country\'s', () {
    expect(packsFor(place('JP', 'Kyoto')), ['city_jp_kyoto', 'country_jp']);
    expect(packsFor(place('JP', 'Nara')), ['country_jp']);
    expect(packsFor(countryPlace('JP')), ['country_jp']);
    expect(packsFor(place('IT', 'Naples')), ['country_it']);
    expect(packsFor(place('GB', 'Glasgow')), ['country_gb']);
    expect(packsFor(place('AU', 'Perth')), ['country_au']);
    expect(packsFor(place('TH', 'Chiang Mai')), ['country_th']);
    expect(packsFor(place('TH', 'Krabi')), ['country_th']);
    expect(packsFor(place('ES', 'Seville')), ['country_es']);
    expect(packsFor(place('KR', 'Busan')), ['country_kr']);
  });

  test('Hong Kong is a country of its own, and nothing else is downloaded for it', () {
    expect(packsFor(countryPlace('HK')), ['country_hk']);
  });

  test('the ten countries drawn as a whole cover every place in them without a pack of its own', () {
    const countries = {
      'AT': 'country_at',
      'HR': 'country_hr',
      'IE': 'country_ie',
      'VN': 'country_vn',
      'MA': 'country_ma',
      'EG': 'country_eg',
      'HU': 'country_hu',
      'CZ': 'country_cz',
      'MY': 'country_my',
      'TW': 'country_tw',
    };
    for (final MapEntry(key: code, value: id) in countries.entries) {
      expect(packsFor(countryPlace(code)), [id], reason: code);
    }
    for (final (code, name, id) in [
      ('AT', 'Vienna', 'country_at'),
      ('AT', 'Salzburg', 'country_at'),
      ('HR', 'Dubrovnik', 'country_hr'),
      ('HR', 'Split', 'country_hr'),
      ('IE', 'Dublin', 'country_ie'),
      ('VN', 'Hanoi', 'country_vn'),
      ('VN', 'Hoi An', 'country_vn'),
      ('MA', 'Marrakech', 'country_ma'),
      ('EG', 'Cairo', 'country_eg'),
      ('EG', 'Luxor', 'country_eg'),
      ('HU', 'Budapest', 'country_hu'),
      ('MY', 'Penang', 'country_my'),
    ]) {
      expect(packsFor(place(code, name)), [id], reason: name);
    }
  });

  test('a same-named place elsewhere never takes a city\'s pack', () {
    Trip other(String country, String city) => Trip(
      id: 'other',
      title: city,
      theme: ExperienceTheme.classicTravel,
      visualProfile: TripVisualProfile(
        primaryTheme: ExperienceTheme.classicTravel,
        location: TripLocationHint(
          countryCode: country,
          citySlug: city,
          confidence: 0.95,
          verification: LocationVerification.verified,
        ),
        confidence: 0.9,
        sourceHash: 'a' * 64,
      ),
      ownerId: 'me',
      memberIds: const ['me'],
      createdAt: DateTime(2027),
      updatedAt: DateTime(2027),
    );

    List<String> forTrip(Trip trip) => [for (final pack in packsToDownload(trip, sources)) pack.id];
    expect(forTrip(other('US', 'london')), ['country_us']);
    expect(forTrip(other('CA', 'london')), ['country_ca']);
    expect(forTrip(other('US', 'madrid')), ['country_us']);
    expect(forTrip(other('GB', 'milan')), ['country_gb']);
  });
}

ArtPackRef _ref(Directory dir) {
  final id = p.basename(dir.path);
  final entry = jsonDecode(File(p.join(dir.path, 'catalog-entry.json')).readAsStringSync()) as Map<String, Object?>;
  return ArtPackRef(
    id: id,
    version: 1,
    priority: entry['priority']! as int,
    selectors: parseArtPackSelectors(entry['selectors'], packId: id),
  );
}
