import 'local_date.dart';

/// Something to sort out for a trip that isn't a booking: "Apply for the
/// visa", "Book the dog sitter". Shared with everyone on the trip, kept on
/// the trip (`Trip.checklist`), and never on a day of it: it may well be
/// due before the trip starts.
class ChecklistItem {
  const ChecklistItem({required this.id, required this.text, this.done = false, this.due, required this.createdAt});

  /// Longest text kept.
  static const maxText = 120;

  final String id;
  final String text;
  final bool done;

  /// Optional "by" date, any day (often before the trip).
  final LocalDate? due;
  final DateTime createdAt;

  ChecklistItem copyWith({String? text, bool? done, LocalDate? due, bool clearDue = false}) => ChecklistItem(
    id: id,
    text: text ?? this.text,
    done: done ?? this.done,
    due: clearDue ? null : due ?? this.due,
    createdAt: createdAt,
  );

  Map<String, Object?> toJson() => {
    'text': text,
    'done': done,
    'due': due?.toIso(),
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  /// Null for anything that isn't an item worth showing.
  static ChecklistItem? tryParse(String id, Object? json) {
    if (json is! Map) return null;
    final text = json['text'];
    if (text is! String || text.trim().isEmpty) return null;
    final created = json['createdAt'];
    return ChecklistItem(
      id: id,
      text: text.trim().length > maxText ? text.trim().substring(0, maxText) : text.trim(),
      done: json['done'] == true,
      due: LocalDate.tryParse(json['due']),
      createdAt: created is num ? DateTime.fromMillisecondsSinceEpoch(created.toInt()) : DateTime(2026),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChecklistItem &&
      other.id == id &&
      other.text == text &&
      other.done == done &&
      other.due == due &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, text, done, due, createdAt);

  @override
  String toString() => 'ChecklistItem($id, $text${done ? ', done' : ''})';
}
