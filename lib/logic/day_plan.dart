import '../domain/domain.dart';

/// Which part of a booking an entry represents on a given day.
enum EntryRole {
  /// The whole booking happens on this day.
  single,

  /// The first day of a multi-day booking (check-in, pick-up, departure).
  start,

  /// The last day of a multi-day booking (check-out, drop-off, landing).
  end,
}

enum EntryStatus { done, now, upcoming }

/// One line on a day's timeline.
class DayEntry {
  const DayEntry({
    required this.booking,
    required this.role,
    required this.time,
    required this.status,
  });

  final Booking booking;
  final EntryRole role;

  /// Null for all-day entries.
  final ClockTime? time;
  final EntryStatus status;

  bool get isAllDay => time == null;
}

/// Everything happening on one calendar day, in order.
class DayPlan {
  const DayPlan({
    required this.date,
    required this.entries,
    required this.ongoing,
    this.highlightIndex,
  });

  final LocalDate date;

  /// All-day entries first, then by time.
  final List<DayEntry> entries;

  /// Multi-day bookings you're in the middle of (the hotel you're staying
  /// at, the hire car you have). Shown as slim strips, not timeline entries.
  final List<Booking> ongoing;

  /// Index into [entries] of the card to feature: what's happening now,
  /// else what's next. Only set when [date] is today.
  final int? highlightIndex;

  DayEntry? get highlight =>
      highlightIndex == null ? null : entries[highlightIndex!];
  bool get isEmpty => entries.isEmpty && ongoing.isEmpty;
}

/// Lays out [bookings] for [date], judging done/now/upcoming against [now].
DayPlan buildDayPlan(LocalDate date, Iterable<Booking> bookings, DateTime now) {
  final today = LocalDate.fromDateTime(now);
  final entries = <DayEntry>[];
  final ongoing = <Booking>[];

  for (final booking in bookings) {
    if (date.isBefore(booking.startDate) || date.isAfter(booking.lastDate)) {
      continue;
    }
    final EntryRole role;
    final ClockTime? time;
    if (!booking.spansDays) {
      role = EntryRole.single;
      time = booking.startTime;
    } else if (date == booking.startDate) {
      role = EntryRole.start;
      time = booking.startTime;
    } else if (date == booking.lastDate) {
      role = EntryRole.end;
      time = booking.endTime;
    } else {
      ongoing.add(booking);
      continue;
    }
    entries.add(
      DayEntry(
        booking: booking,
        role: role,
        time: time,
        status: _statusOf(booking, role, date, time, today, now),
      ),
    );
  }

  entries.sort(_byTime);
  ongoing.sort((a, b) => a.startsAt.compareTo(b.startsAt));

  int? highlight;
  if (date == today) {
    // When things overlap (lunch inside a park day), feature whichever
    // started most recently: that's what the traveller is doing right now.
    final nowIndex = entries.lastIndexWhere(
      (e) => e.status == EntryStatus.now && !e.isAllDay,
    );
    final nextIndex = entries.indexWhere(
      (e) => e.status == EntryStatus.upcoming && !e.isAllDay,
    );
    highlight = nowIndex != -1 ? nowIndex : (nextIndex != -1 ? nextIndex : null);
  }

  return DayPlan(
    date: date,
    entries: List.unmodifiable(entries),
    ongoing: List.unmodifiable(ongoing),
    highlightIndex: highlight,
  );
}

EntryStatus _statusOf(
  Booking booking,
  EntryRole role,
  LocalDate date,
  ClockTime? time,
  LocalDate today,
  DateTime now,
) {
  if (date.isBefore(today)) return EntryStatus.done;
  if (date.isAfter(today)) return EntryStatus.upcoming;
  // All-day entries stay relevant for the whole of their day.
  if (time == null) return EntryStatus.now;

  final start = date.toDateTime(time);
  final finish = _finishOf(booking, role, date, start);
  if (now.isBefore(start)) return EntryStatus.upcoming;
  if (now.isBefore(finish)) return EntryStatus.now;
  return EntryStatus.done;
}

/// When an entry stops being "happening now".
DateTime _finishOf(
  Booking booking,
  EntryRole role,
  LocalDate date,
  DateTime start,
) {
  final endOfDay = date.addDays(1).toDateTime();
  if (role == EntryRole.single && booking.endTime != null) {
    final end = date.toDateTime(booking.endTime);
    if (end.isAfter(start)) return end;
  }
  if (role == EntryRole.end) return start;
  final finish = start.add(booking.kind.spec.typicalDuration);
  return finish.isAfter(endOfDay) ? endOfDay : finish;
}

int _byTime(DayEntry a, DayEntry b) {
  if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
  if (a.isAllDay) return a.booking.title.compareTo(b.booking.title);
  final byClock = a.time!.compareTo(b.time!);
  return byClock != 0 ? byClock : a.booking.title.compareTo(b.booking.title);
}
