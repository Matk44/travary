import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/art/art_slots.dart';
import '../../design/art/card_shells.dart';
import '../../design/cards/booking_card.dart';
import '../../design/cards/ongoing_strip.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/trip_theme_style.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../../state/travel_store.dart';

/// Design tool: every kind of card in every size and state on one page, in
/// any trip look (with any installed experience packs for it). Use it to
/// judge new card styles and artwork at a glance.
class CardGalleryScreen extends StatefulWidget {
  const CardGalleryScreen({super.key});

  @override
  State<CardGalleryScreen> createState() => _CardGalleryScreenState();
}

class _CardGalleryScreenState extends State<CardGalleryScreen> {
  ExperienceTheme _theme = ExperienceTheme.classicTravel;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final samples = _samples(store.bookings);

    final lookContext = store.artContextForLook(_theme);
    return TravaryChrome(
      colors: TripColors.of(store.art.catalog.palette(context: lookContext)),
      slots: ArtSlots(store.art.catalog, lookContext),
      child: Scaffold(
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
                  for (final theme in ExperienceTheme.values)
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
      ),
    );
  }

  List<Widget> _kindSection(TravelStore store, Booking booking) {
    final art = store.art.resolve(booking, store.artContextForLook(_theme));
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
    final picture = art.key ?? 'placeholder';
    final subject = art.subject ?? 'no subject';
    String shellName(ShellArt? shell) =>
        shell == null ? 'no shell' : '${shell.art.fileKey}${shell.standInFor == null ? '' : ' (stand-in)'}';
    final shells = art.shells;

    return [
      SectionLabel('${booking.kind.spec.label} · $subject · $picture'),
      Padding(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.sm),
        child: Text(
          'Shells: ${shellName(shells.featured)} · ${shellName(shells.room)} · ${shellName(shells.reservation)}',
          style: TravaryText.small,
        ),
      ),
      padded(
        BookingCard(
          text: cardTextForEntry(entry(EntryStatus.upcoming), highlighted: true),
          art: art,
          size: CardSize.hero,
          onShowTickets: () {},
        ),
      ),
      padded(BookingCard(text: cardTextForEntry(entry(EntryStatus.upcoming)), art: art)),
      padded(
        BookingCard(
          text: cardTextForEntry(entry(EntryStatus.upcoming)),
          art: art,
          size: CardSize.compact,
          onShowTickets: () {},
        ),
      ),
      padded(
        BookingCard(
          text: cardTextForEntry(entry(EntryStatus.done)),
          art: art,
          size: CardSize.compact,
          status: EntryStatus.done,
        ),
      ),
      // Only bookings with a day in the middle ever show an ongoing strip.
      if (booking.startDate.addDays(1).isBefore(booking.lastDate))
        padded(OngoingStrip(text: ongoingCardText(booking, booking.startDate.addDays(1)), art: art)),
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
