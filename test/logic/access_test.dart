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
  final paris = TripPlan(trip('paris'), [
    booking('p', BookingKind.stay, d(6, 1), tripId: 'paris', endDate: d(6, 4)),
  ]);

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
    final plus = Entitlements(plus: PlusSubscription(expiresAt: now.add(const Duration(days: 10)), inTrial: true));

    test('unlocks everything on every trip, without using free imports', () {
      final decision = policy(plus).decide(PremiumFeature.smartImport);
      expect(decision.allowed, isTrue);
      expect(decision.isFreeUse, isFalse);
      expect(policy(plus).decide(PremiumFeature.familySharing, trip: paris).allowed, isTrue);
      expect(policy(plus).inTrial, isTrue);
    });

    test('stops when it expires', () {
      final later = now.add(const Duration(days: 11));
      expect(policy(plus, later).hasPlus, isFalse);
      expect(policy(plus, later).decide(PremiumFeature.familySharing, trip: orlando).allowed, isFalse);
    });
  });

  group('Trip Pass', () {
    const pass = Entitlements(tripPasses: {'orlando'});

    test('unlocks its own trip only', () {
      expect(policy(pass).decide(PremiumFeature.familySharing, trip: orlando).allowed, isTrue);
      expect(policy(pass).decide(PremiumFeature.familySharing, trip: paris).allowed, isFalse);
    });

    test('lasts until a week after the trip ends', () {
      expect(policy(pass, DateTime(2026, 10, 25, 23, 59)).hasTripPass(orlando), isTrue);
      expect(policy(pass, DateTime(2026, 10, 26, 0, 1)).hasTripPass(orlando), isFalse);
    });

    test('can only be bought for a dated trip that has not ended', () {
      expect(policy(Entitlements.none).canBuyTripPassFor(orlando), isTrue);
      expect(policy(Entitlements.none).canBuyTripPassFor(paris), isFalse);
      expect(policy(Entitlements.none).canBuyTripPassFor(null), isFalse);
      expect(policy(pass).canBuyTripPassFor(orlando), isFalse);
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
      final decision = policy(Entitlements.none).decide(
        PremiumFeature.familySharing,
        trip: stamped(now.add(const Duration(days: 5))),
      );
      expect(decision.allowed, isTrue);
      expect(decision.viaTripPremium, isTrue);
    });

    test('but not once it has lapsed', () {
      expect(
        policy(Entitlements.none).decide(PremiumFeature.familySharing, trip: stamped(now)).allowed,
        isFalse,
      );
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
