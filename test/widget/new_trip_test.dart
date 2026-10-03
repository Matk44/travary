import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/common.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/sharing/join_trip_sheet.dart';
import 'package:travary/features/trips/trip_details_sheet.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/countdown_today.dart';
import '../support/open_tab.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  /// The app at iPhone size on 28 September 2026.
  Future<void> pumpApp(WidgetTester tester, {List<Trip> trips = const [], List<Booking> bookings = const []}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(countdownTodayApp(data: (trips: trips, bookings: bookings)));
    await tester.pumpAndSettle();
  }

  TravelStore storeOf(WidgetTester tester) =>
      Provider.of<TravelStore>(tester.element(find.byType(Scaffold).first), listen: false);

  /// Types [start] and [end] (MM/DD/YYYY) into the date range picker.
  Future<void> pickDates(WidgetTester tester, String start, String end) async {
    await tester.tap(find.byKey(const ValueKey('trip-dates')));
    await tester.pumpAndSettle();
    // Flutter's own calendar header ("Start Date – End Date") overflows with
    // the test font's wide glyphs; with the app's fonts it fits at 320–430.
    expect(
      tester.takeException(),
      anyOf(isNull, isA<FlutterError>().having((e) => '$e', 'error', contains('overflowed'))),
    );
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Start Date'), start);
    await tester.enterText(find.widgetWithText(TextField, 'End Date'), end);
    final confirm = find.text('OK').evaluate().isNotEmpty ? find.text('OK') : find.text('Save');
    await tester.tap(confirm);
    await tester.pumpAndSettle();
  }

  testWidgets('a new trip from Today: where to and when, then it opens, ready for bookings', (tester) async {
    await pumpApp(tester);
    expect(find.text('Where are you off to?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(EmptyState), matching: find.text('New trip')));
    await tester.pumpAndSettle();
    expect(find.byType(TripDetailsSheet), findsOneWidget);

    // Both are needed.
    await tester.tap(find.text('Create trip'));
    await tester.pump();
    expect(find.text('Choose your dates'), findsOneWidget);
    expect(find.textContaining('Where are you going?'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Where to?'), '  Paris ');
    await pickDates(tester, '10/12/2026', '10/18/2026');
    expect(find.text('12–18 Oct 2026 · 7 days'), findsOneWidget);
    expect(find.text('Choose your dates'), findsNothing);

    await tester.tap(find.text('Create trip'));
    await tester.pumpAndSettle();
    expect(find.byType(TripDetailsSheet), findsNothing);
    expect(find.byType(TripScreen), findsOneWidget);
    expect(find.descendant(of: find.byType(TripScreen), matching: find.text('Paris')), findsOneWidget);
    expect(find.text('12–18 Oct 2026 · 7 days'), findsOneWidget);
    // It leads with its first booking: no free days, no second add button.
    expect(find.text('Add your first booking'), findsOneWidget);
    expect(find.textContaining('Day 1'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);

    final plan = storeOf(tester).plans.single;
    expect(plan.trip.title, 'Paris');
    expect((plan.trip.plannedStart, plan.trip.plannedEnd), (LocalDate(2026, 10, 12), LocalDate(2026, 10, 18)));
    expect(plan.trip.isAutomaticLook, isTrue);
  });

  testWidgets('the Trips tab starts a trip from its heading, and the sheet can join one instead', (tester) async {
    await pumpApp(
      tester,
      trips: [trip('rome', title: 'Rome')],
      bookings: [_romeHotel],
    );
    await openTab(tester, 'Trips');

    await tester.tap(find.widgetWithText(InfoPill, 'New trip'));
    await tester.pumpAndSettle();
    expect(find.text('Anything you book on these dates joins it automatically.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Have an invite code? Join a trip'));
    await tester.pumpAndSettle();
    expect(find.byType(TripDetailsSheet), findsNothing);
    expect(find.byType(JoinTripSheet), findsOneWidget);
  });

  testWidgets('no trips yet: the Trips tab offers a new trip or joining one', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Trips');
    expect(find.text('No trips yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Join a trip'));
    await tester.pumpAndSettle();
    expect(find.byType(JoinTripSheet), findsOneWidget);
  });

  testWidgets('editing a trip: a new name keeps it automatic; new dates still cover its bookings', (tester) async {
    await pumpApp(
      tester,
      trips: [trip('rome', title: 'Rome')],
      bookings: [_romeHotel],
    );
    await openTab(tester, 'Trips');
    await tester.tap(find.text('Rome'));
    await tester.pumpAndSettle();
    expect(find.text('10–14 Nov 2026 · 5 days'), findsOneWidget);

    // Just the name: the dates keep following the bookings.
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit trip'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Rome'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Where to?'), 'Roma');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(TripScreen), matching: find.text('Roma')), findsOneWidget);
    expect(storeOf(tester).plan('rome')!.trip.plannedStart, isNull);

    // Dates that start after the hotel: the trip still covers it.
    await tester.tap(find.text('10–14 Nov 2026 · 5 days'));
    await tester.pumpAndSettle();
    await pickDates(tester, '11/12/2026', '11/16/2026');
    expect(find.text('Your bookings run 10–14 Nov 2026, so the trip covers those days too.'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('10–16 Nov 2026 · 7 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('where the trip goes', () {
    Future<void> openSheet(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.descendant(of: find.byType(EmptyState), matching: find.text('New trip')));
      await tester.pumpAndSettle();
    }

    Finder destination() => find.byKey(const ValueKey('trip-destination'));
    String destinationText(WidgetTester tester) => tester.widget<Text>(destination()).data!;
    final name = find.widgetWithText(TextField, 'Where to?');

    testWidgets('read from the name as it\'s typed, and saved with the trip', (tester) async {
      await openSheet(tester);
      expect(destination(), findsNothing);
      expect(find.text('Add a destination'), findsOneWidget);

      await tester.enterText(name, 'Japan holiday');
      await tester.pump();
      expect(destinationText(tester), 'Japan');

      // A name that no longer says where takes the guess away again.
      await tester.enterText(name, 'Honeymoon');
      await tester.pump();
      expect(destination(), findsNothing);

      await tester.enterText(name, 'Our Japanese adventure');
      await tester.pump();
      await pickDates(tester, '04/10/2027', '04/16/2027');
      await tester.tap(find.text('Create trip'));
      await tester.pumpAndSettle();

      final trip = storeOf(tester).plans.single.trip;
      expect(trip.destination?.countryCode, 'JP');
      expect(trip.effectiveLocation?.verification, LocationVerification.verified);
      // The trip screen says where, since its name doesn't.
      expect(find.text('JAPAN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a half-typed place is completed from a suggestion', (tester) async {
      await openSheet(tester);
      await tester.enterText(name, 'Autumn in Kyo');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('place-suggestion-Kyoto, Japan')));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'Autumn in Kyoto'), findsOneWidget);
      expect(destinationText(tester), 'Kyoto, Japan');
      expect(find.byKey(const ValueKey('place-suggestion-Kyoto, Japan')), findsNothing);
    });

    testWidgets('an everyday word is only a suggestion, and any place can be removed', (tester) async {
      await openSheet(tester);
      await tester.enterText(name, 'Nice');
      await tester.pump();
      expect(destination(), findsNothing);
      await tester.tap(find.byKey(const ValueKey('place-suggestion-Nice, France')));
      await tester.pump();
      expect(destinationText(tester), 'Nice, France');

      await tester.tap(find.byTooltip('Not this place'));
      await tester.pump();
      expect(destination(), findsNothing);
      // Removed means removed: the name doesn't bring it back.
      await tester.enterText(name, 'Nice and Paris');
      await tester.pump();
      expect(destination(), findsNothing);
    });

    testWidgets('chosen from the list, for a name that doesn\'t say', (tester) async {
      await openSheet(tester);
      await tester.enterText(name, 'Grandma\'s');
      await tester.pump();
      await tester.tap(find.text('Add a destination'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Country, region or city'), 'corn');
      await tester.pump();
      await tester.tap(find.text('Cornwall'));
      await tester.pumpAndSettle();
      expect(destinationText(tester), 'Cornwall, United Kingdom');
      expect(find.widgetWithText(TextField, 'Grandma\'s'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('editing keeps it unless the new name names somewhere else', (tester) async {
      final japan =
          trip(
            'jp',
            title: 'Spring',
            plannedStart: LocalDate(2027, 4, 10),
            plannedEnd: LocalDate(2027, 4, 16),
          ).copyWith(
            destination: const TripDestination(countryCode: 'JP', countryName: 'Japan'),
          );
      await pumpApp(tester, trips: [japan]);
      await openTab(tester, 'Trips');
      await tester.tap(find.text('Spring'));
      await tester.pumpAndSettle();
      expect(find.text('JAPAN'), findsOneWidget);
      await tester.tap(find.text('Spring').last);
      await tester.pumpAndSettle();
      expect(destinationText(tester), 'Japan');

      await tester.enterText(name, 'Spring blossom');
      await tester.pump();
      expect(destinationText(tester), 'Japan');
      await tester.enterText(name, 'Spring in Seoul');
      await tester.pump();
      expect(destinationText(tester), 'Seoul, South Korea');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(storeOf(tester).plan('jp')!.trip.destination?.citySlug, 'seoul');
    });
  });
}

final _romeHotel = booking(
  'hotel',
  BookingKind.stay,
  LocalDate(2026, 11, 10),
  tripId: 'rome',
  title: 'Hotel Artemide',
  endDate: LocalDate(2026, 11, 14),
);
