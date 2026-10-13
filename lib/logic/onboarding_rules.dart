import '../domain/domain.dart';
import '../domain/onboarding.dart';

/// Where the phone's Back button goes from [step], or null from the first
/// screen (where Back leaves the app).
OnboardingStep? stepBackFrom(OnboardingStep step) => switch (step) {
  OnboardingStep.destination => null,
  OnboardingStep.dates => OnboardingStep.destination,
  OnboardingStep.booking => OnboardingStep.dates,
};

/// The dates a first booking's form starts on, from the holiday's own: its
/// first day, and for a stay its last day too (check-out), when it has more
/// than one. Otherwise the form picks its own default (a stay: one night).
({LocalDate? start, LocalDate? end}) firstBookingDates(BookingKind kind, {LocalDate? start, LocalDate? end}) {
  final stays = kind == BookingKind.stay && start != null && end != null && end.isAfter(start);
  return (start: start, end: stays ? end : null);
}

/// Whether first-run setup shows for this account on this phone.
///
/// A setup already under way here resumes, even if the account finished
/// onboarding elsewhere (it may have signed in partway through). Otherwise
/// it shows only to an account that hasn't finished it here, hasn't been
/// through it on any phone ([completedElsewhere]: finished or signed in) and
/// has no plans yet. An unknown [completedElsewhere] (offline on a new
/// phone) falls back to the plans.
bool onboardingNeeded({required OnboardingDraft draft, required bool hasPlans, bool? completedElsewhere}) {
  if (draft.completed) return false;
  if (draft.destination != null) return true;
  return !hasPlans && completedElsewhere != true;
}
