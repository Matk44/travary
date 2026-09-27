import '../domain/domain.dart';

/// Where trips and bookings are kept.
///
/// Writes return as soon as the change is applied locally. A cloud-backed
/// implementation syncs in the background and reports sync failures on
/// [errors], so the UI never waits on the network.
abstract interface class TravelRepository {
  /// The signed-in traveller (anonymous until they create an account).
  String get userId;

  /// A short label for settings, e.g. "Demo data" or "Cloud".
  String get label;

  Stream<List<Trip>> watchTrips();
  Stream<List<Booking>> watchBookings();

  /// Human-readable background sync failures.
  Stream<String> get errors;

  String newId();

  Future<void> saveTrip(Trip trip);

  /// Deletes [trip] and every one of its [bookings].
  Future<void> deleteTrip(Trip trip, Iterable<Booking> bookings);

  Future<void> saveBooking(Booking booking);

  /// Saves [booking] into its new trip and removes it from [fromTripId].
  Future<void> moveBooking(Booking booking, String fromTripId);

  Future<void> deleteBooking(Booking booking);

  Future<void> dispose();
}
