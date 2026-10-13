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

  test('a name the app gave is remembered, and a trip saved before is the traveller\'s', () {
    final named = trip('t', title: 'Kyoto').copyWith(destination: kyoto, autoName: true);
    expect(Trip.fromJson('t', named.toJson()).autoName, isTrue);
    expect(Trip.fromJson('t', named.toEditableJson()).autoName, isTrue);
    expect(named.copyWith(autoName: false).toEditableJson()['autoName'], isFalse);
    expect(trip('t').toJson().containsKey('autoName'), isFalse);
    expect(Trip.fromJson('t', const {'title': 'Old'}).autoName, isFalse);
  });

  test('the app\'s own reading gives way to a verified one in another country', () {
    // "Naples, FL" read offline is Naples, Italy; the classifier checked.
    final florida = Trip.fromJson('t', {
      'title': 'Naples',
      'visualProfile': {
        'primaryTheme': 'beach_resort',
        'confidence': 0.9,
        'sourceHash': 'a' * 64,
        'location': {'countryCode': 'US', 'confidence': 0.9, 'verificationStatus': 'verified'},
      },
    });
    const naples = TripDestination(countryCode: 'IT', countryName: 'Italy', city: 'Naples', citySlug: 'naples');
    expect(florida.copyWith(destination: naples, autoName: true).effectiveLocation?.countryCode, 'US');
    expect(florida.copyWith(destination: naples).effectiveLocation?.countryCode, 'IT', reason: 'the traveller\'s');
    // The same country: the app's reading, which may name the city.
    expect(
      florida.copyWith(destination: kyoto.copyWithCountry('US'), autoName: true).effectiveLocation?.citySlug,
      'kyoto',
    );
  });

  test('anything but a real country is ignored', () {
    expect(TripDestination.tryParse({'countryCode': 'XX', 'countryName': 'Nowhere'}), isNull);
    expect(TripDestination.tryParse({'countryCode': 'JP'}), isNull);
    expect(TripDestination.tryParse('Japan'), isNull);
    final odd = TripDestination.tryParse({'countryCode': 'jp', 'countryName': 'Japan', 'citySlug': 'Not A Slug'})!;
    expect((odd.countryCode, odd.citySlug), ('JP', null));
  });
}

extension on TripDestination {
  TripDestination copyWithCountry(String code) => TripDestination(
    countryCode: code,
    countryName: countryName,
    region: region,
    regionSlug: regionSlug,
    city: city,
    citySlug: citySlug,
  );
}
