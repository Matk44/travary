import 'dart:async';
import 'dart:math';

import '../domain/domain.dart';
import 'latest_stream.dart';
import 'travel_repository.dart';

/// Keeps everything in memory. Used for demo mode (design work with sample
/// data) and tests. Nothing survives a restart.
class MemoryTravelRepository implements TravelRepository {
  MemoryTravelRepository({this.userId = 'demo-traveller', this.label = 'Demo data'});

  @override
  final String userId;

  @override
  final String label;

  final _trips = <String, Trip>{};
  final _bookings = <String, Booking>{};
  final _tripsController = StreamController<List<Trip>>.broadcast();
  final _bookingsController = StreamController<List<Booking>>.broadcast();
  final _random = Random();

  List<Trip> get trips => List.unmodifiable(_trips.values);
  List<Booking> get bookings => List.unmodifiable(_bookings.values);

  @override
  Stream<List<Trip>> watchTrips() => startWith(() => trips, _tripsController.stream);

  @override
  Stream<List<Booking>> watchBookings() => startWith(() => bookings, _bookingsController.stream);

  @override
  Stream<String> get errors => const Stream.empty();

  @override
  String newId() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      List.generate(20, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
    );
  }

  @override
  Future<void> saveTrip(Trip trip) async {
    _trips[trip.id] = trip;
    _tripsController.add(trips);
  }

  @override
  Future<void> deleteTrip(Trip trip, Iterable<Booking> bookings) async {
    for (final booking in bookings) {
      _bookings.remove(booking.id);
    }
    _trips.remove(trip.id);
    _bookingsController.add(this.bookings);
    _tripsController.add(trips);
  }

  @override
  Future<void> saveBooking(Booking booking) async {
    _bookings[booking.id] = booking;
    _bookingsController.add(bookings);
  }

  @override
  Future<void> moveBooking(Booking booking, String fromTripId) =>
      saveBooking(booking);

  @override
  Future<void> deleteBooking(Booking booking) async {
    _bookings.remove(booking.id);
    _bookingsController.add(bookings);
  }

  /// Replaces all data at once (used to reset demo data).
  void replaceAll(List<Trip> trips, List<Booking> bookings) {
    _trips
      ..clear()
      ..addEntries(trips.map((t) => MapEntry(t.id, t)));
    _bookings
      ..clear()
      ..addEntries(bookings.map((b) => MapEntry(b.id, b)));
    _tripsController.add(this.trips);
    _bookingsController.add(this.bookings);
  }

  @override
  Future<void> dispose() async {
    await _tripsController.close();
    await _bookingsController.close();
  }
}
