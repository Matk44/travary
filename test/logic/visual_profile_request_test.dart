import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/visual_profile_service.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/visual_profile_request.dart';

import '../helpers.dart';

void main() {
  final kyoto = trip('trip-1', title: 'Kyoto and Osaka');

  Booking flight() => Booking(
    id: 'b-flight',
    tripId: 'trip-1',
    kind: BookingKind.flight,
    title: 'London to Kyoto',
    startDate: d(4, 5),
    startTime: const ClockTime(10, 30),
    endDate: d(4, 6),
    endTime: const ClockTime(7, 10),
    location: 'London Heathrow (LHR)',
    reference: 'X7K2PQ',
    notes: 'Gate code 4411, passport ends 9981',
    details: const {DetailKeys.flightNumber: 'BA 7', DetailKeys.seats: '22A, 22B'},
    attachments: const [Attachment(id: 'a', name: 'Alex boarding pass.pdf', fileName: 'x.pdf', sizeBytes: 10)],
    artKey: 'any_plane_01',
    artSubject: 'plane',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  group('the callable payload', () {
    test('holds only the request contract\'s fields', () {
      final payload = classifierPayload(kyoto, [
        flight(),
        booking(
          'b-ryokan',
          BookingKind.stay,
          d(4, 6),
          tripId: 'trip-1',
          title: 'Ryokan Sakura',
          endDate: d(4, 9),
          location: 'Gion, Kyoto',
          details: const {DetailKeys.room: '12', DetailKeys.guests: '2'},
          reference: 'RS-77',
        ),
      ]);
      expect(payload.keys, unorderedEquals(['tripId', 'tripTitle', 'bookings']));
      expect(payload['tripId'], 'trip-1');
      expect(payload['tripTitle'], 'Kyoto and Osaka');
      final bookings = (payload['bookings']! as List).cast<Map<String, Object?>>();
      expect(bookings.first, {
        'id': 'b-flight',
        'kind': 'flight',
        'title': 'London to Kyoto',
        'location': 'London Heathrow (LHR)',
        'artSubject': 'plane',
        'startDate': '2026-04-05',
        'endDate': '2026-04-06',
      });
      for (final b in bookings) {
        expect(
          b.keys.toSet().difference({'id', 'kind', 'title', 'location', 'artSubject', 'startDate', 'endDate'}),
          isEmpty,
        );
      }
    });

    test('excludes notes, references, attachments, passenger and seat details', () {
      final sent = jsonEncode(classifierPayload(kyoto, [flight()]));
      for (final secret in [
        'X7K2PQ',
        '4411',
        '9981',
        'Alex',
        'boarding',
        'x.pdf',
        'BA 7',
        '22A',
        '10:30',
        '07:10',
        'any_plane_01',
      ]) {
        expect(sent, isNot(contains(secret)), reason: secret);
      }
    });

    test('bookings go in date order, and a same-day end is left out', () {
      final payload = classifierPayload(kyoto, [
        booking('late', BookingKind.dining, d(4, 9), tripId: 'trip-1'),
        booking('early', BookingKind.dining, d(4, 5), tripId: 'trip-1', endDate: d(4, 5)),
      ]);
      final bookings = (payload['bookings']! as List).cast<Map<String, Object?>>();
      expect(bookings.map((b) => b['id']), ['early', 'late']);
      expect(bookings.first.containsKey('endDate'), isFalse);
    });

    test('stays within the server\'s limits', () {
      final long = trip('trip-1', title: 'T' * 300);
      final many = [
        for (var i = 0; i < 90; i++)
          booking(
            'b${i.toString().padLeft(3, '0')}',
            i < 5 ? BookingKind.note : BookingKind.dining,
            d(4, 1).addDays(i),
            tripId: 'trip-1',
            title: 'x' * 150,
            location: 'y' * 250,
          ),
      ];
      final payload = classifierPayload(long, many);
      expect((payload['tripTitle']! as String).length, ClassifierLimits.tripTitle);
      final bookings = (payload['bookings']! as List).cast<Map<String, Object?>>();
      expect(bookings.length, ClassifierLimits.bookings);
      expect(bookings.any((b) => b['kind'] == 'note'), isFalse, reason: 'notes give way first');
      expect(bookings.every((b) => (b['title']! as String).length == ClassifierLimits.title), isTrue);
      expect(bookings.every((b) => (b['location']! as String).length == ClassifierLimits.location), isTrue);
    });

    test('shrinks to the byte limit with long non-Latin names', () {
      final many = [
        for (var i = 0; i < 80; i++)
          booking(
            'b$i',
            BookingKind.attraction,
            d(4, 1).addDays(i % 20),
            tripId: 'trip-1',
            title: '京' * 100,
            location: '都' * 180,
          ),
      ];
      final payload = classifierPayload(kyoto, many);
      expect(utf8.encode(jsonEncode(payload)).length, lessThanOrEqualTo(ClassifierLimits.payloadBytes));
      expect((payload['bookings']! as List), isNotEmpty);
    });

    test('tidies text like the server and never splits an emoji', () {
      expect(classifierText('  Kyoto \n\t and   Osaka  ', 100), 'Kyoto and Osaka');
      expect(classifierText('a${String.fromCharCode(0x202E)}b${String.fromCharCode(0)}c', 100), 'a b c');
      expect(classifierText('   ', 100), isNull);
      expect(classifierText('😀😀', 3), '😀');
    });
  });

  group('meaningful changes', () {
    final base = booking('b', BookingKind.dining, d(4, 5), tripId: 'trip-1', title: 'Pizzeria', location: 'Kyoto');

    test('cosmetic edits don\'t reclassify', () {
      expect(
        changesClassification(
          base,
          base.copyWith(
            attachments: const [Attachment(id: 'a', name: 'a', fileName: 'a.pdf', sizeBytes: 1)],
          ),
        ),
        isFalse,
      );
      expect(changesClassification(base, base.copyWith(artKey: 'any_pizza_01')), isFalse);
      expect(
        changesClassification(
          base,
          booking(
            'b',
            BookingKind.dining,
            d(4, 5),
            tripId: 'trip-1',
            title: ' Pizzeria ',
            location: 'Kyoto',
            at: const ClockTime(19, 0),
            reference: 'NEW',
            details: const {DetailKeys.partySize: '6'},
          ),
        ),
        isFalse,
      );
    });

    test('what the classifier reads does', () {
      Booking edit({
        String title = 'Pizzeria',
        String? location = 'Kyoto',
        BookingKind kind = BookingKind.dining,
        LocalDate? date,
        LocalDate? end,
        String tripId = 'trip-1',
      }) => booking('b', kind, date ?? d(4, 5), tripId: tripId, title: title, location: location, endDate: end);
      expect(changesClassification(base, edit(title: 'Sushi bar')), isTrue);
      expect(changesClassification(base, edit(location: 'Osaka')), isTrue);
      expect(changesClassification(base, edit(kind: BookingKind.event)), isTrue);
      expect(changesClassification(base, edit(date: d(4, 6))), isTrue);
      expect(changesClassification(base, edit(end: d(4, 7))), isTrue);
      expect(changesClassification(base, edit(tripId: 'other')), isTrue);
    });

    test('there must be something to classify', () {
      expect(hasEnoughToClassify(trip('t', title: 'October trip'), const []), isFalse);
      expect(hasEnoughToClassify(trip('t', title: 'Trip'), const []), isFalse);
      expect(hasEnoughToClassify(trip('t', title: 'Ski week in Zermatt'), const []), isTrue);
      expect(hasEnoughToClassify(trip('t', title: 'October trip'), [base]), isTrue);
    });
  });

  group('the Cloud service', () {
    test('sends the payload to classifyTripVisuals with a 120-second timeout', () async {
      String? name;
      Map<String, Object?>? sent;
      Duration? timeout;
      var signedIn = false;
      final service = CloudVisualProfileService(
        ensureSignedIn: () async => signedIn = true,
        invoke: (n, data, t) async {
          name = n;
          sent = data;
          timeout = t;
          return {
            'profile': {
              'primaryTheme': 'urban_heritage',
              'confidence': 0.9,
              'sourceHash': 'f' * 64,
              'setting': 'urban',
            },
            'cached': false,
          };
        },
      );
      final profile = await service.classify(kyoto, [flight()]);
      expect(signedIn, isTrue);
      expect(name, 'classifyTripVisuals');
      expect(timeout, const Duration(seconds: 120));
      expect(sent, classifierPayload(kyoto, [flight()]));
      expect(jsonEncode(sent), isNot(contains('X7K2PQ')));
      expect(profile.primaryTheme, ExperienceTheme.urbanHeritage);
    });

    test('a malformed answer is a friendly failure', () async {
      final service = CloudVisualProfileService(ensureSignedIn: () async {}, invoke: (_, _, _) async => {'nope': 1});
      await expectLater(
        service.classify(kyoto, const []),
        throwsA(isA<VisualProfileException>().having((e) => e.failure, 'failure', VisualProfileFailure.failed)),
      );
    });

    test('server errors become friendly, typed failures', () {
      expect(
        visualProfileExceptionFor('not-found', {'reason': 'trip_not_synced'}).failure,
        VisualProfileFailure.notSynced,
      );
      final cooldown = visualProfileExceptionFor('resource-exhausted', {'reason': 'cooldown', 'retryAfterSeconds': 9});
      expect(cooldown.failure, VisualProfileFailure.cooldown);
      expect(cooldown.retryAfter, const Duration(seconds: 9));
      expect(
        visualProfileExceptionFor('resource-exhausted', {'reason': 'daily'}).failure,
        VisualProfileFailure.dailyLimit,
      );
      expect(visualProfileExceptionFor('aborted', null).failure, VisualProfileFailure.superseded);
      expect(visualProfileExceptionFor('unavailable', null).failure, VisualProfileFailure.busy);
      for (final code in ['internal', 'permission-denied', 'unauthenticated', 'invalid-argument']) {
        final failure = visualProfileExceptionFor(code, null);
        expect(failure.failure, VisualProfileFailure.failed);
        expect(failure.message, isNot(contains(code)));
      }
    });
  });
}
