import 'package:flutter_test/flutter_test.dart';
import 'package:travary/logic/airports.dart';
import 'package:travary/logic/destinations.dart';

void main() {
  test('an airport by its code or its own name is the place it serves', () {
    expect(airportPlace('Kansai International (KIX)'), placeNamed('Osaka'));
    expect(airportPlace('Narita International Airport'), placeNamed('Tokyo'));
    expect(airportPlace('Newark Liberty (EWR)'), placeNamed('New York'));
    expect(airportPlace('NCE'), placeNamed('Nice'), reason: 'a name the list never detects on its own');
    expect(airportPlace('LHR T5'), placeNamed('London'));
  });

  test('anything else names no airport', () {
    expect(airportPlace('Kyoto Station'), isNull);
    expect(airportPlace('Hotel Granvia'), isNull);
    expect(airportPlace('kix'), isNull, reason: 'codes are capitals');
  });

  test('every airport serves a place the app knows', () {
    for (final MapEntry(key: code, value: name) in airportCodes.entries) {
      expect(placeNamed(name), isNotNull, reason: '$code serves $name');
    }
  });
}
