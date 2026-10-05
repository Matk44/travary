import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/art/art_slots.dart';
import '../../design/cards/booking_card.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/ledger.dart';
import '../../design/widgets/plan_gap_row.dart';
import '../../design/widgets/trip_hero.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../../logic/trip_gaps.dart';
import '../../logic/trip_hero_text.dart';
import '../../logic/trip_plan.dart';
import '../../state/travel_store.dart';
import '../booking/booking_actions.dart';
import 'trip_details_screen.dart';
import 'trip_details_sheet.dart';

/// One trip: its postcard and tag, then its plan as a ledger (every booking
/// by date, tickets one tap away), what it still seems to need (a stay for
/// some nights, the flight home), and who's going. "Add a booking" stays
/// at the bottom; everything about the trip itself (its name and dates,
/// family, card style, deleting it) is under "Trip details".
class TripScreen extends StatelessWidget {
  const TripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final plan = store.plan(tripId);
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This trip has been deleted.')),
      );
    }
    // The trip's own palette and art, wherever Today happens to be.
    return TravaryChrome(
      colors: TripColors.of(store.paletteFor(plan)),
      slots: store.chromeArtFor(plan),
      child: _TripBody(plan: plan),
    );
  }
}

class _TripBody extends StatelessWidget {
  const _TripBody({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final chrome = TravaryChrome.of(context);
    final addDate = plan.contains(store.today) ? store.today : plan.start;
    final gaps = planGaps(plan);

    return LinenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _bar(
          AppBar(
            backgroundColor: Colors.transparent,
            // Dark clock and battery on the light linen.
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            // A real back button (screen readers say "Back"), with where it
            // goes beside it.
            leading: BackButton(color: chrome.colors.ink),
            titleSpacing: 0,
            title: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Text('Trips', style: TravaryText.body.copyWith(color: chrome.colors.ink)),
            ),
            actions: [
              TextButton(
                key: const ValueKey('trip-details'),
                onPressed: () => openTripDetails(context, plan),
                style: TextButton.styleFrom(foregroundColor: chrome.colors.ink, textStyle: TravaryText.body),
                child: const Text('Trip details'),
              ),
              const SizedBox(width: TravarySpace.sm),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.xl),
          children: [
            TripHero(
              text: tripHeroTextFor(plan, store.today),
              // The place's own art first (its landscape postcard, else its
              // portrait one cropped), and only then the neutral postcard.
              postcard:
                  (store.tripPostcardFor(plan) ??
                          (store.countdownPostcardFor(plan) == null ? store.neutralTripPostcard : null))
                      ?.image,
              portrait: (store.countdownPostcardFor(plan) ?? store.neutralCountdownPostcard)?.image,
              tag: chrome.slots.surface(SurfaceSlot.countdownTag),
              variant: plan.id.hashCode,
              onTag: () => editTripDetails(context, plan),
            ),
            const SizedBox(height: TravarySpace.lg),
            _Plan(plan: plan),
            for (final gap in gaps) ...[const SizedBox(height: TravarySpace.md), _GapRow(plan: plan, gap: gap)],
            if (PremiumFeature.familySharing.released || kDebugMode) ...[
              const SizedBox(height: TravarySpace.lg),
              _Travellers(plan: plan),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TravarySpace.gutter,
              TravarySpace.sm,
              TravarySpace.gutter,
              TravarySpace.md,
            ),
            child: TicketButton(
              key: const ValueKey('trip-add-booking'),
              label: 'Add a booking',
              icon: Icons.add_rounded,
              onPressed: () => startAddBooking(context, tripId: plan.id, date: addDate),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Your plan": every booking by date, as ledger rows on one paper panel.
class _Plan extends StatelessWidget {
  const _Plan({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final bookings = plan.bookings;
    final art = store.artForAll(bookings);
    return PaperPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(TravarySpace.lg, TravarySpace.lg, TravarySpace.lg, TravarySpace.sm),
            child: Text('Your plan', style: TravaryText.ledgerHeading),
          ),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(TravarySpace.lg, 0, TravarySpace.lg, TravarySpace.lg),
              child: Text(
                'Add what you\'ve booked and Travary sorts it into days, with your tickets one tap away.',
                style: TravaryText.bodySoft,
              ),
            ),
          for (final (index, booking) in bookings.indexed) ...[
            const PaperDivider(indent: 0),
            BookingCard(
              key: ValueKey('plan-${booking.id}'),
              text: cardTextForLedger(
                booking,
                showDate: index == 0 || bookings[index - 1].startDate != booking.startDate,
              ),
              art: art[index],
              size: CardSize.ledger,
              status: bookingStatus(booking, store.now),
              onTap: () => openBooking(context, booking),
              onShowTickets: booking.hasTickets ? () => showTickets(context, booking) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({required this.plan, required this.gap});

  final TripPlan plan;
  final PlanGap gap;

  @override
  Widget build(BuildContext context) {
    final text = describeGap(gap, plan);
    return PlanGapRow(
      key: ValueKey('gap-${gap.id}'),
      title: text.title,
      when: text.when,
      semanticLabel: text.semanticLabel,
      icon: IconSlot.forKind(gap.bookingKind),
      onAdd: () => addBookingOfKind(context, gap.bookingKind, tripId: plan.id, date: gap.start, endDate: gap.end),
      onNotNeeded: () => _hide(context),
    );
  }

  void _hide(BuildContext context) {
    final store = context.read<TravelStore>();
    final messenger = ScaffoldMessenger.of(context);
    final title = describeGap(gap, plan).title;
    store.hideGap(plan, gap);
    messenger.showSnackBar(
      SnackBar(
        content: Text('$title hidden'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final current = store.plan(plan.id)?.trip ?? plan.trip;
            store.updateTrip(current.copyWith(hiddenGaps: {...current.hiddenGaps}..remove(gap.id)));
          },
        ),
      ),
    );
  }
}

/// Who's going: an initial for each traveller and a way to invite more.
class _Travellers extends StatelessWidget {
  const _Travellers({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final colors = TravaryChrome.of(context).colors;
    final members = plan.trip.memberIds;
    final names = [for (final id in members) store.memberName(plan, id)];
    final shown = names.take(4).toList();
    return PaperPanel(
      child: PaperRow(
        key: const ValueKey('trip-travellers'),
        title: 'Who\'s coming',
        subtitle: members.length <= 1 ? 'Just you so far' : names.join(', '),
        leading: SizedBox(
          width: 34.0 + 18 * (shown.length - 1).clamp(0, 3),
          height: 34,
          child: Stack(
            children: [
              for (final (index, name) in shown.indexed)
                Positioned(
                  left: 18.0 * index,
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == 0 ? colors.ink : colors.paper,
                      border: Border.all(color: index == 0 ? colors.paper : TravaryColors.line, width: 2),
                    ),
                    child: Text(
                      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                      style: TravaryText.label.copyWith(color: index == 0 ? colors.paper : colors.ink),
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RowIcon(IconSlot.invite, size: 20),
            const SizedBox(width: 6),
            Text(plan.trip.isShared ? 'Invite more' : 'Invite', style: TravaryText.label.copyWith(color: colors.ink)),
          ],
        ),
        onTap: () => inviteToTrip(context, plan),
      ),
    );
  }
}

/// The top bar with its text kept to [BarText.maxScale].
PreferredSizeWidget _bar(AppBar bar) => PreferredSize(
  preferredSize: bar.preferredSize,
  child: BarText(child: bar),
);
