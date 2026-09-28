import '../domain/domain.dart';
import 'art_subjects.dart';
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
    this.footnote,
    this.action,
    this.badge,
    this.badgeCaption,
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

/// One stop on a day's timeline: "9:00" over "Park".
class TimelineStop {
  const TimelineStop({required this.time, required this.label, required this.spoken, required this.status});

  /// Twelve-hour clock without am/pm: the day reads left to right.
  final String time;

  /// One short word or two: "Park", "Lunch", "Check-in".
  final String label;

  /// For screen readers: "9:00am, Park, Magic Kingdom".
  final String spoken;
  final EntryStatus status;
}

/// The timed stops of [plan] for its timeline, in order. Notes and all-day
/// entries aren't stops.
List<TimelineStop> timelineFor(DayPlan plan) => [
  for (final entry in plan.entries)
    if (entry.time != null && entry.booking.kind != BookingKind.note)
      TimelineStop(
        time: formatClockShort(entry.time!),
        label: _timelineLabel(entry),
        spoken: '${formatClock(entry.time!)}, ${_timelineLabel(entry)}, ${entry.booking.title}',
        status: entry.status,
      ),
];

String _timelineLabel(DayEntry entry) {
  final booking = entry.booking;
  final spec = booking.kind.spec;
  if (entry.role == EntryRole.start) return spec.startEvent;
  if (entry.role == EntryRole.end) return spec.endEvent;
  final subject = artSubjectFor(booking);
  return switch (booking.kind) {
    BookingKind.dining => _sentenceCase(_kindEyebrow(booking, entry.time)),
    BookingKind.attraction => switch (subject) {
      'castle' || 'rollercoaster' || 'waterpark' => 'Park',
      'museum' => 'Museum',
      'zoo' => 'Zoo',
      'aquarium' => 'Aquarium',
      'gardens' => 'Gardens',
      _ => 'Visit',
    },
    BookingKind.transport => switch (subject) {
      'train' => 'Train',
      'bus' => 'Bus',
      'ferry' => 'Ferry',
      'bike' => 'Bike',
      'car' => 'Car',
      _ => 'Transfer',
    },
    BookingKind.activity => switch (subject) {
      'boat' => 'Boat trip',
      'hiking' => 'Hike',
      'snorkel' => 'Snorkel',
      'spa' => 'Spa',
      'safari' => 'Safari',
      'class' => 'Class',
      _ => 'Tour',
    },
    _ => spec.label,
  };
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
