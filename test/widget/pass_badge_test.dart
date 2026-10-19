import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/demo_data.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/pass_badge.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/today/today_screen.dart';
import 'package:travary/features/trips/trips_screen.dart';
import 'package:travary/logic/access.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../support/canonical_today.dart';
import '../support/countdown_today.dart';
import '../support/open_tab.dart';
import '../support/trip_postcards.dart';

void main() {
  final now = DateTime(2026, 10, 19, 20, 21);
  final qa = Platform.environment['TRAVARY_PASS_QA'] == '1';
  final boundary = GlobalKey();

  setUpAll(() async {
    TravaryText.useGoogleFonts = false;
    if (qa) {
      for (final (family, prefix) in [
        ('Source Serif 4', 'SourceSerif4'),
        ('Inter', 'Inter'),
        ('MaterialIcons', 'MaterialIcons'),
      ]) {
        final loader = FontLoader(family);
        for (final file in Directory('build/visual_qa/fonts').listSync().whereType<File>()) {
          if (file.uri.pathSegments.last.startsWith(prefix)) {
            loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
          }
        }
        await loader.load();
      }
      TravaryText.serifFamily = 'Source Serif 4';
      TravaryText.sansFamily = 'Inter';
    }
  });
  tearDownAll(() {
    TravaryText.serifFamily = null;
    TravaryText.sansFamily = null;
  });

  Future<void> pump(WidgetTester tester, {double width = 402, double scale = 1}) async {
    tester.view.physicalSize = Size(width * 2, 1748);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MediaQuery(
          data: MediaQueryData(size: Size(width, 874), textScaler: TextScaler.linear(scale)),
          child: countdownTodayApp(
            now: now,
            data: buildDemoData(LocalDate.fromDateTime(now), userId: 'me'),
            catalog: bundledArtCatalog().withPacks([...tripPostcardSourcePacks(), ...countdownPostcardSourcePacks()]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!qa) return;
    final images = [
      for (final element in find.byType(Image).evaluate())
        ((element.widget as Image).image, createLocalImageConfiguration(element)),
    ];
    imageCache
      ..clear()
      ..clearLiveImages();
    await tester.runAsync(() async {
      for (final (provider, config) in images) {
        final done = Completer<void>();
        final stream = provider.resolve(config);
        final listener = ImageStreamListener(
          (_, _) {
            if (!done.isCompleted) done.complete();
          },
          onError: (Object error, StackTrace? stack) {
            if (!done.isCompleted) done.complete();
          },
        );
        stream.addListener(listener);
        await done.future;
        stream.removeListener(listener);
      }
    });
    // Rebind the widgets to the decoded streams without the global hot
    // reload hook, which would flush the image cache again.
    for (final element in find.byType(Image).evaluate()) {
      // This debug-only hook is confined to the optional screenshot harness.
      // ignore: invalid_use_of_protected_member
      element.reassemble();
    }
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('docs/mockups/purchased-passes-v1/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
  }

  Finder badges(Type screen) => find.descendant(of: find.byType(screen), matching: find.byType(PassBadge));

  testWidgets('purchase updates Today and only the paid holiday; annual and revoked states update live', (
    tester,
  ) async {
    await pump(tester);
    final context = tester.element(find.byType(TodayScreen));
    final premium = context.read<PremiumStore>();
    final travel = context.read<TravelStore>();
    expect(badges(TodayScreen), findsNothing);

    final holiday = newTripPassFor(travel.plan('demo-orlando')!);
    premium.debugSetEntitlements(Entitlements(tripPasses: {holiday.tripId: holiday}));
    await tester.pumpAndSettle();
    expect(tester.widget<PassBadge>(badges(TodayScreen)).kind, OfferKind.tripPass);
    await capture(tester, 'holiday-today');
    await openTab(tester, 'Trips');
    expect(badges(TripsScreen), findsOneWidget);
    await capture(tester, 'holiday-trips');

    premium.debugSetEntitlements(Entitlements(plus: PlusSubscription(expiresAt: now.add(const Duration(days: 365)))));
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<PassBadge>(badges(TripsScreen)).every((badge) => badge.kind == OfferKind.plusAnnual),
      isTrue,
    );
    await capture(tester, 'annual-trips');
    await openTab(tester, 'Today');
    expect(tester.widget<PassBadge>(badges(TodayScreen)).kind, OfferKind.plusAnnual);
    await capture(tester, 'annual-today');

    premium.debugSetEntitlements(Entitlements.none);
    await tester.pumpAndSettle();
    expect(badges(TodayScreen), findsNothing);
    await openTab(tester, 'Trips');
    expect(badges(TripsScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paid headers fit a 320 point phone at large text size', (tester) async {
    await pump(tester, width: 320, scale: 2);
    expect(MediaQuery.textScalerOf(tester.element(find.byType(TodayScreen))).scale(14), 28);
    final premium = tester.element(find.byType(TodayScreen)).read<PremiumStore>();
    premium.debugSetEntitlements(Entitlements(plus: PlusSubscription(expiresAt: now.add(const Duration(days: 365)))));
    await tester.pumpAndSettle();
    expect(badges(TodayScreen), findsOneWidget);
    await openTab(tester, 'Trips');
    expect(badges(TripsScreen), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
