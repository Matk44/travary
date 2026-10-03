import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/app/app.dart';
import 'package:travary/app/bootstrap.dart';
import 'package:travary/data/art_pack_service.dart';
import 'package:travary/data/art_pack_store.dart';
import 'package:travary/data/attachment_store.dart';
import 'package:travary/data/memory_travel_document_repository.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/smart_import_service.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/nav_bar.dart';
import 'package:travary/domain/domain.dart';

import '../helpers.dart';
import '../support/art_pack_fixtures.dart';
import '../support/canonical_today.dart';
import '../support/open_tab.dart';
import '../support/session.dart';

/// The whole app (`TravaryApp`, not a test copy of its providers), so
/// switching account really rebuilds the stores on the other account's data.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  late Directory temp;
  setUp(() => temp = Directory.systemTemp.createTempSync('sign_in_'));
  tearDown(() => temp.deleteSync(recursive: true));

  /// Each account's own trips: the guest has Lisbon, "other" has Kyoto.
  MemoryTravelRepository repositoryFor(String uid) {
    final repository = MemoryTravelRepository(userId: uid);
    final today = LocalDate.fromDateTime(DateTime.now());
    final title = switch (uid) {
      'me' => 'Lisbon',
      'other' => 'Kyoto',
      _ => null,
    };
    if (title != null) {
      repository.replaceAll([
        trip(title.toLowerCase(), title: title, plannedStart: today.addDays(20), plannedEnd: today.addDays(24)),
      ], const []);
    }
    return repository;
  }

  Future<void> pumpApp(WidgetTester tester, FakeAuthService auth) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dependencies = Dependencies(
      repositoryFor: repositoryFor,
      initialUserId: auth.current!.uid,
      auth: auth,
      purchases: TestPurchaseService(),
      smartImport: CloudSmartImportService(ensureSignedIn: () async {}),
      artCatalog: bundledArtCatalog(),
      artPacks: ArtPackManager(
        store: ArtPackStore.at(Directory('${temp.path}/packs')),
        remote: FakeArtPackRemote(),
        appBuild: 1,
      ),
      attachments: AttachmentStore.at(Directory('${temp.path}/attachments')..createSync()),
      travelDocuments: MemoryTravelDocumentRepository(),
      documentLock: FixedDocumentLock(),
    );
    await tester.pumpWidget(TravaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
  }

  Finder inTrips(String text) => find.descendant(of: find.byType(Scaffold), matching: find.text(text));

  testWidgets('a guest signs in on Profile: same trips, now saved to their account', (tester) async {
    final auth = FakeAuthService(email: 'sam@example.com');
    await pumpApp(tester, auth);
    await openTab(tester, 'Profile');
    expect(find.text('Keep your trips safe'), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-in-apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-in-google')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sign-in-apple')));
    await tester.pumpAndSettle();
    expect(find.text('Signed in with Apple. Your trips are saved to your account.'), findsOneWidget);
    expect(find.text('Signed in with Apple'), findsOneWidget);
    expect(find.text('sam@example.com'), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-out')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-account')), findsOneWidget);

    await openTab(tester, 'Trips');
    expect(inTrips('Lisbon'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signing in to an account from another phone switches to its trips', (tester) async {
    final auth = FakeAuthService(email: 'sam@example.com')
      ..existing[SignInMethod.google] = 'other'
      ..guestTrips = 1;
    await pumpApp(tester, auth);
    await openTab(tester, 'Profile');
    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await tester.pumpAndSettle();

    // The app rebuilt on the other account, and says what happened.
    expect(find.text('Signed in with Google. 1 trip from this phone moved to your account.'), findsOneWidget);
    await openTab(tester, 'Trips');
    expect(inTrips('Kyoto'), findsWidgets);
    expect(inTrips('Lisbon'), findsNothing);
  });

  testWidgets('signing out asks first, then starts afresh as a guest', (tester) async {
    final auth = FakeAuthService(uid: 'me', methods: {SignInMethod.apple}, email: 'sam@example.com');
    await pumpApp(tester, auth);
    await openTab(tester, 'Profile');
    await tester.tap(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signOut']);
    expect(find.text('Signed out. Sign in again to see your trips.'), findsOneWidget);
    await openTab(tester, 'Trips');
    expect(inTrips('Lisbon'), findsNothing);
    expect(find.text('No trips yet'), findsOneWidget);
  });

  testWidgets('deleting the account asks first and can be called off', (tester) async {
    final auth = FakeAuthService(uid: 'me', methods: {SignInMethod.google}, email: 'sam@example.com');
    await pumpApp(tester, auth);
    await openTab(tester, 'Profile');
    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(auth.calls, isEmpty);

    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete account').last);
    await tester.pumpAndSettle();
    expect(auth.calls, ['deleteAccount']);
    expect(find.text('Your account has been deleted.'), findsOneWidget);
    expect(find.descendant(of: find.byType(TravaryNavBar), matching: find.bySemanticsLabel('Today')), findsOneWidget);
  });
}
