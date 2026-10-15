import '../domain/domain.dart';
import 'day_plan.dart';
import 'formatters.dart';

/// "ba 283", "BA-283", "ezy8123" → "BA283", "EZY8123"; null when it isn't a
/// flight number yet. Mirrors `cleanFlightNumber` on the server, so the app
/// only asks once a whole number has been typed.
String? cleanFlightNumber(String input) {
  final clean = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^(?:[A-Z]{3}|[A-Z0-9]{2})\d{1,4}[A-Z]?$').hasMatch(clean) ? clean : null;
}

/// What a found flight fills in on the add-flight form, from the airline's
/// schedule: the times printed on the ticket, not today's delays.
class FlightFill {
  const FlightFill({
    required this.title,
    required this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.location,
    this.arrival,
    required this.flightNumber,
  });

  /// "London to Los Angeles".
  final String title;
  final LocalDate startDate;
  final ClockTime? startTime;

  /// Set when it lands on a later day, or on the same day earlier by the
  /// clock (east across the date line: [keptEndDate]).
  final LocalDate? endDate;
  final ClockTime? endTime;

  /// The departure airport, with its code so live status finds the right
  /// leg: "London Heathrow (LHR)".
  final String? location;

  /// The arrival airport, the same way: "Los Angeles (LAX)".
  final String? arrival;

  /// As the airline writes it: "BA 283".
  final String flightNumber;
}

/// The form's fill for [leg]. Null when the schedule has no departure time.
FlightFill? flightFill(FlightStatus leg, {required String typedNumber}) {
  final departs = leg.departure.scheduled;
  if (departs == null) return null;
  final lands = leg.arrival.scheduled;
  return FlightFill(
    title: '${_place(leg.departure)} to ${_place(leg.arrival)}',
    startDate: departs.date,
    startTime: departs.time,
    endDate: lands == null ? null : keptEndDate(departs.date, lands.date, startTime: departs.time, endTime: lands.time),
    endTime: lands?.time,
    location: _airport(leg.departure),
    arrival: _airport(leg.arrival),
    flightNumber: leg.number.isEmpty ? typedNumber : leg.number,
  );
}

/// The add-flight form's fields a found flight fills in.
class FlightFields {
  const FlightFields({
    required this.startDate,
    this.title = '',
    this.location = '',
    this.arrival = '',
    this.startTime,
    this.endDate,
    this.endTime,
  });

  final LocalDate startDate;
  final String title;
  final String location;
  final String arrival;
  final ClockTime? startTime;
  final LocalDate? endDate;
  final ClockTime? endTime;
}

/// The form once the board's answer changes from [previous] to [fill] (null:
/// no flight on the board now). A field that's empty, or still holds what
/// [previous] put there, takes [fill]'s value, or is emptied when there's
/// none; whatever the traveller typed is kept. The day is the found
/// flight's, or [searchDate] again once the flight that set it has gone.
FlightFields refillFlight(FlightFields form, {FlightFill? previous, FlightFill? fill, required LocalDate searchDate}) {
  String text(String current, String? before, String? next) =>
      current.trim().isEmpty || (previous != null && current == before) ? next ?? '' : current;
  T? value<T>(T? current, T? before, T? next) =>
      current == null || (previous != null && current == before) ? next : current;
  return FlightFields(
    startDate:
        fill?.startDate ?? (previous != null && form.startDate == previous.startDate ? searchDate : form.startDate),
    title: text(form.title, previous?.title, fill?.title),
    location: text(form.location, previous?.location, fill?.location),
    arrival: text(form.arrival, previous?.arrival, fill?.arrival),
    startTime: value(form.startTime, previous?.startTime, fill?.startTime),
    endDate: value(form.endDate, previous?.endDate, fill?.endDate),
    endTime: value(form.endTime, previous?.endTime, fill?.endTime),
  );
}

/// A found flight, worded for "Is this your flight?".
class FoundFlightText {
  const FoundFlightText({required this.heading, required this.route, required this.times});

  /// "BA 283 · British Airways".
  final String heading;

  /// "London Heathrow (LHR) → Los Angeles (LAX)".
  final String route;

  /// "10:05am → 1:25pm", with the day when it lands on a later one.
  final String times;
}

FoundFlightText describeFoundFlight(FlightStatus leg) {
  final departs = leg.departure.scheduled;
  final lands = leg.arrival.scheduled;
  final landTime = lands == null
      ? null
      : departs != null && lands.date != departs.date
      ? '${formatClock(lands.time)} ${formatDayShort(lands.date)}'
      : formatClock(lands.time);
  return FoundFlightText(
    heading: [leg.number, ?leg.airline].where((part) => part.isNotEmpty).join(' · '),
    route: '${_airport(leg.departure) ?? 'Departure'} → ${_airport(leg.arrival) ?? 'Arrival'}',
    times: [departs == null ? 'Time to be confirmed' : formatClock(departs.time), ?landTime].join(' → '),
  );
}

String _place(FlightEnd end) => end.city ?? end.airportName ?? end.airport ?? '?';

String? _airport(FlightEnd end) {
  final name = end.airportFullName ?? end.airportName;
  if (name == null) return end.airport;
  return end.airport == null ? name : '$name (${end.airport})';
}

/// A found flight on the departures board: "QF 25" / "Sydney" → "Tokyo"
/// / "20:55", and when it lands.
class BoardText {
  const BoardText({required this.flight, required this.from, required this.to, this.departs, this.lands});

  /// As the airline writes it, in capitals: "QF 25".
  final String flight;
  final String from;
  final String to;

  /// The board's twenty-four-hour clock: "20:55".
  final String? departs;

  /// Under the board: "Lands 6:10am Mon 12 Oct".
  final String? lands;
}

BoardText boardTextFor(FlightStatus leg, {required String typedNumber}) {
  final departs = leg.departure.scheduled;
  final arrives = leg.arrival.scheduled;
  final String? lands;
  if (arrives == null) {
    lands = null;
  } else if (departs != null && arrives.date != departs.date) {
    lands = 'Lands ${formatClock(arrives.time)} ${formatDayShort(arrives.date)}';
  } else {
    lands = 'Lands ${formatClock(arrives.time)}';
  }
  return BoardText(
    flight: (leg.number.isEmpty ? typedNumber : leg.number).toUpperCase(),
    from: _place(leg.departure),
    to: _place(leg.arrival),
    departs: departs == null ? null : formatClock24(departs.time),
    lands: lands,
  );
}
