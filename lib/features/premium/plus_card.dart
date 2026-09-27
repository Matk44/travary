import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../domain/domain.dart';
import '../../logic/formatters.dart';
import '../../logic/price_text.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import 'premium_gate.dart';

/// Profile card: your plan, your Trip Passes, and a way to Plus.
class PlusCard extends StatelessWidget {
  const PlusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumStore>();
    final travel = context.watch<TravelStore>();
    final policy = premium.policy;
    final plus = premium.entitlements.plus;
    final plusOffer = premium.offer(OfferKind.plusAnnual);

    final String title;
    final String body;
    if (policy.hasPlus && plus != null) {
      final date = formatDate(LocalDate.fromDateTime(plus.expiresAt));
      title = policy.inTrial ? 'Plus · free trial' : 'Travary Plus';
      body = policy.inTrial
          ? 'Your trial ends on $date${plusOffer == null ? '' : ', then ${priceOf(plusOffer)} a year'}.'
          : (plus.willRenew ? 'Renews on $date.' : 'Ends on $date.');
    } else {
      final left = policy.freeSmartImportsLeft;
      title = 'Travary Plus';
      body =
          'Smart Import, family sharing and ticket backup. '
          '$left free Smart Import${left == 1 ? '' : 's'} left.';
    }
    final passes = [
      for (final id in premium.entitlements.tripPasses)
        travel.plan(id)?.trip.title ?? 'A past trip',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
      child: Container(
        padding: const EdgeInsets.all(TravarySpace.lg),
        decoration: BoxDecoration(
          color: policy.hasPlus ? TravaryColors.ink : TravaryColors.paper,
          borderRadius: BorderRadius.circular(TravaryRadius.card),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: policy.hasPlus ? TravaryColors.paper : TravaryColors.ink,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: policy.hasPlus
                        ? TravaryColors.mustard
                        : TravaryColors.coral,
                  ),
                  const SizedBox(width: TravarySpace.sm),
                  Text(
                    title,
                    style: TravaryText.title.copyWith(
                      color: policy.hasPlus
                          ? TravaryColors.paper
                          : TravaryColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TravarySpace.sm),
              Text(
                body,
                style: TravaryText.bodySoft.copyWith(
                  color: policy.hasPlus
                      ? TravaryColors.paper.withValues(alpha: 0.85)
                      : null,
                ),
              ),
              for (final trip in passes)
                Padding(
                  padding: const EdgeInsets.only(top: TravarySpace.xs),
                  child: Text('Trip Pass: $trip', style: TravaryText.label),
                ),
              if (!policy.hasPlus) ...[
                const SizedBox(height: TravarySpace.md),
                FilledButton(
                  onPressed: () => showPaywall(context, source: 'profile'),
                  child: const Text('See Travary Plus'),
                ),
              ],
              TextButton(
                onPressed: premium.busy ? null : premium.restore,
                style: TextButton.styleFrom(
                  foregroundColor: policy.hasPlus
                      ? TravaryColors.paper
                      : TravaryColors.ink,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Restore purchases'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug only: flip between plans to see every state of the app.
class TestPlanSwitcher extends StatelessWidget {
  const TestPlanSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumStore>();
    final now = context.read<TravelStore>().now;
    final e = premium.entitlements;
    final current = !premium.hasPlus
        ? 'free'
        : (premium.policy.inTrial ? 'trial' : 'plus');

    if (!kDebugMode || !premium.isTestStore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Test plan', style: TravaryText.label),
          const SizedBox(height: TravarySpace.sm),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'free', label: Text('Free')),
              ButtonSegment(value: 'trial', label: Text('Trial')),
              ButtonSegment(value: 'plus', label: Text('Plus')),
            ],
            selected: {current},
            onSelectionChanged: (value) {
              final choice = value.single;
              premium.debugSetEntitlements(switch (choice) {
                'trial' => e.copyWith(
                  plus: PlusSubscription(
                    expiresAt: now.add(const Duration(days: 14)),
                    inTrial: true,
                  ),
                ),
                'plus' => e.copyWith(
                  plus: PlusSubscription(
                    expiresAt: now.add(const Duration(days: 365)),
                  ),
                ),
                _ => e.copyWith(clearPlus: true),
              });
            },
          ),
          TextButton(
            onPressed: () => premium.debugSetEntitlements(
              e.copyWith(
                clearPlus: true,
                tripPasses: const {},
                smartImportsUsed: 0,
              ),
            ),
            child: const Text('Reset passes and free imports'),
          ),
        ],
      ),
    );
  }
}
