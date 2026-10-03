import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_slots.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/travel_store.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';
import '../support/documents_stamps.dart';

/// Which destination stamp the Documents heading shows for a trip: its
/// own verified city's, region's or country's pack, never another
/// place's, a look pack's or bundled art.
void main() {
  final bundled = bundledArtCatalog();
  final installed = [for (final id in stampPackIds) sourcePack(id)];

  TripVisualProfile place(
    ExperienceTheme theme, {
    required String country,
    required String countryName,
    String? region,
    String? regionName,
    String? city,
    String? cityName,
    LocationVerification verification = LocationVerification.verified,
  }) => TripVisualProfile(
    primaryTheme: theme,
    confidence: 0.9,
    sourceHash: 'hash',
    location: TripLocationHint(
      countryCode: country,
      countryName: countryName,
      region: regionName,
      regionSlug: region,
      city: cityName,
      citySlug: city,
      confidence: 0.95,
      verification: verification,
    ),
  );

  /// The stamp for a trip called [title] at [profile], as (pack, place).
  Future<(String?, String)?> stampFor(
    TripVisualProfile? profile,
    List<ArtPackContent> packs, {
    String title = 'Trip',
  }) async {
    final repository = MemoryTravelRepository(userId: 'me');
    repository.replaceAll(
      [countdownTrip('trip', title, profile: profile)],
      [countdownBooking('b', 'trip', BookingKind.activity, 'Something', LocalDate(2026, 11, 25))],
    );
    final store = TravelStore(repository: repository, artCatalog: bundled.withPacks(packs), clock: () => countdownNow);
    addTearDown(store.dispose);
    await Future<void>.delayed(Duration.zero);
    final stamp = store.destinationStampFor(store.plans.single);
    if (stamp == null) return null;
    expect(stamp.art.name, documentsDestinationStampArt);
    return (stamp.art.pack?.id, stamp.place);
  }

  final orlando = place(
    ExperienceTheme.themepark,
    country: 'US',
    countryName: 'United States',
    region: 'florida',
    regionName: 'Florida',
    city: 'orlando',
    cityName: 'Orlando',
  );
  final lakes = place(
    ExperienceTheme.countryside,
    country: 'GB',
    countryName: 'United Kingdom',
    region: 'lake_district',
    regionName: 'Lake District',
  );
  final kyoto = place(
    ExperienceTheme.urbanHeritage,
    country: 'JP',
    countryName: 'Japan',
    region: 'kansai',
    regionName: 'Kansai',
    city: 'kyoto',
    cityName: 'Kyoto',
  );

  test('each destination gets its own pack\'s stamp, named on its label', () async {
    expect(await stampFor(orlando, installed), ('city_us_orlando', 'Orlando'));
    expect(await stampFor(lakes, installed), ('region_gb_lake_district', 'Lake District'));
    expect(await stampFor(kyoto, installed), ('city_jp_kyoto', 'Kyoto'));
    final paris = place(
      ExperienceTheme.urbanHeritage,
      country: 'FR',
      countryName: 'France',
      region: 'ile_de_france',
      city: 'paris',
      cityName: 'Paris',
    );
    expect(await stampFor(paris, installed), ('city_fr_paris', 'Paris'));
    final bali = place(
      ExperienceTheme.coastalResort,
      country: 'ID',
      countryName: 'Indonesia',
      region: 'bali',
      regionName: 'Bali',
    );
    expect(await stampFor(bali, installed), ('region_id_bali', 'Bali'));
  });

  test('a country pack\'s stamp is named for the country', () async {
    final britain = sourcePack('region_gb_lake_district');
    final countryGb = ArtPackContent(
      pack: const ArtPackRef(
        id: 'country_gb',
        version: 1,
        priority: 400,
        selectors: ArtPackSelectors(countryCodes: ['GB']),
      ),
      assets: const [],
      common: {documentsDestinationStampArt: britain.common[documentsDestinationStampArt]!},
    );
    final london = place(
      ExperienceTheme.urbanHeritage,
      country: 'GB',
      countryName: 'United Kingdom',
      region: 'greater_london',
      regionName: 'Greater London',
    );
    expect(await stampFor(london, [countryGb]), ('country_gb', 'United Kingdom'));
    // The place's own pack still wins over its country's.
    expect(await stampFor(lakes, [countryGb, britain]), ('region_gb_lake_district', 'Lake District'));
  });

  test('never another place\'s stamp', () async {
    // Another city in a country that only has a city pack.
    final miami = place(
      ExperienceTheme.coastalResort,
      country: 'US',
      countryName: 'United States',
      region: 'florida',
      regionName: 'Florida',
      city: 'miami',
      cityName: 'Miami',
    );
    expect(await stampFor(miami, installed), isNull);
    // Another region.
    final london = place(
      ExperienceTheme.urbanHeritage,
      country: 'GB',
      countryName: 'United Kingdom',
      region: 'greater_london',
    );
    expect(await stampFor(london, installed), isNull);
    // Another country entirely.
    final rome = place(
      ExperienceTheme.urbanHeritage,
      country: 'IT',
      countryName: 'Italy',
      city: 'rome',
      cityName: 'Rome',
    );
    expect(await stampFor(rome, installed), isNull);
  });

  test('never from a look pack, and nothing is bundled', () async {
    // A theme-park experience pack carrying a (castle) stamp suits every
    // theme-park trip, so it must never be used: it isn't the place's own.
    final themepark = ArtPackContent(
      pack: const ArtPackRef(
        id: 'theme_themepark',
        version: 1,
        priority: 500,
        selectors: ArtPackSelectors(themes: [ExperienceTheme.themepark]),
      ),
      assets: const [],
      common: {documentsDestinationStampArt: sourcePack('city_us_orlando').common[documentsDestinationStampArt]!},
    );
    final paris = place(
      ExperienceTheme.themepark,
      country: 'FR',
      countryName: 'France',
      city: 'paris',
      cityName: 'Paris',
    );
    expect(await stampFor(paris, [themepark]), isNull);
    expect(bundled.common(documentsDestinationStampArt), isNull, reason: 'no stamp is bundled');
    expect(await stampFor(orlando, const []), isNull);
  });

  test('only for a verified place', () async {
    final unverified = place(
      ExperienceTheme.themepark,
      country: 'US',
      countryName: 'United States',
      city: 'orlando',
      cityName: 'Orlando',
      verification: LocationVerification.unverified,
    );
    expect(await stampFor(unverified, installed), isNull);
    expect(await stampFor(null, installed), isNull);
  });

  test('a place without a name prints the trip\'s title', () async {
    final unnamed = verifiedProfile(ExperienceTheme.themepark, country: 'US', region: 'florida', city: 'orlando');
    expect(await stampFor(unnamed, installed, title: 'Disney 2027'), ('city_us_orlando', 'Disney 2027'));
  });
}
