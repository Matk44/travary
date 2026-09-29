import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/image_header.dart' as header;
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/travel_store.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';

/// Which postcard the countdown to a trip uses: the trip's verified city,
/// then region, then country, then its look; never another place's.
void main() {
  final bundled = bundledArtCatalog();

  /// The pack ID of the postcard [store] picks for its only trip, or null.
  Future<String?> postcardFor(TripVisualProfile? profile, List<ArtPackContent> packs) async {
    final repository = MemoryTravelRepository(userId: 'me');
    repository.replaceAll(
      [countdownTrip('trip', 'Trip', profile: profile)],
      [countdownBooking('b', 'trip', BookingKind.activity, 'Something', LocalDate(2026, 11, 25))],
    );
    final store = TravelStore(repository: repository, artCatalog: bundled.withPacks(packs), clock: () => countdownNow);
    addTearDown(store.dispose);
    await Future<void>.delayed(Duration.zero);
    final art = store.countdownPostcardFor(store.plans.single);
    if (art == null) return null;
    expect(art.image, isA<FileArtImage>());
    return art.pack?.id;
  }

  final kyoto = verifiedProfile(ExperienceTheme.urbanHeritage, country: 'JP', region: 'kansai', city: 'kyoto');
  final tokyo = verifiedProfile(ExperienceTheme.urbanModern, country: 'JP', region: 'kanto', city: 'tokyo');
  final lakes = verifiedProfile(ExperienceTheme.countryside, country: 'GB', region: 'lake_district');

  ArtPackContent withPostcard(String id, {required String country, String? region, String? city}) =>
      postcardPack(id, country: country, region: region, city: city, postcard: '/packs/$id/countdown_postcard.png');

  final kyotoCity = withPostcard('city_jp_kyoto', country: 'JP', region: 'kansai', city: 'kyoto');
  final kansai = withPostcard('region_jp_kansai', country: 'JP', region: 'kansai');
  final japan = withPostcard('country_jp', country: 'JP');
  final paris = withPostcard('city_fr_paris', country: 'FR', city: 'paris');
  final lakeDistrict = withPostcard('region_gb_lake_district', country: 'GB', region: 'lake_district');

  test('the city first, then the region, then the country', () async {
    expect(await postcardFor(kyoto, [paris, japan, kansai, kyotoCity]), 'city_jp_kyoto');
    expect(await postcardFor(kyoto, [paris, japan, kansai]), 'region_jp_kansai');
    expect(await postcardFor(kyoto, [paris, japan]), 'country_jp');
  });

  test('a region postcard for its region', () async {
    expect(await postcardFor(lakes, [paris, kyotoCity, lakeDistrict]), 'region_gb_lake_district');
  });

  test('never another city, region or country', () async {
    // Tokyo: the Kyoto and Kansai postcards are in Japan, but not Tokyo.
    expect(await postcardFor(tokyo, [kyotoCity, kansai, paris, lakeDistrict]), isNull);
    // Its country's postcard does suit it.
    expect(await postcardFor(tokyo, [kyotoCity, kansai, japan]), 'country_jp');
    // A Lake District trip never borrows Japan's or Paris's.
    expect(await postcardFor(lakes, [kyotoCity, kansai, japan, paris]), isNull);
    // A city or region pack never stands in for the rest of its country.
    final elsewhereInGb = verifiedProfile(ExperienceTheme.urbanHeritage, country: 'GB', region: 'greater_london');
    expect(await postcardFor(elsewhereInGb, [lakeDistrict]), isNull);
  });

  test('a pack with no postcard is skipped for the next that has one', () async {
    final bareCity = postcardPack('city_jp_kyoto', country: 'JP', region: 'kansai', city: 'kyoto');
    expect(await postcardFor(kyoto, [bareCity, japan]), 'country_jp');
  });

  test('an unconfirmed place picks only its country, after the look; a disputed one nothing', () async {
    final unverified = verifiedProfile(
      ExperienceTheme.urbanHeritage,
      country: 'JP',
      region: 'kansai',
      city: 'kyoto',
      verification: LocationVerification.unverified,
      confidence: 0.9,
    );
    expect(await postcardFor(unverified, [kyotoCity, kansai]), isNull);
    expect(await postcardFor(unverified, [kyotoCity, kansai, japan]), 'country_jp');

    final disputed = verifiedProfile(
      ExperienceTheme.urbanHeritage,
      country: 'JP',
      city: 'kyoto',
      verification: LocationVerification.conflict,
    );
    expect(await postcardFor(disputed, [kyotoCity, japan]), isNull);
    expect(await postcardFor(null, [kyotoCity, japan, paris]), isNull, reason: 'no profile, no place');
  });

  test("the trip's look, when its place has none; its place first", () async {
    final countrysideLook = ArtPackContent(
      pack: const ArtPackRef(
        id: 'theme_countryside',
        version: 1,
        priority: 100,
        selectors: ArtPackSelectors(themes: [ExperienceTheme.countryside]),
      ),
      assets: const [],
      common: const {'countdown_postcard': FileArtImage('/packs/theme_countryside/countdown_postcard.png')},
    );
    expect(await postcardFor(lakes, [countrysideLook]), 'theme_countryside');
    expect(await postcardFor(lakes, [countrysideLook, lakeDistrict]), 'region_gb_lake_district');
    expect(await postcardFor(kyoto, [countrysideLook]), isNull, reason: 'not drawn for an urban heritage trip');
  });

  test('a postcard drawn for other looks is left out', () async {
    final alpineOnly = postcardPack(
      'region_gb_lake_district',
      country: 'GB',
      region: 'lake_district',
      postcard: '/packs/lakes/countdown_postcard.png',
      drawnFor: const {
        'common/countdown_postcard': [ExperienceTheme.alpine],
      },
    );
    expect(await postcardFor(lakes, [alpineOnly]), isNull);
  });

  test('the bundled art has no postcard of its own', () async {
    expect(bundled.commonArt('countdown_postcard'), isNull);
    expect(await postcardFor(lakes, const []), isNull);
  });

  test('the pending postcards and the bundled tag are the handed-off sizes', () {
    for (final pack in pendingPostcardPacks()) {
      final path = pack.common['countdown_postcard']!.path;
      final info = header.readImageInfo(File(path).readAsBytesSync())!;
      expect((info.width, info.height), (1122, 1402), reason: path);
    }
    final tag = header.readImageInfo(File('assets/art/common/countdown_luggage_tag.png').readAsBytesSync())!;
    expect((tag.width, tag.height), (1024, 1536));
  });
}
