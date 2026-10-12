import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/checklist_row.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/trips/packing_list_screen.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/countdown_today.dart';

/// The packing list: everything to take, ticked as it goes in the case.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Finder note() => find.byKey(const ValueKey('countdown-note'));

  testWidgets('from the countdown: start the list, add an idea, tick it; the countdown says so', (tester) async {
    phone(tester);
    await tester.pumpWidget(countdownTodayApp());
    await tester.pumpAndSettle();
    expect(tester.getSemantics(note()).label, 'Packing list: Start yours');

    await tester.tap(note());
    await tester.pumpAndSettle();
    expect(find.byType(PackingListScreen), findsOneWidget);
    expect(find.text('Lake District'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('packing-idea-Sun cream')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(ChecklistRow), matching: find.text('Sun cream')), findsOneWidget);
    expect(find.byKey(const ValueKey('packing-idea-Sun cream')), findsNothing);
    expect(find.text('0 of 1 packed'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(ChecklistRow), matching: find.byType(InkResponse)).first);
    await tester.pumpAndSettle();
    expect(find.text('1 of 1 packed'), findsOneWidget);

    // Ticked things stay where they are while the list is open.
    await tester.tap(find.byKey(const ValueKey('packing-idea-Swimwear')));
    await tester.pumpAndSettle();
    List<String> rows() => [for (final row in tester.widgetList<ChecklistRow>(find.byType(ChecklistRow))) row.title];
    expect(rows(), ['Swimwear', 'Sun cream'], reason: 'new things go before what\'s packed');
    await tester.tap(find.descendant(of: find.byType(ChecklistRow), matching: find.byType(InkResponse)).first);
    await tester.pumpAndSettle();
    expect(rows(), ['Swimwear', 'Sun cream']);
    await tester.tap(find.descendant(of: find.byType(ChecklistRow), matching: find.byType(InkResponse)).first);
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 packed'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.getSemantics(note()).label, 'Packing list: 1 of 2 packed');
  });

  testWidgets('typing things in: return adds one after another', (tester) async {
    phone(tester);
    await tester.pumpWidget(countdownTodayApp());
    await tester.pumpAndSettle();
    await tester.tap(note());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('packing-add')));
    await tester.pumpAndSettle();
    expect(find.text('Something to pack'), findsOneWidget);
    expect(find.byKey(const ValueKey('checklist-due')), findsNothing, reason: 'no "by when" for packing');
    for (final thing in ['Wellies', 'Map']) {
      await tester.enterText(find.byKey(const ValueKey('checklist-text')), thing);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
    }
    // Still open, ready for the next one; an empty return closes it.
    expect(find.text('Something to pack'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(find.text('Something to pack'), findsNothing);
    expect(find.text('0 of 2 packed'), findsOneWidget);
  });

  testWidgets('an empty list starts from the last trip\'s, unticked; and it\'s a row on the trip', (tester) async {
    phone(tester);
    final item = ChecklistItem(id: 'p1', text: 'Snorkel', done: true, createdAt: DateTime(2026));
    final lisbon = trip(
      'lisbon',
      title: 'Lisbon',
      plannedStart: d(6, 1),
      plannedEnd: d(6, 5),
    ).copyWith(packing: {'p1': item});
    final japan = trip('japan', title: 'Japan', plannedStart: d(10, 11), plannedEnd: d(10, 23));
    final repo = MemoryTravelRepository(userId: 'me')..replaceAll([lisbon, japan], const []);
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
          home: const TripScreen(tripId: 'japan'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('trip-packing'));
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.descendant(of: find.byType(TripScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(PackingListScreen), findsOneWidget);

    // Nobody else is on the trip yet: an invitation to pack together.
    expect(find.byKey(const ValueKey('packing-together')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('packing-reuse')));
    await tester.pumpAndSettle();
    expect(find.text('Added 1 thing from Lisbon'), findsOneWidget);
    expect(find.text('0 of 1 packed'), findsOneWidget, reason: 'copied unticked');
    expect(find.byKey(const ValueKey('packing-reuse')), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.descendant(of: row, matching: find.text('0 of 1 packed')), findsOneWidget);
  });
}
