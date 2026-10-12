import '../domain/domain.dart';
import 'art_subjects.dart';
import 'day_plan.dart';
import 'flight_status_text.dart';
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
    this.footnote,
    this.action,
    this.badge,
    this.badgeCaption,
    this.day,
    this.month,
    this.live,
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

  /// A small supporting line in spaced capitals, for cards with room for
  /// one: "CHECK-OUT IN 4 DAYS" on a hotel key card.
  final String? footnote;

  /// The featured card's button: "Show tickets" when there's something to
  /// show at the gate, else "Details".
  final String? action;

  /// A short value for a round badge on a ticket stub, with its caption:
  /// "4" under "TABLE FOR" on a restaurant ticket.
  final String? badge;
  final String? badgeCaption;

  /// The date on two lines, for a postmark: "26" over "Sep".
  final String? day;
  final String? month;

  /// A flight's live state, under its card on Today (flight alerts).
  final LiveFlightLine? live;

  /// This wording with [live] under the card.
  CardText withLive(LiveFlightLine? live) => CardText(
    eyebrow: eyebrow,
    title: title,
    when: when,
    detail: detail,
    place: place,
    stub: stub,
    reference: reference,
    footnote: footnote,
    action: action,
    badge: badge,
    badgeCaption: badgeCaption,
    day: day,
    month: month,
    live: live,
  );

  /// [when] and [detail] joined for one-line layouts.
  String? get whenAndDetail {
    final parts = [when, detail].whereType<String>();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// The kind and one detail (else the place) for single-row layouts whose
  /// date sits apart: "Lunch · ST-4412", "Hotel · LR-99312".
  String? get summary {
    final parts = [_sentenceCase(eyebrow), detail ?? place].whereType<String>().where((part) => part.isNotEmpty);
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
    action: _action(booking),
    badge: _badge(booking),
    badgeCaption: _badge(booking) == null ? null : 'TABLE FOR',
  );
}

String? _badge(Booking booking) {
  if (booking.kind != BookingKind.dining) return null;
  final party = int.tryParse(booking.detail(DetailKeys.partySize) ?? '');
  return party == null ? null : '$party';
}

/// Whether [booking] has something to show at the gate: ticket files, or at
/// least a booking reference.
bool showsTickets(Booking booking) => booking.hasTickets || _nonEmpty(booking.reference) != null;

String _action(Booking booking) => showsTickets(booking) ? 'Show tickets' : 'Details';

/// Wording for [booking] outside a day context (the booking's own page).
/// Its button opens the ticket files, or adds some when there are none
/// (the reference is printed on the page itself).
CardText cardTextForBooking(Booking booking) {
  return CardText(
    eyebrow: _kindEyebrow(booking, booking.startTime),
    title: booking.title,
    when: describeWhen(booking),
    detail: _detailLine(booking),
    place: _nonEmpty(booking.location),
    stub: _stub(booking),
    reference: _nonEmpty(booking.reference),
    action: booking.hasTickets ? 'Show tickets' : 'Add tickets',
    badge: _badge(booking),
    badgeCaption: _badge(booking) == null ? null : 'TABLE FOR',
  );
}

/// Wording for [booking] in a list covering many days (the Wallet), where
/// the date matters more than the time.
CardText cardTextForList(Booking booking) {
  final date = formatDayMonthParts(booking.startDate);
  return CardText(
    eyebrow: _kindEyebrow(booking, booking.startTime),
    title: booking.title,
    when: formatDayMonth(booking.startDate),
    detail: _nonEmpty(booking.reference) ?? _detailLine(booking),
    place: _nonEmpty(booking.location),
    stub: _stub(booking),
    reference: _nonEmpty(booking.reference),
    day: date.day,
    month: date.month,
  );
}

/// Wording for [booking] as a row of a trip's plan (the trip screen): the
/// date in its own column, then what matters at a glance: "QF 25 ·
/// 8:55pm", "12–14 Oct · 2 nights", "10:00am · 2 tickets". [showDate] is
/// false for a row sharing the date above it.
CardText cardTextForLedger(Booking booking, {bool showDate = true}) {
  final date = formatDayMonthParts(booking.startDate);
  final time = booking.startTime == null ? null : formatClock(booking.startTime!);
  final List<String?> parts;
  if (booking.kind == BookingKind.flight) {
    parts = [booking.detail(DetailKeys.flightNumber)?.toUpperCase(), time];
  } else if (booking.spansDays) {
    final range = formatDayMonthRange(booking.startDate, booking.lastDate);
    final nights = booking.startDate.daysUntil(booking.lastDate);
    parts = [range, booking.kind == BookingKind.stay ? formatNights(nights) : _detailLine(booking)];
  } else {
    parts = [time, _detailLine(booking)];
  }
  final present = parts.whereType<String>().where((part) => part.isNotEmpty).toList();
  final eyebrow = _kindEyebrow(booking, booking.startTime);
  return CardText(
    eyebrow: eyebrow,
    title: booking.title,
    when: describeWhen(booking),
    detail: present.isEmpty ? _sentenceCase(eyebrow) : present.join(' · '),
    place: _nonEmpty(booking.location),
    reference: _nonEmpty(booking.reference),
    day: showDate ? date.day : null,
    month: showDate ? date.month.toUpperCase() : null,
  );
}

/// Wording for checking a booking before it's saved (Smart Import): the
/// date in the narrow column, the time up front in the detail line.
CardText cardTextForReview(Booking booking) {
  final time = booking.startTime == null ? null : formatClock(booking.startTime!);
  final detail = [time, _detailLine(booking)].whereType<String>().join(' · ');
  return CardText(
    eyebrow: _kindEyebrow(booking, booking.startTime),
    title: booking.title,
    when: formatDayMonth(booking.startDate),
    detail: detail.isEmpty ? null : detail,
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
  return (title: [booking.title, ?extra].join(' · '), subtitle: '${booking.kind.spec.endEvent} ${relativeDays(days)}');
}

/// Card wording for a multi-day booking you're in the middle of on [date]
/// (the hotel key card): "HOTEL" / "Lagoon Resort" / "Room 2214" /
/// "CHECK-OUT IN 4 DAYS".
CardText ongoingCardText(Booking booking, LocalDate date) {
  final days = date.daysUntil(booking.lastDate);
  final detail = switch (booking.kind) {
    BookingKind.stay => _prefixed('Room', booking.detail(DetailKeys.room)),
    BookingKind.transport => booking.detail(DetailKeys.company),
    _ => _detailLine(booking),
  };
  return CardText(
    eyebrow: _kindEyebrow(booking, null),
    title: booking.title,
    detail: detail,
    place: _nonEmpty(booking.location),
    stub: _stub(booking),
    reference: _nonEmpty(booking.reference),
    footnote: '${booking.kind.spec.endEvent} ${relativeDays(days)}'.toUpperCase(),
    action: _action(booking),
  );
}

/// A card's stop on the day's time rail: "9:00" over "am", beside the
/// card. The card itself carries the time for screen readers.
class TimelineStop {
  const TimelineStop({required this.time, required this.period, required this.status});

  /// Twelve-hour clock: "9:00", "12:30".
  final String time;

  /// "am" or "pm", under [time].
  final String period;
  final EntryStatus status;
}

/// [entry]'s stop on the time rail: the time it starts that day (a
/// check-out's or drop-off's time on its last day). Null for an all-day
/// entry, which has no place on the rail.
TimelineStop? timelineStopFor(DayEntry entry) {
  final time = entry.time;
  if (time == null) return null;
  return TimelineStop(time: formatClockShort(time), period: formatClockPeriod(time), status: entry.status);
}

/// Full date wording: "Wed 14 Oct · 12:30pm", "Wed 14 – Sat 17 Oct".
String describeWhen(Booking booking) {
  final start = formatDayShort(booking.startDate);
  final startTime = booking.startTime == null ? '' : ' · ${formatClock(booking.startTime!)}';
  if (booking.spansDays) {
    final end = formatDayShort(booking.lastDate);
    final endTime = booking.endTime == null ? '' : ' · ${formatClock(booking.endTime!)}';
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
  if (booking.kind == BookingKind.stay) {
    // What the key card is for: most stays are hotels.
    return switch (artSubjectFor(booking)) {
      'cottage' => 'COTTAGE',
      'chalet' => 'CHALET',
      'villa' => 'VILLA',
      'camping' => 'CAMPSITE',
      _ => 'HOTEL',
    };
  }
  return booking.kind.spec.label.toUpperCase();
}

String _sentenceCase(String value) => value.isEmpty ? value : value[0] + value.substring(1).toLowerCase();

String _whenForEntry(DayEntry entry) {
  if (entry.time == null) return 'All day';
  final booking = entry.booking;
  final start = formatClock(entry.time!);
  if (entry.role == EntryRole.single && booking.endTime != null && booking.endTime!.compareTo(entry.time!) > 0) {
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
    BookingKind.attraction || BookingKind.activity => [plural(booking.detail(DetailKeys.guests), 'ticket', 'tickets')],
    BookingKind.dining => [_prefixed('Table for', booking.detail(DetailKeys.partySize))],
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
      // The operator, on the ticket's number strip: "EUROSTAR", "ALAMO".
      return _nonEmpty(booking.detail(DetailKeys.company))?.toUpperCase();
    case BookingKind.note:
      return null;
  }
}

String? _prefixed(String prefix, String? value) => value == null ? null : '$prefix $value';

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? _firstLine(String? value) => _nonEmpty(value)?.split('\n').first;
