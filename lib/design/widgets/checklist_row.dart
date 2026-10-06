import 'package:flutter/material.dart';

import '../tokens.dart';
import '../trip_chrome.dart';

/// One thing to do on a trip's checklist, on a paper panel: a tick box in
/// the trip's ink, the words (struck through once done), and when it's due
/// ("By 1 Oct", in coral when overdue). The box ticks it; the words open it.
class ChecklistRow extends StatelessWidget {
  const ChecklistRow({
    super.key,
    required this.title,
    required this.done,
    required this.semanticLabel,
    required this.onToggle,
    this.due,
    this.overdue = false,
    this.onOpen,
  });

  final String title;
  final bool done;
  final String? due;
  final bool overdue;
  final String semanticLabel;
  final VoidCallback onToggle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Row(
        children: [
          Semantics(
            checked: done,
            label: semanticLabel,
            onTap: onToggle,
            excludeSemantics: true,
            child: InkResponse(
              onTap: onToggle,
              radius: 24,
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: _TickBox(done: done, ink: colors.ink, paper: colors.paper),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, TravarySpace.md, TravarySpace.lg, TravarySpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TravaryText.label.copyWith(
                        fontSize: 16,
                        color: done ? TravaryColors.inkSoft : colors.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: TravaryColors.inkSoft,
                      ),
                    ),
                    if (due != null)
                      Text(
                        due!,
                        style: TravaryText.small.copyWith(color: overdue && !done ? TravaryColors.coral : null),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small square drawn in ink: empty, or filled with a tick.
class _TickBox extends StatelessWidget {
  const _TickBox({required this.done, required this.ink, required this.paper});

  final bool done;
  final Color ink;
  final Color paper;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: done ? ink : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: ink, width: 1.6),
      ),
      child: done ? Icon(Icons.check_rounded, size: 16, color: paper) : null,
    );
  }
}
