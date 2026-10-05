import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/flight_status_service.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/departure_board.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/edit_booking_screen.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/logic/flight_status_text.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/flight_status.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  late MemoryTravelRepository repo;

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    FlightStatusService? service,
    List<Booking> bookings = const [],
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repo = MemoryTravelRepository(userId: 'me')
      ..replaceAll([trip('la', title: 'Los Angeles', plannedStart: d(11, 8), plannedEnd: d(11, 15))], bookings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(
              repository: repo,
              artCatalog: const ArtCatalog.empty(),
              flightStatus: service,
              clock: () => DateTime(2026, 10, 4, 9),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
        ],
        child: MaterialApp(theme: buildTravaryTheme(), home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A page that opens the add-flight form, so saving can close it.
  Widget opener({Booking? existing}) => Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  EditBookingScreen(kind: BookingKind.flight, existing: existing, initialDate: d(11, 8), tripId: 'la'),
            ),
          ),
          child: const Text('Add a flight'),
        ),
      ),
    ),
  );

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text('Add a flight'));
    await tester.pumpAndSettle();
  }

  final number = find.byKey(const ValueKey('flight-number-field'));
  String fieldText(WidgetTester tester, String key) => tester
      .widget<TextField>(find.descendant(of: find.byKey(ValueKey('field-$key')), matching: find.byType(TextField)))
      .controller!
      .text;
  Finder flaps(String text) => find.byWidgetPredicate((widget) => widget is FlapText && widget.text == text);
  final board = find.byKey(const ValueKey('departure-board'));

  /// Lets the search pause pass, the answer arrive and the flaps flip.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the departures board finds the flight; one tap fills in the ticket', (tester) async {
    final service = FakeFlightStatusService()..legs = [ba283()];
    await pump(tester, opener(), service: service);
    await openForm(tester);
    expect(find.text('Find your flight'), findsOneWidget);
    expect(board, findsOneWidget);
    expect(find.text('8 Nov 2026'), findsOneWidget, reason: 'the day it leaves, in its box');

    // Typing doesn't ask until a whole number has been typed and the typing pauses.
    await tester.enterText(number, 'ba');
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(number, 'ba28');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(number, 'ba283');
    await tester.pump();
    expect(find.text('Looking for BA283 on Sun 8 Nov…'), findsOneWidget);
    await settle(tester);
    expect(service.calls, [FlightLookup(flightNumber: 'BA283', date: d(11, 8))]);

    expect(find.text('FLIGHT FOUND'), findsOneWidget);
    expect(flaps('BA 283'), findsOneWidget);
    expect(find.text('London'), findsOneWidget);
    expect(find.text('Los Angeles'), findsOneWidget);
    expect(flaps('10:05'), findsOneWidget);
    expect(find.text('Lands 1:25pm'), findsOneWidget);
    expect(find.text('Details stay editable'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('use-flight')));
    await tester.pumpAndSettle();
    expect(find.text('Add a flight'), findsWidgets);
    expect(find.text('Filled in from the airline\'s schedule. Check it matches your ticket.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'London to Los Angeles'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'London Heathrow (LHR)'), findsOneWidget);
    expect(fieldText(tester, 'flightNumber'), 'BA 283');
    expect(find.text('8 NOV 2026'), findsOneWidget);
    expect(find.text('10:05am'), findsOneWidget);
    expect(find.text('1:25pm'), findsOneWidget);
    expect(service.calls, hasLength(1), reason: 'filling in isn\'t a new search');

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    final saved = repo.bookings.single;
    expect(saved.title, 'London to Los Angeles');
    expect(saved.startDate, d(11, 8));
    expect(saved.startTime, const ClockTime(10, 5));
    expect(saved.endTime, const ClockTime(13, 25));
    expect(saved.location, 'London Heathrow (LHR)');
    expect(saved.detail(DetailKeys.flightNumber), 'BA 283');
    expect(saved.tripId, 'la');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a number that isn\'t flying that day says so; the ticket can be filled in by hand', (tester) async {
    final service = FakeFlightStatusService();
    await pump(tester, opener(), service: service);
    await openForm(tester);
    await tester.enterText(number, 'BA 999');
    await settle(tester);
    expect(find.text('NOT FOUND'), findsOneWidget);
    expect(flaps('NO FLIGHT'), findsOneWidget);
    expect(find.text('No BA999 found on Sun 8 Nov. Check the number and date, or enter it yourself.'), findsOneWidget);

    service.failure = const FlightStatusException('Flights can be looked up up to a year ahead.');
    await tester.enterText(number, 'BA 998');
    await settle(tester);
    expect(find.text('Flights can be looked up up to a year ahead.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('enter-flight-manually')));
    await tester.pumpAndSettle();
    expect(board, findsNothing);
    expect(find.byKey(const ValueKey('form-ticket')), findsOneWidget);
    expect(fieldText(tester, 'flightNumber'), 'BA 998', reason: 'what was typed carries over');
  });

  testWidgets('without the service, and when editing, the flight form is the ticket', (tester) async {
    await pump(tester, opener());
    await openForm(tester);
    expect(board, findsNothing);
    expect(find.byKey(const ValueKey('field-flightNumber')), findsOneWidget);
  });

  testWidgets('editing a flight opens its ticket, not the board', (tester) async {
    final flight = booking(
      'out',
      BookingKind.flight,
      d(11, 8),
      tripId: 'la',
      title: 'London to Los Angeles',
      details: {DetailKeys.flightNumber: 'BA 283'},
    );
    final service = FakeFlightStatusService()..legs = [ba283()];
    await pump(
      tester,
      opener(existing: flight),
      service: service,
      bookings: [flight],
    );
    await openForm(tester);
    expect(board, findsNothing);
    expect(find.text('Edit flight'), findsOneWidget);
    expect(service.calls, isEmpty);
  });

  testWidgets('a new trip suggests its flight out; adding it opens the board on the trip\'s first day', (tester) async {
    final service = FakeFlightStatusService()..legs = [ba283()];
    await pump(tester, const TripScreen(tripId: 'la'), service: service);
    expect(find.textContaining('Flight out', findRichText: true), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gap-flight-out')));
    await tester.pumpAndSettle();
    expect(board, findsOneWidget);
    expect(find.text('8 Nov 2026'), findsOneWidget);
  });

  for (final (width, scale) in [(320.0, 1.6), (430.0, 2.0)]) {
    testWidgets('the board and the ticket fit $width points at text scale $scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final service = FakeFlightStatusService()..legs = [ba283(departs: '2026-11-08T21:40', lands: '2026-11-09T06:10')];
      await pump(tester, opener(), service: service);
      tester.view.physicalSize = Size(width * 3, 844 * 3);
      await openForm(tester);
      await tester.enterText(number, 'BA 283');
      await settle(tester);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('use-flight')));
      await tester.tap(find.byKey(const ValueKey('use-flight')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  test('live status picks up a filled-in flight by its airport code', () {
    final filled = booking(
      'out',
      BookingKind.flight,
      d(11, 8),
      location: 'London Heathrow (LHR)',
      details: {DetailKeys.flightNumber: 'BA 283'},
    );
    expect(flightLookupFor(filled, d(11, 7))?.from, 'LHR');
  });
}
