import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../art/card_shells.dart';
import '../tokens.dart';
import 'shell_frame.dart';

/// A stay on its hotel key-card shell: "HOTEL", the hotel's name, the room
/// and a small supporting line are live text in the card's quiet area.
class RoomKeyCard extends StatelessWidget {
  const RoomKeyCard({super.key, required this.shell, required this.text, this.onTap});

  final ShellArt shell;
  final CardText text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final geometry = shell.geometry;
    const ink = TravaryColors.ink;
    final detail = text.detail ?? text.when;

    return ShellFrame(
      shell: shell,
      fallbackColor: TravaryColors.paper,
      onTap: onTap,
      semanticLabel: [text.eyebrow, text.title, text.when, text.detail, text.footnote].whereType<String>().join(', '),
      overlays: [
        ShellOverlay(
          geometry.text,
          ExcludeSemantics(
            child: ShellTextBlock(
              children: [
                Text(
                  text.eyebrow,
                  style: TravaryText.shellEyebrow.copyWith(color: ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                FitTitle(text.title, style: TravaryText.roomTitle),
                const SizedBox(height: 8),
                ShellRule(color: ink.withValues(alpha: 0.7), width: 0.36),
                const SizedBox(height: 8),
                if (detail != null)
                  Text(
                    detail,
                    style: TravaryText.shellLine.copyWith(fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
        if (text.footnote != null && geometry.footnote != null)
          ShellOverlay(
            geometry.footnote!,
            ExcludeSemantics(
              child: Row(
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(text.footnote!, style: TravaryText.footnote, maxLines: 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 1, color: ink.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
