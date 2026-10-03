import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';
import 'travel_documents.dart';
import 'package:travary/app/route_observer.dart';
import 'session.dart';

/// The real bundled art catalog, read from `assets/art/` (the same files the
/// app bundles), so tests exercise the actual shells and icons.
ArtCatalog bundledArtCatalog() => ArtCatalog.fromAssetPaths(bundledArtPaths());

/// Every file under `assets/art/`, as asset paths.
List<String> bundledArtPaths() => [
  for (final entity in Directory('assets/art').listSync(recursive: true))
    if (entity is File) entity.path.replaceAll(r'\', '/'),
];

/// The reference screen's moment: 8:00am on day 3 of a 7-day Orlando trip.
final canonicalNow = DateTime(2026, 10, 14, 8, 0);

/// The reference screen's forecast.
const canonicalWeather = WeatherReport(temperature: 28, condition: WeatherCondition.sunny);

/// The content of docs/reference/travary_today_reference.png, as ordinary
/// trips and bookings (the shipping demo data stays generic):
///
///   Good morning · Day 3 of 7 · Orlando · 28° Sunny
///   Magic Kingdom, 9:00am, 2 tickets (next up)
///   Disney's Polynesian Resort, Room 2214 (staying)
///   Be Our Guest Restaurant, 12:30pm, table for 4
///   Ohana, 7:15pm
({List<Trip> trips, List<Booking> bookings}) canonicalTodayData({String userId = 'me', TripVisualProfile? profile}) {
  final created = DateTime(2026, 1, 1);
  const tripId = 'orlando';
  final day1 = LocalDate.fromDateTime(canonicalNow).addDays(-2);
  LocalDate day(int n) => day1.addDays(n - 1);

  Booking booking(
    String id,
    BookingKind kind,
    String title,
    LocalDate date, {
    ClockTime? at,
    LocalDate? endDate,
    ClockTime? until,
    String? reference,
    String? artSubject,
    Map<String, String> details = const {},
  }) => Booking(
    id: id,
    tripId: tripId,
    kind: kind,
    title: title,
    startDate: date,
    startTime: at,
    endDate: endDate,
    endTime: until,
    reference: reference,
    artSubject: artSubject,
    details: details,
    createdAt: created,
    updatedAt: created,
  );

  return (
    trips: [
      Trip(
        id: tripId,
        title: 'Orlando',
        theme: ExperienceTheme.themepark,
        themeSource: profile == null ? ThemeSource.manual : ThemeSource.auto,
        visualProfile: profile,
        ownerId: userId,
        memberIds: [userId],
        createdAt: created,
        updatedAt: created,
      ),
    ],
    bookings: [
      booking(
        'hotel',
        BookingKind.stay,
        "Disney's Polynesian Resort",
        day(1),
        at: const ClockTime(15, 0),
        endDate: day(7),
        until: const ClockTime(11, 0),
        reference: 'POLY-2214',
        details: {DetailKeys.room: '2214'},
      ),
      booking(
        'park',
        BookingKind.attraction,
        'Magic Kingdom',
        day(3),
        at: const ClockTime(9, 0),
        reference: 'MK-448120',
        details: {DetailKeys.guests: '2'},
      ),
      // The subjects Smart Import would pick: a castle dining hall, a
      // Polynesian grill (their art is listed in docs/ART_ASSET_GAPS.md).
      booking(
        'lunch',
        BookingKind.dining,
        'Be Our Guest Restaurant',
        day(3),
        at: const ClockTime(12, 30),
        artSubject: 'castle',
        details: {DetailKeys.partySize: '4'},
      ),
      booking('dinner', BookingKind.dining, 'Ohana', day(3), at: const ClockTime(19, 15), artSubject: 'grill'),
    ],
  );
}

/// The app's home screen with the canonical content, bundled art and the
/// reference forecast.
Widget canonicalTodayApp({ArtCatalog? catalog, DateTime? now, TripVisualProfile? profile}) {
  final clock = now ?? canonicalNow;
  final repository = MemoryTravelRepository(userId: 'me');
  final data = canonicalTodayData(userId: repository.userId, profile: profile);
  repository.replaceAll(data.trips, data.bookings);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) =>
            TravelStore(repository: repository, artCatalog: catalog ?? bundledArtCatalog(), clock: () => clock),
      ),
      ChangeNotifierProvider(
        create: (_) => PremiumStore(
          purchases: TestPurchaseService(clock: () => clock),
          clock: () => clock,
        ),
      ),
      appSessionProvider(),
      travelDocumentsProvider(),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTravaryTheme(),
      navigatorObservers: [appRouteObserver],
      home: const HomeShell(weather: canonicalWeather),
    ),
  );
}
