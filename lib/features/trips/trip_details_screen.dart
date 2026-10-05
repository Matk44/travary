import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/sharing_service.dart';
import '../../data/visual_profile_service.dart';
import '../../design/art/art_slots.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/trip_theme_style.dart';
import '../../design/widgets/ledger.dart';
import '../../domain/domain.dart';
import '../../logic/formatters.dart';
import '../../logic/trip_plan.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../premium/premium_gate.dart';
import '../sharing/invite_sheet.dart';
import 'trip_details_sheet.dart';

/// Opens [plan]'s details: its name and dates, who's coming, its card
/// style, and deleting or leaving it.
Future<void> openTripDetails(BuildContext context, TripPlan plan) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TripDetailsScreen(tripId: plan.id)));

/// Invites family to [plan]: a premium feature, and only for trips saved to
/// the cloud.
Future<void> inviteToTrip(BuildContext context, TripPlan plan) async {
  if (!context.read<TravelStore>().sharingAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family sharing works with trips saved to the cloud. This is the demo version.')),
    );
    return;
  }
  final access = await requirePremium(context, PremiumFeature.familySharing, trip: plan, source: 'trip_invite');
  if (access == null || !context.mounted) return;
  await showInviteSheet(context, plan);
}

/// Everything about a trip that isn't a booking, on paper panels: the
/// trip (name, dates), who's coming, the card style, Plus, and at the
/// bottom deleting it (the organiser) or leaving it (everyone else).
class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key, required this.tripId});

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
    return TravaryChrome(
      colors: TripColors.of(store.paletteFor(plan)),
      slots: store.chromeArtFor(plan),
      child: Builder(builder: (context) => _Details(plan: plan)),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final trip = plan.trip;
    final owner = store.isOwner(plan);
    final covered = context.watch<PremiumStore>().forTrip(plan).allowed;
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(TravarySpace.xs, TravarySpace.xl, 0, TravarySpace.sm),
      child: Text(text, style: TravaryText.title),
    );

    return LinenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _bar(
          AppBar(
            backgroundColor: Colors.transparent,
            // Dark clock and battery on the light linen.
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            centerTitle: true,
            title: Text('Trip details', style: TravaryText.formTitle),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            TravarySpace.gutter,
            TravarySpace.sm,
            TravarySpace.gutter,
            TravarySpace.xxl,
          ),
          children: [
            PaperPanel(
              child: PaperRow(
                key: const ValueKey('edit-trip'),
                title: trip.title,
                subtitle: plan.hasDates
                    ? '${formatDateRange(plan.start!, plan.end!)} · ${plan.dayCount} ${plan.dayCount == 1 ? 'day' : 'days'}'
                    : 'No dates yet',
                leading: const RowIcon(IconSlot.calendar),
                trailing: Text('Edit', style: TravaryText.label),
                onTap: () => editTripDetails(context, plan),
              ),
            ),
            if (PremiumFeature.familySharing.released || kDebugMode) ...[
              heading('Who\'s coming'),
              PaperPanel(
                child: Column(
                  children: [
                    for (final memberId in trip.memberIds) ...[
                      _MemberRow(plan: plan, memberId: memberId, canRemove: owner && memberId != trip.ownerId),
                      const PaperDivider(),
                    ],
                    PaperRow(
                      key: const ValueKey('invite-family'),
                      title: trip.isShared ? 'Invite more' : 'Invite the family',
                      subtitle: 'Up to ${Pricing.familySize} people, with the plan and tickets on every phone',
                      leading: const RowIcon(IconSlot.invite),
                      onTap: () => inviteToTrip(context, plan),
                    ),
                  ],
                ),
              ),
            ],
            heading('Card style'),
            PaperPanel(
              child: Column(
                children: [
                  _LookRow(
                    key: const ValueKey('look-automatic'),
                    icon: Icons.auto_awesome_rounded,
                    title: 'Automatic',
                    subtitle: trip.isAutomaticLook
                        ? 'Travary chose ${trip.effectiveTheme.label}'
                        : 'Let Travary choose from your bookings',
                    selected: trip.isAutomaticLook,
                    onTap: () => _useAutomaticLook(context, store, plan),
                  ),
                  for (final theme in ExperienceTheme.values) ...[
                    const PaperDivider(),
                    _LookRow(
                      key: ValueKey('look-${theme.wireName}'),
                      icon: tripThemeStyle(theme).icon,
                      title: theme.label,
                      selected: !trip.isAutomaticLook && trip.theme == theme,
                      onTap: () => store.chooseLook(plan, theme),
                    ),
                  ],
                ],
              ),
            ),
            if (covered) ...[
              heading('Travary Plus'),
              PaperPanel(
                child: PaperRow(
                  title: 'Plus covers this trip',
                  subtitle: 'Smart Import, family sharing and ticket backup for everyone on it',
                  leading: const Icon(Icons.workspace_premium_rounded, color: TravaryColors.mustard),
                  trailing: const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: TravarySpace.xl),
            Center(
              child: TextButton(
                onPressed: () => owner ? _delete(context, store, plan) : _leave(context, store, plan),
                style: TextButton.styleFrom(foregroundColor: TravaryColors.coral, textStyle: TravaryText.label),
                child: Text(owner ? 'Delete trip' : 'Leave trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hands the look back to Travary. The trip turns automatic at once; a
  /// failed classification only means the current look stays for now.
  Future<void> _useAutomaticLook(BuildContext context, TravelStore store, TripPlan plan) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.useAutomaticLook(plan);
    } on VisualProfileException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _leave(BuildContext context, TravelStore store, TripPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave ${plan.trip.title}?'),
        content: const Text('It will disappear from your phone. The others keep it, and can invite you back.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await store.leaveTrip(plan);
      if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on SharingException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
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
    Navigator.of(context).popUntil((route) => route.isFirst);
    await store.deleteTrip(plan);
  }
}

/// A traveller on the trip: their initial, name, "Organiser", and for the
/// organiser a way to remove them.
class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.plan, required this.memberId, required this.canRemove});

  final TripPlan plan;
  final String memberId;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final colors = TravaryChrome.of(context).colors;
    final name = store.memberName(plan, memberId);
    final you = memberId == store.userId;
    return PaperRow(
      title: name,
      subtitle: memberId == plan.trip.ownerId ? 'Organiser' : null,
      titleStyle: TravaryText.label.copyWith(fontSize: 16),
      leading: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: you ? colors.ink : colors.paper,
          border: Border.all(color: TravaryColors.line),
        ),
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: TravaryText.label.copyWith(color: you ? colors.paper : colors.ink),
        ),
      ),
      trailing: canRemove
          ? IconButton(
              tooltip: 'Remove from trip',
              icon: const Icon(Icons.person_remove_outlined, size: 20),
              onPressed: () => _remove(context, store, name),
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _remove(BuildContext context, TravelStore store, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $name?'),
        content: Text('$name will no longer see ${plan.trip.title} or its tickets.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.removeMember(plan, memberId);
    } on SharingException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

/// A card style: its icon and name, ticked when it's the trip's.
class _LookRow extends StatelessWidget {
  const _LookRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    return Semantics(
      selected: selected,
      child: PaperRow(
        title: title,
        subtitle: subtitle,
        titleStyle: TravaryText.label.copyWith(fontSize: 16),
        leading: Icon(icon, color: colors.ink, size: 22),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: colors.ink)
            : const Icon(Icons.circle_outlined, color: TravaryColors.line),
        onTap: onTap,
      ),
    );
  }
}

/// The top bar with its text kept to [BarText.maxScale].
PreferredSizeWidget _bar(AppBar bar) => PreferredSize(
  preferredSize: bar.preferredSize,
  child: BarText(child: bar),
);
