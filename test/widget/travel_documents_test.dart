import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/document_lock.dart';
import 'package:travary/data/memory_travel_document_repository.dart';
import 'package:travary/design/cards/travel_document_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/nav_bar.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/travel_documents/edit_travel_document_screen.dart';
import 'package:travary/features/travel_documents/travel_document_screen.dart';
import 'package:travary/features/travel_documents/travel_documents_screen.dart';
import 'package:travary/state/travel_documents_store.dart';

import '../support/countdown_today.dart';
import '../support/open_tab.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  // The countdown data: the next trip is the Lake District, 25–28 November
  // 2026; today is 28 September 2026.
  TravelDocument passport({String holder = 'Sam', LocalDate? expires}) => TravelDocument(
    id: 'p1',
    type: TravelDocumentType.passport,
    holder: holder,
    number: '533120784',
    issuedBy: 'GB',
    expiresOn: expires ?? LocalDate(2031, 3, 12),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    List<TravelDocument> documents = const [],
    FixedDocumentLock? lock,
    MemoryTravelDocumentRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      countdownTodayApp(documents: documents, documentLock: lock, documentRepository: repository),
    );
    await tester.pumpAndSettle();
  }

  TravelDocumentsStore storeOf(WidgetTester tester) =>
      Provider.of<TravelDocumentsStore>(tester.element(find.byType(Scaffold).last), listen: false);

  Finder entry() => find.byKey(const ValueKey('travel-documents-entry'));

  testWidgets('from the Documents tab: add a passport, kept on this phone, then see it', (tester) async {
    final repository = MemoryTravelDocumentRepository();
    await pumpApp(tester, repository: repository);
    await openTab(tester, 'Documents');
    expect(find.text('Add your passport'), findsOneWidget);

    await tester.tap(entry());
    await tester.pumpAndSettle();
    expect(find.byType(TravelDocumentsScreen), findsOneWidget);
    expect(find.textContaining('never uploads them'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('documents-invite')));
    await tester.pumpAndSettle();
    expect(find.byType(EditTravelDocumentScreen), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Whose is it?'), 'Sam');
    final number = tester.widget<TextField>(find.byKey(const ValueKey('document-number')));
    expect((number.autocorrect, number.enableSuggestions, number.enableIMEPersonalizedLearning), (false, false, false));
    await tester.enterText(find.byKey(const ValueKey('document-number')), '533120784');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.saved.single.holder, 'Sam');
    expect(repository.saved.single.type, TravelDocumentType.passport);
    expect(find.byType(TravelDocumentCard), findsOneWidget);
    expect(find.text('Sam · •••• 0784'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a document\'s number stays hidden until asked, and everything locks with the app', (tester) async {
    await pumpApp(tester, documents: [passport()]);
    await openTab(tester, 'Documents');
    expect(find.descendant(of: entry(), matching: find.text('1')), findsOneWidget);
    expect(find.descendant(of: entry(), matching: find.byIcon(Icons.lock_outline_rounded)), findsOneWidget);

    // Opening asks the phone's lock straight away.
    await tester.tap(entry());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TravelDocumentCard));
    await tester.pumpAndSettle();
    expect(find.byType(TravelDocumentScreen), findsOneWidget);
    String shown() => tester.widget<Text>(find.byKey(const ValueKey('document-number-shown'))).data!;
    expect(shown(), '•••• 0784');
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(shown(), '533120784');
    expect(find.text('United Kingdom'), findsOneWidget);

    // Into the background: locked, the number gone from the screen.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('533120784'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // Unlocking again shows it masked, as at first.
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(shown(), '•••• 0784');
  });

  testWidgets('refused by the lock: they stay shut', (tester) async {
    final lock = FixedDocumentLock(UnlockResult.refused);
    await pumpApp(tester, documents: [passport()], lock: lock);
    await openTab(tester, 'Documents');
    await tester.tap(entry());
    await tester.pumpAndSettle();
    expect(lock.asked, 1);
    expect(find.byKey(const ValueKey('documents-locked')), findsOneWidget);
    expect(find.byType(TravelDocumentCard), findsNothing);
    expect(find.text('Your travel documents stay locked.'), findsOneWidget);
  });

  testWidgets('a passport too close to the next trip is flagged, even on the locked pill', (tester) async {
    // Under 6 months after the Lake District trip ends on 28 November.
    await pumpApp(tester, documents: [passport(expires: LocalDate(2027, 4, 1))]);
    await openTab(tester, 'Documents');
    expect(find.byKey(const ValueKey('travel-documents-to-check')), findsOneWidget);
    await tester.tap(entry());
    await tester.pumpAndSettle();
    expect(find.text('Expires 1 Apr 2027, under 6 months after Lake District'), findsOneWidget);
    await tester.tap(find.byType(TravelDocumentCard));
    await tester.pumpAndSettle();
    expect(find.textContaining('valid for 6 months after you leave'), findsOneWidget);
  });

  testWidgets('also from the add button and from Profile', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.descendant(of: find.byType(TravaryNavBar), matching: find.bySemanticsLabel('Add a booking')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-travel-document')));
    await tester.pumpAndSettle();
    expect(find.byType(EditTravelDocumentScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openTab(tester, 'Profile');
    await tester.tap(find.text('Travel documents'));
    await tester.pumpAndSettle();
    expect(find.byType(TravelDocumentsScreen), findsOneWidget);
    expect(storeOf(tester).count, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting asks first, then removes it from the phone', (tester) async {
    final repository = MemoryTravelDocumentRepository([passport()]);
    await pumpApp(tester, repository: repository);
    await openTab(tester, 'Documents');
    await tester.tap(entry());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TravelDocumentCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete document'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repository.saved, isEmpty);
    expect(find.byType(TravelDocumentCard), findsNothing);
  });
}
