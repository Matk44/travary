import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_resolver.dart';
import 'package:travary/design/art/card_shells.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';

import '../helpers.dart';
import '../support/canonical_today.dart';

/// A country isn't a style: a Japan pack's historic-city ticket suits a
/// Kyoto trip, not an Okinawa beach week in the same country.
void main() {
  final bundled = bundledArtCatalog();
  const japan = ArtPackRef(
    id: 'country_jp',
    version: 1,
    priority: 500,
    selectors: ArtPackSelectors(countryCodes: ['JP']),
  );
  const okinawa = ArtPackRef(
    id: 'region_jp_okinawa',
    version: 1,
    priority: 500,
    selectors: ArtPackSelectors(countryCodes: ['JP'], regions: ['okinawa']),
  );

  TripArtContext trip(
    ExperienceTheme look, {
    Map<String, ArtRank> packs = const {'country_jp': ArtRank.country},
    List<ExperienceTheme> secondary = const [],
  }) => TripArtContext(theme: look, secondaryThemes: secondary, packRanks: packs);

  ArtPackContent japanPack({Map<String, List<ExperienceTheme>> themes = const {}, List<ArtAsset> assets = const []}) =>
      ArtPackContent(
        pack: japan,
        assets: assets,
        common: const {'featured_ticket': FileArtImage('/packs/country_jp/1/common/featured_ticket.png')},
        icons: const {'dining': FileArtImage('/packs/country_jp/1/icons/dining.png')},
        sizes: const {
          'common/featured_ticket': (width: 1774, height: 887),
          'icons/dining': (width: 1024, height: 1024),
        },
        themes: themes,
      );

  group('shells and icons drawn for particular looks', () {
    final heritageOnly = bundled.withPacks([
      japanPack(
        themes: {
          'common/featured_ticket': const [ExperienceTheme.urbanHeritage, ExperienceTheme.classicTravel],
        },
      ),
    ]);

    test('a Kyoto (historic city) trip gets the Japan ticket', () {
      final shell = ShellResolver(heritageOnly).shell(ShellRole.featuredTicket, trip(ExperienceTheme.urbanHeritage));
      expect(shell!.art.pack?.id, 'country_jp');
    });

    test('an Okinawa (coastal) trip in Japan keeps its own look\'s ticket', () {
      final shell = ShellResolver(heritageOnly).shell(ShellRole.featuredTicket, trip(ExperienceTheme.coastalResort));
      expect(shell!.art.fileKey, 'coastal_resort_featured_ticket');
    });

    test('a secondary look counts', () {
      final shell = ShellResolver(
        heritageOnly,
      ).shell(ShellRole.featuredTicket, trip(ExperienceTheme.urbanModern, secondary: [ExperienceTheme.urbanHeritage]));
      expect(shell!.art.pack?.id, 'country_jp');
    });

    test('unmarked pack art suits every look in the place, as before', () {
      final everyLook = bundled.withPacks([japanPack()]);
      for (final look in [ExperienceTheme.coastalResort, ExperienceTheme.alpine, ExperienceTheme.themepark]) {
        expect(ShellResolver(everyLook).shell(ShellRole.featuredTicket, trip(look))!.art.pack?.id, 'country_jp');
        expect(
          everyLook.icon('dining', context: trip(look)),
          const FileArtImage('/packs/country_jp/1/icons/dining.png'),
        );
      }
    });

    test('a region pack for a different look outranks the country pack', () {
      final catalog = bundled.withPacks([
        japanPack(
          themes: {
            'common/featured_ticket': const [ExperienceTheme.urbanHeritage],
          },
        ),
        const ArtPackContent(
          pack: okinawa,
          assets: [],
          common: {'featured_ticket': FileArtImage('/packs/region_jp_okinawa/1/common/featured_ticket.png')},
          sizes: {'common/featured_ticket': (width: 1774, height: 887)},
        ),
      ]);
      final context = trip(
        ExperienceTheme.coastalResort,
        packs: const {'country_jp': ArtRank.country, 'region_jp_okinawa': ArtRank.region},
      );
      expect(ShellResolver(catalog).shell(ShellRole.featuredTicket, context)!.art.pack?.id, 'region_jp_okinawa');
    });
  });

  group('destination pictures drawn for particular looks', () {
    ArtAsset picture(String group, ExperienceTheme? theme) => ArtAsset(
      image: FileArtImage('/packs/country_jp/1/transport/$group.png'),
      kind: BookingKind.transport,
      theme: theme,
      subject: 'train',
      group: group,
      pack: japan,
    );
    final train = Booking(
      id: 'bullet',
      tripId: 't',
      kind: BookingKind.transport,
      title: 'Tokyo to Kyoto train',
      startDate: d(4, 8),
      createdAt: DateTime(2027),
      updatedAt: DateTime(2027),
    );

    test('used for trips with that look, not for others in the same country', () {
      final catalog = bundled.withPacks([
        japanPack(assets: [picture('urban_heritage_train_01', ExperienceTheme.urbanHeritage)]),
      ]);
      final resolver = ArtResolver(catalog);
      expect(resolver.resolve(train, trip(ExperienceTheme.urbanHeritage)).key, 'country_jp:urban_heritage_train_01');
      expect(resolver.resolve(train, trip(ExperienceTheme.coastalResort)).asset?.isBundled, isTrue);
    });

    test('pictures marked any suit every trip there', () {
      final catalog = bundled.withPacks([
        japanPack(assets: [picture('any_train_01', null)]),
      ]);
      expect(ArtResolver(catalog).resolve(train, trip(ExperienceTheme.coastalResort)).key, 'country_jp:any_train_01');
    });
  });

  group('pack.json themes on shared art', () {
    Map<String, Object?> manifest(Map<String, Object?> asset) => {
      'schemaVersion': 1,
      'packId': 'country_jp',
      'version': 1,
      'assets': [
        {
          'file': 'common/featured_ticket.png',
          'kind': 'common',
          'name': 'featured_ticket',
          'width': 1774,
          'height': 887,
          ...asset,
        },
      ],
    };
    PackSharedArt parse(Map<String, Object?> asset) =>
        PackManifest.parse(utf8.encode(jsonEncode(manifest(asset)))).assets.single as PackSharedArt;

    test('are optional, validated and written back out', () {
      expect(parse({}).themes, isEmpty);
      final themed = parse({
        'themes': ['urban_heritage', 'classic_travel', 'urban_heritage'],
      });
      expect(themed.themes, [ExperienceTheme.urbanHeritage, ExperienceTheme.classicTravel]);
      expect(themed.toJson()['themes'], ['urban_heritage', 'classic_travel']);
      expect(parse({}).toJson().containsKey('themes'), isFalse);
    });

    test('an unknown look or an empty list rejects the pack', () {
      expect(
        () => parse({
          'themes': ['kyoto'],
        }),
        throwsA(isA<ArtPackFormatException>()),
      );
      expect(() => parse({'themes': <String>[]}), throwsA(isA<ArtPackFormatException>()));
      expect(() => parse({'themes': 'urban_heritage'}), throwsA(isA<ArtPackFormatException>()));
    });
  });
}
