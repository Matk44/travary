import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/ledger.dart';
import '../../design/widgets/readable_width.dart';
import '../../state/travel_documents_store.dart';
import '../../state/travel_store.dart';
import 'document_actions.dart';
import 'travel_documents_section.dart';

/// Every travel document on one screen, with what Travary does (and never
/// does) with them. Asks for the phone's lock as it opens, when there's
/// anything to unlock.
class TravelDocumentsScreen extends StatefulWidget {
  const TravelDocumentsScreen({super.key});

  @override
  State<TravelDocumentsScreen> createState() => _TravelDocumentsScreenState();
}

class _TravelDocumentsScreenState extends State<TravelDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<TravelDocumentsStore>();
      if (store.count > 0 && !store.isUnlocked) ensureDocumentsUnlocked(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final travel = context.watch<TravelStore>();
    return TravaryChrome(
      colors: TripColors.of(travel.paletteFor(travel.focus.plan)),
      slots: travel.chromeArtFor(travel.focus.plan),
      child: Scaffold(
        appBar: AppBar(title: const BarText(child: Text('Travel documents'))),
        body: LinenBackground(
          child: ListView(
            padding: readablePadding(
              context,
              const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.xxl),
            ),
            children: [
              const TravelDocumentsSection(illustratedInvitation: true),
              const SizedBox(height: TravarySpace.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, size: 20, color: TravaryColors.inkSoft),
                  const SizedBox(width: TravarySpace.sm),
                  Expanded(
                    child: Text(
                      'These stay on this phone. Travary never uploads them, never reads them with AI and never '
                      'shares them with a trip\'s family. Your phone\'s own backup keeps a copy.',
                      style: TravaryText.small,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
