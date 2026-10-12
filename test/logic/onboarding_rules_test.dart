import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/onboarding.dart';
import 'package:travary/logic/destinations.dart';
import 'package:travary/logic/onboarding_rules.dart';

void main() {
  const fresh = OnboardingDraft();
  final started = OnboardingDraft(destination: detectPlace('Bali')!.destination, step: OnboardingStep.dates);

  test('a new account with nothing yet sees onboarding', () {
    expect(onboardingNeeded(draft: fresh, hasPlans: false, completedElsewhere: false), isTrue);
  });

  test('an account that finished or signed in on another phone goes straight home', () {
    expect(onboardingNeeded(draft: fresh, hasPlans: false, completedElsewhere: true), isFalse);
  });

  test('plans already there (joined, or from before the flag) go home too', () {
    expect(onboardingNeeded(draft: fresh, hasPlans: true, completedElsewhere: false), isFalse);
    expect(onboardingNeeded(draft: fresh, hasPlans: true), isFalse);
  });

  test('offline on a new phone, the plans decide', () {
    expect(onboardingNeeded(draft: fresh, hasPlans: false), isTrue);
  });

  test('a setup under way on this phone resumes, even after signing in partway', () {
    expect(onboardingNeeded(draft: started, hasPlans: true, completedElsewhere: true), isTrue);
  });

  test('finished on this phone stays finished', () {
    expect(
      onboardingNeeded(draft: started.copyWith(completed: true), hasPlans: false, completedElsewhere: false),
      isFalse,
    );
  });
}
