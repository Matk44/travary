import 'dart:math' as math;

import '../domain/domain.dart';
import 'airports.dart';
import 'destinations.dart';

/// Where a trip's bookings are: the city (or region, or country) each one
/// happens in, so a Kyoto day's cards show Kyoto and a Tokyo day's show
/// Tokyo, and where a trip as a whole goes, so the app can name it. Offline
/// and free: places come from the built-in list (`destinations.dart`).

/// A transfer's two ends: where it arrives ([DetailKeys.arrivesAt], from the
/// flight finder or Smart Import), else what its name says ("Osaka to
/// Tokyo", "Osaka → Tokyo", "Osaka - Tokyo"); where it leaves from, by its
/// name, else its address. Null for anything but a flight or transport, or
/// without both ends.
({String from, String to})? routeOf(Booking booking) {
  if (booking.kind != BookingKind.flight && booking.kind != BookingKind.transport) return null;
  final named = _routeIn(booking.title);
  final to = booking.detail(DetailKeys.arrivesAt) ?? named?.to;
  final location = booking.location?.trim();
  final from = named?.from ?? (location == null || location.isEmpty ? null : location);
  return to == null || from == null ? null : (from: from, to: to);
}

({String from, String to})? _routeIn(String title) {
  for (final pattern in _routePatterns) {
    final match = pattern.firstMatch(title);
    if (match != null) return (from: match.group(1)!.trim(), to: match.group(2)!.trim());
  }
  return null;
}

/// " to " first ("BA 7 - London to Tokyo" goes to Tokyo), then an arrow,
/// then a dash with spaces round it (never the one in "Shin-Osaka").
final _routePatterns = [
  RegExp(r'^\s*(.+?)\s+to\s+(.+?)\s*$', caseSensitive: false),
  RegExp(r'^\s*(.+?)\s*(?:→|->|⟶|➔)\s*(.+?)\s*$'),
  RegExp(r'^\s*(.+?)\s+[-–—]\s+(.+?)\s*$'),
];

/// The place one end of a transfer is in: an airport the app knows
/// ([airportPlace]: Kansai is Osaka), else whatever place it names.
Place? transferPlace(String text) => airportPlace(text) ?? _placeIn(text);

/// Whether [a] and [b], two ends of transfers, name the same place: the
/// same words, or one place by two names ("London Heathrow (LHR)",
/// "London"). Two towns in one country aren't the same place just because
/// the list only knows their country.
bool samePlaceName(String a, String b) {
  final folded = foldPlaceText(a);
  if (folded.isNotEmpty && folded == foldPlaceText(b)) return true;
  final place = transferPlace(a);
  return place != null && !place.isCountry && place == transferPlace(b);
}

/// The place [booking] names itself, or null: where a transfer goes
/// ("Osaka to Tokyo" is on its way to Tokyo), else its address, else its
/// name ("Hotel Granvia Kyoto"). A flight's address is the airport it
/// leaves from, so only its route counts.
Place? ownPlaceOf(Booking booking) {
  final route = routeOf(booking);
  final arrives = route == null ? null : transferPlace(route.to);
  if (arrives != null || booking.kind == BookingKind.flight) return arrives;
  final location = booking.location;
  final address = location == null ? null : _placeIn(location);
  final name = _placeIn(booking.title);
  if (address != null && !address.isCountry) return address;
  if (name != null && (address == null || name.countryCode == address.countryCode)) return name;
  return address;
}

/// Where each of a trip's bookings is.
///
/// A booking that names a place ([ownPlaceOf]) is there. One that doesn't
/// is wherever the traveller is at its time: where they last checked in or
/// arrived (all-day bookings count from midday; a stay with no time checks
/// in at 15:00), so on the day the train goes a morning is still in Osaka
/// and the evening in Kyoto. Before the first stay or arrival, it's the
/// first. A booking naming only a country is wherever the traveller is in
/// it.
///
/// Only places in the trip's countries count: its own (the traveller's,
/// the classifier's or the app's reading of its bookings) and any other
/// that two of its bookings name, so a week in Italy can take in Paris but
/// one hotel in "Paris, TX" doesn't take a Texas trip to France. When none
/// of the bookings is in the trip's own country, theirs don't count at
/// all: a Naples, Florida trip reads offline as Naples, Italy.
class TripRoute {
  TripRoute._(this.countryCode, this._bookings, this._own, this._countries, this._stops);

  /// The route of a trip made of [bookings], in [countryCode] (the trip's
  /// own country, when it has one).
  factory TripRoute.of(Iterable<Booking> bookings, {String? countryCode}) {
    final byId = {for (final booking in bookings) booking.id: booking};
    final own = {for (final booking in byId.values) booking.id: ownPlaceOf(booking)};
    final votes = <String, int>{};
    for (final place in own.values.nonNulls) {
      votes[place.countryCode] = (votes[place.countryCode] ?? 0) + 1;
    }
    final countries = {
      ?countryCode,
      if (countryCode == null || votes.containsKey(countryCode))
        for (final MapEntry(:key, :value) in votes.entries)
          if (value >= 2) key,
    };
    final stops = <_Stop>[];
    for (final booking in byId.values) {
      final place = own[booking.id];
      if (place == null || !countries.contains(place.countryCode)) continue;
      if (booking.kind == BookingKind.stay) {
        stops.add(_Stop(booking.startDate.toDateTime(booking.startTime ?? _checkIn), place, stay: true));
      } else if (routeOf(booking) != null) {
        stops.add(_Stop(_arrival(booking), place, stay: false));
      }
    }
    stops.sort((a, b) => a.at.compareTo(b.at));
    return TripRoute._(countryCode, byId, own, countries, List.unmodifiable(stops));
  }

  /// The trip's own country, if it has one.
  final String? countryCode;
  final Map<String, Booking> _bookings;
  final Map<String, Place?> _own;
  final Set<String> _countries;
  final List<_Stop> _stops;

  /// Where [booking] is (it needn't be one of the trip's yet: a booking
  /// being edited is placed as it now reads), or null when that's nowhere
  /// more than the trip's own country, whose art the trip has already.
  Place? placeOf(Booking booking) {
    final known = identical(_bookings[booking.id], booking);
    var place = _counted(known ? _own[booking.id] : ownPlaceOf(booking));
    if (place == null || place.isCountry) {
      final there = _whereAt(booking.startDate.toDateTime(booking.startTime ?? _midday));
      if (there != null && (place == null || there.countryCode == place.countryCode)) place = there;
    }
    if (place != null && place.isCountry && place.countryCode == countryCode) return null;
    return place;
  }

  /// Every place the trip's bookings are in ([placeOf]), in the order they
  /// first come up.
  late final List<Place> places = List.unmodifiable({for (final booking in _bookings.values) ?placeOf(booking)});

  /// The places the traveller stays in, or with nowhere to stay booked
  /// yet, the places they travel to.
  late final Set<Place> visited = () {
    final stays = {
      for (final stop in _stops)
        if (stop.stay) stop.place,
    };
    return stays.isNotEmpty ? stays : {for (final stop in _stops) stop.place};
  }();

  Place? _counted(Place? place) => place != null && _countries.contains(place.countryCode) ? place : null;

  Place? _whereAt(DateTime moment) {
    if (_stops.isEmpty) return null;
    Place? place;
    for (final stop in _stops) {
      if (stop.at.isAfter(moment)) break;
      place = stop.place;
    }
    return place ?? _stops.first.place;
  }
}

/// Where [trip]'s own art (postcards, colours, stamp) comes from: its
/// place, or the wider area round it (the region all its places share,
/// else the country) when nobody chose that place and the traveller stays
/// in several there. The classifier names one main city ("Kyoto") for a
/// trip through Osaka, Kyoto and Tokyo; that trip's postcard is Japan's.
TripLocationHint? tripArtLocation(Trip trip, TripRoute route) {
  final location = trip.effectiveLocation;
  if (location == null || (location.citySlug == null && location.regionSlug == null)) return location;
  final chosen = trip.destination != null && !trip.autoName;
  if (chosen) return location;
  final there = [
    for (final place in route.visited)
      if (place.countryCode == location.countryCode) place.destination,
  ];
  if (there.length < 2) return location;
  final region = location.regionSlug;
  final oneRegion = region != null && there.every((place) => place.regionSlug == region);
  return location.widened(keepRegion: oneRegion);
}

/// What a trip's bookings say about where it goes: one [place], or [mixed]
/// when they're spread over several countries, or neither when they name
/// nowhere the app knows.
class TripPlaceReading {
  const TripPlaceReading(this.place, {this.mixed = false});

  static const nowhere = TripPlaceReading(null);
  static const several = TripPlaceReading(null, mixed: true);

  final Place? place;
  final bool mixed;
}

/// Where a trip made of [bookings] goes, for the app to name it.
///
/// Where the traveller sleeps decides, once somewhere to stay is booked
/// (flying into Osaka for a week in Kyoto is a Kyoto trip): the country
/// with at least three quarters of the nights (a night in Dubai on the way
/// doesn't make a Japan trip mixed), and its places. With nowhere to stay
/// yet, the places its transfers go to, leaving out home (where the first
/// left from) and stopovers (left again within a day): "London to Dubai"
/// and "Dubai to Osaka" go to Osaka. Failing both, wherever its other
/// bookings are.
///
/// One place gives that place; several in one country give the country.
TripPlaceReading readTripPlace(Iterable<Booking> bookings) {
  final sorted = [...bookings]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  final nights = <Place, int>{};
  for (final booking in sorted.where((b) => b.kind == BookingKind.stay)) {
    if (ownPlaceOf(booking) case final place?) {
      nights[place] = (nights[place] ?? 0) + math.max(1, booking.startDate.daysUntil(booking.lastDate));
    }
  }
  if (nights.isNotEmpty) {
    final byCountry = <String, int>{};
    for (final MapEntry(key: place, value: count) in nights.entries) {
      byCountry[place.countryCode] = (byCountry[place.countryCode] ?? 0) + count;
    }
    final total = byCountry.values.fold(0, (sum, count) => sum + count);
    final main = byCountry.entries.reduce((a, b) => b.value > a.value ? b : a);
    if (main.value * 4 < total * 3) return TripPlaceReading.several;
    return _reduce(nights.keys.where((place) => place.countryCode == main.key));
  }
  final travelled = _travelledTo(sorted);
  if (travelled.isNotEmpty) return _reduce(travelled);
  return _reduce([for (final booking in sorted) ?ownPlaceOf(booking)]);
}

/// The places [sorted]'s transfers go to and leave from, but for home and
/// stopovers.
List<Place> _travelledTo(List<Booking> sorted) {
  final transfers = [
    for (final booking in sorted)
      if (routeOf(booking) case final route?) (booking: booking, route: route),
  ];
  if (transfers.isEmpty) return const [];
  final home = transfers.first.route.from;
  // The two ends at a stopover: the leg in's arrival, the leg out's departure.
  final stopoverArrivals = <int>{};
  final stopoverDepartures = <int>{};
  for (var i = 0; i + 1 < transfers.length; i++) {
    final (:booking, :route) = transfers[i];
    final next = transfers[i + 1];
    if (samePlaceName(next.route.from, route.to) &&
        next.booking.startsAt.difference(_arrival(booking)) < const Duration(hours: 24)) {
      stopoverArrivals.add(i);
      stopoverDepartures.add(i + 1);
    }
  }
  return [
    for (final (i, (booking: _, :route)) in transfers.indexed) ...[
      if (!stopoverArrivals.contains(i) && !samePlaceName(route.to, home)) ?transferPlace(route.to),
      if (i > 0 && !stopoverDepartures.contains(i) && !samePlaceName(route.from, home)) ?transferPlace(route.from),
    ],
  ];
}

/// One place, or the country several in one country share.
TripPlaceReading _reduce(Iterable<Place> found) {
  final places = found.toSet();
  if (places.isEmpty) return TripPlaceReading.nowhere;
  final countries = {for (final place in places) place.countryCode};
  if (countries.length > 1) return TripPlaceReading.several;
  // A country or region found beside a place inside it says no more.
  final specific = [
    for (final place in places)
      if (!places.any((other) => other != place && placeContains(place, other))) place,
  ];
  return TripPlaceReading(specific.length == 1 ? specific.single : countryPlace(countries.single));
}

/// When a transfer gets there, on its ticket's clock.
DateTime _arrival(Booking booking) {
  final start = booking.startTime;
  final end = booking.endTime;
  if (end != null) {
    // Saved bookings have their overnight end date; one still on the form may not.
    final overnight = booking.endDate == null && start != null && end.compareTo(start) < 0;
    return (overnight ? booking.startDate.addDays(1) : booking.lastDate).toDateTime(end);
  }
  if (start != null) return booking.startDate.toDateTime(start).add(booking.kind.spec.typicalDuration);
  return booking.lastDate.toDateTime(_midday);
}

/// [detectPlace], remembered: routes are worked out again whenever a trip
/// changes, from the same few names.
Place? _placeIn(String text) {
  if (_placesIn.length > 4000) _placesIn.clear();
  return _placesIn.putIfAbsent(text, () => detectPlace(text));
}

final _placesIn = <String, Place?>{};

const _midday = ClockTime(12, 0);
const _checkIn = ClockTime(15, 0);

class _Stop {
  const _Stop(this.at, this.place, {required this.stay});

  final DateTime at;
  final Place place;
  final bool stay;
}
