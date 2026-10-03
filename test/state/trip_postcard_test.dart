import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/image_header.dart' as header;
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/travel_store.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';
import '../support/trip_postcards.dart';

/// Which landscape postcard a coming trip gets on the Trips tab: its
/// verified city, then region, then country, then its look; never another
/// place's, and never the portrait countdown postcard in its place.
void main() {
  final bundled = bundledArtCatalog();

  /// The pack ID of the Trips postcard for a trip with [profile], or null.
  Future<String?> postcardFor(TripVisualProfile? profile, List<ArtPackContent> packs) async {
    final repository = MemoryTravelRepository(userId: 'me');
    repository.replaceAll(
      [countdownTrip('trip', 'Trip', profile: profile)],
      [countdownBooking('b', 'trip', BookingKind.activity, 'Something', LocalDate(2026, 11, 25))],
    );
    final store = TravelStore(repository: repository, artCatalog: bundled.withPacks(packs), clock: () => countdownNow);
    addTearDown(store.dispose);
    await Future<void>.delayed(Duration.zero);
    final art = store.tripPostcardFor(store.plans.single);
    if (art == null) return null;
    expect(art.name, 'trip_postcard');
    return art.pack?.id;
  }

  final kyoto = verifiedProfile(ExperienceTheme.urbanHeritage, country: 'JP', region: 'kansai', city: 'kyoto');
  final tokyo = verifiedProfile(ExperienceTheme.urbanModern, country: 'JP', region: 'kanto', city: 'tokyo');
  final lakes = verifiedProfile(ExperienceTheme.countryside, country: 'GB', region: 'lake_district');

  ArtPackContent withPostcard(String id, {required String country, String? region, String? city}) =>
      tripPostcardPack(id, country: country, region: region, city: city, postcard: '/packs/$id/trip_postcard.png');

  final kyotoCity = withPostcard('city_jp_kyoto', country: 'JP', region: 'kansai', city: 'kyoto');
  final kansai = withPostcard('region_jp_kansai', country: 'JP', region: 'kansai');
  final japan = withPostcard('country_jp', country: 'JP');
  final paris = withPostcard('city_fr_paris', country: 'FR', city: 'paris');
  final lakeDistrict = withPostcard('region_gb_lake_district', country: 'GB', region: 'lake_district');

  test('the city first, then the region, then the country', () async {
    expect(await postcardFor(kyoto, [paris, japan, kansai, kyotoCity]), 'city_jp_kyoto');
    expect(await postcardFor(kyoto, [paris, japan, kansai]), 'region_jp_kansai');
    expect(await postcardFor(kyoto, [paris, japan]), 'country_jp');
    expect(await postcardFor(lakes, [paris, kyotoCity, lakeDistrict]), 'region_gb_lake_district');
  });

  test('never another city, region or country', () async {
    expect(await postcardFor(tokyo, [kyotoCity, kansai, paris, lakeDistrict]), isNull);
    expect(await postcardFor(tokyo, [kyotoCity, kansai, japan]), 'country_jp');
    expect(await postcardFor(lakes, [kyotoCity, kansai, japan, paris]), isNull);
    final london = verifiedProfile(ExperienceTheme.urbanHeritage, country: 'GB', region: 'greater_london');
    expect(await postcardFor(london, [lakeDistrict]), isNull);
  });

  test('a portrait countdown postcard never stands in for the landscape one', () async {
    final countdownOnly = postcardPack(
      'region_gb_lake_district',
      country: 'GB',
      region: 'lake_district',
      postcard: countdownPostcardSource('region_gb_lake_district'),
    );
    expect(await postcardFor(lakes, [countdownOnly]), isNull);
    // A pack with only the countdown postcard steps aside for the next
    // pack that has a Trips postcard.
    final gb = withPostcard('country_gb', country: 'GB');
    expect(await postcardFor(lakes, [countdownOnly, gb]), 'country_gb');
  });

  test('an unverified, disputed or missing location gets no postcard', () async {
    final unverified = verifiedProfile(
      ExperienceTheme.urbanHeritage,
      country: 'JP',
      region: 'kansai',
      city: 'kyoto',
      verification: LocationVerification.unverified,
      confidence: 0.9,
    );
    expect(await postcardFor(unverified, [kyotoCity, kansai]), isNull);
    expect(await postcardFor(unverified, [kyotoCity, japan]), isNull);
    final disputed = verifiedProfile(
      ExperienceTheme.urbanHeritage,
      country: 'JP',
      city: 'kyoto',
      verification: LocationVerification.conflict,
    );
    expect(await postcardFor(disputed, [kyotoCity, japan]), isNull);
    final skipped = verifiedProfile(
      ExperienceTheme.urbanHeritage,
      country: 'JP',
      city: 'kyoto',
      verification: LocationVerification.skipped,
    );
    expect(await postcardFor(skipped, [kyotoCity, japan]), isNull);
    expect(await postcardFor(null, [kyotoCity, japan, paris]), isNull, reason: 'no profile, no place');
  });

  test("a verified trip can use its look when its place has none; its place still wins", () async {
    final countrysideLook = ArtPackContent(
      pack: const ArtPackRef(
        id: 'theme_countryside',
        version: 1,
        priority: 100,
        selectors: ArtPackSelectors(themes: [ExperienceTheme.countryside]),
      ),
      assets: const [],
      common: const {'trip_postcard': FileArtImage('/packs/theme_countryside/trip_postcard.png')},
    );
    expect(await postcardFor(lakes, [countrysideLook]), 'theme_countryside');
    expect(await postcardFor(lakes, [countrysideLook, lakeDistrict]), 'region_gb_lake_district');
    expect(await postcardFor(kyoto, [countrysideLook]), isNull);
  });

  test('nothing bundled; the packed postcards have their contracted size', () async {
    expect(bundled.commonArt('trip_postcard'), isNull);
    expect(await postcardFor(lakes, const []), isNull);
    for (final pack in tripPostcardSourcePacks()) {
      final path = pack.common['trip_postcard']!.path;
      final info = header.readImageInfo(File(path).readAsBytesSync())!;
      expect((info.width, info.height), (1536, 1024), reason: path);
    }
  });
}
