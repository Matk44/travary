import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../art/art_resolver.dart';
import '../art/card_shells.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'card_parts.dart';
import 'shell_frame.dart';

/// A note on its sheet of ruled paper: the note icon in the printed
/// medallion by the paperclip, live eyebrow, title and first line on the
/// rules. The same paper serves a note that's next up.
class NotePaperCard extends StatelessWidget {
  const NotePaperCard({super.key, required this.shell, required this.text, required this.art, this.onTap});

  final ShellArt shell;
  final CardText text;
  final ArtChoice art;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final geometry = shell.geometry;
    final colors = TravaryChrome.of(context).colors;

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
              child: KindIcon(art: art, color: TravaryColors.ink),
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
                const SizedBox(height: 8),
                if (text.whenAndDetail != null)
                  Text(text.whenAndDetail!, style: TravaryText.shellLine, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
