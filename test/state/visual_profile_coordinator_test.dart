import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/data/visual_profile_service.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/travel_store.dart';
import 'package:travary/state/visual_profile_coordinator.dart';

import '../helpers.dart';

/// Records classification calls; fails as scripted.
class FakeVisualProfiles implements VisualProfileService {
  final calls = <({Trip trip, List<Booking> bookings})>[];
  final failures = <Object>[];

  @override
  Future<TripVisualProfile> classify(Trip trip, List<Booking> bookings) async {
    calls.add((trip: trip, bookings: [...bookings]));
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return TripVisualProfile(primaryTheme: ExperienceTheme.themepark, confidence: 0.9, sourceHash: 'h${calls.length}');
  }
}

const _debounce = Duration(milliseconds: 20);
Future<void> settle([int times = 1]) => Future<void>.delayed(_debounce * 3 * times);

void main() {
  late MemoryTravelRepository repository;
  late FakeVisualProfiles service;
  late TravelStore store;

  setUp(() async {
    repository = MemoryTravelRepository(userId: 'me');
    repository.replaceAll(
      [trip('orlando', title: 'Orlando')],
      [booking('hotel', BookingKind.stay, d(10, 12), tripId: 'orlando', endDate: d(10, 18), title: 'Lagoon Resort')],
    );
    service = FakeVisualProfiles();
    store = TravelStore(
      repository: repository,
      artCatalog: const ArtCatalog.empty(),
      visualProfiles: service,
      classificationDebounce: _debounce,
      clock: () => DateTime(2026, 10, 14, 9),
    );
    await pumpEventQueue();
  });

  tearDown(() => store.dispose());

  test('a new booking classifies its trip once edits settle', () async {
    await store.saveBooking(
      booking('park', BookingKind.attraction, d(10, 14), tripId: 'orlando', title: 'Sunshine Park'),
    );
    expect(service.calls, isEmpty, reason: 'debounced, never during the save');
    await settle();
    expect(service.calls, hasLength(1));
    expect(service.calls.single.trip.id, 'orlando');
    expect(service.calls.single.bookings.map((b) => b.id), containsAll(['hotel', 'park']));
  });

  test('several quick edits make one call', () async {
    for (var i = 0; i < 4; i++) {
      await store.saveBooking(booking('b$i', BookingKind.dining, d(10, 14), tripId: 'orlando', title: 'Dinner $i'));
    }
    await settle();
    expect(service.calls, hasLength(1));
  });

  test('cosmetic edits don\'t classify; meaningful ones do', () async {
    final hotel = store.booking('hotel')!;
    await store.saveBooking(
      hotel.copyWith(
        attachments: const [Attachment(id: 'a', name: 'Voucher.pdf', fileName: 'a.pdf', sizeBytes: 1)],
      ),
      previous: hotel,
    );
    await settle();
    expect(service.calls, isEmpty);

    final renamed = booking(
      'hotel',
      BookingKind.stay,
      d(10, 12),
      tripId: 'orlando',
      endDate: d(10, 18),
      title: 'Castle View Hotel',
    );
    await store.saveBooking(renamed, previous: store.booking('hotel'));
    await settle();
    expect(service.calls, hasLength(1));
  });

  test('a batch import classifies each trip once, after the whole batch', () async {
    await store.saveBookings([
      booking('f1', BookingKind.flight, d(12, 1), tripId: '', title: 'London to Lisbon'),
      booking('h1', BookingKind.stay, d(12, 1), tripId: '', title: 'Alfama Hotel', endDate: d(12, 5)),
      booking('f2', BookingKind.flight, d(12, 5), tripId: '', title: 'Lisbon to London'),
    ]);
    await settle();
    expect(service.calls, hasLength(1));
    expect(service.calls.single.bookings, hasLength(3));
  });

  test('classification failure never blocks saving a booking', () async {
    final errors = <Object>[];
    await runZonedGuarded(() async {
      service.failures.addAll([
        const VisualProfileException(VisualProfileFailure.failed, 'Nope'),
        StateError('Unexpected'),
      ]);
      final result = await store.saveBooking(
        booking('lunch', BookingKind.dining, d(10, 14), tripId: 'orlando', title: 'Lunch'),
      );
      expect(result.booking.id, 'lunch');
      expect(repository.bookings.map((b) => b.id), contains('lunch'));
      await settle();
      await store.saveBooking(booking('tea', BookingKind.dining, d(10, 15), tripId: 'orlando', title: 'Tea'));
      await settle();
    }, (error, _) => errors.add(error));
    expect(errors, isEmpty);
    expect(service.calls, hasLength(2));
    expect(store.error, isNull);
    expect(store.bookings.map((b) => b.id), containsAll(['lunch', 'tea']));
  });

  test('an unchanged itinerary isn\'t sent twice', () async {
    await store.saveBooking(
      booking('park', BookingKind.attraction, d(10, 14), tripId: 'orlando', title: 'Sunshine Park'),
    );
    await settle();
    final park = store.booking('park')!;
    await store.saveBooking(
      booking('park', BookingKind.attraction, d(10, 14), tripId: 'orlando', title: 'Sunshine Park', location: null),
      previous: booking('park', BookingKind.attraction, d(10, 14), tripId: 'orlando', title: 'Sunshine Park 2'),
    );
    await settle();
    expect(service.calls, hasLength(1), reason: 'the payload is what was last sent');
    expect(park.title, 'Sunshine Park');
  });

  test('renaming a trip classifies it; picking a look doesn\'t', () async {
    final plan = store.plan('orlando')!;
    await store.chooseLook(plan, ExperienceTheme.alpine);
    await settle();
    expect(service.calls, isEmpty);
    expect(store.plan('orlando')!.trip.themeSource, ThemeSource.manual);
    expect(store.plan('orlando')!.trip.effectiveTheme, ExperienceTheme.alpine);

    await store.updateTrip(store.plan('orlando')!.trip.copyWith(title: 'Florida'));
    await settle();
    expect(service.calls, hasLength(1));
  });

  test('deleting a booking reclassifies what\'s left', () async {
    await store.saveBooking(
      booking('park', BookingKind.attraction, d(10, 14), tripId: 'orlando', title: 'Sunshine Park'),
    );
    await settle();
    await store.deleteBooking(store.booking('park')!);
    await settle();
    expect(service.calls, hasLength(2));
    expect(service.calls.last.bookings.map((b) => b.id), ['hotel']);
  });

  test('"Use automatic look" turns the trip automatic and classifies now', () async {
    await store.chooseLook(store.plan('orlando')!, ExperienceTheme.cruise);
    await store.useAutomaticLook(store.plan('orlando')!);
    expect(store.plan('orlando')!.trip.themeSource, ThemeSource.auto);
    expect(service.calls, hasLength(1), reason: 'no debounce for an explicit request');

    service.failures.add(const VisualProfileException(VisualProfileFailure.busy, 'Busy right now.'));
    await expectLater(store.useAutomaticLook(store.plan('orlando')!), throwsA(isA<VisualProfileException>()));
    await pumpEventQueue();
    expect(store.plan('orlando')!.trip.themeSource, ThemeSource.auto, reason: 'automatic regardless');
  });

  test('without the cloud, the automatic look explains itself', () async {
    final demo = TravelStore(repository: repository, artCatalog: const ArtCatalog.empty());
    addTearDown(demo.dispose);
    await pumpEventQueue();
    await demo.chooseLook(demo.plan('orlando')!, ExperienceTheme.cruise);
    await expectLater(
      demo.useAutomaticLook(demo.plan('orlando')!),
      throwsA(isA<VisualProfileException>().having((e) => e.message, 'message', contains('demo'))),
    );
    await pumpEventQueue();
    expect(demo.plan('orlando')!.trip.themeSource, ThemeSource.auto);
    expect(demo.automaticLooksAvailable, isFalse);
  });

  group('the coordinator', () {
    late Map<String, TripSnapshot> trips;
    late VisualProfileCoordinator coordinator;

    setUp(() {
      trips = {
        'kyoto': (
          trip: trip('kyoto', title: 'Kyoto'),
          bookings: [booking('a', BookingKind.stay, d(4, 1), tripId: 'kyoto')],
        ),
        'empty': (trip: trip('empty', title: 'October trip'), bookings: const []),
      };
      coordinator = VisualProfileCoordinator(
        service: service,
        snapshot: (id) => trips[id],
        debounce: _debounce,
        notSyncedRetries: const [Duration(milliseconds: 10), Duration(milliseconds: 20)],
      );
    });

    tearDown(() => coordinator.dispose());

    test('a trip not yet on the server is retried a bounded number of times', () async {
      service.failures.addAll(List.filled(5, const VisualProfileException(VisualProfileFailure.notSynced, 'Saving')));
      coordinator.schedule('kyoto');
      await settle(4);
      expect(service.calls, hasLength(3), reason: 'first try and two retries');
    });

    test('a cooldown is waited out, then retried', () async {
      service.failures.add(
        const VisualProfileException(VisualProfileFailure.cooldown, 'Soon', retryAfter: Duration(milliseconds: 30)),
      );
      coordinator.schedule('kyoto');
      await settle(3);
      expect(service.calls, hasLength(2));
    });

    test('other failures wait for the next change', () async {
      for (final failure in [
        VisualProfileFailure.dailyLimit,
        VisualProfileFailure.superseded,
        VisualProfileFailure.busy,
        VisualProfileFailure.offline,
      ]) {
        service.failures.add(VisualProfileException(failure, failure.name));
      }
      coordinator.schedule('kyoto');
      await settle(3);
      expect(service.calls, hasLength(1));
    });

    test('pauses while a batch saves, then runs once per trip', () async {
      coordinator.pause();
      coordinator
        ..schedule('kyoto')
        ..schedule('kyoto');
      await settle();
      expect(service.calls, isEmpty);
      coordinator.resume();
      await settle();
      expect(service.calls, hasLength(1));
    });

    test('a trip with nothing to go on isn\'t sent', () async {
      coordinator.schedule('empty');
      coordinator.schedule('gone');
      await settle();
      expect(service.calls, isEmpty);
    });

    test('an edit during a call runs again afterwards', () async {
      final gate = Completer<void>();
      final slow = _SlowService(gate);
      final slowCoordinator = VisualProfileCoordinator(service: slow, snapshot: (id) => trips[id], debounce: _debounce);
      addTearDown(slowCoordinator.dispose);
      slowCoordinator.schedule('kyoto');
      await settle();
      trips['kyoto'] = (trip: trip('kyoto', title: 'Kyoto and Nara'), bookings: trips['kyoto']!.bookings);
      slowCoordinator.schedule('kyoto');
      await settle();
      expect(slow.calls, 1, reason: 'one at a time per trip');
      gate.complete();
      await settle(2);
      expect(slow.calls, 2);
    });
  });
}

class _SlowService implements VisualProfileService {
  _SlowService(this.gate);

  final Completer<void> gate;
  int calls = 0;

  @override
  Future<TripVisualProfile> classify(Trip trip, List<Booking> bookings) async {
    calls++;
    await gate.future;
    return TripVisualProfile(primaryTheme: ExperienceTheme.urbanHeritage, confidence: 0.9, sourceHash: 'h$calls');
  }
}
