import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_resolver.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_subjects.dart';

import '../helpers.dart';

void main() {
  final catalog = ArtCatalog.fromAssetPaths([
    'assets/art/dining/any_pizza_01_scene.png',
    'assets/art/dining/any_pizza_01_vignette.png',
    'assets/art/dining/tropical_pizza_01.png',
    'assets/art/dining/tropical_grill_01_scene.png',
    'assets/art/dining/tropical_01.png', // old style: generic, both formats
    'assets/art/dining/classic_generic_01.webp',
    'assets/art/dining/classic_generic_02.webp',
    'assets/art/attraction/themepark_castle_01_scene.png',
    'assets/art/stay/key_card.png', // no theme: classic, generic
    'assets/art/common/linen.png',
    'assets/art/icons/dining.png',
    'assets/art/dining/.gitkeep',
    'assets/art/unknown/classic_01.png',
    'assets/fonts/whatever.ttf',
  ]);

  group('catalog', () {
    test('reads theme, subject, group and format from file names', () {
      final assets = {for (final a in catalog.allFor(BookingKind.dining)) a.path: a};
      final scene = assets['assets/art/dining/any_pizza_01_scene.png']!;
      expect(scene.theme, isNull);
      expect(scene.subject, 'pizza');
      expect(scene.group, 'any_pizza_01');
      expect(scene.format, ArtFormat.scene);

      final old = assets['assets/art/dining/tropical_01.png']!;
      expect(old.theme, TripTheme.tropical);
      expect(old.subject, genericSubject);
      expect(old.format, isNull);

      final bare = catalog.allFor(BookingKind.stay).single;
      expect(bare.theme, TripTheme.classic);
      expect(bare.subject, genericSubject);
    });

    test('finds shared textures and icons', () {
      expect(catalog.common('linen'), 'assets/art/common/linen.png');
      expect(catalog.icon('dining'), 'assets/art/icons/dining.png');
    });

    test('ignores other folders and files', () {
      expect(catalog.allFor(BookingKind.flight), isEmpty);
    });
  });

  group('choosing a picture', () {
    const resolver = ArtResolver.new;
    Booking dining(String id, String title, {String? artSubject}) => Booking(
      id: id,
      tripId: 't',
      kind: BookingKind.dining,
      title: title,
      startDate: d(10, 14),
      artSubject: artSubject,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    test('matches the subject in the trip theme first', () {
      final choice = resolver(catalog).resolve(dining('a', 'Harbour Pizza Co.'), TripTheme.tropical);
      expect(choice.subject, 'pizza');
      expect(choice.group, 'tropical_pizza_01');
    });

    test('then a theme-free picture of the subject, pairing scene and vignette', () {
      final choice = resolver(catalog).resolve(dining('a', 'Harbour Pizza Co.'), TripTheme.city);
      expect(choice.group, 'any_pizza_01');
      expect(choice.scene?.path, 'assets/art/dining/any_pizza_01_scene.png');
      expect(choice.vignette?.path, 'assets/art/dining/any_pizza_01_vignette.png');
      expect(choice.preferring(ArtFormat.vignette)?.format, ArtFormat.vignette);
    });

    test('a subject chosen by Smart Import beats keywords', () {
      final choice = resolver(catalog).resolve(dining('a', 'Ohana', artSubject: 'grill'), TripTheme.tropical);
      expect(choice.group, 'tropical_grill_01');
      expect(choice.vignette, isNull);
      expect(choice.preferring(ArtFormat.vignette)?.path, choice.scene?.path, reason: 'falls back to the scene');
    });

    test('with no subject match, a generic picture for the theme', () {
      final choice = resolver(catalog).resolve(dining('a', 'Sunshine Terrace'), TripTheme.tropical);
      expect(choice.subject, isNull);
      expect(choice.group, 'tropical_01');
    });

    test('anything for the theme beats a generic from elsewhere', () {
      final booking = Booking(
        id: 'p', tripId: 't', kind: BookingKind.attraction, title: 'Sunshine Park',
        startDate: d(10, 14), createdAt: DateTime(2026), updatedAt: DateTime(2026),
      );
      expect(resolver(catalog).resolve(booking, TripTheme.themepark).group, 'themepark_castle_01');
    });

    test('is stable and honours a picked picture', () {
      final b = dining('abc', 'Sunshine Terrace');
      expect(resolver(catalog).resolve(b, TripTheme.city).group, resolver(catalog).resolve(b, TripTheme.city).group);
      final picked = b.copyWith(artKey: 'any_pizza_01');
      expect(resolver(catalog).resolve(picked, TripTheme.city).group, 'any_pizza_01');
    });

    test('never shows the same picture twice in a row', () {
      final bookings = [for (var i = 0; i < 12; i++) dining('b$i', 'Sunshine Terrace')];
      final choices = resolver(catalog).resolveAll(bookings, (_) => TripTheme.city);
      for (var i = 1; i < choices.length; i++) {
        expect(choices[i].group, isNot(choices[i - 1].group));
      }
    });

    test('placeholders also differ side by side', () {
      final bookings = [for (var i = 0; i < 12; i++) booking('b$i', BookingKind.flight, d(10, 14))];
      final choices = const ArtResolver(ArtCatalog.empty()).resolveAll(bookings, (_) => TripTheme.classic);
      for (var i = 1; i < choices.length; i++) {
        expect(choices[i].variant % 3, isNot(choices[i - 1].variant % 3));
      }
    });

    test('stableHash is fixed across runs', () {
      // FNV-1a of "a" is 0xe40c292c; the sign bit is dropped.
      expect(stableHash('a'), 0xe40c292c & 0x7fffffff);
    });
  });

  group('subjects from keywords', () {
    String? subject(BookingKind kind, String title, {String? location, Map<String, String> details = const {}}) =>
        artSubjectFor(booking('x', kind, d(10, 14), title: title, location: location, details: details));

    test('reads the name, place and details', () {
      expect(subject(BookingKind.dining, 'Harbour Pizza Co.'), 'pizza');
      expect(subject(BookingKind.dining, 'Pancake House'), 'breakfast');
      expect(subject(BookingKind.dining, 'Lagoon Grill'), 'grill');
      expect(subject(BookingKind.dining, 'Le Petit Bistro'), 'bistro');
      expect(subject(BookingKind.attraction, 'Splash Lagoon Water Park'), 'waterpark');
      expect(subject(BookingKind.activity, 'Everglades airboat tour'), 'boat');
      expect(subject(BookingKind.activity, 'Space Center tour'), 'space');
      expect(subject(BookingKind.event, 'Evening Circus Show'), 'show');
      expect(subject(BookingKind.transport, 'London to Windermere', details: {DetailKeys.company: 'Avanti West Coast'}), 'train');
      expect(subject(BookingKind.transport, 'Car hire'), 'car');
    });

    test('matches whole words only', () {
      expect(subject(BookingKind.dining, 'Barnaby\'s'), isNull, reason: '"bar" inside a word');
      expect(subject(BookingKind.stay, 'Scampi Towers'), isNull, reason: '"camp" inside a word');
    });

    test('nothing fits', () {
      expect(subject(BookingKind.dining, 'Sunshine Terrace'), isNull);
      expect(subject(BookingKind.note, 'Pack sunscreen'), isNull);
    });
  });

  test('the app and Smart Import use the same subjects', () {
    final ts = File('functions/src/artSubjects.ts').readAsStringSync();
    final server = <String, List<String>>{
      for (final m in RegExp(r"(\w+): \[([^\]]*)\]").allMatches(ts))
        m.group(1)!: RegExp(r"'([a-z]+)'").allMatches(m.group(2)!).map((s) => s.group(1)!).toList(),
    };
    for (final kind in BookingKind.values) {
      expect(server[kind.name], artSubjects[kind]!.keys.toList(), reason: kind.name);
    }
  });
}
