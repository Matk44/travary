import 'package:flutter/material.dart';

import '../art/art_resolver.dart';
import '../kind_style.dart';
import '../tokens.dart';

/// A slim card for something you're in the middle of: the hotel you're
/// staying at, the hire car you have. Sits under the day header.
class OngoingStrip extends StatelessWidget {
  const OngoingStrip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.art,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final ArtChoice art;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = KindStyle.of(art.kind);
    return Material(
      color: TravaryColors.paper,
      elevation: 1,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(TravaryRadius.small),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(style.icon, color: TravaryColors.teal, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TravaryText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: TravaryText.small),
                  ],
                ),
              ),
              if (style.shape == CardShape.keyCard)
                Container(width: 22, color: TravaryColors.tealDeep)
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
