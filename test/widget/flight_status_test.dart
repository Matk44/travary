import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/flight_status_service.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/booking_detail_screen.dart';
import 'package:travary/logic/flight_status_text.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/flight_status.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  final now = DateTime(2026, 10, 4, 9, 10);
  final delayed = FlightStatus.fromJson({
    'number': 'BA 283',
    'status': 'Expected',
    'departure': {
      'airport': 'LHR',
      'airportName': 'Heathrow',
      'scheduled': '2026-10-04T10:30',
      'revised': '2026-10-04T11:05',
      'delayMinutes': 35,
      'terminal': '5',
      'gate': 'B32',
      'checkInDesk': 'D',
    },
    'arrival': {'airport': 'LAX', 'airportName': 'Los Angeles', 'scheduled': '2026-10-04T13:45', 'terminal': 'B'},
  }, checkedAt: now);

  Future<void> pump(WidgetTester tester, {required LocalDate on, FlightStatusService? service}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [trip('la', title: 'Los Angeles')],
        [
          booking(
            'out',
            BookingKind.flight,
            on,
            tripId: 'la',
            title: 'London to Los Angeles',
            at: const ClockTime(10, 30),
            location: 'London Heathrow (LHR)',
            details: {DetailKeys.flightNumber: 'BA 283'},
          ),
        ],
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(
              repository: repo,
              artCatalog: const ArtCatalog.empty(),
              flightStatus: service,
              clock: () => now,
            ),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: const BookingDetailScreen(bookingId: 'out'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('on the day, the flight shows its gate, terminal and delay', (tester) async {
    final service = FakeFlightStatusService()..answer = delayed;
    await pump(tester, on: d(10, 4), service: service);

    expect(service.calls, [FlightLookup(flightNumber: 'BA 283', date: d(10, 4), from: 'LHR')]);
    expect(find.text('LIVE STATUS · BA 283'), findsOneWidget);
    expect(find.text('Delayed 35 min'), findsOneWidget);
    expect(find.text('Terminal 5 · Gate B32 · Check-in D'), findsOneWidget);
    expect(find.text('Checked just now'), findsOneWidget);

    await tester.tap(find.byTooltip('Check again'));
    await tester.pumpAndSettle();
    expect(service.calls, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('weeks ahead, it says when live status will show, without asking', (tester) async {
    final service = FakeFlightStatusService()..answer = delayed;
    await pump(tester, on: d(10, 20), service: service);
    expect(find.text(flightStatusComesLaterText), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-status')), findsNothing);
    expect(service.calls, isEmpty);
  });

  testWidgets('a flight the airline hasn\'t listed yet, and a failed check, say so', (tester) async {
    final service = FakeFlightStatusService();
    await pump(tester, on: d(10, 5), service: service);
    expect(find.textContaining('BA 283 isn\'t showing yet'), findsOneWidget);

    service.failure = const FlightStatusException('Live flight status isn\'t available right now. Try again soon.');
    await tester.tap(find.byTooltip('Check again'));
    await tester.pumpAndSettle();
    expect(find.text('Live flight status isn\'t available right now. Try again soon.'), findsOneWidget);
  });

  testWidgets('without the service (demo, release builds for now) nothing shows', (tester) async {
    await pump(tester, on: d(10, 4));
    expect(find.byKey(const ValueKey('flight-status')), findsNothing);
    expect(find.text(flightStatusComesLaterText), findsNothing);
  });
}
