import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travary/data/ai_consent_record.dart';
import 'package:travary/data/attachment_store.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/purchase_service.dart';
import 'package:travary/data/shared_files.dart';
import 'package:travary/data/smart_import_service.dart';
import 'package:travary/data/visual_profile_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/ai/ai_consent_sheet.dart';
import 'package:travary/features/ai/trip_looks_offer.dart';
import 'package:travary/features/booking/booking_actions.dart';
import 'package:travary/features/import/smart_import_screen.dart';
import 'package:travary/features/profile/profile_screen.dart';
import 'package:travary/features/trips/trip_screen.dart';
import 'package:travary/logic/ai_consent.dart';
import 'package:travary/state/ai_consent_store.dart';
import 'package:travary/state/premium_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';
import '../support/session.dart';
import '../support/travel_documents.dart';

class _Reader implements SmartImportService {
  int calls = 0;

  @override
  Future<SmartImportResult> read(String path, {required LocalDate today, String? tripId}) async {
    calls++;
    return const SmartImportResult([]);
  }
}

class _Classifier implements VisualProfileService {
  int calls = 0;

  @override
  Future<TripVisualProfile> classify(Trip trip, List<Booking> bookings) async {
    calls++;
    return const TripVisualProfile(primaryTheme: ExperienceTheme.urbanHeritage, confidence: 0.9, sourceHash: 'h');
  }
}

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  group('Smart Import asks before Google’s AI reads anything', () {
    late MemoryAiConsentRecord record;
    late _Reader reader;
    late SharedFile shared;

    Future<void> pump(WidgetTester tester, {AiConsent consent = AiConsent.undecided}) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final directory = Directory.systemTemp.createTempSync('travary-ai-share');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/Lagoon Grill.png')..writeAsBytesSync([137, 80, 78, 71]);
      shared = (path: file.path, name: 'Lagoon Grill.png');
      final files = Directory('${directory.path}/files')..createSync();
      record = MemoryAiConsentRecord(consent);
      reader = _Reader();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SmartImportService>.value(value: reader),
            ChangeNotifierProvider(create: (_) => AiConsentStore(record)),
            ChangeNotifierProvider(
              create: (_) => TravelStore(
                repository: MemoryTravelRepository(userId: 'me'),
                artCatalog: const ArtCatalog.empty(),
                attachments: AttachmentStore.at(files),
                clock: () => DateTime(2026, 10, 5, 9),
              ),
            ),
            ChangeNotifierProvider(lazy: false, create: (_) => PremiumStore(purchases: TestPurchaseService())),
          ],
          child: MaterialApp(
            theme: buildTravaryTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(onPressed: () => importSharedFile(context, shared), child: const Text('share')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Shares the file in, and lets Travi pop up with his sign.
    Future<void> share(WidgetTester tester) async {
      await tester.tap(find.text('share'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    testWidgets('the sheet says what goes to Gemini, and Travi holds up the question', (tester) async {
      await pump(tester);
      await share(tester);
      expect(find.byKey(const ValueKey('ai-consent-ticket')), findsOneWidget);
      expect(find.text(aiConsentWordsFor(AiAsk.smartImport).title), findsOneWidget);
      expect(find.text(aiSentWords), findsOneWidget);
      expect(find.text(aiNeverSentWords), findsOneWidget);
      expect(find.byKey(const ValueKey('ai-consent-privacy')), findsOneWidget);
      expect(find.text(aiConsentSign), findsOneWidget);
      final sign = tester.widget<AnimatedOpacity>(
        find.ancestor(of: find.byKey(const ValueKey('travi-sign')), matching: find.byType(AnimatedOpacity)),
      );
      expect(sign.opacity, 1, reason: 'written once he’s up');
      expect(reader.calls, 0, reason: 'nothing read before the answer');
    });

    testWidgets('"Not now" sends nothing; the shared file can still be typed in', (tester) async {
      await pump(tester);
      await share(tester);
      await tester.tap(find.byKey(const ValueKey('ai-consent-not-now')));
      await tester.pumpAndSettle();
      expect(reader.calls, 0);
      expect(record.consent, AiConsent.declined);
      expect(find.text('Add this booking'), findsOneWidget);
      expect(find.text('Lagoon Grill.png stays with it as the ticket.'), findsOneWidget);
    });

    testWidgets('"Allow" reads it, and is remembered: no question next time', (tester) async {
      await pump(tester);
      await share(tester);
      await tester.tap(find.byKey(const ValueKey('ai-consent-allow')));
      await tester.pumpAndSettle();
      expect(record.consent, AiConsent.allowed);
      expect(find.byType(SmartImportScreen), findsOneWidget);
      expect(reader.calls, 1);
    });

    testWidgets('already allowed: straight to reading', (tester) async {
      await pump(tester, consent: AiConsent.allowed);
      await share(tester);
      expect(find.byKey(const ValueKey('ai-consent-ticket')), findsNothing);
      expect(reader.calls, 1);
    });

    testWidgets('put away without an answer: nothing read, nothing decided', (tester) async {
      await pump(tester);
      await share(tester);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(reader.calls, 0);
      expect(record.consent, AiConsent.undecided);
    });
  });

  testWidgets('a small phone with large text: it scrolls, nothing overflows, and Travi stays on screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final record = MemoryAiConsentRecord();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AiConsentStore(record),
        child: MaterialApp(
          theme: buildTravaryTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(onPressed: () => askAiConsent(context, AiAsk.tripLooks), child: const Text('ask')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(find.byKey(const ValueKey('ai-consent-travi'))).dy, greaterThanOrEqualTo(0));

    // The answers stay in view while the ticket scrolls.
    expect(find.byKey(const ValueKey('ai-consent-allow')).hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-consent-not-now')).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ai-consent-allow')));
    await tester.pumpAndSettle();
    expect(record.consent, AiConsent.allowed);
  });

  group('a trip’s page offers automatic looks', () {
    late MemoryAiConsentRecord record;
    late _Classifier classifier;

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      record = MemoryAiConsentRecord();
      classifier = _Classifier();
      final repository = MemoryTravelRepository(userId: 'me')
        ..replaceAll(
          [trip('jp', title: 'Japan', plannedStart: d(10, 11), plannedEnd: d(10, 16))],
          [booking('museum', BookingKind.attraction, d(10, 12), tripId: 'jp', at: const ClockTime(15, 0))],
        );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AiConsentStore(record)),
            ChangeNotifierProvider(
              create: (context) => TravelStore(
                repository: repository,
                artCatalog: const ArtCatalog.empty(),
                visualProfiles: classifier,
                classificationDebounce: Duration.zero,
                aiConsent: context.read<AiConsentStore>(),
                clock: () => DateTime(2026, 10, 5, 9),
              ),
            ),
            ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
          ],
          child: MaterialApp(
            theme: buildTravaryTheme(),
            home: const TripScreen(tripId: 'jp'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapOffer(WidgetTester tester, String key) async {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(key)),
        200,
        scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
    }

    testWidgets('"Show me" asks properly; "Allow" dresses the trip and the offer goes', (tester) async {
      await pump(tester);
      expect(classifier.calls, 0);
      await tapOffer(tester, 'trip-looks-show-me');
      expect(find.text(aiConsentWordsFor(AiAsk.tripLooks).title), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ai-consent-allow')));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(record.consent, AiConsent.allowed);
      expect(classifier.calls, 1);
      expect(find.byType(TripLooksOffer), findsNothing);
    });

    testWidgets('"Not now" puts it away for good and sends nothing', (tester) async {
      await pump(tester);
      await tapOffer(tester, 'trip-looks-not-now');
      expect(find.byType(TripLooksOffer), findsNothing);
      expect(record.consent, AiConsent.declined);
      expect(classifier.calls, 0);
    });
  });

  testWidgets('Profile’s switch: on asks with the sheet, off sends nothing more', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final record = MemoryAiConsentRecord();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AiConsentStore(record)),
          ChangeNotifierProvider(
            create: (_) => TravelStore(
              repository: MemoryTravelRepository(userId: 'me'),
              artCatalog: const ArtCatalog.empty(),
              clock: () => DateTime(2026, 10, 5, 9),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PremiumStore(purchases: TestPurchaseService())),
          appSessionProvider(),
          travelDocumentsProvider(),
        ],
        child: MaterialApp(
          theme: buildTravaryTheme(),
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('profile-ai'));
    await tester.scrollUntilVisible(toggle, 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(find.text(aiSettingCopy), findsOneWidget);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text(aiConsentWordsFor(AiAsk.settings).title), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ai-consent-allow')));
    await tester.pumpAndSettle();
    expect(record.consent, AiConsent.allowed);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(record.consent, AiConsent.declined);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
  });
}
