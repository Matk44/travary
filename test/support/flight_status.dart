import 'package:travary/data/flight_status_service.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/flight_status_text.dart';

/// Answers flight lookups from memory and records them.
class FakeFlightStatusService implements FlightStatusService {
  final calls = <FlightLookup>[];

  /// What [lookUp] answers.
  FlightStatus? answer;

  /// What [find] answers.
  List<FlightStatus> legs = const [];
  FlightStatusException? failure;

  @override
  Future<FlightStatus?> lookUp({required String flightNumber, required LocalDate date, String? from}) async {
    calls.add(FlightLookup(flightNumber: flightNumber, date: date, from: from));
    if (failure != null) throw failure!;
    return answer;
  }

  @override
  Future<List<FlightStatus>> find({required String flightNumber, required LocalDate date}) async {
    calls.add(FlightLookup(flightNumber: flightNumber, date: date));
    if (failure != null) throw failure!;
    return legs;
  }
}

/// BA 283, London to Los Angeles, as the `flightStatus` function answers.
FlightStatus ba283({
  String departs = '2026-11-08T10:05',
  String lands = '2026-11-08T13:25',
  String? revised,
  int? delayMinutes,
  String state = 'Expected',
  String? gate,
  DateTime? checkedAt,
}) => FlightStatus.fromJson({
  'number': 'BA 283',
  'airline': 'British Airways',
  'status': state,
  'departure': {
    'airport': 'LHR',
    'airportName': 'Heathrow',
    'airportFullName': 'London Heathrow',
    'city': 'London',
    'scheduled': departs,
    'revised': ?revised,
    'delayMinutes': delayMinutes,
    'terminal': '5',
    'gate': ?gate,
    'checkInDesk': 'D',
  },
  'arrival': {
    'airport': 'LAX',
    'airportName': 'Los Angeles',
    'airportFullName': 'Los Angeles',
    'city': 'Los Angeles',
    'scheduled': lands,
    'terminal': 'B',
  },
}, checkedAt: checkedAt ?? DateTime(2026, 10, 4, 9, 10));
