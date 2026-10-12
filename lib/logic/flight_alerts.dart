import '../domain/domain.dart';
import 'flight_fill.dart';

/// Flight alerts (paid trips): the server watches a trip's flights and
/// tells everyone on it the moment one changes (functions/src/flightAlerts.ts).
/// These are the app's side of it: which flights it covers, when to ask for
/// notifications, and how the flight's page says where things stand.

/// Whether flight alerts cover [booking] on [today]: a flight with a flight
/// number that hasn't landed yet, at most a year ahead (the server's
/// `watchedFlightFor`).
bool flightAlertsCover(Booking booking, LocalDate today) {
  if (booking.kind != BookingKind.flight) return false;
  final number = booking.detail(DetailKeys.flightNumber);
  if (number == null || cleanFlightNumber(number) == null) return false;
  return !booking.lastDate.isBefore(today) && !booking.startDate.isAfter(today.addDays(365));
}

/// Whether opening this flight's page is the moment to ask for
/// notifications: alerts are on for its trip ([allowed]), they'd cover it
/// ([covered]), and this phone hasn't been asked (the system asks only
/// once). Never at launch.
bool shouldAskForNotifications({
  required bool allowed,
  required bool covered,
  required NotificationPermission permission,
}) => allowed && covered && permission == NotificationPermission.notAsked;

/// Where flight alerts stand for one flight, from this phone.
enum FlightAlertsState {
  /// The trip has no pass and nobody's Plus covers it.
  locked,

  /// On, and this phone shows them.
  on,

  /// On for the trip, but notifications are off on this phone.
  blocked,

  /// On for the trip; this phone hasn't been asked yet.
  ask,
}

FlightAlertsState flightAlertsStateFor({required bool allowed, required NotificationPermission permission}) {
  if (!allowed) return FlightAlertsState.locked;
  return switch (permission) {
    NotificationPermission.allowed => FlightAlertsState.on,
    NotificationPermission.denied => FlightAlertsState.blocked,
    NotificationPermission.notAsked => FlightAlertsState.ask,
  };
}

/// The flight page's row about alerts.
class FlightAlertsText {
  const FlightAlertsText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

/// Sold and described as flight changes: gates and belts only come when
/// the airport shares them, so they're never promised. [everyone] when the
/// trip itself has premium (a pass, or its organiser's Plus), so everyone
/// on it hears; else only this traveller's own Plus covers it.
FlightAlertsText flightAlertsTextFor(
  FlightAlertsState state, {
  required String flightNumber,
  required bool everyone,
  required bool shared,
}) {
  // Kept on one line: "BA 2037", never "BA" then "2037".
  final number = flightNumber.toUpperCase().replaceAll(' ', '\u00A0');
  final who = everyone && shared ? 'Everyone on this trip hears' : 'You\'ll hear';
  return switch (state) {
    FlightAlertsState.locked => FlightAlertsText(
      title: 'Flight alerts',
      subtitle: 'Know the moment $number is delayed, moved or cancelled, on everyone\'s phone.',
    ),
    FlightAlertsState.on => FlightAlertsText(
      title: 'Flight alerts are on',
      subtitle: '$who the moment $number is delayed, moved or cancelled.',
    ),
    FlightAlertsState.blocked => FlightAlertsText(
      title: 'Flight alerts are off on this phone',
      subtitle: 'Allow notifications for Travary in Settings to hear when $number changes.',
    ),
    FlightAlertsState.ask => FlightAlertsText(
      title: 'Turn on flight alerts',
      subtitle: 'Hear the moment $number is delayed, moved or cancelled.',
    ),
  };
}
