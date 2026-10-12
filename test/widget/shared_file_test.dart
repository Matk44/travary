import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/attachment_store.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/booking/booking_actions.dart';
import 'package:travary/features/booking/edit_booking_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  testWidgets('free reads used up: no paywall, the add sheet, and the file stays as the ticket', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final directory = Directory.systemTemp.createTempSync('travary-shared');
    addTearDown(() => directory.deleteSync(recursive: true));
    final shared = File('${directory.path}/Lagoon Grill.png')..writeAsBytesSync([137, 80, 78, 71]);
    final files = Directory('${directory.path}/files')..createSync();
    late TravelStore travel;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => travel = TravelStore(
              repository: MemoryTravelRepository(userId: 'me'),
              artCatalog: const ArtCatalog.empty(),
              attachments: AttachmentStore.at(files),
              clock: () => DateTime(2026, 10, 5, 9),
            ),
          ),
          // Loaded before the share arrives, as in the app.
          ChangeNotifierProvider(
            lazy: false,
            create: (_) =>
                PremiumStore(purchases: TestPurchaseService(initial: const Entitlements(smartImportsUsed: 3))),
          ),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => importSharedFile(context, (path: shared.path, name: 'Lagoon Grill.png')),
                child: const Text('share'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    expect(find.text('Add this booking'), findsOneWidget);
    expect(find.text('Lagoon Grill.png stays with it as the ticket.'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-travel-document')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('add-dining')));
    await tester.pumpAndSettle();
    // The form copies the file in (real disk work, outside the fake clock).
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(files.listSync(), hasLength(1), reason: 'copied in as the ticket');
    expect(find.byType(EditBookingScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lagoon Grill.png'),
      300,
      scrollable: find.descendant(of: find.byType(EditBookingScreen), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Lagoon Grill.png'), findsOneWidget, reason: 'attached as the ticket');
    expect(travel.bookings, isEmpty);
  });
}
