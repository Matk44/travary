import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/cards/booking_card.dart';
import '../../design/cards/ongoing_strip.dart';
import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../design/widgets/day_strip.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../../logic/formatters.dart';
import '../../logic/trip_plan.dart';
import '../../state/travel_store.dart';
import '../booking/booking_actions.dart';

/// Opens on what matters right now: today's plan during a trip, or the first
/// day of the next trip before it starts. The day strip reaches every other
/// day of that trip in one tap.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  /// A day picked in the strip; null follows the focus day.
  LocalDate? _picked;

  /// Finished items stay folded away so "next up" is always near the top.
  bool _showEarlier = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    if (store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final focus = store.focus;
    final plan = focus.plan;
    final day = _picked != null && plan != null && plan.contains(_picked!) ? _picked! : focus.day;
    final dayPlan = store.dayPlan(day);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(store: store, focus: focus, day: day)),
          if (plan != null && plan.dayCount > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: TravarySpace.lg),
                child: DayStrip(
                  days: plan.days,
                  selected: day,
                  today: store.today,
                  onSelected: (picked) => setState(() => _picked = picked),
                ),
              ),
            ),
          if (!store.hasAnything)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  icon: Icons.luggage_outlined,
                  title: 'Where are you off to?',
                  message: 'Add a flight, hotel, ticket or table. Travary sorts '
                      'your holiday into days and shows you each one as it comes.',
                  actionLabel: 'Add your first booking',
                  onAction: () => startAddBooking(context),
                ),
              ),
            )
          else if (dayPlan.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.wb_twilight_rounded,
                title: plan == null ? 'Nothing coming up' : 'A free day',
                message: plan == null
                    ? 'Add a booking and your next trip will appear here.'
                    : 'Nothing booked on ${formatDayLong(day)}.',
                actionLabel: 'Add a booking',
                onAction: () => startAddBooking(context, date: day, tripId: plan?.id),
              ),
            )
          else
            ..._daySlivers(context, store, dayPlan),
          const SliverToBoxAdapter(child: SizedBox(height: TravarySpace.xxl)),
        ],
      ),
    );
  }

  List<Widget> _daySlivers(BuildContext context, TravelStore store, DayPlan dayPlan) {
    final isToday = dayPlan.date == store.today;
    final art = store.artForAll([for (final e in dayPlan.entries) e.booking]);
    final earlier = <int>[];
    final rest = <int>[];
    for (var i = 0; i < dayPlan.entries.length; i++) {
      (isToday && dayPlan.entries[i].status == EntryStatus.done ? earlier : rest).add(i);
    }

    Widget card(int index) {
      final entry = dayPlan.entries[index];
      final highlighted = index == dayPlan.highlightIndex;
      final CardSize resolved;
      if (highlighted) {
        resolved = CardSize.hero;
      } else if (entry.status == EntryStatus.done) {
        resolved = CardSize.compact;
      } else {
        resolved = CardSize.standard;
      }
      return Padding(
        padding: EdgeInsets.fromLTRB(
          TravarySpace.gutter, 0, TravarySpace.gutter,
          resolved == CardSize.compact ? TravarySpace.sm : TravarySpace.lg,
        ),
        child: BookingCard(
          text: cardTextForEntry(entry, highlighted: highlighted),
          art: art[index],
          size: resolved,
          status: entry.status,
          onTap: () => openBooking(context, entry.booking),
          onShowTickets: ticketsAction(context, entry.booking),
        ),
      );
    }

    return [
      if (dayPlan.ongoing.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, TravarySpace.lg, TravarySpace.gutter, 0),
          sliver: SliverList.separated(
            itemCount: dayPlan.ongoing.length,
            separatorBuilder: (_, _) => const SizedBox(height: TravarySpace.sm),
            itemBuilder: (context, i) {
              final booking = dayPlan.ongoing[i];
              final text = ongoingText(booking, dayPlan.date);
              return OngoingStrip(
                title: text.title,
                subtitle: text.subtitle,
                art: store.artFor(booking),
                onTap: () => openBooking(context, booking),
              );
            },
          ),
        ),
      if (earlier.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionLabel(
            'Earlier (${earlier.length})',
            trailing: TextButton(
              onPressed: () => setState(() => _showEarlier = !_showEarlier),
              child: Text(_showEarlier ? 'Hide' : 'Show'),
            ),
          ),
        ),
        if (_showEarlier)
          SliverList.builder(
            itemCount: earlier.length,
            itemBuilder: (context, i) => card(earlier[i]),
          ),
      ],
      if (rest.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionLabel(isToday ? (earlier.isEmpty ? 'Today' : 'Still to come') : formatDayLong(dayPlan.date)),
        ),
        SliverList.builder(
          itemCount: rest.length,
          itemBuilder: (context, i) => card(rest[i]),
        ),
      ],
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.store, required this.focus, required this.day});

  final TravelStore store;
  final TodayFocus focus;
  final LocalDate day;

  @override
  Widget build(BuildContext context) {
    final plan = focus.plan;
    final String subtitle;
    if (plan == null) {
      subtitle = store.hasAnything ? 'No trips coming up' : 'Let\'s plan something';
    } else if (focus.isCountdown && day == plan.start) {
      subtitle = '${plan.trip.title} ${relativeDays(focus.daysUntilStart!)}';
    } else {
      final dayNumber = plan.dayNumber(day);
      final prefix = day == store.today ? '' : '${formatDayShort(day)} · ';
      subtitle = dayNumber == null
          ? '$prefix${plan.trip.title}'
          : '${prefix}Day $dayNumber of ${plan.dayCount} · ${plan.trip.title}';
    }

    final pill = focus.isCountdown
        ? InfoPill(icon: Icons.flight_takeoff_rounded, label: _countdownLabel(focus.daysUntilStart!))
        : InfoPill(icon: Icons.calendar_today_rounded, label: formatDayShort(store.today));

    return Padding(
      padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, TravarySpace.lg, TravarySpace.gutter, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(greetingFor(store.now), style: TravaryText.display, maxLines: 1),
                ),
                const SizedBox(height: TravarySpace.xs),
                Text(subtitle, style: TravaryText.body.copyWith(fontSize: 17)),
              ],
            ),
          ),
          const SizedBox(width: TravarySpace.sm),
          Padding(padding: const EdgeInsets.only(top: 6), child: pill),
        ],
      ),
    );
  }

  String _countdownLabel(int days) => switch (days) {
    0 => 'Today!',
    1 => 'Tomorrow',
    _ => '$days days',
  };
}
