import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_subjects.dart';
import 'package:travary/logic/destinations.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

/// A holiday through Osaka, Kyoto and Tokyo, by way of Dubai: how its trip
/// is named and kept together, and whose art each day's cards take.
void main() {
  late MemoryTravelRepository repository;
  late TravelStore store;

  Future<void> start({List<Trip> trips = const [], List<Booking> bookings = const [], ArtCatalog? art}) async {
    repository = MemoryTravelRepository(userId: 'me')..replaceAll(trips, bookings);
    store = TravelStore(
      repository: repository,
      artCatalog: art ?? const ArtCatalog.empty(),
      clock: () => DateTime(2026, 9, 1, 9),
    );
    addTearDown(store.dispose);
    await pumpEventQueue();
  }

  Booking flight(String id, LocalDate day, String title, ClockTime at, {ClockTime? lands, bool overnight = false}) =>
      booking(
        id,
        BookingKind.flight,
        day,
        tripId: '',
        title: title,
        at: at,
        until: lands,
        endDate: overnight ? day.addDays(1) : null,
      );
  Booking stay(String id, LocalDate from, LocalDate to, String title, {String? location}) =>
      booking(id, BookingKind.stay, from, tripId: '', title: title, endDate: to, location: location);

  final itinerary = [
    flight('f1', d(11, 1), 'London to Dubai', const ClockTime(9, 0), lands: const ClockTime(19, 0)),
    flight('f2', d(11, 1), 'Dubai to Osaka', const ClockTime(21, 0), lands: const ClockTime(11, 0), overnight: true),
    stay('osaka', d(11, 2), d(11, 5), 'Hotel Hankyu', location: 'Kita-ku, Osaka'),
    stay('kyoto', d(11, 5), d(11, 9), 'Hotel Granvia Kyoto'),
    stay('tokyo', d(11, 9), d(11, 14), 'Park Hotel', location: 'Minato, Tokyo'),
    flight('f3', d(11, 14), 'Tokyo to Dubai', const ClockTime(22, 0), lands: const ClockTime(4, 0), overnight: true),
    flight('f4', d(11, 15), 'Dubai to London', const ClockTime(8, 0), lands: const ClockTime(12, 0)),
  ];

  group('naming the trip', () {
    test('a whole itinerary from one file is named after where it goes, not the stopover', () async {
      await start();
      final results = await store.saveBookings(itinerary);
      await pumpEventQueue();
      final plan = store.plans.single;
      expect(plan.trip.title, 'Japan');
      expect(plan.trip.destination, countryPlace('JP').destination);
      expect(plan.trip.autoName, isTrue);
      expect(results.map((r) => r.tripTitle).toSet(), {'Japan'});
    });

    test('added one by one, the name follows the bookings', () async {
      await start();
      final first = await store.saveBooking(itinerary[0]);
      await pumpEventQueue();
      expect(first.tripTitle, 'Dubai');
      final second = await store.saveBooking(itinerary[1]);
      await pumpEventQueue();
      expect(second.tripTitle, 'Osaka', reason: 'Dubai was the way there');
      expect(store.plans.single.trip.destination?.city, 'Osaka');
      for (final booking in itinerary.sublist(2)) {
        await store.saveBooking(booking);
        await pumpEventQueue();
      }
      expect(store.plans.single.trip.title, 'Japan');

      // Taking the other cities out takes the name back.
      await store.deleteBooking(store.booking('tokyo')!);
      await pumpEventQueue();
      await store.deleteBooking(store.booking('osaka')!);
      await pumpEventQueue();
      expect(store.plans.single.trip.title, 'Kyoto');
    });

    test('in to one city and home from another stays one trip', () async {
      await start();
      await store.saveBooking(flight('out', d(11, 1), 'London to Osaka', const ClockTime(11, 0)));
      await pumpEventQueue();
      final home = await store.saveBooking(flight('home', d(11, 14), 'Tokyo to London', const ClockTime(11, 0)));
      await pumpEventQueue();
      expect(store.plans, hasLength(1));
      expect(home.newTrip, isFalse);
      expect(home.tripTitle, 'Japan');
    });

    test('a name the traveller gave stays theirs', () async {
      await start();
      final trip = await store.createTrip('Dubai stopover', destination: detectPlace('Dubai')!.destination);
      await pumpEventQueue();
      await store.saveBooking(itinerary[0].copyWith(tripId: trip.id));
      await store.saveBooking(itinerary[1].copyWith(tripId: trip.id));
      await pumpEventQueue();
      expect(store.plans.single.trip.title, 'Dubai stopover');
      expect(store.plans.single.trip.destination?.city, 'Dubai');
    });

    test('a file added to a trip the app named renames it once, and says so', () async {
      await start();
      await store.saveBooking(itinerary[2]);
      await pumpEventQueue();
      expect(store.plans.single.trip.title, 'Osaka');
      final results = await store.saveBookings(itinerary.sublist(3, 5));
      await pumpEventQueue();
      expect(store.plans.single.trip.title, 'Japan');
      expect(results.map((r) => r.tripTitle).toSet(), {'Japan'});
    });
  });

  group('what a Holiday Pass goes by stays put', () {
    test('renaming a trip never puts back dates someone else just changed', () async {
      await start();
      await store.saveBooking(itinerary[0]);
      await pumpEventQueue();
      final named = store.plans.single.trip;
      // A family member sets the trip's dates; this phone hasn't heard yet.
      final premium = TripPremium(grantedBy: 'me', until: DateTime(2026, 11, 22));
      repository.putTrip(
        Trip(
          id: named.id,
          title: named.title,
          destination: named.destination,
          autoName: true,
          plannedStart: d(11, 1),
          plannedEnd: d(11, 15),
          premium: premium,
          ownerId: 'me',
          memberIds: const ['me'],
          createdAt: named.createdAt,
          updatedAt: named.updatedAt,
        ),
      );
      final renamed = await store.saveBooking(itinerary[1].copyWith(tripId: named.id));
      await pumpEventQueue();
      final trip = store.plans.single.trip;
      expect(renamed.tripTitle, 'Osaka');
      expect((trip.title, trip.plannedStart, trip.plannedEnd), ('Osaka', d(11, 1), d(11, 15)));
      expect(trip.premium?.until, premium.until);
    });

    test('a file is counted against the trip it lands in', () async {
      await start();
      await store.saveBooking(flight('out', d(11, 1), 'London to Osaka', const ClockTime(11, 0)));
      await pumpEventQueue();
      final japan = store.plans.single.id;
      final file = [
        flight('home', d(11, 14), 'Tokyo to London', const ClockTime(11, 0)),
        stay('later', d(12, 20), d(12, 27), 'Chalet', location: 'Zermatt'),
      ];
      expect(store.importPlaces(file), [japan, 'new:0']);
      final results = await store.saveBookings(file);
      await pumpEventQueue();
      expect(results.first.booking.tripId, japan);
      expect(results.last.newTrip, isTrue);
    });
  });

  group('each day\'s art', () {
    ArtPackRef ref(String id, {List<String> cities = const []}) => ArtPackRef(
      id: id,
      version: 1,
      priority: 500,
      selectors: ArtPackSelectors(countryCodes: const ['JP'], cities: cities),
    );
    ArtPackContent pack(ArtPackRef ref) => ArtPackContent(
      pack: ref,
      assets: [
        for (final kind in [BookingKind.dining, BookingKind.stay])
          ArtAsset(
            image: FileArtImage('/packs/${ref.id}/${kind.name}.png'),
            kind: kind,
            theme: null,
            subject: genericSubject,
            group: '${kind.name}_01',
            pack: ref,
          ),
      ],
    );
    final japan = pack(ref('country_jp'));
    final kyoto = pack(ref('city_jp_kyoto', cities: const ['kyoto']));

    Future<void> startJapan(Trip trip) => start(
      trips: [trip],
      bookings: [
        for (final booking in itinerary) booking.copyWith(tripId: trip.id),
        booking('kyoto-dinner', BookingKind.dining, d(11, 6), tripId: trip.id, at: const ClockTime(19, 0)),
        booking('tokyo-dinner', BookingKind.dining, d(11, 10), tripId: trip.id, at: const ClockTime(19, 0)),
      ],
      art: const ArtCatalog.empty().withPacks([japan, kyoto]),
    );
    String? packOf(String bookingId) => store.artFor(store.booking(bookingId)!).asset?.pack?.id;

    test('Kyoto\'s days take Kyoto\'s pack; Osaka\'s and Tokyo\'s, with none of their own, Japan\'s', () async {
      await startJapan(trip('t', title: 'Japan holiday').copyWith(destination: countryPlace('JP').destination));
      expect(packOf('kyoto'), 'city_jp_kyoto');
      expect(packOf('kyoto-dinner'), 'city_jp_kyoto', reason: 'no place of its own: where they\'re staying');
      expect(packOf('osaka'), 'country_jp');
      expect(packOf('tokyo-dinner'), 'country_jp');
    });

    test('the trip itself is Japan, even when the classifier named Kyoto', () async {
      final kyotoReading = TripVisualProfile(
        primaryTheme: ExperienceTheme.urbanHeritage,
        location: detectPlace('Kyoto')!.destination.location,
        confidence: 0.9,
        sourceHash: 'hash',
      );
      await startJapan(
        Trip(
          id: 't',
          title: 'Autumn',
          visualProfile: kyotoReading,
          ownerId: 'me',
          memberIds: const ['me'],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      final plan = store.plans.single;
      expect(store.artContextForPlan(plan).packRanks.keys, ['country_jp']);
      expect(packOf('tokyo-dinner'), 'country_jp', reason: 'not Kyoto\'s, as it was');
      expect(packOf('kyoto-dinner'), 'city_jp_kyoto');
    });
  });
}
