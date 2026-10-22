import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/app/keyboard_guard.dart';
import 'package:travary/data/demo_data.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/sharing_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/sharing/join_trip_sheet.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/features/wallet/wallet_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../support/open_tab.dart';
import '../support/session.dart';
import '../support/travel_documents.dart';

class _FakeSharing implements SharingService {
  @override
  Future<TripInvite> createInvite(String tripId, {String? name}) async => TripInvite('K7MPQ2', DateTime(2026, 10, 30));

  @override
  Future<({String tripId, String title})> join(String code, {required String name}) async =>
      (tripId: 'japan', title: 'Japan holiday');

  @override
  Future<void> removeMember(String tripId, String memberId) async {}
}

/// The keyboard never hides what's being typed, and never outlives it.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  /// A phone of [size] points with the keyboard down.
  void usePhone(WidgetTester tester, {Size size = const Size(390, 844)}) {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// The keyboard comes up, [height] points tall.
  Future<void> showKeyboard(WidgetTester tester, {double height = 336}) async {
    tester.view.viewInsets = FakeViewPadding(bottom: height * 3);
    await tester.pumpAndSettle();
  }

  void expectAboveKeyboard(WidgetTester tester, Finder finder) {
    final keyboardTop =
        (tester.view.physicalSize.height - tester.view.viewInsets.bottom) / tester.view.devicePixelRatio;
    expect(tester.getRect(finder).bottom, lessThanOrEqualTo(keyboardTop), reason: '$finder is behind the keyboard');
  }

  /// A page with ways into the sheets, over a holiday the traveller has
  /// the Annual Pass for and hasn't named themselves on yet.
  Future<void> pumpHome(WidgetTester tester) async {
    final start = LocalDate.fromDateTime(DateTime.now()).addDays(100);
    final trip = Trip(
      id: 'japan',
      title: 'Japan holiday',
      ownerId: 'me',
      memberIds: const ['me'],
      plannedStart: start,
      plannedEnd: start.addDays(18),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final repository = MemoryTravelRepository(userId: 'me')..putTrip(trip);
    final purchases = TestPurchaseService(
      initial: Entitlements.none.copyWith(plus: PlusSubscription(expiresAt: DateTime(2100))),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          appSessionProvider(),
          ChangeNotifierProvider(
            create: (_) =>
                TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), sharing: _FakeSharing()),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: purchases)),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          builder: (context, child) => KeyboardGuard(child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute<void>(builder: (_) => const TripScreen(tripId: 'japan'))),
                      child: const Text('Open the trip'),
                    ),
                    TextButton(onPressed: () => showJoinTripSheet(context), child: const Text('Join a trip')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTrip(WidgetTester tester) async {
    await tester.tap(find.text('Open the trip'));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTripTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.descendant(of: find.byType(TripScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  group('sheets sit above the keyboard', () {
    testWidgets('inviting the family: the name and its button show while typing', (tester) async {
      usePhone(tester);
      await pumpHome(tester);
      await openTrip(tester);
      await scrollTripTo(tester, find.text('Invite'));
      await tester.tap(find.text('Invite'));
      await tester.pumpAndSettle();
      await showKeyboard(tester);

      expectAboveKeyboard(tester, find.widgetWithText(TextField, 'Your name'));
      expectAboveKeyboard(tester, find.text('Create invite'));
    });

    testWidgets('on an iPhone SE the invite sheet scrolls rather than overflow', (tester) async {
      usePhone(tester, size: const Size(320, 568));
      await pumpHome(tester);
      await openTrip(tester);
      await scrollTripTo(tester, find.text('Invite'));
      await tester.tap(find.text('Invite'));
      await tester.pumpAndSettle();
      await showKeyboard(tester, height: 253);

      expect(tester.takeException(), isNull);
      expectAboveKeyboard(tester, find.widgetWithText(TextField, 'Your name'));
      await tester.ensureVisible(find.text('Create invite'));
      await tester.pumpAndSettle();
      expectAboveKeyboard(tester, find.text('Create invite'));
    });

    testWidgets('joining a trip: the code, the name and Join trip show while typing', (tester) async {
      usePhone(tester);
      await pumpHome(tester);
      await tester.tap(find.text('Join a trip'));
      await tester.pumpAndSettle();
      await showKeyboard(tester);

      expectAboveKeyboard(tester, find.widgetWithText(TextField, 'Invite code'));
      expectAboveKeyboard(tester, find.widgetWithText(TextField, 'Your name'));
      expectAboveKeyboard(tester, find.text('Join trip'));
    });

    testWidgets('something to do before you go: its words show while typing', (tester) async {
      usePhone(tester);
      await pumpHome(tester);
      await openTrip(tester);
      await scrollTripTo(tester, find.byKey(const ValueKey('checklist-add')));
      await tester.tap(find.byKey(const ValueKey('checklist-add')));
      await tester.pumpAndSettle();
      await showKeyboard(tester);

      expectAboveKeyboard(tester, find.byKey(const ValueKey('checklist-text')));
    });
  });

  group('the keyboard goes when nothing is typing', () {
    Future<void> pumpField(WidgetTester tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => KeyboardGuard(child: child!),
          home: const Scaffold(body: TextField(autofocus: true)),
        ),
      );
      await tester.pumpAndSettle();
      await showKeyboard(tester);
      expect(tester.testTextInput.isVisible, isTrue);
    }

    testWidgets('iOS bringing the keyboard back after letting go of the field', (tester) async {
      await pumpField(tester);
      // iOS drops the keyboard as the app goes briefly inactive: the field
      // lets go, and Flutter leaves the keyboard to iOS.
      tester.testTextInput.closeConnection();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.context?.widget, isNot(isA<EditableText>()));
      expect(tester.testTextInput.isVisible, isTrue, reason: 'Flutter alone never hides it');

      // iOS puts it back up.
      await showKeyboard(tester, height: 300);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('coming back to the app with a keyboard and nothing to type in', (tester) async {
      await pumpField(tester);
      tester.testTextInput.closeConnection();
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('a field that has the keyboard keeps it, as does one opening on the next screen', (tester) async {
      await pumpField(tester);
      await showKeyboard(tester, height: 300);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.testTextInput.isVisible, isTrue);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: TextField(key: ValueKey('next'), autofocus: true)),
        ),
      );
      await tester.pumpAndSettle();
      await showKeyboard(tester, height: 310);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(
        FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextField>()?.key,
        const ValueKey('next'),
      );
    });

    testWidgets('leaving the Documents tab puts its search keyboard away', (tester) async {
      usePhone(tester, size: const Size(640, 1000));
      final repository = MemoryTravelRepository();
      final now = DateTime(2026, 10, 14, 11, 0);
      final demo = buildDemoData(LocalDate.fromDateTime(now), userId: repository.userId);
      repository.replaceAll(demo.trips, demo.bookings);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), clock: () => now),
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
          child: MaterialApp(theme: buildTravaryTheme(), home: const HomeShell()),
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'Documents');
      await tester.showKeyboard(find.descendant(of: find.byType(WalletScreen), matching: find.byType(TextField)));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      await openTab(tester, 'Trips');
      expect(tester.testTextInput.isVisible, isFalse);
    });
  });
}
