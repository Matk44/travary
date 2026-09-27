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
///     trips/{tripId}/bookings/{bookingId} the booking + a copy of memberIds
///
/// Every booking carries a copy of its trip's `memberIds`, so all of a
/// traveller's bookings load with one collection-group query and the read
/// rule never has to look the trip up. (Looking it up fails for a trip
/// created a moment ago, before the server has it.) When trip members
/// change, their bookings' copies must be updated in the same batch.
class FirestoreTravelRepository implements TravelRepository {
  FirestoreTravelRepository({
    required FirebaseFirestore firestore,
    required this.userId,
  }) : _db = firestore;

  final FirebaseFirestore _db;
  final _errors = StreamController<String>.broadcast();

  /// Latest known members of each trip, for stamping onto bookings.
  final _membersByTrip = <String, List<String>>{};

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
      .transform(_friendlyErrors('trips'))
      .map((snapshot) {
        final trips = [for (final d in snapshot.docs) Trip.fromJson(d.id, d.data())];
        for (final trip in trips) {
          _membersByTrip[trip.id] = trip.memberIds;
        }
        return trips;
      });

  @override
  Stream<List<Booking>> watchBookings() => _db
      .collectionGroup('bookings')
      .where('memberIds', arrayContains: userId)
      .snapshots()
      .transform(_friendlyErrors('bookings'))
      .map((s) => [for (final d in s.docs) Booking.fromJson(d.id, d.data())]);

  @override
  Future<void> createTrip(Trip trip) async {
    _membersByTrip[trip.id] = trip.memberIds;
    _sync(_trips.doc(trip.id).set(trip.toJson()));
  }

  /// Only the editable fields: member lists are the server's, and this
  /// phone's copy may be a few seconds old.
  @override
  Future<void> updateTrip(Trip trip) async =>
      _sync(_trips.doc(trip.id).update(trip.toEditableJson()));

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
    _bookingsOf(booking.tripId).doc(booking.id).set(_bookingData(booking)),
  );

  @override
  Future<void> moveBooking(Booking booking, String fromTripId) async {
    final batch = _db.batch()
      ..delete(_bookingsOf(fromTripId).doc(booking.id))
      ..set(_bookingsOf(booking.tripId).doc(booking.id), _bookingData(booking));
    _sync(batch.commit());
  }

  @override
  Future<void> deleteBooking(Booking booking) async =>
      _sync(_bookingsOf(booking.tripId).doc(booking.id).delete());

  Map<String, Object?> _bookingData(Booking booking) => {
    ...booking.toJson(),
    'memberIds': _membersByTrip[booking.tripId] ?? [userId],
  };

  /// Turns Firestore listener errors into a sentence for the traveller.
  /// The code stays in brackets to help with support.
  StreamTransformer<T, T> _friendlyErrors<T>(String what) =>
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) => sink.addError(
          error is FirebaseException
              ? 'Couldn\'t load your $what (${error.code}). Try again shortly.'
              : 'Couldn\'t load your $what.',
          stackTrace,
        ),
      );

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
