import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/image_header.dart' as header;
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_resolver.dart';
import 'package:travary/design/art/art_slots.dart';
import 'package:travary/design/art/card_shells.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';

import '../helpers.dart';
import '../support/canonical_today.dart';

void main() {
  final bundled = bundledArtCatalog();
  final shells = ShellResolver(bundled);
  TripArtContext look(ExperienceTheme theme, {List<ExperienceTheme> secondary = const []}) =>
      TripArtContext(theme: theme, secondaryThemes: secondary);
  String? file(ShellArt? shell) => shell?.art.fileKey;

  group('bundled shell families', () {
    test('each look with shells gets its own, filename aliases included', () {
      final expected = {
        ExperienceTheme.themepark: ('featured_ticket', 'room_card', 'reservation_card_blank'),
        ExperienceTheme.coastalResort: (
          'coastal_resort_featured_ticket',
          'coastal_resort_room_card',
          'coastal_resort_reservation_card',
        ),
        ExperienceTheme.urbanHeritage: (
          'urban_heritage_featured_ticket',
          'urban_heritage_room_card',
          'urban_heritage_reservation_card',
        ),
        // alpine_adventure_* → alpine, countryside_escape_* → countryside.
        ExperienceTheme.alpine: (
          'alpine_adventure_featured_ticket',
          'alpine_adventure_room_card',
          'alpine_adventure_reservation_card',
        ),
        ExperienceTheme.countryside: (
          'countryside_escape_featured_ticket',
          'countryside_escape_room_card',
          'countryside_escape_reservation_card',
        ),
      };
      for (final entry in expected.entries) {
        final set = shells.resolve(look(entry.key));
        expect((file(set.featured), file(set.room), file(set.reservation)), entry.value, reason: entry.key.name);
        expect(set.featured!.standInFor, isNull);
      }
    });

    test('looks without shells borrow the nearest family; tagged cards use the blank shell', () {
      for (final entry in shellStandIns.entries) {
        final set = shells.resolve(look(entry.key));
        expect(set.featured!.art.theme, entry.value, reason: entry.key.name);
        expect(set.featured!.standInFor, entry.key);
        expect(set.room!.art.theme, entry.value);
        expect(file(set.reservation), 'reservation_card_blank', reason: 'a vignette always fits the booking');
        expect(set.reservation!.isComplete, isFalse);
      }
      expect(file(shells.resolve(look(ExperienceTheme.classicTravel)).featured), 'urban_heritage_featured_ticket');
    });

    test('a secondary look\'s shells come before a stand-in', () {
      final set = shells.resolve(look(ExperienceTheme.cruise, secondary: [ExperienceTheme.alpine]));
      expect(file(set.featured), 'alpine_adventure_featured_ticket');
      expect(set.featured!.standInFor, isNull);
    });

    test('shells are complete except the blank reservation card', () {
      final set = shells.resolve(look(ExperienceTheme.themepark));
      expect(set.featured!.isComplete, isTrue);
      expect(set.room!.isComplete, isTrue);
      expect(set.reservation!.role, ShellRole.reservationBlank);
      expect(set.reservation!.geometry.vignette, isNotNull);
      expect(
        shells.resolve(look(ExperienceTheme.coastalResort)).reservation!.geometry.vignette,
        isNull,
        reason: 'nothing is layered on a complete shell',
      );
    });

    test('an unthemed complete reservation card is never used for every look', () {
      final catalog = ArtCatalog.fromAssetPaths([
        'assets/art/common/reservation_card.png',
        'assets/art/common/reservation_card_blank.png',
      ]);
      expect(
        file(ShellResolver(catalog).resolve(look(ExperienceTheme.themepark)).reservation),
        'reservation_card_blank',
      );
    });

    test('with no shells at all, none: cards fall back to plain panels', () {
      final set = const ShellResolver(ArtCatalog.empty()).resolve(look(ExperienceTheme.themepark));
      expect((set.featured, set.room, set.reservation), (null, null, null));
    });
  });

  group('downloaded shells', () {
    ArtPackRef pack(String id, ArtPackSelectors selectors) =>
        ArtPackRef(id: id, version: 1, priority: 100, selectors: selectors);
    final city = pack('city_us_orlando', const ArtPackSelectors(countryCodes: ['US'], cities: ['orlando']));
    final country = pack('country_us', const ArtPackSelectors(countryCodes: ['US']));
    final experience = pack('theme_themepark', const ArtPackSelectors(themes: [ExperienceTheme.themepark]));

    ArtPackContent content(ArtPackRef pack, {int width = 1774, int height = 887}) => ArtPackContent(
      pack: pack,
      assets: const [],
      common: {
        'featured_ticket': FileArtImage('/packs/${pack.id}/1/common/featured_ticket.png'),
        'reservation_card': FileArtImage('/packs/${pack.id}/1/common/reservation_card.png'),
      },
      sizes: {
        'common/featured_ticket': (width: width, height: height),
        'common/reservation_card': (width: 1983, height: 793),
      },
    );
    TripArtContext orlando(Map<String, ArtRank> ranks) =>
        TripArtContext(theme: ExperienceTheme.themepark, packRanks: ranks);

    test('a destination pack overrides the bundled shell through ArtCatalog.common', () {
      final catalog = bundled.withPacks([content(country)]);
      final context = orlando({'country_us': ArtRank.country});
      expect(
        catalog.common('featured_ticket', context: context),
        const FileArtImage('/packs/country_us/1/common/featured_ticket.png'),
      );
      final set = ShellResolver(catalog).resolve(context);
      expect(set.featured!.art.pack?.id, 'country_us');
      expect(set.reservation!.role, ShellRole.reservationCard, reason: 'the pack has a complete tagged card');
      expect(set.room!.art.isBundled, isTrue, reason: 'roles the pack lacks stay bundled');
    });

    test('city, then country, then the look\'s pack, then bundled', () {
      final catalog = bundled.withPacks([content(city), content(country), content(experience)]);
      String? featured(Map<String, ArtRank> ranks) =>
          ShellResolver(catalog).resolve(orlando(ranks)).featured?.art.fileKey;
      expect(
        featured({'city_us_orlando': ArtRank.city, 'country_us': ArtRank.country, 'theme_themepark': ArtRank.primary}),
        'city_us_orlando:featured_ticket',
      );
      expect(
        featured({'country_us': ArtRank.country, 'theme_themepark': ArtRank.primary}),
        'country_us:featured_ticket',
      );
      expect(featured({'theme_themepark': ArtRank.primary}), 'theme_themepark:featured_ticket');
      expect(featured({}), 'featured_ticket', reason: 'packs that don\'t suit the trip are ignored');
    });

    test('pack shells use the role template; a wrongly sized one is skipped', () {
      final good = ShellResolver(
        bundled.withPacks([content(country)]),
      ).shell(ShellRole.featuredTicket, orlando({'country_us': ArtRank.country}));
      expect(good!.geometry.stubLabel, isNotNull);
      final squashed = bundled.withPacks([content(country, width: 1000, height: 1000)]);
      final skipped = ShellResolver(squashed).shell(ShellRole.featuredTicket, orlando({'country_us': ArtRank.country}));
      expect(skipped!.art.isBundled, isTrue);
    });

    test('pack icons override bundled ones in the same ranked order', () {
      final catalog = bundled.withPacks([
        ArtPackContent(
          pack: experience,
          assets: const [],
          icons: {'nav_today': const FileArtImage('/packs/tp/icons/nav_today.png')},
        ),
      ]);
      final slots = ArtSlots(catalog, orlando({'theme_themepark': ArtRank.primary}));
      expect(slots.icon(IconSlot.navToday).image, const FileArtImage('/packs/tp/icons/nav_today.png'));
      expect(
        ArtSlots(catalog, orlando({})).icon(IconSlot.navToday).image,
        const BundledArtImage('assets/art/icons/nav_today.png'),
      );
    });
  });

  group('icons and surfaces', () {
    test('supplied raster icons are used; missing ones say so', () {
      final slots = ArtSlots(bundled, look(ExperienceTheme.themepark));
      // Every booking kind has its raster icon, drawn as one set.
      for (final kind in BookingKind.values) {
        final icon = slots.icon(IconSlot.forKind(kind));
        expect(icon.image, BundledArtImage('assets/art/icons/${icon.slot.key}.png'), reason: kind.name);
      }
      // Icons, like surfaces, are used exactly when their files exist.
      for (final slot in IconSlot.values) {
        expect(slots.icon(slot).isFallback, !File('assets/art/icons/${slot.key}.png').existsSync(), reason: slot.key);
      }
      for (final supplied in [IconSlot.navDocuments, IconSlot.navProfile, IconSlot.navAdd, IconSlot.attach]) {
        expect(slots.icon(supplied).isFallback, isFalse, reason: supplied.key);
      }
      // Surfaces are used exactly when their files exist.
      for (final surface in SurfaceSlot.values) {
        expect(
          slots.surface(surface) != null,
          File('assets/art/common/${surface.key}.png').existsSync(),
          reason: surface.key,
        );
      }
    });

    test('every card carries its shells and kind icon', () {
      final booking = bookingFor(BookingKind.dining, 'Be Our Guest Restaurant');
      final choice = ArtResolver(bundled).resolve(booking, look(ExperienceTheme.themepark));
      expect(choice.shells.featured?.art.fileKey, 'featured_ticket');
      expect(choice.icon?.image, const BundledArtImage('assets/art/icons/dining.png'));
      expect(choice.vignette?.group, 'themepark_castle_01', reason: 'the theme park\'s castle dining picture');
      // Its scene, for featured cards and Documents.
      expect(choice.scene?.group, 'themepark_castle_01');
    });
  });

  group('measured geometry', () {
    final commonFiles = Directory('assets/art/common')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.png', ''))
        .where((name) => ShellRole.values.any((role) => name == role.key || name.endsWith('_${role.key}')))
        .toList();

    test('every bundled shell file has measured anchors', () {
      expect(commonFiles, isNotEmpty);
      for (final name in commonFiles) {
        expect(ShellGeometry.measuredFiles, contains(name), reason: name);
      }
    });

    test('each shell is its role\'s exact size, and its anchors sit inside its card', () {
      for (final name in commonFiles) {
        final role = ShellRole.values.lastWhere((role) => name == role.key || name.endsWith('_${role.key}'));
        final info = header.readImageInfo(File('assets/art/common/$name.png').readAsBytesSync())!;
        expect((info.width, info.height), (role.width, role.height), reason: name);

        final art = SharedArtRef(image: BundledArtImage('assets/art/common/$name.png'), name: role.key);
        final geometry = ShellGeometry.of(role, art);
        final body = geometry.body;
        bool inside(FractionRect r, FractionRect outer) =>
            r.left >= outer.left &&
            r.top >= outer.top &&
            r.right <= outer.right &&
            r.bottom <= outer.bottom &&
            r.width > 0 &&
            r.height > 0;
        const image = FractionRect(0, 0, 1, 1);
        expect(inside(body, image), isTrue, reason: '$name body');
        for (final anchor in [
          geometry.text,
          geometry.action,
          geometry.stubLabel,
          geometry.footnote,
          geometry.vignette,
          geometry.scene,
        ]) {
          if (anchor != null) expect(inside(anchor, body), isTrue, reason: '$name $anchor');
        }
        if (geometry.tagIcon != null) expect(inside(geometry.tagIcon!, image), isTrue);
        // Live text never runs into the printed illustration's panel.
        if (geometry.vignette != null) expect(geometry.text.right, lessThan(geometry.vignette!.left));
        if (geometry.stubLabel != null) expect(geometry.text.right, lessThan(geometry.stubLabel!.left));
      }
    });
  });
}

Booking bookingFor(BookingKind kind, String title) =>
    booking('b', kind, d(10, 14), title: title, at: const ClockTime(12, 30));
