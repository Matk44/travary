import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../art/art_catalog.dart';
import '../art/art_resolver.dart';
import '../kind_style.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'card_parts.dart';
import 'featured_ticket_card.dart';
import 'room_key_card.dart';
import 'tagged_reservation_card.dart';

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
/// this folder. No screen needs to change.
///
/// Each kind is a physical object drawn from raster shells (`ArtChoice.shells`):
/// a featured ticket for what's next (a key card when that's a stay), the
/// hotel key card for stays, and a tagged reservation card for everything
/// else. Only if a trip has no shell at all (the art is missing from the
/// build) does a plain panel stand in, with no imitation of the material.
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

  @override
  Widget build(BuildContext context) {
    final shells = art.shells;
    final isStay = art.kind == BookingKind.stay;
    switch (size) {
      case CardSize.hero:
        if (isStay && shells.room != null) return RoomKeyCard(shell: shells.room!, text: text, onTap: onTap);
        if (shells.featured != null) {
          return FeaturedTicketCard(shell: shells.featured!, text: text, onTap: onTap, onAction: onShowTickets);
        }
      case CardSize.standard:
        if (isStay && shells.room != null) return RoomKeyCard(shell: shells.room!, text: text, onTap: onTap);
        if (shells.reservation != null) {
          return TaggedReservationCard(shell: shells.reservation!, text: text, art: art, onTap: onTap);
        }
      case CardSize.compact:
        return _Labelled(card: this, child: _CompactCard(this));
    }
    return _Labelled(card: this, child: _PlainCard(this));
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.card, required this.child});

  final BookingCard card;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = card.text;
    return Semantics(
      button: card.onTap != null,
      label: [text.eyebrow, text.title, text.when].whereType<String>().join(', '),
      excludeSemantics: card.size == CardSize.compact,
      child: child,
    );
  }
}

/// Stands in for a missing shell: a plain rounded panel with the card's
/// text and picture. Listed as a gap in docs/ART_ASSET_GAPS.md whenever it
/// can appear.
class _PlainCard extends StatelessWidget {
  const _PlainCard(this.card);

  final BookingCard card;

  @override
  Widget build(BuildContext context) {
    final style = KindStyle.of(card.art.kind);
    final palette = style.palette(card.art.variant);
    final hero = card.size == CardSize.hero;
    final text = card.text;
    final fg = palette.foreground;

    return SizedBox(
      key: const ValueKey('plain-card'),
      height: hero ? 200 : 116,
      child: Material(
        color: palette.background,
        borderRadius: BorderRadius.circular(TravaryRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: card.onTap,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 220,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text.eyebrow, style: TravaryText.shellEyebrow.copyWith(color: fg)),
                          const SizedBox(height: 4),
                          Text(
                            text.title,
                            style: (hero ? TravaryText.ticketTitle : TravaryText.reservationTitle).copyWith(color: fg),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (text.whenAndDetail != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              text.whenAndDetail!,
                              style: TravaryText.shellLine.copyWith(color: fg),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (hero && card.onShowTickets != null) ...[
                            const SizedBox(height: 10),
                            OutlinedButton(onPressed: card.onShowTickets, child: const Text('Show tickets')),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: hero ? 150 : 104,
                child: ArtPanel(art: card.art, format: hero ? ArtFormat.scene : ArtFormat.vignette),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row: finished items, trip days, the Documents list. The kind's
/// raster icon sits in a small paper disc.
class _CompactCard extends StatelessWidget {
  const _CompactCard(this.card);

  final BookingCard card;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final text = card.text;
    final subtitle = [_sentenceCase(text.eyebrow), text.detail ?? text.place].whereType<String>().join(' · ');

    return Opacity(
      opacity: card.status == EntryStatus.done ? 0.55 : 1,
      child: Material(
        color: TravaryColors.paper,
        borderRadius: BorderRadius.circular(TravaryRadius.small),
        child: InkWell(
          onTap: card.onTap,
          focusColor: colors.highlight.withValues(alpha: 0.18),
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
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: TravaryColors.linen, shape: BoxShape.circle),
                  child: KindIcon(art: card.art, color: TravaryColors.ink),
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

String _sentenceCase(String value) => value.isEmpty ? value : value[0] + value.substring(1).toLowerCase();
