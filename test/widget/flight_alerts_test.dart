import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/app/route_observer.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/push_service.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/live_flight_strip.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/booking_detail_screen.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/state/notifications_store.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/canonical_today.dart';
import '../support/push.dart';
import '../support/session.dart';
import '../support/travel_documents.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  /// Two and a half hours before BA 2037 leaves Gatwick.
  final now = DateTime(2026, 10, 14, 7);
  final stamp = DateTime(2026, 9, 1);

  final delayed = FlightStatus.fromJson({
    'number': 'BA 2037',
    'status': 'Delayed',
    'departure': {
      'airport': 'LGW',
      'airportName': 'Gatwick',
      'scheduled': '2026-10-14T09:30',
      'revised': '2026-10-14T10:15',
      'delayMinutes': 45,
      'terminal': 'S',
      'gate': '12',
    },
    'arrival': {'airport': 'MCO', 'airportName': 'Orlando', 'scheduled': '2026-10-14T14:30'},
  }, checkedAt: now.subtract(const Duration(minutes: 5)));

  Trip orlando({bool paid = true, Map<String, FlightStatus> live = const {}}) => Trip(
    id: 'orlando',
    title: 'Orlando',
    ownerId: 'me',
    memberIds: const ['me'],
    premium: paid ? TripPremium(grantedBy: 'me', until: DateTime(2026, 11, 30)) : null,
    liveFlights: live,
    createdAt: stamp,
    updatedAt: stamp,
  );

  final flight = booking(
    'out',
    BookingKind.flight,
    d(10, 14),
    tripId: 'orlando',
    title: 'London to Orlando',
    at: const ClockTime(9, 30),
    location: 'London Gatwick (LGW)',
    details: {DetailKeys.flightNumber: 'BA 2037'},
  );

  Future<void> pump(
    WidgetTester tester, {
    required Widget home,
    required Trip trip,
    PushService? push,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = MemoryTravelRepository(userId: 'me')..replaceAll([trip], [flight]);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TravelStore(repository: repository, artCatalog: bundledArtCatalog(), clock: () => now),
          ),
          ChangeNotifierProvider(
            create: (_) => PremiumStore(
              purchases: TestPurchaseService(clock: () => now),
              clock: () => now,
            ),
          ),
          if (push != null)
            ChangeNotifierProvider(
              create: (_) => NotificationsStore(push: push, userId: 'me')..start(),
            ),
          appSessionProvider(),
          travelDocumentsProvider(),
        ],
        child: MaterialApp(theme: buildTravaryTheme(), navigatorObservers: [appRouteObserver], home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Today', () {
    for (final width in [390.0, 320.0]) {
      testWidgets('a watched flight shows how it stands under its ticket (${width.toInt()} wide)', (tester) async {
        await pump(
          tester,
          home: const HomeShell(),
          trip: orlando(live: {'out': delayed}),
          width: width,
        );
        final strip = find.byType(LiveFlightStrip);
        expect(strip, findsOneWidget);
        expect(
          find.descendant(of: strip, matching: find.text('Delayed 45 min · Leaves 10:15am · Gate 12')),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(strip).dy,
          greaterThan(tester.getTopLeft(find.text('London to Orlando').first).dy),
          reason: 'under the ticket',
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('without alerts, the ticket stands alone', (tester) async {
      await pump(tester, home: const HomeShell(), trip: orlando(paid: false));
      expect(find.byType(LiveFlightStrip), findsNothing);
    });

    testWidgets('a tapped alert opens its flight; one arriving in the app shows there', (tester) async {
      final push = FakePushService(current: NotificationPermission.allowed);
      await pump(
        tester,
        home: const HomeShell(),
        trip: orlando(live: {'out': delayed}),
        push: push,
      );
      push.arrive(
        const FlightPush(
          tripId: 'orlando',
          bookingId: 'out',
          title: 'BA 2037 is delayed',
          body: 'Now leaves at 10:15am instead of 9:30am.',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('BA 2037 is delayed\nNow leaves at 10:15am instead of 9:30am.'), findsOneWidget);

      push.tap(const FlightPush(tripId: 'orlando', bookingId: 'out'));
      await tester.pumpAndSettle();
      expect(find.byType(BookingDetailScreen), findsOneWidget);
    });
  });

  group('the flight\'s page', () {
    testWidgets('on a paid trip, opening the flight asks for notifications once', (tester) async {
      final push = FakePushService();
      await pump(
        tester,
        home: const BookingDetailScreen(bookingId: 'out'),
        trip: orlando(),
        push: push,
      );
      expect(push.asks, 1);
      expect(push.registered, ['me']);
      await tester.ensureVisible(find.byKey(const ValueKey('flight-alerts')));
      expect(find.text('Flight alerts are on'), findsOneWidget);
      expect(find.text('You\'ll hear the moment BA\u00A02037 is delayed, moved or cancelled.'), findsOneWidget);

      // Opened again: never asked twice.
      await pump(
        tester,
        home: const BookingDetailScreen(bookingId: 'out'),
        trip: orlando(),
        push: push,
      );
      expect(push.asks, 1);
    });

    testWidgets('turned off on this phone, it says where to turn them on', (tester) async {
      final push = FakePushService(current: NotificationPermission.denied);
      await pump(
        tester,
        home: const BookingDetailScreen(bookingId: 'out'),
        trip: orlando(),
        push: push,
      );
      expect(push.asks, 0);
      await tester.ensureVisible(find.byKey(const ValueKey('flight-alerts')));
      expect(find.text('Flight alerts are off on this phone'), findsOneWidget);
    });

    testWidgets('on a free trip, it\'s offered, never asked', (tester) async {
      final push = FakePushService();
      await pump(
        tester,
        home: const BookingDetailScreen(bookingId: 'out'),
        trip: orlando(paid: false),
        push: push,
      );
      expect(push.asks, 0);
      await tester.ensureVisible(find.byKey(const ValueKey('flight-alerts')));
      expect(find.text('Flight alerts'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('flight-alerts')));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text('Shall I watch\nyour flights?', findRichText: true), findsOneWidget);
    });

    testWidgets('without notifications (demo mode) there\'s no row', (tester) async {
      await pump(
        tester,
        home: const BookingDetailScreen(bookingId: 'out'),
        trip: orlando(),
      );
      expect(find.byKey(const ValueKey('flight-alerts')), findsNothing);
    });
  });
}
