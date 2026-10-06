import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/checklist_row.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/trips/checklist_item_sheet.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

/// "Before you go" on a trip: things to sort that aren't bookings.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  late TravelStore store;

  /// [tripId]'s screen at iPhone size on 5 October 2026.
  Future<void> pump(WidgetTester tester, List<Trip> trips, String tripId) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = MemoryTravelRepository(userId: 'me')..replaceAll(trips, const []);
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
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: TripScreen(tripId: tripId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final japan = trip('japan', title: 'Japan holiday', plannedStart: d(10, 11), plannedEnd: d(10, 23));
  final checklist = find.byKey(const ValueKey('trip-checklist'));

  Future<void> scrollToChecklist(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('checklist-add')),
      200,
      scrollable: find.descendant(of: find.byType(TripScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
  }

  Finder row(String text) => find.ancestor(of: find.text(text), matching: find.byType(ChecklistRow));

  testWidgets('add from an idea with a date, tick it, change it, remove it and bring it back', (tester) async {
    await pump(tester, [japan], 'japan');
    await scrollToChecklist(tester);
    expect(find.descendant(of: checklist, matching: find.text('Before you go')), findsOneWidget);
    expect(find.text('Visas, insurance, the dog sitter: anything to sort before you go.'), findsOneWidget);

    // Nothing written: it asks.
    await tester.tap(find.byKey(const ValueKey('checklist-add')));
    await tester.pumpAndSettle();
    expect(find.byType(ChecklistItemSheet), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checklist-save')));
    await tester.pump();
    expect(find.text('What needs doing?'), findsWidgets);

    // An idea, by a date.
    await tester.tap(find.byKey(const ValueKey('checklist-idea-Travel insurance')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('checklist-due')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: find.byType(DatePickerDialog), matching: find.byType(TextField)),
      '10/09/2026',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('9 Oct 2026'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checklist-save')));
    await tester.pumpAndSettle();
    expect(find.byType(ChecklistItemSheet), findsNothing);
    expect(row('Travel insurance'), findsOneWidget);
    expect(find.descendant(of: row('Travel insurance'), matching: find.text('By 9 Oct')), findsOneWidget);
    expect(find.text('0 of 1 done'), findsOneWidget);

    // Ticked in place.
    await tester.tap(find.descendant(of: row('Travel insurance'), matching: find.byType(InkResponse)));
    await tester.pumpAndSettle();
    expect(find.text('1 of 1 done'), findsOneWidget);
    expect(store.plan('japan')!.trip.checklist.values.single.done, isTrue);

    // The words open it to change.
    await tester.tap(find.text('Travel insurance'));
    await tester.pumpAndSettle();
    expect(find.text('Edit to-do'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('checklist-text')), 'Insurance for all four of us');
    await tester.tap(find.byKey(const ValueKey('checklist-save')));
    await tester.pumpAndSettle();
    expect(row('Insurance for all four of us'), findsOneWidget);

    // Removed, then brought back.
    await tester.tap(find.text('Insurance for all four of us'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checklist-delete')));
    await tester.pumpAndSettle();
    expect(row('Insurance for all four of us'), findsNothing);
    expect(find.text('Removed "Insurance for all four of us"'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(row('Insurance for all four of us'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overdue items say so, and open ones come first', (tester) async {
    ChecklistItem item(String id, String text, {LocalDate? due, bool done = false}) =>
        ChecklistItem(id: id, text: text, due: due, done: done, createdAt: DateTime(2026, 9, 1));
    await pump(tester, [
      japan.copyWith(
        checklist: {
          'a': item('a', 'Pack chargers', done: true),
          'b': item('b', 'Apply for the visa', due: d(10, 1)),
          'c': item('c', 'Cat sitter'),
        },
      ),
    ], 'japan');
    await scrollToChecklist(tester);
    expect(find.text('Overdue · 1 Oct'), findsOneWidget);
    final top = [
      for (final text in ['Apply for the visa', 'Cat sitter', 'Pack chargers']) tester.getTopLeft(find.text(text)).dy,
    ];
    expect(top, orderedEquals([...top]..sort()));
    expect(find.text('1 of 3 done'), findsOneWidget);
  });

  testWidgets('a trip that\'s over shows no empty checklist', (tester) async {
    await pump(tester, [trip('rome', title: 'Rome', plannedStart: d(9, 1), plannedEnd: d(9, 5))], 'rome');
    expect(checklist, findsNothing);
  });
}
