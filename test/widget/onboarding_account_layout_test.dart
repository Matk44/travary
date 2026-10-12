import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/onboarding_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/domain/onboarding.dart';
import 'package:travary/features/onboarding/onboarding_account_screen.dart';
import 'package:travary/features/onboarding/onboarding_pass_screen.dart';
import 'package:travary/features/onboarding/onboarding_screen.dart';
import 'package:travary/logic/destinations.dart';
import 'package:travary/state/onboarding_store.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../support/session.dart';

/// The one-stage journey (dates → booking → saved → sign-in → email →
/// passes) on each kind of stage (Bali, a city, a country, Anywhere) at
/// small, standard and large phones and large type: nothing overflows and
/// every control stays reachable. `TRAVARY_ONBOARDING_QA=1` renders each
/// beat with the app's real fonts into `build/onboarding_stage/` (fonts
/// from `tool/visual_qa.sh`).
void main() {
  final qa = Platform.environment['TRAVARY_ONBOARDING_QA'] == '1';
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

  final places = {
    'bali': detectPlace('Bali')!.destination,
    'paris': detectPlace('Paris')!.destination,
    'japan': countryPlace('JP').destination,
    'iceland': countryPlace('IS').destination,
  };
  const sizes = {'320': Size(320, 568), '390': Size(390, 844), '430': Size(430, 932)};
  final booking = Booking(
    id: 'first-booking',
    tripId: 'holiday',
    kind: BookingKind.stay,
    title: 'Lagoon Retreat',
    startDate: const LocalDate(2026, 11, 8),
    endDate: const LocalDate(2026, 11, 10),
    createdAt: DateTime(2026, 10, 9),
    updatedAt: DateTime(2026, 10, 9),
  );

  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    required double scale,
    required TripDestination place,
    required OnboardingDraft draft,
    bool saved = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    final repository = MemoryTravelRepository(userId: 'me')
      ..putTrip(
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
    if (saved) await repository.saveBooking(booking);
    final setup = OnboardingStore(repository: MemoryOnboardingRepository(draft));
    await setup.load();
    addTearDown(setup.dispose);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MultiProvider(
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
          theme: qa
              ? buildTravaryTheme().copyWith(textTheme: buildTravaryTheme().textTheme.apply(fontFamily: 'Inter'))
              : buildTravaryTheme(),
          builder: (context, child) => RepaintBoundary(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true, textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
          home: OnboardingScreen(onFinished: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull, reason: name);
    if (!qa) return;
    await tester.runAsync(() async {
      final context = tester.element(find.byType(OnboardingScreen));
      await Future.wait(tester.widgetList<Image>(find.byType(Image)).map((i) => precacheImage(i.image, context)));
    });
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/onboarding_stage').create(recursive: true);
      await File('build/onboarding_stage/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: placeName, value: place) in places.entries) {
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      for (final scale in [1.0, 1.6]) {
        final name = '$placeName-$sizeName${scale == 1 ? '' : '-large'}';
        testWidgets('one stage, every beat: $name', (tester) async {
          final holiday = OnboardingDraft(
            step: OnboardingStep.booking,
            destination: place,
            start: const LocalDate(2026, 11, 8),
            end: const LocalDate(2026, 11, 15),
            tripId: 'holiday',
          );
          await pump(
            tester,
            size: size,
            scale: scale,
            place: place,
            draft: holiday.copyWith(step: OnboardingStep.dates),
          );
          await capture(tester, 'dates-$name');
          await pump(tester, size: size, scale: scale, place: place, draft: holiday);
          await capture(tester, 'booking-$name');
          await pump(
            tester,
            size: size,
            scale: scale,
            place: place,
            draft: holiday.copyWith(bookingId: booking.id),
            saved: true,
          );
          await capture(tester, 'proof-$name');
          await tap(tester, 'onboarding-see-passes');
          expect(find.byType(OnboardingAccountPanel), findsOneWidget);
          for (final key in ['sign-in-apple', 'sign-in-google', 'sign-in-email', 'onboarding-account-skip']) {
            await tester.ensureVisible(find.byKey(ValueKey(key)));
          }
          await tester.drag(find.byKey(const ValueKey('onboarding-scroll')), const Offset(0, 2000));
          await tester.pumpAndSettle();
          await capture(tester, 'account-$name');
          await tap(tester, 'sign-in-email');
          await tester.drag(find.byKey(const ValueKey('onboarding-scroll')), const Offset(0, 2000));
          await tester.pumpAndSettle();
          await capture(tester, 'email-$name');
          await tap(tester, 'onboarding-account-options');
          await tap(tester, 'onboarding-account-skip');
          expect(find.byType(OnboardingPassPanel), findsOneWidget);
          await tester.drag(find.byKey(const ValueKey('onboarding-scroll')), const Offset(0, 2000));
          await tester.pumpAndSettle();
          await capture(tester, 'desk-$name');
          await tester.ensureVisible(find.byKey(const ValueKey('onboarding-pass-free')));
        });
      }
    }
  }
}
