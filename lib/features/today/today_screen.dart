import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/art/art_catalog.dart';
import '../../design/art/art_slots.dart';
import '../../design/cards/booking_card.dart';
import '../../design/cards/ongoing_strip.dart';
import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../design/widgets/countdown_trip_hero.dart';
import '../../design/widgets/day_timeline.dart';
import '../../design/widgets/today_header.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../logic/countdown_text.dart';
import '../../logic/day_plan.dart';
import '../../logic/formatters.dart';
import '../../logic/trip_plan.dart';
import '../../state/travel_store.dart';
import '../booking/booking_actions.dart';
import '../trips/trip_screen.dart';

/// Opens on what matters right now: today's plan during a trip, or the first
/// day of the next trip before it starts.
///
/// Top to bottom: the greeting and day, the featured "next up" ticket, the
/// hotel you're staying at, the rest of the day's bookings, and the day's
/// timeline. Other days of the trip are a swipe away, or a tap on the day
/// line ("Day 3 of 7 · Orlando") opens the day chooser.
///
/// Between trips, when a postcard suits the next trip, Today counts down to
/// it instead ([CountdownTripHero]); without one it keeps the first-day view.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.weather});

  /// Today's forecast, when there is one. Travary has no weather service
  /// yet; without it the pill shows the date or a countdown.
  final WeatherReport? weather;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  /// A day picked in the chooser or by swiping; null follows the focus day.
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
    final picked = _picked != null && plan != null && plan.contains(_picked!) ? _picked : null;
    final countdown = picked == null ? _countdownFor(store, focus) : null;
    final day = picked ?? focus.day;
    final dayPlan = store.dayPlan(day);
    final canChoose = countdown == null && plan != null && plan.dayCount > 1;

    return SafeArea(
      bottom: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: canChoose ? (details) => _swipe(details, plan, day) : null,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TodayHeader(
                greeting: greetingFor(store.now),
                subtitle: countdown != null ? 'Nothing planned today' : _subtitle(store, focus, day),
                pill: _pill(store, focus, day, countdown: countdown != null),
                onChooseDay: canChoose ? () => _chooseDay(context, plan, day, store.today) : null,
              ),
            ),
            if (!store.hasAnything)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyState(
                    icon: Icons.luggage_outlined,
                    title: 'Where are you off to?',
                    message:
                        'Add a flight, hotel, ticket or table. Travary sorts '
                        'your holiday into days and shows you each one as it comes.',
                    actionLabel: 'Add your first booking',
                    onAction: () => startAddBooking(context),
                  ),
                ),
              )
            else if (countdown != null)
              SliverToBoxAdapter(
                child: CountdownTripHero(
                  text: countdown.text,
                  postcard: countdown.postcard,
                  onOpen: () => _openTrip(context, countdown.plan),
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
            const SliverToBoxAdapter(child: SizedBox(height: TodayLayout.bottomGap)),
          ],
        ),
      ),
    );
  }

  String _subtitle(TravelStore store, TodayFocus focus, LocalDate day) {
    final plan = focus.plan;
    if (plan == null) return store.hasAnything ? 'No trips coming up' : 'Let\'s plan something';
    if (focus.isCountdown && day == plan.start) return '${plan.trip.title} ${relativeDays(focus.daysUntilStart!)}';
    final dayNumber = plan.dayNumber(day);
    final prefix = day == store.today ? '' : '${formatDayShort(day)} · ';
    return dayNumber == null
        ? '$prefix${plan.trip.title}'
        : '${prefix}Day $dayNumber of ${plan.dayCount} · ${plan.trip.title}';
  }

  /// Between trips, the next trip's countdown: only when nothing is on
  /// today and a postcard suits that trip (its own place, or its look).
  /// Otherwise null, and Today stays as it was.
  _Countdown? _countdownFor(TravelStore store, TodayFocus focus) {
    final plan = focus.plan;
    if (!focus.isCountdown || plan == null || !store.dayPlan(store.today).isEmpty) return null;
    final text = countdownTextFor(plan, store.today);
    final postcard = store.countdownPostcardFor(plan);
    if (text == null || postcard == null) return null;
    return (plan: plan, text: text, postcard: postcard.image);
  }

  void _openTrip(BuildContext context, TripPlan plan) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripScreen(tripId: plan.id)));

  /// The weather when there's a forecast, else the countdown before a trip
  /// or today's date. The countdown hero carries its own count, so the pill
  /// shows the date beside it.
  HeaderPillInfo _pill(TravelStore store, TodayFocus focus, LocalDate day, {required bool countdown}) {
    final weather = widget.weather;
    if (weather != null && (countdown || day == store.today)) {
      return HeaderPillInfo(icon: _weatherIcon(weather.condition), label: formatWeather(weather), iconTinted: false);
    }
    if (focus.isCountdown && !countdown) {
      return HeaderPillInfo(icon: IconSlot.flight, label: _countdownLabel(focus.daysUntilStart!));
    }
    return HeaderPillInfo(icon: IconSlot.calendar, label: formatDayShort(store.today));
  }

  static IconSlot _weatherIcon(WeatherCondition condition) => switch (condition) {
    WeatherCondition.sunny => IconSlot.weatherSunny,
    WeatherCondition.cloudy => IconSlot.weatherCloudy,
    WeatherCondition.rain => IconSlot.weatherRain,
    WeatherCondition.snow => IconSlot.weatherSnow,
  };

  String _countdownLabel(int days) => switch (days) {
    0 => 'Today!',
    1 => 'Tomorrow',
    _ => '$days days',
  };

  void _swipe(DragEndDetails details, TripPlan plan, LocalDate day) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 250) return;
    final next = day.addDays(velocity < 0 ? 1 : -1);
    if (plan.contains(next)) setState(() => _picked = next);
  }

  Future<void> _chooseDay(BuildContext context, TripPlan plan, LocalDate selected, LocalDate today) async {
    final picked = await showModalBottomSheet<LocalDate>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _DayChooser(plan: plan, selected: selected, today: today),
    );
    if (picked != null && mounted) setState(() => _picked = picked);
  }

  List<Widget> _daySlivers(BuildContext context, TravelStore store, DayPlan dayPlan) {
    final isToday = dayPlan.date == store.today;
    final art = store.artForAll([for (final e in dayPlan.entries) e.booking]);
    final hero = dayPlan.highlightIndex;
    final earlier = <int>[];
    final rest = <int>[];
    for (var i = 0; i < dayPlan.entries.length; i++) {
      if (i == hero) continue;
      (isToday && dayPlan.entries[i].status == EntryStatus.done ? earlier : rest).add(i);
    }

    Widget card(int index) {
      final entry = dayPlan.entries[index];
      final highlighted = index == hero;
      final size = highlighted
          ? CardSize.hero
          : (entry.status == EntryStatus.done ? CardSize.compact : CardSize.standard);
      return BookingCard(
        text: cardTextForEntry(entry, highlighted: highlighted),
        art: art[index],
        size: size,
        status: entry.status,
        onTap: () => openBooking(context, entry.booking),
        onShowTickets: ticketsAction(context, entry.booking),
      );
    }

    final items = <_Item>[
      if (hero != null) _Item(card(hero), inset: TodayLayout.featuredInset),
      for (final booking in dayPlan.ongoing)
        _Item(
          OngoingStrip(
            text: ongoingCardText(booking, dayPlan.date),
            art: store.artFor(booking),
            onTap: () => openBooking(context, booking),
          ),
        ),
      for (final index in rest) _Item(card(index), compact: dayPlan.entries[index].status == EntryStatus.done),
      if (earlier.isNotEmpty) ...[
        _Item(
          SectionLabel(
            'Earlier (${earlier.length})',
            inset: false,
            trailing: TextButton(
              onPressed: () => setState(() => _showEarlier = !_showEarlier),
              child: Text(_showEarlier ? 'Hide' : 'Show'),
            ),
          ),
          compact: true,
        ),
        if (_showEarlier)
          for (final index in earlier) _Item(card(index), compact: true),
      ],
    ];
    final stops = timelineFor(dayPlan);

    return [
      SliverPadding(
        padding: const EdgeInsets.only(top: TodayLayout.headerGap),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final gap = i == 0
                ? 0.0
                : (item.compact || items[i - 1].compact ? TodayLayout.compactGap : TodayLayout.cardGap);
            return Padding(padding: EdgeInsets.fromLTRB(item.inset, gap, item.inset, 0), child: item.child);
          },
        ),
      ),
      if (stops.length > 1)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(TodayLayout.cardInset, TodayLayout.timelineGap, TodayLayout.cardInset, 0),
          sliver: SliverToBoxAdapter(child: DayTimeline(stops: stops)),
        ),
    ];
  }
}

/// The next trip, its countdown wording and its postcard.
typedef _Countdown = ({TripPlan plan, CountdownText text, ArtImageRef postcard});

class _Item {
  const _Item(this.child, {this.inset = TodayLayout.cardInset, this.compact = false});

  final Widget child;
  final double inset;

  /// Rows sit closer together than cards.
  final bool compact;
}

/// Every day of the trip, to jump to one.
class _DayChooser extends StatelessWidget {
  const _DayChooser({required this.plan, required this.selected, required this.today});

  final TripPlan plan;
  final LocalDate selected;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final days = plan.days;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.sm),
              child: Text(plan.trip.title, style: TravaryText.headline),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: days.length,
                itemBuilder: (context, i) {
                  final date = days[i];
                  final isSelected = date == selected;
                  return Semantics(
                    selected: isSelected,
                    button: true,
                    label: formatDayLong(date),
                    excludeSemantics: true,
                    child: ListTile(
                      selected: isSelected,
                      title: Text('Day ${i + 1} · ${formatDayShort(date)}', style: TravaryText.label),
                      subtitle: date == today ? const Text('Today') : null,
                      trailing: isSelected ? const Icon(Icons.check_rounded) : null,
                      onTap: () => Navigator.of(context).pop(date),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
