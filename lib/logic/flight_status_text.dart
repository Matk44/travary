import '../domain/domain.dart';
import 'formatters.dart';

/// What to ask the server for: a flight on its departure date.
class FlightLookup {
  const FlightLookup({required this.flightNumber, required this.date, this.from});

  final String flightNumber;
  final LocalDate date;

  /// The departure airport's IATA code, when the booking names one.
  final String? from;

  @override
  bool operator ==(Object other) =>
      other is FlightLookup && other.flightNumber == flightNumber && other.date == date && other.from == from;

  @override
  int get hashCode => Object.hash(flightNumber, date, from);
}

/// How many days before departure live status starts. Earlier, only the
/// schedule is known, and that's already on the ticket.
const flightStatusDaysAhead = 3;

/// The lookup for [booking] if it's a flight with a number whose live
/// status is worth showing on [today]: from [flightStatusDaysAhead] days
/// before it leaves until the day after it lands.
FlightLookup? flightLookupFor(Booking booking, LocalDate today) {
  final number = _flightNumber(booking);
  if (number == null) return null;
  if (today.isBefore(booking.startDate.addDays(-flightStatusDaysAhead))) return null;
  if (today.isAfter(booking.lastDate.addDays(1))) return null;
  return FlightLookup(flightNumber: number, date: booking.startDate, from: airportCodeIn(booking.location));
}

/// True when [booking] is a flight whose live status will show nearer the
/// day ("Live gate and delays show here from 3 days before take-off").
bool flightStatusComesLater(Booking booking, LocalDate today) =>
    _flightNumber(booking) != null && today.isBefore(booking.startDate.addDays(-flightStatusDaysAhead));

const flightStatusComesLaterText =
    'Live gate, terminal and delays show here from $flightStatusDaysAhead days before take-off.';

String? _flightNumber(Booking booking) {
  if (booking.kind != BookingKind.flight) return null;
  final number = booking.detail(DetailKeys.flightNumber)?.trim();
  return number == null || number.isEmpty ? null : number;
}

/// An IATA airport code written in [location] ("London Heathrow (LHR)",
/// "LHR T5"), else null. Only capitals count, so words aren't mistaken
/// for codes.
String? airportCodeIn(String? location) {
  if (location == null) return null;
  final codes = RegExp(r'(?<![A-Za-z])[A-Z]{3}(?![A-Za-z])').allMatches(location).map((m) => m[0]!).toList();
  return codes.length == 1 ? codes.single : null;
}

/// How the status reads at a glance.
enum FlightTone { good, notice, bad, neutral }

/// One end of the flight, worded.
class FlightEndText {
  const FlightEndText({required this.title, this.time, this.was, this.details});

  /// "Departs Heathrow", "Arrives Los Angeles".
  final String title;

  /// "11:05am" (the airline's latest time).
  final String? time;

  /// The scheduled time when it has changed: "10:30am".
  final String? was;

  /// "Terminal 5 · Gate B32 · Check-in D".
  final String? details;
}

/// A flight's live status, worded for the flight's own page.
class FlightStatusText {
  const FlightStatusText({
    required this.title,
    required this.headline,
    required this.tone,
    required this.departure,
    required this.arrival,
    required this.checked,
  });

  /// "Live status · BA 283".
  final String title;

  /// "On time", "Delayed 35 min", "Boarding", "Cancelled".
  final String headline;
  final FlightTone tone;
  final FlightEndText departure;
  final FlightEndText arrival;

  /// "Checked just now", "Checked 5 min ago".
  final String checked;
}

FlightStatusText describeFlightStatus(FlightStatus status, DateTime now) {
  final (headline, tone) = _headline(status);
  return FlightStatusText(
    title: 'Live status${status.number.isEmpty ? '' : ' · ${status.number}'}',
    headline: headline,
    tone: tone,
    departure: _end('Departs', status.departure, [
      _prefixed('Terminal', status.departure.terminal),
      _prefixed('Gate', status.departure.gate),
      _prefixed('Check-in', status.departure.checkInDesk),
    ]),
    arrival: _end('Arrives', status.arrival, [
      _prefixed('Terminal', status.arrival.terminal),
      _prefixed('Gate', status.arrival.gate),
      _prefixed('Baggage belt', status.arrival.baggageBelt),
    ]),
    checked: _checked(status.checkedAt, now),
  );
}

/// "35 min", "1 hr", "1 hr 20 min".
String formatDelay(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest min';
  return rest == 0 ? '$hours hr' : '$hours hr $rest min';
}

/// Late by this much or more reads as delayed: airlines count 15 minutes.
const _lateMinutes = 15;

(String, FlightTone) _headline(FlightStatus status) {
  final late = status.departure.delayMinutes;
  final landedLate = status.arrival.delayMinutes;
  return switch (status.state) {
    FlightState.canceled => ('Cancelled', FlightTone.bad),
    FlightState.canceledUncertain => ('May be cancelled', FlightTone.bad),
    FlightState.diverted => ('Diverted', FlightTone.bad),
    FlightState.arrived =>
      landedLate != null && landedLate >= _lateMinutes
          ? ('Landed ${formatDelay(landedLate)} late', FlightTone.notice)
          : ('Landed', FlightTone.good),
    FlightState.approaching => ('Landing soon', FlightTone.good),
    FlightState.enRoute || FlightState.departed => ('In the air', FlightTone.good),
    FlightState.boarding => ('Boarding', FlightTone.notice),
    FlightState.gateClosed => ('Gate closed', FlightTone.notice),
    _ when late != null && late >= _lateMinutes => ('Delayed ${formatDelay(late)}', FlightTone.bad),
    FlightState.delayed => ('Delayed', FlightTone.bad),
    FlightState.checkIn => ('Check-in open', FlightTone.good),
    _ when status.departure.revised != null => ('On time', FlightTone.good),
    _ => ('Scheduled', FlightTone.neutral),
  };
}

FlightEndText _end(String verb, FlightEnd end, List<String?> details) {
  final place = end.airportName ?? end.airport;
  final shown = end.revised ?? end.scheduled;
  final changed = end.revised != null && end.scheduled != null && end.revised != end.scheduled;
  final present = details.whereType<String>().toList();
  return FlightEndText(
    title: place == null ? verb : '$verb $place',
    time: shown == null ? null : _time(shown, end.scheduled),
    was: changed ? _time(end.scheduled!, end.scheduled) : null,
    details: present.isEmpty ? null : present.join(' · '),
  );
}

/// "11:05am", with the day when it has moved to another one.
String _time(FlightTime time, FlightTime? scheduled) {
  final clock = formatClock(time.time);
  return scheduled == null || time.date == scheduled.date ? clock : '$clock ${formatDayShort(time.date)}';
}

String? _prefixed(String label, String? value) => value == null ? null : '$label $value';

String _checked(DateTime checkedAt, DateTime now) {
  final minutes = now.difference(checkedAt).inMinutes;
  if (minutes < 1) return 'Checked just now';
  if (minutes < 60) return 'Checked $minutes min ago';
  return 'Checked at ${formatClock(ClockTime.fromDateTime(checkedAt))}';
}
