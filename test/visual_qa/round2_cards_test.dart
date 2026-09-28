import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/design/art/art_resolver.dart';
import 'package:travary/design/art/card_shells.dart';
import 'package:travary/design/cards/booking_card.dart';
import 'package:travary/design/cards/card_parts.dart';
import 'package:travary/design/cards/featured_ticket_card.dart';
import 'package:travary/design/cards/note_paper_card.dart';
import 'package:travary/design/cards/ongoing_strip.dart';
import 'package:travary/design/cards/ongoing_tag_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/art_pack_selection.dart';
import 'package:travary/logic/card_text.dart';
import 'package:travary/logic/day_plan.dart';

import '../helpers.dart';
import '../support/canonical_today.dart';

/// The round-2 shells on a phone-width page: each kind of "next up" card,
/// the hire-car key tag and a note. With `TRAVARY_VISUAL_QA=1` (and fonts
/// from `tool/visual_qa.sh`) writes `build/visual_qa/round2_cards.png`.
void main() {
  final qa = Platform.environment['TRAVARY_VISUAL_QA'] == '1';
  final resolver = ArtResolver(bundledArtCatalog());
  final look = TripArtContext.forTheme(ExperienceTheme.themepark);
  final today = d(10, 14);

  setUpAll(() async {
    TravaryText.useGoogleFonts = false;
    if (qa) await _loadFonts('build/visual_qa/fonts');
  });
  tearDownAll(() {
    TravaryText.serifFamily = null;
    TravaryText.sansFamily = null;
  });

  Booking make(
    String id,
    BookingKind kind,
    String title, {
    ClockTime? at,
    Map<String, String> details = const {},
    String? reference,
    LocalDate? endDate,
    String? notes,
  }) => Booking(
    id: id,
    tripId: 't',
    kind: kind,
    title: title,
    startDate: endDate == null ? today : today.addDays(-2),
    startTime: at,
    endDate: endDate,
    reference: reference,
    notes: notes,
    details: details,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final flight = make(
    'f',
    BookingKind.flight,
    'London to Orlando',
    at: const ClockTime(10, 30),
    reference: 'X7K2PQ',
    details: {DetailKeys.flightNumber: 'BA 2037', DetailKeys.seats: '14A'},
  );
  final dinner = make(
    'd',
    BookingKind.dining,
    'Lagoon Grill',
    at: const ClockTime(19, 15),
    details: {DetailKeys.partySize: '4'},
  );
  final train = make(
    't',
    BookingKind.transport,
    'London to Paris',
    at: const ClockTime(9, 1),
    reference: 'EUR-1',
    details: {DetailKeys.company: 'Eurostar'},
  );
  final note = make(
    'n',
    BookingKind.note,
    'Fireworks from the beach',
    at: const ClockTime(21, 0),
    notes: 'Best view is by the lifeguard tower.',
  );
  final space = make(
    's',
    BookingKind.activity,
    'Space Center tour',
    at: const ClockTime(9, 0),
    details: {DetailKeys.guests: '4'},
  );
  final show = make('e', BookingKind.event, 'Evening Circus Show', at: const ClockTime(18, 30));
  final park = make('a', BookingKind.attraction, 'Magic Kingdom', at: const ClockTime(9, 0));
  final car = make(
    'c',
    BookingKind.transport,
    'Car hire',
    endDate: today.addDays(4),
    details: {DetailKeys.company: 'Alamo'},
  );

  CardText hero(Booking b) => cardTextForEntry(
    DayEntry(booking: b, role: EntryRole.single, time: b.startTime, status: EntryStatus.upcoming),
    highlighted: true,
  );

  testWidgets('each kind gets its own shell, with its scene beneath the window', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();

    Widget card(Booking b) => Padding(
      padding: const EdgeInsets.fromLTRB(TodayLayout.featuredInset, 0, TodayLayout.featuredInset, 22),
      child: BookingCard(text: hero(b), art: resolver.resolve(b, look), size: CardSize.hero, onShowTickets: () {}),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTravaryTheme(),
        home: RepaintBoundary(
          key: boundary,
          child: Material(
            color: TravaryColors.linen,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                card(flight),
                card(dinner),
                card(train),
                card(note),
                Padding(
                  padding: const EdgeInsets.fromLTRB(TodayLayout.cardInset, 0, TodayLayout.cardInset, 22),
                  child: OngoingStrip(text: ongoingCardText(car, today), art: resolver.resolve(car, look)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TodayLayout.cardInset),
                  child: BookingCard(
                    text: cardTextForEntry(
                      DayEntry(
                        booking: note,
                        role: EntryRole.single,
                        time: note.startTime,
                        status: EntryStatus.upcoming,
                      ),
                    ),
                    art: resolver.resolve(note, look),
                  ),
                ),
                // Tagged cards: each booking's vignette fills the panel
                // right of the printed rule.
                for (final b in [space, dinner, flight, train, show, park])
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TodayLayout.cardInset,
                      TodayLayout.cardGap,
                      TodayLayout.cardInset,
                      0,
                    ),
                    child: BookingCard(
                      text: cardTextForEntry(
                        DayEntry(booking: b, role: EntryRole.single, time: b.startTime, status: EntryStatus.upcoming),
                      ),
                      art: resolver.resolve(b, look),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _precacheImages(tester);

    ImageProvider shellOf(Finder card) =>
        tester.widget<Image>(find.descendant(of: card, matching: find.byType(Image)).at(1)).image;
    final featured = find.byType(FeaturedTicketCard);
    expect(featured, findsNWidgets(3));
    expect(shellOf(featured.at(0)), const AssetImage('assets/art/common/boarding_pass.png'));
    expect(shellOf(featured.at(1)), const AssetImage('assets/art/common/featured_reservation.png'));
    expect(shellOf(featured.at(2)), const AssetImage('assets/art/common/travel_ticket.png'));

    // The scene is painted first (beneath), then the shell with its window.
    final images = find.descendant(of: featured.at(0), matching: find.byType(Image)).evaluate().toList();
    expect((images[0].widget as Image).image, const AssetImage('assets/art/flight/any_plane_01_scene.png'));
    expect((images[1].widget as Image).image, const AssetImage('assets/art/common/boarding_pass.png'));
    final window = tester.getRect(
      find.descendant(of: featured.at(0), matching: find.byKey(const ValueKey('scene-window'))),
    );
    final ticket = tester.getRect(featured.at(0));
    expect(window.left, greaterThan(ticket.left + ticket.width * 0.35), reason: 'the scene stays clear of the text');

    // Live text in each shell's own places.
    expect(find.text('SEAT 14A'), findsOneWidget);
    expect(find.text('TABLE FOR'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('EUROSTAR'), findsOneWidget);
    expect(find.text('Show tickets'), findsNWidgets(2));
    expect(find.text('Details'), findsOneWidget, reason: 'the dinner has nothing to show at the door');
    expect(find.byType(NotePaperCard), findsNWidgets(2), reason: 'a note next up and in the list');
    expect(find.byType(OngoingTagCard), findsOneWidget);
    expect(find.textContaining('DROP-OFF IN 4 DAYS', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);

    if (!qa) return;
    await tester.runAsync(() async {
      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/visual_qa').create(recursive: true);
      await File('build/visual_qa/round2_cards.png').writeAsBytes(png!.buffer.asUint8List());
    });
  });

  for (final width in [320.0, 430.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('long titles at ${width.toInt()} points and text scale $scale: no overflow', (tester) async {
        tester.view.physicalSize = Size(width * 3, 2600 * 3);
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        Booking long(Booking b) => Booking(
          id: b.id,
          tripId: b.tripId,
          kind: b.kind,
          title: '${b.title} with a much longer name than usual for a card',
          startDate: b.startDate,
          startTime: b.startTime,
          endDate: b.endDate,
          reference: b.reference,
          notes: b.notes,
          details: b.details,
          createdAt: b.createdAt,
          updatedAt: b.updatedAt,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTravaryTheme(),
            home: Material(
              child: ListView(
                children: [
                  for (final b in [flight, dinner, train, note])
                    BookingCard(
                      text: hero(long(b)),
                      art: resolver.resolve(b, look),
                      size: CardSize.hero,
                      onShowTickets: () {},
                    ),
                  OngoingStrip(text: ongoingCardText(long(car), today), art: resolver.resolve(car, look)),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(OngoingTagCard), findsOneWidget);
      });
    }
  }

  test('every kind has a featured and a list shell', () {
    final shells = resolver.resolve(flight, look).shells;
    expect(
      {for (final kind in BookingKind.values) kind: shells.featuredFor(kind)?.role},
      {
        BookingKind.flight: ShellRole.boardingPass,
        BookingKind.stay: ShellRole.roomCard,
        BookingKind.attraction: ShellRole.featuredTicket,
        BookingKind.dining: ShellRole.featuredReservation,
        BookingKind.transport: ShellRole.travelTicket,
        BookingKind.activity: ShellRole.featuredTicket,
        BookingKind.event: ShellRole.featuredTicket,
        BookingKind.note: ShellRole.notePaper,
      },
    );
    expect(
      {for (final kind in BookingKind.values) kind: shells.standardFor(kind)?.role},
      {
        for (final kind in BookingKind.values)
          kind: switch (kind) {
            BookingKind.stay => ShellRole.roomCard,
            BookingKind.note => ShellRole.notePaper,
            _ => ShellRole.reservationBlank,
          },
      },
    );
    expect(shells.ongoing?.role, ShellRole.ongoingTag);
    // Without the round-2 files, featured cards fall back to the look's ticket.
    const withoutRound2 = CardShells(featured: null);
    expect(withoutRound2.featuredFor(BookingKind.flight), isNull);
    final onlyTicket = CardShells(featured: shells.featured);
    expect(onlyTicket.featuredFor(BookingKind.flight), shells.featured);
    expect(onlyTicket.featuredFor(BookingKind.note), shells.featured);
  });
}

Future<void> _loadFonts(String dir) async {
  final folder = Directory(dir);
  if (!folder.existsSync()) return;
  final files = folder.listSync().whereType<File>().toList();
  Future<void> load(String family, String prefix) async {
    final loader = FontLoader(family);
    for (final file in files.where((f) => p.basename(f.path).startsWith(prefix))) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }

  await load('Source Serif 4', 'SourceSerif4');
  await load('Inter', 'Inter');
  await load('MaterialIcons', 'MaterialIcons');
  TravaryText.serifFamily = 'Source Serif 4';
  TravaryText.sansFamily = 'Inter';
}

Future<void> _precacheImages(WidgetTester tester) async {
  for (var pass = 0; pass < 2; pass++) {
    final elements = find.byType(Image).evaluate().toList();
    final trimmed = find.byType(TrimmedArt).evaluate().toList();
    await tester.runAsync(() async {
      for (final element in elements) {
        await precacheImage((element.widget as Image).image, element);
      }
      for (final element in trimmed) {
        await precacheImage(artImageProvider((element.widget as TrimmedArt).image), element);
      }
      // Trimmed art measures its visible part once decoded.
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
  }
}
