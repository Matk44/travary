import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_resolver.dart';
import 'package:travary/design/art/card_shells.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';

import '../helpers.dart';
import '../support/canonical_today.dart';

/// A pack's complete tagged card has its picture printed on it, the same
/// for every booking: neighbours must not show it twice.
void main() {
  const country = ArtPackRef(
    id: 'country_us',
    version: 1,
    priority: 100,
    selectors: ArtPackSelectors(countryCodes: ['US']),
  );
  final catalog = bundledArtCatalog().withPacks([
    ArtPackContent(
      pack: country,
      assets: const [],
      common: const {
        'featured_ticket': FileArtImage('/packs/country_us/1/common/featured_ticket.png'),
        'reservation_card': FileArtImage('/packs/country_us/1/common/reservation_card.png'),
      },
      sizes: const {
        'common/featured_ticket': (width: 1774, height: 887),
        'common/reservation_card': (width: 1983, height: 793),
      },
    ),
  ]);
  final context = TripArtContext(theme: ExperienceTheme.themepark, packRanks: const {'country_us': ArtRank.country});
  final resolver = ArtResolver(catalog);

  List<Booking> meals(int n) => [
    for (var i = 0; i < n; i++) booking('meal$i', BookingKind.dining, d(10, 14), at: ClockTime(12 + i, 0)),
  ];

  ShellRole? roleOf(ArtChoice choice) => choice.shells.standardFor(choice.kind)?.role;

  test('the pack really has a complete tagged card to share', () {
    final shell = resolver.resolve(meals(1).single, context).shells.reservation!;
    expect(shell.role, ShellRole.reservationCard);
    expect(shell.art.pack?.id, 'country_us');
  });

  test('the next tagged card takes the blank shell and its own vignette, then the pack\'s again', () {
    final choices = resolver.resolveAll(meals(4), (_) => context);
    expect(choices.map(roleOf), [
      ShellRole.reservationCard,
      ShellRole.reservationBlank,
      ShellRole.reservationCard,
      ShellRole.reservationBlank,
    ]);
  });

  test('only cards drawn as tagged cards count: a featured card between keeps the pack\'s shell', () {
    final choices = resolver.resolveAll(meals(3), (_) => context, tagged: (i) => i != 1);
    expect(choices.map(roleOf), [ShellRole.reservationCard, ShellRole.reservationCard, ShellRole.reservationCard]);
  });

  test('a stay between two meals has its key card; the meals are not neighbours', () {
    final bookings = [
      meals(1).single,
      booking('hotel', BookingKind.stay, d(10, 14), endDate: d(10, 18)),
      booking('dinner', BookingKind.dining, d(10, 14), at: const ClockTime(19, 0)),
    ];
    final choices = resolver.resolveAll(bookings, (_) => context);
    expect(choices.map(roleOf), [ShellRole.reservationCard, ShellRole.roomCard, ShellRole.reservationCard]);
  });

  test('without a blank shell to fall back on, the card keeps what it has', () {
    final lone = ArtCatalog.fromAssetPaths(['assets/art/common/reservation_card.png']);
    final choices = ArtResolver(lone).resolveAll(meals(2), (_) => context);
    expect(choices, hasLength(2));
  });
}
