import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:travary/app/home_shell.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/onboarding_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/cards/booking_card.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/nav_bar.dart';
import 'package:travary/design/widgets/travi_player.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/domain/onboarding.dart';
import 'package:travary/features/booking/booking_detail_screen.dart';
import 'package:travary/features/booking/edit_booking_screen.dart';
import 'package:travary/features/onboarding/onboarding_screen.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/logic/destinations.dart';
import 'package:travary/state/onboarding_store.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/canonical_today.dart';
import '../support/countdown_today.dart';
import '../support/open_tab.dart';
import '../support/session.dart';

/// Travary on screens other than a phone held upright: iPads (portrait,
/// landscape and a split-screen window), Android tablets, foldables (the
/// iPhone Duo folded and open, a Galaxy Fold open) and, for comparison,
/// phones. Onboarding and the pass desk fit without scrolling and Travi
/// stands whole on the stage; the home tabs keep a readable width.
///
/// With `TRAVARY_VISUAL_QA=1` (run by `tool/visual_qa.sh`) it loads the
/// app's real fonts and writes `build/visual_qa/large/<screen>_<device>.png`.
void main() {
  const outDir = 'build/visual_qa';
  final qa = Platform.environment['TRAVARY_VISUAL_QA'] == '1';

  setUpAll(() async {
    TravaryText.useGoogleFonts = false;
    if (qa) await _loadFonts(p.join(outDir, 'fonts'));
  });
  tearDownAll(() {
    TravaryText.serifFamily = null;
    TravaryText.sansFamily = null;
  });

  Future<void> setScreen(WidgetTester tester, _Device device) async {
    tester.view.physicalSize = device.size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = device.padding;
    tester.view.viewPadding = device.padding;
    addTearDown(tester.view.reset);
  }

  Future<void> capture(WidgetTester tester, GlobalKey boundary, String name) async {
    expect(tester.takeException(), isNull, reason: name);
    if (!qa) return;
    await _precacheImages(tester);
    final image = await tester.runAsync(() async {
      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return render.toImage(pixelRatio: 1);
    });
    await tester.runAsync(() async {
      await Directory(p.join(outDir, 'large')).create(recursive: true);
      final png = await image!.toByteData(format: ui.ImageByteFormat.png);
      await File(p.join(outDir, 'large', '$name.png')).writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<GlobalKey> pumpOnboarding(WidgetTester tester, OnboardingDraft draft, {bool saved = false}) async {
    final repository = MemoryTravelRepository(userId: 'me');
    final place = draft.destination;
    if (place != null) {
      repository.putTrip(
        Trip(
          id: 'holiday',
          title: '${place.name} holiday',
          destination: place,
          plannedStart: const LocalDate(2026, 11, 8),
          plannedEnd: const LocalDate(2026, 11, 15),
          ownerId: 'me',
          memberIds: const ['me'],
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
        ),
      );
    }
    if (saved) await repository.saveBooking(_booking);
    final setup = OnboardingStore(repository: MemoryOnboardingRepository(draft));
    await setup.load();
    addTearDown(setup.dispose);
    final boundary = GlobalKey();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MultiProvider(
          providers: [
            appSessionProvider(auth: FakeAuthService()),
            ChangeNotifierProvider(
              create: (_) => TravelStore(
                repository: repository,
                artCatalog: const ArtCatalog.empty(),
                clock: () => DateTime(2026, 10, 9),
              ),
            ),
            ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
            ChangeNotifierProvider.value(value: setup),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTravaryTheme(),
            home: OnboardingScreen(onFinished: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return boundary;
  }

  Future<GlobalKey> pumpPaywall(WidgetTester tester) async {
    final now = DateTime(2026, 10, 5, 9);
    final repository = MemoryTravelRepository(userId: 'me')
      ..replaceAll([
        trip(
          'france',
          title: 'France holiday',
          plannedStart: d(10, 23),
          plannedEnd: d(11, 6),
        ).copyWith(destination: countryPlace('FR').destination),
      ], const []);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MultiProvider(
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
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTravaryTheme(),
            home: const PaywallScreen(tripId: 'france', source: 'test'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return boundary;
  }

  final france = countryPlace('FR').destination;
  final holiday = OnboardingDraft(
    step: OnboardingStep.booking,
    destination: france,
    start: const LocalDate(2026, 11, 8),
    end: const LocalDate(2026, 11, 15),
    tripId: 'holiday',
  );

  // Travi's frame, wholly on screen; the same from beat to beat.
  Rect travi(WidgetTester tester, _Device device) {
    final frame = tester.getRect(find.byType(TraviPlayer));
    expect((Offset.zero & device.size).contains(frame.topLeft), isTrue, reason: device.name);
    expect(frame.right, lessThanOrEqualTo(device.size.width + .01), reason: device.name);
    return frame;
  }

  // Nothing to scroll to reach the controls (the real type decides; the
  // test font is far wider).
  void fits(WidgetTester tester, _Device device, String beat) {
    if (TravaryText.serifFamily == null) return;
    final scroll = tester.state<ScrollableState>(
      find.descendant(of: find.byKey(const ValueKey('onboarding-scroll')), matching: find.byType(Scrollable)),
    );
    expect(scroll.position.maxScrollExtent, 0, reason: '$beat on ${device.name}: nothing to scroll');
  }

  for (final device in _devices) {
    testWidgets('onboarding on ${device.name}: every beat on one screen, Travi on one mark', (tester) async {
      await setScreen(tester, device);
      final beats = [
        ('welcome', const OnboardingDraft(), false, 'Choose my destination'),
        ('dates', holiday.copyWith(step: OnboardingStep.dates), false, 'Choose my dates'),
        ('booking', holiday, false, 'Smart Import'),
        ('proof', holiday.copyWith(bookingId: _booking.id), true, 'See how I can help'),
      ];
      Rect? mark;
      for (final (beat, draft, saved, action) in beats) {
        final boundary = await pumpOnboarding(tester, draft, saved: saved);
        await capture(tester, boundary, '${beat}_${device.name}');
        final frame = travi(tester, device);
        expect(frame, mark ?? frame, reason: '$beat on ${device.name}: the camera never moves');
        mark = frame;
        expect(find.text(action).hitTestable(), findsOneWidget, reason: '$beat on ${device.name}');
        if (device.size.height >= 678) fits(tester, device, beat);
      }
    });

    testWidgets('the pass desk on ${device.name}: passes, button and links on one screen', (tester) async {
      await setScreen(tester, device);
      final boundary = await pumpPaywall(tester);
      await capture(tester, boundary, 'desk_${device.name}');
      travi(tester, device);
      if (TravaryText.serifFamily == null) return;
      fits(tester, device, 'desk');
      for (final key in [
        'onboarding-pass-annual',
        'onboarding-pass-buy',
        'onboarding-pass-free',
        'onboarding-pass-privacy',
      ]) {
        expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget, reason: '$key on ${device.name}');
        expect(
          tester.getRect(find.byKey(ValueKey(key))).bottom,
          lessThanOrEqualTo(device.size.height - device.bottom),
          reason: '$key on ${device.name}',
        );
      }
    });

    testWidgets('home on ${device.name}', (tester) async {
      await setScreen(tester, device);
      var boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: boundary, child: canonicalTodayApp()));
      await tester.pumpAndSettle();
      await capture(tester, boundary, 'today_${device.name}');
      // The day's cards and the tabs keep a phone's proportions, centred.
      final width = device.size.width;
      final column = Rect.fromCenter(
        center: Offset(width / 2, 0),
        width: math.min(width, ScreenLayout.readableWidth) + .01,
        height: 1e6,
      );
      final cards = find.byType(BookingCard).hitTestable();
      expect(cards, findsWidgets);
      for (var i = 0; i < cards.evaluate().length; i++) {
        final rect = tester.getRect(cards.at(i));
        expect(column.left <= rect.left && rect.right <= column.right, isTrue, reason: '$rect on ${device.name}');
      }
      final tabs = tester.getRect(find.descendant(of: find.byType(TravaryNavBar), matching: find.byType(Row)).first);
      expect(tabs.width, lessThanOrEqualTo(ScreenLayout.navWidth), reason: device.name);
      expect((tabs.center.dx - width / 2).abs(), lessThan(1), reason: device.name);
      await openTab(tester, 'Trips');
      await capture(tester, boundary, 'trips_${device.name}');
      await openTab(tester, 'Documents');
      await capture(tester, boundary, 'documents_${device.name}');
      await openTab(tester, 'Profile');
      await capture(tester, boundary, 'profile_${device.name}');
      // A booking's page and the form for a new one, over the tabs.
      final navigator = Navigator.of(tester.element(find.byType(HomeShell)));
      unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => const BookingDetailScreen(bookingId: 'hotel'))));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await capture(tester, boundary, 'booking_detail_${device.name}');
      unawaited(
        navigator.push(MaterialPageRoute<void>(builder: (_) => const EditBookingScreen(kind: BookingKind.stay))),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await capture(tester, boundary, 'form_${device.name}');

      await tester.runAsync(
        () => _preloadFiles(countdownPostcardSourcePacks().map((pack) => pack.common.values.first.path)),
      );
      boundary = GlobalKey();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(RepaintBoundary(key: boundary, child: countdownTodayApp()));
      await tester.pumpAndSettle();
      await capture(tester, boundary, 'countdown_${device.name}');
      // A trip's own page, over the tabs.
      unawaited(
        Navigator.of(
          tester.element(find.byType(HomeShell)),
        ).push(MaterialPageRoute<void>(builder: (_) => const TripScreen(tripId: 'lakes'))),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await capture(tester, boundary, 'trip_${device.name}');
    });
  }
}

final _booking = Booking(
  id: 'first-booking',
  tripId: 'holiday',
  kind: BookingKind.stay,
  title: 'Lagoon Retreat',
  startDate: const LocalDate(2026, 11, 8),
  endDate: const LocalDate(2026, 11, 10),
  createdAt: DateTime(2026, 10, 9),
  updatedAt: DateTime(2026, 10, 9),
);

class _Device {
  const _Device(this.name, this.size, {this.top = 24, this.bottom = 20});
  final String name;
  final Size size;
  final double top;
  final double bottom;
  FakeViewPadding get padding => FakeViewPadding(top: top, bottom: bottom);
}

const _devices = [
  // Phones, for comparison: unchanged.
  _Device('iphone_390x844', Size(390, 844), top: 47, bottom: 34),
  _Device('android_412x915', Size(412, 915), top: 24, bottom: 24),
  // The iPhone Duo, folded (its cover screen) and open, upright and turned.
  _Device('duo_cover_466x678', Size(466, 678), top: 44, bottom: 21),
  _Device('duo_open_626x890', Size(626, 890)),
  _Device('duo_open_890x626', Size(890, 626)),
  // iPads: the 4:3 one from the screenshots, an 11-inch, a 13-inch, turned,
  // and half a landscape screen in Split View.
  _Device('ipad_810x1080', Size(810, 1080), top: 20, bottom: 0),
  _Device('ipad_820x1180', Size(820, 1180)),
  _Device('ipad_1032x1376', Size(1032, 1376)),
  _Device('ipad_1180x820', Size(1180, 820)),
  _Device('ipad_1376x1032', Size(1376, 1032)),
  _Device('ipad_split_590x820', Size(590, 820)),
  // Android: a Galaxy Fold open, a tablet upright, the Pixel Tablet turned.
  _Device('fold_open_707x823', Size(707, 823), top: 32, bottom: 24),
  _Device('tablet_800x1280', Size(800, 1280), top: 24, bottom: 48),
  _Device('tablet_1280x800', Size(1280, 800), top: 24, bottom: 48),
];

Future<void> _loadFonts(String dir) async {
  final folder = Directory(dir);
  if (!folder.existsSync()) {
    // ignore: avoid_print
    print('No fonts in $dir: run tool/visual_qa.sh. Rendering with the test font.');
    return;
  }
  final files = folder.listSync().whereType<File>().toList();
  Future<void> load(String family, bool Function(String) matches) async {
    final loader = FontLoader(family);
    var any = false;
    for (final file in files.where((f) => matches(p.basename(f.path)))) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      any = true;
    }
    if (any) await loader.load();
  }

  await load('Source Serif 4', (name) => name.startsWith('SourceSerif4'));
  await load('Inter', (name) => name.startsWith('Inter'));
  await load('MaterialIcons', (name) => name.startsWith('MaterialIcons'));
  TravaryText.serifFamily = 'Source Serif 4';
  TravaryText.sansFamily = 'Inter';
}

Future<void> _preloadFiles(Iterable<String> paths) async {
  for (final path in paths) {
    final stream = FileImage(File(path)).resolve(ImageConfiguration.empty);
    final done = Future<void>(() async {
      final completer = Completer<void>();
      stream.addListener(
        ImageStreamListener(
          (_, _) => completer.isCompleted ? null : completer.complete(),
          onError: (error, stack) => completer.isCompleted ? null : completer.completeError(error, stack),
        ),
      );
      await completer.future;
    });
    await done;
  }
}

/// Decodes every bundled picture on screen, so the render shows real art.
Future<void> _precacheImages(WidgetTester tester) async {
  for (var pass = 0; pass < 2; pass++) {
    // Only bundled pictures: a file whose load began under the test clock
    // would never finish.
    final elements = find
        .byType(Image)
        .evaluate()
        .where((e) => (e.widget as Image).image is AssetBundleImageProvider)
        .toList();
    await tester.runAsync(() async {
      for (final element in elements) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    // Some screens keep a cameo moving: a few frames, not a settle.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}
