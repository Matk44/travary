import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/design/art/card_shells.dart';
import 'package:travary/design/cards/featured_ticket_card.dart';
import 'package:travary/design/cards/room_key_card.dart';
import 'package:travary/design/cards/tagged_reservation_card.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';
import 'package:travary/state/travel_store.dart';

import '../support/canonical_today.dart';
import '../support/city_cards_qa.dart';
import '../support/countdown_today.dart';
import '../support/documents_stamps.dart';

/// Today on the shells of the world's 30 most-visited cities and ten whole
/// countries: for each, the
/// canonical Today screen (a featured ticket, a key card and two tagged
/// reservation cards) for a trip in that place, with its pack installed
/// beside its country's (where there is one), as it would be on a phone.
///
/// Always checks that the app picks the place's shells for all three cards,
/// that each card on screen is drawn on them, and that its live text sits
/// inside the shell's text zone. With `TRAVARY_VISUAL_QA=1` (run by
/// `tool/visual_qa.sh`) it loads the app's real fonts and writes
/// `build/visual_qa/world_cards_<place>.png` at the reference size. The
/// United States' cities are `us_city_cards_test.dart`.
void main() {
  CityCardsQa.useFonts();

  for (final place in _places) {
    testWidgets('${place.name}: Today is drawn on ${place.packId}\'s shells', (tester) async {
      final catalog = bundledArtCatalog().withPacks([
        ?place.countryPackId == null ? null : sourcePack(place.countryPackId!),
        sourcePack(place.packId),
      ]);
      final boundary = await CityCardsQa.openToday(
        tester,
        catalog: catalog,
        title: place.name,
        profile: verifiedProfile(place.theme, country: place.country, region: place.region, city: place.city),
      );
      await CityCardsQa.save(tester, boundary, 'world_cards_${place.file}.png');

      // The pack outranks the country's, and the app resolves to its shells.
      final store = tester.element(find.byType(HomeShell)).read<TravelStore>();
      final context = store.artContextForPlan(store.focus.plan!);
      expect(context.packRanks[place.packId], place.rank);
      if (place.countryPackId case final countryPackId?) {
        expect(context.packRanks[countryPackId], ArtRank.country);
      }
      final shells = ShellResolver(catalog).resolve(context);
      for (final (role, shell) in [
        ('featured ticket', shells.featured),
        ('key card', shells.room),
        ('reservation card', shells.reservation),
      ]) {
        expect(shell?.art.pack?.id, place.packId, reason: role);
      }
      expect(shells.reservation!.role, ShellRole.reservationCard, reason: 'a complete tagged card, nothing layered on');
      expect(shells.reservation!.geometry.vignette, isNull);

      // Every card on screen is drawn on them.
      final ticket = find.byType(FeaturedTicketCard);
      final key = find.byType(RoomKeyCard);
      final tagged = find.byType(TaggedReservationCard);
      expect(ticket, findsOneWidget);
      expect(key, findsOneWidget);
      expect(tagged, findsNWidgets(2));
      expect(tester.widget<FeaturedTicketCard>(ticket).shell.art.pack?.id, place.packId);
      expect(tester.widget<RoomKeyCard>(key).shell.art.pack?.id, place.packId);
      // The complete shell has its picture printed on it: the card beside
      // it takes the blank shell and its own vignette instead.
      expect(tester.widget<TaggedReservationCard>(tagged.first).shell.art.pack?.id, place.packId);
      expect(tester.widget<TaggedReservationCard>(tagged.last).shell.role, ShellRole.reservationBlank);
      expect(find.text(place.name.toUpperCase()), findsNothing, reason: 'the shells print no place name');

      // The live text is inside each shell's text zone.
      CityCardsQa.expectInZone(
        tester,
        ticket,
        find.descendant(of: ticket, matching: find.text('Magic Kingdom')),
        shells.featured!.geometry,
        shells.featured!.geometry.text,
        'ticket title',
      );
      CityCardsQa.expectInZone(
        tester,
        key,
        find.descendant(of: key, matching: find.text("Disney's Polynesian Resort")),
        shells.room!.geometry,
        shells.room!.geometry.text,
        'key card title',
      );
      CityCardsQa.expectInZone(
        tester,
        tagged.first,
        find.descendant(of: tagged.first, matching: find.text('Be Our Guest Restaurant')),
        shells.reservation!.geometry,
        shells.reservation!.geometry.text,
        'reservation title',
      );
      expect(tester.takeException(), isNull);
    });
  }
}

class _Place {
  const _Place(
    this.name,
    this.file,
    this.packId, {
    required this.country,
    this.countryPackId,
    this.region,
    this.city,
    this.theme = ExperienceTheme.urbanHeritage,
  });

  final String name;
  final String file;
  final String packId;
  final String country;

  /// Null where the country has no pack of its own (Hong Kong, Czechia,
  /// Malaysia, Taiwan).
  final String? countryPackId;
  final String? region;
  final String? city;
  final ExperienceTheme theme;

  /// Where the place's own pack ranks: a city's, a region's (Phuket) or a
  /// country's (Hong Kong).
  ArtRank get rank => city != null
      ? ArtRank.city
      : region != null
      ? ArtRank.region
      : ArtRank.country;
}

// The place slugs are the destination list's own (`lib/logic/destinations.dart`).
const _places = [
  _Place(
    'London',
    'london',
    'city_gb_london',
    country: 'GB',
    countryPackId: 'country_gb',
    region: 'england',
    city: 'london',
  ),
  _Place('Tokyo', 'tokyo', 'city_jp_tokyo', country: 'JP', countryPackId: 'country_jp', region: 'kanto', city: 'tokyo'),
  _Place(
    'Osaka',
    'osaka',
    'city_jp_osaka',
    country: 'JP',
    countryPackId: 'country_jp',
    region: 'kansai',
    city: 'osaka',
  ),
  _Place('Bangkok', 'bangkok', 'city_th_bangkok', country: 'TH', countryPackId: 'country_th', city: 'bangkok'),
  _Place(
    'Phuket',
    'phuket',
    'region_th_phuket',
    country: 'TH',
    countryPackId: 'country_th',
    region: 'phuket',
    theme: ExperienceTheme.coastalResort,
  ),
  _Place('Rome', 'rome', 'city_it_rome', country: 'IT', countryPackId: 'country_it', region: 'lazio', city: 'rome'),
  _Place(
    'Venice',
    'venice',
    'city_it_venice',
    country: 'IT',
    countryPackId: 'country_it',
    region: 'veneto',
    city: 'venice',
  ),
  _Place(
    'Milan',
    'milan',
    'city_it_milan',
    country: 'IT',
    countryPackId: 'country_it',
    region: 'lombardy',
    city: 'milan',
  ),
  _Place(
    'Barcelona',
    'barcelona',
    'city_es_barcelona',
    country: 'ES',
    countryPackId: 'country_es',
    region: 'catalonia',
    city: 'barcelona',
  ),
  _Place('Madrid', 'madrid', 'city_es_madrid', country: 'ES', countryPackId: 'country_es', city: 'madrid'),
  _Place(
    'Dubai',
    'dubai',
    'city_ae_dubai',
    country: 'AE',
    countryPackId: 'country_ae',
    city: 'dubai',
    theme: ExperienceTheme.urbanModern,
  ),
  _Place('Istanbul', 'istanbul', 'city_tr_istanbul', country: 'TR', countryPackId: 'country_tr', city: 'istanbul'),
  _Place(
    'Antalya',
    'antalya',
    'city_tr_antalya',
    country: 'TR',
    countryPackId: 'country_tr',
    city: 'antalya',
    theme: ExperienceTheme.coastalResort,
  ),
  _Place('Amsterdam', 'amsterdam', 'city_nl_amsterdam', country: 'NL', countryPackId: 'country_nl', city: 'amsterdam'),
  _Place('Seoul', 'seoul', 'city_kr_seoul', country: 'KR', countryPackId: 'country_kr', city: 'seoul'),
  _Place('Lisbon', 'lisbon', 'city_pt_lisbon', country: 'PT', countryPackId: 'country_pt', city: 'lisbon'),
  _Place(
    'Cancún',
    'cancun',
    'city_mx_cancun',
    country: 'MX',
    countryPackId: 'country_mx',
    city: 'cancun',
    theme: ExperienceTheme.coastalResort,
  ),
  _Place('Hong Kong', 'hong_kong', 'country_hk', country: 'HK', theme: ExperienceTheme.urbanModern),
  _Place('Prague', 'prague', 'city_cz_prague', country: 'CZ', countryPackId: 'country_cz', city: 'prague'),
  _Place(
    'Kuala Lumpur',
    'kuala_lumpur',
    'city_my_kuala_lumpur',
    country: 'MY',
    countryPackId: 'country_my',
    city: 'kuala_lumpur',
    theme: ExperienceTheme.urbanModern,
  ),
  _Place('Taipei', 'taipei', 'city_tw_taipei', country: 'TW', countryPackId: 'country_tw', city: 'taipei'),
  _Place(
    'Edinburgh',
    'edinburgh',
    'city_gb_edinburgh',
    country: 'GB',
    countryPackId: 'country_gb',
    region: 'scotland',
    city: 'edinburgh',
  ),
  _Place(
    'Sydney',
    'sydney',
    'city_au_sydney',
    country: 'AU',
    countryPackId: 'country_au',
    region: 'new_south_wales',
    city: 'sydney',
  ),
  _Place('Melbourne', 'melbourne', 'city_au_melbourne', country: 'AU', countryPackId: 'country_au', city: 'melbourne'),
  _Place(
    'Florence',
    'florence',
    'city_it_florence',
    country: 'IT',
    countryPackId: 'country_it',
    region: 'tuscany',
    city: 'florence',
  ),
  _Place('Athens', 'athens', 'city_gr_athens', country: 'GR', countryPackId: 'country_gr', city: 'athens'),
  _Place('Vancouver', 'vancouver', 'city_ca_vancouver', country: 'CA', countryPackId: 'country_ca', city: 'vancouver'),
  _Place('Cape Town', 'cape_town', 'city_za_cape_town', country: 'ZA', countryPackId: 'country_za', city: 'cape_town'),
  _Place(
    'Queenstown',
    'queenstown',
    'city_nz_queenstown',
    country: 'NZ',
    countryPackId: 'country_nz',
    city: 'queenstown',
  ),
  _Place(
    'San Francisco',
    'san_francisco',
    'city_us_san_francisco',
    country: 'US',
    countryPackId: 'country_us',
    region: 'california',
    city: 'san_francisco',
  ),
  // Ten countries drawn as a whole: the country's own pack is the only one.
  _Place('Austria', 'austria', 'country_at', country: 'AT', theme: ExperienceTheme.alpine),
  _Place('Croatia', 'croatia', 'country_hr', country: 'HR', theme: ExperienceTheme.coastalResort),
  _Place('Ireland', 'ireland', 'country_ie', country: 'IE', theme: ExperienceTheme.countryside),
  _Place('Vietnam', 'vietnam', 'country_vn', country: 'VN'),
  _Place('Morocco', 'morocco', 'country_ma', country: 'MA'),
  _Place('Egypt', 'egypt', 'country_eg', country: 'EG'),
  _Place('Hungary', 'hungary', 'country_hu', country: 'HU'),
  _Place('Czechia', 'czechia', 'country_cz', country: 'CZ'),
  _Place('Malaysia', 'malaysia', 'country_my', country: 'MY', theme: ExperienceTheme.coastalResort),
  _Place('Taiwan', 'taiwan', 'country_tw', country: 'TW'),
];
