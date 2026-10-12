import 'dart:async';
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
import 'package:travary/data/flight_status_service.dart';
import 'package:travary/data/auth_service.dart';
import 'package:travary/data/sharing_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/ledger.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/domain/onboarding.dart';
import 'package:travary/features/onboarding/onboarding_screen.dart';
import 'package:travary/features/booking/edit_booking_screen.dart';
import 'package:travary/features/booking/attachment_viewer.dart';
import 'package:travary/features/onboarding/onboarding_account_screen.dart';
import 'package:travary/features/onboarding/onboarding_pass_screen.dart';
import 'package:travary/logic/destinations.dart';
import 'package:travary/logic/flight_status_text.dart';
import 'package:travary/state/onboarding_store.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../support/flight_status.dart';
import '../support/session.dart';
import '../support/canonical_today.dart';

void main() {
  final qa = Platform.environment['TRAVARY_ONBOARDING_QA'] == '1';
  setUpAll(() async {
    TravaryText.useGoogleFonts = false;
    if (qa) {
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
    }
  });
  tearDownAll(() {
    TravaryText.serifFamily = null;
    TravaryText.sansFamily = null;
  });
  late MemoryTravelRepository repository;
  late OnboardingStore setup;
  String? finishedTrip;

  Future<void> pump(
    WidgetTester tester, {
    OnboardingDraft draft = const OnboardingDraft(),
    FlightStatusService? flights,
    Size size = const Size(390, 844),
    double scale = 1,
    FakeAuthService? auth,
    Booking? saved,
    bool reduced = true,
    Stream<Uri>? links,
    SharingService? sharing,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    if (qa) {
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    }
    addTearDown(tester.view.reset);
    finishedTrip = null;
    repository = MemoryTravelRepository(userId: 'me');
    if (draft.tripId != null) {
      repository.putTrip(
        Trip(
          id: draft.tripId!,
          title: 'Bali holiday',
          destination: draft.destination,
          theme: qa ? ExperienceTheme.coastalResort : ExperienceTheme.classicTravel,
          plannedStart: draft.start,
          plannedEnd: draft.end,
          ownerId: 'me',
          memberIds: const ['me'],
          createdAt: DateTime(2026, 10, 6),
          updatedAt: DateTime(2026, 10, 6),
        ),
      );
    }
    if (saved != null) await repository.saveBooking(saved);
    setup = OnboardingStore(repository: MemoryOnboardingRepository(draft));
    await setup.load();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          appSessionProvider(auth: auth, links: links),
          ChangeNotifierProvider(
            create: (_) => TravelStore(
              repository: repository,
              artCatalog: qa ? bundledArtCatalog() : const ArtCatalog.empty(),
              flightStatus: flights,
              sharing: sharing,
              clock: () => DateTime(2026, 10, 6),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
          ChangeNotifierProvider.value(value: setup),
        ],
        child: MaterialApp(
          theme: qa
              ? buildTravaryTheme().copyWith(textTheme: buildTravaryTheme().textTheme.apply(fontFamily: 'Inter'))
              : buildTravaryTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced, textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: OnboardingScreen(onFinished: (id) => finishedTrip = id),
        ),
      ),
    );
    addTearDown(setup.dispose);
    await tester.pumpAndSettle();
  }

  OnboardingDraft holiday() => OnboardingDraft(
    step: OnboardingStep.booking,
    destination: detectPlace('Bali')!.destination,
    start: const LocalDate(2026, 11, 8),
    end: const LocalDate(2026, 11, 15),
    tripId: 'first-holiday',
  );

  Booking firstBooking({List<Attachment> attachments = const []}) => Booking(
    id: 'first-booking',
    tripId: 'first-holiday',
    kind: BookingKind.stay,
    title: 'Lagoon Retreat',
    startDate: const LocalDate(2026, 11, 8),
    endDate: const LocalDate(2026, 11, 10),
    attachments: attachments,
    createdAt: DateTime(2026, 10, 6),
    updatedAt: DateTime(2026, 10, 6),
  );

  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    final scroll = find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first;
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, 300, scrollable: scroll);
    } else {
      await tester.ensureVisible(target);
    }
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!qa) return;
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      await Future.wait(
        tester.widgetList<Image>(find.byType(Image)).map((image) => precacheImage(image.image, context)),
      );
    });
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/onboarding_conversion').create(recursive: true);
      await File('build/onboarding_conversion/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('the first screen asks one thing; returning travellers sign in from the corner', (tester) async {
    await pump(tester, auth: FakeAuthService());
    expect(find.byKey(const ValueKey('onboarding-destination')), findsOneWidget);
    expect(find.text('Explore Travary first'), findsNothing);
    expect(find.text('I already have a booking'), findsNothing);
    expect(find.byKey(const ValueKey('onboarding-have-account')), findsOneWidget);
    // Joining needs the cloud; without it there's nothing to join.
    expect(find.byKey(const ValueKey('onboarding-join')), findsNothing);
    expect(repository.trips, isEmpty);
  });

  testWidgets('family sent a code join from the first screen, without making a holiday', (tester) async {
    final sharing = _JoiningSharing(() => repository);
    await pump(tester, sharing: sharing);
    await tester.tap(find.byKey(const ValueKey('onboarding-join')));
    // The sheet slides up (its code field's cursor keeps blinking, so
    // nothing settles while it's open).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Join a trip'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Invite code'), 'K7MPQ2');
    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Alex');
    await tester.pump();
    await tester.tap(find.text('Join trip'));
    await tester.pumpAndSettle();
    expect(sharing.joinedWith, 'K7MPQ2');
    expect(finishedTrip, 'kyoto');
    expect(setup.draft.completed, isTrue);
    expect(repository.trips.single.id, 'kyoto');
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrival is actionable and unknown dates create one real undated holiday', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('onboarding-destination')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField), 'Bali');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Bali').last);
    await tester.pumpAndSettle();
    expect(setup.draft.destination?.regionSlug, 'bali');
    expect(find.byKey(const ValueKey('onboarding-choose-dates')), findsOneWidget);
    await tap(tester, 'onboarding-no-dates');
    expect(repository.trips, hasLength(1));
    expect(repository.trips.single.plannedStart, isNull);
    await tap(tester, 'onboarding-later');
    expect(find.byType(OnboardingPassPanel), findsOneWidget);
    expect(setup.draft.completed, isFalse);
    expect(finishedTrip, isNull);
    await tap(tester, 'onboarding-pass-free');
    expect(finishedTrip, repository.trips.single.id);
    expect(setup.draft.completed, isTrue);
    expect(repository.bookings, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flight folio queries the service and saves its actual overnight schedule', (tester) async {
    final flights = FakeFlightStatusService()
      ..legs = [
        FlightStatus.fromJson({
          'number': 'QF 43',
          'airline': 'Qantas',
          'status': 'Expected',
          'departure': {
            'airport': 'SYD',
            'airportFullName': 'Sydney Airport',
            'city': 'Sydney',
            'scheduled': '2026-11-08T21:50',
          },
          'arrival': {'airport': 'DPS', 'city': 'Denpasar', 'scheduled': '2026-11-09T01:10'},
        }, checkedAt: DateTime(2026, 10, 6)),
      ];
    await pump(tester, draft: holiday(), flights: flights);
    await tap(tester, 'onboarding-manual');
    await tap(tester, 'onboarding-kind-flight');
    expect(find.text('Find your\nflight.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('flight-number-field')), 'qf 43');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(flights.calls, [const FlightLookup(flightNumber: 'QF43', date: LocalDate(2026, 11, 8))]);
    expect(find.text('Sydney'), findsOneWidget);
    expect(find.text('Denpasar'), findsOneWidget);
    await tap(tester, 'use-flight');
    expect(find.text('Check your\nflight.'), findsOneWidget);
    await tap(tester, 'save-booking');
    final saved = repository.bookings.single;
    expect(saved.startTime, const ClockTime(21, 50));
    expect(saved.endDate, const LocalDate(2026, 11, 9));
    expect(saved.endTime, const ClockTime(1, 10));
    expect(saved.location, 'Sydney Airport (SYD)');
    expect(saved.detail(DetailKeys.flightNumber), 'QF 43');
    expect(saved.tripId, 'first-holiday');
    expect(setup.draft.bookingId, saved.id);
    expect(setup.draft.bookingSource, OnboardingBookingSource.manual);
    expect(find.text('Sydney to Denpasar'), findsWidgets);
    expect(repository.trips, hasLength(1));
    expect(flights.calls, hasLength(1));
    expect(tester.takeException(), isNull);

    // The pass desk comes after real proof. Back preserves setup;
    // an explicit free continuation completes into this same saved holiday.
    await tap(tester, 'onboarding-see-passes');
    expect(find.text('Shall I help\nwith the rest?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-pass-back')));
    await tester.pumpAndSettle();
    expect(setup.draft.completed, isFalse);
    expect(find.text('Sydney to Denpasar'), findsWidgets);
    await tap(tester, 'onboarding-see-passes');
    await tap(tester, 'onboarding-pass-free');
    expect(finishedTrip, saved.tripId);
    expect(setup.draft.completed, isTrue);
    expect(repository.bookings.single.id, saved.id);
  });

  testWidgets('resumed proof and free handoff use the booking’s current holiday identity', (tester) async {
    await pump(tester, draft: holiday().copyWith(bookingId: 'saved-before'));
    final stamp = DateTime(2026, 10, 6);
    repository.replaceAll(
      [
        ...repository.trips,
        Trip(
          id: 'actual-holiday',
          title: 'Actual holiday',
          ownerId: 'me',
          memberIds: const ['me'],
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ],
      [
        Booking(
          id: 'saved-before',
          tripId: 'actual-holiday',
          kind: BookingKind.stay,
          title: 'Lagoon Retreat',
          startDate: const LocalDate(2026, 11, 8),
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tap(tester, 'onboarding-see-passes');
    // The desk sells for the booking's actual holiday, not the setup's.
    expect(tester.widget<OnboardingPassPanel>(find.byType(OnboardingPassPanel)).tripId, 'actual-holiday');
    await tap(tester, 'onboarding-pass-free');
    expect(finishedTrip, 'actual-holiday');
    expect(setup.draft.completed, isTrue);
    expect(repository.trips, hasLength(2));
  });

  testWidgets('both dates in one sheet: leave, then home, then straight on to the booking', (tester) async {
    await pump(
      tester,
      draft: OnboardingDraft(step: OnboardingStep.dates, destination: detectPlace('Bali')!.destination),
    );
    await tap(tester, 'onboarding-choose-dates');
    expect(find.text('Tap the day you leave'), findsOneWidget);
    TicketButton confirm() => tester.widget<TicketButton>(find.byKey(const ValueKey('holiday-dates-confirm')));
    await tester.tap(find.byKey(const ValueKey('date-2026-10-20')));
    await tester.pumpAndSettle();
    expect(find.text('Now the day you come home'), findsOneWidget);
    expect(confirm().onPressed, isNull, reason: 'leaving alone never invents a return');
    // An earlier day starts again from there.
    await tester.tap(find.byKey(const ValueKey('date-2026-10-12')));
    await tester.pumpAndSettle();
    expect(find.text('Now the day you come home'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('date-2026-10-19')));
    await tester.pumpAndSettle();
    expect(find.text('7 nights'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('holiday-dates-confirm')));
    await tester.pumpAndSettle();
    expect(setup.draft.start, const LocalDate(2026, 10, 12));
    expect(setup.draft.end, const LocalDate(2026, 10, 19));
    expect(setup.draft.step, OnboardingStep.booking);
    expect(repository.trips.single.plannedStart, const LocalDate(2026, 10, 12));
    expect(find.byKey(const ValueKey('onboarding-import')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('someone already away can say they left days ago', (tester) async {
    // The clock says 6 October 2026: they left on the 2nd.
    await pump(
      tester,
      draft: OnboardingDraft(step: OnboardingStep.dates, destination: detectPlace('Bali')!.destination),
    );
    await tap(tester, 'onboarding-choose-dates');
    await tester.tap(find.byKey(const ValueKey('date-2026-10-02')));
    await tester.pumpAndSettle();
    expect(find.text('Now the day you come home'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('date-2026-10-09')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('holiday-dates-confirm')));
    await tester.pumpAndSettle();
    expect(repository.trips.single.plannedStart, const LocalDate(2026, 10, 2));
    expect(repository.trips.single.plannedEnd, const LocalDate(2026, 10, 9));
    expect(find.byKey(const ValueKey('onboarding-import')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing the dates sheet changes nothing', (tester) async {
    await pump(
      tester,
      draft: OnboardingDraft(step: OnboardingStep.dates, destination: detectPlace('Bali')!.destination),
    );
    await tap(tester, 'onboarding-choose-dates');
    await tester.tap(find.byKey(const ValueKey('date-2026-10-20')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    expect(setup.draft.start, isNull);
    expect(setup.draft.step, OnboardingStep.dates);
    expect(repository.trips, isEmpty);
  });

  testWidgets('service failure keeps manual entry and cancellation preserves the holiday', (tester) async {
    final flights = FakeFlightStatusService()..failure = const FlightStatusException('Board unavailable. Try again.');
    await pump(tester, draft: holiday(), flights: flights);
    await tap(tester, 'onboarding-manual');
    await tap(tester, 'onboarding-kind-flight');
    await tester.enterText(find.byKey(const ValueKey('flight-number-field')), 'QF43');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Board unavailable. Try again.'), findsOneWidget);
    await tap(tester, 'enter-flight-manually');
    expect(find.byType(EditBookingScreen), findsOneWidget);
    final title = find.descendant(of: find.byKey(const ValueKey('field-title')), matching: find.byType(TextField));
    expect(tester.widget<TextField>(title).controller!.text, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(setup.draft.tripId, 'first-holiday');
    expect(repository.bookings, isEmpty);
    expect(repository.trips, hasLength(1));
    expect(find.byKey(const ValueKey('onboarding-manual')), findsOneWidget);
  });

  testWidgets('the first booking stays in the selected undated holiday despite an older overlapping trip', (
    tester,
  ) async {
    await pump(tester, draft: holiday().copyWith(clearDates: true));
    repository.putTrip(
      Trip(
        id: 'older-trip',
        title: 'Orlando',
        destination: detectPlace('Orlando')!.destination,
        plannedStart: const LocalDate(2026, 10, 6),
        plannedEnd: const LocalDate(2026, 10, 20),
        ownerId: 'me',
        memberIds: const ['me'],
        createdAt: DateTime(2026, 10, 6),
        updatedAt: DateTime(2026, 10, 6),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'onboarding-manual');
    await tap(tester, 'onboarding-kind-stay');
    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('field-title')), matching: find.byType(TextField)),
      'Lagoon Retreat',
    );
    await tap(tester, 'save-booking');
    expect(repository.bookings.single.tripId, 'first-holiday');
    expect(setup.draft.tripId, 'first-holiday');
    expect(setup.draft.destination?.regionSlug, 'bali');
    expect(repository.trips, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('small phone and large text keep all actions scrollable without overflow', (tester) async {
    await pump(tester, draft: holiday(), size: const Size(320, 568), scale: 2);
    await tap(tester, 'onboarding-manual');
    await tap(tester, 'onboarding-kind-stay');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('save-booking')),
      300,
      scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('manual proof offers help without claiming an import; sign-in before the desk is optional', (
    tester,
  ) async {
    final auth = FakeAuthService();
    final saved = firstBooking();
    await pump(
      tester,
      draft: holiday().copyWith(bookingId: saved.id),
      saved: saved,
      auth: auth,
    );
    expect(find.textContaining('Got more confirmations?'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-open-confirmation')), findsNothing);
    await capture(tester, 'proof-manual');
    expect(find.byKey(const ValueKey('onboarding-open-holiday')), findsNothing);
    expect(find.text('Open my holiday with free'), findsNothing);
    await tap(tester, 'onboarding-see-passes');
    // Sign-in comes first, then the passes.
    expect(find.byType(OnboardingAccountPanel), findsOneWidget);
    expect(find.byType(OnboardingPassPanel), findsNothing);
    expect(find.textContaining('with you.', findRichText: true), findsOneWidget);
    await capture(tester, 'account-optional');
    expect(setup.draft.completed, isFalse);
    await tap(tester, 'onboarding-account-skip');
    expect(find.byType(OnboardingPassPanel), findsOneWidget);
    expect(setup.draft.completed, isFalse);
    await tap(tester, 'onboarding-pass-free');
    expect(finishedTrip, saved.tripId);
    expect(setup.draft.completed, isTrue);
    expect(auth.calls, isEmpty);
    expect(repository.bookings.single.id, saved.id);
  });

  testWidgets('email: a sent link is not a sign-in; opening it signs in and goes on to the desk', (tester) async {
    final auth = FakeAuthService();
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final saved = firstBooking();
    await pump(
      tester,
      draft: holiday().copyWith(bookingId: saved.id),
      saved: saved,
      auth: auth,
      links: links.stream,
    );
    await tap(tester, 'onboarding-see-passes');
    await tap(tester, 'sign-in-email');
    expect(find.textContaining('And you’re in.', findRichText: true), findsOneWidget);
    expect(tester.widget<TicketButton>(find.byKey(const ValueKey('email-link-send'))).onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('email-link-field')), 'sam@example.com');
    await tester.pump();
    await tap(tester, 'email-link-send');
    expect(auth.calls, contains('sendSignInLink:sam@example.com'));
    expect(find.byKey(const ValueKey('email-link-sent')), findsOneWidget);
    expect(find.textContaining('inbox.', findRichText: true), findsOneWidget);
    expect(auth.current!.isGuest, isTrue);
    expect(find.byType(OnboardingPassPanel), findsNothing);
    // "Use a different email" goes back to the field; the guest way out stays.
    expect(find.byKey(const ValueKey('email-link-change')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-account-skip')), findsOneWidget);
    links.add(Uri.parse('https://links.test/sign-in?oobCode=abc'));
    await tester.pumpAndSettle();
    expect(auth.current!.methods, {SignInMethod.email});
    expect(find.byType(OnboardingPassPanel), findsOneWidget);
    await tap(tester, 'onboarding-pass-free');
    expect(finishedTrip, saved.tripId);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a place without films goes on to the desk as a guest', (tester) async {
    final saved = firstBooking();
    final paris = holiday().copyWith(destination: detectPlace('Paris')!.destination, bookingId: saved.id);
    await pump(tester, draft: paris, saved: saved, auth: FakeAuthService(), reduced: true);
    await tap(tester, 'onboarding-see-passes');
    expect(find.byType(OnboardingAccountPanel), findsOneWidget);
    await tap(tester, 'onboarding-account-skip');
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPassPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a place without films goes on to the desk signed in, with motion', (tester) async {
    final saved = firstBooking();
    final paris = holiday().copyWith(destination: detectPlace('Paris')!.destination, bookingId: saved.id);
    await pump(tester, draft: paris, saved: saved, auth: FakeAuthService(), reduced: false);
    await tap(tester, 'onboarding-see-passes');
    expect(find.byType(OnboardingAccountPanel), findsOneWidget);
    await tap(tester, 'sign-in-apple');
    // Travi tucks the tag into the folio, then presents the passes.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPassPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('email is only offered where links are set up', (tester) async {
    final auth = FakeAuthService()..supported = {SignInMethod.apple, SignInMethod.google};
    final saved = firstBooking();
    await pump(
      tester,
      draft: holiday().copyWith(bookingId: saved.id),
      saved: saved,
      auth: auth,
    );
    await tap(tester, 'onboarding-see-passes');
    expect(find.byKey(const ValueKey('sign-in-apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-in-email')), findsNothing);
  });

  testWidgets('sign-in before the desk: cancellation and failure keep the real booking', (tester) async {
    final auth = FakeAuthService()..failNext = const AuthFailure.cancelled();
    final saved = firstBooking();
    await pump(
      tester,
      draft: holiday().copyWith(bookingId: saved.id),
      saved: saved,
      auth: auth,
    );
    await tap(tester, 'onboarding-see-passes');
    expect(find.byType(OnboardingAccountPanel), findsOneWidget);
    await tap(tester, 'sign-in-apple');
    expect(find.byType(OnboardingAccountPanel), findsOneWidget, reason: 'cancelling stays here');
    expect(setup.draft.completed, isFalse);
    auth.failNext = const AuthFailure('Connect and try again.');
    await tap(tester, 'sign-in-google');
    expect(find.text('Connect and try again.'), findsOneWidget);
    expect(repository.bookings.single.id, saved.id);
    await tap(tester, 'sign-in-apple');
    // Linked: the same holiday goes on to its pass desk.
    expect(auth.current!.isGuest, isFalse);
    expect(find.byType(OnboardingPassPanel), findsOneWidget);
    expect(finishedTrip, isNull);
    await tap(tester, 'onboarding-pass-free');
    expect(finishedTrip, saved.tripId);
    expect(setup.draft.completed, isTrue);
    expect(repository.trips, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('success and account actions survive small phones, large type and account Back', (tester) async {
    final saved = firstBooking();
    await pump(
      tester,
      draft: holiday().copyWith(bookingId: saved.id),
      saved: saved,
      auth: FakeAuthService(),
      size: const Size(320, 568),
      scale: 2,
    );
    await tap(tester, 'onboarding-see-passes');
    expect(tester.takeException(), isNull);
    await tap(tester, 'sign-in-google');
    await tap(tester, 'onboarding-pass-free');
    expect(finishedTrip, saved.tripId);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account Back preserves proof, and the desk still keeps the free choice', (tester) async {
    final saved = firstBooking();
    await pump(
      tester,
      draft: holiday().copyWith(bookingId: saved.id),
      saved: saved,
      auth: FakeAuthService(),
    );
    await tap(tester, 'onboarding-see-passes');
    await tap(tester, 'onboarding-account-back');
    expect(setup.draft.completed, isFalse);
    expect(find.text('Lagoon Retreat'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-open-holiday')), findsNothing);
    expect(find.byKey(const ValueKey('onboarding-see-passes')), findsOneWidget);
    await tap(tester, 'onboarding-see-passes');
    await tap(tester, 'onboarding-account-skip');
    expect(find.byKey(const ValueKey('onboarding-pass-free')), findsOneWidget);
    // The desk's Back returns to the saved booking, not the sign-in.
    await tap(tester, 'onboarding-pass-back');
    expect(find.byKey(const ValueKey('onboarding-see-passes')), findsOneWidget);
    expect(repository.bookings, hasLength(1));
  });

  testWidgets('imported proof resumes accurately and opens the saved confirmation during finite motion', (
    tester,
  ) async {
    final saved = firstBooking(
      attachments: const [
        Attachment(id: 'original', name: 'Confirmation.pdf', fileName: 'original.pdf', sizeBytes: 50),
      ],
    );
    await pump(
      tester,
      draft: holiday().copyWith(bookingId: saved.id, bookingSource: OnboardingBookingSource.smartImport),
      saved: saved,
      reduced: false,
    );
    expect(find.textContaining('Read, checked and in your plan.'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse, reason: 'the save celebration settles');
    await capture(tester, 'proof-import');
    await tap(tester, 'onboarding-open-confirmation');
    expect(tester.widget<AttachmentViewer>(find.byType(AttachmentViewer)).bookingId, saved.id);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, 'onboarding-see-passes');
    await tap(tester, 'onboarding-pass-free');
    // Travi waves them off, then the holiday opens.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(finishedTrip, saved.tripId);
    expect(repository.bookings.single.attachments.single.id, 'original');
    expect(tester.takeException(), isNull);
  });
}

/// Joins whatever code it's given: the server adds them to Kyoto.
class _JoiningSharing implements SharingService {
  _JoiningSharing(this.repository);

  final MemoryTravelRepository Function() repository;
  String? joinedWith;

  @override
  Future<TripInvite> createInvite(String tripId, {String? name}) async => TripInvite('K7MPQ2', DateTime(2026, 10, 30));

  @override
  Future<({String tripId, String title})> join(String code, {required String name}) async {
    joinedWith = code;
    final repo = repository();
    repo.putTrip(
      Trip(
        id: 'kyoto',
        title: 'Kyoto',
        plannedStart: const LocalDate(2026, 11, 2),
        plannedEnd: const LocalDate(2026, 11, 6),
        ownerId: 'sam',
        memberIds: [repo.userId, 'sam'],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    return (tripId: 'kyoto', title: 'Kyoto');
  }

  @override
  Future<void> removeMember(String tripId, String memberId) async {}
}
