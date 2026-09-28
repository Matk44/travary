import 'dart:convert';

import '../domain/domain.dart';
import 'art_subjects.dart';

/// What the app sends to the `classifyTripVisuals` function: the minimum
/// needed to classify a trip, and nothing personal.
///
/// Per booking only its kind, name, place, picture subject and dates.
/// Never references, notes, tickets, details (seats, rooms, guests),
/// times, member names or anything else.
///
/// Limits mirror `REQUEST_LIMITS` in `functions/src/visualProfileRequest.ts`,
/// so the server never has to refuse what the app sends.
abstract final class ClassifierLimits {
  static const tripTitle = 120;
  static const bookings = 80;
  static const bookingId = 128;
  static const title = 100;
  static const location = 180;

  /// The server allows 48 KiB; a little room for its own encoding.
  static const payloadBytes = 46 * 1024;
}

/// The callable's request body for [trip] and its [bookings].
Map<String, Object?> classifierPayload(Trip trip, Iterable<Booking> bookings) {
  final ordered = [
    for (final booking in bookings)
      if (booking.id.isNotEmpty && booking.id.length <= ClassifierLimits.bookingId && _cleaned(booking.title) != null)
        booking,
  ]..sort(_byDate);

  // Very long trips: notes say least about a trip, so they go first.
  var kept = ordered;
  if (kept.length > ClassifierLimits.bookings) {
    kept = [
      for (final b in kept)
        if (b.kind != BookingKind.note) b,
    ];
    if (kept.length > ClassifierLimits.bookings) kept = kept.sublist(0, ClassifierLimits.bookings);
  }

  final title = classifierText(trip.title, ClassifierLimits.tripTitle);
  final entries = [for (final booking in kept) _bookingEntry(booking)];
  Map<String, Object?> payload() => {'tripId': trip.id, 'tripTitle': ?title, 'bookings': entries};
  // Stays within the server's size limit (only reachable with very long
  // non-Latin names): the latest bookings give way first.
  while (entries.isNotEmpty && utf8.encode(jsonEncode(payload())).length > ClassifierLimits.payloadBytes) {
    entries.removeLast();
  }
  return payload();
}

Map<String, Object?> _bookingEntry(Booking booking) {
  final subject = artSubjectFor(booking);
  return {
    'id': booking.id,
    'kind': booking.kind.name,
    'title': classifierText(booking.title, ClassifierLimits.title),
    'location': ?classifierText(booking.location, ClassifierLimits.location),
    if (subject != null && subject != genericSubject) 'artSubject': subject,
    'startDate': booking.startDate.toIso(),
    if (booking.endDate != null && booking.endDate!.isAfter(booking.startDate)) 'endDate': booking.endDate!.toIso(),
  };
}

int _byDate(Booking a, Booking b) {
  final start = a.startDate.compareTo(b.startDate);
  if (start != 0) return start;
  final end = a.lastDate.compareTo(b.lastDate);
  if (end != 0) return end;
  return a.id.compareTo(b.id);
}

final _unwanted = RegExp(r'[\p{Cc}\u202A-\u202E\u2066-\u2069]', unicode: true);
final _spaces = RegExp(r'\s+');

String? _cleaned(String? value) {
  if (value == null) return null;
  final text = value.replaceAll(_unwanted, ' ').replaceAll(_spaces, ' ').trim();
  return text.isEmpty ? null : text;
}

/// [value] tidied like the server does (one line, no control characters)
/// and cut to [max] characters without splitting an emoji. Null if empty.
String? classifierText(String? value, int max) {
  final text = _cleaned(value);
  if (text == null || text.length <= max) return text;
  final unit = text.codeUnitAt(max - 1);
  final end = unit >= 0xD800 && unit <= 0xDBFF ? max - 1 : max;
  return text.substring(0, end).trimRight();
}

/// Whether editing [before] into [after] can change a trip's classification.
/// Times, references, notes, details, tickets and picked art can't.
bool changesClassification(Booking before, Booking after) =>
    before.tripId != after.tripId ||
    before.kind != after.kind ||
    before.title.trim() != after.title.trim() ||
    (before.location ?? '').trim() != (after.location ?? '').trim() ||
    artSubjectFor(before) != artSubjectFor(after) ||
    before.startDate != after.startDate ||
    before.lastDate != after.lastDate;

/// Titles the app gives trips on its own ("October trip"): they say nothing
/// about where or what the trip is.
final _placeholderTitle = RegExp(
  r'^(trip|new trip|my trip|holiday|vacation|(january|february|march|april|may|june|july|august|september|october|november|december) trip)$',
  caseSensitive: false,
);

/// Whether there's enough to classify: a booking, or a telling trip name.
bool hasEnoughToClassify(Trip trip, Iterable<Booking> bookings) {
  if (bookings.isNotEmpty) return true;
  final title = _cleaned(trip.title);
  return title != null && !_placeholderTitle.hasMatch(title);
}
