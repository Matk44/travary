import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';

import 'countdown_today.dart';

/// A landscape Trips postcard waiting in `art_packs/pending/` for its
/// complete pack.
String pendingTripPostcard(String packId) => 'art_packs/pending/trip_postcards/$packId/common/trip_postcard.png';

/// A destination pack (city, region or country, from its selectors) that
/// may carry a Trips postcard, as `pack.json` would describe it.
ArtPackContent tripPostcardPack(
  String id, {
  required String country,
  String? region,
  String? city,
  List<ExperienceTheme> themes = const [],
  String? postcard,
  int priority = 500,
}) => ArtPackContent(
  pack: ArtPackRef(
    id: id,
    version: 1,
    priority: priority,
    selectors: ArtPackSelectors(countryCodes: [country], regions: [?region], cities: [?city], themes: themes),
  ),
  assets: const [],
  common: {if (postcard != null) 'trip_postcard': FileArtImage(postcard)},
  sizes: {if (postcard != null) 'common/trip_postcard': (width: 1536, height: 1024)},
);

/// The five pending Trips postcards as the packs they'll eventually join.
List<ArtPackContent> pendingTripPostcardPacks() => [
  tripPostcardPack(
    'region_gb_lake_district',
    country: 'GB',
    region: 'lake_district',
    postcard: pendingTripPostcard('region_gb_lake_district'),
  ),
  tripPostcardPack('city_us_orlando', country: 'US', city: 'orlando', postcard: pendingTripPostcard('city_us_orlando')),
  tripPostcardPack(
    'city_jp_kyoto',
    country: 'JP',
    region: 'kansai',
    city: 'kyoto',
    postcard: pendingTripPostcard('city_jp_kyoto'),
  ),
  tripPostcardPack('city_fr_paris', country: 'FR', city: 'paris', postcard: pendingTripPostcard('city_fr_paris')),
  tripPostcardPack('region_id_bali', country: 'ID', region: 'bali', postcard: pendingTripPostcard('region_id_bali')),
];

/// The mockup's Trips tab on 28 September 2026 (`countdownNow`): Cornwall
/// happening now; coming up the Lake District (58 days, 25–28 November,
/// three bookings), Kyoto (194 days, 10–16 April 2027) and Orlando
/// (26 September – 3 October 2027); Rome in the past.
///
/// Without [activeAndPast], just the three coming trips, as in the mockup.
({List<Trip> trips, List<Booking> bookings}) upcomingTripsData({
  String lakesTitle = 'Lake District',
  TripVisualProfile? lakesProfile,
  bool activeAndPast = true,
}) {
  LocalDate date(int year, int month, int day) => LocalDate(year, month, day);
  final all = (
    trips: [
      countdownTrip('cornwall', 'Cornwall'),
      countdownTrip(
        'lakes',
        lakesTitle,
        profile: lakesProfile ?? verifiedProfile(ExperienceTheme.countryside, country: 'GB', region: 'lake_district'),
      ),
      countdownTrip(
        'kyoto',
        'Kyoto',
        profile: verifiedProfile(ExperienceTheme.urbanHeritage, country: 'JP', region: 'kansai', city: 'kyoto'),
      ),
      countdownTrip(
        'orlando',
        'Orlando',
        profile: verifiedProfile(ExperienceTheme.themepark, country: 'US', region: 'florida', city: 'orlando'),
      ),
      countdownTrip(
        'rome',
        'Rome',
        profile: verifiedProfile(ExperienceTheme.urbanHeritage, country: 'IT', region: 'lazio', city: 'rome'),
      ),
    ],
    bookings: [
      countdownBooking('surf', 'cornwall', BookingKind.activity, 'Surf lesson', date(2026, 9, 26)),
      countdownBooking('train', 'cornwall', BookingKind.transport, 'Train home', date(2026, 9, 30)),
      countdownBooking(
        'cottage',
        'lakes',
        BookingKind.stay,
        'Lakeside Cottage',
        date(2026, 11, 25),
        endDate: date(2026, 11, 28),
      ),
      countdownBooking('steamer', 'lakes', BookingKind.activity, 'Ullswater Steamer', date(2026, 11, 26)),
      countdownBooking('dinner', 'lakes', BookingKind.dining, 'The Drunken Duck', date(2026, 11, 27)),
      countdownBooking('ryokan', 'kyoto', BookingKind.stay, 'Ryokan', date(2027, 4, 10), endDate: date(2027, 4, 16)),
      countdownBooking('temple', 'kyoto', BookingKind.attraction, 'Kinkaku-ji', date(2027, 4, 12)),
      countdownBooking('resort', 'orlando', BookingKind.stay, 'Resort', date(2027, 9, 26), endDate: date(2027, 10, 3)),
      countdownBooking('colosseum', 'rome', BookingKind.attraction, 'Colosseum', date(2026, 5, 12)),
    ],
  );
  if (activeAndPast) return all;
  const others = {'cornwall', 'rome'};
  return (
    trips: [
      for (final trip in all.trips)
        if (!others.contains(trip.id)) trip,
    ],
    bookings: [
      for (final booking in all.bookings)
        if (!others.contains(booking.tripId)) booking,
    ],
  );
}
