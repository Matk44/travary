import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';

/// The day at a glance: a line through the day's timed stops, each with its
/// time and a word ("9:00 · Park"). Drawn in the trip palette's secondary
/// colour; the stop happening now is marked in its highlight. Many stops
/// scroll sideways rather than squeeze.
class DayTimeline extends StatelessWidget {
  const DayTimeline({super.key, required this.stops});

  final List<TimelineStop> stops;

  static const _dot = 13.0;
  static const _line = 2.4;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();
    final chrome = TravaryChrome.of(context);
    final colors = chrome.colors;
    final stopArt = chrome.slots.icon(IconSlot.timelineStop);
    final nowArt = chrome.slots.icon(IconSlot.timelineNow);

    return Semantics(
      container: true,
      label: 'The day at a glance',
      child: LayoutBuilder(
        builder: (context, box) {
          const inset = TodayLayout.timelineInset;
          final count = stops.length;
          final natural = box.maxWidth - 2 * inset;
          final spacing = count == 1 ? 0.0 : natural / (count - 1);
          final minSpacing = TodayLayout.timelineStopWidth;
          final width = count > 1 && spacing < minSpacing ? minSpacing * (count - 1) + 2 * inset : box.maxWidth;
          final step = count == 1 ? 0.0 : (width - 2 * inset) / (count - 1);

          Widget mark(TimelineStop stop) {
            final now = stop.status == EntryStatus.now;
            final art = now ? nowArt : stopArt;
            final color = now ? colors.highlight : colors.secondary;
            if (!art.isFallback) return SlotIcon(icon: art, color: color, size: _dot + 6);
            return Container(
              key: const ValueKey('timeline-dot'),
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: now ? Border.all(color: colors.paper, width: 2.5) : null,
                boxShadow: now ? [BoxShadow(color: color.withValues(alpha: 0.5), spreadRadius: 2)] : null,
              ),
            );
          }

          final scaler = MediaQuery.textScalerOf(context);
          double lineHeight(TextStyle style) => scaler.scale(style.fontSize!) * style.height!;
          final height = _dot + 3 + lineHeight(TravaryText.timelineTime) + lineHeight(TravaryText.timelineLabel) + 2;
          final labelWidth = count == 1 ? width : (step < 100 ? step : 100.0);
          double centreOf(int i) => count == 1 ? width / 2 : inset + i * step;

          final content = SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The line runs between the first and last stops.
                if (count > 1)
                  Positioned(
                    left: inset,
                    right: inset,
                    top: (_dot - _line) / 2,
                    height: _line,
                    child: ColoredBox(color: colors.secondary),
                  ),
                for (var i = 0; i < count; i++)
                  Positioned(
                    left: centreOf(i) - labelWidth / 2,
                    width: labelWidth,
                    top: 0,
                    bottom: 0,
                    child: _Stop(mark: mark(stops[i]), stop: stops[i], done: stops[i].status == EntryStatus.done),
                  ),
              ],
            ),
          );

          return width > box.maxWidth
              ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: content)
              : content;
        },
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.mark, required this.stop, required this.done});

  final Widget mark;
  final TimelineStop stop;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: stop.spoken,
      excludeSemantics: true,
      child: Opacity(
        opacity: done ? 0.55 : 1,
        child: Column(
          children: [
            SizedBox(
              height: DayTimeline._dot,
              child: Center(child: mark),
            ),
            const SizedBox(height: 3),
            Text(stop.time, style: TravaryText.timelineTime, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
            Text(
              stop.label,
              style: TravaryText.timelineLabel,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}
