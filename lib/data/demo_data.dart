import '../domain/domain.dart';

/// Sample trips built around [today], so demo mode always has a trip in
/// progress (day 3 of an Orlando holiday), one coming up and one in the past.
/// Handy for design work: every kind of card, in every state, on screen.
({List<Trip> trips, List<Booking> bookings}) buildDemoData(
  LocalDate today, {
  required String userId,
}) {
  final created = DateTime(2026, 1, 1);
  final trips = <Trip>[];
  final bookings = <Booking>[];

  Trip trip(String id, String title, TripTheme theme) {
    final t = Trip(
      id: id,
      title: title,
      theme: theme,
      ownerId: userId,
      memberIds: [userId],
      createdAt: created,
      updatedAt: created,
    );
    trips.add(t);
    return t;
  }

  void add(
    Trip trip,
    String id,
    BookingKind kind,
    String title,
    LocalDate date, {
    ClockTime? at,
    LocalDate? endDate,
    ClockTime? until,
    String? location,
    String? reference,
    String? notes,
    Map<String, String> details = const {},
  }) {
    bookings.add(
      Booking(
        id: id,
        tripId: trip.id,
        kind: kind,
        title: title,
        startDate: date,
        startTime: at,
        endDate: endDate,
        endTime: until,
        location: location,
        reference: reference,
        notes: notes,
        details: details,
        createdAt: created,
        updatedAt: created,
      ),
    );
  }

  // Orlando: started two days ago, so today is day 3.
  final orlando = trip('demo-orlando', 'Orlando', TripTheme.themepark);
  final d1 = today.addDays(-2);
  LocalDate day(int n) => d1.addDays(n - 1);

  add(orlando, 'o-flight-out', BookingKind.flight, 'London to Orlando', day(1),
      at: const ClockTime(10, 30), until: const ClockTime(14, 55),
      location: 'London Gatwick (LGW)', reference: 'X7K2PQ',
      details: {DetailKeys.flightNumber: 'BA 2037', DetailKeys.seats: '22A, 22B, 22C, 22D'});
  add(orlando, 'o-car', BookingKind.transport, 'Car hire', day(1),
      at: const ClockTime(16, 0), endDate: day(7), until: const ClockTime(9, 0),
      location: 'Orlando Airport, Level 1', reference: 'ALM-55821',
      details: {DetailKeys.company: 'Alamo'});
  add(orlando, 'o-hotel', BookingKind.stay, 'Lagoon Resort', day(1),
      at: const ClockTime(16, 0), endDate: day(7), until: const ClockTime(11, 0),
      location: '1600 Seven Seas Drive, Orlando', reference: 'LR-99312',
      details: {DetailKeys.room: '2214', DetailKeys.guests: '4'});
  add(orlando, 'o-water-park', BookingKind.attraction, 'Splash Lagoon Water Park', day(2),
      at: const ClockTime(10, 0), reference: 'SLW-2231',
      details: {DetailKeys.guests: '4'});
  add(orlando, 'o-dinner-2', BookingKind.dining, 'Harbour Pizza Co.', day(2),
      at: const ClockTime(18, 30), details: {DetailKeys.partySize: '4'});
  add(orlando, 'o-park', BookingKind.attraction, 'Sunshine Park', day(3),
      at: const ClockTime(9, 0), location: 'Sunshine Park main gate',
      reference: 'SP-448120', details: {DetailKeys.guests: '4'});
  add(orlando, 'o-lunch', BookingKind.dining, 'Sunshine Terrace', day(3),
      at: const ClockTime(12, 30), location: 'Castle Square, Sunshine Park',
      reference: 'ST-4412', details: {DetailKeys.partySize: '4'});
  add(orlando, 'o-dinner', BookingKind.dining, 'Lagoon Grill', day(3),
      at: const ClockTime(19, 15), location: 'Lagoon Resort, lobby level',
      details: {DetailKeys.partySize: '4'});
  add(orlando, 'o-fireworks', BookingKind.note, 'Fireworks from the beach', day(3),
      at: const ClockTime(21, 0), notes: 'Best view is by the lifeguard tower.\nBring a blanket.');
  add(orlando, 'o-airboat', BookingKind.activity, 'Everglades airboat tour', day(4),
      at: const ClockTime(10, 0), until: const ClockTime(12, 0),
      location: 'Kissimmee Boat Dock', reference: 'EAT-7781',
      details: {DetailKeys.guests: '4'});
  add(orlando, 'o-show', BookingKind.event, 'Evening Circus Show', day(4),
      at: const ClockTime(18, 30), location: 'Lakeside Theatre',
      reference: 'CIR-30412', details: {DetailKeys.seats: 'Row F, 12–15'});
  add(orlando, 'o-breakfast', BookingKind.dining, 'Pancake House', day(5),
      at: const ClockTime(7, 45), details: {DetailKeys.partySize: '4'});
  add(orlando, 'o-studios', BookingKind.attraction, 'Starport Studios', day(5),
      at: const ClockTime(8, 30), reference: 'STS-99102',
      details: {DetailKeys.guests: '4'});
  add(orlando, 'o-space', BookingKind.activity, 'Space Center tour', day(6),
      at: const ClockTime(9, 0), until: const ClockTime(16, 0),
      location: 'Cape Canaveral', details: {DetailKeys.guests: '4'});
  add(orlando, 'o-pack', BookingKind.note, 'Pack souvenirs in the big case', day(6));
  add(orlando, 'o-flight-home', BookingKind.flight, 'Orlando to London', day(7),
      at: const ClockTime(18, 40), endDate: day(8), until: const ClockTime(7, 10),
      location: 'Orlando International (MCO)', reference: 'X7K2PQ',
      details: {DetailKeys.flightNumber: 'BA 2036', DetailKeys.seats: '31A, 31B, 31C, 31D'});

  // Lake District: coming up in about two months.
  final lakes = trip('demo-lakes', 'Lake District', TripTheme.countryside);
  final l1 = today.addDays(58);
  add(lakes, 'l-train', BookingKind.transport, 'London to Windermere', l1,
      at: const ClockTime(8, 30), until: const ClockTime(12, 10),
      location: 'London Euston', reference: 'TRN-5521',
      details: {DetailKeys.company: 'Avanti West Coast'});
  add(lakes, 'l-cottage', BookingKind.stay, 'Fellside Cottage', l1,
      at: const ClockTime(15, 0), endDate: l1.addDays(3), until: const ClockTime(10, 0),
      location: 'Ambleside', reference: 'FC-2091', details: {DetailKeys.guests: '2'});
  add(lakes, 'l-boat', BookingKind.activity, 'Windermere boat trip', l1.addDays(1),
      at: const ClockTime(11, 0), details: {DetailKeys.guests: '2'});

  // Paris: a few months ago.
  final paris = trip('demo-paris', 'Paris', TripTheme.city);
  final p1 = today.addDays(-110);
  add(paris, 'p-train', BookingKind.transport, 'London to Paris', p1,
      at: const ClockTime(9, 1), until: const ClockTime(12, 20),
      location: 'St Pancras International', details: {DetailKeys.company: 'Eurostar'});
  add(paris, 'p-hotel', BookingKind.stay, 'Hotel Lumière', p1,
      at: const ClockTime(15, 0), endDate: p1.addDays(3), until: const ClockTime(11, 0),
      location: 'Rue Cler, Paris', details: {DetailKeys.room: '41'});
  add(paris, 'p-tower', BookingKind.attraction, 'Eiffel Tower summit', p1.addDays(1),
      at: const ClockTime(10, 30), details: {DetailKeys.guests: '2'});
  add(paris, 'p-bistro', BookingKind.dining, 'Le Petit Bistro', p1.addDays(1),
      at: const ClockTime(20, 0), details: {DetailKeys.partySize: '2'});

  return (trips: trips, bookings: bookings);
}
