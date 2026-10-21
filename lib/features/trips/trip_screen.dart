import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/art/art_slots.dart';
import '../../design/cards/booking_card.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/checklist_row.dart';
import '../../design/widgets/ledger.dart';
import '../../design/widgets/plan_gap_row.dart';
import '../../design/widgets/pass_badge.dart';
import '../../design/widgets/travi_cameo.dart';
import '../../design/widgets/trip_hero.dart';
import '../../domain/domain.dart';
import '../../logic/card_text.dart';
import '../../logic/checklist.dart';
import '../../logic/day_plan.dart';
import '../../logic/packing.dart';
import '../../logic/price_text.dart';
import '../../logic/sharing_pitch.dart';
import '../../logic/travi_cameos.dart';
import '../../logic/trip_gaps.dart';
import '../../logic/trip_hero_text.dart';
import '../../logic/trip_plan.dart';
import '../../state/reminders_store.dart';
import '../../state/travel_store.dart';
import '../../state/premium_store.dart';
import '../ai/trip_looks_offer.dart';
import '../reminders/reminder_offer.dart';
import '../booking/booking_actions.dart';
import '../premium/premium_gate.dart';
import 'checklist_item_sheet.dart';
import 'packing_list_screen.dart';
import 'trip_details_screen.dart';
import 'trip_details_sheet.dart';

/// One trip: its postcard and tag, then its plan as a ledger (every booking
/// by date, tickets one tap away), what it still seems to need (a stay for
/// some nights, the flight home), what to sort before going (its shared
/// checklist), and who's going. "Add a booking" stays
/// at the bottom; everything about the trip itself (its name and dates,
/// family, card style, deleting it) is under "Trip details".
class TripScreen extends StatelessWidget {
  const TripScreen({super.key, required this.tripId, this.celebrate = false});

  final String tripId;

  /// Just created: Travi pops up from behind its plan, cheering, and ducks.
  final bool celebrate;

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
      child: _TripBody(plan: plan, celebrate: celebrate),
    );
  }
}

class _TripBody extends StatelessWidget {
  const _TripBody({required this.plan, required this.celebrate});

  final TripPlan plan;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final chrome = TravaryChrome.of(context);
    final addDate = plan.contains(store.today) ? store.today : plan.start;
    final gaps = planGaps(plan);
    // One offer at a time: the trip's look first, then reminders.
    final offersLooks = store.offersLooksFor(plan);
    final offersReminders = !offersLooks && (context.watch<RemindersStore?>()?.offersFor(plan) ?? false);

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
              badge: switch (context.watch<PremiumStore?>()?.policy.purchasedPassFor(plan)) {
                final kind? => PassBadge(kind: kind),
                null => null,
              },
            ),
            const SizedBox(height: TravarySpace.lg),
            if (celebrate)
              // Behind the plan, which covers him below its top edge.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    left: TraviCameoLayout.planLeft,
                    top: TraviCameoLayout.planSink - TraviCameoLayout.peekSize,
                    width: TraviCameoLayout.peekSize,
                    height: TraviCameoLayout.peekSize,
                    child: TraviPopUp(key: ValueKey('trip-travi'), peek: TraviPeek.cheer, duck: true),
                  ),
                  _Plan(plan: plan),
                ],
              )
            else
              _Plan(plan: plan),
            for (final gap in gaps) ...[const SizedBox(height: TravarySpace.md), _GapRow(plan: plan, gap: gap)],
            if (offersLooks) ...[const SizedBox(height: TravarySpace.lg), const TripLooksOffer()],
            if (offersReminders) ...[const SizedBox(height: TravarySpace.lg), const ReminderOffer()],
            if (showsChecklist(plan, store.today)) ...[const SizedBox(height: TravarySpace.lg), _Checklist(plan: plan)],
            if (showsPacking(plan, store.today)) ...[const SizedBox(height: TravarySpace.lg), _Packing(plan: plan)],
            if (PremiumFeature.familySharing.released || kDebugMode) ...[
              const SizedBox(height: TravarySpace.lg),
              _Travellers(plan: plan),
            ],
            if (_HolidayPassOffer.offeredFor(context, plan)) ...[
              const SizedBox(height: TravarySpace.lg),
              _HolidayPassOffer(plan: plan),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (context.watch<PremiumStore?>() case final premium?)
                  if (premium.policy.bookingCountShown(plan) case final used?)
                    _BookingCount(plan: plan, used: used, cap: premium.limits.bookingsPerHoliday),
                TicketButton(
                  key: const ValueKey('trip-add-booking'),
                  label: 'Add a booking',
                  icon: Icons.add_rounded,
                  onPressed: () => startAddBooking(context, tripId: plan.id, date: addDate, fillGaps: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A free holiday's bookings counted once few are left before it starts
/// ("9 of 12 free bookings used"), over "Add a booking". Tapping it opens
/// the pass desk for this holiday.
class _BookingCount extends StatelessWidget {
  const _BookingCount({required this.plan, required this.used, required this.cap});

  final TripPlan plan;
  final int used;
  final int cap;

  @override
  Widget build(BuildContext context) {
    final ink = TravaryChrome.of(context).colors.ink;
    return Semantics(
      button: true,
      child: InkWell(
        key: const ValueKey('trip-booking-count'),
        borderRadius: BorderRadius.circular(TravaryRadius.small),
        onTap: () =>
            showPaywall(context, feature: PremiumFeature.everyBooking, tripId: plan.id, source: 'booking_count'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TravarySpace.sm, vertical: TravarySpace.xs),
              child: Text(
                bookingCountText(used, cap),
                textAlign: TextAlign.center,
                style: TravaryText.small.copyWith(color: ink),
              ),
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

/// "Before you go": the trip's shared to-dos, open ones first, ticked in
/// place, each opening to edit; and a way to add another.
class _Checklist extends StatelessWidget {
  const _Checklist({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final colors = TravaryChrome.of(context).colors;
    final items = orderedChecklist(plan.trip.checklist.values);
    final progress = checklistProgress(items);
    return PaperPanel(
      key: const ValueKey('trip-checklist'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(TravarySpace.lg, TravarySpace.lg, TravarySpace.lg, TravarySpace.sm),
            // The count sits beside the heading, or under it when there's no
            // room (a small phone, large text).
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: TravarySpace.md,
              children: [
                Text(checklistHeading(plan, store.today), style: TravaryText.ledgerHeading),
                if (progress != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(progress, style: TravaryText.small),
                  ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(TravarySpace.lg, 0, TravarySpace.lg, TravarySpace.md),
              child: Text(checklistHintFor(plan, store.today), style: TravaryText.bodySoft),
            ),
          for (final item in items) ...[
            const PaperDivider(indent: 0),
            Builder(
              builder: (context) {
                final text = checklistItemText(item, store.today);
                return ChecklistRow(
                  key: ValueKey('checklist-${item.id}'),
                  title: text.title,
                  due: text.due,
                  overdue: text.overdue,
                  done: item.done,
                  semanticLabel: text.semanticLabel,
                  onToggle: () => store.toggleChecklistItem(plan, item),
                  onOpen: () => showChecklistItemSheet(context, plan, editing: item),
                );
              },
            ),
          ],
          const PaperDivider(indent: 0),
          PaperRow(
            key: const ValueKey('checklist-add'),
            title: 'Add something to do',
            titleStyle: TravaryText.label.copyWith(color: colors.ink, fontSize: 16),
            leading: const RowIcon(IconSlot.checklist),
            trailing: Icon(Icons.add_rounded, color: colors.ink),
            onTap: () => showChecklistItemSheet(context, plan),
          ),
        ],
      ),
    );
  }
}

/// The packing list, folded to one row: how it stands, opening the list.
class _Packing extends StatelessWidget {
  const _Packing({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final progress = packingProgress(plan.trip.packing.values);
    return PaperPanel(
      child: PaperRow(
        key: const ValueKey('trip-packing'),
        title: 'Packing list',
        subtitle: progress ?? 'Everything to take, ticked off as it goes in',
        leading: const RowIcon(IconSlot.countdownBookings),
        trailing: Icon(Icons.chevron_right_rounded, color: colors.ink),
        onTap: () => openPackingList(context, plan),
      ),
    );
  }
}

/// This holiday's own Holiday Pass, to buy whenever the traveller likes,
/// not only when a limit is reached: shown while it can take one (dated,
/// not over, at most 30 days, nothing covering it yet). Opens the pass desk
/// for this holiday.
class _HolidayPassOffer extends StatelessWidget {
  const _HolidayPassOffer({required this.plan});

  final TripPlan plan;

  static bool offeredFor(BuildContext context, TripPlan plan) {
    final policy = context.watch<PremiumStore?>()?.policy;
    return policy != null && !policy.forTrip(plan).allowed && policy.canBuyTripPassFor(plan);
  }

  @override
  Widget build(BuildContext context) {
    final offer = context.watch<PremiumStore>().offer(OfferKind.tripPass);
    final text = holidayPassRowText(plan.trip.title, price: offer == null ? null : priceOf(offer));
    return PaperPanel(
      child: PaperRow(
        key: const ValueKey('trip-holiday-pass'),
        title: text.title,
        subtitle: text.subtitle,
        titleStyle: TravaryText.label.copyWith(fontSize: 16),
        leading: const PassBadge(kind: OfferKind.tripPass, width: 64),
        onTap: () => showPaywall(context, tripId: plan.id, source: 'trip_page'),
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
        subtitle: travellersLine(plan, names),
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
