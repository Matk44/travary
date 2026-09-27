import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../design/trip_theme_style.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/formatters.dart';
import '../../logic/trip_plan.dart';
import '../../state/travel_store.dart';
import '../booking/booking_actions.dart';
import 'trip_screen.dart';

/// Every trip: happening now, coming up, and past.
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final today = store.today;
    final active = <TripPlan>[];
    final upcoming = <TripPlan>[];
    final past = <TripPlan>[];
    for (final plan in store.plans) {
      switch (plan.phaseOn(today)) {
        case TripPhase.active:
          active.add(plan);
        case TripPhase.upcoming:
          upcoming.add(plan);
        case TripPhase.past:
          past.add(plan);
      }
    }

    Widget section(String label, List<TripPlan> plans) => SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionLabel(label)),
        SliverList.separated(
          itemCount: plans.length,
          separatorBuilder: (_, _) => const SizedBox(height: TravarySpace.md),
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
            child: _TripTile(plan: plans[i], today: today),
          ),
        ),
      ],
    );

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, TravarySpace.lg, TravarySpace.gutter, 0),
              child: Text('Trips', style: TravaryText.display),
            ),
          ),
          if (store.plans.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  icon: Icons.map_outlined,
                  title: 'No trips yet',
                  message: 'Trips appear here as you add bookings.',
                  actionLabel: 'Add a booking',
                  onAction: () => startAddBooking(context),
                ),
              ),
            ),
          if (active.isNotEmpty) section('Happening now', active),
          if (upcoming.isNotEmpty) section('Coming up', upcoming),
          if (past.isNotEmpty) section('Past trips', past.reversed.toList()),
          const SliverToBoxAdapter(child: SizedBox(height: TravarySpace.xxl)),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.plan, required this.today});

  final TripPlan plan;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final style = tripThemeStyle(plan.trip.theme);
    final count = plan.bookings.length;
    final phase = plan.phaseOn(today);
    final status = switch (phase) {
      TripPhase.active => 'Day ${plan.dayNumber(today)} of ${plan.dayCount}',
      TripPhase.upcoming when plan.hasDates => 'Starts ${relativeDays(today.daysUntil(plan.start!))}',
      _ => null,
    };
    final summary = [
      '$count ${count == 1 ? 'booking' : 'bookings'}',
      ?status,
    ].join(' · ');

    return Material(
      color: TravaryColors.paper,
      borderRadius: BorderRadius.circular(TravaryRadius.card),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripScreen(tripId: plan.id)),
        ),
        child: SizedBox(
          height: 104,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 88,
                color: style.color,
                child: Icon(style.icon, color: TravaryColors.paper.withValues(alpha: 0.9), size: 34),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TravarySpace.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.trip.title, style: TravaryText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      if (plan.hasDates)
                        Text(
                          '${formatDateRange(plan.start!, plan.end!)} · ${plan.dayCount} ${plan.dayCount == 1 ? 'day' : 'days'}',
                          style: TravaryText.bodySoft,
                        ),
                      Text(summary, style: TravaryText.small),
                    ],
                  ),
                ),
              ),
              const Center(child: Icon(Icons.chevron_right_rounded, color: TravaryColors.inkFaint)),
              const SizedBox(width: TravarySpace.sm),
            ],
          ),
        ),
      ),
    );
  }
}
