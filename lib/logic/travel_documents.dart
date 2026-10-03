import 'dart:math' as math;

import '../domain/domain.dart';
import 'destinations.dart';
import 'formatters.dart';
import 'trip_plan.dart';

/// How a document stands for travelling, most urgent last.
enum DocumentAlert {
  none,

  /// Expires within [soonDays].
  soon,

  /// Won't do for the next trip: a passport with under
  /// [passportMonthsAfterTrip] months left after it, or anything that runs
  /// out before it ends.
  trip,
  expired,
}

/// Many countries want this much left on a passport after you leave.
const passportMonthsAfterTrip = 6;

/// A document expiring within this many days is flagged.
const soonDays = 90;

/// What a document's row shows, already worded (like `CardText` for
/// bookings): the design draws it, never words it.
class DocumentCardText {
  const DocumentCardText({
    required this.title,
    required this.holder,
    this.detail,
    this.status,
    this.alert = DocumentAlert.none,
    required this.semanticLabel,
  });

  /// "Passport", "ESTA (USA)".
  final String title;

  /// "You", "Sam".
  final String holder;

  /// The masked number and issuing country: "•••• 4821 · United Kingdom".
  final String? detail;

  /// "Expires 12 Mar 2031", "Expired 3 Jan 2026".
  final String? status;
  final DocumentAlert alert;

  /// For screen readers; never includes the number.
  final String semanticLabel;
}

/// Who a document belongs to, for showing: its holder, or "You".
String holderLabel(TravelDocument document) => document.holder.trim().isEmpty ? 'You' : document.holder.trim();

/// Only the last four characters of a document number: "•••• 4821".
String maskDocumentNumber(String number) {
  final plain = number.replaceAll(RegExp(r'\s+'), '');
  return plain.length <= 4 ? '••••' : '•••• ${plain.substring(plain.length - 4)}';
}

/// [document]'s row, judged against [today] and the [nextTrip] (the trip
/// happening now or the next one).
DocumentCardText documentCardText(TravelDocument document, {required LocalDate today, TripPlan? nextTrip}) {
  final number = document.number;
  final country = document.issuedBy == null ? null : countryPlace(document.issuedBy!).name;
  final detailParts = [if (number != null) maskDocumentNumber(number), ?country];
  final status = documentStatus(document, today: today, nextTrip: nextTrip);
  final holder = holderLabel(document);
  return DocumentCardText(
    title: document.name,
    holder: holder,
    detail: detailParts.isEmpty ? null : detailParts.join(' · '),
    status: status?.text,
    alert: status?.alert ?? DocumentAlert.none,
    semanticLabel: ['${document.name}, ${holder == 'You' ? 'yours' : holder}', ?country, ?status?.text].join('. '),
  );
}

/// When [document] runs out, and whether that's a problem; null without an
/// expiry date.
({String text, DocumentAlert alert})? documentStatus(
  TravelDocument document, {
  required LocalDate today,
  TripPlan? nextTrip,
}) {
  final expires = document.expiresOn;
  if (expires == null) return null;
  final date = formatDate(expires);
  if (expires.isBefore(today)) return (text: 'Expired $date', alert: DocumentAlert.expired);

  final tripEnd = nextTrip?.end;
  if (nextTrip != null && tripEnd != null && !tripEnd.isBefore(today)) {
    final trip = nextTrip.trip.title.trim().isEmpty ? 'your trip' : nextTrip.trip.title.trim();
    if (document.type == TravelDocumentType.passport) {
      if (expires.isBefore(addMonths(tripEnd, passportMonthsAfterTrip))) {
        return (text: 'Expires $date, under 6 months after $trip', alert: DocumentAlert.trip);
      }
    } else if (expires.isBefore(tripEnd)) {
      return (text: 'Expires $date, before $trip ends', alert: DocumentAlert.trip);
    }
  }
  if (today.daysUntil(expires) <= soonDays) return (text: 'Expires $date', alert: DocumentAlert.soon);
  return (text: 'Expires $date', alert: DocumentAlert.none);
}

/// What to do about an [alert] on a [type] of document, for its own screen.
String? documentAdvice(TravelDocumentType type, DocumentAlert alert) => switch (alert) {
  DocumentAlert.none => null,
  DocumentAlert.soon => 'It runs out soon. Renewing can take weeks, so it\'s worth starting early.',
  DocumentAlert.trip when type == TravelDocumentType.passport =>
    'Many countries need a passport valid for 6 months after you leave. Check the entry rules for where you\'re '
        'going, and renew it if you need to.',
  DocumentAlert.trip => 'It runs out before the trip ends, so check you\'re covered for every day.',
  DocumentAlert.expired => 'This has expired. Renew it before you travel.',
};

/// [date] moved [months] calendar months on, on the same day where it
/// exists (31 August + 6 months is 28 or 29 February).
LocalDate addMonths(LocalDate date, int months) {
  final index = date.month - 1 + months;
  final year = date.year + (index ~/ 12);
  final month = index % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return LocalDate(year, month, math.min(date.day, lastDay));
}

/// The names documents have been kept under, for quick picking: everyone
/// but the phone's owner, A to Z.
List<String> knownHolders(Iterable<TravelDocument> documents) {
  final names = {
    for (final document in documents)
      if (document.holder.trim().isNotEmpty) document.holder.trim(),
  }.toList();
  return names..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}

/// Documents by person: the phone's owner first, then A to Z; within a
/// person, passports first, then the other types in order.
List<({String holder, List<TravelDocument> documents})> documentsByHolder(Iterable<TravelDocument> documents) {
  final groups = <String, List<TravelDocument>>{};
  for (final document in documents) {
    groups.putIfAbsent(holderLabel(document), () => []).add(document);
  }
  final holders = groups.keys.toList()
    ..sort((a, b) {
      if (a == 'You' || b == 'You') return a == 'You' ? (b == 'You' ? 0 : -1) : 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
  return [
    for (final holder in holders)
      (
        holder: holder,
        documents: groups[holder]!
          ..sort((a, b) {
            final byType = a.type.index.compareTo(b.type.index);
            return byType != 0 ? byType : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }),
      ),
  ];
}
