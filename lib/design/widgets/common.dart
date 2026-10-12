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

/// A rounded chip like the weather pill in the mockup: "In 12 days". With
/// [onPressed] it's a button, like the Trips tab's "+ New trip".
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.label, this.icon, this.onPressed});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(TravaryRadius.chip);
    return Semantics(
      button: onPressed != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Material(
          color: TravaryColors.paper,
          borderRadius: shape,
          child: InkWell(
            onTap: onPressed,
            borderRadius: shape,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18, color: TravaryColors.coral), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(label, style: TravaryText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
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

/// A friendly empty state with an optional action, and an optional quieter
/// second one below it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.art,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  }) : assert(icon != null || art != null);

  final IconData? icon;

  /// A picture in place of the icon: Travi making a cameo.
  final Widget? art;

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TravarySpace.xxl, vertical: TravarySpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          art ?? Icon(icon, size: 48, color: TravaryColors.kraft),
          const SizedBox(height: TravarySpace.lg),
          Text(title, style: TravaryText.title, textAlign: TextAlign.center),
          const SizedBox(height: TravarySpace.sm),
          Text(message, style: TravaryText.bodySoft, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: TravarySpace.xl),
            FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.add_rounded), label: Text(actionLabel!)),
          ],
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: TravarySpace.sm),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ],
      ),
    );
  }
}

/// A bottom sheet's drag handle, drawn by the sheet itself (as Material's
/// own: a 32 × 4 bar in a 48-point band), for sheets that let something
/// stand over their top edge.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    button: true,
    onTap: () => Navigator.of(context).maybePop(),
    child: SizedBox(
      height: kMinInteractiveDimension,
      child: Center(
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ),
  );
}
