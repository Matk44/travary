import '../domain/domain.dart';
import 'formatters.dart';
import 'trip_plan.dart';

/// "Before you go": a trip's shared to-dos, things to sort that aren't
/// bookings. They're never on a day of the trip, so they don't stretch it.

/// The most a trip's checklist keeps (its security rules allow no more).
const maxChecklistItems = 100;

/// Open items first, the soonest due first and undated ones after them,
/// oldest first among equals; then the done ones, oldest first.
List<ChecklistItem> orderedChecklist(Iterable<ChecklistItem> items) {
  int byDue(ChecklistItem a, ChecklistItem b) {
    final aDue = a.due;
    final bDue = b.due;
    if (aDue != null && bDue != null && aDue != bDue) return aDue.compareTo(bDue);
    if (aDue != null && bDue == null) return -1;
    if (aDue == null && bDue != null) return 1;
    return a.createdAt.compareTo(b.createdAt);
  }

  final open = [
    for (final item in items)
      if (!item.done) item,
  ]..sort(byDue);
  final done = [
    for (final item in items)
      if (item.done) item,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return [...open, ...done];
}

/// A checklist row, already worded.
class ChecklistItemText {
  const ChecklistItemText({required this.title, this.due, this.overdue = false, required this.semanticLabel});

  final String title;

  /// "By 1 Oct", "By today", "Overdue · 1 Oct". Null without a date.
  final String? due;

  /// Not done and its day has passed: drawn as a warning.
  final bool overdue;
  final String semanticLabel;
}

ChecklistItemText checklistItemText(ChecklistItem item, LocalDate today) {
  final due = item.due;
  String? when;
  var overdue = false;
  var spoken = '';
  if (due != null) {
    final day = due.year == today.year ? formatDayMonth(due) : formatDate(due);
    if (!item.done && due.isBefore(today)) {
      overdue = true;
      when = 'Overdue · $day';
      spoken = ', overdue since $day';
    } else if (due == today) {
      when = 'By today';
      spoken = ', by today';
    } else if (due == today.addDays(1)) {
      when = 'By tomorrow';
      spoken = ', by tomorrow';
    } else {
      when = 'By $day';
      spoken = ', by $day';
    }
  }
  return ChecklistItemText(
    title: item.text,
    due: when,
    overdue: overdue,
    semanticLabel: '${item.text}${item.done ? ', done' : ''}$spoken',
  );
}

/// The section's heading: "Before you go" until the trip starts, then
/// "To do".
String checklistHeading(TripPlan plan, LocalDate today) =>
    plan.phaseOn(today) == TripPhase.upcoming ? 'Before you go' : 'To do';

/// Beside the heading: "2 of 5 done". Null for an empty list.
String? checklistProgress(Iterable<ChecklistItem> items) {
  final all = items.length;
  if (all == 0) return null;
  return '${items.where((item) => item.done).length} of $all done';
}

/// Under an empty checklist.
const checklistHint = 'Visas, insurance, the dog sitter: anything to sort before you go.';

/// Whether a trip shows its checklist: always until it's over, and after
/// that only if something is on it.
bool showsChecklist(TripPlan plan, LocalDate today) =>
    plan.phaseOn(today) != TripPhase.past || plan.trip.checklist.isNotEmpty;

const _ideas = [
  'Travel insurance',
  'Check passports are valid',
  'Check entry requirements',
  'Airport parking or transfer',
  'Pet or house sitter',
  'Tell the bank',
  'Download offline maps',
  'Pack chargers and adapters',
];

/// Ideas to add in one tap, leaving out what's on the list already.
List<String> checklistIdeas(Iterable<ChecklistItem> items) {
  final have = {for (final item in items) item.text.trim().toLowerCase()};
  return [
    for (final idea in _ideas)
      if (!have.contains(idea.toLowerCase())) idea,
  ];
}

/// [text] as it's kept: trimmed, at most [ChecklistItem.maxText]
/// characters. Null when there's nothing to keep.
String? cleanChecklistText(String text) {
  final trimmed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed.isEmpty) return null;
  return trimmed.length > ChecklistItem.maxText ? trimmed.substring(0, ChecklistItem.maxText) : trimmed;
}
