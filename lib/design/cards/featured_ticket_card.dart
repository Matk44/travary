import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../art/art_slots.dart';
import '../art/card_shells.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'card_parts.dart';
import 'shell_frame.dart';

/// The featured "next up" booking on its complete ticket shell: the trip's
/// illustration is printed on the ticket; eyebrow, title, time, details, the
/// stub's "ADMIT TWO" and the button are live text on top.
class FeaturedTicketCard extends StatelessWidget {
  const FeaturedTicketCard({super.key, required this.shell, required this.text, this.onTap, this.onAction});

  final ShellArt shell;
  final CardText text;
  final VoidCallback? onTap;

  /// The button ("Show tickets"); falls back to [onTap] ("Details").
  final VoidCallback? onAction;

  static const _onTicket = TravaryColors.paper;

  @override
  Widget build(BuildContext context) {
    final geometry = shell.geometry;
    final action = onAction ?? onTap;
    final actionLabel = onAction != null ? 'Show tickets' : (text.action ?? 'Details');

    return ShellFrame(
      shell: shell,
      fallbackColor: TravaryColors.tealDeep,
      onTap: onTap,
      semanticLabel: [text.eyebrow, text.title, text.when, text.detail].whereType<String>().join(', '),
      overlays: [
        ShellOverlay(
          geometry.text,
          ExcludeSemantics(
            child: ShellTextBlock(
              children: [
                Text(
                  text.eyebrow,
                  style: TravaryText.shellEyebrow.copyWith(color: _onTicket),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                FitTitle(text.title, style: TravaryText.ticketTitle),
                const SizedBox(height: 7),
                ShellRule(color: _onTicket.withValues(alpha: 0.75), width: 0.62),
                const SizedBox(height: 7),
                // One line: the ticket's printed stamp frame leaves room
                // for no more above it.
                if (text.whenAndDetail != null)
                  Text(
                    text.whenAndDetail!,
                    style: TravaryText.shellLine.copyWith(color: _onTicket),
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
        if (action != null && geometry.action != null)
          ShellOverlay(
            geometry.action!,
            interactive: true,
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
  final VoidCallback onPressed;
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

    final Widget face;
    if (framed) {
      face = Center(child: words);
    } else if (stamp != null) {
      face = Stack(
        fit: StackFit.expand,
        children: [
          // `common/stamp.png` is made at the frame's 3.3:1; never stretched.
          Image(image: artImageProvider(stamp), fit: BoxFit.contain),
          Center(child: words),
        ],
      );
    } else {
      // Missing `common/stamp.png` (docs/ART_ASSET_GAPS.md).
      face = DecoratedBox(
        key: const ValueKey('stamp-fallback'),
        decoration: BoxDecoration(
          color: TravaryColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.ink, width: 2),
        ),
        child: Center(child: words),
      );
    }

    return Semantics(
      button: true,
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
