import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/art/art_slots.dart';
import '../../design/cards/card_parts.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../state/travel_documents_store.dart';
import '../../state/travel_store.dart';
import 'document_actions.dart';

/// The way into the travel documents from the Documents tab: a pill that
/// says how many there are, whether any need checking and that they're
/// locked, never what they say. Opens them on a screen of their own,
/// behind the phone's lock.
class TravelDocumentsEntry extends StatelessWidget {
  const TravelDocumentsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelDocumentsStore>();
    final travel = context.watch<TravelStore>();
    final colors = TravaryChrome.of(context).colors;
    final count = store.count;
    final toCheck = store.needingAttention(today: travel.today, nextTrip: travel.focus.plan);
    final locked = count > 0 && !store.isUnlocked;
    final label = [
      'Travel documents',
      if (count == 0) 'add your passport' else '$count',
      if (toCheck > 0) '$toCheck to check',
      if (locked) 'locked',
    ].join(', ');
    final shape = BorderRadius.circular(TravaryRadius.chip);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Material(
          key: const ValueKey('travel-documents-entry'),
          color: TravaryColors.paper,
          borderRadius: shape,
          child: InkWell(
            onTap: () => openTravelDocuments(context),
            borderRadius: shape,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SlotIcon(
                    icon: TravaryChrome.of(context).slots.icon(IconSlot.passport),
                    color: colors.primary,
                    // Letterpress icons keep a quarter margin round the ink.
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      count == 0 ? 'Add your passport' : 'Travel documents',
                      style: TravaryText.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Text('$count', style: TravaryText.label.copyWith(color: TravaryColors.inkSoft)),
                  ],
                  if (toCheck > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      key: const ValueKey('travel-documents-to-check'),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: TravaryColors.coral, shape: BoxShape.circle),
                    ),
                  ],
                  if (locked) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.lock_outline_rounded, size: 15, color: TravaryColors.inkSoft),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
