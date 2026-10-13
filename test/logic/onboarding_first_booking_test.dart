import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/domain/onboarding.dart';
import 'package:travary/logic/booking_form_text.dart';
import 'package:travary/logic/onboarding_films.dart';
import 'package:travary/logic/onboarding_journey.dart';
import 'package:travary/logic/onboarding_rules.dart';

import '../helpers.dart';

void main() {
  group("the phone's Back button", () {
    test('steps back through dates and the booking, and leaves from the first screen', () {
      expect(stepBackFrom(OnboardingStep.booking), OnboardingStep.dates);
      expect(stepBackFrom(OnboardingStep.dates), OnboardingStep.destination);
      expect(stepBackFrom(OnboardingStep.destination), isNull);
    });
  });

  group('a first booking starts on the holiday\'s dates', () {
    test('a stay checks in on the first day and out on the last', () {
      final dates = firstBookingDates(BookingKind.stay, start: d(11, 25), end: d(11, 28));
      expect((dates.start, dates.end), (d(11, 25), d(11, 28)));
    });

    test('other kinds start on the first day only', () {
      for (final kind in BookingKind.values.where((k) => k != BookingKind.stay)) {
        final dates = firstBookingDates(kind, start: d(11, 25), end: d(11, 28));
        expect((dates.start, dates.end), (d(11, 25), null), reason: kind.name);
      }
    });

    test('a stay on a one-day or undated holiday leaves the form its own default', () {
      expect(firstBookingDates(BookingKind.stay, start: d(11, 25), end: d(11, 25)).end, isNull);
      expect(firstBookingDates(BookingKind.stay, start: d(11, 25)).end, isNull);
      final undated = firstBookingDates(BookingKind.stay);
      expect((undated.start, undated.end), (null, null));
    });
  });

  group('the form under the heading', () {
    test('only a read booking asks to be checked', () {
      expect(onboardingFormSubtitle(finding: true, checking: false), 'Flight number and the day it leaves.');
      expect(onboardingFormSubtitle(finding: false, checking: true), 'Check the details before adding it.');
      expect(onboardingFormSubtitle(finding: false, checking: false), isNot(contains('Check')));
    });
  });

  group('Travi on the way to the desk', () {
    test('takes out the ID tag only when sign-in is offered', () {
      expect(traviCuesFor(OnboardingBeat.desk).single, (pose: TraviPose.present, hold: Duration.zero, direct: false));
      final skipped = traviCuesFor(OnboardingBeat.desk, signInSkipped: true).single;
      expect(skipped.pose, TraviPose.present);
      expect(skipped.direct, isTrue, reason: 'he dissolves there instead of acting out the sign-in');
    });

    test('the films from the booking to the desk do go through the ID tag', () {
      expect(traviRoute(TraviPose.proud, TraviPose.present)!.map((f) => f.to), [TraviPose.idTag, TraviPose.present]);
    });
  });
}
