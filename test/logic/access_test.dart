import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/access.dart';
import 'package:travary/logic/price_text.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  final now = DateTime(2026, 10, 14, 10);
  // Orlando: 12–18 Oct.
  final orlando = TripPlan(trip('orlando'), [
    booking('hotel', BookingKind.stay, d(10, 12), tripId: 'orlando', endDate: d(10, 18)),
  ]);
  final paris = TripPlan(trip('paris'), [booking('p', BookingKind.stay, d(6, 1), tripId: 'paris', endDate: d(6, 4))]);

  AccessPolicy policy(Entitlements e, [DateTime? at]) => AccessPolicy(e, at ?? now);

  group('free plan', () {
    test('Smart Import has a few free uses, then locks', () {
      expect(policy(Entitlements.none).decide(PremiumFeature.smartImport).freeUsesLeft, 3);
      const used = Entitlements(smartImportsUsed: 3);
      expect(policy(used).decide(PremiumFeature.smartImport).allowed, isFalse);
    });

    test('other premium features are locked', () {
      for (final feature in [PremiumFeature.familySharing, PremiumFeature.ticketBackup, PremiumFeature.flightAlerts]) {
        expect(policy(Entitlements.none).decide(feature, trip: orlando).allowed, isFalse, reason: feature.name);
      }
    });
  });

  group('Plus', () {
    final plus = Entitlements(plus: PlusSubscription(expiresAt: now.add(const Duration(days: 10))));

    test('unlocks everything on every trip, without using free imports', () {
      final decision = policy(plus).decide(PremiumFeature.smartImport);
      expect(decision.allowed, isTrue);
      expect(decision.isFreeUse, isFalse);
      expect(policy(plus).decide(PremiumFeature.familySharing, trip: paris).allowed, isTrue);
    });

    test('stops when it expires', () {
      final later = now.add(const Duration(days: 11));
      expect(policy(plus, later).hasPlus, isFalse);
      expect(policy(plus, later).decide(PremiumFeature.familySharing, trip: orlando).allowed, isFalse);
    });
  });

  group('Trip Pass', () {
    // Bought for Orlando as it was: 12–18 Oct.
    final pass = Entitlements(tripPasses: {'orlando': newTripPassFor(orlando)});

    test('unlocks its own trip only', () {
      expect(policy(pass).decide(PremiumFeature.familySharing, trip: orlando).allowed, isTrue);
      expect(policy(pass).decide(PremiumFeature.familySharing, trip: paris).allowed, isFalse);
    });

    test('lasts until a week after the trip ends', () {
      expect(policy(pass, DateTime(2026, 10, 25, 23, 59)).hasTripPass(orlando), isTrue);
      expect(policy(pass, DateTime(2026, 10, 26, 0, 1)).hasTripPass(orlando), isFalse);
      expect(policy(pass).tripPassFor(orlando)?.lastDay, d(10, 25));
    });

    test('grows with its trip: the flight home added after buying is covered', () {
      final grown = TripPlan(trip('orlando'), [
        ...orlando.bookings,
        booking('home', BookingKind.flight, d(10, 24), tripId: 'orlando'),
      ]);
      expect(tripPassLastDay(newTripPassFor(orlando), grown.start, grown.end), d(10, 31));
      expect(policy(pass, DateTime(2026, 10, 31, 20)).hasTripPass(grown), isTrue);
      expect(policy(pass, DateTime(2026, 11, 1, 0, 1)).hasTripPass(grown), isFalse);
      // Shrinking or moving earlier never takes days away.
      expect(tripPassLastDay(newTripPassFor(orlando), d(10, 12), d(10, 14)), d(10, 25));
      expect(tripPassLastDay(newTripPassFor(orlando), null, null), d(10, 25));
    });

    test('but only up to 30 days, and only as the same holiday', () {
      final bought = newTripPassFor(orlando);
      // 12 Oct – 10 Nov is 30 days: covered. A day more is too long.
      expect(tripPassLastDay(bought, d(10, 12), d(11, 10)), d(11, 17));
      expect(tripPassLastDay(bought, d(10, 12), d(11, 11)), d(10, 25));
      // Moved to after its own dates: another holiday.
      expect(tripPassLastDay(bought, d(10, 20), d(10, 26)), d(10, 25));
    });

    test('lasts exactly as the server says (cases shared with functions/src/tripPass.ts)', () {
      final json = jsonDecode(File('functions/src/tripPassCases.json').readAsStringSync()) as Map<String, Object?>;
      final cases = json['cases']! as List;
      expect(cases.length, greaterThanOrEqualTo(10));
      for (final c in cases.cast<Map<String, Object?>>()) {
        final pass = (c['pass']! as List).cast<String>();
        final trip = (c['trip'] as List?)?.cast<String>();
        expect(
          tripPassLastDay(
            TripPass(tripId: 't', start: LocalDate.tryParse(pass[0])!, end: LocalDate.tryParse(pass[1])!),
            trip == null ? null : LocalDate.tryParse(trip[0]),
            trip == null ? null : LocalDate.tryParse(trip[1]),
          ),
          LocalDate.tryParse(c['lastDay']),
          reason: c['why'] as String,
        );
      }
    });

    test('covers the dates it was bought for, whatever the trip says later', () {
      // Stretched to the end of the year: still ends a week after 18 Oct.
      final stretched = TripPlan(trip('orlando', plannedStart: d(10, 12), plannedEnd: d(12, 31)), orlando.bookings);
      expect(policy(pass, DateTime(2026, 10, 25, 12)).hasTripPass(stretched), isTrue);
      expect(policy(pass, DateTime(2026, 11, 20)).hasTripPass(stretched), isFalse);
      // Turned into next year's holiday somewhere else: not covered, and
      // it can have a pass of its own.
      final italy = TripPlan(
        trip('orlando', title: 'Italy', plannedStart: LocalDate(2027, 3, 1), plannedEnd: LocalDate(2027, 3, 10)),
        const [],
      );
      final march = DateTime(2027, 3, 5);
      expect(policy(pass, march).decide(PremiumFeature.familySharing, trip: italy).allowed, isFalse);
      expect(policy(pass, march).canBuyTripPassFor(italy), isTrue);
    });

    test('is bought for the trip\'s dates as they are', () {
      final bought = newTripPassFor(orlando);
      expect(bought.tripId, 'orlando');
      expect((bought.start, bought.end), (d(10, 12), d(10, 18)));
    });

    test('can only be bought for a dated trip that has not ended', () {
      expect(policy(Entitlements.none).canBuyTripPassFor(orlando), isTrue);
      expect(policy(Entitlements.none).canBuyTripPassFor(paris), isFalse);
      expect(policy(Entitlements.none).canBuyTripPassFor(null), isFalse);
      expect(policy(pass).canBuyTripPassFor(orlando), isFalse);
    });

    test('covers trips of up to 30 days; longer ones are offered Plus', () {
      final month = TripPlan(trip('month', plannedStart: d(10, 20), plannedEnd: d(11, 18)), const []);
      final longer = TripPlan(trip('longer', plannedStart: d(10, 20), plannedEnd: d(11, 19)), const []);
      expect(month.dayCount, 30);
      expect(policy(Entitlements.none).canBuyTripPassFor(month), isTrue);
      expect(policy(Entitlements.none).isTooLongForTripPass(month), isFalse);
      expect(policy(Entitlements.none).canBuyTripPassFor(longer), isFalse);
      expect(policy(Entitlements.none).isTooLongForTripPass(longer), isTrue);
    });
  });

  group('Plus travels with the trip', () {
    TripPlan stamped(DateTime until) => TripPlan(
      Trip(
        id: 'shared',
        title: 'Shared',
        ownerId: 'organiser',
        memberIds: const ['organiser', 'me'],
        premium: TripPremium(grantedBy: 'organiser', until: until),
        createdAt: now,
        updatedAt: now,
      ),
      const [],
    );

    test('a trip unlocked by its organiser unlocks it for everyone on it', () {
      final decision = policy(
        Entitlements.none,
      ).decide(PremiumFeature.familySharing, trip: stamped(now.add(const Duration(days: 5))));
      expect(decision.allowed, isTrue);
      expect(decision.viaTripPremium, isTrue);
    });

    test('but not once it has lapsed', () {
      expect(policy(Entitlements.none).decide(PremiumFeature.familySharing, trip: stamped(now)).allowed, isFalse);
    });
  });

  test('trips never write the server-only premium field', () {
    expect(trip('x').toJson().containsKey('premium'), isFalse);
    final read = Trip.fromJson('x', {
      ...trip('x').toJson(),
      'premium': {'grantedBy': 'u1', 'until': DateTime(2027).millisecondsSinceEpoch},
    });
    expect(read.premium?.grantedBy, 'u1');
  });

  group('price wording', () {
    const plus = Offer(kind: OfferKind.plusAnnual, productId: 'p', amount: 34.99, currencyCode: 'USD');
    const pass = Offer(kind: OfferKind.tripPass, productId: 't', amount: 7.99, currencyCode: 'USD');

    test('frames the annual price per month and per person', () {
      expect(priceOf(plus), r'$34.99');
      expect(perMonth(plus), r'$2.92');
      expect(perPersonPerMonth(plus), r'$0.49');
    });

    test('frames a Trip Pass per day of the trip', () {
      expect(perDay(pass, 7), r'$1.14');
      expect(perDay(pass, 0), r'$7.99');
    });
  });
}
