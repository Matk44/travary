import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/travi_player.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/premium/paywall_screen.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

/// The paywall (the pass desk) on the phones people use: the passes, the
/// button, "Not now" and the links all on screen at once with nothing to
/// scroll, Travi where he always stands, and as many benefits as there's
/// room for, unlimited bookings and the family first.
///
/// Always checks Travi's frame and the benefits' order. With
/// `TRAVARY_VISUAL_QA=1` (run by `tool/visual_qa.sh`) it loads the app's
/// real fonts, checks that nothing needs scrolling, and writes
/// `build/visual_qa/paywall_<w>x<h>.png`.
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

  // Width × height in points, and the bottom safe area.
  const phones = [
    (Size(375, 812), 34.0), // iPhone 13 mini
    (Size(390, 844), 34.0), // iPhone 14
    (Size(393, 852), 34.0), // iPhone 16
    (Size(412, 915), 24.0), // Pixel
    (Size(430, 932), 34.0), // iPhone 16 Plus
    (Size(440, 956), 34.0), // iPhone 16 Pro Max
  ];

  Future<void> pump(WidgetTester tester, Size size, double bottom, {required String name}) async {
    const dpr = 3.0;
    tester.view.physicalSize = size * dpr;
    tester.view.devicePixelRatio = dpr;
    tester.view.padding = FakeViewPadding(top: 47 * dpr, bottom: bottom * dpr);
    tester.view.viewPadding = FakeViewPadding(top: 47 * dpr, bottom: bottom * dpr);
    addTearDown(tester.view.reset);

    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: _paywall()));
    await tester.pumpAndSettle();
    if (!qa) return;
    await _precacheImages(tester);
    final image = await tester.runAsync(() async {
      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return render.toImage(pixelRatio: 2);
    });
    await tester.runAsync(() async {
      await Directory(outDir).create(recursive: true);
      final png = await image!.toByteData(format: ui.ImageByteFormat.png);
      await File(p.join(outDir, '$name.png')).writeAsBytes(png!.buffer.asUint8List());
    });
  }

  for (final (size, bottom) in phones) {
    final name = 'paywall_${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('a ${size.width.toInt()} × ${size.height.toInt()} phone sees it all without scrolling', (tester) async {
      await pump(tester, size, bottom, name: name);

      // Travi where he always stands, the whole frame wide, and the passes
      // under his shadow.
      expect(tester.getRect(find.byType(TraviPlayer)), Rect.fromLTWH(0, 0, size.width, size.width * 16 / 9));
      expect(
        tester.getRect(find.byKey(const ValueKey('onboarding-pass-holiday'))).top,
        greaterThan(size.width * 1.262),
      );
      // Whatever benefits fit, unlimited bookings and the family lead them.
      final family = find.text('Unlimited bookings, and the plan on every phone');
      for (final other in [
        'Every ticket and confirmation kept and backed up (free keeps 2)',
        "I'll read the rest of your confirmations for you",
      ]) {
        if (find.text(other).hitTestable().evaluate().isNotEmpty) expect(family.hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      // Fitting is a matter of the real type: the test font is far wider.
      if (TravaryText.serifFamily == null) return;
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: find.byKey(const ValueKey('onboarding-scroll')), matching: find.byType(Scrollable)),
      );
      expect(scroll.position.maxScrollExtent, 0, reason: 'nothing to scroll');
      // The button, free and the links all end above the home indicator.
      for (final key in [
        'onboarding-pass-annual',
        'onboarding-pass-buy',
        'onboarding-pass-free',
        'onboarding-pass-privacy',
      ]) {
        expect(tester.getRect(find.byKey(ValueKey(key))).bottom, lessThanOrEqualTo(size.height - bottom), reason: key);
        expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget, reason: key);
      }
      expect(family.hitTestable(), findsOneWidget, reason: 'unlimited bookings and the family lead, on every phone');
      expect(tester.getSize(family).height, lessThan(24), reason: 'on one line');
    });
  }

  for (final (size, bottom) in phones) {
    final name = 'paywall_confirmed_${size.width.toInt()}x${size.height.toInt()}';
    testWidgets(
      'a ${size.width.toInt()} × ${size.height.toInt()} phone sees a bought pass confirmed without scrolling',
      (tester) async {
        await pump(tester, size, bottom, name: '${name}_desk');
        await tester.tap(find.byKey(const ValueKey('onboarding-pass-buy')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('pass-confirmed-badge')), findsOneWidget);
        expect(tester.getRect(find.byType(TraviPlayer)), Rect.fromLTWH(0, 0, size.width, size.width * 16 / 9));
        expect(tester.takeException(), isNull);
        if (TravaryText.serifFamily == null) return;
        final scroll = tester.state<ScrollableState>(
          find.descendant(of: find.byKey(const ValueKey('onboarding-scroll')), matching: find.byType(Scrollable)),
        );
        expect(scroll.position.maxScrollExtent, 0, reason: 'nothing to scroll');
        for (final key in ['pass-confirmed-badge', 'pass-confirmed-coverage', 'pass-confirmed-done']) {
          expect(
            tester.getRect(find.byKey(ValueKey(key))).bottom,
            lessThanOrEqualTo(size.height - bottom),
            reason: key,
          );
          expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget, reason: key);
        }
      },
    );
  }

  testWidgets('an iPhone SE scrolls to the button rather than covering Travi', (tester) async {
    await pump(tester, const Size(375, 667), 0, name: 'paywall_375x667');
    expect(tester.getRect(find.byType(TraviPlayer)), Rect.fromLTWH(0, 0, 375, 375 * 16 / 9));
    await tester.scrollUntilVisible(find.byKey(const ValueKey('onboarding-pass-buy')), 40);
    expect(find.byKey(const ValueKey('onboarding-pass-buy')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _paywall() {
  final now = DateTime(2026, 10, 5, 9);
  final repository = MemoryTravelRepository(userId: 'me')
    ..replaceAll([
      trip('japan', title: 'Japan holiday', plannedStart: d(11, 3), plannedEnd: d(11, 12)).copyWith(
        destination: const TripDestination(countryCode: 'JP', countryName: 'Japan'),
      ),
    ], const []);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => TravelStore(repository: repository, artCatalog: const ArtCatalog.empty(), clock: () => now),
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
      home: const PaywallScreen(tripId: 'japan', source: 'test'),
    ),
  );
}

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

/// Decodes every bundled picture on screen, so the render shows real art.
Future<void> _precacheImages(WidgetTester tester) async {
  for (var pass = 0; pass < 2; pass++) {
    final elements = find.byType(Image).evaluate().toList();
    await tester.runAsync(() async {
      for (final element in elements) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();
  }
}
