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

  test('purchase badges identify active owned passes and never label shared access as a purchase', () {
    final holiday = newTripPassFor(orlando);
    final annual = PlusSubscription(expiresAt: now.add(const Duration(days: 10)));
    final both = Entitlements(plus: annual, tripPasses: {'orlando': holiday});
    expect(policy(Entitlements.none).purchasedPassFor(orlando), isNull);
    expect(policy(both).purchasedPassFor(orlando), OfferKind.plusAnnual);
    expect(policy(both).purchasedPassFor(null), OfferKind.plusAnnual);
    expect(policy(both, now.add(const Duration(days: 11))).purchasedPassFor(orlando), OfferKind.tripPass);
    expect(policy(both, now.add(const Duration(days: 12))).purchasedPassFor(orlando), isNull);
    final justHoliday = Entitlements(tripPasses: {'orlando': holiday});
    expect(policy(justHoliday).purchasedPassFor(orlando), OfferKind.tripPass);
    expect(policy(justHoliday).purchasedPassFor(paris), isNull);
    expect(policy(justHoliday).purchasedPassFor(null), isNull);
    final shared = TripPlan(
      Trip.fromJson('shared', {
        ...trip('shared').toJson(),
        'premium': {'grantedBy': 'another-traveller', 'until': annual.expiresAt.millisecondsSinceEpoch},
      }),
      orlando.bookings,
    );
    expect(policy(Entitlements.none).forTrip(shared).allowed, isTrue);
    expect(policy(Entitlements.none).purchasedPassFor(shared), isNull);
  });

  group('free plan', () {
    test('as many free Smart Imports as the server allows', () {
      final server = RegExp(
        r'FREE_SMART_IMPORTS = (\d+);',
      ).firstMatch(File('functions/src/purchasesLogic.ts').readAsStringSync())!;
      expect(Pricing.freeSmartImports, int.parse(server.group(1)!));
    });

    test('Smart Import has a few free uses, then locks', () {
      expect(policy(Entitlements.none).decide(PremiumFeature.smartImport).freeUsesLeft, 2);
      const used = Entitlements(smartImportsUsed: 2);
      expect(policy(used).decide(PremiumFeature.smartImport).allowed, isFalse);
    });

    test('other premium features are locked', () {
      for (final feature in [
        PremiumFeature.familySharing,
        PremiumFeature.everyBooking,
        PremiumFeature.ticketBackup,
        PremiumFeature.flightAlerts,
      ]) {
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

    test('unlocks its own trip only, and says which (the server checks the same trip)', () {
      expect(policy(pass).decide(PremiumFeature.familySharing, trip: orlando).allowed, isTrue);
      expect(policy(pass).decide(PremiumFeature.smartImport, trip: orlando).tripId, 'orlando');
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

    test('can\'t be carried back to other holidays while it\'s on', () {
      // Bought for a single day far ahead, then the trip is stretched back
      // over everything until then: not covered.
      final far = Entitlements(
        tripPasses: {
          'orlando': TripPass(tripId: 'orlando', start: LocalDate(2027, 12, 31), end: LocalDate(2027, 12, 31)),
        },
      );
      final season = TripPlan(trip('orlando', plannedStart: d(10, 11), plannedEnd: LocalDate(2027, 12, 31)), const []);
      expect(policy(far).hasTripPass(season), isFalse);
      expect(policy(far).decide(PremiumFeature.familySharing, trip: season).allowed, isFalse);

      // Brought forward to before the dates it was bought for: another
      // holiday, which can have a pass of its own.
      final earlier = TripPlan(trip('orlando', plannedStart: d(9, 1), plannedEnd: d(9, 7)), const []);
      expect(policy(pass, DateTime(2026, 8, 20)).hasTripPass(earlier), isFalse);
      expect(policy(pass, DateTime(2026, 8, 20)).canBuyTripPassFor(earlier), isTrue);
      expect(
        tripPassEndsText(newTripPassFor(orlando), d(9, 1), d(9, 7)),
        'Your Holiday Pass is for 12–18 Oct, so it won\'t cover a trip on these dates.',
      );
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

  group('ticket files', () {
    Attachment file(String id, String name, {int size = 100}) =>
        Attachment(id: id, name: name, fileName: '$id.pdf', sizeBytes: size);
    Booking withFiles(String id, List<Attachment> files) => Booking(
      id: id,
      tripId: 'orlando',
      kind: BookingKind.attraction,
      title: id,
      startDate: d(10, 13),
      attachments: files,
      createdAt: now,
      updatedAt: now,
    );

    test('a holiday counts each file once, however many bookings keep it', () {
      final plan = TripPlan(trip('orlando'), [
        withFiles('a', [file('1', 'Park.pdf')]),
        withFiles('b', [file('2', 'Park.pdf')]),
        withFiles('c', [file('3', 'Dinner.png', size: 7)]),
      ]);
      expect(ticketFilesIn(plan), 2);
      expect(ticketFilesIn(plan, except: 'c'), 1);
      expect(ticketFilesIn(plan, except: 'c', also: [file('4', 'Hotel.pdf')]), 2);
      expect(ticketFilesIn(null), 0);
    });

    test('free holidays keep two; a pass or Plus any number; the ones kept stay', () {
      expect(policy(Entitlements.none).canAttachTickets(orlando, kept: 0, adding: 2), isTrue);
      expect(policy(Entitlements.none).canAttachTickets(orlando, kept: 1), isTrue);
      expect(policy(Entitlements.none).canAttachTickets(orlando, kept: 2), isFalse);
      expect(policy(Entitlements.none).ticketFilesLeft(orlando, kept: 5), 0);
      expect(policy(Entitlements.none).canAttachTickets(null, kept: 0), isTrue, reason: 'a new holiday starts empty');
      final pass = Entitlements(tripPasses: {'orlando': newTripPassFor(orlando)});
      expect(policy(pass).ticketFilesLeft(orlando, kept: 9), isNull);
      expect(policy(pass).canAttachTickets(paris, kept: 2), isFalse, reason: 'only on the trip it\'s for');
    });
  });

  group('bookings on a free holiday', () {
    // Lisbon: 1–8 Nov, still to come on 14 Oct.
    TripPlan lisbon(int bookings, {int notes = 0}) => TripPlan(trip('lisbon'), [
      for (var i = 0; i < bookings; i++) booking('b$i', BookingKind.dining, d(11, 1 + i % 8), tripId: 'lisbon'),
      for (var i = 0; i < notes; i++) booking('n$i', BookingKind.note, d(11, 2), tripId: 'lisbon'),
    ]);

    test('a free holiday takes 12 before it starts; adding more needs a pass', () {
      final free = policy(Entitlements.none);
      expect(Pricing.freeBookingsPerHoliday, 12);
      expect(free.bookingsLeft(lisbon(0)), 12);
      expect(free.bookingsLeft(lisbon(11)), 1);
      expect(free.canAddBookings(lisbon(11)), isTrue);
      expect(free.canAddBookings(lisbon(11), adding: 2), isFalse, reason: 'a Smart Import of two');
      expect(free.canAddBookings(lisbon(12)), isFalse);
      expect(
        free.bookingsLeft(lisbon(15)),
        0,
        reason: 'already over (a lower cap, or a pass that ended): never below 0',
      );
    });

    test('notes never count, so they can always be added', () {
      expect(policy(Entitlements.none).bookingsLeft(lisbon(11, notes: 6)), 1);
      expect(bookingsCountedIn(lisbon(3, notes: 2)), 3);
      expect(bookingsCountedIn(null), 0);
      expect(countsTowardsFreePlan(BookingKind.note), isFalse);
      for (final kind in BookingKind.values.where((kind) => kind != BookingKind.note)) {
        expect(countsTowardsFreePlan(kind), isTrue, reason: kind.name);
      }
    });

    test('never blocked once the holiday has started, nor on a new one', () {
      final onTheDay = policy(Entitlements.none, DateTime(2026, 11, 1, 7));
      expect(onTheDay.bookingsLeft(lisbon(20)), isNull);
      expect(onTheDay.canAddBookings(lisbon(20), adding: 5), isTrue);
      expect(policy(Entitlements.none, DateTime(2026, 10, 31, 23, 59)).canAddBookings(lisbon(12)), isFalse);
      expect(policy(Entitlements.none).canAddBookings(null, adding: 30), isTrue, reason: 'a new holiday starts empty');
      final undated = TripPlan(trip('someday'), const []);
      expect(policy(Entitlements.none).bookingsLeft(undated), 12, reason: 'no dates: it hasn\'t started');
    });

    test('a pass, Plus, or Plus travelling with the trip: any number', () {
      final full = lisbon(12);
      expect(policy(Entitlements(tripPasses: {'lisbon': newTripPassFor(full)})).bookingsLeft(full), isNull);
      expect(policy(Entitlements(tripPasses: {'paris': newTripPassFor(paris)})).canAddBookings(full), isFalse);
      final plus = Entitlements(plus: PlusSubscription(expiresAt: now.add(const Duration(days: 30))));
      expect(policy(plus).canAddBookings(full, adding: 40), isTrue);
    });

    test('the number comes from config/freePlan', () {
      final fifteen = AccessPolicy(Entitlements.none, now, limits: const FreePlanLimits(bookingsPerHoliday: 15));
      expect(fifteen.canAddBookings(lisbon(12)), isTrue);
      expect(fifteen.bookingsLeft(lisbon(12)), 3);
      expect(FreePlanLimits.fromJson({'bookingsPerHoliday': 15}).bookingsPerHoliday, 15);
      expect(FreePlanLimits.fromJson({'bookingsPerHoliday': 15.0}).bookingsPerHoliday, 15, reason: 'a console double');
      for (final unlikely in [null, 0, 4, 1001, 12.5, double.infinity, double.nan, '12', true]) {
        expect(
          FreePlanLimits.fromJson({'bookingsPerHoliday': unlikely}),
          FreePlanLimits.defaults,
          reason: '$unlikely keeps the default',
        );
      }
      expect(FreePlanLimits.fromJson(null), FreePlanLimits.defaults, reason: 'no document');
    });

    test('the trip page counts them from 9 of 12', () {
      final free = policy(Entitlements.none);
      expect(free.bookingCountShown(lisbon(8)), isNull);
      expect(free.bookingCountShown(lisbon(9)), 9);
      expect(free.bookingCountShown(lisbon(12, notes: 3)), 12);
      expect(free.bookingCountShown(lisbon(14)), 14);
      expect(policy(Entitlements.none, DateTime(2026, 11, 2)).bookingCountShown(lisbon(10)), isNull, reason: 'started');
      final pass = Entitlements(tripPasses: {'lisbon': newTripPassFor(lisbon(10))});
      expect(policy(pass).bookingCountShown(lisbon(10)), isNull);
    });

    test('worded', () {
      expect(bookingCountText(9, 12), '9 of 12 free bookings used');
      expect(bookingCountText(12, 12), '12 of 12 free bookings used\u00a0· A\u00a0pass\u00a0adds\u00a0more');
      expect(bookingCountText(14, 12), '12 of 12 free bookings used\u00a0· A\u00a0pass\u00a0adds\u00a0more');
      expect(bookingsOverText(0, 12), 'This holiday has its 12 free bookings. A pass makes room for these.');
      expect(
        bookingsOverText(2, 12),
        'Only 2 more fit on this free holiday (12 bookings). Untick some, or get a pass for every one.',
      );
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
