import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/domain.dart';
import '../tokens.dart';

/// A row of trip days to jump between. The selected day is filled in and
/// today carries a small dot.
class DayStrip extends StatefulWidget {
  const DayStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.today,
    required this.onSelected,
  });

  final List<LocalDate> days;
  final LocalDate selected;
  final LocalDate today;
  final ValueChanged<LocalDate> onSelected;

  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  static const _itemWidth = 52.0;
  static const _gap = 8.0;
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centreSelected(animate: false));
  }

  @override
  void didUpdateWidget(DayStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centreSelected(animate: true));
    }
  }

  void _centreSelected({required bool animate}) {
    if (!_controller.hasClients) return;
    final index = widget.days.indexOf(widget.selected);
    if (index == -1) return;
    final viewport = _controller.position.viewportDimension;
    final target = (TravarySpace.gutter + index * (_itemWidth + _gap) + _itemWidth / 2 - viewport / 2)
        .clamp(0.0, _controller.position.maxScrollExtent);
    if (animate) {
      _controller.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _controller.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
        itemCount: widget.days.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, index) {
          final day = widget.days[index];
          final selected = day == widget.selected;
          final isToday = day == widget.today;
          final fg = selected ? TravaryColors.paper : TravaryColors.ink;
          return Semantics(
            selected: selected,
            button: true,
            label: DateFormat('EEEE d MMMM').format(day.toDateTime()),
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => widget.onSelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _itemWidth,
                decoration: BoxDecoration(
                  color: selected ? TravaryColors.ink : TravaryColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? TravaryColors.ink : TravaryColors.line),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(day.toDateTime()).toUpperCase(),
                      style: TravaryText.eyebrow.copyWith(color: fg, fontSize: 10, letterSpacing: 1),
                    ),
                    const SizedBox(height: 2),
                    Text('${day.day}', style: TravaryText.title.copyWith(color: fg, fontSize: 20)),
                    const SizedBox(height: 3),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday ? TravaryColors.coral : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
