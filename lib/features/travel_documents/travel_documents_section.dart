import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/cards/travel_document_card.dart';
import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../design/widgets/profile_stationery.dart';
import '../../logic/travel_documents.dart';
import '../../state/travel_documents_store.dart';
import '../../state/travel_store.dart';
import 'document_actions.dart';

/// "Your travel documents": passports, visas and insurance, by person.
/// Locked behind the phone's lock; while locked it shows only how many
/// there are. With none yet, it invites the first one.
class TravelDocumentsSection extends StatelessWidget {
  const TravelDocumentsSection({super.key, this.limit, this.illustratedInvitation = false});

  /// Show at most this many, then "See all" (the Documents tab).
  final int? limit;

  /// The standalone screen carries the same passport art as Profile.
  final bool illustratedInvitation;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelDocumentsStore>();
    final travel = context.watch<TravelStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          'Your travel documents',
          inset: false,
          trailing: store.isUnlocked || store.count == 0
              ? TextButton.icon(
                  onPressed: () => startAddTravelDocument(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                )
              : null,
        ),
        if (!store.isLoaded)
          const SizedBox.shrink()
        else if (store.count == 0)
          _Notice(
            key: const ValueKey('documents-invite'),
            icon: Icons.menu_book_rounded,
            art: illustratedInvitation ? const PassportIllustration(size: 84) : null,
            title: 'Passports, visas and insurance',
            message: 'Kept on this phone only, behind Face ID or your passcode.',
            onTap: () => startAddTravelDocument(context),
          )
        else if (!store.isUnlocked)
          _Notice(
            key: const ValueKey('documents-locked'),
            icon: Icons.lock_outline_rounded,
            title: store.count == 1 ? '1 document' : '${store.count} documents',
            message: 'Locked. Tap to open with Face ID or your passcode.',
            onTap: () => ensureDocumentsUnlocked(context),
          )
        else
          ..._documents(context, store, travel),
      ],
    );
  }

  List<Widget> _documents(BuildContext context, TravelDocumentsStore store, TravelStore travel) {
    final groups = documentsByHolder(store.documents);
    final showHolders = groups.length > 1;
    final widgets = <Widget>[];
    var shown = 0;
    for (final group in groups) {
      if (limit != null && shown >= limit!) break;
      if (showHolders) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: shown == 0 ? 0 : TravarySpace.sm, bottom: TravarySpace.xs),
            child: Text(group.holder, style: TravaryText.label.copyWith(color: TravaryColors.inkSoft)),
          ),
        );
      }
      for (final document in group.documents) {
        if (limit != null && shown >= limit!) break;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: TravarySpace.sm),
            child: TravelDocumentCard(
              key: ValueKey('travel-document-${document.id}'),
              text: documentCardText(document, today: travel.today, nextTrip: travel.focus.plan),
              type: document.type,
              onTap: () => openTravelDocument(context, document),
            ),
          ),
        );
        shown++;
      }
    }
    final count = store.documents.length;
    if (limit != null && count > limit!) {
      widgets.add(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: () => openTravelDocuments(context), child: Text('See all $count')),
        ),
      );
    }
    if (store.phoneHasNoLock) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: TravarySpace.xs),
          child: Text(
            'This phone has no passcode, so these can\'t be locked. Set one in your phone\'s settings.',
            style: TravaryText.small,
          ),
        ),
      );
    }
    return widgets;
  }
}

/// A quiet card standing in for the list: the invitation, or the lock.
class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    this.art,
    required this.title,
    required this.message,
    required this.onTap,
  });

  final IconData icon;
  final Widget? art;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(TravaryRadius.card);
    return Material(
      color: TravaryColors.paper,
      borderRadius: shape,
      elevation: 1,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: Padding(
          padding: const EdgeInsets.all(TravarySpace.md),
          child: LayoutBuilder(
            builder: (context, box) {
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: art == null ? TravaryText.label : TravaryText.title),
                  const SizedBox(height: 2),
                  Text(message, style: TravaryText.small),
                ],
              );
              if (art != null && (box.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(14) > 20)) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: art),
                    const SizedBox(height: TravarySpace.md),
                    copy,
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.chevron_right_rounded, color: TravaryColors.inkFaint),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  art ?? Icon(icon, color: TravaryColors.kraft, size: 28),
                  const SizedBox(width: TravarySpace.md),
                  Expanded(child: copy),
                  const Icon(Icons.chevron_right_rounded, color: TravaryColors.inkFaint),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
