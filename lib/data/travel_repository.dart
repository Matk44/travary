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

  /// Creates [trip] with its owner as the only member.
  Future<void> createTrip(Trip trip);

  /// Saves the traveller-editable fields of [trip] (title, theme, dates).
  Future<void> updateTrip(Trip trip);

  /// Changes only [tripId]'s name and place ([Trip.autoName] following its
  /// bookings): nothing this phone's copy may have a few seconds old, such
  /// as dates someone else just changed.
  Future<void> renameTrip(String tripId, {required String title, TripDestination? destination});

  /// Adds or changes one item on [tripId]'s checklist (or packing list),
  /// leaving the rest as they are (someone else may be ticking another).
  Future<void> saveChecklistItem(String tripId, ChecklistItem item, {TripList list = TripList.checklist});

  Future<void> deleteChecklistItem(String tripId, String itemId, {TripList list = TripList.checklist});

  /// Deletes [trip] and every one of its [bookings].
  Future<void> deleteTrip(Trip trip, Iterable<Booking> bookings);

  Future<void> saveBooking(Booking booking);

  /// Saves [booking] into its new trip and removes it from [fromTripId].
  Future<void> moveBooking(Booking booking, String fromTripId);

  Future<void> deleteBooking(Booking booking);

  Future<void> dispose();
}
