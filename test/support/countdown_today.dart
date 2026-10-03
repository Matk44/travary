import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/data/memory_travel_document_repository.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import 'canonical_today.dart';
import 'travel_documents.dart';
import 'package:travary/app/route_observer.dart';

/// The mockup's moment (docs/mockups/today-empty/02-hanging-luggage-tag.png):
/// 8am on Monday 28 September 2026, between trips.
final countdownNow = DateTime(2026, 9, 28, 8, 0);

/// A countdown postcard in its complete destination pack source.
String countdownPostcardSource(String packId) => 'art_packs/sources/$packId/common/countdown_postcard.webp';

/// A classifier profile whose place Google verified.
TripVisualProfile verifiedProfile(
  ExperienceTheme theme, {
  required String country,
  String? region,
  String? city,
  LocationVerification verification = LocationVerification.verified,
  double confidence = 0.95,
}) => TripVisualProfile(
  primaryTheme: theme,
  confidence: 0.9,
  sourceHash: 'hash',
  location: TripLocationHint(
    countryCode: country,
    regionSlug: region,
    citySlug: city,
    confidence: confidence,
    verification: verification,
  ),
);

/// A destination pack (city, region or country, from its selectors) that
/// may carry a countdown postcard, as `pack.json` would describe it.
ArtPackContent postcardPack(
  String id, {
  required String country,
  String? region,
  String? city,
  List<ExperienceTheme> themes = const [],
  String? postcard,
  int priority = 500,
  Map<String, List<ExperienceTheme>> drawnFor = const {},
}) => ArtPackContent(
  pack: ArtPackRef(
    id: id,
    version: 1,
    priority: priority,
    selectors: ArtPackSelectors(countryCodes: [country], regions: [?region], cities: [?city], themes: themes),
  ),
  assets: const [],
  common: {if (postcard != null) 'countdown_postcard': FileArtImage(postcard)},
  sizes: {if (postcard != null) 'common/countdown_postcard': (width: 1122, height: 1402)},
  themes: drawnFor,
);

/// The five countdown postcards from their complete destination packs.
List<ArtPackContent> countdownPostcardSourcePacks() => [
  postcardPack(
    'region_gb_lake_district',
    country: 'GB',
    region: 'lake_district',
    postcard: countdownPostcardSource('region_gb_lake_district'),
  ),
  postcardPack('city_us_orlando', country: 'US', city: 'orlando', postcard: countdownPostcardSource('city_us_orlando')),
  postcardPack(
    'city_jp_kyoto',
    country: 'JP',
    region: 'kansai',
    city: 'kyoto',
    postcard: countdownPostcardSource('city_jp_kyoto'),
  ),
  postcardPack('city_fr_paris', country: 'FR', city: 'paris', postcard: countdownPostcardSource('city_fr_paris')),
  postcardPack('region_id_bali', country: 'ID', region: 'bali', postcard: countdownPostcardSource('region_id_bali')),
];

final _created = DateTime(2026, 1, 1);

Trip countdownTrip(
  String id,
  String title, {
  TripVisualProfile? profile,
  TripDestination? destination,
  String userId = 'me',
}) => Trip(
  id: id,
  title: title,
  theme: profile?.primaryTheme ?? ExperienceTheme.classicTravel,
  visualProfile: profile,
  destination: destination,
  ownerId: userId,
  memberIds: [userId],
  createdAt: _created,
  updatedAt: _created,
);

Booking countdownBooking(
  String id,
  String tripId,
  BookingKind kind,
  String title,
  LocalDate date, {
  ClockTime? at,
  LocalDate? endDate,
}) => Booking(
  id: id,
  tripId: tripId,
  kind: kind,
  title: title,
  startDate: date,
  startTime: at,
  endDate: endDate,
  createdAt: _created,
  updatedAt: _created,
);

/// The mockup's trips: Lake District next (25–28 November 2026, three
/// bookings), Paris after it, Orlando in the past.
({List<Trip> trips, List<Booking> bookings}) countdownTodayData({
  String lakesTitle = 'Lake District',
  TripVisualProfile? lakesProfile,
}) {
  final lakes = countdownTrip(
    'lakes',
    lakesTitle,
    profile: lakesProfile ?? verifiedProfile(ExperienceTheme.countryside, country: 'GB', region: 'lake_district'),
  );
  final paris = countdownTrip(
    'paris',
    'Paris',
    profile: verifiedProfile(ExperienceTheme.urbanHeritage, country: 'FR', region: 'ile_de_france', city: 'paris'),
  );
  final orlando = countdownTrip(
    'orlando',
    'Orlando',
    profile: verifiedProfile(ExperienceTheme.themepark, country: 'US', region: 'florida', city: 'orlando'),
  );
  return (
    trips: [lakes, paris, orlando],
    bookings: [
      countdownBooking(
        'cottage',
        'lakes',
        BookingKind.stay,
        'Lakeside Cottage',
        LocalDate(2026, 11, 25),
        at: const ClockTime(16, 0),
        endDate: LocalDate(2026, 11, 28),
      ),
      countdownBooking(
        'steamer',
        'lakes',
        BookingKind.activity,
        'Ullswater Steamer',
        LocalDate(2026, 11, 26),
        at: const ClockTime(10, 0),
      ),
      countdownBooking(
        'dinner',
        'lakes',
        BookingKind.dining,
        'The Drunken Duck',
        LocalDate(2026, 11, 27),
        at: const ClockTime(19, 0),
      ),
      countdownBooking('paris-hotel', 'paris', BookingKind.stay, 'Hotel Le Marais', LocalDate(2026, 12, 10)),
      countdownBooking('orlando-park', 'orlando', BookingKind.attraction, 'Magic Kingdom', LocalDate(2026, 6, 3)),
    ],
  );
}

/// The app's home screen on [data] at [now] (the mockup's moment unless
/// given), with [catalog] (bundled art plus every postcard source pack unless
/// given).
Widget countdownTodayApp({
  ArtCatalog? catalog,
  DateTime? now,
  ({List<Trip> trips, List<Booking> bookings})? data,
  WeatherReport? weather,
  List<TravelDocument> documents = const [],
  FixedDocumentLock? documentLock,
  MemoryTravelDocumentRepository? documentRepository,
}) {
  final clock = now ?? countdownNow;
  final repository = MemoryTravelRepository(userId: 'me');
  final content = data ?? countdownTodayData();
  repository.replaceAll(content.trips, content.bookings);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => TravelStore(
          repository: repository,
          artCatalog: catalog ?? bundledArtCatalog().withPacks(countdownPostcardSourcePacks()),
          clock: () => clock,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => PremiumStore(
          purchases: TestPurchaseService(clock: () => clock),
          clock: () => clock,
        ),
      ),
      travelDocumentsProvider(documents: documents, lock: documentLock, repository: documentRepository),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTravaryTheme(),
      navigatorObservers: [appRouteObserver],
      home: HomeShell(weather: weather),
    ),
  );
}
