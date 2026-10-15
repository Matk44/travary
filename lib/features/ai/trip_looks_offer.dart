import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/ledger.dart';
import '../../design/widgets/travi_cameo.dart';
import '../../logic/ai_consent.dart';
import '../../logic/travi_cameos.dart';
import '../../state/ai_consent_store.dart';
import 'ai_consent_sheet.dart';

/// On a trip's page, once it has a booking: Travi offering to dress the
/// trip up, which needs Google's AI. "Show me" asks properly (the sheet);
/// "Not now" puts it away for good (Profile keeps the switch).
class TripLooksOffer extends StatelessWidget {
  const TripLooksOffer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    return PaperPanel(
      key: const ValueKey('trip-looks-offer'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(TravarySpace.md, TravarySpace.md, TravarySpace.lg, TravarySpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(child: TraviCameo(moment: TraviMoment.hello, height: 72, close: true)),
                const SizedBox(width: TravarySpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(aiLooksOfferTitle, style: TravaryText.ledgerTitle.copyWith(fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(aiLooksOfferCopy, style: TravaryText.small),
                    ],
                  ),
                ),
              ],
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: TravarySpace.xs,
              children: [
                TextButton(
                  key: const ValueKey('trip-looks-not-now'),
                  onPressed: () => context.read<AiConsentStore>().decline(AiAsk.tripLooks),
                  child: Text('Not now', style: TravaryText.label.copyWith(color: TravaryColors.inkSoft)),
                ),
                TextButton(
                  key: const ValueKey('trip-looks-show-me'),
                  onPressed: () => askAiConsent(context, AiAsk.tripLooks),
                  child: Text('Show me', style: TravaryText.label.copyWith(color: colors.ink)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
