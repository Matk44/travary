import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../art/art_resolver.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'card_parts.dart';
import 'ongoing_tag_card.dart';
import 'room_key_card.dart';

/// Something you're in the middle of: the hotel you're staying at (its key
/// card, full size, as on the reference Today screen) or the hire car you
/// have (its key tag). A slim row stands in only if those shells are
/// missing. [text] comes from `ongoingCardText`.
class OngoingStrip extends StatelessWidget {
  const OngoingStrip({super.key, required this.text, required this.art, this.onTap});

  final CardText text;
  final ArtChoice art;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final room = art.shells.room;
    if (art.kind == BookingKind.stay && room != null) return RoomKeyCard(shell: room, text: text, onTap: onTap);
    final tag = art.shells.ongoing;
    if (tag != null) return OngoingTagCard(shell: tag, text: text, art: art, onTap: onTap);

    final colors = TravaryChrome.of(context).colors;
    final subtitle = [text.detail, _sentenceCase(text.footnote)].whereType<String>().join(' · ');
    return Semantics(
      button: onTap != null,
      label: [text.title, subtitle].join(', '),
      excludeSemantics: true,
      child: Material(
        color: TravaryColors.paper,
        elevation: 1,
        shadowColor: const Color(0x33000000),
        borderRadius: BorderRadius.circular(TravaryRadius.small),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          focusColor: colors.highlight.withValues(alpha: 0.18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Row(
              children: [
                const SizedBox(width: 14),
                SizedBox.square(
                  dimension: 28,
                  child: KindIcon(art: art, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.title, style: TravaryText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: TravaryText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _sentenceCase(String? value) =>
    value == null || value.isEmpty ? value : value[0] + value.substring(1).toLowerCase();
