// End to end against the Firebase emulators (a demo project; nothing real is
// touched): publish the seed pack into the Storage emulator with the
// publisher, sign in through the Auth emulator, then download, verify,
// install and resolve cards from it exactly as the app does, and again
// offline after a restart.
//
// Run with tool/run_emulator_tests.sh (it starts the emulators).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/data/art_pack_service.dart';
import 'package:travary/data/art_pack_store.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/travel_store.dart';

import '../tool/src/bucket.dart';
import '../tool/src/publisher.dart';

const bucket = 'demo-travary.appspot.com';

/// The app's download path, over the Storage emulator's REST API with a
/// real (emulated) ID token, so storage.rules decide every read.
class EmulatorArtPackRemote implements ArtPackRemote {
  EmulatorArtPackRemote(this.host, {this.idToken});

  final String host;
  final String? idToken;

  Future<Uint8List> _get(String path, int maxBytes) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('http://$host/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media');
      final request = await client.getUrl(uri);
      if (idToken != null) request.headers.set(HttpHeaders.authorizationHeader, 'Firebase $idToken');
      final response = await request.close();
      final bytes = await response.fold<BytesBuilder>(BytesBuilder(), (b, chunk) => b..add(chunk));
      if (response.statusCode == 403) {
        throw const ArtPackRemoteException('Not allowed (unauthorized).', transient: false);
      }
      if (response.statusCode == 404) {
        throw const ArtPackRemoteException('Not found (object-not-found).', transient: false);
      }
      if (response.statusCode != 200) throw ArtPackRemoteException('HTTP ${response.statusCode}', transient: true);
      if (bytes.length > maxBytes) throw const ArtPackFormatException('Too big.');
      return bytes.takeBytes();
    } finally {
      client.close();
    }
  }

  @override
  Future<Uint8List> fetchCatalog({required int maxBytes}) => _get(artPackCatalogPath, maxBytes);

  @override
  Future<void> downloadArchive(String storagePath, File target) async {
    final bytes = await _get(storagePath, ArtPackLimits.maxCompressedBytes);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);
  }

  @override
  void cancelAll() {}
}

class OfflineRemote implements ArtPackRemote {
  @override
  Future<Uint8List> fetchCatalog({required int maxBytes}) =>
      throw const ArtPackRemoteException('Offline.', transient: true);

  @override
  Future<void> downloadArchive(String storagePath, File target) =>
      throw const ArtPackRemoteException('Offline.', transient: true);

  @override
  void cancelAll() {}
}

Future<String> anonymousIdToken(String authHost) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('http://$authHost/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'returnSecureToken': true}));
    final response = await request.close();
    final body = jsonDecode(await response.transform(utf8.decoder).join()) as Map<String, Object?>;
    return body['idToken']! as String;
  } finally {
    client.close();
  }
}

Future<void> waitFor(bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

void main() {
  final storageHost = Platform.environment['FIREBASE_STORAGE_EMULATOR_HOST'];
  final authHost = Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'];

  test('a published pack downloads, verifies, installs and draws cards, then works offline', () async {
    expect(storageHost, isNotNull, reason: 'Run through tool/run_emulator_tests.sh (Storage emulator).');
    expect(authHost, isNotNull, reason: 'Run through tool/run_emulator_tests.sh (Auth emulator).');
    final temp = await Directory.systemTemp.createTemp('travary_e2e');
    addTearDown(() => temp.delete(recursive: true));

    // 1. Publish the seed pack with the real tool.
    final catalogFile = File(p.join(temp.path, 'catalog.json'));
    final out = Directory(p.join(temp.path, 'out'));
    await buildAndRecord(
      source: Directory('art_packs/sources/seed_themepark'),
      catalogFile: catalogFile,
      outDir: out,
      dryRun: false,
      now: DateTime.now(),
      log: (_) {},
    );
    await publishArtPacks(
      catalogFile: catalogFile,
      outDir: out,
      bucket: EmulatorBucket(host: storageHost!, bucket: bucket),
      dryRun: false,
      log: (_) {},
    );

    // 2. Signed out, the rules refuse; signed in, they allow.
    await expectLater(
      EmulatorArtPackRemote(storageHost).fetchCatalog(maxBytes: ArtPackLimits.maxCatalogBytes),
      throwsA(isA<ArtPackRemoteException>().having((e) => e.message, 'message', contains('unauthorized'))),
    );
    final remote = EmulatorArtPackRemote(storageHost, idToken: await anonymousIdToken(authHost!));

    // 3. The app: a theme-park trip happening now, a manager, a store.
    final root = Directory(p.join(temp.path, 'art-packs'))..createSync();
    final packs = ArtPackManager(store: ArtPackStore.at(root), remote: remote, appBuild: 1);
    addTearDown(packs.dispose);
    await packs.loadInstalled();
    final now = DateTime.now();
    final today = LocalDate.fromDateTime(now);
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [
          Trip(
            id: 'orlando',
            title: 'Orlando',
            theme: ExperienceTheme.themepark,
            themeSource: ThemeSource.manual,
            ownerId: 'me',
            memberIds: const ['me'],
            createdAt: now,
            updatedAt: now,
          ),
        ],
        [
          Booking(
            id: 'dinner',
            tripId: 'orlando',
            kind: BookingKind.dining,
            title: 'Sunshine Terrace',
            startDate: today,
            createdAt: now,
            updatedAt: now,
          ),
          Booking(
            id: 'flight',
            tripId: 'orlando',
            kind: BookingKind.flight,
            title: 'London to Orlando',
            artSubject: 'plane',
            startDate: today,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
    final store = TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), artPacks: packs);
    addTearDown(store.dispose);
    await pumpEventQueue();

    expect(await packs.refreshCatalog(), isTrue);
    await waitFor(() => packs.installed.isNotEmpty);
    final installed = packs.installed.single;
    expect(installed.id, 'seed_themepark');
    expect(installed.directory.path, p.join(root.path, 'packs', 'seed_themepark', '1'));

    // 4. Cards resolve to the installed files.
    await waitFor(() => store.artFor(store.booking('dinner')!).vignette?.image is FileArtImage);
    final dinner = store.artFor(store.booking('dinner')!);
    expect(dinner.key, 'seed_themepark:themepark_generic_01');
    expect(dinner.vignette!.image.path, installed.file('dining/themepark_generic_01_vignette.png').path);
    expect(File(dinner.vignette!.image.path).existsSync(), isTrue);
    final flight = store.artFor(store.booking('flight')!);
    expect(flight.subject, 'plane');
    expect(flight.key, 'seed_themepark:themepark_plane_01');

    // 5. Restart offline: the pack loads from disk and the card is the same.
    final offline = ArtPackManager(store: ArtPackStore.at(root), remote: OfflineRemote(), appBuild: 1);
    addTearDown(offline.dispose);
    await offline.loadInstalled();
    expect(await offline.refreshCatalog(), isFalse);
    final offlineStore = TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), artPacks: offline);
    addTearDown(offlineStore.dispose);
    await pumpEventQueue();
    expect(offline.catalog!.packs.single.id, 'seed_themepark', reason: 'the saved catalog');
    expect(offlineStore.artFor(offlineStore.booking('dinner')!).key, 'seed_themepark:themepark_generic_01');
  });
}
