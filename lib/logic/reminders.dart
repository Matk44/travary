import '../domain/domain.dart';
import 'card_text.dart';
import 'day_plan.dart';
import 'formatters.dart';
import 'trip_plan.dart';
import 'trip_route.dart';

/// Reminders on this phone, free for everyone (flight alerts are the paid
/// live ones): each trip day's plan in the morning, and a nudge before
/// each timed booking. Pure rules; `ReminderScheduler` sets them.
///
/// Times are floating, like the bookings: 8:00 is 8:00 wherever the phone
/// is. A phone only learns it's somewhere new when it lands, so nothing is
/// set past the landing of the next flight that may change its clock
/// ([remindersFor]); the app sets the rest when it next opens, on the new
/// clock. A flight within a country on one time zone (Osaka to Sapporo)
/// doesn't stop them.
class Reminder {
  const Reminder({required this.at, required this.title, required this.body, required this.opens});

  /// When it shows, on the phone's own clock.
  final DateTime at;
  final String title;
  final String body;

  /// What tapping it opens: `booking:<id>` or `day:<yyyy-mm-dd>` (Today).
  final String opens;

  @override
  bool operator ==(Object other) =>
      other is Reminder && other.at == at && other.title == title && other.body == body && other.opens == opens;

  @override
  int get hashCode => Object.hash(at, title, body, opens);

  @override
  String toString() => 'Reminder($at, $title: $body)';
}

/// The morning plan comes at this time, or earlier on a day that starts
/// early ([morningAt]).
const reminderMorning = ClockTime(8, 0);

/// How far ahead reminders are set, and at most how many (iOS keeps 64
/// waiting for an app).
const reminderHorizon = Duration(days: 14);
const reminderLimit = 50;

/// How long before it each kind of booking is nudged. Stays aren't (their
/// check-in and check-out are in the morning's plan); a reminder you wrote
/// comes at its own time.
Duration? reminderLead(BookingKind kind) => switch (kind) {
  BookingKind.flight => const Duration(hours: 3),
  BookingKind.stay => null,
  BookingKind.note => Duration.zero,
  _ => const Duration(hours: 1),
};

/// The reminders to set at [now] for [plans], soonest first: never in the
/// past, within [reminderHorizon], at most [reminderLimit], and none after
/// the next flight lands ([nextLanding]).
List<Reminder> remindersFor(List<TripPlan> plans, DateTime now) {
  final bookings = [for (final plan in plans) ...plan.bookings];
  final until = _earlier(now.add(reminderHorizon), nextLanding(bookings, now));
  final today = LocalDate.fromDateTime(now);
  final reminders = <Reminder>[];
  for (final plan in plans.where((p) => p.hasDates && !p.end!.isBefore(today))) {
    for (final day in plan.days.where((d) => !d.isBefore(today))) {
      if (day.toDateTime().isAfter(until)) break;
      final dayPlan = buildDayPlan(day, plan.bookings, now);
      if (dayPlan.entries.isEmpty) continue;
      reminders.add(_morning(plan, dayPlan));
      for (final entry in dayPlan.entries) {
        if (_nudge(entry, day) case final nudge?) reminders.add(nudge);
      }
    }
  }
  final due = reminders.where((r) => r.at.isAfter(now) && !r.at.isAfter(until)).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
  return due.take(reminderLimit).toList();
}

/// When the next flight in the air or still to leave lands, on the clock
/// printed on its ticket: the phone may be in another time zone from then.
/// Null without one. Flights that keep the clock ([keepsTheClock]) don't
/// count.
DateTime? nextLanding(Iterable<Booking> bookings, DateTime now) {
  DateTime? next;
  for (final flight in bookings.where((b) => b.kind == BookingKind.flight)) {
    if (keepsTheClock(flight)) continue;
    final lands = switch ((flight.endTime, flight.startTime)) {
      (final end?, _) => flight.lastDate.toDateTime(end),
      (null, final start?) => flight.startDate.toDateTime(start).add(BookingKind.flight.spec.typicalDuration),
      _ => flight.lastDate.addDays(1).toDateTime(),
    };
    if (lands.isAfter(now) && (next == null || lands.isBefore(next))) next = lands;
  }
  return next;
}

/// Whether [flight] certainly lands on the clock it left on: both ends in
/// one country with a single time zone (Osaka to Sapporo, London to
/// Edinburgh). Anything else may change it, including ends the app can't
/// place.
bool keepsTheClock(Booking flight) {
  final route = routeOf(flight);
  if (route == null) return false;
  final from = transferPlace(route.from);
  final to = transferPlace(route.to);
  return from != null &&
      to != null &&
      from.countryCode == to.countryCode &&
      !severalTimeZones.contains(from.countryCode);
}

/// Countries whose places don't all keep the same clock (the Canaries are
/// an hour behind Madrid, the Azores behind Lisbon, Galápagos behind
/// Quito), so a flight within one may still change it.
const severalTimeZones = {
  'AQ', 'AU', 'BR', 'CA', 'CD', 'CL', 'EC', 'ES', 'FM', 'GL', 'ID', 'KI', 'KZ', 'MN', 'MX', 'NZ', //
  'PF', 'PG', 'PT', 'RU', 'UM', 'US',
};

/// When the morning plan comes on a day: [reminderMorning], or an hour
/// before a day that starts before 9:00, though never before 6:00.
DateTime morningAt(DayPlan day) {
  final first = day.entries.where((e) => !e.isAllDay).map((e) => e.time!).firstOrNull;
  final usual = day.date.toDateTime(reminderMorning);
  if (first == null || first.compareTo(const ClockTime(9, 0)) >= 0) return usual;
  final early = day.date.toDateTime(first).subtract(const Duration(hours: 1));
  final dawn = day.date.toDateTime(const ClockTime(6, 0));
  return early.isBefore(dawn) ? dawn : early;
}

Reminder _morning(TripPlan plan, DayPlan day) {
  final number = plan.dayNumber(day.date)!;
  final name = plan.trip.title.trim().isEmpty ? 'Your trip' : plan.trip.title.trim();
  final lines = [for (final entry in day.entries) _line(entry)];
  final shown = lines.take(3).join(' · ');
  final more = lines.length - 3;
  return Reminder(
    at: morningAt(day),
    title: number == 1 ? '$name starts today' : '$name, day $number',
    body: more > 0 ? '$shown · and $more more' : shown,
    opens: 'day:${day.date.toIso()}',
  );
}

/// "9:00am Sunshine Park", "11:00am Check-out, Lagoon Resort".
String _line(DayEntry entry) {
  final booking = entry.booking;
  final what = switch (entry.role) {
    EntryRole.single => booking.title,
    EntryRole.start => '${bookingEvents(booking).start}, ${booking.title}',
    EntryRole.end => '${bookingEvents(booking).end}, ${booking.title}',
  };
  return entry.time == null ? what : '${formatClock(entry.time!)} $what';
}

Reminder? _nudge(DayEntry entry, LocalDate day) {
  final booking = entry.booking;
  final time = entry.time;
  final lead = reminderLead(booking.kind);
  // Landings, check-outs and drop-offs are in the morning's plan.
  if (time == null || lead == null || entry.role == EntryRole.end) return null;
  final clock = formatClock(time);
  final body = switch (booking.kind) {
    BookingKind.flight => 'Departs at $clock, in 3 hours.${booking.hasTickets ? ' Tickets are one tap away.' : ''}',
    BookingKind.note => _nonEmpty(booking.notes) ?? clock,
    _ when entry.role == EntryRole.start => '${bookingEvents(booking).start} in an hour, at $clock.',
    _ => 'In an hour, at $clock.${_nonEmpty(booking.location) == null ? '' : ' ${booking.location!.trim()}'}',
  };
  return Reminder(
    at: day.toDateTime(time).subtract(lead),
    title: booking.title,
    body: body,
    opens: 'booking:${booking.id}',
  );
}

DateTime _earlier(DateTime a, DateTime? b) => b != null && b.isBefore(a) ? b : a;

String? _nonEmpty(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
