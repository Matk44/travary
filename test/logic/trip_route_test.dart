import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/destinations.dart';
import 'package:travary/logic/trip_route.dart';

import '../helpers.dart';

/// Osaka, Kyoto and Tokyo, in on the 1st and home from Tokyo on the 14th.
final japan = [
  booking(
    'out',
    BookingKind.flight,
    d(11, 1),
    title: 'London to Osaka',
    at: const ClockTime(11, 0),
    endDate: d(11, 2),
    until: const ClockTime(8, 0),
    location: 'London Heathrow (LHR)',
  ),
  booking('osaka', BookingKind.stay, d(11, 2), title: 'Hotel Hankyu', endDate: d(11, 5), location: 'Kita-ku, Osaka'),
  booking('lunch', BookingKind.dining, d(11, 3), title: 'Lunch', at: const ClockTime(12, 30)),
  booking('pass', BookingKind.transport, d(11, 3), title: 'Japan Rail Pass', endDate: d(11, 10)),
  booking('kyoto', BookingKind.stay, d(11, 5), title: 'Hotel Granvia Kyoto', endDate: d(11, 9)),
  booking('morning', BookingKind.activity, d(11, 5), title: 'Morning walk', at: const ClockTime(10, 0)),
  booking('dinner', BookingKind.dining, d(11, 5), title: 'Dinner', at: const ClockTime(19, 0)),
  booking('breakfast', BookingKind.dining, d(11, 9), title: 'Breakfast', at: const ClockTime(8, 0)),
  booking(
    'train',
    BookingKind.transport,
    d(11, 9),
    title: 'Kyoto to Tokyo',
    at: const ClockTime(9, 30),
    until: const ClockTime(11, 45),
    location: 'Kyoto Station',
  ),
  booking('tea', BookingKind.dining, d(11, 9), title: 'Tea', at: const ClockTime(16, 0)),
  booking('museum', BookingKind.attraction, d(11, 9), title: 'Museum'),
  booking('tokyo', BookingKind.stay, d(11, 9), title: 'Park Hotel', endDate: d(11, 14), location: 'Minato, Tokyo'),
  booking('home', BookingKind.flight, d(11, 14), title: 'Tokyo to London', at: const ClockTime(11, 0)),
];

Booking find(String id, [List<Booking> bookings = const []]) =>
    (bookings.isEmpty ? japan : bookings).firstWhere((b) => b.id == id);

void main() {
  final osaka = detectPlace('Osaka')!;
  final kyoto = detectPlace('Kyoto')!;
  final tokyo = detectPlace('Tokyo')!;

  group('routes', () {
    ({String from, String to})? route(String title, [BookingKind kind = BookingKind.transport]) =>
        routeOf(booking('x', kind, d(11, 1), title: title));

    test('a transfer\'s name gives its two ends', () {
      expect(route('Osaka to Tokyo'), (from: 'Osaka', to: 'Tokyo'));
      expect(route('Osaka → Tokyo'), (from: 'Osaka', to: 'Tokyo'));
      expect(route('Osaka - Tokyo'), (from: 'Osaka', to: 'Tokyo'));
      expect(route('Kyoto – Tokyo', BookingKind.flight), (from: 'Kyoto', to: 'Tokyo'));
      expect(route('BA 7 - London to Tokyo', BookingKind.flight)?.to, 'Tokyo');
    });

    test('where it arrives is the detail kept for it, when there is one', () {
      final flight = booking(
        'f',
        BookingKind.flight,
        d(11, 1),
        title: 'JL 123',
        location: 'Tokyo Haneda (HND)',
        details: {DetailKeys.arrivesAt: 'Kansai International (KIX)'},
      );
      expect(routeOf(flight), (from: 'Tokyo Haneda (HND)', to: 'Kansai International (KIX)'));
      expect(ownPlaceOf(flight), detectPlace('Osaka'), reason: 'Kansai is Osaka\'s airport');
    });

    test('no route without one, or outside transfers', () {
      expect(route('Shin-Osaka shuttle'), isNull);
      expect(route('Airport transfer'), isNull);
      expect(route('Kyoto to Tokyo', BookingKind.stay), isNull);
    });

    test('the same place by two names', () {
      expect(samePlaceName('London Heathrow', 'london'), isTrue);
      expect(samePlaceName('Somewhere', 'somewhere'), isTrue);
      expect(samePlaceName('Osaka', 'Tokyo'), isFalse);
      expect(samePlaceName('Nagano, Japan', 'Sendai, Japan'), isFalse, reason: 'two towns, one country');
    });
  });

  group('the place a booking names', () {
    test('a transfer is on its way to where it arrives', () {
      expect(ownPlaceOf(find('out')), osaka);
      expect(ownPlaceOf(find('train')), tokyo, reason: 'not Kyoto Station, where it leaves');
    });

    test('a flight\'s address is where it leaves from, so it doesn\'t count', () {
      final flight = booking('f', BookingKind.flight, d(11, 1), title: 'JL 123', location: 'Tokyo Haneda (HND)');
      expect(ownPlaceOf(flight), isNull);
    });

    test('anything else: its address, else its name', () {
      expect(ownPlaceOf(find('osaka')), osaka);
      expect(ownPlaceOf(find('kyoto')), kyoto, reason: 'Hotel Granvia Kyoto');
      final named = booking('h', BookingKind.stay, d(11, 1), title: 'Kyoto Machiya', location: 'Japan');
      expect(ownPlaceOf(named), kyoto, reason: 'the name says more than the country');
      expect(ownPlaceOf(find('lunch')), isNull);
    });
  });

  group('where each booking is', () {
    final route = TripRoute.of(japan, countryCode: 'JP');

    test('bookings that name a city are there', () {
      expect(route.placeOf(find('osaka')), osaka);
      expect(route.placeOf(find('kyoto')), kyoto);
      expect(route.placeOf(find('tokyo')), tokyo);
      expect(route.placeOf(find('out')), osaka, reason: 'the flight in shows where it goes');
    });

    test('the rest are wherever the traveller is staying', () {
      expect(route.placeOf(find('lunch')), osaka);
      expect(route.placeOf(find('pass')), osaka, reason: 'it names only Japan; on the 3rd that\'s Osaka');
    });

    test('a move splits its day: the morning where they were, the evening where they\'re going', () {
      // To Kyoto with no train booked: the hotel checks in at 15:00.
      expect(route.placeOf(find('morning')), osaka);
      expect(route.placeOf(find('dinner')), kyoto);
      // To Tokyo on the 9:30 train, there at 11:45.
      expect(route.placeOf(find('breakfast')), kyoto);
      expect(route.placeOf(find('tea')), tokyo);
      expect(route.placeOf(find('museum')), tokyo, reason: 'all day: from midday');
    });

    test('the flight home is in the city it leaves, not home', () {
      expect(route.placeOf(find('home')), tokyo);
    });

    test('a booking being edited is placed as it now reads', () {
      final moved = booking('lunch', BookingKind.dining, d(11, 3), title: 'Lunch', location: 'Gion, Kyoto');
      expect(route.placeOf(moved), kyoto);
    });

    test('every place, and where they stay', () {
      expect(route.places, [osaka, kyoto, tokyo]);
      expect(route.visited, {osaka, kyoto, tokyo});
    });

    test('just the trip\'s own country is the trip\'s own art', () {
      final pass = booking('p', BookingKind.transport, d(11, 1), title: 'Japan Rail Pass');
      expect(TripRoute.of([pass], countryCode: 'JP').placeOf(pass), isNull);
    });
  });

  group('which countries count', () {
    test('a trip\'s own country, and another two bookings name', () {
      // An Italian trip that starts in Paris.
      final bookings = [
        booking('in', BookingKind.flight, d(6, 1), title: 'London to Paris'),
        booking('paris', BookingKind.stay, d(6, 1), title: 'Hotel', endDate: d(6, 4), location: 'Paris'),
        booking('rome', BookingKind.stay, d(6, 4), title: 'Hotel', endDate: d(6, 9), location: 'Rome'),
      ];
      final route = TripRoute.of(bookings, countryCode: 'IT');
      expect(route.placeOf(find('paris', bookings)), detectPlace('Paris'));
      expect(route.placeOf(find('rome', bookings)), detectPlace('Rome'));
    });

    test('one booking can\'t take a trip to another country', () {
      final texas = [
        booking('h', BookingKind.stay, d(6, 1), title: 'Inn', endDate: d(6, 3), location: '123 Main St, Paris, TX'),
        booking('b', BookingKind.dining, d(6, 2), title: 'BBQ', location: 'Austin, TX'),
      ];
      expect(TripRoute.of(texas, countryCode: 'US').placeOf(texas.first), isNull);
    });

    test('when none is in the trip\'s own country, none count', () {
      // Naples, Florida, by the classifier; Naples, Italy, offline.
      final florida = [
        booking('f', BookingKind.flight, d(6, 1), title: 'New York to Naples'),
        booking('h', BookingKind.stay, d(6, 1), title: 'Beach Resort', endDate: d(6, 5), location: 'Naples, FL'),
      ];
      final route = TripRoute.of(florida, countryCode: 'US');
      expect(route.placeOf(florida.last), isNull);
      expect(route.places, isEmpty);
    });

    test('with no country of its own, a place needs two bookings', () {
      final hotel = booking('h', BookingKind.stay, d(6, 1), title: 'Hotel Granvia Kyoto', endDate: d(6, 3));
      final temple = booking('t', BookingKind.attraction, d(6, 2), title: 'Kinkaku-ji', location: 'Kyoto');
      expect(TripRoute.of([hotel]).placeOf(hotel), isNull);
      expect(TripRoute.of([hotel, temple]).placeOf(hotel), kyoto);
    });
  });

  group('the trip\'s own art', () {
    TripLocationHint hint(String city, String region) => TripLocationHint(
      countryCode: 'JP',
      countryName: 'Japan',
      region: region,
      regionSlug: region.toLowerCase(),
      city: city,
      citySlug: city.toLowerCase(),
      confidence: 0.9,
      verification: LocationVerification.verified,
    );
    Trip classified(String city, String region) => trip('t').copyWithProfile(hint(city, region));

    test('the classifier\'s main city, for a trip that stays in several, widens to the country', () {
      final location = tripArtLocation(classified('Kyoto', 'Kansai'), TripRoute.of(japan, countryCode: 'JP'));
      expect((location?.countryCode, location?.regionSlug, location?.citySlug), ('JP', null, null));
    });

    test('to the region, when all of them are in it', () {
      final kansai = [find('osaka'), find('kyoto')];
      final location = tripArtLocation(classified('Kyoto', 'Kansai'), TripRoute.of(kansai, countryCode: 'JP'));
      expect((location?.regionSlug, location?.citySlug), ('kansai', null));
    });

    test('a day out isn\'t a second place to stay', () {
      final dayOut = [
        find('kyoto'),
        booking('nara', BookingKind.transport, d(11, 6), title: 'Kyoto to Nara', at: const ClockTime(9, 0)),
        booking('back', BookingKind.transport, d(11, 6), title: 'Nara to Kyoto', at: const ClockTime(16, 0)),
      ];
      final location = tripArtLocation(classified('Kyoto', 'Kansai'), TripRoute.of(dayOut, countryCode: 'JP'));
      expect(location?.citySlug, 'kyoto');
    });

    test('a city the traveller chose stays theirs', () {
      final chosen = trip('t').copyWith(destination: kyoto.destination);
      expect(tripArtLocation(chosen, TripRoute.of(japan, countryCode: 'JP'))?.citySlug, 'kyoto');
      final named = chosen.copyWith(autoName: true);
      expect(tripArtLocation(named, TripRoute.of(japan, countryCode: 'JP'))?.citySlug, isNull);
    });
  });

  group('where a trip goes, to name it', () {
    Place? placeOf(List<Booking> bookings) => readTripPlace(bookings).place;
    final viaDubai = [
      booking(
        'a',
        BookingKind.flight,
        d(11, 1),
        title: 'London to Dubai',
        at: const ClockTime(9, 0),
        until: const ClockTime(19, 0),
      ),
      booking(
        'b',
        BookingKind.flight,
        d(11, 1),
        title: 'Dubai to Osaka',
        at: const ClockTime(21, 0),
        endDate: d(11, 2),
        until: const ClockTime(11, 0),
      ),
    ];

    test('a stopover on the way isn\'t where it goes', () {
      expect(placeOf(viaDubai), osaka);
      expect(placeOf([viaDubai.first]), detectPlace('Dubai'), reason: 'until the flight on is added');
    });

    test('in to one city and home from another: the country', () {
      expect(placeOf([find('out'), find('home')]), countryPlace('JP'));
    });

    test('there and back', () {
      final lisbon = [
        booking('a', BookingKind.flight, d(11, 1), title: 'London to Lisbon'),
        booking('b', BookingKind.flight, d(11, 8), title: 'Lisbon to London'),
      ];
      expect(placeOf(lisbon), detectPlace('Lisbon'));
    });

    test('where they stay decides', () {
      expect(placeOf(japan), countryPlace('JP'));
      expect(placeOf([...viaDubai, find('kyoto')]), kyoto, reason: 'in to Osaka for a stay in Kyoto');
      // A night in Dubai on the way doesn't make it a two-country trip.
      final night = booking(
        'n',
        BookingKind.stay,
        d(11, 1),
        title: 'Airport hotel',
        endDate: d(11, 2),
        location: 'Dubai',
      );
      expect(placeOf([night, ...japan]), countryPlace('JP'));
    });

    test('several countries: no one place', () {
      final europe = [
        booking('p', BookingKind.stay, d(6, 1), title: 'Hotel', endDate: d(6, 5), location: 'Paris'),
        booking('r', BookingKind.stay, d(6, 5), title: 'Hotel', endDate: d(6, 8), location: 'Rome'),
      ];
      expect(readTripPlace(europe).place, isNull);
      expect(readTripPlace(europe).mixed, isTrue);
    });

    test('a country beside a place in it says no more', () {
      final ryokan = booking('r', BookingKind.stay, d(11, 9), title: 'Ryokan', endDate: d(11, 10), location: 'Japan');
      expect(placeOf([find('kyoto'), ryokan]), kyoto);
    });

    test('otherwise wherever its bookings are, or nowhere', () {
      expect(placeOf([booking('n', BookingKind.dining, d(11, 1), title: 'Nobu', location: 'Tokyo')]), tokyo);
      expect(readTripPlace([find('lunch')]).place, isNull);
      expect(readTripPlace([find('lunch')]).mixed, isFalse);
    });
  });
}

extension on Trip {
  /// This trip as the classifier read it, at [location].
  Trip copyWithProfile(TripLocationHint location) => Trip(
    id: id,
    title: title,
    visualProfile: TripVisualProfile(
      primaryTheme: ExperienceTheme.urbanHeritage,
      location: location,
      confidence: 0.9,
      sourceHash: 'hash',
    ),
    ownerId: ownerId,
    memberIds: memberIds,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
