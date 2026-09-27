/// The handful of booking types a holiday is made of.
///
/// Deliberately small: every kind gets its own form wording, its own card
/// shape and its own folder of artwork (see `assets/art/`).
enum BookingKind {
  flight,
  stay,
  attraction,
  dining,
  transport,
  activity,
  event,
  note;

  static BookingKind fromName(String? name) =>
      values.firstWhere((k) => k.name == name, orElse: () => note);

  KindSpec get spec => switch (this) {
    flight => _flight,
    stay => _stay,
    attraction => _attraction,
    dining => _dining,
    transport => _transport,
    activity => _activity,
    event => _event,
    note => _note,
  };
}

/// Keys for the kind-specific extras stored in `Booking.details`.
abstract final class DetailKeys {
  static const flightNumber = 'flightNumber';
  static const seats = 'seats';
  static const room = 'room';
  static const guests = 'guests';
  static const partySize = 'partySize';
  static const company = 'company';
}

/// One optional extra field on the booking form.
class DetailField {
  const DetailField(this.key, this.label, {this.hint, this.numeric = false});

  final String key;
  final String label;
  final String? hint;
  final bool numeric;
}

/// Everything the app needs to know to ask for, order and describe a kind.
class KindSpec {
  const KindSpec({
    required this.label,
    required this.titleLabel,
    required this.titleHint,
    required this.startLabel,
    this.endLabel,
    this.endUsuallyLaterDay = false,
    required this.locationLabel,
    this.fields = const [],
    required this.typicalDuration,
    required this.startEvent,
    required this.endEvent,
  });

  /// Short name used in pickers and eyebrows, e.g. "Flight".
  final String label;
  final String titleLabel;
  final String titleHint;
  final String startLabel;

  /// Label for the end date/time, or null when the kind has no end.
  final String? endLabel;

  /// Stays usually end on a later day, so the form defaults to the next day.
  final bool endUsuallyLaterDay;
  final String locationLabel;
  final List<DetailField> fields;

  /// How long an item "lasts" when no end time was entered. Used to decide
  /// when a card moves from "happening now" to "done".
  final Duration typicalDuration;

  /// Names for the two ends of a booking that spans several days,
  /// e.g. "Check-in" / "Check-out".
  final String startEvent;
  final String endEvent;

  bool get hasEnd => endLabel != null;
}

const _flight = KindSpec(
  label: 'Flight',
  titleLabel: 'Flight',
  titleHint: 'London to Orlando',
  startLabel: 'Departs',
  endLabel: 'Lands',
  locationLabel: 'Departure airport',
  fields: [
    DetailField(DetailKeys.flightNumber, 'Flight number', hint: 'BA 2037'),
    DetailField(DetailKeys.seats, 'Seats', hint: '14A, 14B'),
  ],
  typicalDuration: Duration(hours: 3),
  startEvent: 'Departs',
  endEvent: 'Lands',
);

const _stay = KindSpec(
  label: 'Stay',
  titleLabel: 'Hotel or rental',
  titleHint: 'Lagoon Resort',
  startLabel: 'Check-in',
  endLabel: 'Check-out',
  endUsuallyLaterDay: true,
  locationLabel: 'Address',
  fields: [
    DetailField(DetailKeys.room, 'Room', hint: '2214'),
    DetailField(DetailKeys.guests, 'Guests', hint: '4', numeric: true),
  ],
  typicalDuration: Duration.zero,
  startEvent: 'Check-in',
  endEvent: 'Check-out',
);

const _attraction = KindSpec(
  label: 'Tickets',
  titleLabel: 'Park or attraction',
  titleHint: 'Sunshine Park',
  startLabel: 'Entry',
  endLabel: 'Until',
  locationLabel: 'Where',
  fields: [
    DetailField(DetailKeys.guests, 'Tickets for', hint: '2', numeric: true),
  ],
  typicalDuration: Duration(hours: 4),
  startEvent: 'Opens',
  endEvent: 'Last day',
);

const _dining = KindSpec(
  label: 'Dining',
  titleLabel: 'Restaurant',
  titleHint: 'Lagoon Grill',
  startLabel: 'Reservation',
  locationLabel: 'Address',
  fields: [
    DetailField(DetailKeys.partySize, 'Table for', hint: '4', numeric: true),
  ],
  typicalDuration: Duration(minutes: 90),
  startEvent: 'Reservation',
  endEvent: 'Ends',
);

const _transport = KindSpec(
  label: 'Transport',
  titleLabel: 'Transfer, train or car hire',
  titleHint: 'Airport transfer',
  startLabel: 'Departs / pick-up',
  endLabel: 'Arrives / drop-off',
  locationLabel: 'Pick-up point',
  fields: [DetailField(DetailKeys.company, 'Company', hint: 'Alamo')],
  typicalDuration: Duration(hours: 1),
  startEvent: 'Pick-up',
  endEvent: 'Drop-off',
);

const _activity = KindSpec(
  label: 'Activity',
  titleLabel: 'Tour or activity',
  titleHint: 'Airboat tour',
  startLabel: 'Starts',
  endLabel: 'Ends',
  locationLabel: 'Meeting point',
  fields: [
    DetailField(DetailKeys.guests, 'Tickets for', hint: '2', numeric: true),
  ],
  typicalDuration: Duration(hours: 3),
  startEvent: 'Starts',
  endEvent: 'Ends',
);

const _event = KindSpec(
  label: 'Show',
  titleLabel: 'Show or event',
  titleHint: 'Evening circus show',
  startLabel: 'Starts',
  endLabel: 'Ends',
  locationLabel: 'Venue',
  fields: [DetailField(DetailKeys.seats, 'Seats', hint: 'Row F, 12–15')],
  typicalDuration: Duration(hours: 3),
  startEvent: 'Starts',
  endEvent: 'Ends',
);

const _note = KindSpec(
  label: 'Note',
  titleLabel: 'Reminder',
  titleHint: 'Pack sunscreen',
  startLabel: 'When',
  locationLabel: 'Where',
  typicalDuration: Duration.zero,
  startEvent: 'Note',
  endEvent: 'Note',
);
