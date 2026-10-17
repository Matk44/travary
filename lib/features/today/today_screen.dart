import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/art/art_catalog.dart';
import '../../design/art/art_slots.dart';
import '../../design/cards/booking_card.dart';
import '../../design/cards/ongoing_strip.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/common.dart';
import '../../design/widgets/countdown_trip_hero.dart';
import '../../design/widgets/time_rail.dart';
import '../../design/widgets/today_header.dart';
import '../../design/widgets/travi_cameo.dart';
import '../../design/widgets/trip_calendar.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../logic/countdown_text.dart';
import '../../logic/countdown_widget_setup.dart';
import '../../logic/packing.dart';
import '../../logic/day_layout.dart';
import '../../logic/day_plan.dart';
import '../../logic/flight_status_text.dart';
import '../../logic/formatters.dart';
import '../../logic/travi_cameos.dart';
import '../../logic/trip_plan.dart';
import '../../state/countdown_widget_store.dart';
import '../../state/travel_store.dart';
import '../../state/travi_greetings.dart';
import '../booking/booking_actions.dart';
import '../trips/packing_list_screen.dart';
import '../trips/trip_details_sheet.dart';
import '../trips/trip_screen.dart';
import '../widget/countdown_widget_sheet.dart';

/// Opens on what matters right now: today's plan during a trip, or the first
/// day of the next trip before it starts.
///
/// Under the greeting and day, the day's cards run down the time rail: the
/// timed ones in time order, each with its time beside it, the featured
/// "next up" ticket in its place and the hotel you're staying at after it
/// ([layOutDay]). Other days of the trip are a swipe away, or a tap on the
/// date pill or the day line ("Day 3 of 7 · Orlando") opens the trip's
/// calendar.
///
/// Between trips, when a postcard suits the next trip, Today counts down to
/// it instead ([CountdownTripHero]); without one it keeps the first-day view.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.weather, this.shown});

  /// Today's forecast, when there is one. Travary has no weather service
  /// yet; without it the pill shows the date or a countdown.
  final WeatherReport? weather;

  /// Ticks each time Today comes back into view (from the home shell): the
  /// countdown replays its entry.
  final Listenable? shown;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  /// A day picked in the chooser or by swiping; null follows the focus day.
  LocalDate? _picked;

  /// The date when [_picked] was chosen. Once the real day moves on (the
  /// app left open overnight), Today opens on the new day again.
  LocalDate? _pickedOn;

  void _pick(LocalDate day, LocalDate today) => setState(() {
    _picked = day;
    _pickedOn = today;
  });

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
    final picked = _picked != null && _pickedOn == store.today && plan != null && plan.contains(_picked!)
        ? _picked
        : null;
    final countdown = picked == null ? _countdownFor(store, focus) : null;
    final day = picked ?? focus.day;
    final dayPlan = store.dayPlan(day);
    final canChoose = countdown == null && plan != null && plan.dayCount > 1;

    return SafeArea(
      bottom: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: canChoose ? (details) => _swipe(details, plan, day, store.today) : null,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TodayHeader(
                greeting: greetingFor(store.now),
                subtitle: countdown != null ? 'Nothing planned today' : _subtitle(store, focus, day),
                pill: _pill(store, focus, day, countdown: countdown != null),
                onChooseDay: canChoose ? () => _chooseDay(context, store, plan, day) : null,
              ),
            ),
            if (!store.hasAnything)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyState(
                    art: const TraviCameo(moment: TraviMoment.waiting),
                    title: 'Where are you off to?',
                    message:
                        'Start a trip, then add your flights, hotels, tickets and tables. '
                        'Travary sorts them into days and shows you each one as it comes.',
                    actionLabel: 'New trip',
                    onAction: () => startNewTrip(context),
                    secondaryLabel: 'Or add a booking',
                    onSecondary: () => startAddBooking(context),
                  ),
                ),
              )
            else if (countdown != null)
              SliverToBoxAdapter(
                child: CountdownTripHero(
                  text: countdown.text,
                  postcard: countdown.postcard,
                  onOpen: () => _openTrip(context, countdown.plan),
                  replay: widget.shown,
                  reaction: countdownReactionFor(focus.daysUntilStart!),
                  greet: () => _greet(context, store),
                  notes: [
                    _packingNote(context, countdown.plan, focus.daysUntilStart!),
                    if (context.watch<CountdownWidgetStore?>()?.offers ?? false) _widgetNote(context),
                  ],
                ),
              )
            else if (dayPlan.isEmpty)
              SliverToBoxAdapter(child: _emptyDay(context, store, focus, day))
            else
              ..._daySlivers(context, store, dayPlan),
            const SliverToBoxAdapter(child: SizedBox(height: TodayLayout.bottomGap)),
          ],
        ),
      ),
    );
  }

  /// A day with nothing on it: a free day of the trip, the holiday still
  /// waiting for its dates, or nothing coming up at all.
  Widget _emptyDay(BuildContext context, TravelStore store, TodayFocus focus, LocalDate day) {
    if (focus.plan case final plan?) {
      return EmptyState(
        art: TraviLounge(greet: () => _greet(context, store)),
        title: 'A free day',
        message: 'Nothing booked on ${formatDayLong(day)}.',
        actionLabel: 'Add a booking',
        onAction: () => startAddBooking(context, date: day, tripId: plan.id),
      );
    }
    if (focus.undated case final undated?) return _UndatedHoliday(plan: undated);
    return EmptyState(
      art: const TraviCameo(moment: TraviMoment.waiting),
      title: 'Nothing coming up',
      message: 'Start your next trip, or add a booking and it will appear here.',
      actionLabel: 'New trip',
      onAction: () => startNewTrip(context),
      secondaryLabel: 'Or add a booking',
      onSecondary: () => startAddBooking(context, date: day),
    );
  }

  String _subtitle(TravelStore store, TodayFocus focus, LocalDate day) {
    final plan = focus.plan;
    if (plan == null) {
      if (focus.undated case final undated?) return '${undated.trip.title} · dates to come';
      return store.hasAnything ? 'No trips coming up' : 'Let\'s plan something';
    }
    if (focus.isCountdown && day == plan.start) return '${plan.trip.title} ${relativeDays(focus.daysUntilStart!)}';
    final dayNumber = plan.dayNumber(day);
    final prefix = day == store.today ? '' : '${formatDayShort(day)} · ';
    return dayNumber == null
        ? '$prefix${plan.trip.title}'
        : '${prefix}Day $dayNumber of ${plan.dayCount} · ${plan.trip.title}';
  }

  /// Between trips, the next trip's countdown, when nothing is on today:
  /// on the postcard that suits that trip (its own place, or its look),
  /// else on the neutral one. Null otherwise, and Today stays as it was.
  _Countdown? _countdownFor(TravelStore store, TodayFocus focus) {
    final plan = focus.plan;
    if (!focus.isCountdown || plan == null || !store.dayPlan(store.today).isEmpty) return null;
    final text = countdownTextFor(plan, store.today);
    final postcard = store.countdownPostcardFor(plan) ?? store.neutralCountdownPostcard;
    if (text == null || postcard == null) return null;
    return (plan: plan, text: text, postcard: postcard.image);
  }

  /// Under the countdown: the trip's packing list, how it stands.
  CountdownNote _packingNote(BuildContext context, TripPlan plan, int daysUntilStart) {
    final text = countdownPackingText(plan.trip.packing.values, daysUntilStart: daysUntilStart);
    return CountdownNote(
      title: text.title,
      detail: text.detail,
      semanticLabel: text.semanticLabel,
      onTap: () => openPackingList(context, plan),
    );
  }

  /// Beside the tag, under the packing list, while the widget isn't on the
  /// home screen: opens the sheet that shows how to put it there.
  CountdownNote _widgetNote(BuildContext context) => CountdownNote(
    id: 'countdown-widget-note',
    icon: Icons.add_to_home_screen_rounded,
    title: countdownWidgetNoteTitle,
    detail: countdownWidgetNoteDetail,
    semanticLabel: countdownWidgetNoteLabel,
    onTap: () => showCountdownWidgetSheet(context, from: 'today'),
  );

  /// Whether Travi greets on his own now: at most once a day on this phone.
  Future<bool> _greet(BuildContext context, TravelStore store) =>
      context.read<TraviGreetings?>()?.claim(store.today) ?? Future.value(false);

  void _openTrip(BuildContext context, TripPlan plan) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripScreen(tripId: plan.id)));

  /// Today's forecast when there is one, else the countdown on the first
  /// day of a trip still to come, else the date of the day on screen. The
  /// countdown hero carries its own count, so the pill shows today's date
  /// beside it.
  HeaderPillInfo _pill(TravelStore store, TodayFocus focus, LocalDate day, {required bool countdown}) {
    final weather = widget.weather;
    if (weather != null && (countdown || day == store.today)) {
      return HeaderPillInfo(icon: _weatherIcon(weather.condition), label: formatWeather(weather), iconTinted: false);
    }
    if (focus.isCountdown && !countdown && day == focus.day) {
      return HeaderPillInfo(icon: IconSlot.flight, label: _countdownLabel(focus.daysUntilStart!));
    }
    return HeaderPillInfo(icon: IconSlot.calendar, label: formatDayShort(countdown ? store.today : day));
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

  void _swipe(DragEndDetails details, TripPlan plan, LocalDate day, LocalDate today) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 250) return;
    final next = day.addDays(velocity < 0 ? 1 : -1);
    if (plan.contains(next)) _pick(next, today);
  }

  Future<void> _chooseDay(BuildContext context, TravelStore store, TripPlan plan, LocalDate selected) async {
    // The sheet opens above this screen's trip palette: carry it along.
    final chrome = TravaryChrome.of(context);
    final booked = {
      for (final date in plan.days)
        if (store.dayPlan(date).entries.isNotEmpty) date,
    };
    final picked = await showModalBottomSheet<LocalDate>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => TravaryChrome(
        colors: chrome.colors,
        slots: chrome.slots,
        child: _DayChooser(plan: plan, selected: selected, today: store.today, booked: booked),
      ),
    );
    if (picked != null && mounted) _pick(picked, store.today);
  }

  List<Widget> _daySlivers(BuildContext context, TravelStore store, DayPlan dayPlan) {
    final layout = layOutDay(dayPlan, store.today);
    // Art is chosen in the order the cards are shown (the layout moves the
    // untimed ones after the featured card): neighbours never repeat, and
    // only the day's tagged cards share a printed picture.
    final shown = [
      for (final row in layout.rows)
        if (row is EntryRow) row,
    ];
    final order = [for (final row in shown) row.index, ...layout.earlier];
    final picked = store.artForAll([
      for (final i in order) dayPlan.entries[i].booking,
    ], tagged: (k) => k < shown.length && !shown[k].featured && dayPlan.entries[order[k]].status != EntryStatus.done);
    final art = {for (final (k, i) in order.indexed) i: picked[k]};

    Widget card(int index, {bool featured = false}) {
      final entry = dayPlan.entries[index];
      final size = featured ? CardSize.hero : (entry.status == EntryStatus.done ? CardSize.compact : CardSize.standard);
      // A flight's live state from flight alerts, under its ticket.
      final live = liveFlightLineFor(entry.booking, store.liveFlightFor(entry.booking), store.now);
      return BookingCard(
        text: cardTextForEntry(entry, highlighted: featured).withLive(live),
        art: art[index]!,
        size: size,
        status: entry.status,
        onTap: () => openBooking(context, entry.booking),
        onShowTickets: ticketsAction(context, entry.booking),
      );
    }

    final items = <_Item>[
      for (final row in layout.rows)
        switch (row) {
          EntryRow(:final index, :final featured) => _Item(
            card(index, featured: featured),
            stop: row.rail.stop ? timelineStopFor(dayPlan.entries[index]) : null,
            rail: row.rail,
            featured: featured,
            compact: dayPlan.entries[index].status == EntryStatus.done,
          ),
          OngoingRow(:final booking) => _Item(
            OngoingStrip(
              text: ongoingCardText(booking, dayPlan.date),
              art: store.artFor(booking),
              onTap: () => openBooking(context, booking),
            ),
            rail: row.rail,
          ),
        },
      if (layout.earlier.isNotEmpty) ...[
        _Item(
          SectionLabel(
            'Earlier (${layout.earlier.length})',
            inset: false,
            trailing: TextButton(
              onPressed: () => setState(() => _showEarlier = !_showEarlier),
              child: Text(_showEarlier ? 'Hide' : 'Show'),
            ),
          ),
          compact: true,
        ),
        if (_showEarlier)
          for (final index in layout.earlier) _Item(card(index), compact: true),
      ],
    ];

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
            // The featured ticket's scalloped edge reaches further out.
            final outset = item.featured ? TodayLayout.cardInset - TodayLayout.featuredInset : 0.0;
            if (!layout.hasRail) {
              final inset = TodayLayout.cardInset - outset;
              return Padding(padding: EdgeInsets.fromLTRB(inset, gap, inset, 0), child: item.child);
            }
            return TimeRailRow(
              stop: item.stop,
              lineAbove: item.rail.lineAbove,
              lineBelow: item.rail.lineBelow,
              gap: gap,
              outset: outset,
              child: item.child,
            );
          },
        ),
      ),
    ];
  }
}

/// A holiday started without dates ("Dates not decided"), when nothing else
/// is on or coming: Today keeps it in view, a booking or its dates away
/// from counting down.
class _UndatedHoliday extends StatelessWidget {
  const _UndatedHoliday({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) => EmptyState(
    art: const TraviCameo(moment: TraviMoment.waiting),
    title: plan.trip.title,
    message: 'No dates yet. Add a booking or set the dates, and Today counts down to it.',
    actionLabel: 'Add a booking',
    onAction: () => startAddBooking(context, tripId: plan.id),
    secondaryLabel: 'Set the dates',
    onSecondary: () => editTripDetails(context, plan),
  );
}

/// The next trip, its countdown wording and its postcard.
typedef _Countdown = ({TripPlan plan, CountdownText text, ArtImageRef postcard});

class _Item {
  const _Item(this.child, {this.stop, this.rail = RailMark.none, this.featured = false, this.compact = false});

  final Widget child;

  /// The row's time on the rail, when it's a stop.
  final TimelineStop? stop;
  final RailMark rail;
  final bool featured;

  /// Rows sit closer together than cards.
  final bool compact;
}

/// The trip's calendar, to jump to one of its days; "Back to today" when
/// another day is on screen.
class _DayChooser extends StatelessWidget {
  const _DayChooser({required this.plan, required this.selected, required this.today, required this.booked});

  final TripPlan plan;
  final LocalDate selected;
  final LocalDate today;

  /// Days with something booked.
  final Set<LocalDate> booked;

  @override
  Widget build(BuildContext context) {
    void choose(LocalDate date) => Navigator.of(context).pop(date);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The button sits beside the trip's name when there's room,
              // else under it.
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.start,
                overflowSpacing: TravarySpace.xs,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.trip.title, style: TravaryText.headline, maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(formatDateRange(plan.start!, plan.end!), style: TravaryText.bodySoft),
                    ],
                  ),
                  if (plan.contains(today) && selected != today)
                    TextButton(onPressed: () => choose(today), child: const Text('Back to today')),
                ],
              ),
              const SizedBox(height: TravarySpace.md),
              TripCalendar(
                first: plan.start!,
                last: plan.end!,
                selected: selected,
                today: today,
                booked: booked,
                semanticLabel: (date) => [
                  'Day ${plan.dayNumber(date)} of ${plan.dayCount}',
                  formatDayLong(date),
                  if (date == today) 'today',
                ].join(', '),
                onSelected: choose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
