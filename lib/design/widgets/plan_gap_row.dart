import 'package:flutter/material.dart';

import '../art/art_slots.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'ledger.dart';

/// Something a trip still needs, under its plan: a quiet inset row with a
/// dashed edge, "Stay needed · 14–16 Oct · 2 nights", and "Add". Its menu
/// says it isn't needed ("we're staying with family").
class PlanGapRow extends StatelessWidget {
  const PlanGapRow({
    super.key,
    required this.title,
    required this.when,
    required this.icon,
    required this.semanticLabel,
    required this.onAdd,
    this.onNotNeeded,
  });

  final String title;
  final String when;
  final IconSlot icon;
  final String semanticLabel;
  final VoidCallback onAdd;
  final VoidCallback? onNotNeeded;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    return CustomPaint(
      painter: _DashedEdge(TravaryColors.inkFaint),
      child: Material(
        color: colors.paper.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(LedgerLayout.panelRadius),
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(LedgerLayout.panelRadius),
          child: Semantics(
            button: true,
            label: semanticLabel,
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TravarySpace.lg, TravarySpace.sm, TravarySpace.xs, TravarySpace.sm),
              child: Row(
                children: [
                  RowIcon(icon, size: 20),
                  const SizedBox(width: TravarySpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: TravaryText.label.copyWith(color: colors.ink, fontSize: 15.5)),
                        Text(when, style: TravaryText.small),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onAdd,
                    child: Text('Add', style: TravaryText.label.copyWith(color: colors.ink)),
                  ),
                  if (onNotNeeded != null)
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      icon: const Icon(Icons.more_horiz_rounded, color: TravaryColors.inkSoft),
                      onSelected: (_) => onNotNeeded!(),
                      itemBuilder: (_) => const [PopupMenuItem(value: 'hide', child: Text('Not needed'))],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedEdge extends CustomPainter {
  _DashedEdge(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(LedgerLayout.panelRadius),
    ).deflate(0.6);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 9) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedEdge oldDelegate) => oldDelegate.color != color;
}
