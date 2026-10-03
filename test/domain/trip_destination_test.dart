import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';

import '../helpers.dart';

void main() {
  const kyoto = TripDestination(
    countryCode: 'JP',
    countryName: 'Japan',
    region: 'Kansai',
    regionSlug: 'kansai',
    city: 'Kyoto',
    citySlug: 'kyoto',
  );

  test('a trip keeps its destination through storage', () {
    final stored = trip('t', title: 'Autumn').copyWith(destination: kyoto);
    expect(Trip.fromJson('t', stored.toJson()).destination, kyoto);
    expect(Trip.fromJson('t', stored.toEditableJson()).destination, kyoto);
  });

  test('removing it writes it away', () {
    final cleared = trip('t').copyWith(destination: kyoto).copyWith(clearDestination: true);
    expect(cleared.destination, isNull);
    expect(cleared.toEditableJson().containsKey('destination'), isTrue);
    expect(cleared.toEditableJson()['destination'], isNull);
    expect(cleared.toJson().containsKey('destination'), isFalse);
  });

  test('the traveller\'s destination is the place art goes by, over the classifier\'s', () {
    final classified = Trip.fromJson('t', {
      'title': 'Trip',
      'visualProfile': {
        'primaryTheme': 'urban_heritage',
        'confidence': 0.9,
        'sourceHash': 'a' * 64,
        'location': {'countryCode': 'FR', 'confidence': 0.9, 'verificationStatus': 'verified'},
      },
    });
    expect(classified.effectiveLocation?.countryCode, 'FR');
    final chosen = classified.copyWith(destination: kyoto);
    expect(chosen.effectiveLocation?.citySlug, 'kyoto');
    expect(chosen.effectiveLocation?.verification, LocationVerification.verified);
  });

  test('anything but a real country is ignored', () {
    expect(TripDestination.tryParse({'countryCode': 'XX', 'countryName': 'Nowhere'}), isNull);
    expect(TripDestination.tryParse({'countryCode': 'JP'}), isNull);
    expect(TripDestination.tryParse('Japan'), isNull);
    final odd = TripDestination.tryParse({'countryCode': 'jp', 'countryName': 'Japan', 'citySlug': 'Not A Slug'})!;
    expect((odd.countryCode, odd.citySlug), ('JP', null));
  });
}
