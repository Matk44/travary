import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../art/art_resolver.dart';
import '../art/card_shells.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'card_parts.dart';
import 'shell_frame.dart';

/// Something you're in the middle of that isn't a hotel (a hire car, a
/// multi-day pass) on its key tag: the kind's icon in the printed medallion,
/// the name, then the company and the countdown ("Alamo · DROP-OFF IN 4
/// DAYS"). When both don't fit, a company gives way to the countdown (when
/// the car is due back matters more than who it's from); a hotel's room
/// number, on the tag only when its key card is missing, stays.
class OngoingTagCard extends StatelessWidget {
  const OngoingTagCard({super.key, required this.shell, required this.text, required this.art, this.onTap});

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
      semanticLabel: [text.title, text.detail, text.footnote].whereType<String>().join(', '),
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
              alignment: Alignment.centerLeft,
              children: [
                FitTitle(text.title, style: TravaryText.reservationTitle.copyWith(fontSize: 19)),
                const SizedBox(height: 2),
                LayoutBuilder(
                  builder: (context, box) {
                    final countdown = text.footnote == null
                        ? null
                        : TextSpan(
                            text: text.footnote,
                            style: TravaryText.footnote.copyWith(color: colors.highlight),
                          );
                    final both = TextSpan(
                      children: [
                        if (text.detail != null) TextSpan(text: text.detail, style: TravaryText.bodySoft),
                        if (text.detail != null && countdown != null)
                          TextSpan(text: '  ·  ', style: TravaryText.bodySoft),
                        ?countdown,
                      ],
                    );
                    final keepDetail = countdown == null || art.kind == BookingKind.stay;
                    final line = keepDetail || _fits(context, both, box.maxWidth) ? both : countdown;
                    return Text.rich(line, maxLines: 1, overflow: TextOverflow.ellipsis);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Whether [span] fits on one line [width] wide, at the reader's text size.
bool _fits(BuildContext context, TextSpan span, double width) {
  final painter = TextPainter(
    text: span,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout(maxWidth: width);
  final fits = !painter.didExceedMaxLines;
  painter.dispose();
  return fits;
}
