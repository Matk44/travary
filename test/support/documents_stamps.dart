import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/data/art_pack_store.dart';
import 'package:travary/data/demo_data.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/art_catalog_controller.dart';

import 'canonical_today.dart';
import 'countdown_today.dart';

/// The Documents mockup's moment
/// (docs/mockups/documents-themed-v2/02-collectible-scenic-stamps.png):
/// 28 September 2026, day 3 of the demo's Orlando trip.
final documentsNow = DateTime(2026, 9, 28, 8, 0);

/// Two months on: day 2 of the demo's Lake District trip, a different
/// destination with its own stamp.
final lakesNow = DateTime(2026, 11, 26, 8, 0);

/// The demo trips as the app ships them, built around [documentsNow] (so
/// Orlando is on day 3 then, and the Lake District starts 58 days later).
({List<Trip> trips, List<Booking> bookings}) documentsData() =>
    buildDemoData(LocalDate.fromDateTime(documentsNow), userId: 'me');

/// The mockup's seven "Coming up" documents, in order, with the scene each
/// one shows.
const documentScenes = <(String, String)>[
  ('Car hire', 'assets/art/transport/any_car_01_scene.png'),
  ('Lagoon Resort', 'assets/art/stay/tropical_resort_01_scene.png'),
  ('Sunshine Park', 'assets/art/attraction/themepark_castle_01_scene.png'),
  ('Sunshine Terrace', 'assets/art/dining/themepark_castle_01_scene.png'),
  ('Lagoon Grill', 'assets/art/dining/themepark_grill_01_scene.png'),
  ('Fireworks from the beach', 'assets/art/note/themepark_generic_01_scene.png'),
  ('Everglades airboat tour', 'assets/art/activity/themepark_boat_01_scene.png'),
];

/// The destination packs that carry a Documents stamp.
const stampPackIds = ['city_us_orlando', 'region_gb_lake_district', 'city_jp_kyoto', 'city_fr_paris', 'region_id_bali'];

/// A pack source from `art_packs/sources/`, loaded exactly as the app
/// loads an installed pack.
ArtPackContent sourcePack(String id) {
  final directory = Directory(p.join('art_packs', 'sources', id));
  final entry =
      jsonDecode(File(p.join(directory.path, 'catalog-entry.json')).readAsStringSync()) as Map<String, Object?>;
  final manifest = PackManifest.parse(File(p.join(directory.path, artPackManifestName)).readAsBytesSync());
  return artPackContentOf(
    InstalledArtPack(
      ref: ArtPackRef(
        id: id,
        version: manifest.version,
        priority: entry['priority']! as int,
        selectors: parseArtPackSelectors(entry['selectors'], packId: id),
      ),
      directory: directory,
      manifest: manifest,
      sha256: '',
      files: const {},
      installedAt: DateTime(2026),
      lastUsedAt: DateTime(2026),
    ),
  );
}

/// The bundled art plus every destination pack with a stamp, as if all
/// were installed.
ArtCatalog catalogWithStamps() => bundledArtCatalog().withPacks([for (final id in stampPackIds) sourcePack(id)]);

/// The app at [now] (default [documentsNow]) with the demo data and
/// [catalog] (default: bundled art only); open the Documents tab to see
/// the stamps.
Widget documentsApp({ArtCatalog? catalog, ({List<Trip> trips, List<Booking> bookings})? data, DateTime? now}) =>
    countdownTodayApp(catalog: catalog ?? bundledArtCatalog(), data: data ?? documentsData(), now: now ?? documentsNow);

/// Decodes every picture on screen for real (images never finish loading
/// under the test clock), so the next build finds them in the image cache.
Future<void> decodePictures(WidgetTester tester) async {
  final wanted = [
    for (final element in find.byType(Image, skipOffstage: false).evaluate())
      ((element.widget as Image).image, createLocalImageConfiguration(element)),
  ];
  imageCache
    ..clear()
    ..clearLiveImages();
  await tester.runAsync(() async {
    for (final (provider, configuration) in wanted) {
      final done = Completer<void>();
      final stream = provider.resolve(configuration);
      final listener = ImageStreamListener(
        (image, synchronousCall) => done.isCompleted ? null : done.complete(),
        onError: (error, stackTrace) => done.isCompleted ? null : done.complete(),
      );
      stream.addListener(listener);
      await done.future;
      stream.removeListener(listener);
    }
  });
}
