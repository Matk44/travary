import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:travary/data/attachment_store.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/smart_import_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/edit_booking_screen.dart';
import 'package:travary/features/import/smart_import_screen.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/logic/access.dart';
import 'package:travary/logic/price_text.dart';
import 'package:travary/logic/travi_cameos.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/photo_fixture.dart';
import '../support/travi.dart';

class _FakeImport implements SmartImportService {
  _FakeImport(this.result);

  final Object result;
  int calls = 0;

  String? tripId;

  @override
  Future<SmartImportResult> read(String path, {required LocalDate today, String? tripId}) async {
    calls++;
    this.tripId = tripId;
    final r = result;
    if (r is SmartImportException) throw r;
    return r as SmartImportResult;
  }
}

/// Refused by the server once (the free imports were used after all), then reads.
class _RefusedOnce implements SmartImportService {
  _RefusedOnce(this.result);

  final SmartImportResult result;
  int calls = 0;

  @override
  Future<SmartImportResult> read(String path, {required LocalDate today, String? tripId}) async {
    if (calls++ == 0) {
      throw const SmartImportException('You\'ve used your free Smart Imports.', needsPass: true);
    }
    return result;
  }
}

/// Still reading.
class _SlowImport implements SmartImportService {
  final reading = Completer<SmartImportResult>();

  @override
  Future<SmartImportResult> read(String path, {required LocalDate today, String? tripId}) => reading.future;
}

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  group('parsing the function response', () {
    test('turns bookings into drafts with their uncertain fields', () {
      final result = smartImportResultFromJson({
        'bookings': [
          {
            'kind': 'flight',
            'title': 'London to Orlando',
            'startDate': '2026-10-12',
            'startTime': '10:30',
            'endTime': '14:55',
            'reference': 'X7K2PQ',
            'details': {'flightNumber': 'BA 2037', 'seats': '22A'},
            'uncertain': ['startTime'],
          },
          {'kind': 'stay', 'title': 'No date'},
        ],
        'warning': 'Part of the page was cut off',
      });
      expect(result.drafts, hasLength(1));
      final draft = result.drafts.single;
      expect(draft.booking.kind, BookingKind.flight);
      expect(draft.booking.startTime, const ClockTime(10, 30));
      expect(draft.booking.detail(DetailKeys.seats), '22A');
      expect(draft.uncertain, {'startTime'});
      expect(draft.highlight, containsAll(['startTime', 'startDate', 'endTime']));
      expect(result.warning, 'Part of the page was cut off');
    });

    test('knows which files it can read', () {
      expect(smartImportMimeType('/x/Ticket.PDF'), 'application/pdf');
      expect(smartImportMimeType('/x/shot.heic'), 'image/heic');
      expect(smartImportMimeType('/x/notes.docx'), isNull);
    });
  });

  group('batch saving', () {
    late MemoryTravelRepository repository;
    late TravelStore store;

    setUp(() async {
      repository = MemoryTravelRepository(userId: 'me');
      store = TravelStore(repository: repository, artCatalog: const ArtCatalog.empty());
      await pumpEventQueue();
    });

    tearDown(() => store.dispose());

    Booking fresh(String id, BookingKind kind, LocalDate date, {LocalDate? endDate}) =>
        booking(id, kind, date, tripId: '', endDate: endDate);

    test('a flight and hotel on new dates share one new trip', () async {
      await store.saveBookings([
        fresh('hotel', BookingKind.stay, d(11, 3), endDate: d(11, 8)),
        fresh('flight', BookingKind.flight, d(11, 3)),
        fresh('home', BookingKind.flight, d(11, 8)),
      ]);
      await pumpEventQueue();
      expect(store.plans, hasLength(1));
      expect(store.plans.single.bookings, hasLength(3));
    });

    test('far-apart bookings get separate trips', () async {
      await store.saveBookings([fresh('a', BookingKind.dining, d(11, 3)), fresh('b', BookingKind.dining, d(12, 20))]);
      await pumpEventQueue();
      expect(store.plans, hasLength(2));
    });
  });

  group('screen', () {
    late String filePath;

    setUpAll(() {
      filePath = '${Directory.systemTemp.createTempSync('travary').path}/booking.pdf';
      File(filePath).writeAsBytesSync([37, 80, 68, 70]);
    });

    Future<(TravelStore, PremiumStore)> pump(
      WidgetTester tester,
      SmartImportService service, {
      AccessDecision access = const AccessDecision.freeUse(3),
      MemoryTravelRepository? repository,
      String? tripId,
      AttachmentStore? attachments,
      String? path,
      String fileName = 'booking.pdf',
    }) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      late TravelStore travel;
      late PremiumStore premium;
      SmartImportOutcome? outcome;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SmartImportService>.value(value: service),
            // Created by the providers so they're disposed with the tree.
            ChangeNotifierProvider(
              create: (_) => travel = TravelStore(
                repository: repository ?? MemoryTravelRepository(),
                artCatalog: const ArtCatalog.empty(),
                attachments: attachments,
              ),
            ),
            ChangeNotifierProvider(create: (_) => premium = PremiumStore(purchases: TestPurchaseService())),
          ],
          child: MaterialApp(
            theme: buildTravaryTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      outcome = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SmartImportScreen(
                            filePath: path ?? filePath,
                            fileName: fileName,
                            access: access,
                            tripId: tripId,
                          ),
                        ),
                      );
                    },
                    child: Text('Import (${outcome?.added ?? '-'})'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.textContaining('Import'));
      await tester.pumpAndSettle();
      return (travel, premium);
    }

    BookingDraft draft(String title, BookingKind kind, LocalDate date) => BookingDraft(
      booking(title, kind, date, title: title, tripId: ''),
      uncertain: const {'startTime'},
    );

    testWidgets('one booking opens the pre-filled form to check', (tester) async {
      final (_, premium) = await pump(
        tester,
        _FakeImport(SmartImportResult([draft('Lagoon Grill', BookingKind.dining, d(11, 3))])),
      );

      expect(find.textContaining('Filled in by Smart Import'), findsOneWidget);
      expect(find.byType(EditBookingScreen), findsOneWidget);
      final title = tester.widget<TextField>(find.byType(TextField).first);
      expect(title.controller!.text, 'Lagoon Grill');
      expect(premium.policy.freeSmartImportsLeft, 1);
    });

    testWidgets('several bookings can be added together', (tester) async {
      final (travel, _) = await pump(
        tester,
        _FakeImport(
          SmartImportResult([
            draft('London to Lisbon', BookingKind.flight, d(11, 3)),
            draft('Lisbon to London', BookingKind.flight, d(11, 8)),
          ]),
        ),
      );

      expect(find.text('We found 2 bookings'), findsOneWidget);
      expect(find.text('Check 1 detail'), findsNWidgets(2));
      await tester.tap(find.text('Add 2 bookings'));
      await tester.pumpAndSettle();

      expect(travel.bookings, hasLength(2));
      expect(travel.plans, hasLength(1));
    });

    testWidgets('a file gone by the time they add them still adds the bookings, without it', (tester) async {
      final directory = Directory.systemTemp.createTempSync('travary-files');
      addTearDown(() => directory.deleteSync(recursive: true));
      final (travel, _) = await pump(
        tester,
        _FakeImport(
          SmartImportResult([
            draft('London to Lisbon', BookingKind.flight, d(11, 3)),
            draft('Lisbon to London', BookingKind.flight, d(11, 8)),
          ]),
        ),
        attachments: AttachmentStore.at(directory),
        path: '${directory.path}/no-longer-there.pdf',
      );

      // Copying the file is real disk work, so it runs outside the fake clock.
      final dynamic add = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Add 2 bookings')).onPressed;
      await tester.runAsync(() async => await add());
      await tester.pumpAndSettle();

      expect(travel.bookings, hasLength(2));
      expect(travel.bookings.every((b) => b.attachments.isEmpty), isTrue);
      expect(find.text('Added without the file: it couldn’t be kept.'), findsOneWidget);
      expect(find.byType(SmartImportScreen), findsNothing, reason: 'nothing left locked');
    });

    group('a camera photo read', () {
      late Directory directory;
      late AttachmentStore files;
      late String photoPath;
      late int photoBytes;

      setUp(() {
        directory = Directory.systemTemp.createTempSync('travary-photos');
        files = AttachmentStore.at(Directory('${directory.path}/attachments')..createSync());
        final photo = cameraPhoto();
        photoBytes = photo.length;
        photoPath = (File('${directory.path}/IMG_0412.JPG')..writeAsBytesSync(photo)).path;
      });

      tearDown(() => directory.deleteSync(recursive: true));

      /// The ticket [booking] keeps: a JPEG on the phone, smaller than it came.
      void expectShrunk(Attachment attachment) {
        final stored = files.fileFor(attachment).readAsBytesSync();
        expect(attachment.name, 'IMG_0412.JPG');
        expect(attachment.sizeBytes, stored.length);
        expect(stored.length, lessThan(photoBytes ~/ 2));
        final image = img.decodeJpg(stored)!;
        expect((image.width, image.height), (1875, 2500));
      }

      testWidgets('into several bookings is shrunk once, kept on each and counted once', (tester) async {
        final (travel, _) = await pump(
          tester,
          _FakeImport(
            SmartImportResult([
              draft('London to Lisbon', BookingKind.flight, d(11, 3)),
              draft('Lisbon to London', BookingKind.flight, d(11, 8)),
            ]),
          ),
          attachments: files,
          path: photoPath,
          fileName: 'IMG_0412.JPG',
        );

        // Shrinking is real work: decoding, an isolate and the disk.
        final dynamic add = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Add 2 bookings')).onPressed;
        await tester.runAsync(() async => await add());
        await tester.pumpAndSettle();

        final tickets = [for (final booking in travel.bookings) ...booking.attachments];
        expect(tickets, hasLength(2));
        tickets.forEach(expectShrunk);
        expect(ticketFilesIn(travel.plans.single), 1, reason: 'one free file, not two');
      });

      testWidgets('into one booking goes with it, even saved straight away', (tester) async {
        final (travel, _) = await pump(
          tester,
          _FakeImport(SmartImportResult([draft('Lagoon Grill', BookingKind.dining, d(11, 3))])),
          attachments: files,
          path: photoPath,
          fileName: 'IMG_0412.JPG',
        );

        // Saved while the photo is still shrinking: it's saved once that's done.
        await tester.tap(find.byKey(const ValueKey('save-booking')));
        await tester.pump();
        for (var i = 0; i < 250 && travel.bookings.isEmpty; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(find.byType(EditBookingScreen), findsNothing);
        expectShrunk(travel.bookings.single.attachments.single);
      });
    });

    testWidgets('opened from a trip, only bookings on its dates go into it', (tester) async {
      final repository = MemoryTravelRepository(userId: 'me')
        ..replaceAll([trip('japan', title: 'Japan holiday', plannedStart: d(10, 11), plannedEnd: d(10, 23))], const []);
      final (travel, _) = await pump(
        tester,
        _FakeImport(
          SmartImportResult([
            draft('Sushi Saito', BookingKind.dining, d(10, 15)),
            draft('Bali villa', BookingKind.stay, LocalDate(2027, 3, 1)),
          ]),
        ),
        repository: repository,
        tripId: 'japan',
      );

      expect(find.byKey(const ValueKey('outside-trip-0')), findsNothing);
      expect(find.text('Not on Japan holiday\'s dates, so it starts a new trip'), findsOneWidget);
      await tester.tap(find.text('Add 2 bookings'));
      await tester.pumpAndSettle();

      Booking saved(String title) => travel.bookings.singleWhere((b) => b.title == title);
      expect(saved('Sushi Saito').tripId, 'japan');
      expect(saved('Bali villa').tripId, isNot('japan'));
      expect(travel.plan('japan')!.end, d(10, 23));
      expect(travel.plans, hasLength(2));
    });

    /// A free holiday keeping its two files already.
    MemoryTravelRepository fullHoliday() {
      Attachment file(String id) => Attachment(id: id, name: '$id.pdf', fileName: '$id.pdf', sizeBytes: 10);
      return MemoryTravelRepository(userId: 'me')..replaceAll(
        [trip('japan', title: 'Japan holiday', plannedStart: d(10, 11), plannedEnd: d(10, 23))],
        [
          booking(
            'park',
            BookingKind.attraction,
            d(10, 13),
            tripId: 'japan',
          ).copyWith(attachments: [file('a'), file('b')]),
        ],
      );
    }

    Future<void> notNow(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const ValueKey('onboarding-pass-free')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding-pass-free')));
      await tester.pumpAndSettle();
    }

    testWidgets('one booking for a free holiday with its two files opens the pass desk for the file', (tester) async {
      await pump(
        tester,
        _FakeImport(SmartImportResult([draft('Sushi Saito', BookingKind.dining, d(10, 15))])),
        repository: fullHoliday(),
        tripId: 'japan',
      );

      expect(find.byType(PaywallScreen), findsOneWidget, reason: 'a third file is a pass’s, so the desk opens');
      await notNow(tester);
      expect(find.byType(EditBookingScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('attach-scanned')), findsOneWidget, reason: 'the file is still on offer');
    });

    testWidgets('several bookings for a full free holiday open the pass desk before they’re added', (tester) async {
      final (travel, _) = await pump(
        tester,
        _FakeImport(
          SmartImportResult([
            draft('Sushi Saito', BookingKind.dining, d(10, 15)),
            draft('Tea ceremony', BookingKind.activity, d(10, 16)),
          ]),
        ),
        repository: fullHoliday(),
        tripId: 'japan',
      );
      await tester.tap(find.text('Add 2 bookings'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget, reason: 'not a quiet snackbar afterwards');
      await notNow(tester);
      final added = travel.bookings.where((b) => b.id != 'park');
      expect(added, hasLength(2), reason: 'the bookings are still added');
      expect(added.every((b) => b.attachments.isEmpty), isTrue);
      expect(find.text(ticketsNotKeptText(2)), findsOneWidget);
    });

    testWidgets('while it reads, Travi studies it instead of a spinner', (tester) async {
      final service = _SlowImport();
      await pump(tester, service);

      expect(find.text('Reading your booking…'), findsOneWidget);
      expect(traviCameo(TraviMoment.reading), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      service.reading.complete(const SmartImportResult([]));
      await tester.pumpAndSettle();
      expect(traviCameo(TraviMoment.reading), findsNothing);
    });

    testWidgets('a failure explains itself and offers to type it in', (tester) async {
      await pump(tester, _FakeImport(const SmartImportException('That file is too big.')));

      expect(find.text('Couldn\'t read that'), findsOneWidget);
      expect(find.text('That file is too big.'), findsOneWidget);
      expect(find.text('Add it myself'), findsOneWidget);
      expect(traviCameo(TraviMoment.oops), findsOneWidget);
    });

    testWidgets('when the server says the free ones are used, the pass desk opens; buying reads it', (tester) async {
      final service = _RefusedOnce(SmartImportResult([draft('Lagoon Grill', BookingKind.dining, d(11, 3))]));
      await pump(tester, service);

      expect(find.byType(PaywallScreen), findsOneWidget, reason: 'the pass desk, not a dead end');
      await tester.ensureVisible(find.byKey(const ValueKey('onboarding-pass-annual')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding-pass-annual')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('onboarding-pass-buy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding-pass-buy')));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsNothing);
      expect(service.calls, 2);
      expect(find.textContaining('Filled in by Smart Import'), findsOneWidget);
    });

    testWidgets('"Not now" on that desk leaves the refusal on screen', (tester) async {
      await pump(tester, _RefusedOnce(const SmartImportResult([])));
      await tester.ensureVisible(find.byKey(const ValueKey('onboarding-pass-free')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding-pass-free')));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsNothing);
      expect(find.text('You\'ve used your free Smart Imports.'), findsOneWidget);
    });

    testWidgets('finding nothing does not use a free import', (tester) async {
      final (_, premium) = await pump(tester, _FakeImport(const SmartImportResult([])));

      expect(find.text('No booking found'), findsOneWidget);
      expect(traviCameo(TraviMoment.oops), findsOneWidget);
      expect(premium.policy.freeSmartImportsLeft, 2);
    });
  });
}
