import '../domain/domain.dart';
import 'checklist.dart';
import 'trip_plan.dart';

/// The packing list: things to take on a trip, shared with everyone on it
/// and ticked once they're in the case (`Trip.packing`). Kept simple on
/// purpose: words and a tick, no dates, people or categories.

/// What's still to pack first, then what's packed, each in the order added.
List<ChecklistItem> orderedPacking(Iterable<ChecklistItem> items) => orderedChecklist(items);

/// Beside the heading: "5 of 12 packed". Null for an empty list.
String? packingProgress(Iterable<ChecklistItem> items) {
  final all = items.length;
  if (all == 0) return null;
  return '${items.where((item) => item.done).length} of $all packed';
}

/// Whether a trip shows its packing list: until it's over, and after that
/// only if something is on it.
bool showsPacking(TripPlan plan, LocalDate today) =>
    plan.phaseOn(today) != TripPhase.past || plan.trip.packing.isNotEmpty;

/// Under an empty packing list.
const packingHint = 'Everything to take, shared with everyone on the trip. Tick things off as they go in the case.';

const _ideas = [
  'Passports',
  'Phone chargers',
  'Travel adapter',
  'Medicines',
  'Toiletries',
  'Sun cream',
  'Swimwear',
  'Sunglasses',
  'Headphones',
  'Snacks for the journey',
];

/// Ideas to add in one tap, leaving out what's on the list already.
List<String> packingIdeas(Iterable<ChecklistItem> items) {
  final have = {for (final item in items) item.text.trim().toLowerCase()};
  return [
    for (final idea in _ideas)
      if (!have.contains(idea.toLowerCase())) idea,
  ];
}

/// Another trip's packing list to start this one from: the latest trip
/// before [plan] with one (the last holiday's list), else any other trip
/// with one. Null when there's none.
TripPlan? packingListToReuse(TripPlan plan, List<TripPlan> plans) {
  TripPlan? best;
  for (final other in plans) {
    if (other.id == plan.id || other.trip.packing.isEmpty) continue;
    if (best == null || _isBetterSource(other, best, plan)) best = other;
  }
  return best;
}

/// Trips before [plan] beat later ones; among those, the latest wins.
bool _isBetterSource(TripPlan candidate, TripPlan best, TripPlan plan) {
  bool before(TripPlan p) => p.start != null && plan.start != null && p.start!.isBefore(plan.start!);
  if (before(candidate) != before(best)) return before(candidate);
  final a = candidate.start;
  final b = best.start;
  if (a == null || b == null) return a != null;
  return before(candidate) ? a.isAfter(b) : a.isBefore(b);
}

/// The line under the countdown postcard: what to do about packing, worded
/// for how it stands and how close the trip is.
class CountdownPackingText {
  const CountdownPackingText({required this.title, required this.detail, required this.semanticLabel});

  /// "Packing list".
  final String title;

  /// "Start yours", "Time to start packing", "5 of 12 packed", "All packed".
  final String detail;
  final String semanticLabel;
}

/// Days before a trip when an empty list is worth a nudge.
const packingNudgeDays = 7;

CountdownPackingText countdownPackingText(Iterable<ChecklistItem> items, {required int daysUntilStart}) {
  const title = 'Packing list';
  final all = items.length;
  final packed = items.where((item) => item.done).length;
  final String detail;
  if (all == 0) {
    detail = daysUntilStart <= packingNudgeDays ? 'Time to start packing' : 'Start yours';
  } else if (packed == all) {
    detail = 'All packed';
  } else if (packed == 0) {
    detail = all == 1 ? '1 thing to pack' : '$all things to pack';
  } else {
    detail = '$packed of $all packed';
  }
  return CountdownPackingText(title: title, detail: detail, semanticLabel: '$title: $detail');
}
