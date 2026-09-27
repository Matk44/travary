import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/cards/booking_card.dart';
import '../../design/cards/ongoing_strip.dart';
import '../../design/tokens.dart';
import '../../design/trip_theme_style.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../../state/travel_store.dart';

/// Design tool: every kind of card in every size and state on one page, in
/// any trip theme. Use it to judge new card styles and artwork at a glance.
class CardGalleryScreen extends StatefulWidget {
  const CardGalleryScreen({super.key});

  @override
  State<CardGalleryScreen> createState() => _CardGalleryScreenState();
}

class _CardGalleryScreenState extends State<CardGalleryScreen> {
  TripTheme _theme = TripTheme.classic;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final samples = _samples(store.bookings);

    return Scaffold(
      appBar: AppBar(title: const Text('Card gallery')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: TravarySpace.xxl),
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
              children: [
                for (final theme in TripTheme.values)
                  Padding(
                    padding: const EdgeInsets.only(right: TravarySpace.sm),
                    child: ChoiceChip(
                      avatar: Icon(tripThemeStyle(theme).icon, size: 16),
                      label: Text(theme.label),
                      selected: _theme == theme,
                      onSelected: (_) => setState(() => _theme = theme),
                    ),
                  ),
              ],
            ),
          ),
          for (final booking in samples) ..._kindSection(store, booking),
        ],
      ),
    );
  }

  List<Widget> _kindSection(TravelStore store, Booking booking) {
    final art = store.art.resolve(booking, _theme);
    DayEntry entry(EntryStatus status, {EntryRole role = EntryRole.single}) => DayEntry(
      booking: booking,
      role: role,
      time: role == EntryRole.end ? booking.endTime : booking.startTime,
      status: status,
    );
    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.md),
      child: child,
    );
    final hasArt = art.asset != null ? art.asset!.path.split('/').last : 'placeholder';

    return [
      SectionLabel('${booking.kind.spec.label} · $hasArt'),
      padded(BookingCard(
        text: cardTextForEntry(entry(EntryStatus.upcoming), highlighted: true),
        art: art,
        size: CardSize.hero,
        onShowTickets: () {},
      )),
      padded(BookingCard(text: cardTextForEntry(entry(EntryStatus.upcoming)), art: art)),
      padded(BookingCard(
        text: cardTextForEntry(entry(EntryStatus.upcoming)),
        art: art,
        size: CardSize.compact,
        onShowTickets: () {},
      )),
      padded(BookingCard(
        text: cardTextForEntry(entry(EntryStatus.done)),
        art: art,
        size: CardSize.compact,
        status: EntryStatus.done,
      )),
      // Only bookings with a day in the middle ever show an ongoing strip.
      if (booking.startDate.addDays(1).isBefore(booking.lastDate))
        padded(Builder(builder: (context) {
          final text = ongoingText(booking, booking.startDate.addDays(1));
          return OngoingStrip(title: text.title, subtitle: text.subtitle, art: art);
        })),
    ];
  }

  /// One booking per kind: from the current data where possible, so the
  /// gallery shows real wording.
  List<Booking> _samples(List<Booking> bookings) {
    final byKind = <BookingKind, Booking>{};
    for (final booking in bookings) {
      final current = byKind[booking.kind];
      // Prefer richer examples: multi-day, then with details.
      if (current == null ||
          (booking.spansDays && !current.spansDays) ||
          (booking.details.length > current.details.length && booking.spansDays == current.spansDays)) {
        byKind[booking.kind] = booking;
      }
    }
    final stamp = DateTime(2026, 1, 1);
    return [
      for (final kind in BookingKind.values)
        byKind[kind] ??
            Booking(
              id: 'gallery-${kind.name}',
              tripId: '',
              kind: kind,
              title: kind.spec.titleHint,
              startDate: LocalDate.fromDateTime(stamp),
              startTime: const ClockTime(10, 0),
              createdAt: stamp,
              updatedAt: stamp,
            ),
    ];
  }
}
