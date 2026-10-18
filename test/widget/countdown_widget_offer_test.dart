import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/data/countdown_widget_settings.dart';
import 'package:travary/design/art/art_slots.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/countdown_trip_hero.dart';
import 'package:travary/design/widgets/nav_bar.dart';
import 'package:travary/features/profile/profile_screen.dart';
import 'package:travary/logic/countdown_widget_setup.dart';
import 'package:travary/state/countdown_widget_store.dart';

import '../support/countdown_today.dart';
import '../support/home_widget.dart';
import '../support/open_tab.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

  late FakeHomeWidget phone;
  late MemoryCountdownWidgetSettings settings;

  /// Today between trips (the countdown), on a phone that says [status].
  Future<void> pump(
    WidgetTester tester, {
    HomeWidgetStatus status = androidPhone,
    MemoryCountdownWidgetSettings? saved,
    Size size = const Size(390, 844),
    double textScale = 1,
    bool withStore = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    phone = FakeHomeWidget(status);
    settings = saved ?? MemoryCountdownWidgetSettings();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      countdownTodayApp(
        extraProviders: [
          if (withStore)
            ChangeNotifierProvider(
              create: (_) => CountdownWidgetStore(bridge: phone, settings: settings)..start(),
            ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  CountdownWidgetStore store(WidgetTester tester) =>
      tester.element(find.byType(HomeShell)).read<CountdownWidgetStore>();

  Finder note() => find.byKey(const ValueKey('countdown-widget-note'));
  Finder action() => find.byKey(const ValueKey('widget-sheet-action'));
  Finder step(int i) => find.byKey(ValueKey('widget-sheet-step-$i'));

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(note());
    await tester.pumpAndSettle();
  }

  group('beside the countdown tag', () {
    testWidgets('offers the widget in a note under the packing list', (tester) async {
      await pump(tester);
      expect(note(), findsOneWidget);
      expect(find.text('Home screen'), findsOneWidget);
      expect(find.text('Add this countdown ›', findRichText: true), findsOneWidget);
      expect(find.text('Packing list'), findsOneWidget, reason: 'the packing list is still there');
      expect(
        tester.getTopLeft(note()).dy,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey('countdown-note'))).dy),
        reason: 'under it',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a 390 × 844 phone it is on screen, above the tabs and clear of the tag', (tester) async {
      await pump(tester);
      final line = tester.getRect(note());
      final words = tester.getRect(find.descendant(of: note(), matching: find.text('Home screen')));
      final hero = tester.getRect(find.byType(CountdownTripHero));
      expect(words.bottom, lessThan(tester.getRect(find.byType(TravaryNavBar)).top), reason: 'no scrolling to find it');
      expect(line.bottom, lessThanOrEqualTo(hero.bottom), reason: 'inside the countdown, which keeps its size');
      expect(hero.height, lessThanOrEqualTo(844 * CountdownLayout.stageMaxHeight + 47 + 0.5));
      final raster = tester.renderObject<RenderBox>(find.byKey(const ValueKey('countdown-tag-raster')));
      final body = SurfaceSlot.countdownTag.body!;
      final tagLeft = [
        for (final y in [body.top, body.bottom])
          raster.localToGlobal(Offset(body.left * raster.size.width, y * raster.size.height)).dx,
      ].reduce(math.min);
      expect(line.right, lessThanOrEqualTo(tagLeft), reason: 'clear of the tag');
    });

    testWidgets('says nothing where the phone can\'t have the widget', (tester) async {
      await pump(tester, status: oldiPhone);
      expect(note(), findsNothing);
      expect(find.text('Packing list'), findsOneWidget);
    });

    testWidgets('says nothing once the widget is on the home screen', (tester) async {
      await pump(tester, status: (supported: true, added: true, canPin: true));
      expect(note(), findsNothing);
    });

    testWidgets('says nothing without the setup (tests, web)', (tester) async {
      await pump(tester, withStore: false);
      expect(note(), findsNothing);
      expect(find.text('Packing list'), findsOneWidget);
    });

    testWidgets('"Not now" in the sheet puts it away for good', (tester) async {
      await pump(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('widget-sheet-not-now')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('widget-sheet-ticket')), findsNothing, reason: 'closes the sheet');
      expect(note(), findsNothing);
      expect(settings.choice.declined, isTrue);

      // Next time the app opens on this phone.
      await pump(tester, saved: settings);
      expect(note(), findsNothing);
    });

    testWidgets('"Got it" leaves it where it is', (tester) async {
      await pump(tester, status: iPhone);
      await openSheet(tester);
      await tester.tap(action());
      await tester.pumpAndSettle();
      expect(note(), findsOneWidget);
      expect(settings.choice.declined, isFalse);
    });

    testWidgets('a small phone with large text fits it', (tester) async {
      await pump(tester, size: const Size(320, 568), textScale: 1.6);
      expect(note(), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The countdown itself needs a scroll on a phone this small.
      await tester.ensureVisible(note());
      await tester.pumpAndSettle();
      await openSheet(tester);
      expect(action(), findsOneWidget);
      expect(find.byKey(const ValueKey('widget-sheet-not-now')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the sheet on Android', () {
    testWidgets('asks the launcher to place it with one button, and shows no steps', (tester) async {
      await pump(tester);
      await openSheet(tester);
      expect(find.byKey(const ValueKey('widget-sheet-ticket')), findsOneWidget);
      expect(find.text('Your countdown, on your home screen'), findsOneWidget);
      expect(find.text('Add to home screen'), findsOneWidget);
      expect(step(0), findsNothing);

      await tester.tap(action());
      await tester.pumpAndSettle();
      expect(phone.pins, 1);
      expect(find.byKey(const ValueKey('widget-sheet-refused')), findsNothing);
      expect(action(), findsOneWidget, reason: 'the launcher\'s dialog is its own; the sheet waits');
    });

    testWidgets('a launcher that won\'t show its dialog gets the steps instead', (tester) async {
      await pump(tester);
      phone.launcherAsks = false;
      await openSheet(tester);
      await tester.tap(action());
      await tester.pumpAndSettle();
      expect(find.text(countdownWidgetPinRefused), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        expect(step(i), findsOneWidget);
      }
      expect(find.textContaining('Widgets'), findsWidgets);
    });

    testWidgets('a launcher with no way to be asked starts on the steps', (tester) async {
      await pump(tester, status: (supported: true, added: false, canPin: false));
      await openSheet(tester);
      expect(step(0), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      expect(phone.pins, 0);
    });

    testWidgets('when the widget lands, the open sheet says so', (tester) async {
      await pump(tester);
      await openSheet(tester);
      await tester.tap(action());
      await tester.pumpAndSettle();

      // The traveller placed it; the app comes back and asks the phone.
      phone.add();
      await store(tester).refresh();
      await tester.pumpAndSettle();
      expect(find.text('It’s on your home screen'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(step(0), findsNothing);
      expect(find.byKey(const ValueKey('widget-sheet-refused')), findsNothing);

      await tester.tap(action());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('widget-sheet-ticket')), findsNothing);
      expect(note(), findsNothing);
    });
  });

  group('the sheet on iOS', () {
    testWidgets('can\'t add it, so it shows how, step by step', variant: iOS, (tester) async {
      await pump(tester, status: iPhone);
      await openSheet(tester);
      expect(find.text('Your countdown, on your home screen'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        expect(step(i), findsOneWidget);
      }
      expect(find.textContaining('Add Widget'), findsOneWidget);
      expect(find.text('Add to home screen'), findsNothing);
      expect(phone.pins, 0, reason: 'iOS has no call for it');

      await tester.tap(action());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('widget-sheet-ticket')), findsNothing, reason: '"Got it" closes it');
      expect(note(), findsOneWidget, reason: 'until the widget is actually there');
    });

    testWidgets('large text on a small phone still reaches the button', variant: iOS, (tester) async {
      await pump(tester, status: iPhone, size: const Size(320, 568), textScale: 1.6);
      await tester.ensureVisible(note());
      await tester.pumpAndSettle();
      await openSheet(tester);
      expect(tester.takeException(), isNull);
      expect(tester.getRect(action()).bottom, lessThanOrEqualTo(568));
      await tester.tap(action());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('widget-sheet-ticket')), findsNothing);
    });
  });

  group('in Profile', () {
    Finder row() => find.byKey(const ValueKey('profile-widget'));

    Future<void> reachRow(WidgetTester tester) async {
      await openTab(tester, 'Profile');
      await tester.scrollUntilVisible(
        row(),
        200,
        scrollable: find.descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable)).first,
      );
    }

    /// Not half under the home tabs.
    Future<void> tapRow(WidgetTester tester) async {
      await tester.ensureVisible(row());
      await tester.pumpAndSettle();
      await tester.tap(row());
      await tester.pumpAndSettle();
    }

    testWidgets('a Home screen section is always there to set it up', (tester) async {
      await pump(tester);
      await reachRow(tester);
      expect(find.text('HOME SCREEN'), findsOneWidget);
      expect(find.text('Countdown widget'), findsOneWidget);
      expect(find.text('See the days to go from your home screen. Free.'), findsOneWidget);

      await tapRow(tester);
      expect(find.text('Your countdown, on your home screen'), findsOneWidget);
    });

    testWidgets('stays after "Not now" on Today', (tester) async {
      await pump(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('widget-sheet-not-now')));
      await tester.pumpAndSettle();
      await reachRow(tester);
      expect(row(), findsOneWidget);
    });

    testWidgets('says when it is on the home screen', (tester) async {
      await pump(tester, status: (supported: true, added: true, canPin: true));
      await reachRow(tester);
      expect(find.text('On your home screen'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

      await tapRow(tester);
      expect(find.text('It’s on your home screen'), findsOneWidget);
    });

    testWidgets('has no row where the phone can\'t have the widget', (tester) async {
      await pump(tester, status: oldiPhone);
      await openTab(tester, 'Profile');
      expect(row(), findsNothing);
      expect(find.text('HOME SCREEN'), findsNothing);
    });

    testWidgets('fits a small phone with large text', (tester) async {
      await pump(tester, size: const Size(320, 568), textScale: 1.6);
      await reachRow(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
