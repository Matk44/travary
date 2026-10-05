import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/booking_actions.dart';
import 'package:travary/features/trips/trip_details_screen.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  late MemoryTravelRepository repo;

  /// Japan, 11–16 Oct: flies out, two nights in Kyoto, nothing booked for
  /// the 13th–15th, flies home.
  final bookings = [
    booking(
      'out',
      BookingKind.flight,
      d(10, 11),
      tripId: 'jp',
      title: 'Sydney to Tokyo',
      at: const ClockTime(20, 55),
      endDate: d(10, 12),
      details: {DetailKeys.flightNumber: 'QF 25'},
    ),
    booking('kyoto', BookingKind.stay, d(10, 12), tripId: 'jp', title: 'Kyoto House', endDate: d(10, 13)),
    booking(
      'museum',
      BookingKind.attraction,
      d(10, 12),
      tripId: 'jp',
      title: 'Kyoto Railway Museum',
      at: const ClockTime(15, 0),
      details: {DetailKeys.guests: '2'},
    ),
    booking('home', BookingKind.flight, d(10, 16), tripId: 'jp', title: 'Tokyo to Sydney'),
  ];

  Future<void> pump(WidgetTester tester, {List<Booking>? items}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repo = MemoryTravelRepository(userId: 'me')
      ..replaceAll([trip('jp', title: 'Japan', plannedStart: d(10, 11), plannedEnd: d(10, 16))], items ?? bookings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(
              repository: repo,
              artCatalog: const ArtCatalog.empty(),
              clock: () => DateTime(2026, 10, 5, 9),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: const TripScreen(tripId: 'jp'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scrolls the trip to its end, where its gaps and travellers are.
  Future<void> toEnd(WidgetTester tester) async {
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
  }

  testWidgets('the trip: its tag, its plan by date, what it still needs, and adding', (tester) async {
    await pump(tester);
    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('11–16 Oct 2026'), findsOneWidget);
    expect(find.text('6 days to go'), findsOneWidget);

    expect(find.text('Your plan'), findsOneWidget);
    expect(find.text('Sydney to Tokyo'), findsOneWidget);
    expect(find.text('QF 25 · 8:55pm'), findsOneWidget);
    expect(find.text('Kyoto House'), findsOneWidget);
    expect(find.text('12–13 Oct · 1 night'), findsOneWidget);
    expect(find.text('3:00pm · 2 tickets'), findsOneWidget);
    // The museum shares the 12th with the stay: one date for the two rows.
    expect(find.text('12'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);

    // The nights of the 13th, 14th and 15th have nowhere to stay.
    final gap = find.byKey(const ValueKey('gap-stay:2026-10-13'));
    expect(gap, findsOneWidget);
    expect(find.textContaining('13–16 Oct · 3 nights', findRichText: true), findsOneWidget);
    expect(find.text('Add a booking'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a stay for the gap opens the stay form on those nights', (tester) async {
    await pump(tester);
    await toEnd(tester);
    await tester.tap(
      find.descendant(of: find.byKey(const ValueKey('gap-stay:2026-10-13')), matching: find.text('Add')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add a stay'), findsOneWidget);
    expect(find.text('YOUR STAY'), findsOneWidget);
    expect(find.text('13 OCT 2026'), findsOneWidget);
    expect(find.text('16 OCT 2026'), findsOneWidget);
    expect(find.text('3 nights'), findsOneWidget);
    expect(find.text('Japan · 11–16 Oct'), findsOneWidget);
  });

  testWidgets('a gap that isn\'t needed is hidden for the whole trip, and can be brought back', (tester) async {
    await pump(tester);
    final gap = find.byKey(const ValueKey('gap-stay:2026-10-13'));
    await toEnd(tester);
    await tester.tap(find.descendant(of: gap, matching: find.byTooltip('More')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not needed'));
    await tester.pumpAndSettle();
    expect(gap, findsNothing);
    expect(repo.trips.single.hiddenGaps, {'stay:2026-10-13'});

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(gap, findsOneWidget);
    expect(repo.trips.single.hiddenGaps, isEmpty);
  });

  testWidgets('an empty trip suggests its flight out and somewhere to stay', (tester) async {
    await pump(tester, items: const []);
    expect(find.textContaining('Add what you\'ve booked'), findsOneWidget);
    expect(find.byKey(const ValueKey('gap-flight-out')), findsOneWidget);
    expect(find.textContaining('Somewhere to stay', findRichText: true), findsOneWidget);
  });

  testWidgets('trip details hold the name and dates, the people, the card style and deleting', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('trip-details')));
    await tester.pumpAndSettle();
    expect(find.byType(TripDetailsScreen), findsOneWidget);
    expect(find.text('11–16 Oct 2026 · 6 days'), findsOneWidget);
    expect(find.text('Card style'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Delete trip'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Delete trip'), findsOneWidget);
  });

  testWidgets('the add sheet leads with the common kinds and folds the rest away', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Add a booking'));
    await tester.pumpAndSettle();
    expect(find.byType(KindPickerSheet), findsOneWidget);
    final sheet = find.byType(KindPickerSheet);
    for (final kind in ['Flight', 'Stay', 'Tickets', 'Dining']) {
      expect(
        find.descendant(of: sheet, matching: find.text(kind)),
        findsOneWidget,
        reason: kind,
      );
    }
    expect(find.text('Note'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('add-more-kinds')));
    await tester.pumpAndSettle();
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Passport & documents'), findsOneWidget);
  });

  group('small phones and large text', () {
    for (final (width, scale) in [(320.0, 1.0), (320.0, 1.6), (430.0, 1.6)]) {
      testWidgets('$width points at text scale $scale: no overflow', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester);
        tester.view.physicalSize = Size(width * 3, 844 * 3);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('trip-details')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        // A booking's own page.
        await tester.tap(find.text('Kyoto House'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        // The add sheet, with every kind showing.
        await tester.tap(find.byKey(const ValueKey('trip-add-booking')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('add-more-kinds')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        final gap = find.byKey(const ValueKey('gap-stay:2026-10-13'));
        await toEnd(tester);
        await tester.tap(find.descendant(of: gap, matching: find.text('Add')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
