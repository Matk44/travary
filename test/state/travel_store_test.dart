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

  test('a booking can start its own trip even on another trip\'s dates', () async {
    final result = await store.saveBooking(
      booking('lunch', BookingKind.dining, d(10, 14), tripId: '', title: 'Lunch', location: 'Miami'),
      newTrip: true,
    );
    await pumpEventQueue();
    expect(result.newTrip, isTrue);
    expect(result.booking.tripId, isNot('orlando'));
    expect(store.plans, hasLength(2));
  });

  test('a trip\'s checklist: add, tick, change and remove items', () async {
    final orlando = store.plan('orlando')!;
    expect(await store.addChecklistItem(orlando, '   '), isNull);
    final insurance = (await store.addChecklistItem(orlando, ' Travel  insurance ', due: d(10, 1), idea: true))!;
    await pumpEventQueue();
    expect(store.plan('orlando')!.trip.checklist[insurance.id]?.text, 'Travel insurance');

    await store.toggleChecklistItem(store.plan('orlando')!, insurance);
    await pumpEventQueue();
    expect(store.plan('orlando')!.trip.checklist[insurance.id]?.done, isTrue);

    await store.saveChecklistItem(store.plan('orlando')!, insurance.copyWith(text: 'Insurance for all four'));
    await pumpEventQueue();
    expect(store.plan('orlando')!.trip.checklist[insurance.id]?.text, 'Insurance for all four');

    // Editing the trip itself leaves the checklist alone.
    await store.updateTrip(store.plan('orlando')!.trip.copyWith(title: 'Florida'));
    await pumpEventQueue();
    expect(store.plan('orlando')!.trip.checklist, hasLength(1));

    await store.deleteChecklistItem(store.plan('orlando')!, insurance);
    await pumpEventQueue();
    expect(store.plan('orlando')!.trip.checklist, isEmpty);
  });

  test('the same words twice add one item; the packing list is its own list', () async {
    final plan = store.plan('orlando')!;
    final first = await store.addChecklistItem(plan, 'Sun cream', list: TripList.packing);
    await pumpEventQueue();
    final again = await store.addChecklistItem(store.plan('orlando')!, ' sun  CREAM ', list: TripList.packing);
    await pumpEventQueue();
    expect(again?.id, first?.id);
    expect(store.plan('orlando')!.trip.packing, hasLength(1));
    expect(store.plan('orlando')!.trip.checklist, isEmpty);
  });

  test('a full checklist takes no more', () async {
    repository.putTrip(
      store
          .plan('orlando')!
          .trip
          .copyWith(
            checklist: {
              for (var i = 0; i < 100; i++)
                'c$i': ChecklistItem(id: 'c$i', text: 'Thing $i', createdAt: DateTime(2026)),
            },
          ),
    );
    await pumpEventQueue();
    expect(await store.addChecklistItem(store.plan('orlando')!, 'One more'), isNull);
  });

  test('search matches references, places and trip names', () async {
    await store.saveBooking(booking('lunch', BookingKind.dining, d(10, 14), tripId: 'orlando', reference: 'ST-4412'));
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

  test('a failed load shows what there is instead of spinning forever', () async {
    final failing = _FailingBookingsRepository();
    final failingStore = TravelStore(repository: failing, artCatalog: const ArtCatalog.empty());
    addTearDown(failingStore.dispose);
    await pumpEventQueue();
    expect(failingStore.isLoading, isFalse);
    expect(failingStore.error, 'Couldn\'t load your bookings.');
  });

  test('deleting the last booking of an automatic trip removes the trip', () async {
    await store.deleteBooking(store.bookings.single);
    await pumpEventQueue();
    expect(store.plans, isEmpty);
  });

  test('an automatic trip with a Holiday Pass keeps its dates when its last booking goes', () async {
    store.keepWhenEmpty = (plan) => plan.id == 'orlando';
    await store.deleteBooking(store.bookings.single);
    await pumpEventQueue();
    final kept = store.plan('orlando')!;
    expect((kept.trip.plannedStart, kept.trip.plannedEnd), (d(10, 12), d(10, 18)));

    // Booked again on those dates: it joins the same trip, pass and all.
    final again = await store.saveBooking(
      booking('hotel2', BookingKind.stay, d(10, 12), tripId: '', endDate: d(10, 18)),
    );
    expect(again.booking.tripId, 'orlando');
  });

  test('a trip with planned dates stays when its last booking goes', () async {
    final planned = await store.createTrip('Lisbon', start: d(12, 1), end: d(12, 5));
    await store.saveBooking(booking('x', BookingKind.dining, d(12, 2), tripId: planned.id));
    await pumpEventQueue();
    await store.deleteBooking(store.booking('x')!);
    await pumpEventQueue();
    expect(store.plan(planned.id), isNotNull);
  });

  test('a trip started by a booking knows its place from its name', () async {
    final result = await store.saveBooking(
      booking('out', BookingKind.flight, d(12, 1), tripId: '', title: 'London to Tokyo'),
    );
    await pumpEventQueue();
    expect(result.tripTitle, 'Tokyo');
    expect(store.plan(store.booking('out')!.tripId)!.trip.destination?.label, 'Tokyo, Japan');
  });

  test('a booking on a new trip\'s dates joins it automatically', () async {
    final planned = await store.createTrip('Lisbon', start: d(12, 1), end: d(12, 5));
    await pumpEventQueue();
    final result = await store.saveBooking(booking('x', BookingKind.dining, d(12, 3), tripId: ''));
    await pumpEventQueue();
    expect(result.newTrip, isFalse);
    expect(store.booking('x')?.tripId, planned.id);
  });

  test('changing a trip\'s dates keeps it covering its bookings', () async {
    final orlando = store.plans.single;
    await store.updateTrip(orlando.trip.copyWith(plannedStart: d(10, 14), plannedEnd: d(10, 22)));
    await pumpEventQueue();
    final plan = store.plan('orlando')!;
    expect((plan.start, plan.end), (d(10, 12), d(10, 22)));
  });

  test('deleting a trip removes its bookings', () async {
    await store.deleteTrip(store.plans.single);
    await pumpEventQueue();
    expect(store.plans, isEmpty);
    expect(store.bookings, isEmpty);
  });
}

class _FailingBookingsRepository extends MemoryTravelRepository {
  @override
  Stream<List<Booking>> watchBookings() => Stream.error('Couldn\'t load your bookings.');
}
