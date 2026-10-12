import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/checklist.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  final today = d(10, 5);
  ChecklistItem item(String id, {LocalDate? due, bool done = false, int minute = 0, String? text}) =>
      ChecklistItem(id: id, text: text ?? id, due: due, done: done, createdAt: DateTime(2026, 9, 1, 9, minute));

  test('open items first, soonest due first, undated after; done ones last', () {
    final ordered = orderedChecklist([
      item('done-early', done: true, minute: 0),
      item('undated-new', minute: 5),
      item('due-later', due: d(10, 9)),
      item('undated-old', minute: 1),
      item('due-soon', due: d(10, 6)),
      item('done-late', done: true, minute: 9),
    ]);
    expect(ordered.map((i) => i.id), [
      'due-soon',
      'due-later',
      'undated-old',
      'undated-new',
      'done-early',
      'done-late',
    ]);
  });

  test('the empty list\'s hint: before you go, then while you\'re away', () {
    final japan = TripPlan(trip('japan', plannedStart: d(10, 11), plannedEnd: d(10, 23)), const []);
    expect(checklistHintFor(japan, d(10, 5)), contains('before you go'));
    expect(checklistHintFor(japan, d(10, 12)), contains('while you\'re away'));
  });

  group('a row says when it\'s due', () {
    String? due(ChecklistItem i) => checklistItemText(i, today).due;

    test('by a day, today or tomorrow', () {
      expect(due(item('a', due: d(10, 9))), 'By 9 Oct');
      expect(due(item('a', due: today)), 'By today');
      expect(due(item('a', due: d(10, 6))), 'By tomorrow');
      expect(due(item('a', due: LocalDate(2027, 1, 4))), 'By 4 Jan 2027');
      expect(due(item('a')), isNull);
    });

    test('overdue until it\'s done', () {
      final late = checklistItemText(item('Visa', due: d(10, 1)), today);
      expect(late.due, 'Overdue · 1 Oct');
      expect(late.overdue, isTrue);
      expect(late.semanticLabel, 'Visa, overdue since 1 Oct');
      final done = checklistItemText(item('Visa', due: d(10, 1), done: true), today);
      expect(done.due, 'By 1 Oct');
      expect(done.overdue, isFalse);
      expect(done.semanticLabel, 'Visa, done, by 1 Oct');
    });
  });

  test('"Before you go" until the trip starts, then "To do"', () {
    final japan = TripPlan(trip('japan', plannedStart: d(10, 11), plannedEnd: d(10, 23)), const []);
    expect(checklistHeading(japan, today), 'Before you go');
    expect(checklistHeading(japan, d(10, 12)), 'To do');
  });

  test('progress beside the heading', () {
    expect(checklistProgress(const []), isNull);
    expect(checklistProgress([item('a', done: true), item('b'), item('c')]), '1 of 3 done');
  });

  test('a finished trip shows its checklist only if something is on it', () {
    final past = trip('past', plannedStart: d(9, 1), plannedEnd: d(9, 5));
    expect(showsChecklist(TripPlan(past, const []), today), isFalse);
    expect(showsChecklist(TripPlan(past.copyWith(checklist: {'a': item('a')}), const []), today), isTrue);
    final coming = trip('coming', plannedStart: d(10, 11), plannedEnd: d(10, 23));
    expect(showsChecklist(TripPlan(coming, const []), today), isTrue);
  });

  test('ideas leave out what\'s already on the list', () {
    final ideas = checklistIdeas([item('x', text: 'travel insurance')]);
    expect(ideas, isNot(contains('Travel insurance')));
    expect(ideas.first, 'Check passports are valid');
  });

  test('text is tidied and kept short', () {
    expect(cleanChecklistText('  Book   the  dog sitter '), 'Book the dog sitter');
    expect(cleanChecklistText('   '), isNull);
    expect(cleanChecklistText('a' * 200)!.length, ChecklistItem.maxText);
  });
}
