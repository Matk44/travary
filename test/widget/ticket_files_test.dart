import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/booking_detail_screen.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

/// Free holidays keep two ticket files; adding a third opens the paywall.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  Attachment file(String id) => Attachment(id: id, name: '$id.pdf', fileName: '$id.pdf', sizeBytes: 10);

  Future<void> pump(
    WidgetTester tester,
    List<Attachment> files, {
    Entitlements entitlements = Entitlements.none,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final japan = trip('japan', title: 'Japan', plannedStart: d(10, 11), plannedEnd: d(10, 23));
    final park = Booking(
      id: 'park',
      tripId: 'japan',
      kind: BookingKind.attraction,
      title: 'Theme park',
      startDate: d(10, 13),
      attachments: files,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final repo = MemoryTravelRepository(userId: 'me')..replaceAll([japan], [park]);
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
          ChangeNotifierProvider(
            create: (_) => PremiumStore(purchases: TestPurchaseService(initial: entitlements)),
          ),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: const BookingDetailScreen(bookingId: 'park'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder attach() => find.byKey(const ValueKey('attach-ticket'));

  Future<void> tapAttach(WidgetTester tester) async {
    await tester.ensureVisible(attach());
    await tester.pumpAndSettle();
    await tester.tap(attach());
    await tester.pumpAndSettle();
  }

  testWidgets('with one kept it says one more is free', (tester) async {
    await pump(tester, [file('a')]);
    expect(find.textContaining('1 more free on this holiday'), findsOneWidget);
  });

  testWidgets('with two kept the next opens the paywall', (tester) async {
    await pump(tester, [file('a'), file('b')]);
    expect(find.textContaining('Free holidays keep 2 tickets'), findsOneWidget);
    await tapAttach(tester);
    expect(find.byType(PaywallScreen), findsOneWidget);
  });

  testWidgets('with a pass for the trip there\'s no limit', (tester) async {
    final pass = Entitlements(
      tripPasses: {'japan': TripPass(tripId: 'japan', start: d(10, 11), end: d(10, 23))},
    );
    await pump(tester, [file('a'), file('b'), file('c')], entitlements: pass);
    expect(find.textContaining('free on this holiday'), findsNothing);
    expect(find.textContaining('Free holidays keep'), findsNothing);
  });
}
