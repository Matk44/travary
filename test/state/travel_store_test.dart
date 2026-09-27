import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/memory_travel_repository.dart';
import 'package:travary/design/art/art_catalog.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/travel_store.dart';

import '../helpers.dart';

void main() {
  late MemoryTravelRepository repository;
  late TravelStore store;

  setUp(() async {
    repository = MemoryTravelRepository(userId: 'me');
    repository.replaceAll(
      [trip('orlando', title: 'Orlando')],
      [booking('hotel', BookingKind.stay, d(10, 12), tripId: 'orlando', endDate: d(10, 18))],
    );
    store = TravelStore(
      repository: repository,
      artCatalog: const ArtCatalog.empty(),
      clock: () => DateTime(2026, 10, 14, 9),
    );
    await pumpEventQueue();
  });

  tearDown(() => store.dispose());

  test('loads trips and bookings into plans', () {
    expect(store.isLoading, isFalse);
    expect(store.plans.single.trip.title, 'Orlando');
    expect(store.focus.plan?.id, 'orlando');
  });

  test('a booking during a trip joins it automatically', () async {
    final result = await store.saveBooking(
      booking('lunch', BookingKind.dining, d(10, 14), tripId: '', at: const ClockTime(12, 30)),
    );
    expect(result.tripTitle, 'Orlando');
    expect(result.newTrip, isFalse);
    expect(repository.bookings.firstWhere((b) => b.id == 'lunch').tripId, 'orlando');
  });

  test('a booking on other dates starts a new trip', () async {
    final result = await store.saveBooking(
      booking('flight', BookingKind.flight, d(12, 20), tripId: '', title: 'London to Lisbon'),
    );
    await pumpEventQueue();
    expect(result.newTrip, isTrue);
    expect(result.tripTitle, 'Lisbon');
    expect(store.plans.map((p) => p.trip.title), containsAll(['Orlando', 'Lisbon']));
  });

  test('search matches references, places and trip names', () async {
    await store.saveBooking(
      booking('lunch', BookingKind.dining, d(10, 14), tripId: 'orlando', reference: 'ST-4412'),
    );
    await pumpEventQueue();
    expect(store.search('st-44').single.id, 'lunch');
    expect(store.search('orlando'), hasLength(2));
    expect(store.search('', kind: BookingKind.stay).single.id, 'hotel');
  });

  test('previewing a different time moves the focus', () async {
    store.previewNow = DateTime(2026, 9, 1, 9);
    expect(store.focus.isCountdown, isTrue);
    expect(store.focus.daysUntilStart, 41);
  });

  test('deleting a trip removes its bookings', () async {
    await store.deleteTrip(store.plans.single);
    await pumpEventQueue();
    expect(store.plans, isEmpty);
    expect(store.bookings, isEmpty);
  });
}
