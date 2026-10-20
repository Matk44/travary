import '../domain/domain.dart';
import 'access.dart';
import 'formatters.dart';
import 'onboarding_journey.dart';
import 'trip_plan.dart';

/// A pass the traveller has just bought, or restored, on the pass desk. The
/// desk says so and shows the pass's foil badge (`PassBadge`) before handing
/// back to what they were doing. Only ever for a pass that's on: a payment
/// the server hasn't recorded yet keeps the desk's "Payment received" line
/// (`passPendingText`) and is never celebrated.
typedef PassConfirmation = ({OfferKind kind, bool restored});

/// The stage's words once a [kind] of pass is bought, or [restored].
OnboardingWords passConfirmedWords(OfferKind kind, {bool restored = false}) {
  final name = kind == OfferKind.tripPass ? 'Holiday Pass' : 'Annual Pass';
  if (restored) return (text: 'Welcome\n', accent: 'back!', subtitle: 'Your $name is restored.');
  return kind == OfferKind.tripPass
      ? (text: 'Enjoy your\n', accent: 'holiday!', subtitle: 'Your Holiday Pass is on.')
      : (text: 'Every holiday,\n', accent: 'sorted!', subtitle: 'Your Annual Pass is on.');
}

/// What the pass covers now, under its badge: the holiday and how long the
/// Holiday Pass keeps it, or every holiday and when the Annual Pass renews.
/// [plan]: the holiday the desk was opened for; [entitlements]: what the
/// store says is held (it may not have caught up with a purchase yet, so a
/// Holiday Pass falls back to the one just bought for [plan]'s dates).
({String title, String detail}) passCoverageFor(OfferKind kind, {TripPlan? plan, required Entitlements entitlements}) {
  if (kind == OfferKind.plusAnnual) {
    final plus = entitlements.plus;
    if (plus == null) return (title: 'Every holiday', detail: 'For a year, for you and everyone you invite');
    final day = formatDate(LocalDate.fromDateTime(plus.expiresAt.toLocal()));
    return (title: 'Every holiday', detail: plus.willRenew ? 'Renews on $day · cancel anytime' : 'Until $day');
  }
  if (plan == null || !plan.hasDates) return (title: 'This holiday', detail: 'Every booking, for everyone on it');
  final pass = entitlements.tripPasses[plan.id];
  final lastDay = pass == null
      ? newTripPassFor(plan).lastDay
      : tripPassLastDay(pass, plan.start, plan.end) ?? pass.lastDay;
  return (
    title: plan.trip.title,
    detail: '${formatDayMonthRange(plan.start!, plan.end!)} · covered until ${formatDate(lastDay)}',
  );
}
