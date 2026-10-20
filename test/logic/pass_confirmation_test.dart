import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/access.dart';
import 'package:travary/logic/onboarding_films.dart';
import 'package:travary/logic/onboarding_journey.dart';
import 'package:travary/logic/pass_confirmation.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  // Lisbon, 1–8 Nov.
  final lisbon = TripPlan(trip('lisbon', title: 'Lisbon', plannedStart: d(11, 1), plannedEnd: d(11, 8)), const []);

  String headline(OnboardingWords words) => '${words.text}${words.accent}'.replaceAll('\n', ' ');

  test('the stage says which pass is on, or that it\'s back', () {
    final holiday = passConfirmedWords(OfferKind.tripPass);
    expect((headline(holiday), holiday.subtitle), ('Enjoy your holiday!', 'Your Holiday Pass is on.'));
    final annual = passConfirmedWords(OfferKind.plusAnnual);
    expect((headline(annual), annual.subtitle), ('Every holiday, sorted!', 'Your Annual Pass is on.'));
    final restored = passConfirmedWords(OfferKind.tripPass, restored: true);
    expect((headline(restored), restored.subtitle), ('Welcome back!', 'Your Holiday Pass is restored.'));
    expect(passConfirmedWords(OfferKind.plusAnnual, restored: true).subtitle, 'Your Annual Pass is restored.');
  });

  test('headlines are as short as the paywall\'s, so they fit the stage on a small phone', () {
    for (final kind in OfferKind.values) {
      for (final restored in [false, true]) {
        final words = passConfirmedWords(kind, restored: restored);
        for (final line in headline(words).split(RegExp(r'(?<=,) |(?<=your) |(?<=Welcome) '))) {
          expect(line.length, lessThanOrEqualTo(14), reason: line);
        }
        expect(words.subtitle!.length, lessThanOrEqualTo(32), reason: 'one line under the headline');
      }
    }
  });

  group('what a Holiday Pass covers', () {
    test('the holiday and how long the pass keeps it, as bought', () {
      final pass = Entitlements(tripPasses: {'lisbon': newTripPassFor(lisbon)});
      expect(passCoverageFor(OfferKind.tripPass, plan: lisbon, entitlements: pass), (
        title: 'Lisbon',
        detail: '1–8 Nov · covered until 15 Nov 2026',
      ));
    });

    test('before the store has caught up, the pass just bought for its dates', () {
      expect(
        passCoverageFor(OfferKind.tripPass, plan: lisbon, entitlements: Entitlements.none).detail,
        '1–8 Nov · covered until 15 Nov 2026',
      );
    });

    test('a pass bought before the flight home was added grows with the holiday', () {
      final bought = Entitlements(
        tripPasses: {'lisbon': TripPass(tripId: 'lisbon', start: d(11, 1), end: d(11, 6))},
      );
      expect(
        passCoverageFor(OfferKind.tripPass, plan: lisbon, entitlements: bought).detail,
        '1–8 Nov · covered until 15 Nov 2026',
      );
    });

    test('no holiday to name: what it gives instead', () {
      expect(passCoverageFor(OfferKind.tripPass, entitlements: Entitlements.none), (
        title: 'This holiday',
        detail: 'Every booking, for everyone on it',
      ));
    });
  });

  group('what an Annual Pass covers', () {
    test('every holiday, and when it renews', () {
      final plus = Entitlements(plus: PlusSubscription(expiresAt: DateTime(2027, 10, 20, 9)));
      expect(passCoverageFor(OfferKind.plusAnnual, plan: lisbon, entitlements: plus), (
        title: 'Every holiday',
        detail: 'Renews on 20 Oct 2027 · cancel anytime',
      ));
    });

    test('or when it ends, once renewing is off', () {
      final ending = Entitlements(plus: PlusSubscription(expiresAt: DateTime(2027, 10, 20, 9), willRenew: false));
      expect(passCoverageFor(OfferKind.plusAnnual, entitlements: ending).detail, 'Until 20 Oct 2027');
    });

    test('before the store has caught up: a year, for everyone they invite', () {
      expect(
        passCoverageFor(OfferKind.plusAnnual, entitlements: Entitlements.none).detail,
        'For a year, for you and everyone you invite',
      );
    });
  });

  test('Travi lifts the pass up, holds it while it\'s shown, then flicks it down and cheers', () {
    final cues = traviCuesForPassConfirmed();
    expect([for (final cue in cues) cue.pose], [TraviPose.passHold, TraviPose.cheer]);
    expect(cues.first.hold, passHoldTime);
    // Films all the way, from the desk where he presents the passes: no dissolves.
    expect([for (final film in traviRoute(TraviPose.present, TraviPose.passHold)!) film.id], ['pass-up']);
    expect([for (final film in traviRoute(TraviPose.passHold, TraviPose.cheer)!) film.id], [passTossFilm]);
    final toss = traviFilms.singleWhere((film) => film.id == passTossFilm);
    expect(toss.handoff, isNotNull, reason: 'the live badge lands on the desk at the handoff');
    expect(traviIdles[TraviPose.cheer], isNotNull, reason: 'he keeps cheering, not frozen');
  });
}
