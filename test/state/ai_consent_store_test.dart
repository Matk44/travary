import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/ai_consent_record.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/visual_profile_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/ai_consent.dart';
import 'package:travary/state/ai_consent_store.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

class _Classifier implements VisualProfileService {
  final trips = <String>[];

  @override
  Future<TripVisualProfile> classify(Trip trip, List<Booking> bookings) async {
    trips.add(trip.id);
    return const TripVisualProfile(primaryTheme: ExperienceTheme.urbanHeritage, confidence: 0.9, sourceHash: 'h');
  }
}

const _debounce = Duration(milliseconds: 20);
Future<void> settle() => Future<void>.delayed(_debounce * 3);

void main() {
  group('the answer on this phone', () {
    test('loads what was stored, and remembers a new answer', () async {
      final record = MemoryAiConsentRecord(AiConsent.declined);
      final consent = AiConsentStore(record);
      expect(consent.loaded, isFalse);
      await consent.ready;
      expect(consent.consent, AiConsent.declined);
      expect(consent.allowed, isFalse);

      await consent.allow(AiAsk.smartImport);
      expect(consent.allowed, isTrue);
      expect(record.consent, AiConsent.allowed);

      await consent.decline(AiAsk.settings);
      expect(record.consent, AiConsent.declined);
    });

    test('kept in the app’s own folder, and an unreadable file is asked again', () async {
      final directory = Directory.systemTemp.createTempSync('travary-ai');
      addTearDown(() => directory.deleteSync(recursive: true));
      final record = LocalAiConsentRecord(directory: directory);
      expect(await record.load(), AiConsent.undecided);
      await record.save(AiConsent.allowed);
      expect(await LocalAiConsentRecord(directory: directory).load(), AiConsent.allowed);

      File('${directory.path}/consent.json').writeAsStringSync('{not json');
      expect(await record.load(), AiConsent.undecided);
    });
  });

  group('trip looks wait for the traveller’s OK', () {
    late _Classifier classifier;
    late AiConsentStore consent;
    late TravelStore store;

    Future<void> start(AiConsent answer) async {
      final repository = MemoryTravelRepository(userId: 'me')
        ..replaceAll(
          [trip('kyoto', title: 'Kyoto'), trip('lisbon', title: 'Lisbon')],
          [
            booking('temple', BookingKind.attraction, d(4, 6), tripId: 'kyoto', title: 'Kinkaku-ji'),
            booking('tram', BookingKind.transport, d(6, 2), tripId: 'lisbon', title: 'Tram 28'),
          ],
        );
      classifier = _Classifier();
      consent = AiConsentStore(MemoryAiConsentRecord(answer));
      await consent.ready;
      store = TravelStore(
        repository: repository,
        artCatalog: const ArtCatalog.empty(),
        visualProfiles: classifier,
        classificationDebounce: _debounce,
        aiConsent: consent,
        clock: () => DateTime(2026, 3, 1, 9),
      );
      addTearDown(store.dispose);
      await pumpEventQueue();
    }

    test('nothing goes to Gemini before they answer, and the trip’s page asks', () async {
      await start(AiConsent.undecided);
      await store.saveBooking(booking('garden', BookingKind.attraction, d(4, 7), tripId: 'kyoto', title: 'Ryoan-ji'));
      await settle();
      expect(classifier.trips, isEmpty);
      expect(store.offersLooksFor(store.plan('kyoto')!), isTrue);
    });

    test('"Allow" gives every trip its look at once, and the offer goes', () async {
      await start(AiConsent.undecided);
      await consent.allow(AiAsk.tripLooks);
      await settle();
      expect(classifier.trips, unorderedEquals(['kyoto', 'lisbon']));
      expect(store.offersLooksFor(store.plan('kyoto')!), isFalse);
    });

    test('"Not now" sends nothing, even after edits, and stops offering', () async {
      await start(AiConsent.declined);
      await store.saveBooking(booking('garden', BookingKind.attraction, d(4, 7), tripId: 'kyoto', title: 'Ryoan-ji'));
      await settle();
      expect(classifier.trips, isEmpty);
      expect(store.offersLooksFor(store.plan('kyoto')!), isFalse);
    });

    test('"Automatic" in Trip details doesn’t send anything without it', () async {
      await start(AiConsent.declined);
      final kyoto = store.plan('kyoto')!;
      await store.chooseLook(kyoto, ExperienceTheme.alpine);
      await store.useAutomaticLook(store.plan('kyoto')!);
      await settle();
      expect(classifier.trips, isEmpty);
    });

    test('already allowed: looks work as before', () async {
      await start(AiConsent.allowed);
      await store.saveBooking(booking('garden', BookingKind.attraction, d(4, 7), tripId: 'kyoto', title: 'Ryoan-ji'));
      await settle();
      expect(classifier.trips, ['kyoto']);
    });
  });
}
