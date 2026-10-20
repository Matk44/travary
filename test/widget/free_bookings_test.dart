import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/edit_booking_screen.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

/// A free holiday takes 12 bookings before it starts: the trip page counts
/// them from 9, and the 13th opens the pass desk with the form kept.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  late TravelStore travel;

  /// Lisbon, 1–8 Nov, with [bookings] dinners (and [notes] notes), on
  /// [today] (5 Oct unless said).
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    required int bookings,
    int notes = 0,
    DateTime? today,
    Entitlements entitlements = Entitlements.none,
    Stream<FreePlanLimits>? limits,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final now = today ?? DateTime(2026, 10, 5, 9);
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [trip('lisbon', title: 'Lisbon', plannedStart: d(11, 1), plannedEnd: d(11, 8))],
        [
          for (var i = 0; i < bookings; i++)
            booking('b$i', BookingKind.dining, d(11, 1 + i % 8), title: 'Dinner $i', tripId: 'lisbon'),
          for (var i = 0; i < notes; i++) booking('n$i', BookingKind.note, d(11, 2), tripId: 'lisbon'),
        ],
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                travel = TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), clock: () => now),
          ),
          ChangeNotifierProvider(
            create: (_) => PremiumStore(
              purchases: TestPurchaseService(initial: entitlements),
              clock: () => now,
              limits: limits,
            ),
          ),
        ],
        child: MaterialApp(theme: buildTravaryTheme(), home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder count() => find.byKey(const ValueKey('trip-booking-count'));

  group('the trip page', () {
    testWidgets('says nothing while there\'s plenty of room', (tester) async {
      await pump(tester, const TripScreen(tripId: 'lisbon'), bookings: 8, notes: 4);
      expect(count(), findsNothing);
    });

    testWidgets('counts them from 9 of 12, over "Add a booking"', (tester) async {
      await pump(tester, const TripScreen(tripId: 'lisbon'), bookings: 9);
      expect(find.text('9 of 12 free bookings used'), findsOneWidget);
      final above =
          tester.getBottomLeft(count()).dy <= tester.getTopLeft(find.byKey(const ValueKey('trip-add-booking'))).dy;
      expect(above, isTrue);
      expect(tester.getSize(count()).height, greaterThanOrEqualTo(kMinInteractiveDimension));
    });

    testWidgets('full, it says a pass adds more, and opens the desk for this holiday', (tester) async {
      await pump(tester, const TripScreen(tripId: 'lisbon'), bookings: 12);
      expect(find.text('12 of 12 free bookings used\u00a0· A\u00a0pass\u00a0adds\u00a0more'), findsOneWidget);
      await tester.tap(count());
      await tester.pumpAndSettle();
      final paywall = tester.widget<PaywallScreen>(find.byType(PaywallScreen));
      expect(
        (paywall.feature, paywall.tripId, paywall.source),
        (PremiumFeature.everyBooking, 'lisbon', 'booking_count'),
      );
      expect(find.text('Unlimited bookings, and the plan on every phone'), findsOneWidget);
    });

    testWidgets('nothing to count with a pass, or once the holiday has started', (tester) async {
      final pass = Entitlements(
        tripPasses: {'lisbon': TripPass(tripId: 'lisbon', start: d(11, 1), end: d(11, 8))},
      );
      await pump(tester, const TripScreen(tripId: 'lisbon'), bookings: 12, entitlements: pass);
      expect(count(), findsNothing);
      await pump(tester, const TripScreen(tripId: 'lisbon'), bookings: 12, today: DateTime(2026, 11, 1, 8));
      expect(count(), findsNothing);
    });

    testWidgets('follows config/freePlan', (tester) async {
      await pump(
        tester,
        const TripScreen(tripId: 'lisbon'),
        bookings: 12,
        limits: Stream.value(const FreePlanLimits(bookingsPerHoliday: 15)),
      );
      expect(find.text('12 of 15 free bookings used'), findsOneWidget);
    });
  });

  group('the form', () {
    Future<void> add(WidgetTester tester, BookingKind kind, String title) async {
      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('field-title')), matching: find.byType(TextField)),
        title,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('save-booking')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-booking')));
      await tester.pumpAndSettle();
    }

    Widget form(BookingKind kind) => EditBookingScreen(kind: kind, initialDate: d(11, 4), tripId: 'lisbon');

    testWidgets('the 12th saves', (tester) async {
      await pump(tester, form(BookingKind.dining), bookings: 11);
      await add(tester, BookingKind.dining, 'Time Out Market');
      expect(find.byType(PaywallScreen), findsNothing);
      expect(travel.plan('lisbon')!.bookings, hasLength(12));
    });

    testWidgets('the 13th opens the pass desk; "Not now" keeps the form as typed', (tester) async {
      await pump(tester, form(BookingKind.dining), bookings: 12);
      await add(tester, BookingKind.dining, 'Time Out Market');
      final paywall = tester.widget<PaywallScreen>(find.byType(PaywallScreen));
      expect((paywall.feature, paywall.tripId, paywall.source), (PremiumFeature.everyBooking, 'lisbon', 'add_booking'));
      expect(find.text('A pass makes room for the whole plan.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('paywall-close')));
      await tester.pumpAndSettle();
      expect(find.byType(EditBookingScreen), findsOneWidget);
      expect(find.text('Time Out Market'), findsOneWidget);
      expect(travel.plan('lisbon')!.bookings, hasLength(12), reason: 'nothing saved without a pass');
    });

    testWidgets('buying a Holiday Pass there confirms it, and leaving the desk saves the booking', (tester) async {
      await pump(tester, form(BookingKind.dining), bookings: 12);
      await add(tester, BookingKind.dining, 'Time Out Market');
      await tester.ensureVisible(find.byKey(const ValueKey('onboarding-pass-buy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding-pass-buy')));
      await tester.pumpAndSettle();

      // The desk confirms the pass: its badge, the holiday it's on.
      expect(find.byKey(const ValueKey('pass-confirmed-badge')), findsOneWidget);
      expect(find.text('Enjoy your\nholiday!', findRichText: true), findsOneWidget);
      expect(find.text('1–8 Nov · covered until 15 Nov 2026'), findsOneWidget);
      expect(travel.plan('lisbon')!.bookings, hasLength(12), reason: 'saved once they leave the desk');

      // Even closing it counts as bought: the booking they were adding saves.
      await tester.tap(find.byKey(const ValueKey('paywall-close')));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsNothing);
      expect(find.byType(EditBookingScreen), findsNothing);
      expect(travel.plan('lisbon')!.bookings.where((b) => b.title == 'Time Out Market'), hasLength(1));
    });

    testWidgets('a note always saves', (tester) async {
      await pump(tester, form(BookingKind.note), bookings: 12);
      await add(tester, BookingKind.note, 'Bring the adapter');
      expect(find.byType(PaywallScreen), findsNothing);
      expect(travel.plan('lisbon')!.bookings, hasLength(13));
    });

    testWidgets('never blocked once the holiday has started', (tester) async {
      await pump(tester, form(BookingKind.dining), bookings: 14, today: DateTime(2026, 11, 3, 18));
      await add(tester, BookingKind.dining, 'Tasca do Chico');
      expect(find.byType(PaywallScreen), findsNothing);
      expect(travel.plan('lisbon')!.bookings, hasLength(15));
    });

    testWidgets('editing one never is', (tester) async {
      final dinner = booking('b0', BookingKind.dining, d(11, 1), title: 'Dinner 0', tripId: 'lisbon');
      await pump(tester, EditBookingScreen(kind: dinner.kind, existing: dinner, tripId: 'lisbon'), bookings: 14);
      await add(tester, dinner.kind, 'Renamed dinner');
      expect(find.byType(PaywallScreen), findsNothing);
      expect(travel.plan('lisbon')!.bookings.singleWhere((b) => b.id == 'b0').title, 'Renamed dinner');
    });
  });
}
