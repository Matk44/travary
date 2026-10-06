import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';

import '../helpers.dart';

void main() {
  final created = DateTime(2026, 9, 1, 9);
  final visa = ChecklistItem(id: 'c1', text: 'Apply for the visa', due: d(10, 1), createdAt: created);

  test('an item round-trips through its stored form', () {
    expect(ChecklistItem.tryParse('c1', visa.toJson()), visa);
    final done = visa.copyWith(done: true, clearDue: true);
    expect(ChecklistItem.tryParse('c1', done.toJson()), done);
    expect(done.due, isNull);
  });

  test('junk is dropped and long text is cut', () {
    expect(ChecklistItem.tryParse('x', 'Apply'), isNull);
    expect(ChecklistItem.tryParse('x', {'text': '   '}), isNull);
    expect(ChecklistItem.tryParse('x', {'done': true}), isNull);
    final long = ChecklistItem.tryParse('x', {'text': 'a' * 300, 'due': 'soon', 'done': 'yes'})!;
    expect(long.text.length, ChecklistItem.maxText);
    expect(long.due, isNull);
    expect(long.done, isFalse);
  });

  test('a trip keeps its checklist, but editing the trip never sends it', () {
    final japan = trip('japan').copyWith(checklist: {visa.id: visa});
    final stored = Trip.fromJson('japan', japan.toJson());
    expect(stored.checklist, {'c1': visa});
    expect(japan.toEditableJson().containsKey('checklist'), isFalse);
    expect(trip('empty').toJson().containsKey('checklist'), isFalse);
    expect(Trip.fromJson('t', {'checklist': 'nope'}).checklist, isEmpty);
  });
}
