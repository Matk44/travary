import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/cards/booking_card.dart';
import '../../design/kind_style.dart';
import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../../state/travel_store.dart';
import '../booking/booking_actions.dart';

/// Find any booking in two taps: search, or filter by kind. Upcoming first,
/// then past, so last year's hotel is as easy to find as tomorrow's flight.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _search = TextEditingController();
  BookingKind? _kind;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final today = store.today;
    final results = store.search(_search.text, kind: _kind);
    final upcoming = results.where((b) => !b.lastDate.isBefore(today)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final past = results.where((b) => b.lastDate.isBefore(today)).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

    Widget section(String label, List<Booking> bookings, EntryStatus status) => SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionLabel(label)),
        SliverList.builder(
          itemCount: bookings.length,
          itemBuilder: (context, i) {
            final booking = bookings[i];
            return Padding(
              padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.sm),
              child: BookingCard(
                text: cardTextForList(booking),
                art: store.artFor(booking),
                size: CardSize.compact,
                status: status,
                onTap: () => openBooking(context, booking),
                onShowTickets: booking.hasTickets ? () => showTickets(context, booking) : null,
              ),
            );
          },
        ),
      ],
    );

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, TravarySpace.lg, TravarySpace.gutter, TravarySpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wallet', style: TravaryText.display),
                  const SizedBox(height: TravarySpace.xs),
                  Text('Every booking and ticket, even offline.', style: TravaryText.bodySoft),
                  const SizedBox(height: TravarySpace.lg),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search hotels, references, places…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(_search.clear),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
                children: [
                  _filter('All', null),
                  for (final kind in BookingKind.values) _filter(kind.spec.label, kind),
                ],
              ),
            ),
          ),
          if (results.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: store.bookings.isEmpty ? 'Nothing here yet' : 'No matches',
                  message: store.bookings.isEmpty
                      ? 'Bookings you add appear here, with their tickets.'
                      : 'Try another word or filter.',
                ),
              ),
            ),
          if (upcoming.isNotEmpty) section('Coming up', upcoming, EntryStatus.upcoming),
          if (past.isNotEmpty) section('Past', past, EntryStatus.done),
          const SliverToBoxAdapter(child: SizedBox(height: TravarySpace.xxl)),
        ],
      ),
    );
  }

  Widget _filter(String label, BookingKind? kind) {
    return Padding(
      padding: const EdgeInsets.only(right: TravarySpace.sm),
      child: ChoiceChip(
        avatar: kind == null ? null : Icon(KindStyle.of(kind).icon, size: 16),
        label: Text(label),
        selected: _kind == kind,
        onSelected: (_) => setState(() => _kind = kind),
      ),
    );
  }
}
