// Audit probes: these assert the observed bugs, NOT desired acceptance behaviour.
// Run: flutter test docs/reviews/2026-10-12/reproduction_test.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/attachment_store.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/smart_import_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/import/smart_import_screen.dart';
import 'package:travary/features/today/today_screen.dart';
import 'package:travary/logic/access.dart';
import 'package:travary/logic/day_layout.dart';
import 'package:travary/logic/day_plan.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';
import '../../../test/helpers.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  test('arrival-day hotel is hidden at the exact check-in time', () {
    final stay = booking(
      'Hotel',
      BookingKind.stay,
      d(10, 12),
      at: const ClockTime(15, 0),
      endDate: d(10, 15),
      until: const ClockTime(11, 0),
    );
    final day = buildDayPlan(d(10, 12), [stay], DateTime(2026, 10, 12, 15));
    expect(day.entries.single.status, EntryStatus.done);
    expect(day.ongoing, isEmpty);
    expect(layOutDay(day, d(10, 12)).rows, isEmpty);
    expect(layOutDay(day, d(10, 12)).earlier, [0]);
  });

  test('same-day westbound arrival is changed to tomorrow even with explicit date', () {
    final flight = booking(
      'Sydney to Los Angeles',
      BookingKind.flight,
      d(10, 12),
      at: const ClockTime(11, 0),
      endDate: d(10, 12),
      until: const ClockTime(6, 0),
    );
    expect(withOvernightEnd(flight).endDate, d(10, 13));
  });

  test('timed note becomes done immediately without any acknowledgement', () {
    final note = booking('Take medication bag', BookingKind.note, d(10, 12), at: const ClockTime(8, 0));
    final day = buildDayPlan(d(10, 12), [note], DateTime(2026, 10, 12, 8));
    expect(day.entries.single.status, EntryStatus.done);
    expect(layOutDay(day, d(10, 12)).rows, isEmpty);
  });

  test('moving a booking preserves the old trip Storage path', () async {
    final repo = MemoryTravelRepository(userId: 'me')..replaceAll([trip('old'), trip('new')], []);
    final store = TravelStore(repository: repo, artCatalog: const ArtCatalog.empty());
    addTearDown(store.dispose);
    await pumpEventQueue();
    final original = booking('flight', BookingKind.flight, d(10, 12), tripId: 'old').copyWith(
      attachments: [
        const Attachment(
          id: 'a',
          name: 'ticket.pdf',
          fileName: 'a.pdf',
          sizeBytes: 10,
          remotePath: 'trips/old/attachments/a.pdf',
        ),
      ],
    );
    await store.saveBooking(original);
    await pumpEventQueue();
    final result = await store.saveBooking(original.copyWith(tripId: 'new'), previous: original);
    expect(result.booking.tripId, 'new');
    expect(result.booking.attachments.single.remotePath, 'trips/old/attachments/a.pdf');
  });

  testWidgets('Today retains a browsed day when the actual day advances', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [trip('trip', title: 'Test holiday', plannedStart: d(10, 12), plannedEnd: d(10, 16))],
        [
          booking('Monday booking', BookingKind.dining, d(10, 12)),
          booking('Tuesday booking', BookingKind.dining, d(10, 13)),
          booking('Wednesday booking', BookingKind.dining, d(10, 14)),
        ],
      );
    final store = TravelStore(
      repository: repo,
      artCatalog: const ArtCatalog.empty(),
      clock: () => DateTime(2026, 10, 12, 8),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => store,
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: const Scaffold(body: TodayScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.fling(find.byType(CustomScrollView), const Offset(-350, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Tuesday booking'), findsOneWidget);
    store.previewNow = DateTime(2026, 10, 14, 8);
    await tester.pumpAndSettle();
    expect(find.text('Tuesday booking'), findsOneWidget);
    expect(find.text('Wednesday booking'), findsNothing);
  });

  testWidgets('bulk import file failure throws and leaves saving locked', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final directory = Directory.systemTemp.createTempSync('travary-audit-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final store = TravelStore(
      repository: MemoryTravelRepository(userId: 'me'),
      artCatalog: const ArtCatalog.empty(),
      attachments: AttachmentStore.at(directory),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => store),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: SmartImportScreen(
            filePath: '${directory.path}/no-longer-available.pdf',
            fileName: 'booking.pdf',
            access: const AccessDecision.freeUse(3),
            initialResult: SmartImportResult([
              BookingDraft(booking('First booking', BookingKind.dining, d(11, 3), tripId: '')),
              BookingDraft(booking('Second booking', BookingKind.dining, d(11, 4), tripId: '')),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final dynamic save = tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed;
    await tester.runAsync(() async {
      await expectLater(save(), throwsA(isA<FileSystemException>()));
    });
    await tester.pump();
    expect(store.bookings, isEmpty);
    expect(tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed, isNull);
  });
}
