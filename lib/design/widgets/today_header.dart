import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/pricing.dart';
import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'pass_badge.dart';

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
  const TodayHeader({
    super.key,
    this.title,
    this.titleLike,
    required this.subtitle,
    this.pill,
    this.pass,
    this.onChooseDay,
  });

  /// The big heading: the greeting on today's page, the day's name on
  /// another day. Left out on pages that head themselves (a trip's
  /// countdown, where to next).
  final String? title;

  /// The words whose line the heading stands level with, when it isn't
  /// them: another day's name keeps the height of today's greeting, so the
  /// days of the sheet line up as they slide past each other (the greeting
  /// shrinks to fit beside the pill, a shorter name wouldn't).
  final String? titleLike;
  final String subtitle;
  final HeaderPillInfo? pill;
  final OfferKind? pass;
  final VoidCallback? onChooseDay;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final day = Text(subtitle, style: TravaryText.daySubtitle, maxLines: 2, overflow: TextOverflow.ellipsis);
    final heading = title;
    // The day line sits a little below the heading, or at the top without one.
    final gap = heading == null ? 0.0 : 11.0;

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
                if (heading != null) _heading(heading),
                if (onChooseDay == null)
                  Padding(
                    padding: EdgeInsets.only(top: gap),
                    child: day,
                  )
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
                        child: Padding(
                          padding: EdgeInsets.only(top: gap, bottom: 4),
                          child: day,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (pill != null || pass != null) ...[
            const SizedBox(width: TravarySpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (pill != null) _pill(colors),
                if (pass case final kind?) PassBadge(kind: kind),
              ],
            ),
          ],
          const SizedBox(width: TodayLayout.pillInset),
        ],
      ),
    );
  }

  /// The heading, shrunk to fit the width. With [titleLike] it is in a line
  /// as tall as those words would make, at most that big.
  Widget _heading(String text) {
    final style = TravaryText.greeting;
    final like = titleLike;
    Widget line() => Semantics(
      header: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(text, style: style, maxLines: 1),
      ),
    );
    if (like == null) return line();
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: like, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final shrink = math.min(1.0, constraints.maxWidth / painter.width);
        return SizedBox(height: painter.height * shrink, child: line());
      },
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
