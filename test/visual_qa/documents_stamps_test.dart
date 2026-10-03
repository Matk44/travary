import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/design/cards/booking_card.dart';
import 'package:travary/design/cards/document_stamp_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/destination_stamp.dart';
import 'package:travary/logic/card_text.dart';
import 'package:travary/logic/day_plan.dart';
import 'package:travary/state/travel_store.dart';

import '../support/documents_stamps.dart';
import '../support/open_tab.dart';

/// The Documents tab on its scenic stamps, rendered at the size of
/// docs/mockups/documents-themed-v2/02-collectible-scenic-stamps.png (851 ×
/// 1848: a 390-point phone), for Orlando (the mockup) and the Lake
/// District (another destination: its own stamp and scenes), and a strip
/// of rows on light and dark backdrops to show any alpha halo.
///
/// Always checks the order and scenes. With `TRAVARY_VISUAL_QA=1` (run by
/// `tool/visual_qa.sh`) it loads the app's real fonts and writes
/// `build/visual_qa/documents_{actual,lakes_actual,halo_light,halo_dark}.png`.
void main() {
  const outDir = 'build/visual_qa';
  final qa = Platform.environment['TRAVARY_VISUAL_QA'] == '1';
  const dpr = 851 / 390;
  final catalog = catalogWithStamps();

  setUpAll(() async {
    TravaryText.useGoogleFonts = false;
    if (qa) await _loadFonts(p.join(outDir, 'fonts'));
  });
  tearDownAll(() {
    TravaryText.serifFamily = null;
    TravaryText.sansFamily = null;
  });

  Future<void> save(WidgetTester tester, GlobalKey boundary, String name) async {
    if (!qa) return;
    final image = await tester.runAsync(() async {
      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return render.toImage(pixelRatio: dpr);
    });
    await tester.runAsync(() async {
      await Directory(outDir).create(recursive: true);
      final png = await image!.toByteData(format: ui.ImageByteFormat.png);
      await File(p.join(outDir, name)).writeAsBytes(png!.buffer.asUint8List());
    });
  }

  Future<GlobalKey> openDocuments(WidgetTester tester, DateTime now) async {
    tester.view.physicalSize = const Size(851, 1848);
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();
    Future<void> open() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: documentsApp(catalog: catalog, now: now),
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'Documents');
    }

    await open();
    await decodePictures(tester);
    await open();
    return boundary;
  }

  testWidgets('Orlando: the coming-up documents on their stamps at the mockup size', (tester) async {
    final boundary = await openDocuments(tester, documentsNow);
    await save(tester, boundary, 'documents_actual.png');

    expect(find.byType(DestinationStamp), findsOneWidget);
    expect(find.text('ORLANDO'), findsOneWidget);
    var previous = tester.getTopLeft(find.text('COMING UP')).dy;
    for (final (title, scene) in documentScenes) {
      final row = find.ancestor(of: find.text(title), matching: find.byType(DocumentStampCard));
      expect(row, findsOneWidget, reason: title);
      final top = tester.getTopLeft(row).dy;
      expect(top, greaterThan(previous), reason: '$title is in date order');
      previous = top;
      final image = tester.widget<Image>(
        find.descendant(of: row, matching: find.byKey(const ValueKey('document-scene'))),
      );
      expect(((image.image as ResizeImage).imageProvider as AssetImage).assetName, scene, reason: title);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Lake District: its own stamp and scenes', (tester) async {
    final boundary = await openDocuments(tester, lakesNow);
    await save(tester, boundary, 'documents_lakes_actual.png');

    expect(find.text('LAKE DISTRICT'), findsOneWidget);
    expect(find.text('ORLANDO'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rows and the destination stamp on light and dark backdrops', (tester) async {
    tester.view.physicalSize = const Size(851, 1100);
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);

    for (final (name, backdrop) in [
      ('documents_halo_light.png', const Color(0xFFF8F4EC)),
      ('documents_halo_dark.png', TravaryColors.ink),
    ]) {
      final boundary = GlobalKey();
      Future<void> pump() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: documentsApp(catalog: catalog, now: documentsNow),
          ),
        );
        await tester.pumpAndSettle();
        final store = tester.element(find.byType(HomeShell)).read<TravelStore>();
        final bookings = [
          for (final (title, _) in documentScenes.take(4)) store.bookings.firstWhere((b) => b.title == title),
        ];
        final stamp = store.destinationStampFor(store.focus.plan!)!;
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTravaryTheme(),
              home: Scaffold(
                backgroundColor: backdrop,
                body: ListView(
                  padding: const EdgeInsets.all(DocumentStampLayout.inset),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: DestinationStamp(image: stamp.art.image, place: stamp.place),
                    ),
                    const SizedBox(height: 16),
                    for (final booking in bookings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: DocumentStampLayout.gap),
                        child: BookingCard(
                          text: cardTextForList(booking),
                          art: store.artFor(booking),
                          size: CardSize.document,
                          status: EntryStatus.upcoming,
                          onTap: () {},
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump();
      await decodePictures(tester);
      await pump();
      await save(tester, boundary, name);
      expect(tester.takeException(), isNull);
    }
  });
}

Future<void> _loadFonts(String dir) async {
  final folder = Directory(dir);
  if (!folder.existsSync()) {
    // ignore: avoid_print
    print('No fonts in $dir: run tool/visual_qa.sh. Rendering with the test font.');
    return;
  }
  final files = folder.listSync().whereType<File>().toList();
  Future<void> load(String family, bool Function(String) matches) async {
    final loader = FontLoader(family);
    var any = false;
    for (final file in files.where((f) => matches(p.basename(f.path)))) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      any = true;
    }
    if (any) await loader.load();
  }

  await load('Source Serif 4', (name) => name.startsWith('SourceSerif4'));
  await load('Inter', (name) => name.startsWith('Inter'));
  await load('MaterialIcons', (name) => name.startsWith('MaterialIcons'));
  TravaryText.serifFamily = 'Source Serif 4';
  TravaryText.sansFamily = 'Inter';
}
