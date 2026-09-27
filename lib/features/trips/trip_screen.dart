import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/cards/booking_card.dart';
import '../../design/tokens.dart';
import '../../design/trip_theme_style.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../../logic/formatters.dart';
import '../../logic/trip_plan.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../booking/booking_actions.dart';
import '../premium/premium_gate.dart';

/// One trip, day by day, with every booking in order.
class TripScreen extends StatelessWidget {
  const TripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final plan = store.plan(tripId);
    if (plan == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('This trip has been deleted.')));
    }
    final trip = plan.trip;
    final days = [for (final day in plan.days) buildDayPlan(day, plan.bookings, store.now)];

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (PremiumFeature.familySharing.released || kDebugMode)
            IconButton(
              tooltip: 'Invite family',
              icon: const Icon(Icons.group_add_outlined),
              onPressed: () => _invite(context, plan),
            ),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'rename' => _rename(context, store, trip),
              'delete' => _delete(context, store, plan),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename trip')),
              PopupMenuItem(value: 'delete', child: Text('Delete trip')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TravaryColors.ink,
        foregroundColor: TravaryColors.paper,
        tooltip: 'Add to this trip',
        onPressed: () => startAddBooking(
          context,
          tripId: trip.id,
          date: plan.contains(store.today) ? store.today : plan.start,
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _rename(context, store, trip),
                    child: Text(trip.title, style: TravaryText.display),
                  ),
                  if (context.watch<PremiumStore>().forTrip(plan).allowed)
                    const Padding(
                      padding: EdgeInsets.only(top: TravarySpace.xs),
                      child: _PlusBadge(),
                    ),
                  const SizedBox(height: TravarySpace.xs),
                  Text(
                    plan.hasDates
                        ? '${formatDateRange(plan.start!, plan.end!)} · ${plan.dayCount} ${plan.dayCount == 1 ? 'day' : 'days'}'
                        : 'No dates yet',
                    style: TravaryText.body,
                  ),
                  const SizedBox(height: TravarySpace.lg),
                  Text('CARD STYLE', style: TravaryText.eyebrow),
                  const SizedBox(height: TravarySpace.sm),
                  Wrap(
                    spacing: TravarySpace.sm,
                    runSpacing: TravarySpace.sm,
                    children: [
                      for (final theme in TripTheme.values)
                        ChoiceChip(
                          avatar: Icon(tripThemeStyle(theme).icon, size: 16),
                          label: Text(theme.label),
                          selected: trip.theme == theme,
                          onSelected: (_) => store.updateTrip(trip.copyWith(theme: theme)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          for (final (index, day) in days.indexed) ..._daySlivers(context, store, plan, day, index + 1),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  List<Widget> _daySlivers(BuildContext context, TravelStore store, TripPlan plan, DayPlan day, int number) {
    final art = store.artForAll([for (final e in day.entries) e.booking]);
    final ongoing = [for (final b in day.ongoing) ongoingText(b, day.date)];
    return [
      SliverToBoxAdapter(
        child: SectionLabel('Day $number · ${formatDayShort(day.date)}${day.date == store.today ? ' · Today' : ''}'),
      ),
      for (final text in ongoing)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.sm),
            child: Text('${text.title} · ${text.subtitle}', style: TravaryText.small),
          ),
        ),
      if (day.entries.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
            child: Text('Free day', style: TravaryText.bodySoft),
          ),
        ),
      SliverList.builder(
        itemCount: day.entries.length,
        itemBuilder: (context, i) {
          final entry = day.entries[i];
          return Padding(
            padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.sm),
            child: BookingCard(
              text: cardTextForEntry(entry),
              art: art[i],
              size: CardSize.compact,
              status: entry.status,
              onTap: () => openBooking(context, entry.booking),
              onShowTickets: entry.booking.hasTickets ? () => showTickets(context, entry.booking) : null,
            ),
          );
        },
      ),
    ];
  }

  Future<void> _invite(BuildContext context, TripPlan plan) async {
    final access = await requirePremium(
      context,
      PremiumFeature.familySharing,
      trip: plan,
      source: 'trip_invite',
    );
    if (access == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family sharing is being built. Invites arrive soon.')),
    );
  }

  Future<void> _rename(BuildContext context, TravelStore store, Trip trip) async {
    final controller = TextEditingController(text: trip.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename trip'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty) return;
    await store.updateTrip(trip.copyWith(title: title.trim()));
  }

  Future<void> _delete(BuildContext context, TravelStore store, TripPlan plan) async {
    final count = plan.bookings.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${plan.trip.title}?'),
        content: Text(
          count == 0
              ? 'This trip has no bookings.'
              : 'Its $count ${count == 1 ? 'booking' : 'bookings'} and their tickets will be deleted too.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).pop();
    await store.deleteTrip(plan);
  }
}

/// "PLUS" on a trip covered by Plus or a Trip Pass.
class _PlusBadge extends StatelessWidget {
  const _PlusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TravaryColors.ink,
        borderRadius: BorderRadius.circular(TravaryRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 14, color: TravaryColors.mustard),
          const SizedBox(width: 4),
          Text('PLUS', style: TravaryText.eyebrow.copyWith(color: TravaryColors.paper, fontSize: 10.5)),
        ],
      ),
    );
  }
}
