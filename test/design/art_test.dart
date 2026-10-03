import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_resolver.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';
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
      expect(old.theme, ExperienceTheme.coastalResort, reason: 'legacy prefixes still load');
      expect(old.subject, genericSubject);
      expect(old.format, isNull);

      final bare = catalog.allFor(BookingKind.stay).single;
      expect(bare.theme, ExperienceTheme.classicTravel);
      expect(bare.subject, genericSubject);
    });

    test('finds shared textures and icons', () {
      expect(catalog.common('linen'), const BundledArtImage('assets/art/common/linen.png'));
      expect(catalog.icon('dining'), const BundledArtImage('assets/art/icons/dining.png'));
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
      final choice = resolver(
        catalog,
      ).resolve(dining('a', 'Harbour Pizza Co.'), TripArtContext.forTheme(ExperienceTheme.coastalResort));
      expect(choice.subject, 'pizza');
      expect(choice.group, 'tropical_pizza_01');
    });

    test('then a theme-free picture of the subject, pairing scene and vignette', () {
      final choice = resolver(
        catalog,
      ).resolve(dining('a', 'Harbour Pizza Co.'), TripArtContext.forTheme(ExperienceTheme.urbanModern));
      expect(choice.group, 'any_pizza_01');
      expect(choice.scene?.path, 'assets/art/dining/any_pizza_01_scene.png');
      expect(choice.vignette?.path, 'assets/art/dining/any_pizza_01_vignette.png');
      expect(choice.preferring(ArtFormat.vignette)?.format, ArtFormat.vignette);
    });

    test('a subject chosen by Smart Import beats keywords', () {
      final choice = resolver(
        catalog,
      ).resolve(dining('a', 'Ohana', artSubject: 'grill'), TripArtContext.forTheme(ExperienceTheme.coastalResort));
      expect(choice.group, 'tropical_grill_01');
      // The grill is drawn only as a scene: normal cards get the best
      // vignette by the same rules (the look's generic), not the scene.
      expect(choice.vignette?.group, 'tropical_01');
      expect(choice.preferring(ArtFormat.vignette)?.group, 'tropical_01');
    });

    test('a picture in one format only stands in for the other when nothing else comes in it', () {
      final booking = Booking(
        id: 'p',
        tripId: 't',
        kind: BookingKind.attraction,
        title: 'Sunshine Park',
        startDate: d(10, 14),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final choice = resolver(catalog).resolve(booking, TripArtContext.forTheme(ExperienceTheme.themepark));
      expect(choice.vignette, isNull);
      expect(choice.preferring(ArtFormat.vignette)?.path, 'assets/art/attraction/themepark_castle_01_scene.png');
    });

    test('with no subject match, a generic picture for the theme', () {
      final choice = resolver(
        catalog,
      ).resolve(dining('a', 'Sunshine Terrace'), TripArtContext.forTheme(ExperienceTheme.coastalResort));
      expect(choice.subject, isNull);
      expect(choice.group, 'tropical_01');
    });

    test('anything for the theme beats a generic from elsewhere', () {
      final booking = Booking(
        id: 'p',
        tripId: 't',
        kind: BookingKind.attraction,
        title: 'Sunshine Park',
        startDate: d(10, 14),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(
        resolver(catalog).resolve(booking, TripArtContext.forTheme(ExperienceTheme.themepark)).group,
        'themepark_castle_01',
      );
    });

    test('is stable and honours a picked picture', () {
      final b = dining('abc', 'Sunshine Terrace');
      expect(
        resolver(catalog).resolve(b, TripArtContext.forTheme(ExperienceTheme.urbanModern)).group,
        resolver(catalog).resolve(b, TripArtContext.forTheme(ExperienceTheme.urbanModern)).group,
      );
      final picked = b.copyWith(artKey: 'any_pizza_01');
      expect(
        resolver(catalog).resolve(picked, TripArtContext.forTheme(ExperienceTheme.urbanModern)).group,
        'any_pizza_01',
      );
    });

    test('never shows the same picture twice in a row', () {
      final bookings = [for (var i = 0; i < 12; i++) dining('b$i', 'Sunshine Terrace')];
      final choices = resolver(
        catalog,
      ).resolveAll(bookings, (_) => TripArtContext.forTheme(ExperienceTheme.urbanModern));
      for (var i = 1; i < choices.length; i++) {
        expect(choices[i].group, isNot(choices[i - 1].group));
      }
    });

    test('placeholders also differ side by side', () {
      final bookings = [for (var i = 0; i < 12; i++) booking('b$i', BookingKind.flight, d(10, 14))];
      final choices = const ArtResolver(
        ArtCatalog.empty(),
      ).resolveAll(bookings, (_) => TripArtContext.forTheme(ExperienceTheme.classicTravel));
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
      expect(
        subject(BookingKind.transport, 'London to Windermere', details: {DetailKeys.company: 'Avanti West Coast'}),
        'train',
      );
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

  packTests();

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

// ------------------------------------------------------------ art packs

ArtPackRef _pack(String id, ArtPackSelectors selectors, {int priority = 100}) =>
    ArtPackRef(id: id, version: 1, priority: priority, selectors: selectors);

ArtAsset _packAsset(
  ArtPackRef pack,
  String group, {
  String subject = genericSubject,
  ExperienceTheme? theme,
  ArtFormat? format,
}) => ArtAsset(
  image: FileArtImage('/packs/${pack.id}/1/dining/$group.png'),
  kind: BookingKind.dining,
  theme: theme,
  subject: subject,
  group: group,
  format: format,
  pack: pack,
);

void packTests() {
  final city = _pack('city_jp_kyoto', const ArtPackSelectors(countryCodes: ['JP'], cities: ['kyoto']));
  final region = _pack('region_jp_kansai', const ArtPackSelectors(countryCodes: ['JP'], regions: ['kansai']));
  final country = _pack('country_jp', const ArtPackSelectors(countryCodes: ['JP']));
  final primary = _pack('theme_heritage', const ArtPackSelectors(themes: [ExperienceTheme.urbanHeritage]));
  final secondary = _pack('theme_modern', const ArtPackSelectors(themes: [ExperienceTheme.urbanModern]));
  final elsewhere = _pack('city_fr_paris', const ArtPackSelectors(countryCodes: ['FR'], cities: ['paris']));

  // Every source has a pizza and a generic picture.
  final bundled = ArtCatalog.fromAssetPaths([
    'assets/art/dining/urban_heritage_pizza_01.png',
    'assets/art/dining/urban_heritage_01.png',
    'assets/art/dining/urban_modern_pizza_01.png',
    'assets/art/dining/any_pizza_01.png',
    'assets/art/dining/classic_travel_generic_01.png',
    'assets/art/dining/alpine_pizza_01.png',
  ]);
  ArtPackContent content(ArtPackRef pack) => ArtPackContent(
    pack: pack,
    assets: [
      _packAsset(pack, '${pack.id}_pizza', subject: 'pizza'),
      _packAsset(pack, '${pack.id}_generic'),
    ],
  );
  final everything = bundled.withPacks([
    for (final pack in [city, region, country, primary, secondary, elsewhere]) content(pack),
  ]);

  Booking dining(String id, String title) => Booking(
    id: id,
    tripId: 't',
    kind: BookingKind.dining,
    title: title,
    startDate: d(4, 5),
    createdAt: DateTime(2027),
    updatedAt: DateTime(2027),
  );
  final pizza = dining('p', 'Pizzeria Kyoto');
  final plain = dining('g', 'Sunshine Terrace');

  TripArtContext kyoto({Set<String>? packs, List<ArtRank> order = TripArtContext.standardRankOrder}) => TripArtContext(
    theme: ExperienceTheme.urbanHeritage,
    secondaryThemes: const [ExperienceTheme.urbanModern],
    packRanks: {
      for (final entry in {
        'city_jp_kyoto': ArtRank.city,
        'region_jp_kansai': ArtRank.region,
        'country_jp': ArtRank.country,
        'theme_heritage': ArtRank.primary,
        'theme_modern': ArtRank.secondary,
      }.entries)
        if (packs == null || packs.contains(entry.key)) entry.key: entry.value,
    },
    rankOrder: order,
  );

  group('resolver priority with art packs', () {
    String? pick(Booking booking, TripArtContext context, [ArtCatalog? catalog]) =>
        ArtResolver(catalog ?? everything).resolve(booking, context).key;

    test('city, region, country, look, secondary look, then core, each with the subject', () {
      expect(pick(pizza, kyoto()), 'city_jp_kyoto:city_jp_kyoto_pizza');
      expect(
        pick(pizza, kyoto(packs: {'region_jp_kansai', 'country_jp', 'theme_heritage', 'theme_modern'})),
        'region_jp_kansai:region_jp_kansai_pizza',
      );
      expect(
        pick(pizza, kyoto(packs: {'country_jp', 'theme_heritage', 'theme_modern'})),
        'country_jp:country_jp_pizza',
      );
      // The look: its pack and bundled art for it, together.
      expect(
        pick(pizza, kyoto(packs: {'theme_heritage', 'theme_modern'})),
        anyOf('theme_heritage:theme_heritage_pizza', 'urban_heritage_pizza_01'),
      );
      expect(pick(pizza, kyoto(packs: {'theme_modern'})), 'urban_heritage_pizza_01');
      final withoutHeritage = ArtCatalog.fromAssetPaths([
        'assets/art/dining/urban_modern_pizza_01.png',
        'assets/art/dining/any_pizza_01.png',
      ]).withPacks([content(secondary)]);
      expect(
        pick(pizza, kyoto(packs: {'theme_modern'}), withoutHeritage),
        anyOf('theme_modern:theme_modern_pizza', 'urban_modern_pizza_01'),
      );
      expect(
        pick(
          pizza,
          kyoto(packs: const {}),
          ArtCatalog.fromAssetPaths(['assets/art/dining/any_pizza_01.png', 'assets/art/dining/alpine_pizza_01.png']),
        ),
        'any_pizza_01',
        reason: 'core before another look',
      );
    });

    test('without a subject: destination generics, the look\'s generic, then classic generic', () {
      expect(pick(plain, kyoto()), 'city_jp_kyoto:city_jp_kyoto_generic');
      expect(
        pick(plain, kyoto(packs: {'theme_heritage'})),
        anyOf('theme_heritage:theme_heritage_generic', 'urban_heritage_01'),
      );
      expect(
        pick(
          plain,
          kyoto(packs: const {}),
          ArtCatalog.fromAssetPaths([
            'assets/art/dining/classic_travel_generic_01.png',
            'assets/art/dining/alpine_pizza_01.png',
          ]),
        ),
        'classic_travel_generic_01',
      );
    });

    test('an unverified destination\'s country art comes after the look\'s', () {
      final context = kyoto(packs: {'country_jp', 'theme_heritage'}, order: TripArtContext.experienceFirstRankOrder);
      final choice = pick(pizza, context);
      expect(choice, anyOf('theme_heritage:theme_heritage_pizza', 'urban_heritage_pizza_01'));
    });

    test('another destination\'s pack is never used', () {
      final onlyParis = ArtCatalog.fromAssetPaths(const []).withPacks([content(elsewhere)]);
      expect(pick(pizza, kyoto(), onlyParis), isNull);
      expect(pick(plain, kyoto(), onlyParis), isNull);
    });

    test('a picked picture wins, keyed uniquely across packs', () {
      final picked = pizza.copyWith(artKey: 'country_jp:country_jp_generic');
      expect(pick(picked, kyoto()), 'country_jp:country_jp_generic');
      final twins = ArtCatalog.fromAssetPaths(const []).withPacks([
        ArtPackContent(pack: city, assets: [_packAsset(city, 'shared_group')]),
        ArtPackContent(pack: country, assets: [_packAsset(country, 'shared_group')]),
      ]);
      expect(twins.byKey(BookingKind.dining, 'city_jp_kyoto:shared_group').single.pack, city);
      expect(twins.byKey(BookingKind.dining, 'country_jp:shared_group').single.pack, country);
    });

    test('is deterministic and avoids the same picture side by side', () {
      final many = ArtCatalog.fromAssetPaths(const []).withPacks([
        ArtPackContent(pack: primary, assets: [for (var i = 0; i < 3; i++) _packAsset(primary, 'generic_0$i')]),
      ]);
      final bookings = [for (var i = 0; i < 12; i++) dining('b$i', 'Sunshine Terrace')];
      final context = kyoto(packs: {'theme_heritage'});
      final first = ArtResolver(many).resolveAll(bookings, (_) => context).map((c) => c.key).toList();
      final second = ArtResolver(many).resolveAll(bookings, (_) => context).map((c) => c.key).toList();
      expect(first, second);
      for (var i = 1; i < first.length; i++) {
        expect(first[i], isNot(first[i - 1]));
      }
    });

    test('downloaded and bundled pictures follow identical rules', () {
      // The same four pictures, once bundled and once as a pack for the look.
      final names = [
        'urban_heritage_pizza_01',
        'urban_heritage_pizza_02',
        'urban_heritage_generic_01',
        'any_generic_01',
      ];
      final asBundled = ArtCatalog.fromAssetPaths([for (final n in names) 'assets/art/dining/$n.png']);
      final asPack = ArtCatalog.fromAssetPaths(const []).withPacks([
        ArtPackContent(
          pack: primary,
          assets: [
            for (final n in names)
              _packAsset(
                primary,
                n,
                subject: n.contains('pizza') ? 'pizza' : genericSubject,
                theme: n.startsWith('any') ? null : ExperienceTheme.urbanHeritage,
              ),
          ],
        ),
      ]);
      final context = kyoto(packs: {'theme_heritage'});
      for (final booking in [for (var i = 0; i < 20; i++) dining('x$i', i.isEven ? 'Pizzeria' : 'Sunshine Terrace')]) {
        final bundledChoice = ArtResolver(asBundled).resolve(booking, context);
        final packChoice = ArtResolver(asPack).resolve(booking, context);
        expect(packChoice.group, bundledChoice.group, reason: booking.title);
        expect(bundledChoice.asset!.image, isA<BundledArtImage>());
        expect(packChoice.asset!.image, isA<FileArtImage>());
      }
    });

    test('shared art from a suitable pack wins over the bundled copy', () {
      final withIcons = ArtCatalog.fromAssetPaths(['assets/art/icons/dining.png']).withPacks([
        ArtPackContent(
          pack: country,
          assets: const [],
          icons: {'dining': const FileArtImage('/packs/country_jp/1/icons/dining.png')},
        ),
        ArtPackContent(
          pack: city,
          assets: const [],
          icons: {'dining': const FileArtImage('/packs/city_jp_kyoto/1/icons/dining.png')},
        ),
      ]);
      expect(withIcons.icon('dining'), const BundledArtImage('assets/art/icons/dining.png'));
      expect(withIcons.icon('dining', context: kyoto()), const FileArtImage('/packs/city_jp_kyoto/1/icons/dining.png'));
      expect(
        withIcons.icon('dining', context: kyoto(packs: const {})),
        const BundledArtImage('assets/art/icons/dining.png'),
      );
      expect(withIcons.common('linen', context: kyoto()), isNull);
    });
  });

  group('bundled file names', () {
    test('recognise current and legacy theme prefixes', () {
      final catalog = ArtCatalog.fromAssetPaths([
        'assets/art/transport/urban_heritage_train_01_scene.png',
        'assets/art/transport/classic_travel_generic_01.png',
        'assets/art/transport/wellness_retreat_01.png',
        'assets/art/transport/snow_train_01.png',
        'assets/art/transport/city_bus_01.png',
        'assets/art/activity/any_citytour_01.png',
      ]);
      final byGroup = {
        for (final a in [...catalog.allFor(BookingKind.transport), ...catalog.allFor(BookingKind.activity)]) a.group: a,
      };
      expect(
        (byGroup['urban_heritage_train_01']!.theme, byGroup['urban_heritage_train_01']!.subject),
        (ExperienceTheme.urbanHeritage, 'train'),
      );
      expect(byGroup['urban_heritage_train_01']!.format, ArtFormat.scene);
      expect(
        (byGroup['classic_travel_generic_01']!.theme, byGroup['classic_travel_generic_01']!.subject),
        (ExperienceTheme.classicTravel, genericSubject),
      );
      expect(byGroup['wellness_retreat_01']!.theme, ExperienceTheme.wellnessRetreat);
      expect((byGroup['snow_train_01']!.theme, byGroup['snow_train_01']!.subject), (ExperienceTheme.alpine, 'train'));
      expect((byGroup['city_bus_01']!.theme, byGroup['city_bus_01']!.subject), (ExperienceTheme.urbanModern, 'bus'));
      expect((byGroup['any_citytour_01']!.theme, byGroup['any_citytour_01']!.subject), (null, 'citytour'));
      expect(
        byGroup.values.every((a) => a.isBundled && a.key == a.group),
        isTrue,
        reason: 'bundled keys stay as they were',
      );
    });
  });
}
