import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/domain.dart';
import 'travel_repository.dart';

/// Cloud storage in Firestore, with Firestore's offline cache doing the
/// local-first work.
///
/// Layout (built for family sharing):
///
///     trips/{tripId}                      title, theme, ownerId, memberIds[]
///     trips/{tripId}/bookings/{bookingId} the booking
///
/// A trip is visible to everyone in its `memberIds`; bookings inherit that
/// through the security rules (see `firestore.rules`).
class FirestoreTravelRepository implements TravelRepository {
  FirestoreTravelRepository({
    required FirebaseFirestore firestore,
    required this.userId,
  }) : _db = firestore;

  final FirebaseFirestore _db;
  final _errors = StreamController<String>.broadcast();

  @override
  final String userId;

  @override
  String get label => 'Cloud';

  CollectionReference<Map<String, dynamic>> get _trips => _db.collection('trips');

  CollectionReference<Map<String, dynamic>> _bookingsOf(String tripId) =>
      _trips.doc(tripId).collection('bookings');

  @override
  Stream<String> get errors => _errors.stream;

  @override
  String newId() => _trips.doc().id;

  @override
  Stream<List<Trip>> watchTrips() => _trips
      .where('memberIds', arrayContains: userId)
      .snapshots()
      .map((s) => [for (final d in s.docs) Trip.fromJson(d.id, d.data())]);

  /// Merges one live listener per trip into a single list of bookings.
  @override
  Stream<List<Booking>> watchBookings() {
    late final StreamController<List<Booking>> controller;
    StreamSubscription<List<Trip>>? tripsSubscription;
    final perTrip = <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final byTrip = <String, List<Booking>>{};

    void emit() => controller.add([for (final list in byTrip.values) ...list]);

    void onTrips(List<Trip> trips) {
      final ids = {for (final t in trips) t.id};
      for (final gone in perTrip.keys.where((id) => !ids.contains(id)).toList()) {
        perTrip.remove(gone)?.cancel();
        byTrip.remove(gone);
      }
      for (final id in ids.where((id) => !perTrip.containsKey(id))) {
        perTrip[id] = _bookingsOf(id).snapshots().listen((snapshot) {
          byTrip[id] = [
            for (final d in snapshot.docs) Booking.fromJson(d.id, d.data()),
          ];
          emit();
        }, onError: controller.addError);
      }
      emit();
    }

    controller = StreamController<List<Booking>>(
      onListen: () {
        tripsSubscription = watchTrips().listen(
          onTrips,
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await tripsSubscription?.cancel();
        for (final subscription in perTrip.values) {
          await subscription.cancel();
        }
        perTrip.clear();
        byTrip.clear();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> saveTrip(Trip trip) async =>
      _sync(_trips.doc(trip.id).set(trip.toJson()));

  @override
  Future<void> deleteTrip(Trip trip, Iterable<Booking> bookings) async {
    final batch = _db.batch();
    for (final booking in bookings) {
      batch.delete(_bookingsOf(trip.id).doc(booking.id));
    }
    batch.delete(_trips.doc(trip.id));
    _sync(batch.commit());
  }

  @override
  Future<void> saveBooking(Booking booking) async => _sync(
    _bookingsOf(booking.tripId).doc(booking.id).set(booking.toJson()),
  );

  @override
  Future<void> moveBooking(Booking booking, String fromTripId) async {
    final batch = _db.batch()
      ..delete(_bookingsOf(fromTripId).doc(booking.id))
      ..set(_bookingsOf(booking.tripId).doc(booking.id), booking.toJson());
    _sync(batch.commit());
  }

  @override
  Future<void> deleteBooking(Booking booking) async =>
      _sync(_bookingsOf(booking.tripId).doc(booking.id).delete());

  /// Firestore applies writes to its local cache immediately, but the
  /// returned future only completes once the server confirms, which never
  /// happens offline. So don't wait for it; just report failures.
  void _sync(Future<void> write) {
    unawaited(
      write.catchError((Object error) {
        _errors.add(
          error is FirebaseException
              ? 'Couldn\'t sync a change (${error.code}).'
              : 'Couldn\'t sync a change.',
        );
      }),
    );
  }

  @override
  Future<void> dispose() => _errors.close();
}
