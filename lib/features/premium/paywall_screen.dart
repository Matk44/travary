import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/purchase_service.dart';
import '../../design/tokens.dart';
import '../../domain/domain.dart';
import '../../logic/formatters.dart';
import '../../logic/price_text.dart';
import '../../logic/trip_plan.dart';
import '../../state/analytics.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';

/// Travary Plus / Trip Pass paywall.
///
/// Built on the plan in docs/PRODUCT_PLAN.md: Plus preselected, a Trip Pass
/// when there's a trip to attach it to, prices framed per month and per day,
/// a transparent trial timeline, and an easy way out. Returns true from the
/// route when something was bought.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.feature, this.tripId, required this.source});

  /// What the traveller tried to use (shapes the headline).
  final PremiumFeature? feature;

  /// The trip in context, which makes a Trip Pass possible.
  final String? tripId;

  /// Where the paywall was opened from, for funnel analytics.
  final String source;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  OfferKind _selected = OfferKind.plusAnnual;

  @override
  void initState() {
    super.initState();
    track('paywall_shown', {'source': widget.source, 'feature': widget.feature?.name});
  }

  void _close() {
    track('paywall_dismissed', {'source': widget.source});
    Navigator.of(context).pop(false);
  }

  Future<void> _buy(Offer offer, TripPlan? plan) async {
    final premium = context.read<PremiumStore>();
    final outcome = await premium.purchase(
      offer,
      tripId: offer.kind == OfferKind.tripPass ? plan?.id : null,
      source: widget.source,
    );
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.purchased:
        Navigator.of(context).pop(true);
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That didn\'t go through. You haven\'t been charged.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumStore>();
    final travel = context.watch<TravelStore>();
    final plan = widget.tripId == null ? null : travel.plan(widget.tripId!);
    final plus = premium.offer(OfferKind.plusAnnual);
    final pass = premium.offer(OfferKind.tripPass);
    final canPass = pass != null && premium.policy.canBuyTripPassFor(plan);
    final selected = canPass && _selected == OfferKind.tripPass ? pass : plus;
    final copy = _PaywallCopy.forFeature(widget.feature);

    return Scaffold(
      backgroundColor: TravaryColors.linen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TravarySpace.sm),
              child: Row(
                children: [
                  IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: _close),
                  const Spacer(),
                  TextButton(
                    onPressed: premium.busy ? null : premium.restore,
                    child: const Text('Restore purchases'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.lg),
                children: [
                  Text('TRAVARY PLUS', style: TravaryText.eyebrow.copyWith(color: TravaryColors.coral)),
                  const SizedBox(height: TravarySpace.sm),
                  Text(copy.headline, style: TravaryText.display.copyWith(fontSize: 32)),
                  const SizedBox(height: TravarySpace.sm),
                  Text(copy.subtitle, style: TravaryText.bodySoft),
                  const SizedBox(height: TravarySpace.xl),
                  // Plans first: price and choice sit next to the button
                  // without scrolling. The details follow below.
                  if (plus != null)
                    _PlanOption(
                      selected: selected == plus,
                      title: 'Travary Plus',
                      badge: 'Best value',
                      price: plus.trialDays != null
                          ? 'Free for ${plus.trialDays} days, then ${priceOf(plus)}/year'
                          : '${priceOf(plus)}/year',
                      detail: '${perMonth(plus)} a month · everyone on your trips, up to ${Pricing.familySize}',
                      onTap: () => setState(() => _selected = OfferKind.plusAnnual),
                    ),
                  if (canPass) ...[
                    const SizedBox(height: TravarySpace.md),
                    _PlanOption(
                      selected: selected == pass,
                      title: 'Just ${plan!.trip.title}',
                      price: '${priceOf(pass)} once',
                      detail: 'Trip Pass · no subscription · ${perDay(pass, plan.dayCount)} a day',
                      onTap: () => setState(() => _selected = OfferKind.tripPass),
                    ),
                  ],
                  const SizedBox(height: TravarySpace.xl),
                  if (selected != null && selected.kind == OfferKind.plusAnnual && selected.trialDays != null)
                    _TrialTimeline(offer: selected)
                  else if (selected != null && selected.kind == OfferKind.tripPass && plan != null)
                    _PassSummary(plan: plan),
                  const SizedBox(height: TravarySpace.xl),
                  Text('WHAT YOU GET', style: TravaryText.eyebrow),
                  const SizedBox(height: TravarySpace.md),
                  _Benefits(highlight: widget.feature),
                ],
              ),
            ),
            _Footer(
              offer: selected,
              busy: premium.busy,
              testStore: premium.isTestStore,
              onBuy: selected == null ? null : () => _buy(selected, plan),
              onNotNow: _close,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallCopy {
  const _PaywallCopy(this.headline, this.subtitle);

  final String headline;
  final String subtitle;

  static _PaywallCopy forFeature(PremiumFeature? feature) => switch (feature) {
    PremiumFeature.smartImport => const _PaywallCopy(
      'Skip the typing',
      'Snap a screenshot or PDF of any booking and Travary fills it in for you.',
    ),
    PremiumFeature.familySharing => const _PaywallCopy(
      'Everyone on the same page',
      'Invite the family. Everyone gets the plan, the updates and their own tickets.',
    ),
    PremiumFeature.ticketBackup => const _PaywallCopy(
      'Your tickets, safe',
      'Every ticket backed up and on all your devices, even if your phone goes missing.',
    ),
    PremiumFeature.flightAlerts => const _PaywallCopy(
      'Never miss a gate change',
      'Delays and gate changes the moment they happen.',
    ),
    null => const _PaywallCopy(
      'Holidays, handled',
      'Less admin, everyone in sync, and your tickets always safe.',
    ),
  };
}

class _Benefits extends StatelessWidget {
  const _Benefits({this.highlight});

  final PremiumFeature? highlight;

  @override
  Widget build(BuildContext context) {
    final features = [
      for (final f in PremiumFeature.values)
        if (f.released || kDebugMode) f,
    ];
    return Column(
      children: [
        for (final pillar in PremiumPillar.values)
          if (features.any((f) => f.pillar == pillar))
            Padding(
              padding: const EdgeInsets.only(bottom: TravarySpace.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: TravaryColors.paper, shape: BoxShape.circle),
                    child: Icon(_pillarIcon(pillar), color: TravaryColors.teal, size: 22),
                  ),
                  const SizedBox(width: TravarySpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pillar.label, style: TravaryText.label),
                        for (final feature in features.where((f) => f.pillar == pillar))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${feature.title}: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: feature == highlight ? TravaryColors.coral : null,
                                    ),
                                  ),
                                  TextSpan(text: feature.benefit),
                                  if (!feature.released) const TextSpan(text: '  (soon)'),
                                ],
                              ),
                              style: TravaryText.bodySoft,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  IconData _pillarIcon(PremiumPillar pillar) => switch (pillar) {
    PremiumPillar.time => Icons.bolt_rounded,
    PremiumPillar.together => Icons.family_restroom_rounded,
    PremiumPillar.peaceOfMind => Icons.verified_user_outlined,
  };
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.selected,
    required this.title,
    required this.price,
    required this.detail,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final String title;
  final String price;
  final String detail;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: TravaryColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TravaryRadius.card),
          side: BorderSide(
            color: selected ? TravaryColors.ink : TravaryColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TravaryRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(TravarySpace.lg),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? TravaryColors.ink : TravaryColors.inkFaint,
                ),
                const SizedBox(width: TravarySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(title, style: TravaryText.title.copyWith(fontSize: 19))),
                          if (badge != null) ...[
                            const SizedBox(width: TravarySpace.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: TravaryColors.coral,
                                borderRadius: BorderRadius.circular(TravaryRadius.chip),
                              ),
                              child: Text(
                                badge!.toUpperCase(),
                                style: TravaryText.eyebrow.copyWith(color: TravaryColors.paper, fontSize: 9.5, letterSpacing: 1),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(price, style: TravaryText.label),
                      Text(detail, style: TravaryText.small),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Today / Day 12 / Day 14" so nobody is surprised by a charge.
class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final days = offer.trialDays!;
    final steps = [
      ('Today', 'Everything in Plus unlocks. Nothing to pay today.', Icons.lock_open_rounded),
      ('Day ${days - 2}', 'We\'ll remind you that your trial is ending.', Icons.notifications_none_rounded),
      ('Day $days', 'Your Plus year starts at ${priceOf(offer)}. Cancel any time before and you won\'t be charged.', Icons.event_available_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOW YOUR FREE TRIAL WORKS', style: TravaryText.eyebrow),
        const SizedBox(height: TravarySpace.md),
        for (final (index, step) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: index == 0 ? TravaryColors.ink : TravaryColors.paper,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(step.$3, size: 16, color: index == 0 ? TravaryColors.paper : TravaryColors.ink),
                    ),
                    if (index < steps.length - 1)
                      Expanded(child: Container(width: 2, color: TravaryColors.line)),
                  ],
                ),
                const SizedBox(width: TravarySpace.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: TravarySpace.lg, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.$1, style: TravaryText.label),
                        Text(step.$2, style: TravaryText.bodySoft),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PassSummary extends StatelessWidget {
  const _PassSummary({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final until = plan.end!.addDays(Pricing.tripPassGraceDays);
    return Container(
      padding: const EdgeInsets.all(TravarySpace.lg),
      decoration: BoxDecoration(
        color: TravaryColors.paper,
        borderRadius: BorderRadius.circular(TravaryRadius.card),
      ),
      child: Text(
        'One payment, no subscription. Unlocks Plus on ${plan.trip.title} for everyone '
        'on the trip, until ${formatDate(until)}.',
        style: TravaryText.bodySoft,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.offer,
    required this.busy,
    required this.testStore,
    required this.onBuy,
    required this.onNotNow,
  });

  final Offer? offer;
  final bool busy;
  final bool testStore;
  final VoidCallback? onBuy;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final offer = this.offer;
    final label = switch (offer) {
      null => 'Unavailable',
      Offer(kind: OfferKind.plusAnnual, trialDays: final int days) => 'Start my free $days days',
      Offer(kind: OfferKind.plusAnnual) => 'Get Travary Plus · ${priceOf(offer)}/year',
      Offer(kind: OfferKind.tripPass) => 'Get Trip Pass · ${priceOf(offer)}',
    };
    final smallPrint = offer?.kind == OfferKind.tripPass
        ? 'One-off purchase. Doesn\'t renew.'
        : 'Plus renews yearly until you cancel. Cancel any time in your App Store or Google Play settings.';

    return Container(
      padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, TravarySpace.md, TravarySpace.gutter, TravarySpace.sm),
      decoration: const BoxDecoration(
        color: TravaryColors.linen,
        border: Border(top: BorderSide(color: TravaryColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: busy ? null : onBuy,
            child: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(label),
          ),
          TextButton(onPressed: onNotNow, child: const Text('Not now')),
          Text(
            testStore ? '$smallPrint\nTest store: nothing is charged.' : smallPrint,
            style: TravaryText.small.copyWith(fontSize: 11.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
