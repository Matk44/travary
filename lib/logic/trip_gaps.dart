import '../domain/domain.dart';
import 'formatters.dart';
import 'transport.dart';
import 'trip_plan.dart';
import 'trip_route.dart';

/// What a trip seems to be missing.
enum PlanGapKind { flightOut, stay, flightHome }

/// Something a trip usually needs that isn't booked yet: nights with
/// nowhere to stay, or the flight at one end of a trip that flies at the
/// other. Shown under the trip's plan with a way to add it, or to say it
/// isn't needed ([Trip.hiddenGaps]).
class PlanGap {
  const PlanGap({required this.kind, required this.start, this.end});

  final PlanGapKind kind;

  /// The first night without a stay, or the day of the missing flight.
  final LocalDate start;

  /// For a stay: the morning after the last night (the check-out date).
  final LocalDate? end;

  /// Stable while the gap is the same gap, for hiding it: "stay:2026-10-14",
  /// "flight-out", "flight-home".
  String get id => switch (kind) {
    PlanGapKind.stay => 'stay:${start.toIso()}',
    PlanGapKind.flightOut => 'flight-out',
    PlanGapKind.flightHome => 'flight-home',
  };

  /// The kind of booking that fills it.
  BookingKind get bookingKind => kind == PlanGapKind.stay ? BookingKind.stay : BookingKind.flight;

  @override
  bool operator ==(Object other) => other is PlanGap && other.kind == kind && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);

  @override
  String toString() => 'PlanGap($id → $end)';
}

/// The gaps in [plan], in date order, leaving out any the travellers hid.
///
/// - A trip with nothing booked suggests its flight out and somewhere to
///   stay for the whole trip.
/// - Every night between the first and last day needs a stay, unless a
///   stay, an overnight flight or an overnight journey (a sleeper train, a
///   night ferry) covers it.
/// - Flights are only suggested once the trip flies: one at the start and
///   none at the end means a flight home (and the other way round). A
///   flight within the trip ([isInternalFlight]: Osaka to Sapporo) is
///   neither, and a trip with only those needs both. A trip without
///   flights may well be a road trip.
List<PlanGap> planGaps(TripPlan plan) {
  final start = plan.start;
  final end = plan.end;
  if (start == null || end == null) return const [];
  final gaps = <PlanGap>[];

  final flights = [
    for (final b in plan.bookings)
      if (b.kind == BookingKind.flight) b,
  ];
  if (plan.bookings.isEmpty) {
    gaps.add(PlanGap(kind: PlanGapKind.flightOut, start: start));
  } else if (plan.dayCount >= 3 && flights.isNotEmpty) {
    final ends = [
      for (final f in flights)
        if (!isInternalFlight(f, plan.bookings)) f,
    ];
    final out = ends.any((f) => !f.startDate.isAfter(start.addDays(1)));
    final home = ends.any((f) => !f.startDate.isBefore(end.addDays(-1)));
    if ((out || ends.isEmpty) && !home) gaps.add(PlanGap(kind: PlanGapKind.flightHome, start: end));
    if ((home || ends.isEmpty) && !out) gaps.add(PlanGap(kind: PlanGapKind.flightOut, start: start));
  }

  // Nights are the dates you go to sleep on: the first day to the day
  // before the last.
  final covered = <LocalDate>{};
  for (final booking in plan.bookings) {
    if (booking.kind != BookingKind.stay && booking.kind != BookingKind.flight && !isJourney(booking)) continue;
    if (booking.kind == BookingKind.stay && !booking.spansDays) covered.add(booking.startDate);
    for (var night = booking.startDate; night.isBefore(booking.lastDate); night = night.addDays(1)) {
      covered.add(night);
    }
  }
  LocalDate? runStart;
  for (var night = start; night.isBefore(end); night = night.addDays(1)) {
    if (!covered.contains(night)) {
      runStart ??= night;
    } else if (runStart != null) {
      gaps.add(PlanGap(kind: PlanGapKind.stay, start: runStart, end: night));
      runStart = null;
    }
  }
  if (runStart != null) gaps.add(PlanGap(kind: PlanGapKind.stay, start: runStart, end: end));

  final hidden = plan.trip.hiddenGaps;
  return [
    for (final gap in gaps..sort((a, b) => a.start.compareTo(b.start)))
      if (!hidden.contains(gap.id)) gap,
  ];
}

/// Whether [flight] is one within the trip, not its flight out or home:
/// both ends in one country, with somewhere to stay booked from before it
/// leaves until after the day it lands (Osaka, then Sapporo). A flight
/// whose ends the app can't place counts as an end of the trip.
bool isInternalFlight(Booking flight, Iterable<Booking> bookings) {
  final route = routeOf(flight);
  if (route == null) return false;
  final from = transferPlace(route.from);
  final to = transferPlace(route.to);
  if (from == null || to == null || from.countryCode != to.countryCode) return false;
  final stays = bookings.where((b) => b.kind == BookingKind.stay);
  return stays.any((s) => s.startDate.isBefore(flight.startDate)) &&
      stays.any((s) => s.lastDate.isAfter(flight.lastDate));
}

/// The first gap a booking of [kind] would fill in [plan], leaving out
/// any that's over before [from] (during the trip, today): where the form
/// starts when a stay or flight is added from the trip. Null for kinds no
/// gap asks for, or when nothing is missing.
PlanGap? firstGapFor(BookingKind kind, TripPlan plan, {LocalDate? from}) {
  for (final gap in planGaps(plan)) {
    if (gap.bookingKind != kind) continue;
    // A stay gap's last night is the day before its check-out.
    final lastDay = gap.kind == PlanGapKind.stay ? (gap.end ?? gap.start.addDays(1)).addDays(-1) : gap.start;
    if (from != null && lastDay.isBefore(from)) continue;
    return gap;
  }
  return null;
}

/// A gap, worded for its row: "Stay needed" / "14–16 Oct · 2 nights" / "Add".
class PlanGapText {
  const PlanGapText({required this.title, required this.when, required this.semanticLabel});

  final String title;
  final String when;
  final String semanticLabel;
}

PlanGapText describeGap(PlanGap gap, TripPlan plan) {
  switch (gap.kind) {
    case PlanGapKind.stay:
      final end = gap.end ?? gap.start.addDays(1);
      final nights = gap.start.daysUntil(end);
      // With nothing booked anywhere it's the first thing to sort, not a hole.
      final anyStay = plan.bookings.any((b) => b.kind == BookingKind.stay);
      final title = anyStay ? 'Stay needed' : 'Somewhere to stay';
      final when = '${formatDayMonthRange(gap.start, end)} · ${formatNights(nights)}';
      return PlanGapText(title: title, when: when, semanticLabel: '$title, $when. Add a stay.');
    case PlanGapKind.flightOut:
    case PlanGapKind.flightHome:
      final title = gap.kind == PlanGapKind.flightOut ? 'Flight out' : 'Flight home';
      final when = formatDayMonth(gap.start);
      return PlanGapText(title: title, when: when, semanticLabel: '$title, $when. Add a flight.');
  }
}
