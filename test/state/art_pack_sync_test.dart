import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_service.dart';
import 'package:travary/data/art_pack_store.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/art_pack_fixtures.dart';

/// Trips and bookings arrive only when the test says so (a slow cloud).
class _SlowRepository extends MemoryTravelRepository {
  _SlowRepository() : super(userId: 'me');

  final tripsNow = StreamController<List<Trip>>();
  final bookingsNow = StreamController<List<Booking>>();

  @override
  Stream<List<Trip>> watchTrips() => tripsNow.stream;

  @override
  Stream<List<Booking>> watchBookings() => bookingsNow.stream;
}

void main() {
  test('packs a current trip uses are never evicted before trips have loaded', () async {
    final temp = await Directory.systemTemp.createTemp('travary_sync');
    addTearDown(() => temp.delete(recursive: true));
    final built = await buildTestPack(Directory(p.join(temp.path, 'src')), id: 'theme_themepark');
    final remote = FakeArtPackRemote()
      ..serve(built)
      ..catalog = catalogBytes([built.entry]);
    final packs = ArtPackManager(
      store: ArtPackStore.at(Directory(p.join(temp.path, 'art-packs'))..createSync()),
      remote: remote,
      appBuild: 1,
      cacheBudgetBytes: 0,
    );
    addTearDown(packs.dispose);
    await packs.loadInstalled();
    await packs.install(built.entry);

    final repository = _SlowRepository();
    final store = TravelStore(
      repository: repository,
      artCatalog: const ArtCatalog.empty(),
      artPacks: packs,
      clock: () => DateTime(2026, 10, 14, 9),
    );
    addTearDown(store.dispose);

    // The catalog arrives while the trips are still loading.
    expect(await packs.refreshCatalog(), isTrue);
    await pumpEventQueue();
    expect(packs.installed.single.id, 'theme_themepark', reason: 'nothing may be evicted yet');

    // The trips arrive: a theme-park trip happening now pins the pack.
    repository.tripsNow.add([
      Trip(
        id: 'orlando',
        title: 'Orlando',
        theme: ExperienceTheme.themepark,
        themeSource: ThemeSource.manual,
        ownerId: 'me',
        memberIds: const ['me'],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]);
    repository.bookingsNow.add([booking('dinner', BookingKind.dining, d(10, 14), tripId: 'orlando')]);
    await pumpEventQueue();
    await packs.request(wanted: const [], pinned: {'theme_themepark'}, used: const {});
    expect(packs.installed.single.id, 'theme_themepark');

    // A failed reload doesn't count as "no trips" either.
    repository.tripsNow.addError('Couldn\'t load your trips.');
    await pumpEventQueue();
    expect(packs.installed, hasLength(1));
  });
}
