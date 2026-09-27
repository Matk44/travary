import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../art/art_catalog.dart';
import '../art/art_resolver.dart';
import '../kind_style.dart';
import '../tokens.dart';
import 'card_parts.dart';

enum CardSize {
  /// The featured "next up" card at the top of today.
  hero,

  /// A normal card on the timeline.
  standard,

  /// A single row: finished items, trip timelines, the Wallet.
  compact,
}

/// The one widget every screen uses to show a booking.
///
/// Screens hand over ready-made [text] and [art] and pick a [size]; the card
/// decides how that booking looks. Restyling the app's cards means changing
/// this file and `card_parts.dart`. No screen needs to change.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.text,
    required this.art,
    this.size = CardSize.standard,
    this.status = EntryStatus.upcoming,
    this.onTap,
    this.onShowTickets,
  });

  final CardText text;
  final ArtChoice art;
  final CardSize size;
  final EntryStatus status;
  final VoidCallback? onTap;

  /// Shown as a "Show tickets" button when set.
  final VoidCallback? onShowTickets;

  static const heroHeight = 232.0;
  static const standardHeight = 124.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: [text.eyebrow, text.title, text.when].whereType<String>().join(', '),
      excludeSemantics: size == CardSize.compact,
      child: switch (size) {
        CardSize.hero => _HeroCard(this),
        CardSize.standard => _StandardCard(this),
        CardSize.compact => _CompactCard(this),
      },
    );
  }
}

bool _isLight(Color color) => color.computeLuminance() > 0.5;

const _stubShapes = {CardShape.ticket, CardShape.boardingPass, CardShape.travelTicket};

class _HeroCard extends StatelessWidget {
  const _HeroCard(this.card);

  final BookingCard card;

  static const stubWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    final style = KindStyle.of(card.art.kind);
    final palette = style.palette(card.art.variant);
    final fg = palette.foreground;
    final showStub = _stubShapes.contains(style.shape);
    final hasImage = card.art.asset != null;

    return SizedBox(
      height: BookingCard.heroHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          final stubAt = showStub ? (box.maxWidth - stubWidth) / box.maxWidth : null;
          return PhysicalShape(
            clipper: TicketClipper(stubAt: stubAt),
            clipBehavior: Clip.antiAlias,
            color: palette.background,
            elevation: 3,
            shadowColor: const Color(0x55000000),
            child: InkWell(
              onTap: card.onTap,
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ArtPanel(art: card.art),
                        if (hasImage && card.art.scene != null)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  palette.background.withValues(alpha: 0.9),
                                  palette.background.withValues(alpha: 0),
                                ],
                                stops: const [0.35, 0.8],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 16, 18),
                          child: _HeroText(card: card, fg: fg),
                        ),
                      ],
                    ),
                  ),
                  if (style.shape == CardShape.keyCard)
                    Container(width: 30, color: TravaryColors.tealDeep),
                  if (showStub) _Stub(text: card.text.stub ?? 'ADMIT', seed: card.art.variant),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({required this.card, required this.fg});

  final BookingCard card;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final text = card.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.eyebrow, style: TravaryText.eyebrow.copyWith(color: fg.withValues(alpha: 0.85))),
        const SizedBox(height: 6),
        Text(
          text.title,
          style: TravaryText.heroTitle.copyWith(color: fg),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(width: 120, height: 1.2, color: fg.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        if (text.whenAndDetail != null)
          Text(
            text.whenAndDetail!,
            style: TravaryText.body.copyWith(color: fg, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const Spacer(),
        if (card.onShowTickets != null)
          StampButton(label: 'Show tickets', onPressed: card.onShowTickets!, color: TravaryColors.ink),
      ],
    );
  }
}

class _Stub extends StatelessWidget {
  const _Stub({required this.text, required this.seed});

  final String text;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _HeroCard.stubWidth,
      color: TravaryColors.paper,
      child: Row(
        children: [
          const TearLine(color: TravaryColors.inkFaint),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TravaryText.eyebrow.copyWith(color: TravaryColors.ink, fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StubBarcode(seed: seed, color: TravaryColors.ink),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardCard extends StatelessWidget {
  const _StandardCard(this.card);

  final BookingCard card;

  static const artWidth = 104.0;

  @override
  Widget build(BuildContext context) {
    final style = KindStyle.of(card.art.kind);
    final palette = style.palette(card.art.variant);
    final fg = palette.foreground;
    final light = _isLight(palette.background);
    final text = card.text;
    final isTicket = _stubShapes.contains(style.shape);

    return SizedBox(
      height: BookingCard.standardHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          final stubAt = isTicket ? (box.maxWidth - artWidth) / box.maxWidth : null;
          return PhysicalShape(
            clipper: TicketClipper(stubAt: stubAt),
            clipBehavior: Clip.antiAlias,
            color: palette.background,
            elevation: 1.5,
            shadowColor: const Color(0x44000000),
            child: InkWell(
              onTap: card.onTap,
              child: Row(
                children: [
                  if (style.shape == CardShape.reservation)
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: LuggageTag(icon: style.icon, variant: card.art.variant),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            text.eyebrow,
                            style: TravaryText.eyebrow.copyWith(
                              color: light ? palette.accent : fg.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text.title,
                            style: TravaryText.title.copyWith(color: fg),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (text.whenAndDetail != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              text.whenAndDetail!,
                              style: TravaryText.bodySoft.copyWith(color: fg.withValues(alpha: 0.85)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (isTicket) TearLine(color: fg.withValues(alpha: 0.4)),
                  SizedBox(width: artWidth, child: ArtPanel(art: card.art, format: ArtFormat.vignette)),
                  if (style.shape == CardShape.keyCard)
                    Container(width: 18, color: TravaryColors.tealDeep),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompactCard extends StatelessWidget {
  const _CompactCard(this.card);

  final BookingCard card;

  @override
  Widget build(BuildContext context) {
    final style = KindStyle.of(card.art.kind);
    final palette = style.palette(card.art.variant);
    final text = card.text;
    final subtitle = [_sentenceCase(text.eyebrow), text.detail ?? text.place]
        .whereType<String>()
        .join(' · ');

    return Opacity(
      opacity: card.status == EntryStatus.done ? 0.55 : 1,
      child: Material(
        color: TravaryColors.paper,
        borderRadius: BorderRadius.circular(TravaryRadius.small),
        child: InkWell(
          onTap: card.onTap,
          borderRadius: BorderRadius.circular(TravaryRadius.small),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 66,
                  child: Text(text.when ?? '', style: TravaryText.small.copyWith(color: TravaryColors.ink)),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isLight(palette.background) ? palette.accent.withValues(alpha: 0.18) : palette.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    style.icon,
                    size: 19,
                    color: _isLight(palette.background) ? TravaryColors.ink : palette.foreground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.title, style: TravaryText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: TravaryText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (card.onShowTickets != null)
                  IconButton(
                    onPressed: card.onShowTickets,
                    tooltip: 'Show tickets',
                    icon: const Icon(Icons.confirmation_number_outlined, color: TravaryColors.inkSoft),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _sentenceCase(String value) =>
    value.isEmpty ? value : value[0] + value.substring(1).toLowerCase();
