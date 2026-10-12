import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/packing.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  ChecklistItem item(String id, String text, {bool done = false, int at = 0}) => ChecklistItem(
    id: id,
    text: text,
    done: done,
    createdAt: DateTime(2026, 10, 1).add(Duration(minutes: at)),
  );

  TripPlan planWith(String id, {LocalDate? start, List<ChecklistItem> packing = const []}) => TripPlan(
    trip(
      id,
      title: id,
      plannedStart: start,
      plannedEnd: start?.addDays(5),
    ).copyWith(packing: {for (final i in packing) i.id: i}),
    const [],
  );

  group('the countdown\'s line', () {
    test('an empty list: start it, and a nudge in the last week', () {
      expect(countdownPackingText(const [], daysUntilStart: 30).detail, 'Start yours');
      expect(countdownPackingText(const [], daysUntilStart: 7).detail, 'Time to start packing');
      expect(countdownPackingText(const [], daysUntilStart: 1).semanticLabel, 'Packing list: Time to start packing');
    });

    test('how it stands once there\'s something on it', () {
      expect(countdownPackingText([item('a', 'Sun cream')], daysUntilStart: 3).detail, '1 thing to pack');
      final some = [item('a', 'Sun cream', done: true), item('b', 'Hats'), item('c', 'Chargers')];
      expect(countdownPackingText(some.skip(1), daysUntilStart: 3).detail, '2 things to pack');
      expect(countdownPackingText(some, daysUntilStart: 3).detail, '1 of 3 packed');
      expect(countdownPackingText([item('a', 'Sun cream', done: true)], daysUntilStart: 3).detail, 'All packed');
    });
  });

  test('progress, and what\'s still to pack first', () {
    final items = [item('a', 'Hats', done: true), item('b', 'Sun cream', at: 1), item('c', 'Chargers', at: 2)];
    expect(packingProgress(const []), isNull);
    expect(packingProgress(items), '1 of 3 packed');
    expect(orderedPacking(items).map((i) => i.text), ['Sun cream', 'Chargers', 'Hats']);
  });

  test('ideas leave out what\'s on the list already, whatever its case', () {
    final ideas = packingIdeas([item('a', 'sun cream'), item('b', 'PASSPORTS')]);
    expect(ideas, isNot(contains('Sun cream')));
    expect(ideas, isNot(contains('Passports')));
    expect(ideas, contains('Phone chargers'));
  });

  test('the list to start from: the last holiday before this one, else a later one', () {
    final lisbon = planWith('Lisbon', start: d(6, 1), packing: [item('a', 'Hats')]);
    final paris = planWith('Paris', start: d(8, 1), packing: [item('b', 'Umbrella')]);
    final rome = planWith('Rome', start: d(12, 1), packing: [item('c', 'Scarf')]);
    final empty = planWith('Empty', start: d(9, 1));
    final japan = planWith('Japan', start: d(10, 12));
    expect(packingListToReuse(japan, [lisbon, paris, empty, rome, japan])?.id, 'Paris');
    expect(packingListToReuse(lisbon, [lisbon, paris, rome])?.id, 'Paris');
    expect(packingListToReuse(japan, [empty, japan]), isNull);
  });

  test('a trip shows its packing list until it\'s over, and after only if it has one', () {
    final over = planWith('Over', start: d(1, 1));
    expect(showsPacking(over, d(10, 1)), isFalse);
    expect(showsPacking(planWith('Kept', start: d(1, 1), packing: [item('a', 'Hats')]), d(10, 1)), isTrue);
    expect(showsPacking(planWith('Soon', start: d(11, 1)), d(10, 1)), isTrue);
  });
}
