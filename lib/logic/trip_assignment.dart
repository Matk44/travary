import 'package:intl/intl.dart';

import '../domain/domain.dart';
import 'trip_plan.dart';
import 'trip_route.dart';

/// Bookings within this many days of a trip are assumed to belong to it.
const tripMarginDays = 2;

/// Finds the trip a booking dated [start]–[end] belongs to, or null when it
/// needs a new trip. Prefers a trip the dates actually fall inside, then the
/// nearest one within [tripMarginDays].
TripPlan? findTripFor(LocalDate start, LocalDate end, List<TripPlan> plans, {int marginDays = tripMarginDays}) {
  TripPlan? best;
  var bestGap = marginDays + 1;
  for (final plan in plans.where((p) => p.hasDates)) {
    final gap = gapBetween(start, end, plan.start!, plan.end!);
    if (gap < bestGap) {
      best = plan;
      bestGap = gap;
    }
  }
  return best;
}

/// Bookings read from one file (a confirmation email, an itinerary PDF)
/// belong together when they're this close.
const sameSourceMarginDays = 30;

/// A flight home joins the trip it ends, even days later: one that flies
/// back to where the trip's flight out left from, from where that flight
/// went ("Lisbon to London" on the 8th goes with "London to Lisbon" on the
/// 3rd) or from elsewhere in a country the trip goes to ("Tokyo to London"
/// with "London to Osaka": in to one city, home from another), but never
/// from home's own country. Within [sameSourceMarginDays] of the trip's
/// start. Returns null when [booking] isn't such a flight.
TripPlan? findReturnFlightTrip(Booking booking, List<TripPlan> plans) {
  if (booking.kind != BookingKind.flight) return null;
  final route = routeOf(booking);
  if (route == null) return null;
  final from = transferPlace(route.from);
  final leavesFrom = from != null && from.countryCode != transferPlace(route.to)?.countryCode ? from : null;
  TripPlan? best;
  for (final plan in plans.where((p) => p.hasDates)) {
    final daysAfterStart = plan.start!.daysUntil(booking.startDate);
    if (daysAfterStart < 0 || daysAfterStart > sameSourceMarginDays) continue;
    final countries = _countriesOf(plan);
    final isReturn = plan.bookings.any((b) {
      final outbound = b.kind == BookingKind.flight ? routeOf(b) : null;
      if (outbound == null || !samePlaceName(outbound.from, route.to)) return false;
      if (samePlaceName(outbound.to, route.from)) return true;
      return leavesFrom != null && countries.contains(leavesFrom.countryCode);
    });
    if (isReturn && (best == null || plan.start!.isAfter(best.start!))) best = plan;
  }
  return best;
}

/// The countries [plan]'s bookings and destination are in.
Set<String> _countriesOf(TripPlan plan) => {
  ?plan.trip.destination?.countryCode,
  for (final booking in plan.bookings) ?ownPlaceOf(booking)?.countryCode,
};

/// Days between two date ranges; 0 when they overlap.
int gapBetween(LocalDate aStart, LocalDate aEnd, LocalDate bStart, LocalDate bEnd) {
  if (aEnd.isBefore(bStart)) return aEnd.daysUntil(bStart);
  if (bEnd.isBefore(aStart)) return bEnd.daysUntil(aStart);
  return 0;
}

/// A name and place for a trip the app makes for [bookings]: the first
/// booking, or everything in one file that goes with it. Where they go
/// ([readTripPlace]), else [suggestTripTitle] of the first, with no place.
({String title, TripDestination? destination}) suggestTripName(List<Booking> bookings) {
  final place = readTripPlace(bookings).place;
  if (place != null) return (title: place.name, destination: place.destination);
  final first = bookings.reduce((a, b) => b.startsAt.isBefore(a.startsAt) ? b : a);
  return (title: suggestTripTitle(first), destination: null);
}

/// [trip] renamed after [bookings] (all it has now), when the app named it
/// ([Trip.autoName]) and they say somewhere else; null when nothing changes.
/// Bookings in several countries keep the name but drop the place, for the
/// classifier to read the main one; bookings that name nowhere change
/// nothing.
Trip? followBookings(Trip trip, Iterable<Booking> bookings) {
  if (!trip.autoName) return null;
  final reading = readTripPlace(bookings);
  final place = reading.place;
  if (place != null) {
    final destination = place.destination;
    if (trip.title == place.name && trip.destination == destination) return null;
    return trip.copyWith(title: place.name, destination: destination);
  }
  if (reading.mixed && trip.destination != null) return trip.copyWith(clearDestination: true);
  return null;
}

/// A sensible name for a trip created automatically from [booking] when
/// it names nowhere the app knows. The traveller can rename it later.
String suggestTripTitle(Booking booking) {
  final title = booking.title.trim();
  if (booking.kind == BookingKind.flight) {
    final match = RegExp(r'\bto\s+(.+)$', caseSensitive: false).firstMatch(title);
    if (match != null) return _capitalise(match.group(1)!.trim());
  }
  final location = booking.location?.trim() ?? '';
  if (location.isNotEmpty && location.length <= 24) return location;
  return '${DateFormat('MMMM').format(booking.startDate.toDateTime())} trip';
}

String _capitalise(String value) => value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
