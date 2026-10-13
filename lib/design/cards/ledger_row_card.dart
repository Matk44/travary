import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../art/art_resolver.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'card_parts.dart';

/// A booking as a row of a trip's plan (`CardSize.ledger`): the date in its
/// own column ("11" over "OCT", blank for a second row that day), a hairline,
/// the title and one line of what matters ("QF 25 · 8:55pm"), then the
/// tickets when there are some, and a chevron when it opens. Drawn on the paper panel it
/// sits in; finished bookings fade.
class LedgerRowCard extends StatelessWidget {
  const LedgerRowCard({
    super.key,
    required this.text,
    required this.art,
    this.status = EntryStatus.upcoming,
    this.onTap,
    this.onShowTickets,
  });

  final CardText text;
  final ArtChoice art;
  final EntryStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onShowTickets;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(TravarySpace.lg, TravarySpace.md, TravarySpace.sm, TravarySpace.md),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: LedgerLayout.dateColumn,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (text.day != null) Text(text.day!, style: TravaryText.ledgerDay.copyWith(color: colors.ink)),
                    if (text.month != null)
                      Text(text.month!, style: TravaryText.ledgerMonth.copyWith(color: colors.ink)),
                  ],
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: TravarySpace.md),
                color: TravaryColors.line,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.title,
                      style: TravaryText.ledgerTitle.copyWith(color: colors.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (text.detail != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          SizedBox.square(
                            dimension: 15,
                            child: KindIcon(art: art, color: TravaryColors.inkSoft),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              text.detail!,
                              style: TravaryText.small,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onShowTickets != null)
                IconButton(
                  tooltip: 'Show tickets',
                  onPressed: onShowTickets,
                  icon: Icon(Icons.confirmation_number_outlined, color: colors.ink, size: 22),
                ),
              if (onTap != null) const Center(child: Icon(Icons.chevron_right_rounded, color: TravaryColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
    return status == EntryStatus.done ? Opacity(opacity: 0.55, child: row) : row;
  }
}
