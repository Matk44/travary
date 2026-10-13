import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../art/art_resolver.dart';
import '../art/art_slots.dart';
import '../art/card_shells.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'card_parts.dart';
import 'shell_frame.dart';

/// The featured "next up" booking on its shell: the look's admission
/// ticket (its destination printed on), or a windowed boarding pass,
/// restaurant or travel ticket with the booking's own scene showing through
/// the window (drawn beneath the shell). Eyebrow, title, time, details, the
/// stub's label or table badge and the button are live text on top.
class FeaturedTicketCard extends StatelessWidget {
  const FeaturedTicketCard({
    super.key,
    required this.shell,
    required this.text,
    required this.art,
    this.onTap,
    this.onAction,
  });

  final ShellArt shell;
  final CardText text;

  /// The booking's picture, shown in a windowed shell's window.
  final ArtChoice art;
  final VoidCallback? onTap;

  /// The button, labelled by [CardText.action] ("Show tickets"); falls back
  /// to [onTap].
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final geometry = shell.geometry;
    final action = onAction ?? onTap;
    final actionLabel = text.action ?? 'Details';
    final ink = geometry.textInk == ShellInk.light ? TravaryColors.paper : TravaryColors.ink;
    final scene = geometry.scene;
    // The table disc already says "TABLE FOR 4": the line keeps to the time.
    final showsBadge = text.badge != null && geometry.badge != null;
    final line = showsBadge ? text.when : text.whenAndDetail;

    return ShellFrame(
      shell: shell,
      fallbackColor: geometry.textInk == ShellInk.light ? TravaryColors.tealDeep : TravaryColors.paper,
      onTap: onTap,
      semanticLabel: [text.eyebrow, text.title, text.when, text.detail].whereType<String>().join(', '),
      underlays: [
        // A hair larger than the window: the shell's own frame covers the
        // edge, so no seam shows and nothing needs clipping.
        if (scene != null)
          ShellOverlay(
            FractionRect(scene.left - 0.006, scene.top - 0.012, scene.right + 0.006, scene.bottom + 0.012),
            ArtPanel(key: const ValueKey('scene-window'), art: art, alignment: Alignment.centerRight),
          ),
      ],
      overlays: [
        ShellOverlay(
          geometry.text,
          ExcludeSemantics(
            child: ShellTextBlock(
              children: [
                ShellEyebrow(text.eyebrow, style: TravaryText.shellEyebrow.copyWith(color: ink)),
                const SizedBox(height: 5),
                FitTitle(
                  text.title,
                  style: TravaryText.ticketTitle.copyWith(color: ink),
                  floorScale: ShellLayout.titleFloorScale,
                ),
                const SizedBox(height: 7),
                ShellRule(color: ink.withValues(alpha: 0.75), width: 0.62),
                const SizedBox(height: 7),
                // One line: the ticket's printed stamp frame leaves room
                // for no more above it.
                if (line != null)
                  Text(
                    line,
                    style: TravaryText.shellLine.copyWith(color: ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
        if (text.stub != null && geometry.stubLabel != null)
          ShellOverlay(
            geometry.stubLabel!,
            ExcludeSemantics(
              child: RotatedBox(
                quarterTurns: 3,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(text.stub!, style: TravaryText.stubLabel, maxLines: 1),
                  ),
                ),
              ),
            ),
          ),
        if (showsBadge)
          ShellOverlay(
            geometry.badge!,
            ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (text.badgeCaption != null)
                      Text(text.badgeCaption!, style: TravaryText.stubLabel.copyWith(fontSize: 7, letterSpacing: 1.6)),
                    Text(text.badge!, style: TravaryText.ticketTitle.copyWith(color: TravaryColors.ink, height: 1)),
                  ],
                ),
              ),
            ),
          ),
        // A printed stamp frame is never left empty.
        if (geometry.action != null && (action != null || geometry.actionFramed))
          ShellOverlay(
            geometry.action!,
            interactive: action != null,
            _TicketButton(
              label: actionLabel,
              onPressed: action,
              angle: geometry.actionAngle,
              framed: geometry.actionFramed,
            ),
          ),
      ],
    );
  }
}

/// The ticket's button. On a ticket that prints its own stamp frame only
/// the words are set in it; otherwise the stamp comes from the `stamp`
/// surface, or a plain paper button while that art is missing. Its anchor
/// grows to a 48-point tap target whatever the frame's size.
class _TicketButton extends StatelessWidget {
  const _TicketButton({required this.label, required this.onPressed, required this.angle, required this.framed});

  final String label;
  final VoidCallback? onPressed;
  final double angle;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final stamp = framed ? null : TravaryChrome.of(context).slots.surface(SurfaceSlot.stamp);
    final words = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: TravaryText.stamp.copyWith(color: colors.ink), maxLines: 1),
      ),
    );

    // The stamp or paper button is drawn at its anchor's own size: the tap
    // target around it may be bigger, but the picture mustn't cover the
    // line above it.
    final anchor = ShellAnchor.maybeOf(context);
    Widget sized(Widget child) => anchor == null
        ? child
        : Center(
            child: SizedBox(width: anchor.width, height: anchor.height, child: child),
          );

    final Widget face;
    if (framed) {
      face = Center(child: words);
    } else if (stamp != null) {
      face = sized(
        Stack(
          fit: StackFit.expand,
          children: [
            // `common/stamp.png` is made at the frame's 3.3:1; never stretched.
            Image(image: artImageProvider(stamp), fit: BoxFit.contain),
            Center(child: words),
          ],
        ),
      );
    } else {
      // Missing `common/stamp.png` (docs/ART_ASSET_GAPS.md).
      face = sized(
        DecoratedBox(
          key: const ValueKey('stamp-fallback'),
          decoration: BoxDecoration(
            color: TravaryColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.ink, width: 2),
          ),
          child: Center(child: words),
        ),
      );
    }

    return Semantics(
      button: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Transform.rotate(
        angle: angle,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            focusColor: colors.highlight.withValues(alpha: 0.3),
            child: face,
          ),
        ),
      ),
    );
  }
}
