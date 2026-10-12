import 'local_date.dart';
import 'trip.dart';

enum OnboardingStep { destination, dates, booking }

enum OnboardingBookingSource { manual, smartImport }

/// A resumable first holiday. Unknown dates are kept as null.
class OnboardingDraft {
  const OnboardingDraft({
    this.step = OnboardingStep.destination,
    this.destination,
    this.start,
    this.end,
    this.tripId,
    this.bookingId,
    this.bookingSource,
    this.completed = false,
  });

  final OnboardingStep step;
  final TripDestination? destination;
  final LocalDate? start;
  final LocalDate? end;
  final String? tripId;
  final String? bookingId;
  final OnboardingBookingSource? bookingSource;
  final bool completed;

  OnboardingHoliday get holiday => OnboardingHoliday(name: destination?.name ?? 'Your holiday', start: start, end: end);

  OnboardingDraft copyWith({
    OnboardingStep? step,
    TripDestination? destination,
    bool clearDestination = false,
    LocalDate? start,
    LocalDate? end,
    bool clearDates = false,
    bool clearEnd = false,
    String? tripId,
    String? bookingId,
    OnboardingBookingSource? bookingSource,
    bool? completed,
  }) => OnboardingDraft(
    step: step ?? this.step,
    destination: clearDestination ? null : destination ?? this.destination,
    start: clearDates ? null : start ?? this.start,
    end: clearDates || clearEnd ? null : end ?? this.end,
    tripId: tripId ?? this.tripId,
    bookingId: bookingId ?? this.bookingId,
    bookingSource: bookingSource ?? this.bookingSource,
    completed: completed ?? this.completed,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'step': step.name,
    'destination': destination?.toJson(),
    'start': start?.toIso(),
    'end': end?.toIso(),
    'tripId': tripId,
    'bookingId': bookingId,
    'bookingSource': bookingSource?.name,
    'completed': completed,
  };

  factory OnboardingDraft.fromJson(Object? value) {
    if (value is! Map || value['schemaVersion'] != 1) throw const FormatException('Unknown holiday setup');
    LocalDate? date(String key) {
      final text = value[key];
      if (text == null) return null;
      if (text is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
        throw const FormatException('Invalid holiday date');
      }
      final parsed = LocalDate.parse(text);
      if (LocalDate.fromDateTime(parsed.toDateTime()) != parsed) throw const FormatException('Invalid holiday date');
      return parsed;
    }

    String? id(String key) {
      final text = value[key];
      if (text == null) return null;
      if (text is! String || text.isEmpty || text.length > 150) throw const FormatException('Invalid holiday ID');
      return text;
    }

    final step = OnboardingStep.values.where((s) => s.name == value['step']).firstOrNull;
    if (step == null) throw const FormatException('Unknown setup step');
    final start = date('start');
    final end = date('end');
    if (end != null && (start == null || end.isBefore(start))) throw const FormatException('Invalid holiday range');
    final destination = TripDestination.tryParse(value['destination']);
    if (value['destination'] != null && destination == null) throw const FormatException('Invalid destination');
    final source = OnboardingBookingSource.values.where((s) => s.name == value['bookingSource']).firstOrNull;
    if (value['bookingSource'] != null && source == null) throw const FormatException('Invalid booking source');
    return OnboardingDraft(
      step: step,
      destination: destination,
      start: start,
      end: end,
      tripId: id('tripId'),
      bookingId: id('bookingId'),
      bookingSource: source,
      completed: value['completed'] == true,
    );
  }
}

/// The live context printed on the folio, shared by lookup and import review.
class OnboardingHoliday {
  const OnboardingHoliday({required this.name, this.start, this.end});
  final String name;
  final LocalDate? start;
  final LocalDate? end;
}
