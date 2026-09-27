import '../domain/domain.dart';
import 'day_plan.dart';
import 'formatters.dart';

/// Every string a booking card can show, already worded and formatted.
///
/// Card designs only lay these out; they never format dates or pick wording
/// themselves. That keeps every skin consistent and easy to swap.
class CardText {
  const CardText({
    required this.eyebrow,
    required this.title,
    this.when,
    this.detail,
    this.place,
    this.stub,
    this.reference,
  });

  /// Small uppercase label above the title: "NEXT UP", "LUNCH", "CHECK-OUT".
  final String eyebrow;
  final String title;

  /// "12:30pm", "9:00am – 5:00pm", "All day".
  final String? when;

  /// Kind-specific line: "Table for 4", "Room 2214", "BA 2037 · Seats 14A".
  final String? detail;
  final String? place;

  /// Short text for a ticket stub: "ADMIT TWO", "SEAT 14A", "ROOM 2214".
  final String? stub;
  final String? reference;

  /// [when] and [detail] joined for one-line layouts.
  String? get whenAndDetail {
    final parts = [when, detail].whereType<String>();
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Wording for [entry] on a day timeline.
CardText cardTextForEntry(DayEntry entry, {bool highlighted = false}) {
  final booking = entry.booking;
  final spec = booking.kind.spec;

  final String eyebrow;
  if (highlighted) {
    eyebrow = entry.status == EntryStatus.now ? 'HAPPENING NOW' : 'NEXT UP';
  } else if (entry.role == EntryRole.start) {
    eyebrow = spec.startEvent.toUpperCase();
  } else if (entry.role == EntryRole.end) {
    eyebrow = spec.endEvent.toUpperCase();
  } else {
    eyebrow = _kindEyebrow(booking, entry.time);
  }

  return CardText(
    eyebrow: eyebrow,
    title: booking.title,
    when: _whenForEntry(entry),
    detail: _detailLine(booking),
    place: _nonEmpty(booking.location),
    stub: _stub(booking),
    reference: _nonEmpty(booking.reference),
  );
}

/// Wording for [booking] outside a day context (Wallet, detail screen).
CardText cardTextForBooking(Booking booking) {
  return CardText(
    eyebrow: _kindEyebrow(booking, booking.startTime),
    title: booking.title,
    when: describeWhen(booking),
    detail: _detailLine(booking),
    place: _nonEmpty(booking.location),
    stub: _stub(booking),
    reference: _nonEmpty(booking.reference),
  );
}

/// Wording for [booking] in a list covering many days (the Wallet), where
/// the date matters more than the time.
CardText cardTextForList(Booking booking) {
  return CardText(
    eyebrow: _kindEyebrow(booking, booking.startTime),
    title: booking.title,
    when: formatDayMonth(booking.startDate),
    detail: _nonEmpty(booking.reference) ?? _detailLine(booking),
    place: _nonEmpty(booking.location),
    stub: _stub(booking),
    reference: _nonEmpty(booking.reference),
  );
}

/// Wording for a multi-day booking you're in the middle of on [date]:
/// "Lagoon Resort · Room 2214" / "Check-out in 4 days".
({String title, String subtitle}) ongoingText(Booking booking, LocalDate date) {
  final days = date.daysUntil(booking.lastDate);
  final extra = switch (booking.kind) {
    BookingKind.stay => _prefixed('Room', booking.detail(DetailKeys.room)),
    BookingKind.transport => booking.detail(DetailKeys.company),
    _ => null,
  };
  return (
    title: [booking.title, ?extra].join(' · '),
    subtitle: '${booking.kind.spec.endEvent} ${relativeDays(days)}',
  );
}

/// Full date wording: "Wed 14 Oct · 12:30pm", "Wed 14 – Sat 17 Oct".
String describeWhen(Booking booking) {
  final start = formatDayShort(booking.startDate);
  final startTime = booking.startTime == null
      ? ''
      : ' · ${formatClock(booking.startTime!)}';
  if (booking.spansDays) {
    final end = formatDayShort(booking.lastDate);
    final endTime = booking.endTime == null
        ? ''
        : ' · ${formatClock(booking.endTime!)}';
    return '$start$startTime → $end$endTime';
  }
  if (booking.endTime != null && booking.startTime != null) {
    return '$start · ${formatClock(booking.startTime!)} – ${formatClock(booking.endTime!)}';
  }
  return '$start$startTime';
}

String _kindEyebrow(Booking booking, ClockTime? time) {
  if (booking.kind == BookingKind.dining && time != null) {
    if (time.hour < 11) return 'BREAKFAST';
    if (time.hour < 16) return 'LUNCH';
    return 'DINNER';
  }
  return booking.kind.spec.label.toUpperCase();
}

String _whenForEntry(DayEntry entry) {
  if (entry.time == null) return 'All day';
  final booking = entry.booking;
  final start = formatClock(entry.time!);
  if (entry.role == EntryRole.single &&
      booking.endTime != null &&
      booking.endTime!.compareTo(entry.time!) > 0) {
    return '$start – ${formatClock(booking.endTime!)}';
  }
  return start;
}

String? _detailLine(Booking booking) {
  String? plural(String? count, String one, String many) {
    final n = int.tryParse(count ?? '');
    if (n == null) return count;
    return '$n ${n == 1 ? one : many}';
  }

  final parts = switch (booking.kind) {
    BookingKind.flight => [
      booking.detail(DetailKeys.flightNumber),
      _prefixed('Seats', booking.detail(DetailKeys.seats)),
    ],
    BookingKind.stay => [
      _prefixed('Room', booking.detail(DetailKeys.room)),
      plural(booking.detail(DetailKeys.guests), 'guest', 'guests'),
    ],
    BookingKind.attraction || BookingKind.activity => [
      plural(booking.detail(DetailKeys.guests), 'ticket', 'tickets'),
    ],
    BookingKind.dining => [
      _prefixed('Table for', booking.detail(DetailKeys.partySize)),
    ],
    BookingKind.transport => [booking.detail(DetailKeys.company)],
    BookingKind.event => [_prefixed('Seats', booking.detail(DetailKeys.seats))],
    BookingKind.note => [_firstLine(booking.notes)],
  };
  final present = parts.whereType<String>().toList();
  return present.isEmpty ? null : present.join(' · ');
}

String? _stub(Booking booking) {
  switch (booking.kind) {
    case BookingKind.attraction:
    case BookingKind.activity:
      final n = int.tryParse(booking.detail(DetailKeys.guests) ?? '');
      return n == null ? 'ADMIT' : 'ADMIT ${numberWord(n)}';
    case BookingKind.flight:
      // Stubs are narrow: one seat fits, a family's worth doesn't.
      final seats = booking.detail(DetailKeys.seats);
      final flight = booking.detail(DetailKeys.flightNumber)?.toUpperCase();
      if (seats != null && !seats.contains(',')) return 'SEAT ${seats.toUpperCase()}';
      return flight ?? (seats == null ? null : '${seats.split(',').length} SEATS');
    case BookingKind.stay:
      final room = booking.detail(DetailKeys.room);
      return room == null ? null : 'ROOM $room';
    case BookingKind.dining:
      final party = booking.detail(DetailKeys.partySize);
      return party == null ? null : 'TABLE FOR $party';
    case BookingKind.event:
      return booking.detail(DetailKeys.seats)?.toUpperCase();
    case BookingKind.transport:
    case BookingKind.note:
      return null;
  }
}

String? _prefixed(String prefix, String? value) =>
    value == null ? null : '$prefix $value';

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? _firstLine(String? value) => _nonEmpty(value)?.split('\n').first;
