import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/onboarding_record.dart';
import 'package:travary/data/onboarding_repository.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/domain/onboarding.dart';
import 'package:travary/logic/destinations.dart';
import 'package:travary/logic/onboarding_art.dart';
import 'package:travary/state/onboarding_store.dart';
import 'package:travary/state/travel_store.dart';

class _FailsOnce extends MemoryTravelRepository {
  final attempted = <String>[];
  @override
  Future<void> createTrip(Trip trip) async {
    attempted.add(trip.id);
    if (attempted.length == 1) throw StateError('Local write failed');
    await super.createTrip(trip);
  }
}

void main() {
  test('unknown dates survive storage, retry and relaunch without another holiday', () async {
    final repository = _FailsOnce();
    final travel = TravelStore(repository: repository, artCatalog: const ArtCatalog.empty());
    final progress = MemoryOnboardingRepository(
      OnboardingDraft(destination: detectPlace('Bali')!.destination, step: OnboardingStep.booking),
    );
    final first = OnboardingStore(repository: progress);
    addTearDown(travel.dispose);
    addTearDown(first.dispose);
    await first.load();
    await expectLater(first.ensureHoliday(travel), throwsStateError);
    final reserved = progress.draft.tripId;
    expect(reserved, isNotNull);
    final resumed = OnboardingStore(repository: progress);
    addTearDown(resumed.dispose);
    await resumed.load();
    final results = await Future.wait([resumed.ensureHoliday(travel), resumed.ensureHoliday(travel)]);
    expect(results.map((t) => t.id).toSet(), {reserved});
    expect(repository.attempted, [reserved, reserved]);
    expect(repository.trips, hasLength(1));
    expect(repository.trips.single.plannedStart, isNull);
    expect(repository.trips.single.plannedEnd, isNull);
    await Future<void>.delayed(Duration.zero);
    final again = OnboardingStore(repository: progress);
    addTearDown(again.dispose);
    await again.load();
    await again.ensureHoliday(travel);
    expect(repository.attempted, hasLength(2));
  });

  test('setup files are isolated by account and reject a malformed calendar date', () async {
    final directory = await Directory.systemTemp.createTemp('travary-onboarding-test-');
    addTearDown(() => directory.delete(recursive: true));
    final alice = LocalOnboardingRepository(userId: 'alice', directory: directory);
    final bob = LocalOnboardingRepository(userId: 'bob', directory: directory);
    await alice.save(OnboardingDraft(destination: countryPlace('JP').destination, completed: true));
    expect((await alice.load()).completed, isTrue);
    expect((await bob.load()).destination, isNull);
    await bob.save(const OnboardingDraft());
    expect((await alice.load()).destination?.countryCode, 'JP');
    expect(
      () => OnboardingDraft.fromJson({...const OnboardingDraft().toJson(), 'start': '2026-02-31'}),
      throwsFormatException,
    );
    expect(
      () => OnboardingDraft.fromJson({...const OnboardingDraft().toJson(), 'start': '2026-12-19', 'end': '2026-12-12'}),
      throwsFormatException,
    );
  });

  test('a city\'s own stage, then its country\'s, then a stand-in city, then Anywhere', () {
    final bali = detectPlace('Bali')!.destination;
    final kyoto = detectPlace('Kyoto')!.destination;
    expect(onboardingStageFor(bali), contains('bali-stage'));
    expect(onboardingStageFor(kyoto), contains('city_jp_kyoto'));
    expect(onboardingStage(kyoto).props, isFalse, reason: 'the new Kyoto has no painted folio');
    expect(onboardingStageFor(detectPlace('Tokyo')!.destination), contains('city_jp_tokyo'));
    // A country stage covers its other cities, and is never Bali or Kyoto.
    expect(onboardingStageFor(countryPlace('FR').destination), contains('country_fr'));
    expect(onboardingStageFor(countryPlace('JP').destination), contains('country_jp'));
    expect(onboardingStageFor(detectPlace('Hiroshima')!.destination), contains('country_jp'));
    expect(onboardingStageFor(countryPlace('ID').destination), contains('country_id'));
    // Czechia has Prague's stage but no country stage yet.
    expect(onboardingStageFor(countryPlace('CZ').destination), contains('city_cz_prague'));
    // Nowhere to borrow from, or no holiday yet: Anywhere.
    expect(onboardingStageFor(countryPlace('IS').destination), onboardingAnywhereStage);
    expect(onboardingStageFor(null), onboardingAnywhereStage);
    expect(onboardingStage(null).props, isFalse);
  });

  test('every country and stand-in stage is a bundled picture', () {
    for (final MapEntry(key: code, value: city) in onboardingCountryCities.entries) {
      expect(onboardingCityStages['$code/$city'], isNotNull, reason: code);
      expect(onboardingCountryStages[code], isNull, reason: '$code has its own stage now');
    }
    for (final asset in [...onboardingCityStages.values, ...onboardingCountryStages.values, onboardingAnywhereStage]) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
    expect(onboardingCountryStages, hasLength(26));
  });

  test('every approved city stage is reachable from the place a traveller picks', () {
    for (final name in ['Paris', 'New York', 'Cancún', 'Kuala Lumpur', 'Cape Town', 'Queenstown', 'San Francisco']) {
      final stage = onboardingStage(detectPlace(name)!.destination);
      expect(stage.asset, contains('assets/onboarding/stages/city_'), reason: name);
      expect(stage.props, isFalse);
    }
    expect(onboardingCityStages, hasLength(28));
    // City-states: the city's art is the country's.
    expect(onboardingStageFor(countryPlace('SG').destination), contains('city_sg_singapore'));
    expect(onboardingStageFor(countryPlace('HK').destination), contains('city_hk_hong_kong'));
    // Somewhere without art: Anywhere, with the shared folio.
    expect(onboardingStage(countryPlace('IS').destination).props, isFalse);
  });

  test('booking source survives resume and old drafts do not invent an import', () {
    final imported = OnboardingDraft.fromJson(
      const OnboardingDraft(bookingId: 'actual', bookingSource: OnboardingBookingSource.smartImport).toJson(),
    );
    expect(imported.bookingSource, OnboardingBookingSource.smartImport);
    expect(imported.bookingId, 'actual');
    final old = const OnboardingDraft(bookingId: 'legacy').toJson()..remove('bookingSource');
    expect(OnboardingDraft.fromJson(old).bookingSource, isNull);
    expect(() => OnboardingDraft.fromJson({...old, 'bookingSource': 'made-up'}), throwsFormatException);
  });

  test('the account\'s onboarding is read from every phone and recorded on completion', () async {
    final record = MemoryOnboardingRecord(['returning']);
    final returning = OnboardingStore(repository: MemoryOnboardingRepository(), record: record, userId: 'returning');
    final fresh = OnboardingStore(repository: MemoryOnboardingRepository(), record: record, userId: 'fresh');
    final demo = OnboardingStore(repository: MemoryOnboardingRepository());
    addTearDown(returning.dispose);
    addTearDown(fresh.dispose);
    addTearDown(demo.dispose);
    await Future.wait([returning.load(), fresh.load(), demo.load()]);
    expect(returning.completedElsewhere, isTrue);
    expect(fresh.completedElsewhere, isFalse);
    expect(demo.completedElsewhere, isNull);
    await fresh.complete();
    await pumpEventQueue();
    expect(fresh.draft.completed, isTrue);
    expect(record.completed, contains('fresh'));
  });

  test('an unreachable record (offline on a new phone) is unknown, not "done"', () async {
    final store = OnboardingStore(repository: MemoryOnboardingRepository(), record: _Offline(), userId: 'me');
    addTearDown(store.dispose);
    await store.load();
    expect(store.completedElsewhere, isNull);
    expect(store.error, isNull);
  });
}

class _Offline implements OnboardingRecord {
  @override
  Future<bool?> isCompleted(String uid) async => null;
  @override
  Future<void> markCompleted(String uid) async {}
}
