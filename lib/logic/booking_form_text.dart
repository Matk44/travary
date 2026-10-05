import '../domain/domain.dart';
import 'formatters.dart';
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

/// What a booking spanning [start] to [end] lasts, between its two dates
/// on the form: "2 nights" for a stay, "3 days" for anything else. Null on
/// a single day.
String? bookingSpanLabel(BookingKind kind, LocalDate start, LocalDate? end) {
  if (end == null || !end.isAfter(start)) return null;
  final days = start.daysUntil(end);
  if (kind == BookingKind.stay) return formatNights(days);
  return '${days + 1} days';
}

/// Under a form's title: the trip it's going into, "Japan · 11–30 Oct", or
/// what happens without one.
String formTripLine(TripPlan? plan) {
  if (plan == null) return 'Joins a trip by its dates';
  final start = plan.start;
  final end = plan.end;
  final title = plan.trip.title.trim().isEmpty ? 'Your trip' : plan.trip.title.trim();
  return start == null || end == null ? title : '$title · ${formatDayMonthRange(start, end)}';
}
