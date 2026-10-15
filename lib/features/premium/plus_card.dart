import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../design/widgets/profile_stationery.dart';
import '../../design/widgets/profile_travi.dart';
import '../../domain/domain.dart';
import '../../logic/formatters.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../help/help_links.dart';
import 'premium_gate.dart';

/// Profile card: your plan, your Holiday Passes, a way to the Annual Pass,
/// and, with one, a way to manage or cancel it in the store.
class PlusCard extends StatelessWidget {
  const PlusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumStore>();
    final travel = context.watch<TravelStore>();
    final policy = premium.policy;
    final plus = premium.entitlements.plus;

    final passes = [
      for (final id in premium.entitlements.tripPasses.keys) travel.plan(id)?.trip.title ?? 'A past trip',
    ];
    final left = policy.freeSmartImportsLeft;
    final renewal = policy.hasPlus && plus != null
        ? '${plus.willRenew ? 'Renews' : 'Ends'} on ${formatDate(LocalDate.fromDateTime(plus.expiresAt))}.'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
      child: ProfileStationery.pass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: policy.hasPlus ? TravaryColors.mustard : TravaryColors.coral,
                        size: 28,
                      ),
                      const SizedBox(width: TravarySpace.sm),
                      Expanded(child: Text('Annual Pass', style: TravaryText.profilePassTitle)),
                    ],
                  ),
                  const SizedBox(height: TravarySpace.sm),
                  Text(renewal ?? 'A little help for every holiday.', style: TravaryText.profilePassLead),
                  const SizedBox(height: TravarySpace.sm),
                  LayoutBuilder(
                    builder: (context, box) {
                      final benefits = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Benefit(Icons.cloud_upload_rounded, 'Smart Imports'),
                          const _Benefit(Icons.people_rounded, 'Shared plans & tickets'),
                          const _Benefit(Icons.description_rounded, 'Booking-file backup'),
                          if (!policy.hasPlus) ...[
                            const SizedBox(height: TravarySpace.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                border: Border.all(color: TravaryColors.kraft),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '$left free Smart Import${left == 1 ? '' : 's'} left',
                                style: TravaryText.small,
                              ),
                            ),
                          ],
                        ],
                      );
                      const travi = SizedBox(
                        key: ValueKey('profile-travi-slot'),
                        width: 112,
                        height: 124,
                        child: ProfileTravi(),
                      );
                      // Keep the copy readable on small phones and at large
                      // text sizes. Pleading belongs only on the free upsell.
                      if (policy.hasPlus || box.maxWidth < 285 || MediaQuery.textScalerOf(context).scale(14) > 19) {
                        return benefits;
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 5, child: benefits),
                          const SizedBox(width: TravarySpace.sm),
                          const Expanded(flex: 3, child: travi),
                        ],
                      );
                    },
                  ),
                  for (final trip in passes)
                    Padding(
                      padding: const EdgeInsets.only(top: TravarySpace.sm),
                      child: Text('Holiday Pass: $trip', style: TravaryText.label),
                    ),
                  if (!policy.hasPlus) ...[
                    const SizedBox(height: TravarySpace.sm),
                    ProfilePassAction(
                      key: const ValueKey('profile-annual-pass'),
                      busy: premium.busy,
                      onPressed: () =>
                          showPaywall(context, tripId: context.read<TravelStore>().focus.plan?.id, source: 'profile'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: TravarySpace.sm),
            if (plus != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton(
                  key: const ValueKey('profile-manage-subscription'),
                  onPressed: () => openSubscriptions(context),
                  style: TextButton.styleFrom(
                    foregroundColor: TravaryColors.ink,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: TravaryText.body.copyWith(decoration: TextDecoration.underline),
                  ),
                  child: const Text('Manage or cancel'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: TextButton(
                key: const ValueKey('profile-restore-purchases'),
                onPressed: premium.busy ? null : premium.restore,
                style: TextButton.styleFrom(
                  foregroundColor: TravaryColors.ink,
                  minimumSize: const Size.fromHeight(48),
                  textStyle: TravaryText.body.copyWith(decoration: TextDecoration.underline),
                ),
                child: const Text('Restore purchases'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: TravaryColors.ink, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TravaryText.profileBenefit)),
      ],
    ),
  );
}

/// Debug only: flip between plans to see every state of the app.
class TestPlanSwitcher extends StatelessWidget {
  const TestPlanSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumStore>();
    final now = context.read<TravelStore>().now;
    final e = premium.entitlements;
    final current = premium.hasPlus ? 'plus' : 'free';

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
              ButtonSegment(value: 'plus', label: Text('Plus')),
            ],
            selected: {current},
            onSelectionChanged: (value) {
              final choice = value.single;
              premium.debugSetEntitlements(switch (choice) {
                'plus' => e.copyWith(plus: PlusSubscription(expiresAt: now.add(const Duration(days: 365)))),
                _ => e.copyWith(clearPlus: true),
              });
            },
          ),
          TextButton(
            onPressed: () =>
                premium.debugSetEntitlements(e.copyWith(clearPlus: true, tripPasses: const {}, smartImportsUsed: 0)),
            child: const Text('Reset passes and free imports'),
          ),
        ],
      ),
    );
  }
}
