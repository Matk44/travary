# First native onboarding preview

6 October 2026. Flutter debug build on iPhone 17 Pro simulator, iOS 26.1, using `TRAVARY_BACKEND=demo` and `TRAVARY_PREVIEW_ONBOARDING=true`. Screenshots were captured directly through native computer-use controls. These are actual app frames, not generated UI mockups.

| Frame | Evidence |
|---|---|
| [Arrival](arrival-ios-v1.png) | Entrance/idle video plays behind immediately actionable destination controls. Travi's pose changed between captures during the idle. |
| [Bali dates](dates-bali-ios-v1.png) | Full colourful landscape, coral spinner, native date actions; return remains disabled until departure is selected. |
| [Booking invitation](booking-invitation-ios-v1.png) | Reused folio and receiving pose; actual remaining free import allowance. |
| [Stay folio](folio-stay-ios-v1.png) | Real editable manual booking form, straight fields and date controls on the full-screen folio. |
| [Saved booking](saved-booking-bali-ios-v1.png) | Confirmed `Lagoon Retreat` demo booking remains in Bali, shown on its actual 6 October day; free holiday continuation and optional pass link. |
| [Actual holiday](holiday-handoff-ios-v1.png) | “Open my holiday” opens the real Bali trip, with the same stay under its real day. |

The native run exposed an undated-holiday assignment edge case: an overlapping older demo holiday could receive the first booking. The editor now preserves an explicitly selected undated onboarding holiday; a regression test covers it. Planned-date conflict behaviour remains covered by the existing boundary tests.

The full suite passed **711 tests** after that fix. Final layout/folio navigation refinements were rechecked with the **9 onboarding state/widget tests**. Static analysis and `git diff --check` are clean.

No live provider or purchase was called. AeroData integration is exercised by the real `FlightFinder`/editor flow with a controlled service response, including overnight arrival, cancellation and failure. The native preview uses in-memory demo bookings. Physical/Android playback and software-keyboard overlap remain device QA; typing worked with the simulator's keyboard input, and scrolling/reachability is covered by widget tests, including 320 points and 2× text.

The invitation and dates captures precede a final 10-pixel copy-spacing adjustment on non-arrival scenes; the saved-booking frame reflects the final day-stamp and copy treatment. The actual native implementation and current limitations are in [ONBOARDING_NATIVE](../../ONBOARDING_NATIVE.md).
