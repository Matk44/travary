import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../logic/trip_calendar.dart';
import '../tokens.dart';
import '../trip_chrome.dart';

/// A trip's days on a small calendar, to jump to one: the weeks from its
/// first day to its last under the weekday letters, the days either side
/// faint and not for choosing. The day on screen is filled in the trip
/// palette's primary colour, today is ringed in its highlight, and a dot
/// marks a day with something booked. Weeks start on the locale's first
/// day of the week.
class TripCalendar extends StatelessWidget {
  const TripCalendar({
    super.key,
    required this.first,
    required this.last,
    required this.selected,
    required this.today,
    required this.semanticLabel,
    required this.onSelected,
    this.booked = const {},
  });

  /// The trip's first and last days: the only ones that can be chosen.
  final LocalDate first;
  final LocalDate last;

  /// The day on screen.
  final LocalDate selected;
  final LocalDate today;

  /// Days with something booked.
  final Set<LocalDate> booked;

  /// What a screen reader says for a day of the trip.
  final String Function(LocalDate date) semanticLabel;
  final ValueChanged<LocalDate> onSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    // 0 is Sunday; DateTime counts Monday as 1 and Sunday as 7.
    final firstIndex = localizations.firstDayOfWeekIndex;
    final weeks = calendarWeeks(first, last, firstWeekday: firstIndex == 0 ? DateTime.sunday : firstIndex);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: CalendarLayout.maxTextScale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        localizations.narrowWeekdays[(firstIndex + i) % 7],
                        style: TravaryText.calendarWeekday,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TravarySpace.xs),
          for (final week in weeks)
            Row(
              children: [
                for (final date in week)
                  Expanded(
                    child: _Day(
                      date: date,
                      inTrip: !date.isBefore(first) && !date.isAfter(last),
                      selected: date == selected,
                      today: date == today,
                      booked: booked.contains(date),
                      semanticLabel: semanticLabel,
                      onTap: () => onSelected(date),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.date,
    required this.inTrip,
    required this.selected,
    required this.today,
    required this.booked,
    required this.semanticLabel,
    required this.onTap,
  });

  final LocalDate date;
  final bool inTrip;
  final bool selected;
  final bool today;
  final bool booked;
  final String Function(LocalDate date) semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final ink = selected ? colors.onPrimary : TravaryColors.ink;
    final disc = Container(
      width: CalendarLayout.disc,
      height: CalendarLayout.disc,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.primary : null,
        border: today ? Border.all(color: colors.highlight, width: CalendarLayout.ring) : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(CalendarLayout.ring + 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${date.day}',
                style: TravaryText.calendarDay.copyWith(
                  color: ink,
                  fontWeight: selected || today ? FontWeight.w700 : null,
                ),
              ),
            ),
          ),
          if (booked)
            Positioned(
              bottom: CalendarLayout.disc * 0.14,
              child: Container(
                key: const ValueKey('calendar-booked'),
                width: CalendarLayout.bookedDot,
                height: CalendarLayout.bookedDot,
                decoration: BoxDecoration(color: selected ? ink : colors.highlight, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
    final cell = SizedBox(
      height: CalendarLayout.rowHeight,
      child: Center(child: disc),
    );

    if (!inTrip) return ExcludeSemantics(child: Opacity(opacity: 0.32, child: cell));
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel(date),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: CalendarLayout.rowHeight / 2,
        highlightShape: BoxShape.circle,
        focusColor: colors.highlight.withValues(alpha: 0.2),
        child: cell,
      ),
    );
  }
}
