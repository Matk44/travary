import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../art/art_catalog.dart';
import '../art/art_resolver.dart';
import '../art/card_shells.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'card_parts.dart';
import 'shell_frame.dart';

/// A booking on the tagged reservation shell: the category icon printed on
/// the luggage tag, live eyebrow, title and time on the card, and, on the
/// blank shell, the booking's own vignette in the right-hand panel. A
/// complete themed shell already carries its illustration, so nothing is
/// layered on it.
class TaggedReservationCard extends StatelessWidget {
  const TaggedReservationCard({super.key, required this.shell, required this.text, required this.art, this.onTap});

  final ShellArt shell;
  final CardText text;
  final ArtChoice art;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final geometry = shell.geometry;
    final colors = TravaryChrome.of(context).colors;
    const ink = TravaryColors.ink;
    final vignette = art.preferring(ArtFormat.vignette);

    return ShellFrame(
      shell: shell,
      fallbackColor: TravaryColors.paper,
      onTap: onTap,
      semanticLabel: [text.eyebrow, text.title, text.when, text.detail].whereType<String>().join(', '),
      overlays: [
        if (geometry.tagIcon != null)
          ShellOverlay(
            geometry.tagIcon!,
            ExcludeSemantics(
              child: Transform.rotate(
                angle: geometry.tagAngle,
                child: KindIcon(art: art, color: geometry.tagInk == ShellInk.light ? TravaryColors.paper : ink),
              ),
            ),
          ),
        ShellOverlay(
          geometry.text,
          ExcludeSemantics(
            child: ShellTextBlock(
              children: [
                Text(
                  text.eyebrow,
                  style: TravaryText.shellEyebrow.copyWith(color: colors.highlight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                FitTitle(text.title, style: TravaryText.reservationTitle),
                const SizedBox(height: 7),
                ShellRule(color: ink.withValues(alpha: 0.35), width: 0.36),
                const SizedBox(height: 7),
                if (text.whenAndDetail != null)
                  Text(text.whenAndDetail!, style: TravaryText.shellLine, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
        if (!shell.isComplete && geometry.vignette != null && vignette != null)
          ShellOverlay(
            geometry.vignette!,
            // Trimmed to its visible part, so the art fills the panel
            // rather than its canvas's empty margin; a picture that can't
            // load leaves the panel blank.
            ExcludeSemantics(
              child: TrimmedArt(
                key: const ValueKey('card-vignette'),
                image: vignette.image,
                alignment: const Alignment(0, 0.3),
              ),
            ),
          ),
      ],
    );
  }
}
