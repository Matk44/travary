import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/app/route_observer.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/reminder_scheduler.dart';
import 'package:travary/data/reminder_settings.dart';
import 'package:travary/data/onboarding_repository.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/art/art_bounds.dart';
import 'package:travary/design/cards/card_parts.dart';
import 'package:travary/design/widgets/profile_stationery.dart';
import 'package:travary/design/widgets/profile_travi.dart';
import 'package:travary/design/widgets/travi_player.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/features/profile/profile_screen.dart';
import 'package:travary/features/travel_documents/travel_documents_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';
import 'package:travary/state/reminders_store.dart';
import 'package:travary/state/onboarding_store.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';
import '../support/open_tab.dart';
import '../support/session.dart';
import '../support/travel_documents.dart';

void main() {
  final qa = Platform.environment['TRAVARY_VISUAL_QA'] == '1';
  setUpAll(() async {
    TravaryText.useGoogleFonts = false;
    if (!qa) return;
    final fonts = Directory('build/visual_qa/fonts').listSync().whereType<File>();
    for (final family in ['Source Serif 4', 'Inter', 'MaterialIcons']) {
      final prefix = family == 'Source Serif 4' ? 'SourceSerif4' : family;
      final loader = FontLoader(family);
      for (final file in fonts.where((f) => f.uri.pathSegments.last.startsWith(prefix))) {
        loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      }
      await loader.load();
    }
    TravaryText.serifFamily = 'Source Serif 4';
    TravaryText.sansFamily = 'Inter';
  });
  tearDownAll(() {
    TravaryText.serifFamily = null;
    TravaryText.sansFamily = null;
  });

  Future<void> capture(WidgetTester tester, GlobalKey boundary, String name) async {
    if (!qa) return;
    final shadowsWereDisabled = debugDisableShadows;
    debugDisableShadows = false;
    void repaintSurfaces() {
      for (final element in find.byType(DecoratedBox).evaluate()) {
        element.renderObject?.markNeedsPaint();
      }
    }

    try {
      repaintSurfaces();
      for (var pass = 0; pass < 2; pass++) {
        await tester.runAsync(() async {
          for (final element in find.byType(Image).evaluate().toList()) {
            await precacheImage((element.widget as Image).image, element);
          }
          for (final element in find.byType(TrimmedArt).evaluate().toList()) {
            final art = (element.widget as TrimmedArt).image;
            final stream = artImageProvider(art).resolve(createLocalImageConfiguration(element));
            final decoded = Completer<ImageInfo>();
            final listener = ImageStreamListener((info, _) => decoded.complete(info), onError: decoded.completeError);
            stream.addListener(listener);
            final info = await decoded.future;
            await ArtContentBounds.measure(art, info.image);
            stream.removeListener(listener);
            info.dispose();
          }
        });
        await tester.pumpAndSettle();
      }
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('build/visual_qa/$name.png').writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
    } finally {
      debugDisableShadows = shadowsWereDisabled;
      repaintSurfaces();
      await tester.pump();
    }
  }

  Future<GlobalKey> pumpProfile(
    WidgetTester tester, {
    Size size = const Size(402, 874),
    double scale = 1,
    Entitlements initial = Entitlements.none,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 62 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
    final data = countdownTodayData();
    final repository = MemoryTravelRepository(userId: 'me')..replaceAll(data.trips, data.bookings);
    final auth = FakeAuthService()..supported = {SignInMethod.apple, SignInMethod.google};
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  TravelStore(repository: repository, artCatalog: bundledArtCatalog(), clock: () => countdownNow),
            ),
            ChangeNotifierProvider(
              create: (_) => PremiumStore(
                purchases: TestPurchaseService(initial: initial, clock: () => countdownNow),
                clock: () => countdownNow,
              ),
            ),
            appSessionProvider(auth: auth),
            travelDocumentsProvider(),
            ChangeNotifierProvider(
              create: (context) => RemindersStore(
                scheduler: MemoryReminderScheduler(permitted: true),
                settings: MemoryReminderSettings(),
                travel: context.read<TravelStore>(),
              )..start(),
            ),
            ChangeNotifierProvider(create: (_) => OnboardingStore(repository: MemoryOnboardingRepository())..load()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: qa
                ? buildTravaryTheme().copyWith(textTheme: ThemeData().textTheme.apply(fontFamily: 'Inter'))
                : buildTravaryTheme(),
            navigatorObservers: [appRouteObserver],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const HomeShell(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'Profile');
    return boundary;
  }

  Finder profileScroll() => find.descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable));

  testWidgets('pleading Travi honours Reduce Motion and pauses under a hidden tab', (tester) async {
    final playback = TraviPlayer.playback;
    TraviPlayer.playback = true;
    addTearDown(() => TraviPlayer.playback = playback);
    Future<void> show({required bool reduced}) => tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: TickerMode(
            enabled: false,
            child: Center(child: SizedBox(width: 112, height: 124, child: ProfileTravi())),
          ),
        ),
      ),
    );
    await show(reduced: true);
    expect((tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName, ProfileTravi.stillAsset);
    await show(reduced: false);
    expect((tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName, ProfileTravi.animationAsset);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'profile shows the approved pleading Travi and opens the pass desk',
    (tester) async {
      final boundary = await pumpProfile(tester);
      await capture(tester, boundary, 'profile_guest');
      final slot = find.byKey(const ValueKey('profile-travi-slot'));
      await tester.scrollUntilVisible(slot, 150, scrollable: profileScroll());
      expect(tester.getSize(slot).height, 124);
      final travi = tester.widget<Image>(find.descendant(of: slot, matching: find.byType(Image)));
      expect((travi.image as AssetImage).assetName, ProfileTravi.stillAsset);
      await capture(tester, boundary, 'profile_pass');
      final buy = find.byKey(const ValueKey('profile-annual-pass'));
      await tester.scrollUntilVisible(buy, 100, scrollable: profileScroll());
      await Scrollable.ensureVisible(tester.element(buy), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(buy);
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'profile pocket opens the illustrated invitation inside Travel documents',
    (tester) async {
      final boundary = await pumpProfile(tester);
      final pocket = find.byKey(const ValueKey('profile-travel-documents'));
      await tester.scrollUntilVisible(pocket, 150, scrollable: profileScroll());
      await Scrollable.ensureVisible(tester.element(pocket), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(pocket);
      await tester.pumpAndSettle();
      expect(find.byType(TravelDocumentsScreen), findsOneWidget);
      final invite = find.byKey(const ValueKey('documents-invite'));
      expect(find.descendant(of: invite, matching: find.byType(PassportIllustration)), findsOneWidget);
      expect(find.text('Passports, visas and insurance'), findsOneWidget);
      await capture(tester, boundary, 'travel_documents_invitation');
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'small phone with double text keeps sign-in, restore and documents reachable',
    (tester) async {
      final boundary = await pumpProfile(tester, size: const Size(320, 568), scale: 2);
      expect(find.byType(ProfileTravi), findsNothing);
      for (final key in ['sign-in-apple', 'sign-in-google', 'profile-restore-purchases', 'profile-travel-documents']) {
        final action = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(action, 100, scrollable: profileScroll());
        await Scrollable.ensureVisible(tester.element(action), alignment: 0.5);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget, reason: key);
        expect(tester.takeException(), isNull, reason: key);
      }
      await tester.tap(find.byKey(const ValueKey('profile-travel-documents')));
      await tester.pumpAndSettle();
      await capture(tester, boundary, 'travel_documents_large_type');
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'every remaining profile section has a paper card and its actions remain reachable',
    (tester) async {
      final boundary = await pumpProfile(tester);
      for (final (key, name) in [
        ('profile-reminders-card', 'profile_reminders_data'),
        ('profile-data-card', 'profile_data'),
        ('profile-design-card', 'profile_design_tools'),
        ('profile-help-card', 'profile_help_legal_about'),
      ]) {
        final card = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(card, 150, scrollable: profileScroll());
        await Scrollable.ensureVisible(tester.element(card), alignment: 0.15);
        await tester.pumpAndSettle();
        expect(tester.widget<ProfilePaperCard>(card).kind, isNot(ProfilePaperKind.pocket));
        await capture(tester, boundary, name);
        expect(tester.takeException(), isNull);
      }
      final reminders = find.byKey(const ValueKey('profile-reminders'));
      await tester.scrollUntilVisible(reminders, -150, scrollable: profileScroll());
      await Scrollable.ensureVisible(tester.element(reminders), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(reminders);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(reminders).value, isTrue);

      for (final key in ['help-support', 'help-email', 'help-privacy', 'help-terms', 'profile-about-card']) {
        final action = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(action, 150, scrollable: profileScroll());
        await Scrollable.ensureVisible(tester.element(action), alignment: 0.5);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget, reason: key);
        expect(tester.takeException(), isNull, reason: key);
      }
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets('lower profile cards fit a small phone with double text', (tester) async {
    final boundary = await pumpProfile(tester, size: const Size(320, 568), scale: 2);
    for (final key in [
      'profile-reminders',
      'profile-data-card',
      'profile-design-card',
      'help-terms',
      'profile-about-card',
    ]) {
      final action = find.byKey(ValueKey(key));
      await tester.scrollUntilVisible(action, 150, scrollable: profileScroll());
      await Scrollable.ensureVisible(tester.element(action), alignment: 0.3);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: key);
    }
    await capture(tester, boundary, 'profile_lower_large_type');
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets(
    'Annual Pass holder sees renewal and restore without a repeat upsell',
    (tester) async {
      await pumpProfile(
        tester,
        initial: Entitlements(plus: PlusSubscription(expiresAt: DateTime(2027, 9, 28))),
      );
      final restore = find.byKey(const ValueKey('profile-restore-purchases'));
      await tester.scrollUntilVisible(restore, 150, scrollable: profileScroll());
      await Scrollable.ensureVisible(tester.element(restore), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-annual-pass')), findsNothing);
      expect(find.byType(ProfileTravi), findsNothing);
      expect(find.textContaining('Renews on'), findsOneWidget);
      await tester.tap(restore);
      await tester.pumpAndSettle();
      expect(restore.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'Annual Pass holders can manage or cancel it in their store; free users see no such link',
    (tester) async {
      final opened = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async {
          opened.add((call.arguments as Map)['url'] as String);
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        ),
      );
      final manage = find.byKey(const ValueKey('profile-manage-subscription'));
      final restore = find.byKey(const ValueKey('profile-restore-purchases'));

      await pumpProfile(tester);
      await tester.scrollUntilVisible(restore, 150, scrollable: profileScroll());
      expect(manage, findsNothing);

      await pumpProfile(
        tester,
        initial: Entitlements(plus: PlusSubscription(expiresAt: DateTime(2027, 9, 28))),
      );
      await tester.scrollUntilVisible(manage, 150, scrollable: profileScroll());
      await Scrollable.ensureVisible(tester.element(manage), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(manage);
      await tester.pumpAndSettle();
      final expected = debugDefaultTargetPlatformOverride == TargetPlatform.iOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions?sku=travary_annual_pass&package=com.travary.app';
      expect(opened, [expected]);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.android}),
  );
}
