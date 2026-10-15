import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/art/art_resolver.dart';
import 'package:travary/design/art/art_slots.dart';
import 'package:travary/design/art/document_stamps.dart';
import 'package:travary/design/cards/booking_card.dart';
import 'package:travary/design/cards/document_stamp_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/destination_stamp.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/wallet/wallet_screen.dart';
import 'package:travary/logic/art_pack_selection.dart';
import 'package:travary/logic/card_text.dart';
import 'package:travary/logic/day_plan.dart';
import 'package:travary/state/travel_store.dart';

import '../support/canonical_today.dart';
import '../support/documents_stamps.dart';
import '../support/open_tab.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);
  final bundled = bundledArtCatalog();
  final withStamps = catalogWithStamps();
  final boundary = GlobalKey();

  /// The Documents tab at [now] on a phone [width] × [height].
  Future<void> pumpDocuments(
    WidgetTester tester, {
    ArtCatalog? catalog,
    ({List<Trip> trips, List<Booking> bookings})? data,
    DateTime? now,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * 3);
    addTearDown(tester.view.reset);
    // A fresh store (with its clock and catalog) for every app.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: documentsApp(catalog: catalog ?? withStamps, data: data, now: now),
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'Documents');
  }

  /// Draws the screen with every picture decoded, and returns its pixels.
  Future<({ByteData pixels, int width})> capture(WidgetTester tester) async {
    await decodePictures(tester);
    await tester.pump();
    return (await tester.runAsync(() async {
      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      final width = image.width;
      image.dispose();
      return (pixels: pixels, width: width);
    }))!;
  }

  Color pixelAt(({ByteData pixels, int width}) screen, Offset point) {
    final i = ((point.dy * 3).round() * screen.width + (point.dx * 3).round()) * 4;
    final p = screen.pixels;
    return Color.fromARGB(p.getUint8(i + 3), p.getUint8(i), p.getUint8(i + 1), p.getUint8(i + 2));
  }

  double distance(Color a, Color b) => ((a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs()) * 255;

  Finder row(String title) => find.ancestor(of: find.text(title), matching: find.byType(DocumentStampCard));
  Finder inRow(String title, Finder finder) => find.descendant(of: row(title), matching: finder);
  TravelStore storeOf(WidgetTester tester) => tester.element(find.byType(HomeShell)).read<TravelStore>();
  Booking bookingTitled(WidgetTester tester, String title) =>
      storeOf(tester).bookings.firstWhere((b) => b.title == title);
  StampDesign designOf(WidgetTester tester, String title) => StampDesign.values.singleWhere(
    (design) => inRow(title, find.byKey(ValueKey('document-stamp-${design.name}'))).evaluate().isNotEmpty,
  );

  /// The demo data with [title]'s booking replaced by [change]'s copy.
  ({List<Trip> trips, List<Booking> bookings}) changing(String title, Booking Function(Booking) change) {
    final data = documentsData();
    return (trips: data.trips, bookings: [for (final b in data.bookings) b.title == title ? change(b) : b]);
  }

  group('rows', () {
    testWidgets('each booking has one of three stamps, the same one every time', (tester) async {
      Map<String, StampDesign> designs() => {for (final (title, _) in documentScenes) title: designOf(tester, title)};

      // Tall enough for all seven rows.
      await pumpDocuments(tester, height: 1300);
      final first = designs();
      for (final (title, _) in documentScenes) {
        final variant = storeOf(tester).artFor(bookingTitled(tester, title)).variant;
        expect(first[title], StampDesign.forVariant(variant), reason: title);
      }
      expect(first.values.toSet(), hasLength(3), reason: 'the list mixes all three stamps');

      await pumpDocuments(tester, height: 1300);
      expect(designs(), first);
      expect(tester.takeException(), isNull);
    });

    testWidgets('each row stays one button, labelled with its kind, name and date', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpDocuments(tester);
      final node = tester.getSemantics(find.ancestor(of: row('Sunshine Park'), matching: find.byType(Semantics)).first);
      expect(node.label, 'TICKETS, Sunshine Park, 28 Sep');
      expect(node.flagsCollection.isButton, isTrue);
      semantics.dispose();
    });

    testWidgets('each stamp\'s scene is drawn beneath its frame and shows through its window', (tester) async {
      await pumpDocuments(tester, height: 1300);
      // One row per design.
      final byDesign = <StampDesign, String>{};
      for (final (title, _) in documentScenes) {
        byDesign.putIfAbsent(designOf(tester, title), () => title);
      }
      expect(byDesign.keys, containsAll(StampDesign.values));

      for (final MapEntry(key: design, value: title) in byDesign.entries) {
        final stack = tester.widget<Stack>(
          find
              .ancestor(of: inRow(title, find.byKey(const ValueKey('document-scene'))), matching: find.byType(Stack))
              .first,
        );
        int layerOf(Key key) => stack.children.indexWhere(
          (child) => find.descendant(of: find.byWidget(child), matching: find.byKey(key)).evaluate().isNotEmpty,
        );
        expect(
          layerOf(const ValueKey('document-scene')),
          lessThan(layerOf(ValueKey('document-stamp-${design.name}'))),
          reason: '$title (${design.name})',
        );
      }

      final screen = await capture(tester);
      for (final MapEntry(key: design, value: title) in byDesign.entries) {
        final scene = tester.getRect(inRow(title, find.byKey(const ValueKey('document-scene'))));
        // The frame beside the window: the stamp's paper, drawn over the scene.
        final frame = pixelAt(screen, Offset(scene.left - 4.5, scene.center.dy));
        expect(frame.a, 1.0, reason: '${design.name}: the frame is drawn');
        expect([frame.r, frame.g, frame.b].reduce((a, b) => a < b ? a : b), greaterThan(0.6), reason: design.name);
        // Through the window: the scene, not the paper.
        final window = pixelAt(screen, scene.center + Offset(scene.width * 0.1, 0));
        expect(distance(window, frame), greaterThan(60), reason: '${design.name}: the scene shows');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('long titles and details end in an ellipsis', (tester) async {
      const title = 'The Grand Floridian Evening Fireworks Dessert Party on the Lagoon';
      await pumpDocuments(
        tester,
        data: changing(
          'Sunshine Park',
          (b) => Booking(
            id: b.id,
            tripId: b.tripId,
            kind: b.kind,
            title: title,
            startDate: b.startDate,
            startTime: b.startTime,
            reference: 'REFERENCE-0123456789-ABCDEFGHIJ',
            createdAt: b.createdAt,
            updatedAt: b.updatedAt,
          ),
        ),
      );
      final chevron = tester.getRect(inRow(title, find.byIcon(Icons.chevron_right_rounded)));
      for (final text in [title, 'Tickets · REFERENCE-0123456789-ABCDEFGHIJ']) {
        final paragraph = tester.renderObject<RenderParagraph>(inRow(title, find.text(text)));
        expect(paragraph.maxLines, 1, reason: text);
        expect(paragraph.didExceedMaxLines, isTrue, reason: '$text is cut short');
        expect(tester.getRect(inRow(title, find.text(text))).right, lessThanOrEqualTo(chevron.left), reason: text);
      }
      expect(tester.renderObject<RenderParagraph>(inRow('Car hire', find.text('Car hire'))).didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('larger text: rows grow rather than clip', (tester) async {
      for (final scale in [1.3, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await pumpDocuments(tester);
        expect(tester.takeException(), isNull, reason: '$scale');
        final height = tester.getSize(row('Car hire')).height;
        if (scale == 2.0) expect(height, greaterThan(DocumentStampLayout.rowHeight));
      }
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    testWidgets('on the smallest phone the lines go and the art shrinks, without overflow', (tester) async {
      await pumpDocuments(tester, width: 320, height: 568);
      expect(find.byType(DocumentStampCard), findsWidgets);
      expect(find.byKey(const ValueKey('document-cancel-lines')), findsNothing);
      expect(tester.getSize(row('Car hire')).width, closeTo(320 - 2 * DocumentStampLayout.inset, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('past documents fade as before', (tester) async {
      await pumpDocuments(tester);
      double opacityOf(String title) =>
          tester.widget<Opacity>(find.descendant(of: row(title), matching: find.byType(Opacity)).first).opacity;
      expect(opacityOf('Car hire'), 1.0);
      await tester.scrollUntilVisible(
        find.text('London to Orlando'),
        400,
        scrollable: find.descendant(of: find.byType(WalletScreen), matching: find.byType(Scrollable)).first,
      );
      await tester.pumpAndSettle();
      expect(opacityOf('London to Orlando'), 0.55);
    });
  });

  group('missing art', () {
    testWidgets('without a scene the window shows a calm placeholder, never black', (tester) async {
      final noScenes = ArtCatalog.fromAssetPaths(bundledArtPaths().where((path) => !path.endsWith('_scene.webp')));
      await pumpDocuments(tester, catalog: noScenes);
      for (final (title, _) in documentScenes) {
        expect(inRow(title, find.byKey(const ValueKey('document-window-placeholder'))), findsOneWidget, reason: title);
        expect(designOf(tester, title), isNotNull, reason: 'still a stamp');
      }
      final screen = await capture(tester);
      final window = tester.getRect(inRow('Sunshine Park', find.byKey(const ValueKey('document-window-placeholder'))));
      // Away from the placeholder's icon and sun: plain linen.
      final linen = pixelAt(screen, window.topLeft + Offset(window.width * 0.2, window.height * 0.2));
      expect(linen.a, 1.0);
      expect(distance(linen, TravaryColors.linen), lessThan(30));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a scene that can\'t be loaded falls back to the placeholder', (tester) async {
      final broken = ArtCatalog.fromAssetPaths([
        ...bundledArtPaths().where((path) => !path.startsWith('assets/art/attraction/')),
        'assets/art/attraction/themepark_castle_09_scene.webp',
      ]);
      await pumpDocuments(tester, catalog: broken);
      expect(inRow('Sunshine Park', find.byKey(const ValueKey('document-scene'))), findsOneWidget);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      expect(inRow('Sunshine Park', find.byKey(const ValueKey('document-window-placeholder'))), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without stamp or postmark art the row stays, on a plain paper mount', (tester) async {
      final bare = ArtCatalog.fromAssetPaths(bundledArtPaths().where((path) => !path.contains('/documents_')));
      await pumpDocuments(tester, catalog: bare);
      expect(inRow('Sunshine Park', find.byKey(const ValueKey('document-stamp-fallback'))), findsOneWidget);
      expect(inRow('Sunshine Park', find.byKey(const ValueKey('document-scene'))), findsOneWidget);
      expect(inRow('Sunshine Park', find.byKey(const ValueKey('document-postmark'))), findsNothing);
      expect(inRow('Sunshine Park', find.text('28')), findsOneWidget, reason: 'the date still shows');
      expect(tester.takeException(), isNull);
    });
  });

  group('kind icons', () {
    /// One document of every kind, in a column.
    Future<void> pumpEveryKind(WidgetTester tester, ArtCatalog catalog) async {
      tester.view.physicalSize = const Size(390 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final resolver = ArtResolver(catalog);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTravaryTheme(),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(DocumentStampLayout.inset),
              children: [
                for (final kind in BookingKind.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DocumentStampLayout.gap),
                    child: BookingCard(
                      key: ValueKey('kind-${kind.name}'),
                      text: cardTextForList(_booking(kind)),
                      art: resolver.resolve(_booking(kind), const TripArtContext(theme: ExperienceTheme.themepark)),
                      size: CardSize.document,
                      status: EntryStatus.upcoming,
                      onTap: () {},
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Finder badgeOf(BookingKind kind) => find.descendant(
      of: find.byKey(ValueKey('kind-${kind.name}')),
      matching: find.byKey(const ValueKey('document-kind-badge')),
    );

    testWidgets('all eight kinds carry their own raster icon on the stamp', (tester) async {
      await pumpEveryKind(tester, bundled);
      for (final kind in BookingKind.values) {
        final slot = IconSlot.forKind(kind);
        final icon = tester.widget<ImageIcon>(
          find.descendant(of: badgeOf(kind), matching: find.byKey(ValueKey('icon-raster-${slot.key}'))),
        );
        expect(icon.image, AssetImage('assets/art/icons/${slot.key}.webp'), reason: kind.name);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a missing icon file shows the kind\'s glyph instead', (tester) async {
      await pumpEveryKind(tester, ArtCatalog.fromAssetPaths(bundledArtPaths().where((p) => !p.contains('/icons/'))));
      for (final kind in BookingKind.values) {
        final slot = IconSlot.forKind(kind);
        expect(
          find.descendant(of: badgeOf(kind), matching: find.byKey(ValueKey('icon-fallback-${slot.key}'))),
          findsOneWidget,
          reason: kind.name,
        );
      }
    });
  });

  group('taps', () {
    final park = _booking(BookingKind.attraction);
    final art = ArtResolver(bundled).resolve(park, const TripArtContext(theme: ExperienceTheme.themepark));

    Future<void> pumpCard(WidgetTester tester, {VoidCallback? onTap, VoidCallback? onShowTickets}) async {
      tester.view.physicalSize = const Size(390 * 3, 300 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTravaryTheme(),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DocumentStampLayout.inset),
                child: BookingCard(
                  text: cardTextForList(park),
                  art: art,
                  size: CardSize.document,
                  status: EntryStatus.upcoming,
                  onTap: onTap,
                  onShowTickets: onShowTickets,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('the row opens the booking; tickets have their own full-size button', (tester) async {
      var opened = 0;
      var shown = 0;
      await pumpCard(tester, onTap: () => opened++, onShowTickets: () => shown++);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing, reason: 'the button takes its place');
      final button = find.byTooltip('Show tickets');
      final target = tester.getSize(find.byType(IconButton));
      expect(target.width, greaterThanOrEqualTo(44));
      expect(target.height, greaterThanOrEqualTo(48));

      await tester.tap(button);
      expect((opened, shown), (0, 1));
      await tester.tap(find.text(park.title));
      expect((opened, shown), (1, 1));
    });

    testWidgets('without tickets, a chevron', (tester) async {
      await pumpCard(tester, onTap: () {});
      expect(find.byTooltip('Show tickets'), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });
  });

  group('the destination stamp', () {
    testWidgets('the heading shows the focused trip\'s own stamp, its place printed live', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpDocuments(tester);
      expect(find.byType(DestinationStamp), findsOneWidget);
      expect(find.text('ORLANDO'), findsOneWidget);
      final image = tester.widget<Image>(find.byKey(const ValueKey('destination-stamp'))).image as FileImage;
      expect(image.file.path, 'art_packs/sources/city_us_orlando/common/documents_destination_stamp.webp');
      expect(find.bySemanticsLabel('Orlando'), findsOneWidget);
      semantics.dispose();

      await pumpDocuments(tester, now: lakesNow);
      expect(find.text('LAKE DISTRICT'), findsOneWidget);
      final lakes = tester.widget<Image>(find.byKey(const ValueKey('destination-stamp'))).image as FileImage;
      expect(lakes.file.path, 'art_packs/sources/region_gb_lake_district/common/documents_destination_stamp.webp');
    });

    testWidgets('no stamp rather than another place\'s', (tester) async {
      // Every pack but Orlando's: the Orlando trip gets none of the others.
      final others = bundled.withPacks([
        for (final id in stampPackIds)
          if (id != 'city_us_orlando') sourcePack(id),
      ]);
      await pumpDocuments(tester, catalog: others);
      expect(find.byType(DestinationStamp), findsNothing);
      expect(find.text('Documents'), findsWidgets);

      await pumpDocuments(tester, catalog: bundled);
      expect(find.byType(DestinationStamp), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

Booking _booking(BookingKind kind) => Booking(
  id: 'b-${kind.name}',
  tripId: 'demo-orlando',
  kind: kind,
  title: 'A ${kind.name} booking',
  startDate: LocalDate.fromDateTime(documentsNow),
  reference: 'REF-${kind.index}',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
