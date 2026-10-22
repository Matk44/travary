# Native Travi onboarding

6 October 2026. First Flutter integration of the approved [story](ONBOARDING_STORY.md) and [full-screen folio direction](ONBOARDING_BOOKING_FOLIO.md). Original browser studies remain as creative history. That first integration reused existing artwork and films. The subsequent optional [pass desk](ONBOARDING_PASS_DESK.md) uses the owner-approved full composition with a text-free atlas, native text/controls and no new film.

## The connected journey

**9 October, native:** sign-in now sits immediately before the pass desk
(see [the native account scene](#native-account-scene--9-october) below).
Steps 8 and 9 below describe the earlier order and are kept as history.

1. **Arrival:** the existing four-second roll-in plays once, then switches to the six-second idle. Destination, existing-booking import, joining a shared holiday when available, and exploring the app are immediately actionable. The settled still remains underneath playback. Reduced motion or video failure uses it directly; backgrounding or opening another route pauses playback.
2. **Destination and dates:** native place/date pickers; the approved landscape fades into view, with finite cream/coral text movement. Departure does not invent a return. “Dates not decided” keeps both dates null and creates a genuine undated holiday.
3. **Booking invitation:** Travi presents the navy folio in the same colourful world. Manual entry and screenshot/PDF import use real application paths; later opens the pass desk without fabricating a booking.
4. **Full-screen folio:** the working page expands and fades into place over 550 ms, with navy binding, brass stitching, cream paper and straight fields. Travi yields the page. Booking type → editor changes fade within the full-screen surface, without a return to the scenic invitation. Native picker access has no animation delay. The existing form retains trip assignment, dates, attachments and conflict handling. An explicitly selected undated onboarding holiday keeps its first booking despite an older overlapping trip.
5. **Flight:** “Find your flight” uses the existing `FlightFinder` and injected `FlightStatusService`. Number plus local departure date queries the server; the selected returned leg fills “Check your flight”. Scheduled departure/arrival dates and airport-local times survive overnight journeys. Manual fallback remains available. A schedule match is not proof of a reservation.
6. **Import:** reading follows the actual Smart Import service, then “Check your booking” review. Several drafts remain available for selection/review. The existing `requirePremium` decision and remaining free allowance apply; manual entry remains available.
7. **Handoff:** successful save returns the actual `SaveResult`, including its booking ID and trip ID. The same saved `BookingCard` arrives on its real departure/check-in day with a finite stamp and proud Travi hop. An attached confirmation stays directly accessible. The [conversion refinement](ONBOARDING_CONVERSION.md), updated by the owner on 8 October, makes “Let’s sort the rest” the single continuation for uncovered holidays and explains the remaining help. The free bypass is removed from this screen. Covered holidays continue to the desk’s ready state.
8. **Pass desk:** “Shall I help with the rest?” keeps the colourful world and introduces proud Travi with two physical passes. Packages, titles/scope and localized prices can come from RevenueCat; the existing coverage policy determines eligibility. All new-holiday continuations, including postponed bookings and Explore, visit this desk. Without a holiday, only Annual can be offered; without known dates, Holiday Pass is ineligible. Back preserves the current onboarding state; free or successful purchase continues through the optional account invitation into the same holiday when one exists. Restore and failure remain actionable. The [approved v2 artwork](mockups/onboarding-pass-desk-v2/README.md) replaces the compact v1 native adaptation. Other premium gates keep the generic paywall.
9. **Optional account folio:** after the pass/free choice, supported cloud guests can sign in with Apple/Google or continue as guests. The purpose is finding their plan on another phone, not granting free premium attachment backup. Demo/signed-in travellers skip it. Back returns to proof; cancellation/failure keeps the holiday. Linking an existing account carries the adopted holiday ID through `AppSession` so its new navigator opens that holiday after loading.

The first native pass animates whole layers and page transitions. It does not yet implement independently rigged eye, hand or wheel acting, a hinged cover, or a folded page corner. These remain shared character/folio refinements, not new country assets.

## Progress and account behaviour

`OnboardingStore` saves destination, date selection, current step, reserved holiday ID, saved booking ID and completion in an account-specific local JSON file. It reserves and flushes the holiday ID before creating the trip, so retrying creation uses that identity. Dates can stay genuinely unknown. A new account has its own setup; returning accounts with existing plans skip first-run setup unless a setup is already in progress.

Booking forms, unsaved imported drafts and selected source files keep the existing route lifetime; they are not persisted across a process kill. Resumption restores the holiday setup and any confirmed booking, not unconfirmed edits. Ordinary demo runs retain the existing home screen; preview runs use an in-memory setup.

## Preview and flight configuration

```sh
flutter run --dart-define=TRAVARY_BACKEND=demo --dart-define=TRAVARY_PREVIEW_ONBOARDING=true
```

The preview creates real in-memory demo holidays/bookings and uses simulated
purchases. Demo authentication and live flight lookup are disabled. It is not
wholly offline: the existing art-catalog refresh can contact Firebase, and
selecting a real Smart Import file uses the cloud import service with its
normal limits. Use manual entry for a local functional test.

The [connected browser walkthrough](mockups/onboarding-workflow-v1/README.md)
puts the approved Bali scenes and latest smoothed pass film in one review
route. It carries example dates and checked booking details into an example
holiday. Imports, flight results and purchases are fixtures; it does not test
native account linking or integrate the new acting films into Flutter.

Cloud mode uses the existing authenticated Firebase callable and server-held AeroDataBox key. Debug builds enable it by default. `--dart-define=TRAVARY_FLIGHT_LOOKUP=true` explicitly enables it in release once the deployment/provider plan is ready; `false` disables lookup and leaves manual flight entry. This integration did not read credentials or call the live provider. Existing authentication, cache and server caps remain in effect. Purchase simulation remains the existing application's configuration. The [RevenueCat catalog](REVENUECAT_OFFER_CATALOG.md) can fetch remote packages/metadata and localized store prices; production purchases, verified claims and entitlement wiring remain separate work.

## Country-first artwork

The [art register](onboarding/DESTINATION_ART_REGISTER.md) still tracks **25 country stages** to create from existing references, plus the selected Bali and Kyoto exceptions. A new city inherits its country's plate. Until one exists, the real destination name stays visible over the neutral workshop. Neither Bali nor Kyoto is used as an entire-country plate.

The first runtime resolver is `lib/logic/onboarding_art.dart`, using the bundled ISO-code map `onboardingCountryStages`. Add an approved country image to `assets/onboarding/` and that map, then update the planning ledger with its actual path, scope and QA. This does not yet add `onboarding_stage` to downloaded art-pack manifests; that contract/delivery remains separate work. No per-country video is required. Asset provenance is in [the bundle README](../assets/onboarding/README.md).

## Verification

The targeted tests exercise real widget routes with an injected flight service: number/date lookup, selected overnight schedule, editable review and actual saved identity. Other checks cover date selection, undated holidays, cancellation/failure, account-isolated storage, retry after failed creation without another holiday, country inheritance and a 320-point phone with 2× text. Existing flight-finder and Smart Import tests also run. This is service integration verification with a controlled response, not a live-provider response test.

The full Flutter suite passed **711 tests** after the undated-assignment fix; the final layout and folio-navigation changes passed all **9 onboarding state/widget tests**. `flutter analyze --no-pub` reports no issues and `git diff --check` is clean. The [native simulator evidence](mockups/onboarding-native-v1/README.md) records actual entrance/idle playback, Bali reveal, manual review, successful save and navigation into that same holiday. Android, physical-device playback, software-keyboard overlap, provider availability and production purchase handling still require their own launch checks.

The subsequent pass-desk run passed **40 targeted tests** covering onboarding routes, current saved identity, offer/coverage rules, purchase cancellation/failure, restore and large text. Analysis remains clean. [New native captures](mockups/onboarding-pass-desk-v1/README.md) show both selections, Back preservation and free navigation into the actual holiday. Purchase outcomes were tested with a controlled service; production billing was not exercised.

The owner-approved v2 revision replaces the compact adaptation with the full
scenic composition and native text/control overlays. Its full suite passed
**734 tests** with clean analysis. Remote catalog tests cover changing
packages, pass names/scope, localized prices, removal and loading/failure;
production billing remains simulated. [Current evidence and layout](mockups/onboarding-pass-desk-v2/README.md)
and [RevenueCat configuration](REVENUECAT_OFFER_CATALOG.md).

The 7 October conversion iteration passed **745 full-suite tests**, **12
real-font onboarding widget checks**, and clean analysis. [Saved references](mockups/onboarding-conversion-v1/README.md)
show the actual native booking-success → approved pass-desk → same free holiday
walkthrough, plus controlled-service widget renders of import proof and optional
account linking. Existing-account adoption, cancellation/failure/retry and guest
continuation are tested; no live auth or production billing result is claimed.

8 October: the owner approved the first-booking handoff still board and
authorized motion. The [Scene Studio acting review](mockups/onboarding-booking-handoff-v1/MOTION_QA_v1.md)
now demonstrates a controlled folio withdrawal, Travi's corner-pat reaction,
and a pass presentation triggered by an explicit tap. These are opaque Bali
review films with live browser example text, not a new Flutter integration or
shared transparent character media. Native first-booking/day identity and
RevenueCat behavior remain as above; do not claim the new acting ships yet.

## Owner continuation update — 8 October

Removed “Open my holiday with free” from booking success. Saved proof,
postponed bookings and Explore now reach `OnboardingPassScreen` before setup
completion. The desk owns the free continuation. A dated holiday with no first
booking remains eligible under the actual coverage rules; Explore with no
holiday offers Annual only. Invalid supplied identity remains a safe free
handoff. Already covered holidays show readiness instead of duplicate offers.

The full suite passes 747 tests with one unrelated existing build-number
mismatch (app build 1; pubspec build 2). All 27 onboarding/pass tests pass;
static analysis is clean. The browser paywall film was temporarily removed
because it reframed scenery under fixed tickets, then restored full-frame
with live comparison text deferred until settlement at the owner’s request. The native approved atlas,
remote pricing and existing media bundle are unchanged by that browser fix.

## Native account scene — 9 October

Implemented in Flutter at the owner's request, from the approved
[stills and choreography](ONBOARDING_ACCOUNT_SCENE.md) and
[motion](mockups/onboarding-account-motion-v1/README.md).

- **Order:** proof → “Let’s sort the rest” → optional sign-in → pass desk →
  holiday, as one route (`OnboardingOfferFlow`). Bookings later and Explore
  take the same route. Guests in cloud mode are asked; signed-in travellers
  and demo mode go straight to the desk. Back from either returns to the
  saved booking.
- **Sign-in scene** (`OnboardingAccountScreen`): “Keep your holiday with
  you.” with Apple / Google (the platform's own first) / email, “Continue as
  a guest” and “Signing in is free.” Email is an email and password (“Your
  email and a password.”), starting on a new account, then a waiting state
  (“Check your inbox.”) with “I’ve tapped the link”, resend, a different
  address and guest; an unconfirmed address never claims sign-in
  ([EMAIL_SIGN_IN.md](EMAIL_SIGN_IN.md), 22 Oct 2026).
- **Beats:** signing in shows “Your holiday. Linked to you.” and a “Signed in”
  line while Travi tucks the tag away; a guest's text fades while he puts it
  aside. Both then present the passes and the desk fades in (600 ms). Skip is
  always offered during the beat; cancellation and failure stay on the
  invitation with a message. Playback pauses while Apple's or Google's sheet
  is up, and in the background. Reduced motion shows settled stills.
- **Switching to an existing account** rebuilds the app; `AppSession` carries
  the holiday and `OnboardingGate` opens its pass desk (the “Signed in…”
  message shown on the desk), then the holiday.
- **Films follow the destination.** `onboardingStage` resolves city → Bali /
  Kyoto → country → neutral workshop; the 30 city stages are bundled as WebP
  (5.4 MB). Bali plays the six approved account films
  (`assets/onboarding/films/`, 11 MB, unchanged copies) with live text and
  controls over them. Other places show their own stage with the settled
  Travi and folio, the stage raised or lowered so its floor meets the films'
  floor (`OnboardingStagePlate`); the neutral workshop's painted folio stands
  in for the shared one. The pass desk's other-place layout now uses the same
  alignment as the approved Bali desk (it had been centre-cropping the stage
  and squashing the shared layer). The plan for moving Travi everywhere is the
  green-screen request in
  [ART_REQUESTS_2026-10-09.md](onboarding/ART_REQUESTS_2026-10-09.md).
- **Onboarding completed, on every phone:** finishing onboarding or signing
  in sets `users/{uid}.onboardingCompleted` (rules allow only that field, true,
  with the server's time). The gate skips onboarding for such an account with
  no setup under way on this phone (`logic/onboarding_rules.dart`). “I already
  have an account” on the first screen opens the sign-in sheet.
- **Checks:** 773 Flutter tests and 19 rules tests (emulator) pass; analysis
  and formatting are clean. `test/widget/onboarding_account_layout_test.dart`
  covers Bali, Paris, Tokyo and an unillustrated place at 320/390/430 points
  and 1.6× text (`TRAVARY_ONBOARDING_QA=1` renders them with the real fonts
  into `build/onboarding_account/`). On the iPhone 17 Pro simulator against
  local emulators: Bali → undecided dates → manual stay → proof → entry and
  idle films → guest film → desk → free → the holiday, with
  `onboardingCompleted` written; a relaunch with no local setup and no trips
  went straight home on the flag alone, and without it showed onboarding.
  Not run: Apple/Google/email against production, a physical device, Android,
  real RevenueCat offerings.
