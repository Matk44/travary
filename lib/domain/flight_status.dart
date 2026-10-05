import 'local_date.dart';

/// Where a flight is, as the airline reports it (AeroDataBox's statuses).
enum FlightState {
  unknown('Unknown'),
  expected('Expected'),
  enRoute('EnRoute'),
  checkIn('CheckIn'),
  boarding('Boarding'),
  gateClosed('GateClosed'),
  departed('Departed'),
  delayed('Delayed'),
  approaching('Approaching'),
  arrived('Arrived'),
  canceled('Canceled'),
  diverted('Diverted'),
  canceledUncertain('CanceledUncertain');

  const FlightState(this.wireName);

  final String wireName;

  static FlightState fromWire(Object? value) =>
      values.firstWhere((state) => state.wireName == value, orElse: () => unknown);
}

/// A time on an airport's clock, like the ticket prints it.
class FlightTime {
  const FlightTime(this.date, this.time);

  /// "2026-10-04T10:30"; null if it isn't one.
  static FlightTime? tryParse(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2})').firstMatch(value);
    if (match == null) return null;
    return FlightTime(LocalDate.parse(match[1]!), ClockTime.parse(match[2]!));
  }

  final LocalDate date;
  final ClockTime time;

  @override
  bool operator ==(Object other) => other is FlightTime && other.date == date && other.time == time;

  @override
  int get hashCode => Object.hash(date, time);
}

/// One end of the flight: where, when, and the airport details that change
/// on the day.
class FlightEnd {
  const FlightEnd({
    this.airport,
    this.airportName,
    this.airportFullName,
    this.city,
    this.scheduled,
    this.revised,
    this.delayMinutes,
    this.terminal,
    this.gate,
    this.checkInDesk,
    this.baggageBelt,
  });

  factory FlightEnd.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    String? text(String key) => map[key] is String && (map[key] as String).isNotEmpty ? map[key] as String : null;
    return FlightEnd(
      airport: text('airport'),
      airportName: text('airportName'),
      airportFullName: text('airportFullName'),
      city: text('city'),
      scheduled: FlightTime.tryParse(map['scheduled']),
      revised: FlightTime.tryParse(map['revised']),
      delayMinutes: (map['delayMinutes'] as num?)?.toInt(),
      terminal: text('terminal'),
      gate: text('gate'),
      checkInDesk: text('checkInDesk'),
      baggageBelt: text('baggageBelt'),
    );
  }

  /// IATA code, e.g. "LHR".
  final String? airport;

  /// Short name for the status: "Heathrow".
  final String? airportName;

  /// Full name for a booking's location: "London Heathrow".
  final String? airportFullName;

  /// The city it serves: "London".
  final String? city;
  final FlightTime? scheduled;

  /// The airline's actual or estimated time, when it has given one.
  final FlightTime? revised;

  /// Minutes late (negative when early).
  final int? delayMinutes;
  final String? terminal;
  final String? gate;
  final String? checkInDesk;
  final String? baggageBelt;
}

/// A flight's live status on the day: gate, terminal, delays.
class FlightStatus {
  const FlightStatus({
    required this.number,
    this.airline,
    required this.state,
    required this.departure,
    required this.arrival,
    this.updatedAt,
    required this.checkedAt,
  });

  /// From the `flightStatus` function's answer.
  factory FlightStatus.fromJson(Map<String, Object?> flight, {required DateTime checkedAt}) => FlightStatus(
    number: flight['number'] as String? ?? '',
    airline: flight['airline'] as String?,
    state: FlightState.fromWire(flight['status']),
    departure: FlightEnd.fromJson(flight['departure']),
    arrival: FlightEnd.fromJson(flight['arrival']),
    updatedAt: DateTime.tryParse(flight['updatedAt'] as String? ?? ''),
    checkedAt: checkedAt,
  );

  /// As the airline writes it, e.g. "BA 283".
  final String number;
  final String? airline;
  final FlightState state;
  final FlightEnd departure;
  final FlightEnd arrival;

  /// When the airline's information last changed.
  final DateTime? updatedAt;

  /// When Travary last asked.
  final DateTime checkedAt;
}
