import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/travel_documents.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

TravelDocument doc(
  String id,
  TravelDocumentType type, {
  String holder = '',
  String? title,
  String? number,
  String? issuedBy,
  LocalDate? expiresOn,
}) => TravelDocument(
  id: id,
  type: type,
  holder: holder,
  title: title,
  number: number,
  issuedBy: issuedBy,
  expiresOn: expiresOn,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  final today = LocalDate(2026, 10, 3);
  final japan = TripPlan(
    trip('jp', title: 'Japan Holiday', plannedStart: LocalDate(2026, 11, 8), plannedEnd: LocalDate(2026, 11, 14)),
    const [],
  );

  group('status', () {
    String? text(TravelDocument d, {TripPlan? trip}) => documentStatus(d, today: today, nextTrip: trip)?.text;
    DocumentAlert? alert(TravelDocument d, {TripPlan? trip}) => documentStatus(d, today: today, nextTrip: trip)?.alert;

    test('nothing to say without an expiry date', () {
      expect(documentStatus(doc('p', TravelDocumentType.passport), today: today), isNull);
    });

    test('a passport needs 6 months left after the next trip', () {
      final ok = doc('p', TravelDocumentType.passport, expiresOn: LocalDate(2027, 6, 1));
      expect(text(ok, trip: japan), 'Expires 1 Jun 2027');
      expect(alert(ok, trip: japan), DocumentAlert.none);

      final short = doc('p', TravelDocumentType.passport, expiresOn: LocalDate(2027, 5, 13));
      expect(text(short, trip: japan), 'Expires 13 May 2027, under 6 months after Japan Holiday');
      expect(alert(short, trip: japan), DocumentAlert.trip);
      // Exactly 6 months after the trip ends is enough.
      expect(
        alert(doc('p', TravelDocumentType.passport, expiresOn: LocalDate(2027, 5, 14)), trip: japan),
        DocumentAlert.none,
      );
    });

    test('anything else must last until the trip ends', () {
      final insurance = doc('i', TravelDocumentType.insurance, expiresOn: LocalDate(2026, 11, 10));
      expect(text(insurance, trip: japan), 'Expires 10 Nov 2026, before Japan Holiday ends');
      expect(alert(insurance, trip: japan), DocumentAlert.trip);
      expect(
        alert(doc('i', TravelDocumentType.insurance, expiresOn: LocalDate(2026, 11, 14)), trip: japan),
        DocumentAlert.soon,
      );
    });

    test('soon, expired, and no trip to judge by', () {
      expect(alert(doc('v', TravelDocumentType.visa, expiresOn: LocalDate(2026, 12, 31))), DocumentAlert.soon);
      expect(alert(doc('v', TravelDocumentType.visa, expiresOn: LocalDate(2027, 3, 1))), DocumentAlert.none);
      final old = doc('d', TravelDocumentType.drivingLicence, expiresOn: LocalDate(2026, 1, 3));
      expect(text(old, trip: japan), 'Expired 3 Jan 2026');
      expect(alert(old, trip: japan), DocumentAlert.expired);
    });

    test('a trip that has ended judges nothing', () {
      final past = TripPlan(
        trip('old', title: 'Old', plannedStart: LocalDate(2026, 8, 1), plannedEnd: LocalDate(2026, 8, 5)),
        const [],
      );
      expect(
        alert(doc('p', TravelDocumentType.passport, expiresOn: LocalDate(2027, 3, 1)), trip: past),
        DocumentAlert.none,
      );
    });

    test('advice for each alert', () {
      expect(documentAdvice(TravelDocumentType.passport, DocumentAlert.none), isNull);
      expect(documentAdvice(TravelDocumentType.passport, DocumentAlert.trip), contains('6 months'));
      expect(documentAdvice(TravelDocumentType.insurance, DocumentAlert.trip), contains('before the trip ends'));
    });
  });

  test('months are added by the calendar', () {
    expect(addMonths(LocalDate(2026, 11, 14), 6), LocalDate(2027, 5, 14));
    expect(addMonths(LocalDate(2026, 8, 31), 6), LocalDate(2027, 2, 28));
    expect(addMonths(LocalDate(2027, 8, 31), 6), LocalDate(2028, 2, 29));
  });

  test('numbers show only their last four characters', () {
    expect(maskDocumentNumber('123 456 789'), '•••• 6789');
    expect(maskDocumentNumber('AB12'), '••••');
  });

  test('a row\'s words, and a screen reader never hears the number', () {
    final passport = doc(
      'p',
      TravelDocumentType.passport,
      holder: 'Sam',
      number: '533 120 784',
      issuedBy: 'GB',
      expiresOn: LocalDate(2031, 3, 12),
    );
    final text = documentCardText(passport, today: today, nextTrip: japan);
    expect(text.title, 'Passport');
    expect(text.holder, 'Sam');
    expect(text.detail, '•••• 0784 · United Kingdom');
    expect(text.status, 'Expires 12 Mar 2031');
    expect(text.semanticLabel, 'Passport, Sam. United Kingdom. Expires 12 Mar 2031');
    expect(text.semanticLabel, isNot(contains('0784')));

    final mine = documentCardText(doc('e', TravelDocumentType.visa, title: 'ESTA (USA)'), today: today);
    expect((mine.title, mine.holder, mine.detail, mine.status), ('ESTA (USA)', 'You', null, null));
  });

  test('grouped by person, the owner first, passports first', () {
    final groups = documentsByHolder([
      doc('1', TravelDocumentType.insurance, holder: 'Sam'),
      doc('2', TravelDocumentType.passport, holder: 'Sam'),
      doc('3', TravelDocumentType.visa),
      doc('4', TravelDocumentType.passport, holder: 'alex'),
      doc('5', TravelDocumentType.passport),
    ]);
    expect([for (final g in groups) g.holder], ['You', 'alex', 'Sam']);
    expect([for (final d in groups.first.documents) d.id], ['5', '3']);
    expect([for (final d in groups.last.documents) d.id], ['2', '1']);
    expect(knownHolders([doc('a', TravelDocumentType.other, holder: ' Sam '), doc('b', TravelDocumentType.other)]), [
      'Sam',
    ]);
  });

  test('a document keeps everything through storage, and drops what it can\'t trust', () {
    final full = TravelDocument(
      id: 'p',
      type: TravelDocumentType.passport,
      holder: 'Sam',
      number: '533120784',
      issuedBy: 'GB',
      expiresOn: LocalDate(2031, 3, 12),
      notes: 'Renewed 2021',
      files: const [DocumentFile(id: 'f', name: 'Photo page.jpg', fileName: 'f.jpg', sizeBytes: 10)],
      createdAt: DateTime(2026, 10, 3),
      updatedAt: DateTime(2026, 10, 3),
    );
    final back = TravelDocument.tryParse(full.toJson())!;
    expect(back.toJson(), full.toJson());
    expect(back.files.single.isImage, isTrue);

    final odd = TravelDocument.tryParse({
      'id': 'x',
      'type': 'spaceship',
      'issuedBy': 'XX',
      'files': [
        {'id': 'f', 'fileName': '../escape.jpg'},
      ],
    })!;
    expect((odd.type, odd.issuedBy), (TravelDocumentType.other, null));
    expect(odd.files, isEmpty);
    expect(TravelDocument.tryParse({'type': 'passport'}), isNull);
  });
}
