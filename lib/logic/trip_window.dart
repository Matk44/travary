import '../domain/domain.dart';
import 'formatters.dart';
import 'trip_assignment.dart';
import 'trip_plan.dart';

/// Days either side of a trip's planned dates a booking may still use (the
/// red-eye out the night before, the flight home that lands next morning):
/// the same margin that lets a booking join a trip by its dates.
const travelDayMargin = tripMarginDays;

/// A run of days, first to last inclusive.
class DateWindow {
  const DateWindow(this.first, this.last);

  final LocalDate first;
  final LocalDate last;

  bool contains(LocalDate date) => !date.isBefore(first) && !date.isAfter(last);

  /// Whether a booking from [start] to [end] sits wholly inside.
  bool covers(LocalDate start, LocalDate end) => contains(start) && contains(end);

  LocalDate clamp(LocalDate date) => date.isBefore(first) ? first : (date.isAfter(last) ? last : date);

  @override
  bool operator ==(Object other) => other is DateWindow && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);

  @override
  String toString() => 'DateWindow($first → $last)';
}

/// The days a booking in [plan] may use, or null when any will do.
///
/// A trip with planned dates (started with "New trip", or given dates
/// since) keeps its bookings to them, with a travel day either side, and
/// never shuts out what's already booked. A trip that formed from its
/// bookings has no dates of its own: it follows them.
DateWindow? bookingWindowFor(TripPlan plan) {
  final start = plan.trip.plannedStart;
  if (start == null) return null;
  final end = plan.trip.plannedEnd ?? start;
  var first = start.addDays(-travelDayMargin);
  var last = end.addDays(travelDayMargin);
  final booked = bookedSpan(plan.bookings);
  if (booked != null) {
    first = LocalDate.min(first, booked.start);
    last = LocalDate.max(last, booked.end);
  }
  return DateWindow(first, last);
}

/// [plan] as if booking [bookingId] weren't in it: its dates while that
/// booking is being edited.
TripPlan withoutBooking(TripPlan plan, String bookingId) => plan.bookings.any((b) => b.id == bookingId)
    ? TripPlan(plan.trip, plan.bookings.where((b) => b.id != bookingId))
    : plan;

/// Whether a booking from [start] to [end] belongs with [plan]: inside its
/// window ([bookingWindowFor]) when it has planned dates, else within
/// [looseMarginDays] of what it has booked. A trip with nothing to go by
/// takes anything.
bool fitsTrip(LocalDate start, LocalDate end, TripPlan plan, {int looseMarginDays = tripMarginDays}) {
  final window = bookingWindowFor(plan);
  if (window != null) return window.covers(start, end);
  if (!plan.hasDates) return true;
  return gapBetween(start, end, plan.start!, plan.end!) <= looseMarginDays;
}

/// Where a booking on the add or edit form goes.
class TripPlacement {
  const TripPlacement(this.plan, {this.stretches = false, this.alternative});

  /// The trip it goes into. Null: a trip of its own (a new one).
  final TripPlan? plan;

  /// It's going into [plan], a trip that formed from its bookings, well
  /// outside their dates: worth asking first (a typed month is easy to get
  /// wrong). [alternative] is where its dates would put it instead.
  final bool stretches;
  final TripPlan? alternative;
}

/// Where a booking from [start] to [end] goes.
///
/// [tripId] is the trip it's in, was added from or was imported into, or
/// empty to go by its dates. It keeps that trip while the dates fit it.
/// When they don't, a trip with planned dates lets it go to the trip its
/// dates fall in (or a new one); a trip that formed from its bookings
/// keeps it but asks ([TripPlacement.stretches]). A trip of its own that
/// it's alone in follows it into a trip its new dates fall in.
///
/// [chosen]: the traveller picked [tripId] on the form, so it stays put.
/// [editing]: the booking being edited, left out of every trip's dates;
/// with [datesChanged] false it stays where it is. [looseMarginDays]: how
/// far from a formed trip's bookings still fits it (wider for Smart
/// Import, whose dates come off the ticket).
TripPlacement placeBooking({
  required LocalDate start,
  required LocalDate end,
  required List<TripPlan> plans,
  String tripId = '',
  bool chosen = false,
  String? editing,
  bool datesChanged = true,
  int looseMarginDays = tripMarginDays,
}) {
  final trips = editing == null ? plans : [for (final plan in plans) withoutBooking(plan, editing)];
  final asked = tripId.isEmpty ? null : trips.where((p) => p.id == tripId).firstOrNull;
  if (asked == null) return TripPlacement(findTripFor(start, end, trips));
  if (chosen || !datesChanged || fitsTrip(start, end, asked, looseMarginDays: looseMarginDays)) {
    // Alone in a trip of its own: new dates inside another trip join it.
    if (!chosen && datesChanged && asked.bookings.isEmpty && asked.trip.plannedStart == null) {
      final others = [
        for (final plan in trips)
          if (plan.id != asked.id) plan,
      ];
      return TripPlacement(findTripFor(start, end, others, marginDays: 0) ?? asked);
    }
    return TripPlacement(asked);
  }
  final others = [
    for (final plan in trips)
      if (plan.id != asked.id) plan,
  ];
  final elsewhere = findTripFor(start, end, others);
  if (asked.trip.plannedStart == null) return TripPlacement(asked, stretches: true, alternative: elsewhere);
  return TripPlacement(elsewhere);
}

/// New dates for a booking moved into [window] (choosing a trip on the
/// form): it starts on [preferredStart] if it was outside, keeping its
/// length while it fits. Dates already inside stay as they are.
({LocalDate start, LocalDate? end}) moveInto(
  DateWindow window,
  LocalDate start,
  LocalDate? end, {
  required LocalDate preferredStart,
}) {
  if (window.covers(start, end ?? start)) return (start: start, end: end);
  final newStart = window.contains(start) ? start : window.clamp(preferredStart);
  if (end == null) return (start: newStart, end: null);
  final moved = end.addDays(start.daysUntil(newStart));
  final newEnd = window.clamp(moved);
  return (start: newStart, end: newEnd.isAfter(newStart) ? newEnd : null);
}

/// Bookings that trip dates [start]–[end] would leave out: more than a
/// travel day outside them.
List<Booking> bookingsLeftOut(Iterable<Booking> bookings, LocalDate start, LocalDate end) {
  final window = DateWindow(start.addDays(-travelDayMargin), end.addDays(travelDayMargin));
  return [
    for (final booking in bookings)
      if (!window.covers(booking.startDate, booking.lastDate)) booking,
  ];
}

/// Why trip dates can't leave [leftOut] out, under the dates: "Hotel
/// Gracery (14–16 Oct) would be left out. …".
String leftOutText(List<Booking> leftOut) {
  if (leftOut.length == 1) {
    final booking = leftOut.single;
    final when = formatDayMonthRange(booking.startDate, booking.lastDate);
    return '${booking.title} ($when) would be left out. Choose dates that include it, or change the booking first.';
  }
  final span = bookedSpan(leftOut)!;
  return '${leftOut.length} bookings would be left out (${formatDayMonthRange(span.start, span.end)}). '
      'Choose dates that include them, or change those bookings first.';
}

/// The first other trip that dates [start]–[end] overlap, if any.
TripPlan? overlappingTrip(LocalDate start, LocalDate end, List<TripPlan> plans, {String? except}) {
  for (final plan in plans) {
    if (plan.id == except || !plan.hasDates) continue;
    if (gapBetween(start, end, plan.start!, plan.end!) == 0) return plan;
  }
  return null;
}

/// Under the dates of a trip that overlaps [other]: "These dates overlap
/// Japan holiday (11–23 Oct)."
String overlapText(TripPlan other) =>
    'These dates overlap ${other.trip.title} (${formatDayMonthRange(other.start!, other.end!)}).';
