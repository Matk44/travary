import 'package:flutter/material.dart';

import '../tokens.dart';

/// Small spaced-capitals heading between groups: "EARLIER TODAY".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.inset = true});

  final String text;
  final Widget? trailing;

  /// False when the parent already applies the screen gutter.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final side = inset ? TravarySpace.gutter : 0.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(side, TravarySpace.xl, side, TravarySpace.sm),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: TravaryText.eyebrow)),
          ?trailing,
        ],
      ),
    );
  }
}

/// A rounded chip like the weather pill in the mockup: "In 12 days".
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: TravaryColors.paper,
        borderRadius: BorderRadius.circular(TravaryRadius.chip),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: TravaryColors.coral),
            const SizedBox(width: 6),
          ],
          Text(label, style: TravaryText.label),
        ],
      ),
    );
  }
}

/// A friendly empty state with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TravarySpace.xxl, vertical: TravarySpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: TravaryColors.kraft),
          const SizedBox(height: TravarySpace.lg),
          Text(title, style: TravaryText.title, textAlign: TextAlign.center),
          const SizedBox(height: TravarySpace.sm),
          Text(message, style: TravaryText.bodySoft, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: TravarySpace.xl),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
