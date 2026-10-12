import '../domain/onboarding.dart';

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
