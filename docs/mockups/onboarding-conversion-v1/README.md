# Onboarding conversion — first native iteration

7 October 2026. See the approved [conversion decisions](../../ONBOARDING_CONVERSION.md)
and [native flow](../../ONBOARDING_NATIVE.md).

## Actual iPhone simulator captures

These are screenshots of the running Flutter app on iPhone 17 Pro, iOS 26.1,
using the in-memory demo onboarding preview. They reuse the existing artwork;
no new images or films were generated for this iteration.

- [Booking success](native-booking-success.png): a real demo stay saved in
  Bali holiday, its actual check-in day, proud Travi, the remaining paid help,
  primary offer action and explicit free continuation. Opening the card and
  editing the stay returns to this scene with the updated booking.
- [Pass handoff](native-pass-handoff.png): the primary success action opens
  the existing owner-approved pass desk. The test catalog shows $14.99 once
  and $34.99/year, with no fixed “US” prefix. This is simulated billing.
- [Free continuation](native-free-holiday.png): the same Bali holiday opens
  with the same Lagoon Retreat booking. No payment or account was required.

## Actual-widget renders with controlled services

The following images render the Flutter widgets with cached Source Serif 4,
Inter and MaterialIcons fonts, bundled artwork, a 390 × 844 logical-point
viewport and safe-area insets. These are test renders, not simulator screenshots.

- [Manual success](proof-manual.png): manual entry does not claim an import.
- [Imported success](proof-import.png): a saved import exposes its actual
  attached confirmation and source-aware copy. Extraction is controlled test data.
- [Optional account folio](account-optional.png): supported Apple/Google
  sign-in and a guest route. Auth availability is injected; no live login was
  performed. The demo simulator skips this screen because cloud auth is unavailable.

## Verification and limits

The full Flutter suite passed **745 tests**, and `flutter analyze --no-pub`
reported no issues. The real-font render run passed **12 onboarding widget tests**.
Tests cover sign-in cancellation/failure/retry, guest continuation, large text,
confirmation access and reopening the actual adopted holiday after linking an
existing account rebuilds the app navigator.

Travi currently has a finite whole-pose hop/tilt and the real card/date arrive
with native motion. Independently animated facial/hand acting and an interactive
import example for manual-entry users remain the next creative work. Live auth,
production billing, analytics collection and physical-device playback remain
separate release checks.
