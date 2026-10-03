import '../domain/domain.dart';
import 'day_plan.dart';

/// How Today stacks one day: its rows top to bottom, which of them are
/// stops on the time rail, and what's folded away as finished.
///
/// Timed entries still to come run down the rail in time order, the
/// featured one in its place. What has no time (the hotel you're staying
/// at, a hire car you have, all-day entries) follows the featured card, or
/// opens the day when nothing is featured. On today, finished entries fold
/// away under "Earlier", off the rail; a past day's entries are rows off
/// the rail too.
class DayLayout {
  const DayLayout({required this.rows, required this.earlier});

  /// Top to bottom.
  final List<DayRow> rows;

  /// Indexes into [DayPlan.entries] of today's finished entries, in time
  /// order: folded under "Earlier", below the rows.
  final List<int> earlier;

  /// Whether the day has a stop on the rail. Without one there's no rail.
  bool get hasRail => rows.any((row) => row.rail.stop);
}

/// One row of the day, with what the rail draws beside it.
sealed class DayRow {
  const DayRow({required this.rail});

  final RailMark rail;
}

/// One of the plan's entries.
final class EntryRow extends DayRow {
  const EntryRow({required this.index, required super.rail, this.featured = false});

  /// Into [DayPlan.entries].
  final int index;

  /// The featured card: what's happening now, else what's next.
  final bool featured;
}

/// A multi-day booking you're in the middle of.
final class OngoingRow extends DayRow {
  const OngoingRow({required this.booking, required super.rail});

  final Booking booking;
}

/// What the time rail draws beside a row.
class RailMark {
  const RailMark({this.stop = false, this.lineAbove = false, this.lineBelow = false});

  static const none = RailMark();

  /// The row is a stop: its time and a dot.
  final bool stop;

  /// The line comes down from a stop above, and carries on to a stop below.
  /// A row that isn't a stop has both or neither: the line passes behind it
  /// only between two stops.
  final bool lineAbove;
  final bool lineBelow;

  @override
  bool operator ==(Object other) =>
      other is RailMark && other.stop == stop && other.lineAbove == lineAbove && other.lineBelow == lineBelow;

  @override
  int get hashCode => Object.hash(stop, lineAbove, lineBelow);

  @override
  String toString() => 'RailMark(stop: $stop, lineAbove: $lineAbove, lineBelow: $lineBelow)';
}

/// Lays [plan] out for Today, folding finished entries away when its date
/// is [today].
DayLayout layOutDay(DayPlan plan, LocalDate today) {
  final isToday = plan.date == today;
  final entries = plan.entries;
  final earlier = <int>[];
  final stops = <int>[];
  final allDay = <int>[];
  final finished = <int>[];
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    if (isToday && entry.status == EntryStatus.done) {
      earlier.add(i);
    } else if (entry.isAllDay) {
      allDay.add(i);
    } else if (entry.status == EntryStatus.done) {
      finished.add(i);
    } else {
      stops.add(i);
    }
  }

  // Always a stop: the featured card is timed and not finished.
  final featured = stops.contains(plan.highlightIndex) ? plan.highlightIndex : null;
  // Rows without a time; the rail marks are filled in below.
  final untimed = <_Row>[
    for (final booking in plan.ongoing) (index: null, ongoing: booking, stop: false),
    for (final i in allDay) (index: i, ongoing: null, stop: false),
  ];
  final order = <_Row>[
    if (featured == null) ...untimed,
    for (final i in stops) ...[(index: i, ongoing: null, stop: true), if (i == featured) ...untimed],
    for (final i in finished) (index: i, ongoing: null, stop: false),
  ];

  final first = order.indexWhere((row) => row.stop);
  final last = order.lastIndexWhere((row) => row.stop);
  RailMark railAt(int position, bool stop) {
    if (first == -1) return RailMark.none;
    if (stop) return RailMark(stop: true, lineAbove: position > first, lineBelow: position < last);
    final between = position > first && position < last;
    return RailMark(lineAbove: between, lineBelow: between);
  }

  return DayLayout(
    rows: List.unmodifiable([
      for (var p = 0; p < order.length; p++)
        if (order[p].ongoing case final booking?)
          OngoingRow(booking: booking, rail: railAt(p, false))
        else
          EntryRow(index: order[p].index!, featured: order[p].index == featured, rail: railAt(p, order[p].stop)),
    ]),
    earlier: List.unmodifiable(earlier),
  );
}

typedef _Row = ({int? index, Booking? ongoing, bool stop});
