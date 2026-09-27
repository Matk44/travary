import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_resolver.dart';
import 'package:travary/domain/domain.dart';

import '../helpers.dart';

void main() {
  final catalog = ArtCatalog.fromAssetPaths([
    'assets/art/dining/classic_01.png',
    'assets/art/dining/classic_02.png',
    'assets/art/dining/tropical_01.png',
    'assets/art/dining/tropical_02.webp',
    'assets/art/stay/key_card.png', // no theme prefix: counts as classic
    'assets/art/common/linen.png',
    'assets/art/dining/.gitkeep',
    'assets/art/unknown/classic_01.png',
    'assets/fonts/whatever.ttf',
  ]);

  group('catalog', () {
    test('groups artwork by kind and theme', () {
      expect(catalog.assetsFor(BookingKind.dining, TripTheme.tropical).map((a) => a.path),
          ['assets/art/dining/tropical_01.png', 'assets/art/dining/tropical_02.webp']);
    });

    test('falls back to classic, then nothing', () {
      expect(catalog.assetsFor(BookingKind.dining, TripTheme.snow), hasLength(2));
      expect(catalog.assetsFor(BookingKind.stay, TripTheme.tropical).single.path, 'assets/art/stay/key_card.png');
      expect(catalog.assetsFor(BookingKind.flight, TripTheme.classic), isEmpty);
    });

    test('finds shared textures', () {
      expect(catalog.common('linen'), 'assets/art/common/linen.png');
    });
  });

  group('resolver', () {
    test('is stable for the same booking', () {
      final b = booking('abc', BookingKind.dining, d(10, 14));
      final first = ArtResolver(catalog).resolve(b, TripTheme.tropical);
      final second = ArtResolver(catalog).resolve(b, TripTheme.tropical);
      expect(first.asset?.path, second.asset?.path);
      expect(first.variant, second.variant);
    });

    test('honours artwork the traveller picked', () {
      final b = booking('abc', BookingKind.dining, d(10, 14)).copyWith(artKey: 'assets/art/dining/classic_02.png');
      expect(ArtResolver(catalog).resolve(b, TripTheme.tropical).asset?.path, 'assets/art/dining/classic_02.png');
    });

    test('never shows the same picture twice in a row', () {
      final bookings = [for (var i = 0; i < 12; i++) booking('b$i', BookingKind.dining, d(10, 14))];
      final choices = ArtResolver(catalog).resolveAll(bookings, (_) => TripTheme.tropical);
      for (var i = 1; i < choices.length; i++) {
        expect(choices[i].asset?.path, isNot(choices[i - 1].asset?.path));
      }
    });

    test('placeholder variants also differ side by side', () {
      final bookings = [for (var i = 0; i < 12; i++) booking('b$i', BookingKind.flight, d(10, 14))];
      final choices = const ArtResolver(ArtCatalog.empty()).resolveAll(bookings, (_) => TripTheme.classic);
      for (var i = 1; i < choices.length; i++) {
        expect(choices[i].variant % 3, isNot(choices[i - 1].variant % 3));
      }
    });

    test('stableHash is fixed across runs', () {
      expect(stableHash('o-lunch'), stableHash('o-lunch'));
      // FNV-1a of "a" is 0xe40c292c; the sign bit is dropped.
      expect(stableHash('a'), 0xe40c292c & 0x7fffffff);
    });
  });
}
