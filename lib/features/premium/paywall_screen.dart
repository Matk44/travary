import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/widgets/onboarding_scene.dart';
import '../../domain/domain.dart';
import '../../logic/onboarding_art.dart';
import '../../logic/onboarding_films.dart';
import '../../logic/onboarding_journey.dart';
import '../../logic/pass_confirmation.dart';
import '../../state/analytics.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../onboarding/onboarding_pass_screen.dart';
import '../onboarding/onboarding_stage_layout.dart';

/// The paywall is the pass desk from onboarding: Travi presenting Travary
/// Plus and the Holiday Pass on the trip's own stage, its headline for what
/// the traveller reached for ([feature]), the benefits family first, and
/// "Not now" one tap away. No free trial: premium sells itself where it's
/// needed. Once a pass is bought the desk confirms it (Travi cheers, the
/// badge and what it covers), and "Carry on" hands back. Pops true when
/// something was bought, however it's left (Back included), so the action
/// that opened it carries on.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.feature, this.tripId, required this.source});

  /// What the traveller tried to use (shapes the headline).
  final PremiumFeature? feature;

  /// The trip in context, which makes a Holiday Pass possible.
  final String? tripId;

  /// Where the paywall was opened from, for funnel analytics.
  final String source;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  /// The pass just bought or restored here.
  PassConfirmation? _confirmed;

  @override
  void initState() {
    super.initState();
    track('paywall_shown', {'source': widget.source, 'feature': widget.feature?.name});
  }

  void _close() {
    if (_confirmed != null) return Navigator.of(context).pop(true);
    track('paywall_dismissed', {'source': widget.source});
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumStore>();
    final plan = context.watch<TravelStore>().plan(widget.tripId ?? '');
    final confirmed = _confirmed;
    return PopScope(
      // Paid for: Back leaves with "bought", like Carry on.
      canPop: !premium.busy && confirmed == null,
      onPopInvokedWithResult: (popped, _) {
        if (!popped && confirmed != null) Navigator.of(context).pop(true);
      },
      child: OnboardingStageLayout(
        scene: OnboardingScene(
          stage: onboardingStage(plan?.trip.destination),
          cues: confirmed == null ? traviCuesFor(OnboardingBeat.desk) : traviCuesForPassConfirmed(),
        ),
        words: confirmed == null
            ? paywallWordsFor(widget.feature)
            : passConfirmedWords(confirmed.kind, restored: confirmed.restored),
        wordsKey: confirmed == null ? 'paywall-${widget.feature?.name}' : 'paywall-confirmed',
        onBack: _close,
        backEnabled: !premium.busy,
        backTooltip: 'Close',
        backKey: 'paywall-close',
        snugFloor: true,
        floor: OnboardingPassPanel(
          // A trip that's gone (or none) offers the Annual Pass only.
          tripId: plan?.id,
          feature: widget.feature,
          freeLabel: 'Not now',
          confirmedLabel: 'Carry on',
          source: widget.source,
          onConfirmed: (confirmation) => setState(() => _confirmed = confirmation),
          onDone: (outcome) {
            if (outcome == OnboardingPassOutcome.free) return _close();
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );
  }
}
