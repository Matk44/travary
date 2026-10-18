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
import '../../logic/packing.dart';
import '../../logic/day_layout.dart';
import '../../logic/day_plan.dart';
import '../../logic/flight_status_text.dart';
import '../../logic/formatters.dart';
import '../../logic/today_sheet.dart';
import '../../logic/travi_cameos.dart';
import '../../logic/trip_plan.dart';
import '../../state/travel_store.dart';
import '../../state/travi_greetings.dart';
import '../booking/booking_actions.dart';
import '../trips/packing_list_screen.dart';
import '../trips/trip_details_sheet.dart';
import '../trips/trip_screen.dart';

/// Opens on what matters right now: today's plan during a trip, or the next
/// trip's countdown before it starts.
///
/// Today is one sheet of pages laid side by side ([todaySheetFor]) that
/// follows the finger: drag left for the next day, right for the one
/// before, and let go to settle on the nearest with a little bobble
/// ([TodayLayout.daySettle]). It runs from the first day of the trip you're
/// on through every trip to come, each one's countdown between the last day
/// of the trip before it and its own first day, and ends on where to next.
/// A day picked in the trip's calendar (tap the date pill or the day line,
/// "Day 3 of 7 · Orlando") slides in like a tab ([NavLayout.switchCurve]).
///
/// Under the greeting and day, each day's cards run down the time rail:
/// the timed ones in time order, each with its time beside it, the
/// featured "next up" ticket in its place and the hotel you're staying at
/// after it ([layOutDay]).
///
/// Between trips, a trip still to come counts down on the postcard that
/// suits it ([CountdownTripHero]); without one, the sheet goes straight to
/// its first day.
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
  /// The page the traveller moved the sheet to (a swipe, or a day picked in
  /// the calendar); null keeps to the one Today opens on.
  TodayPage? _moved;

  /// The date when [_moved] was chosen. Once the real day moves on (the
  /// app left open overnight), Today opens on the new day again.
  LocalDate? _movedOn;

  /// The sheet's position: made when the sheet appears, on the page it
  /// opens on.
  PageController? _pages;

  /// The sheet as last built.
  TodaySheet _sheet = TodaySheet.empty;

  /// Finished items stay folded away so "next up" is always near the top.
  bool _showEarlier = false;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    if (store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final focus = store.focus;
    // Every trip still to come counts down before its first day, whatever is
    // on today: it opens the sheet when no trip is on today, and follows the
    // last day of the trip before it otherwise.
    final sheet = _sheet = todaySheetFor(
      store.plans,
      focus,
      store.today,
      countsDown: (plan) => _countdownFor(store, plan) != null,
    );
    if (sheet.isEmpty) {
      _dropSheet();
      return SafeArea(bottom: false, child: _nothingOn(context, store, focus));
    }

    final moved = _movedOn == store.today ? _moved : null;
    final index = (moved == null ? null : sheet.indexOf(moved)) ?? sheet.opening;
    final pages = _pages ??= PageController(initialPage: index, keepPage: false);
    _keepOn(pages, index);
    return SafeArea(
      bottom: false,
      // The pages are clear: the linen behind stays put, so the days slide
      // over it as one sheet, with no edge between them.
      child: PageView.builder(
        controller: pages,
        // With reduced motion a page let go settles without the bobble.
        physics: MediaQuery.disableAnimationsOf(context) ? null : const _DaySheetPhysics(),
        onPageChanged: (i) {
          _moved = _sheet.pages[i];
          _movedOn = store.today;
        },
        itemCount: sheet.pages.length,
        itemBuilder: (context, i) {
          final page = sheet.pages[i];
          return KeyedSubtree(key: ValueKey(page), child: _page(context, store, page));
        },
      ),
    );
  }

  /// When the page on screen moves along the sheet without a swipe (a
  /// trip's dates change, or a new day begins), the sheet goes to it once
  /// the frame is drawn, never under the traveller's finger.
  void _keepOn(PageController pages, int index) {
    bool away() => pages.hasClients && pages.page?.round() != index && !pages.position.isScrollingNotifier.value;
    if (!away()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pages == pages && away()) pages.jumpToPage(index);
    });
  }

  /// Nothing on or coming: the sheet goes, and the next one starts afresh
  /// on its own opening page.
  void _dropSheet() {
    final pages = _pages;
    if (pages == null) return;
    _pages = null;
    _moved = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => pages.dispose());
  }

  /// A day picked in the calendar slides in from the day beside it with
  /// the tabs' bobble, however far away it is (never a blur of days), or
  /// is there at once with reduced motion.
  void _goTo(TodayPage page) {
    final pages = _pages;
    final index = _sheet.indexOf(page);
    if (pages == null || !pages.hasClients || index == null) return;
    final from = pages.page?.round() ?? index;
    if (index == from) return;
    if (MediaQuery.disableAnimationsOf(context)) return pages.jumpToPage(index);
    if ((index - from).abs() > 1) pages.jumpToPage(index > from ? index - 1 : index + 1);
    pages.animateToPage(index, duration: NavLayout.switchDuration, curve: NavLayout.switchCurve);
  }

  /// One page of the sheet: its own header over its own cards, so each day
  /// scrolls on its own and slides as a whole.
  Widget _page(BuildContext context, TravelStore store, TodayPage page) {
    // The greeting belongs to today's page only: another day is headed by
    // its name, and the pages that aren't a day (a trip's countdown after
    // another trip, where to next) head themselves.
    final today = store.today;
    final greeting = greetingFor(store.now);
    final (header, content) = switch (page) {
      TripDayPage(:final plan, :final day) => (
        TodayHeader(
          title: day == today ? greeting : dayHeading(day, today),
          titleLike: day == today ? null : greeting,
          subtitle: _subtitle(store, plan, day),
          pill: _dayPill(store, plan, day),
          onChooseDay: plan.dayCount > 1 ? () => _chooseDay(context, store, plan, day) : null,
        ),
        _day(context, store, plan, day),
      ),
      CountdownPage(:final plan, :final after) => (
        TodayHeader(
          // Between trips the page is today. Further on it isn't.
          title: after == null ? greeting : null,
          subtitle: after == null ? 'Nothing planned today' : 'After ${after.trip.title}',
          // Between trips the page is today: its forecast or date (the tag
          // has the count). Further on, the tag says it all.
          pill: after == null ? _todayPill(store) : null,
        ),
        [SliverToBoxAdapter(child: _countdown(context, store, plan))],
      ),
      EndPage(:final after) => (
        TodayHeader(subtitle: 'After ${after.trip.title}'),
        [SliverToBoxAdapter(child: _whereNext(context))],
      ),
    };
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: header),
        ...content,
        const SliverToBoxAdapter(child: SizedBox(height: TodayLayout.bottomGap)),
      ],
    );
  }

  /// Nothing on or coming: no trips at all yet, a holiday still waiting for
  /// its dates, or nothing coming up.
  Widget _nothingOn(BuildContext context, TravelStore store, TodayFocus focus) {
    final undated = focus.undated;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TodayHeader(
            title: greetingFor(store.now),
            subtitle: undated != null
                ? '${undated.trip.title} · dates to come'
                : (store.hasAnything ? 'No trips coming up' : 'Let\'s plan something'),
            pill: _todayPill(store),
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
        else if (undated != null)
          SliverToBoxAdapter(child: _UndatedHoliday(plan: undated))
        else
          SliverToBoxAdapter(
            child: EmptyState(
              art: const TraviCameo(moment: TraviMoment.waiting),
              title: 'Nothing coming up',
              message: 'Start your next trip, or add a booking and it will appear here.',
              actionLabel: 'New trip',
              onAction: () => startNewTrip(context),
              secondaryLabel: 'Or add a booking',
              onSecondary: () => startAddBooking(context, date: store.today),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: TodayLayout.bottomGap)),
      ],
    );
  }

  /// A day of a trip: its cards, or a free day.
  List<Widget> _day(BuildContext context, TravelStore store, TripPlan plan, LocalDate day) {
    final dayPlan = store.dayPlan(day);
    if (!dayPlan.isEmpty) return _daySlivers(context, store, dayPlan);
    return [
      SliverToBoxAdapter(
        child: EmptyState(
          art: TraviLounge(greet: () => _greet(context, store)),
          title: 'A free day',
          message: 'Nothing booked on ${formatDayLong(day)}.',
          actionLabel: 'Add a booking',
          onAction: () => startAddBooking(context, date: day, tripId: plan.id),
        ),
      ),
    ];
  }

  /// After the last trip planned, at the end of the sheet: Travi with his
  /// folio open, ready for the next one.
  Widget _whereNext(BuildContext context) => EmptyState(
    art: const TraviCameo(moment: TraviMoment.waiting),
    title: 'Where to next?',
    message: 'That\'s everything planned for now. Start your next trip, or add a booking and it will appear here.',
    actionLabel: 'New trip',
    onAction: () => startNewTrip(context),
    secondaryLabel: 'Or add a booking',
    onSecondary: () => startAddBooking(context),
  );

  /// "Day 3 of 7 · Orlando", with the date in front on any day but today,
  /// and "Lake District in 58 days" on the first day of a trip to come.
  String _subtitle(TravelStore store, TripPlan plan, LocalDate day) {
    final today = store.today;
    if (day == plan.start && day.isAfter(today)) return '${plan.trip.title} ${relativeDays(today.daysUntil(day))}';
    final dayNumber = plan.dayNumber(day);
    final prefix = day == today ? '' : '${formatDayShort(day)} · ';
    return dayNumber == null
        ? '$prefix${plan.trip.title}'
        : '${prefix}Day $dayNumber of ${plan.dayCount} · ${plan.trip.title}';
  }

  /// A trip still to come, counting down: its wording, on the postcard that
  /// suits it (its own place, or its look), else on the neutral one. Null
  /// without either, and the sheet goes straight to its first day.
  _Countdown? _countdownFor(TravelStore store, TripPlan plan) {
    final text = countdownTextFor(plan, store.today);
    final postcard = store.countdownPostcardFor(plan) ?? store.neutralCountdownPostcard;
    if (text == null || postcard == null) return null;
    return (plan: plan, text: text, postcard: postcard.image);
  }

  Widget _countdown(BuildContext context, TravelStore store, TripPlan plan) {
    final countdown = _countdownFor(store, plan);
    if (countdown == null) return const SizedBox.shrink();
    final days = store.today.daysUntil(plan.start!);
    return CountdownTripHero(
      text: countdown.text,
      postcard: countdown.postcard,
      onOpen: () => _openTrip(context, plan),
      replay: widget.shown,
      reaction: countdownReactionFor(days),
      greet: () => _greet(context, store),
      note: _packingNote(context, plan, days),
    );
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

  /// Whether Travi greets on his own now: at most once a day on this phone.
  Future<bool> _greet(BuildContext context, TravelStore store) =>
      context.read<TraviGreetings?>()?.claim(store.today) ?? Future.value(false);

  void _openTrip(BuildContext context, TripPlan plan) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripScreen(tripId: plan.id)));

  /// A day's pill: today's forecast when there is one, the countdown on the
  /// first day of a trip still to come, else the date of the day.
  HeaderPillInfo _dayPill(TravelStore store, TripPlan plan, LocalDate day) {
    if (day == store.today) {
      if (_forecast() case final forecast?) return forecast;
    }
    if (day == plan.start && day.isAfter(store.today)) {
      return HeaderPillInfo(icon: IconSlot.flight, label: _countdownLabel(store.today.daysUntil(day)));
    }
    return HeaderPillInfo(icon: IconSlot.calendar, label: formatDayShort(day));
  }

  /// Today's forecast, else today's date.
  HeaderPillInfo _todayPill(TravelStore store) =>
      _forecast() ?? HeaderPillInfo(icon: IconSlot.calendar, label: formatDayShort(store.today));

  HeaderPillInfo? _forecast() {
    final weather = widget.weather;
    if (weather == null) return null;
    return HeaderPillInfo(icon: _weatherIcon(weather.condition), label: formatWeather(weather), iconTinted: false);
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
    if (picked != null && mounted) _goTo(TripDayPage(plan, picked));
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

/// A trip to come, its countdown wording and its postcard.
typedef _Countdown = ({TripPlan plan, CountdownText text, ArtImageRef postcard});

/// The day sheet keeps the platform's own drag and edges (past the first
/// or last page it stretches, or on iOS gives and springs back), and
/// settles a page let go on [TodayLayout.daySettle].
class _DaySheetPhysics extends ScrollPhysics {
  const _DaySheetPhysics({super.parent});

  @override
  _DaySheetPhysics applyTo(ScrollPhysics? ancestor) => _DaySheetPhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => TodayLayout.daySettle;
}

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
