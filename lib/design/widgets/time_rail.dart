import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';

/// One row of the day beside the time rail: the card on the right and the
/// rail on the left. A stop shows its time ("9:00" over "am") above a dot;
/// the line runs down from stop to stop, behind any row without a time.
/// Drawn in the trip palette's ink, calm enough to run down the whole
/// screen (a pack's accent colours are too loud for that); a stop happening
/// now is marked in its highlight.
///
/// The row includes the [gap] above its card, so the line runs on unbroken
/// into the next row. Screen readers skip the rail: every card says its own
/// time.
class TimeRailRow extends StatelessWidget {
  const TimeRailRow({
    super.key,
    required this.child,
    this.stop,
    this.lineAbove = false,
    this.lineBelow = false,
    this.gap = 0,
    this.outset = 0,
  });

  /// The row's card.
  final Widget child;

  /// The row's time and dot, when it's a stop.
  final TimelineStop? stop;

  /// The line comes down from a stop above, and carries on to a stop below.
  /// A row without a stop shows the line only when both are set.
  final bool lineAbove;
  final bool lineBelow;

  /// Space above the card.
  final double gap;

  /// How much further out than other cards this one reaches on each side
  /// (the featured ticket's scalloped edge).
  final double outset;

  @override
  Widget build(BuildContext context) {
    final stop = this.stop;
    final rail = stop != null || (lineAbove && lineBelow);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (rail)
          Positioned(
            left: TodayLayout.railLeft,
            width: TodayLayout.railWidth,
            top: 0,
            bottom: 0,
            child: ExcludeSemantics(
              child: _Rail(
                stop: stop,
                lineAbove: lineAbove,
                lineBelow: lineBelow,
                markTop: gap + TodayLayout.railStopTop,
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(TodayLayout.railCardLeft - outset, gap, TodayLayout.cardInset - outset, 0),
          child: child,
        ),
      ],
    );
  }
}

enum _RailPart { above, below, through, mark }

class _Rail extends StatelessWidget {
  const _Rail({required this.stop, required this.lineAbove, required this.lineBelow, required this.markTop});

  final TimelineStop? stop;
  final bool lineAbove;
  final bool lineBelow;
  final double markTop;

  @override
  Widget build(BuildContext context) {
    final color = TravaryChrome.of(context).colors.ink;
    Widget line(_RailPart part) => LayoutId(
      id: part,
      child: ColoredBox(key: const ValueKey('rail-line'), color: color),
    );
    final stop = this.stop;
    return CustomMultiChildLayout(
      delegate: _RailLayout(markTop: markTop),
      children: [
        if (stop == null)
          line(_RailPart.through)
        else ...[
          // Lines first: the one below leaves from behind the dot.
          if (lineAbove) line(_RailPart.above),
          if (lineBelow) line(_RailPart.below),
          LayoutId(
            id: _RailPart.mark,
            child: _StopMark(stop: stop),
          ),
        ],
      ],
    );
  }
}

/// Places a stop's mark [markTop] down the row, centred on the line, and
/// the line above and below it. A mark taller than its row (very large
/// text) runs past the bottom rather than overflowing.
class _RailLayout extends MultiChildLayoutDelegate {
  _RailLayout({required this.markTop});

  final double markTop;

  @override
  void performLayout(Size size) {
    const width = TodayLayout.railLine;
    final left = (size.width - width) / 2;
    void placeLine(_RailPart part, double top, double bottom) {
      layoutChild(part, BoxConstraints.tightFor(width: width, height: bottom > top ? bottom - top : 0));
      positionChild(part, Offset(left, top));
    }

    if (hasChild(_RailPart.through)) placeLine(_RailPart.through, 0, size.height);
    var dotCentre = markTop;
    if (hasChild(_RailPart.mark)) {
      final mark = layoutChild(_RailPart.mark, BoxConstraints(maxWidth: size.width));
      positionChild(_RailPart.mark, Offset((size.width - mark.width) / 2, markTop));
      dotCentre = markTop + mark.height - TodayLayout.railDot / 2;
    }
    if (hasChild(_RailPart.above)) placeLine(_RailPart.above, 0, markTop - TodayLayout.railLineGap);
    if (hasChild(_RailPart.below)) placeLine(_RailPart.below, dotCentre, size.height);
  }

  @override
  bool shouldRelayout(_RailLayout oldDelegate) => oldDelegate.markTop != markTop;
}

/// "9:00" over "am" over the stop's dot.
class _StopMark extends StatelessWidget {
  const _StopMark({required this.stop});

  final TimelineStop stop;

  @override
  Widget build(BuildContext context) {
    final chrome = TravaryChrome.of(context);
    final colors = chrome.colors;
    final now = stop.status == EntryStatus.now;
    final art = chrome.slots.icon(now ? IconSlot.timelineNow : IconSlot.timelineStop);
    final color = now ? colors.highlight : colors.ink;
    const dot = TodayLayout.railDot;
    final Widget mark = art.isFallback
        ? Container(
            key: ValueKey(now ? 'rail-dot-now' : 'rail-dot'),
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: now ? Border.all(color: colors.paper, width: 2.5) : null,
              boxShadow: now ? [BoxShadow(color: color.withValues(alpha: 0.5), spreadRadius: 2)] : null,
            ),
          )
        : SlotIcon(icon: art, color: color, size: dot + 6);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: TodayLayout.railMaxTextScale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(stop.time, style: TravaryText.railTime, maxLines: 1, softWrap: false),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(stop.period, style: TravaryText.railPeriod, maxLines: 1, softWrap: false),
          ),
          const SizedBox(height: 5),
          SizedBox.square(
            dimension: dot,
            child: OverflowBox(maxWidth: dot + 6, maxHeight: dot + 6, child: mark),
          ),
        ],
      ),
    );
  }
}
