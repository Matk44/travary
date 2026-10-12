import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/domain.dart';
import '../../logic/date_range_selection.dart';
import '../../logic/formatters.dart';
import '../../logic/trip_calendar.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'ledger.dart';

/// A holiday's first and last day.
typedef HolidayDates = ({LocalDate start, LocalDate end});

/// Both of a holiday's dates in one sheet: tap the day they leave, then the
/// day they come home, on one smooth run of months ([tapHolidayDay]).
/// Returns null if they close it.
Future<HolidayDates?> showHolidayDates(
  BuildContext context, {
  required LocalDate today,
  LocalDate? start,
  LocalDate? end,
  LocalDate? first,
  LocalDate? last,
  String title = 'When’s the holiday?',
  String confirm = 'Set my dates',
}) {
  final from = first ?? today;
  return showModalBottomSheet<HolidayDates>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: TravaryChrome.of(context).colors.paper,
    // Short phones give the months the whole height.
    builder: (context) => FractionallySizedBox(
      heightFactor: MediaQuery.sizeOf(context).height < 700 ? 1 : .92,
      child: HolidayDatesSheet(
        today: today,
        first: from,
        last: last ?? LocalDate.max(from, today).addDays(365 * 3),
        start: start,
        end: end,
        title: title,
        confirm: confirm,
      ),
    ),
  );
}

class HolidayDatesSheet extends StatefulWidget {
  const HolidayDatesSheet({
    super.key,
    required this.today,
    required this.first,
    required this.last,
    required this.title,
    required this.confirm,
    this.start,
    this.end,
  });
  final LocalDate today;
  final LocalDate first;
  final LocalDate last;
  final LocalDate? start;
  final LocalDate? end;
  final String title;
  final String confirm;

  @override
  State<HolidayDatesSheet> createState() => _HolidayDatesSheetState();
}

const _cell = 46.0;
const _monthTitle = 52.0;
const _monthGap = 14.0;

class _HolidayDatesSheetState extends State<HolidayDatesSheet> {
  late LocalDate? _start = widget.start;
  late LocalDate? _end = widget.start == null ? null : widget.end;
  late final List<LocalDate> _months = monthsBetween(widget.first, widget.last);
  late final ScrollController _scroll = ScrollController(initialScrollOffset: _offsetOf(_start ?? widget.today));

  double _extent(int i) =>
      _monthTitle + calendarWeeks(_months[i], lastDayOfMonth(_months[i])).length * _cell + _monthGap;

  /// Opens on the chosen month (or this one), not the first in the list.
  double _offsetOf(LocalDate day) {
    var offset = 0.0;
    for (var i = 0; i < _months.length; i++) {
      final m = _months[i];
      if (m.year == day.year && m.month == day.month) return offset;
      offset += _extent(i);
    }
    return 0;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _tap(LocalDate day) {
    HapticFeedback.selectionClick();
    final next = tapHolidayDay(day, start: _start, end: _end);
    setState(() {
      _start = next.start;
      _end = next.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final start = _start;
    final end = _end;
    final choosingEnd = start != null && end == null;
    final rule = Divider(height: 1, color: colors.ink.withValues(alpha: .12));
    return LayoutBuilder(
      builder: (context, box) => Column(
        children: [
          // Large type scrolls within the header rather than squeezing the months.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: box.maxHeight * .4),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, 10),
              child: Column(
                children: [
                  // One line, so large type leaves room for the dates.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(widget.title, maxLines: 1, style: TravaryText.title.copyWith(color: colors.ink)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTag(label: 'Leave', date: start, active: !choosingEnd, colors: colors),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded, size: 18, color: colors.ink.withValues(alpha: .5)),
                      ),
                      Expanded(
                        child: _DateTag(label: 'Home', date: end, active: choosingEnd, colors: colors),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            holidayDatesHint(start: start, end: end),
                            key: ValueKey('$start-$end'),
                            style: TravaryText.label.copyWith(color: colors.ink.withValues(alpha: .75)),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: AnimatedOpacity(
                            opacity: start == null ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: TextButton(
                              key: const ValueKey('holiday-dates-clear'),
                              onPressed: start == null ? null : () => setState(() => _start = _end = null),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.ink,
                                textStyle: TravaryText.label.copyWith(decoration: TextDecoration.underline),
                                minimumSize: const Size(44, 32),
                              ),
                              child: const Text('Clear'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Weekdays(colors: colors),
          rule,
          Expanded(
            child: ListView.builder(
              key: const ValueKey('holiday-dates-months'),
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _months.length,
              itemExtentBuilder: (i, _) => _extent(i),
              itemBuilder: (context, i) => _Month(
                month: _months[i],
                first: widget.first,
                last: widget.last,
                today: widget.today,
                start: start,
                end: end,
                colors: colors,
                onTap: _tap,
              ),
            ),
          ),
          rule,
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 10, TravarySpace.gutter, 6),
              child: SizedBox(
                width: double.infinity,
                child: TicketButton(
                  key: const ValueKey('holiday-dates-confirm'),
                  label: widget.confirm,
                  onPressed: start == null || end == null
                      ? null
                      : () => Navigator.of(context).pop<HolidayDates>((start: start, end: end)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "LEAVE · Sun 8 Nov": the day chosen, or the one to choose next.
class _DateTag extends StatelessWidget {
  const _DateTag({required this.label, required this.date, required this.active, required this.colors});
  final String label;
  final LocalDate? date;
  final bool active;
  final TripColors colors;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOut,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: active ? colors.highlight.withValues(alpha: .1) : Colors.transparent,
      borderRadius: BorderRadius.circular(TravaryRadius.small),
      border: Border.all(color: active ? colors.highlight : colors.ink.withValues(alpha: .2), width: active ? 1.6 : 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TravaryText.eyebrow.copyWith(color: colors.ink.withValues(alpha: .6))),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          // Large type shrinks the date rather than cutting it short.
          child: FittedBox(
            key: ValueKey(date),
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              date == null ? 'Choose' : formatDayShort(date!),
              maxLines: 1,
              style: TravaryText.title.copyWith(
                fontSize: 18,
                color: date == null ? colors.ink.withValues(alpha: .45) : colors.ink,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Weekdays extends StatelessWidget {
  const _Weekdays({required this.colors});
  final TripColors colors;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    child: ExcludeSemantics(
      child: Row(
        children: [
          for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
            Expanded(
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: TravaryText.small.copyWith(color: colors.ink.withValues(alpha: .55)),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Month extends StatelessWidget {
  const _Month({
    required this.month,
    required this.first,
    required this.last,
    required this.today,
    required this.start,
    required this.end,
    required this.colors,
    required this.onTap,
  });
  final LocalDate month;
  final LocalDate first;
  final LocalDate last;
  final LocalDate today;
  final LocalDate? start;
  final LocalDate? end;
  final TripColors colors;
  final ValueChanged<LocalDate> onTap;

  @override
  Widget build(BuildContext context) {
    final weeks = calendarWeeks(month, lastDayOfMonth(month));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _monthTitle,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 10),
              child: FittedBox(
                child: Text(formatMonthYear(month), style: TravaryText.title.copyWith(color: colors.ink)),
              ),
            ),
          ),
        ),
        for (final week in weeks)
          SizedBox(
            height: _cell,
            child: Row(
              children: [
                for (final day in week)
                  Expanded(
                    child: day.month != month.month
                        ? const SizedBox.shrink()
                        : _Day(
                            day: day,
                            enabled: !day.isBefore(first) && !day.isAfter(last),
                            today: day == today,
                            start: start,
                            end: end,
                            colors: colors,
                            onTap: onTap,
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.enabled,
    required this.today,
    required this.start,
    required this.end,
    required this.colors,
    required this.onTap,
  });
  final LocalDate day;
  final bool enabled;
  final bool today;
  final LocalDate? start;
  final LocalDate? end;
  final TripColors colors;
  final ValueChanged<LocalDate> onTap;

  @override
  Widget build(BuildContext context) {
    final isStart = day == start;
    final isEnd = day == end;
    final chosen = isStart || isEnd;
    final range = start != null && end != null && start != end;
    final inside = range && day.isAfter(start!) && day.isBefore(end!);
    // The band runs between the two days: half a cell on each end.
    final bandLeft = inside || (range && isEnd);
    final bandRight = inside || (range && isStart);
    final band = colors.highlight.withValues(alpha: .16);
    const duration = Duration(milliseconds: 180);
    return Semantics(
      button: enabled,
      selected: chosen,
      label:
          formatDayLong(day) +
          (isStart
              ? ', leaving'
              : isEnd
              ? ', coming home'
              : ''),
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('date-${day.toIso()}'),
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onTap(day) : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: 5,
              bottom: 5,
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(duration: duration, color: bandLeft ? band : band.withValues(alpha: 0)),
                  ),
                  Expanded(
                    child: AnimatedContainer(duration: duration, color: bandRight ? band : band.withValues(alpha: 0)),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chosen ? colors.ink : colors.ink.withValues(alpha: 0),
                border: today && !chosen ? Border.all(color: colors.highlight, width: 1.4) : null,
              ),
              child: FittedBox(
                child: Text(
                  '${day.day}',
                  style: TravaryText.label.copyWith(
                    fontSize: 15,
                    color: chosen
                        ? colors.paper
                        : enabled
                        ? colors.ink
                        : colors.ink.withValues(alpha: .28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
