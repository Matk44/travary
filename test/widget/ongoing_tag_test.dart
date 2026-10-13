import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/app/route_observer.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/cards/ongoing_tag_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/canonical_today.dart';
import '../support/session.dart';
import '../support/travel_documents.dart';

/// The key tag of something held for days, on a small phone: when the
/// company and the countdown don't both fit, the countdown stays.
void main() {
  testWidgets('a hire car\'s key tag keeps when it\'s due back over its company', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 700 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 11, 4, 9);
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll(
        [trip('jp', title: 'Japan')],
        [
          booking(
            'car',
            BookingKind.transport,
            d(11, 3),
            tripId: 'jp',
            title: 'Car hire',
            at: const ClockTime(10, 0),
            endDate: d(11, 6),
            details: {DetailKeys.company: 'Times Car Rental Hokkaido'},
          ),
          booking('pass', BookingKind.transport, d(11, 3), tripId: 'jp', title: 'Japan Rail Pass', endDate: d(11, 10)),
        ],
      );
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
          appSessionProvider(),
          travelDocumentsProvider(),
        ],
        child: MaterialApp(theme: buildTravaryTheme(), navigatorObservers: [appRouteObserver], home: const HomeShell()),
      ),
    );
    await tester.pumpAndSettle();

    final car = find.ancestor(of: find.text('Car hire'), matching: find.byType(OngoingTagCard));
    expect(find.descendant(of: car, matching: find.textContaining('DROP-OFF IN 2 DAYS', findRichText: true)), findsOne);
    expect(find.descendant(of: car, matching: find.textContaining('Times Car', findRichText: true)), findsNothing);
    final pass = find.ancestor(of: find.text('Japan Rail Pass'), matching: find.byType(OngoingTagCard));
    expect(find.descendant(of: pass, matching: find.textContaining('ENDS IN 6 DAYS', findRichText: true)), findsOne);
    expect(tester.takeException(), isNull);
  });
}
