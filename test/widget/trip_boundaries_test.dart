import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/edit_booking_screen.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

/// Bookings keep to their trip's days: the form's date pickers, where a
/// booking goes when its dates leave its trip, and what adding from a trip
/// starts on.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  late MemoryTravelRepository repo;
  late TravelStore store;

  final japan = trip('japan', title: 'Japan holiday', plannedStart: d(10, 11), plannedEnd: d(10, 23));
  final tokyo = trip('tokyo', title: 'Tokyo');
  final outbound = booking('out', BookingKind.flight, d(10, 11), tripId: 'tokyo', title: 'London to Tokyo');

  /// [home] at iPhone size on 5 October 2026.
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    List<Trip> trips = const [],
    List<Booking> bookings = const [],
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repo = MemoryTravelRepository(userId: 'me')..replaceAll(trips, bookings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => store = TravelStore(
              repository: repo,
              artCatalog: const ArtCatalog.empty(),
              clock: () => DateTime(2026, 10, 5, 9),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
        ],
        child: MaterialApp(theme: buildTravaryTheme(), home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// From the trip's "Add a booking" to the form for [kind].
  Future<void> addFromTrip(WidgetTester tester, BookingKind kind) async {
    await tester.tap(find.byKey(const ValueKey('trip-add-booking')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('add-${kind.name}')));
    await tester.pumpAndSettle();
    expect(find.byType(EditBookingScreen), findsOneWidget);
  }

  Finder dateIn(String box, String date) =>
      find.descendant(of: find.byKey(ValueKey('date-$box')), matching: find.text(date));

  Future<void> openStartPicker(WidgetTester tester, String date) async {
    await tester.tap(dateIn('start', date));
    await tester.pumpAndSettle();
  }

  /// Types [date] (MM/DD/YYYY) into the open date picker and confirms it.
  Future<void> typeDate(WidgetTester tester, String date) async {
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(DatePickerDialog), matching: find.byType(TextField)), date);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  String tripLine(WidgetTester tester) => tester
      .widget<Text>(find.descendant(of: find.byKey(const ValueKey('form-trip')), matching: find.byType(Text)))
      .data!;

  testWidgets('in a trip with planned dates the pickers only offer its days, and a travel day either side', (
    tester,
  ) async {
    await pump(tester, const TripScreen(tripId: 'japan'), trips: [japan]);
    await addFromTrip(tester, BookingKind.dining);
    expect(tripLine(tester), 'Japan holiday · 11–23 Oct');

    await openStartPicker(tester, '11 OCT 2026');
    final calendar = tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker));
    expect(calendar.firstDate, DateTime(2026, 10, 9));
    expect(calendar.lastDate, DateTime(2026, 10, 25));
    expect(
      find.descendant(of: find.byType(DatePickerDialog), matching: find.text('Japan holiday · 11–23 Oct')),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Choosing to let the dates decide lifts the limits.
    await tester.tap(find.byKey(const ValueKey('form-trip')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose automatically'));
    await tester.pumpAndSettle();
    await openStartPicker(tester, '11 OCT 2026');
    expect(tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker)).lastDate, DateTime(2100, 12, 31));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an end date can\'t be picked before the start', (tester) async {
    await pump(tester, const TripScreen(tripId: 'japan'), trips: [japan]);
    await addFromTrip(tester, BookingKind.attraction);
    await openStartPicker(tester, '11 OCT 2026');
    await typeDate(tester, '10/15/2026');
    await tester.tap(dateIn('end', 'SAME DAY'));
    await tester.pumpAndSettle();
    expect(tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker)).firstDate, DateTime(2026, 10, 15));
  });

  testWidgets('adding a stay from the trip starts on the nights it still needs', (tester) async {
    await pump(
      tester,
      const TripScreen(tripId: 'japan'),
      trips: [japan],
      bookings: [
        booking('out', BookingKind.flight, d(10, 11), tripId: 'japan', title: 'London to Tokyo'),
        booking('ryokan', BookingKind.stay, d(10, 11), tripId: 'japan', title: 'Ryokan', endDate: d(10, 14)),
      ],
    );
    await addFromTrip(tester, BookingKind.stay);
    expect(dateIn('start', '14 OCT 2026'), findsOneWidget);
    expect(dateIn('end', '23 OCT 2026'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // And a flight, on the day of the one missing: home.
    await addFromTrip(tester, BookingKind.flight);
    expect(dateIn('start', '23 OCT 2026'), findsOneWidget);
  });

  group('a trip that formed from its bookings', () {
    Future<void> addDinnerOn(WidgetTester tester, String date) async {
      await pump(
        tester,
        const TripScreen(tripId: 'tokyo'),
        trips: [tokyo],
        bookings: [outbound],
      );
      await addFromTrip(tester, BookingKind.dining);
      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('field-title')), matching: find.byType(TextField)),
        'Sushi Saito',
      );
      await openStartPicker(tester, '11 OCT 2026');
      await typeDate(tester, date);
      await tester.tap(find.byKey(const ValueKey('save-booking')));
      await tester.pumpAndSettle();
    }

    Booking sushi() => store.bookings.singleWhere((b) => b.title == 'Sushi Saito');

    testWidgets('takes what\'s near it without asking', (tester) async {
      await addDinnerOn(tester, '10/12/2026');
      expect(find.byKey(const ValueKey('stretch-trip')), findsNothing);
      expect(sushi().tripId, 'tokyo');
    });

    testWidgets('asks before stretching well past them, and can start a new trip', (tester) async {
      await addDinnerOn(tester, '11/20/2026');
      expect(find.text('Add to Tokyo?'), findsOneWidget);
      expect(
        find.text('Tokyo runs 11 Oct so far. This is on 20 Nov, so the trip would run 11 Oct – 20 Nov.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('stretch-other')));
      await tester.pumpAndSettle();
      expect(sushi().tripId, isNot('tokyo'));
      expect(store.plan('tokyo')!.end, d(10, 11));
      expect(store.plans, hasLength(2));
    });

    testWidgets('or stretch it, when that\'s what they meant', (tester) async {
      await addDinnerOn(tester, '10/20/2026');
      await tester.tap(find.byKey(const ValueKey('stretch-keep')));
      await tester.pumpAndSettle();
      expect(sushi().tripId, 'tokyo');
      expect(store.plan('tokyo')!.end, d(10, 20));
    });
  });

  testWidgets('fixing a typed month moves a booking out of the stray trip it made', (tester) async {
    final gracery = booking(
      'gracery',
      BookingKind.stay,
      d(11, 11),
      tripId: 'shinjuku',
      title: 'Hotel Gracery',
      endDate: d(11, 23),
    );
    await pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EditBookingScreen(kind: BookingKind.stay, existing: gracery),
                ),
              ),
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
      trips: [
        japan,
        trip('shinjuku', title: 'Shinjuku'),
      ],
      bookings: [gracery],
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(tripLine(tester), 'Shinjuku · 11–23 Nov');

    await openStartPicker(tester, '11 NOV 2026');
    await typeDate(tester, '10/11/2026');
    expect(dateIn('end', '23 OCT 2026'), findsOneWidget);
    expect(tripLine(tester), 'Moves to Japan holiday · 11–23 Oct');

    await tester.tap(find.byKey(const ValueKey('save-booking')));
    await tester.pumpAndSettle();
    expect(store.booking('gracery')!.tripId, 'japan');
    expect(store.plan('shinjuku'), isNull);
    expect(store.plans.single.end, d(10, 23));
  });
}
