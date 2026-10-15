import 'package:flutter/material.dart';

import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';

/// What the header pill says: the weather when there's a forecast, else the
/// date or a countdown.
class HeaderPillInfo {
  const HeaderPillInfo({required this.icon, required this.label, this.iconTinted = true});

  final IconSlot icon;
  final String label;

  /// One-colour icons take the palette's highlight; a full-colour weather
  /// picture keeps its own colours.
  final bool iconTinted;
}

/// "Good morning" over "Day 3 of 7 · Orlando", with the pill at the top
/// right. Tapping the pill or the day line opens the day chooser.
class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key, required this.greeting, required this.subtitle, this.pill, this.onChooseDay});

  final String greeting;
  final String subtitle;
  final HeaderPillInfo? pill;
  final VoidCallback? onChooseDay;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final day = Text(subtitle, style: TravaryText.daySubtitle, maxLines: 2, overflow: TextOverflow.ellipsis);

    return Padding(
      padding: const EdgeInsets.only(top: TodayLayout.headerTop),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: TodayLayout.headerInset),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(greeting, style: TravaryText.greeting, maxLines: 1),
                  ),
                ),
                if (onChooseDay == null)
                  Padding(padding: const EdgeInsets.only(top: 11), child: day)
                else
                  Semantics(
                    button: true,
                    hint: 'Choose a day',
                    child: InkWell(
                      onTap: onChooseDay,
                      borderRadius: BorderRadius.circular(TravaryRadius.small),
                      focusColor: colors.highlight.withValues(alpha: 0.2),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(padding: const EdgeInsets.only(top: 11, bottom: 4), child: day),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (pill != null) ...[const SizedBox(width: TravarySpace.sm), _pill(colors)],
          const SizedBox(width: TodayLayout.pillInset),
        ],
      ),
    );
  }

  /// The pill, centred in a full-size tap target that opens the day
  /// chooser when there is one.
  Widget _pill(TripColors colors) {
    final pill = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: TodayLayout.pillTarget),
      child: Center(child: HeaderPill(info: this.pill!)),
    );
    if (onChooseDay == null) return pill;
    return Semantics(
      button: true,
      hint: 'Choose a day',
      child: InkWell(
        onTap: onChooseDay,
        customBorder: const StadiumBorder(),
        focusColor: colors.highlight.withValues(alpha: 0.2),
        child: pill,
      ),
    );
  }
}

/// The raised pill: the `pill` surface when it exists, else a plain cream
/// pill with a soft shadow.
class HeaderPill extends StatelessWidget {
  const HeaderPill({super.key, required this.info});

  final HeaderPillInfo info;

  /// `common/pill.webp` is made at 3:1 (1536 × 512) and drawn 35 points tall.
  static const pillAspect = 3.0;
  static const pillHeight = 35.0;

  @override
  Widget build(BuildContext context) {
    final chrome = TravaryChrome.of(context);
    final surface = chrome.slots.surface(SurfaceSlot.pill);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 16, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SlotIcon(
            icon: chrome.slots.icon(info.icon),
            color: chrome.colors.highlight,
            tinted: info.iconTinted,
            size: 28,
          ),
          const SizedBox(width: 4),
          Text(info.label, style: TravaryText.pill, maxLines: 1),
        ],
      ),
    );

    return Semantics(
      label: info.label,
      excludeSemantics: true,
      child: surface == null
          ? DecoratedBox(
              key: const ValueKey('pill-fallback'),
              decoration: BoxDecoration(
                color: TravaryColors.paper,
                borderRadius: BorderRadius.circular(TravaryRadius.chip),
                boxShadow: const [
                  BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 3)),
                  BoxShadow(color: Color(0x0F000000), blurRadius: 1, offset: Offset(0, 1)),
                ],
              ),
              child: content,
            )
          // The raster pill keeps its own proportions; the words fit it.
          : SizedBox(
              height: pillHeight,
              child: AspectRatio(
                aspectRatio: pillAspect,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(image: artImageProvider(surface), fit: BoxFit.contain),
                    FittedBox(fit: BoxFit.scaleDown, child: content),
                  ],
                ),
              ),
            ),
    );
  }
}
