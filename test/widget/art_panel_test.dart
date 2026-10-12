import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:travary/data/art_pack_service.dart';
import 'package:travary/data/art_pack_store.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_resolver.dart';
import 'package:travary/design/cards/card_parts.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/art_pack_fixtures.dart';

/// Alternates real time (file I/O) and frames (stream events, image
/// callbacks) until [done], as widget tests need both.
Future<void> until(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  }
  await tester.pump();
}

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  ArtChoice choice(ArtImageRef image, {ArtFormat? format = ArtFormat.scene}) {
    final asset = ArtAsset(
      image: image,
      kind: BookingKind.dining,
      theme: null,
      subject: 'generic',
      group: 'g',
      format: format,
    );
    return ArtChoice(
      kind: BookingKind.dining,
      theme: ExperienceTheme.classicTravel,
      variant: 3,
      scene: format == ArtFormat.vignette ? null : asset,
      vignette: format == ArtFormat.vignette ? asset : null,
    );
  }

  Future<void> pumpPanel(WidgetTester tester, ArtChoice art, {ArtFormat format = ArtFormat.scene}) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 200,
          height: 120,
          child: ArtPanel(art: art, format: format),
        ),
      ),
    ),
  );

  testWidgets('bundled and downloaded pictures draw the same way', (tester) async {
    await pumpPanel(tester, choice(const BundledArtImage('assets/art/icons/dining.png')));
    final bundled = tester.widget<Image>(find.byType(Image));
    expect(bundled.image, isA<AssetImage>().having((i) => i.assetName, 'asset', 'assets/art/icons/dining.png'));

    await pumpPanel(tester, choice(const FileArtImage('/packs/theme/1/dining/g.png')));
    final downloaded = tester.widget<Image>(find.byType(Image));
    expect(downloaded.image, isA<FileImage>().having((i) => i.file.path, 'file', '/packs/theme/1/dining/g.png'));
    expect((downloaded.fit, downloaded.alignment), (bundled.fit, bundled.alignment));
    expect(downloaded.fit, BoxFit.cover);

    await pumpPanel(
      tester,
      choice(const FileArtImage('/x.png'), format: ArtFormat.vignette),
      format: ArtFormat.vignette,
    );
    final vignette = tester.widget<Image>(find.byType(Image));
    expect((vignette.fit, vignette.alignment), (BoxFit.contain, Alignment.bottomRight));
    expect(artImageProvider(const BundledArtImage('a.png')), isA<AssetImage>());
    expect(artImageProvider(const FileArtImage('/a.png')), isA<FileImage>());
  });

  testWidgets('a deleted or corrupt pack file shows the placeholder instead of throwing', (tester) async {
    final temp = await tester.runAsync(() => Directory.systemTemp.createTemp('travary_panel'));
    addTearDown(() => temp!.deleteSync(recursive: true));
    final corrupt = File(p.join(temp!.path, 'corrupt.png'));
    await tester.runAsync(() => corrupt.writeAsBytes([0x89, 0x50, 0x4E, 0x47, 1, 2, 3, 4, 5]));

    for (final path in [p.join(temp.path, 'deleted.png'), corrupt.path]) {
      await tester.pumpWidget(const SizedBox());
      await pumpPanel(tester, choice(FileArtImage(path)));
      expect(find.byType(ArtPlaceholder), findsNothing);
      await until(tester, () => find.byType(ArtPlaceholder).evaluate().isNotEmpty);
      expect(find.byType(ArtPlaceholder), findsOneWidget, reason: path);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('no picture at all draws the placeholder', (tester) async {
    await pumpPanel(
      tester,
      const ArtChoice(kind: BookingKind.dining, theme: ExperienceTheme.classicTravel, variant: 1),
    );
    expect(find.byType(ArtPlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('installing or evicting a pack updates visible cards without a restart', (tester) async {
    final temp = (await tester.runAsync(() => Directory.systemTemp.createTemp('travary_live')))!;
    addTearDown(() => temp.deleteSync(recursive: true));
    final root = Directory(p.join(temp.path, 'art-packs'))..createSync();
    final remote = FakeArtPackRemote();
    final built = (await tester.runAsync(
      () => buildTestPack(Directory(p.join(temp.path, 'src')), id: 'theme_themepark'),
    ))!;
    remote.serve(built);
    remote.catalog = catalogBytes([built.entry]);

    final packs = ArtPackManager(store: ArtPackStore.at(root), remote: remote, appBuild: 1, cacheBudgetBytes: 0);
    await tester.runAsync(packs.loadInstalled);

    final repository = MemoryTravelRepository(userId: 'me');
    final orlando = Trip(
      id: 'orlando',
      title: 'Orlando',
      theme: ExperienceTheme.themepark,
      themeSource: ThemeSource.manual,
      ownerId: 'me',
      memberIds: const ['me'],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    repository.replaceAll(
      [orlando],
      [booking('dinner', BookingKind.dining, d(10, 14), tripId: 'orlando', title: 'Sunshine Terrace')],
    );
    var now = DateTime(2026, 10, 14, 9);
    final store = TravelStore(
      repository: repository,
      artCatalog: const ArtCatalog.empty(),
      artPacks: packs,
      clock: () => now,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Consumer<TravelStore>(
            builder: (context, store, _) {
              final dinner = store.booking('dinner');
              if (dinner == null) return const SizedBox();
              return SizedBox(
                width: 120,
                height: 120,
                child: ArtPanel(art: store.artFor(dinner), format: ArtFormat.vignette),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ArtPlaceholder), findsOneWidget, reason: 'nothing installed yet');

    // The catalog arrives; the current trip wants the pack; it installs.
    await tester.runAsync(packs.refreshCatalog);
    // Installation can finish between frames. Wait for the visible render,
    // not just the manager's state, before inspecting its image.
    await until(tester, () => find.byType(Image).evaluate().isNotEmpty);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      image.image,
      isA<FileImage>().having((i) => i.file.path, 'file', contains(p.join('theme_themepark', '1', 'dining'))),
    );

    // Once the trip is over the pack isn't pinned, and the zero budget evicts it.
    now = DateTime(2027, 1, 1);
    await repository.saveBooking(booking('note', BookingKind.note, d(10, 15), tripId: 'orlando', title: 'Pack'));
    await until(tester, () => find.byType(ArtPlaceholder).evaluate().isNotEmpty);
    expect(packs.installed, isEmpty);
    expect(find.byType(ArtPlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    // Within the test body: the store's clock ticker is a (fake) timer.
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    packs.dispose();
  });
}
