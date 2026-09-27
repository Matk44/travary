import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/smart_import_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/edit_booking_screen.dart';
import 'package:travary/features/import/smart_import_screen.dart';
import 'package:travary/logic/access.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

class _FakeImport implements SmartImportService {
  _FakeImport(this.result);

  final Object result;
  int calls = 0;

  @override
  Future<SmartImportResult> read(String path, {required LocalDate today}) async {
    calls++;
    final r = result;
    if (r is SmartImportException) throw r;
    return r as SmartImportResult;
  }
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
      await store.saveBookings([
        fresh('a', BookingKind.dining, d(11, 3)),
        fresh('b', BookingKind.dining, d(12, 20)),
      ]);
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

    Future<(TravelStore, PremiumStore)> pump(WidgetTester tester, SmartImportService service,
        {AccessDecision access = const AccessDecision.freeUse(3)}) async {
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
              create: (_) => travel = TravelStore(repository: MemoryTravelRepository(), artCatalog: const ArtCatalog.empty()),
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
                          builder: (_) => SmartImportScreen(filePath: filePath, fileName: 'booking.pdf', access: access),
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

    BookingDraft draft(String title, BookingKind kind, LocalDate date) =>
        BookingDraft(booking(title, kind, date, title: title, tripId: ''), uncertain: const {'startTime'});

    testWidgets('one booking opens the pre-filled form to check', (tester) async {
      final (_, premium) = await pump(tester, _FakeImport(SmartImportResult([
        draft('Lagoon Grill', BookingKind.dining, d(11, 3)),
      ])));

      expect(find.textContaining('Filled in by Smart Import'), findsOneWidget);
      expect(find.byType(EditBookingScreen), findsOneWidget);
      final title = tester.widget<TextField>(find.byType(TextField).first);
      expect(title.controller!.text, 'Lagoon Grill');
      expect(premium.policy.freeSmartImportsLeft, 2);
    });

    testWidgets('several bookings can be added together', (tester) async {
      final (travel, _) = await pump(tester, _FakeImport(SmartImportResult([
        draft('London to Lisbon', BookingKind.flight, d(11, 3)),
        draft('Lisbon to London', BookingKind.flight, d(11, 8)),
      ])));

      expect(find.text('We found 2 bookings'), findsOneWidget);
      expect(find.text('Check 1 detail'), findsNWidgets(2));
      await tester.tap(find.text('Add 2 bookings'));
      await tester.pumpAndSettle();

      expect(travel.bookings, hasLength(2));
      expect(travel.plans, hasLength(1));
    });

    testWidgets('a failure explains itself and offers to type it in', (tester) async {
      await pump(tester, _FakeImport(const SmartImportException('That file is too big.')));

      expect(find.text('Couldn\'t read that'), findsOneWidget);
      expect(find.text('That file is too big.'), findsOneWidget);
      expect(find.text('Add it myself'), findsOneWidget);
    });

    testWidgets('finding nothing does not use a free import', (tester) async {
      final (_, premium) = await pump(tester, _FakeImport(const SmartImportResult([])));

      expect(find.text('No booking found'), findsOneWidget);
      expect(premium.policy.freeSmartImportsLeft, 3);
    });
  });
}
