import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/countdown_widget_bridge.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/countdown_widget_setup.dart';
import 'package:travary/state/countdown_widget_sync.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/canonical_today.dart';

/// A folder in a temporary directory, counting the redraws asked for.
class _FakeBridge implements CountdownWidgetBridge {
  _FakeBridge(this.root);

  final Directory root;
  int reloads = 0;

  @override
  Future<CountdownWidgetFolder?> folder() async => CountdownWidgetFolder(root);

  @override
  Future<void> reload() async => reloads++;

  @override
  Future<HomeWidgetStatus> status() async => homeWidgetUnavailable;

  @override
  Future<bool> requestPin() async => false;
}

void main() {
  late Directory root;
  late _FakeBridge bridge;
  late MemoryTravelRepository repository;
  late TravelStore travel;
  late CountdownWidgetSync sync;

  Map<String, Object?> written() =>
      jsonDecode(File('${root.path}/countdown.json').readAsStringSync()) as Map<String, Object?>;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('countdown_widget');
    bridge = _FakeBridge(root);
    repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [trip('lakes', title: 'Lake District', plannedStart: d(11, 25), plannedEnd: d(11, 28))],
        [booking('cottage', BookingKind.stay, d(11, 25), tripId: 'lakes')],
      );
    travel = TravelStore(
      repository: repository,
      artCatalog: bundledArtCatalog(),
      clock: () => DateTime(2026, 11, 20, 9),
    );
    await pumpEventQueue();
    sync = CountdownWidgetSync(
      bridge: bridge,
      travel: travel,
      // The bundled files, read from the project as the app reads its bundle.
      loadAsset: (key) async => ByteData.sublistView(File(key).readAsBytesSync()),
    );
  });

  tearDown(() {
    sync.dispose();
    travel.dispose();
    root.deleteSync(recursive: true);
  });

  test('writes every day ahead with the art, Travi and fonts it names, then redraws', () async {
    await sync.publish();
    final json = written();
    final days = json['days']! as Map<String, Object?>;
    expect(days.keys.first, '2026-11-20');
    expect(days.keys.last, '2026-11-28');
    expect(days['2026-11-20'], containsPair('days', '5'));

    final art = (json['trips']! as Map)['lakes'] as Map<String, Object?>;
    // No verified place: the neutral postcards, on Travary's own tag and linen.
    for (final key in ['portrait', 'landscape', 'tag', 'linen']) {
      expect(File('${root.path}/${art[key]}').existsSync(), isTrue, reason: key);
    }
    expect(art['portrait'], endsWith('.webp'));
    final travi = json['travi']! as Map<String, Object?>;
    expect(travi.keys, containsAll(['ready', 'today', 'wave']));
    final fonts = json['fonts']! as Map<String, Object?>;
    expect(fonts.keys, ['serif', 'sans', 'sansMedium']);
    for (final name in fonts.values) {
      expect(File('${root.path}/$name').existsSync(), isTrue);
    }
    expect(bridge.reloads, 1);
  });

  test('the same trips write nothing again; a change rewrites and tidies up', () async {
    await sync.publish();
    final before = File('${root.path}/countdown.json').lastModifiedSync();
    await sync.publish();
    expect(bridge.reloads, 1);
    expect(File('${root.path}/countdown.json').lastModifiedSync(), before);

    // The trip is gone: the widget goes idle, and nothing names Travi's
    // other moods any more.
    repository.replaceAll(const [], const []);
    await pumpEventQueue();
    await sync.publish();
    expect(bridge.reloads, 2);
    final json = written();
    expect(json['days'], isEmpty);
    expect((json['idle']! as Map)['title'], 'Where to next?');
    expect((json['travi']! as Map).keys, ['wave']);
    expect(Directory('${root.path}/travi').listSync(), hasLength(1));
  });

  test('"Preview a different time" never reaches the home screen', () async {
    travel.previewNow = DateTime(2027, 1, 1);
    await sync.publish();
    expect(File('${root.path}/countdown.json').existsSync(), isFalse);
    expect(bridge.reloads, 0);
  });
}
