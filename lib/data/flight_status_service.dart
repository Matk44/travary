import 'package:cloud_functions/cloud_functions.dart';

import '../domain/domain.dart';

/// A problem worth showing the traveller as-is.
class FlightStatusException implements Exception {
  const FlightStatusException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Flights by number: their schedule (to fill in a new flight) and live
/// status (gate, terminal, delays). Runs on the server, which holds the
/// AeroDataBox key and shares answers between travellers.
abstract interface class FlightStatusService {
  /// Every leg flown as [flightNumber] on [date] (usually one), with the
  /// airline's schedule: up to `flightLookupDaysAhead` days ahead (the plan's
  /// limit). Empty when there's none.
  Future<List<FlightStatus>> find({required String flightNumber, required LocalDate date});

  /// [flightNumber] as the ticket prints it ("BA 283"), [date] the local
  /// departure date, [from] the departure airport's IATA code when known
  /// (one flight number can fly several legs a day). Null when the airline
  /// has nothing for that flight yet.
  Future<FlightStatus?> lookUp({required String flightNumber, required LocalDate date, String? from});
}

class CloudFlightStatusService implements FlightStatusService {
  CloudFlightStatusService({required this.ensureSignedIn, FirebaseFunctions? functions}) : _functions = functions;

  final Future<void> Function() ensureSignedIn;
  final FirebaseFunctions? _functions;

  @override
  Future<FlightStatus?> lookUp({required String flightNumber, required LocalDate date, String? from}) async {
    final data = await _call(flightNumber, date, from);
    final flight = data['flight'];
    return flight is Map ? _status(flight, data) : null;
  }

  @override
  Future<List<FlightStatus>> find({required String flightNumber, required LocalDate date}) async {
    final data = await _call(flightNumber, date, null);
    return [
      for (final leg in data['legs'] as List? ?? const [])
        if (leg is Map) _status(leg, data),
    ];
  }

  FlightStatus _status(Map<dynamic, dynamic> flight, Map<String, Object?> data) => FlightStatus.fromJson(
    Map<String, Object?>.from(flight),
    checkedAt: DateTime.tryParse(data['checkedAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
  );

  Future<Map<String, Object?>> _call(String flightNumber, LocalDate date, String? from) async {
    try {
      await ensureSignedIn();
      final result = await (_functions ?? FirebaseFunctions.instance).httpsCallable('flightStatus').call<dynamic>({
        'flightNumber': flightNumber,
        'date': date.toIso(),
        'from': ?from,
      });
      return Map<String, Object?>.from(result.data as Map? ?? const {});
    } on FirebaseFunctionsException catch (e) {
      throw FlightStatusException(
        e.code == 'internal' || (e.message ?? '').isEmpty
            ? 'Couldn\'t check the flight. Check your connection and try again.'
            : e.message!,
      );
    }
  }
}
