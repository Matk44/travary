import '../domain/domain.dart';
import 'formatters.dart';
import 'transport.dart';
import 'trip_plan.dart';

/// The add or edit form's own wording for a kind of booking: its title,
/// the heading printed on the ticket, and the button.
class BookingFormText {
  const BookingFormText({required this.title, required this.heading, required this.button});

  /// "Add a stay", "Edit stay".
  final String title;

  /// On the ticket's band: "YOUR STAY".
  final String heading;

  /// "Add stay", "Save changes".
  final String button;
}

BookingFormText bookingFormText(BookingKind kind, {bool editing = false}) {
  final (String add, String thing) = switch (kind) {
    BookingKind.flight => ('Add a flight', 'flight'),
    BookingKind.stay => ('Add a stay', 'stay'),
    BookingKind.attraction => ('Add tickets', 'tickets'),
    BookingKind.dining => ('Add a table', 'table'),
    BookingKind.transport => ('Add transport', 'transport'),
    BookingKind.activity => ('Add an activity', 'activity'),
    BookingKind.event => ('Add an event', 'event'),
    BookingKind.note => ('Add a note', 'note'),
  };
  return BookingFormText(
    title: editing ? 'Edit $thing' : add,
    heading: 'YOUR ${thing.toUpperCase()}',
    button: editing ? 'Save changes' : 'Add $thing',
  );
}

/// The line under the first-booking form's heading in onboarding. Only a
/// booking read from a file or the airline's schedule asks to be checked;
/// one typed in is the traveller's own.
String onboardingFormSubtitle({required bool finding, required bool checking}) {
  if (finding) return 'Flight number and the day it leaves.';
  return checking ? 'Check the details before adding it.' : 'A name and a day are all it needs.';
}

/// What [booking] lasts, between its two dates on the form: "2 nights" for
/// a stay, "Overnight" for a flight or journey into the next day (a
/// sleeper train isn't a two-day booking), "3 days" for anything else.
/// Null on a single day.
String? bookingSpanLabel(Booking booking) {
  final end = booking.endDate;
  if (end == null || !end.isAfter(booking.startDate)) return null;
  final days = booking.startDate.daysUntil(end);
  if (booking.kind == BookingKind.stay) return formatNights(days);
  if (booking.kind == BookingKind.flight || isJourney(booking)) return days == 1 ? 'Overnight' : formatNights(days);
  return '${days + 1} days';
}

/// Under a form's title: the trip it's going into, "Japan · 11–30 Oct",
/// "Moves to Japan · 11–30 Oct" when an edit takes it out of its trip, or
/// "Starts a new trip".
String formTripLine(TripPlan? plan, {bool moves = false}) {
  if (plan == null) return 'Starts a new trip';
  final start = plan.start;
  final end = plan.end;
  final title = _tripTitle(plan);
  final line = start == null || end == null ? title : '$title · ${formatDayMonthRange(start, end)}';
  return moves ? 'Moves to $line' : line;
}

/// Asked before a booking stretches a trip that formed from its bookings
/// well past them: "Add to Tokyo?".
class StretchQuestion {
  const StretchQuestion({required this.title, required this.message, required this.keep, required this.other});

  final String title;
  final String message;

  /// Into the trip anyway: "Add to Tokyo".
  final String keep;

  /// Where its dates put it instead: "Add to Paris", "Start a new trip".
  final String other;
}

/// [plan] (without the booking being edited) runs to fewer days than a
/// booking from [start] to [end]; [alternative] is where its dates would
/// put it instead (null: a new trip).
StretchQuestion stretchQuestion(
  TripPlan plan,
  LocalDate start,
  LocalDate end, {
  TripPlan? alternative,
  bool editing = false,
}) {
  final title = _tripTitle(plan);
  final from = LocalDate.min(plan.start!, start);
  final to = LocalDate.max(plan.end!, end);
  return StretchQuestion(
    title: editing ? 'Keep in $title?' : 'Add to $title?',
    message:
        '$title runs ${formatDayMonthRange(plan.start!, plan.end!)} so far. '
        'This is on ${formatDayMonthRange(start, end)}, so the trip would run ${formatDayMonthRange(from, to)}.',
    keep: editing ? 'Keep in $title' : 'Add to $title',
    other: alternative == null ? 'Start a new trip' : 'Add to ${_tripTitle(alternative)}',
  );
}

/// Under a draft Smart Import found outside the trip it was opened from:
/// "Not on Japan's dates, so it goes to Paris".
String outsideTripText(TripPlan asked, TripPlan? elsewhere) =>
    'Not on ${_tripTitle(asked)}\'s dates, so it '
    '${elsewhere == null ? 'starts a new trip' : 'goes to ${_tripTitle(elsewhere)}'}';

String _tripTitle(TripPlan plan) => plan.trip.title.trim().isEmpty ? 'Your trip' : plan.trip.title.trim();
