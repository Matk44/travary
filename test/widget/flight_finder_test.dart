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

  testWidgets('the board heads the ticket; a found flight fills in the rest', (tester) async {
    final service = FakeFlightStatusService()..legs = [ba283()];
    await pump(tester, opener(), service: service);
    await openForm(tester);
    expect(find.text('Add a flight'), findsWidgets);
    expect(board, findsOneWidget);
    expect(find.byKey(const ValueKey('form-ticket')), findsOneWidget, reason: 'the ticket is under the board');
    expect(find.byKey(const ValueKey('field-flightNumber')), findsNothing, reason: 'the number is typed on the board');
    expect(find.text('8 Nov 2026'), findsOneWidget, reason: 'the day it leaves, in its box');
    final top = tester.getTopLeft(number).dy;
    expect(top, lessThan(tester.getTopLeft(find.byKey(const ValueKey('field-title'))).dy));

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

    // No extra tap: the ticket below is filled in, and stays editable.
    expect(find.text('Filled in from the airline\'s schedule. Check it matches your ticket.'), findsOneWidget);
    expect(fieldText(tester, 'title'), 'London to Los Angeles');
    expect(fieldText(tester, 'location'), 'London Heathrow (LHR)');
    expect(find.text('8 NOV 2026'), findsOneWidget);
    expect(find.text('10:05am'), findsOneWidget);
    expect(find.text('1:25pm'), findsOneWidget);
    expect(service.calls, hasLength(1), reason: 'filling in isn\'t a new search');

    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('field-title')), matching: find.byType(TextField)),
      'Off to LA',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    final saved = repo.bookings.single;
    expect(saved.title, 'Off to LA');
    expect(saved.startDate, d(11, 8));
    expect(saved.startTime, const ClockTime(10, 5));
    expect(saved.endTime, const ClockTime(13, 25));
    expect(saved.location, 'London Heathrow (LHR)');
    expect(saved.detail(DetailKeys.flightNumber), 'BA 283', reason: 'as the airline writes it');
    expect(saved.tripId, 'la');
    expect(tester.takeException(), isNull);
  });

  testWidgets('what\'s typed by hand stays; another number swaps only the board\'s details', (tester) async {
    final service = FakeFlightStatusService()..legs = [ba283()];
    await pump(tester, opener(), service: service);
    await openForm(tester);
    final title = find.descendant(of: find.byKey(const ValueKey('field-title')), matching: find.byType(TextField));
    await tester.enterText(title, 'Holiday flight');
    await tester.enterText(number, 'BA 283');
    await settle(tester);
    expect(fieldText(tester, 'title'), 'Holiday flight');
    expect(fieldText(tester, 'location'), 'London Heathrow (LHR)');

    service.legs = [];
    await tester.enterText(number, 'BA 999');
    await settle(tester);
    expect(find.text('NOT FOUND'), findsOneWidget);
    expect(fieldText(tester, 'title'), 'Holiday flight');
    expect(fieldText(tester, 'location'), isEmpty, reason: 'BA 283\'s airport went with it');
    expect(find.text('Filled in from the airline\'s schedule. Check it matches your ticket.'), findsNothing);
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
    expect(
      find.text('No BA999 found on Sun 8 Nov. Check the number and date, or fill in the ticket yourself.'),
      findsOneWidget,
    );

    service.failure = const FlightStatusException('Live flight status isn\'t available right now. Try again soon.');
    await tester.enterText(number, 'BA 998');
    await settle(tester);
    expect(find.text('Live flight status isn\'t available right now. Try again soon.'), findsOneWidget);

    final title = find.descendant(of: find.byKey(const ValueKey('field-title')), matching: find.byType(TextField));
    await tester.enterText(title, 'Home');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(repo.bookings.single.title, 'Home');
    expect(repo.bookings.single.detail(DetailKeys.flightNumber), 'BA 998', reason: 'what was typed is kept');
  });

  testWidgets('a date past the schedule says so and asks nothing; the ticket can be filled in by hand', (tester) async {
    final service = FakeFlightStatusService()..legs = [ba283()];
    // 4 Oct 2026 is today, so 20 Apr 2027 is 198 days ahead.
    final far = Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    EditBookingScreen(kind: BookingKind.flight, initialDate: LocalDate(2027, 4, 20), tripId: 'la'),
              ),
            ),
            child: const Text('Add a flight'),
          ),
        ),
      ),
    );
    await pump(tester, far, service: service);
    await openForm(tester);
    await tester.enterText(number, 'BA 283');
    await settle(tester);
    expect(service.calls, isEmpty, reason: 'the plan refuses it, so it isn\'t asked');
    expect(find.text('SCHEDULE NOT OUT YET'), findsOneWidget);
    expect(find.textContaining('about six months ahead'), findsOneWidget);
    expect(find.text('NOT FOUND'), findsNothing);
    expect(find.byKey(const ValueKey('form-ticket')), findsOneWidget, reason: 'the ticket is still there to fill in');
  });

  testWidgets('without the service the flight number heads the ticket', (tester) async {
    await pump(tester, opener());
    await openForm(tester);
    expect(board, findsNothing);
    final flightNumber = find.byKey(const ValueKey('field-flightNumber'));
    expect(flightNumber, findsOneWidget);
    expect(
      tester.getTopLeft(flightNumber).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('field-title'))).dy),
    );
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
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-booking')),
        300,
        scrollable: find.descendant(of: find.byType(EditBookingScreen), matching: find.byType(Scrollable)).first,
      );
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
