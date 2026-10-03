import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/destinations.dart';

void main() {
  String? label(String text) => detectPlace(text)?.label;

  group('detecting the place in a trip\'s name', () {
    test('countries, by any of their names or their people\'s word', () {
      expect(label('Japan holiday'), 'Japan');
      expect(label('JAPAN!'), 'Japan');
      expect(label('Our Japanese adventure'), 'Japan');
      expect(label('Italian lakes'), 'Italy');
      expect(label('Holland 2027'), 'Netherlands');
      expect(label('Türkiye'), 'Turkey');
      expect(label('Ivory Coast'), 'Côte d’Ivoire');
      expect(label('Côte d’Ivoire'), 'Côte d’Ivoire');
      expect(label('UK road trip'), 'United Kingdom');
    });

    test('regions and cities, with the names they go by', () {
      expect(label('Kyoto'), 'Kyoto, Japan');
      expect(label('Disney World 2027'), 'Orlando, United States');
      expect(label('Disneyland Paris'), 'Paris, France');
      expect(label('The Lake District'), 'Lake District, United Kingdom');
      expect(label('Bali'), 'Bali, Indonesia');
      expect(label('Scotland'), 'Scotland, United Kingdom');
      expect(label('Mallorca villa'), 'Mallorca, Spain');
      expect(label('Majorca villa'), 'Mallorca, Spain');
      expect(label('São Paulo'), 'São Paulo, Brazil');
      expect(label('Sao Paulo'), 'São Paulo, Brazil');
    });

    test('the most specific place wins', () {
      expect(label('Kyoto, Japan'), 'Kyoto, Japan');
      expect(label('Orlando, Florida'), 'Orlando, United States');
      expect(label('Lake District, England'), 'Lake District, United Kingdom');
      expect(label('Edinburgh, Scotland'), 'Edinburgh, United Kingdom');
      expect(label('Paris and Disneyland Paris'), 'Paris, France');
    });

    test('the longest name takes its words', () {
      expect(label('New York'), 'New York, United States');
      expect(label('New South Wales'), 'New South Wales, Australia');
      expect(label('French Polynesia'), 'French Polynesia');
      expect(label('Papua New Guinea'), 'Papua New Guinea');
      expect(label('North Korea'), 'North Korea');
      expect(label('New England in the fall'), 'New England, United States');
      expect(label('South America'), isNull);
      expect(label('Indian Ocean cruise'), isNull);
    });

    test('several places in one country give the country; several countries nothing', () {
      expect(label('Kyoto and Tokyo'), 'Japan');
      expect(label('Italy and France'), isNull);
      expect(label('London to Paris'), isNull);
    });

    test('no place, everyday words and people\'s names: nothing', () {
      expect(label(''), isNull);
      expect(label('Grandma\'s'), isNull);
      expect(label('Honeymoon'), isNull);
      expect(label('A nice weekend'), isNull);
      expect(label('Jordan\'s wedding'), isNull);
      expect(label('Sydney\'s 40th'), isNull);
      expect(label('Bath time'), isNull);
      expect(label('Georgia'), isNull, reason: 'a country and a US state');
    });

    test('the destination carries the slugs art packs select by', () {
      final kyoto = detectPlace('Kyoto')!.destination;
      expect((kyoto.countryCode, kyoto.citySlug, kyoto.regionSlug), ('JP', 'kyoto', 'kansai'));
      final lakes = detectPlace('Lake District')!.destination;
      expect((lakes.countryCode, lakes.regionSlug, lakes.citySlug), ('GB', 'lake_district', null));
      final paris = detectPlace('Paris')!.destination;
      expect((paris.citySlug, paris.regionSlug), ('paris', 'ile_de_france'));
      expect(detectPlace('Japan')!.destination.location.verification, LocationVerification.verified);
    });
  });

  group('suggestions while typing', () {
    List<String> labels(String text) => [for (final s in suggestPlaces(text)) s.place.label];

    test('complete the place being typed at the end of the name', () {
      expect(suggestPlaces('Kyo').first.completed, 'Kyoto');
      expect(suggestPlaces('Summer in Kyo').first.completed, 'Summer in Kyoto');
      expect(suggestPlaces('new yo').first.completed, 'New York');
      expect(labels('Jap'), ['Japan']);
      expect(labels('Gre').first, 'Greece');
    });

    test('several places can share a beginning, each saying where it is', () {
      final disney = labels('Disney');
      expect(disney, containsAll(['Orlando, United States', 'Paris, France']));
      final world = suggestPlaces('Disney W').single;
      expect((world.name, world.where), ('Disney World', 'Orlando, United States'));
      expect(suggestPlaces('Kyo').first.where, 'Japan');
      expect(suggestPlaces('Jap').first.where, isNull);
    });

    test('everyday words are offered, for the traveller to confirm', () {
      expect(labels('Nice'), contains('Nice, France'));
      expect(labels('Georgia'), containsAll(['Georgia', 'Georgia, United States']));
    });

    test('nothing for short or filler words, and words for people are never offered', () {
      expect(suggestPlaces('Ky'), isEmpty);
      expect(suggestPlaces('Week in the'), isEmpty);
      expect(suggestPlaces('Japanes'), isEmpty);
    });
  });

  group('the destination picker', () {
    test('lists the favourite countries first, then every country', () {
      final all = searchPlaces('');
      expect(all.first.label, 'France');
      expect(all.length, isoCountryCodes.length);
    });

    test('finds a place by any word of its name', () {
      expect(
        searchPlaces('york').map((p) => p.label),
        containsAll(['New York, United States', 'York, United Kingdom']),
      );
      expect(searchPlaces('jap').first.label, 'Japan');
    });
  });

  group('the list itself', () {
    test('names every country, and every place is a valid destination', () {
      for (final code in isoCountryCodes) {
        expect(countryPlace(code).countryName, isNotEmpty, reason: code);
      }
      for (final place in places) {
        final destination = place.destination;
        expect(TripDestination.tryParse(destination.toJson()), destination, reason: place.label);
        expect(destination.regionSlug == null || isSlug(destination.regionSlug), isTrue, reason: place.label);
        expect(destination.citySlug == null || isSlug(destination.citySlug), isTrue, reason: place.label);
      }
    });

    test('every destination art pack has its place', () {
      final sources = Directory('art_packs/sources').listSync().whereType<Directory>();
      for (final source in sources) {
        final entry = File('${source.path}/catalog-entry.json');
        if (!entry.existsSync()) continue;
        final selectors = (jsonDecode(entry.readAsStringSync()) as Map)['selectors'] as Map;
        final countries = [for (final c in selectors['countryCodes'] as List? ?? const []) '$c'];
        if (countries.isEmpty) continue;
        final cities = [for (final c in selectors['cities'] as List? ?? const []) '$c'];
        final regions = [for (final r in selectors['regions'] as List? ?? const []) '$r'];
        final covered = places.any((place) {
          final d = place.destination;
          if (!countries.contains(d.countryCode)) return false;
          if (cities.isNotEmpty) return cities.contains(d.citySlug);
          if (regions.isNotEmpty) return regions.contains(d.regionSlug) && d.citySlug == null;
          return place.isCountry;
        });
        expect(covered, isTrue, reason: source.path);
      }
    });
  });
}
