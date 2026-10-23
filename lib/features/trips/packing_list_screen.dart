import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/art/art_slots.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/checklist_row.dart';
import '../../design/widgets/ledger.dart';
import '../../design/widgets/readable_width.dart';
import '../../domain/domain.dart';
import '../../logic/formatters.dart';
import '../../logic/packing.dart';
import '../../logic/sharing_pitch.dart';
import '../../logic/trip_plan.dart';
import '../../state/travel_store.dart';
import 'checklist_item_sheet.dart';
import 'trip_details_screen.dart';

void openPackingList(BuildContext context, TripPlan plan) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PackingListScreen(tripId: plan.id)));

/// A trip's packing list: everything to take, shared with everyone on the
/// trip, ticked as it goes in the case. Ideas add in one tap, and an empty
/// list can start from the last trip's.
class PackingListScreen extends StatelessWidget {
  const PackingListScreen({super.key, required this.tripId});

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
      child: _PackingBody(plan: plan),
    );
  }
}

class _PackingBody extends StatefulWidget {
  const _PackingBody({required this.plan});

  final TripPlan plan;

  @override
  State<_PackingBody> createState() => _PackingBodyState();
}

class _PackingBodyState extends State<_PackingBody> {
  /// The order the list was shown in: ticking something leaves it where it
  /// is (struck through) rather than moving every row under the finger.
  /// Packed things sink to the bottom the next time the list opens.
  List<String> _shown = const [];

  List<ChecklistItem> _steady(Iterable<ChecklistItem> all) {
    final fresh = orderedPacking(all);
    final byId = {for (final item in fresh) item.id: item};
    final kept = [
      for (final id in _shown)
        if (byId[id] case final item?) item,
    ];
    final known = {for (final item in kept) item.id};
    final added = [
      for (final item in fresh)
        if (!known.contains(item.id)) item,
    ];
    // New things go after what's still to pack, before what's packed.
    final firstPacked = kept.indexWhere((item) => item.done);
    final at = firstPacked == -1 ? kept.length : firstPacked;
    final steady = [...kept.take(at), ...added, ...kept.skip(at)];
    _shown = [for (final item in steady) item.id];
    return steady;
  }

  TripPlan get plan => widget.plan;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final colors = TravaryChrome.of(context).colors;
    final items = _steady(plan.trip.packing.values);
    final progress = packingProgress(items);
    final ideas = packingIdeas(items);
    final reuse = items.isEmpty ? packingListToReuse(plan, store.plans) : null;
    final start = plan.start;
    final end = plan.end;

    return LinenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: BarText(
            child: AppBar(
              backgroundColor: Colors.transparent,
              systemOverlayStyle: TravarySystemBars.onLight,
              leading: BackButton(color: colors.ink),
              titleSpacing: 0,
              title: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Text(
                  plan.trip.title,
                  style: TravaryText.body.copyWith(color: colors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: readablePadding(
            context,
            const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.xl),
          ),
          children: [
            Text('Packing list', style: TravaryText.display.copyWith(color: colors.ink)),
            if (start != null && end != null) ...[
              const SizedBox(height: TravarySpace.xs),
              Text(formatDayMonthRange(start, end), style: TravaryText.bodySoft),
            ],
            const SizedBox(height: TravarySpace.lg),
            PaperPanel(
              key: const ValueKey('packing-list'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (progress != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TravarySpace.lg,
                        TravarySpace.md,
                        TravarySpace.lg,
                        TravarySpace.sm,
                      ),
                      child: Text(progress, key: const ValueKey('packing-progress'), style: TravaryText.small),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(TravarySpace.lg),
                      child: Text(packingHint, style: TravaryText.bodySoft),
                    ),
                  for (final item in items) ...[
                    const PaperDivider(indent: 0),
                    ChecklistRow(
                      key: ValueKey('packing-${item.id}'),
                      title: item.text,
                      done: item.done,
                      semanticLabel: '${item.text}${item.done ? ', packed' : ''}',
                      onToggle: () => store.toggleChecklistItem(plan, item, list: TripList.packing),
                      onOpen: () => showChecklistItemSheet(context, plan, editing: item, list: TripList.packing),
                    ),
                  ],
                  const PaperDivider(indent: 0),
                  PaperRow(
                    key: const ValueKey('packing-add'),
                    title: 'Add something to pack',
                    titleStyle: TravaryText.label.copyWith(color: colors.ink, fontSize: 16),
                    leading: const RowIcon(IconSlot.countdownBookings),
                    trailing: Icon(Icons.add_rounded, color: colors.ink),
                    onTap: () => showChecklistItemSheet(context, plan, list: TripList.packing),
                  ),
                ],
              ),
            ),
            if (!plan.trip.isShared && (PremiumFeature.familySharing.released || kDebugMode)) ...[
              const SizedBox(height: TravarySpace.md),
              PaperPanel(
                child: PaperRow(
                  key: const ValueKey('packing-together'),
                  title: packTogetherTitle,
                  subtitle: packTogetherDetail,
                  leading: const RowIcon(IconSlot.invite),
                  trailing: Icon(Icons.chevron_right_rounded, color: colors.ink),
                  onTap: () => inviteToTrip(context, plan),
                ),
              ),
            ],
            if (reuse != null) ...[
              const SizedBox(height: TravarySpace.lg),
              OutlinedButton.icon(
                key: const ValueKey('packing-reuse'),
                onPressed: () => _reuse(context, store, reuse),
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                label: Text('Use your list from ${reuse.trip.title}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.ink,
                  side: BorderSide(color: colors.ink.withValues(alpha: 0.4)),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
            if (ideas.isNotEmpty) ...[
              const SizedBox(height: TravarySpace.xl),
              Text('IDEAS', style: TravaryText.eyebrow.copyWith(color: colors.ink)),
              const SizedBox(height: TravarySpace.sm),
              Wrap(
                spacing: TravarySpace.sm,
                runSpacing: TravarySpace.xs,
                children: [
                  for (final idea in ideas)
                    ActionChip(
                      key: ValueKey('packing-idea-$idea'),
                      avatar: Icon(Icons.add_rounded, size: 18, color: colors.ink),
                      label: Text(idea),
                      onPressed: () => store.addChecklistItem(plan, idea, idea: true, list: TripList.packing),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _reuse(BuildContext context, TravelStore store, TripPlan from) async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await store.copyPackingList(from, plan);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added == 1 ? 'Added 1 thing from ${from.trip.title}' : 'Added $added things from ${from.trip.title}',
        ),
      ),
    );
  }
}
