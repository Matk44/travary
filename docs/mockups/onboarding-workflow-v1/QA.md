# Walkthrough checks — 8 October 2026

This is browser QA of the connected review, not new Flutter test results or
live backend/billing verification. The user-facing tab was left intact when
the owner began testing; later checks used a separate tab/session.

## Checked routes

- Welcome roll-in and idle playback; Bali reveal; departure/return selection.
- Manual Stay: **Lagoon Retreat**, 10 November 2026, 15:30, Canggu Bali,
  within the chosen 8–15 November holiday. The proof retained its checked
  title/date and real example day.
- Example PDF: edited **Frangipani House** carried through saved proof,
  simulated Annual success and final holiday with 8 November, 15:00, Ubud Bali.
  Reload preserved the completed example and selected outcome.
- Simulated purchase cancellation and failure left the example booking and
  free continuation available; success granted only the controlled preview
  result. No store purchase or entitlement was exercised.
- Unknown dates disabled Holiday Pass. Postponing the first booking opened
  the settled desk without a card-filing film, marked the proof as postponed,
  and finished with no fictional booking or holiday dates.
- Example flight: **QF444** returned unavailable. **TV123** on the shown
  8 November fixture date produced the labelled Sydney → Denpasar example.
  Editable review, proof and free completion kept TV123 and 09:20.
- Actual corrected pass film loaded and played after **Let’s sort the rest**:
  `pass-presentation-smooth-v2.mp4`, readyState 4, advancing currentTime,
  duration 4.35 seconds. It settled into the live pass controls.
- Settled-stills switching, back to booking choices and restart were used.
  Separate screenshot checks at 430 and 320 px confirmed reachable controls;
  the width selector also offers 390 px without changing the user's browser
  viewport.

Fresh iframe mounting disposes the previous scene's media and timers. A
detached-frame `postMessage` error found during QA was repaired by assigning
the new frame before insertion, setting its URL before insertion, ignoring
stale load handlers and guarding an absent window. The corrected navigation
was checked separately after reloading the QA tab.
There were no new application-source error/warning logs during that corrected
navigation. Five JavaScript sources (including inline scripts) parsed with
`node --check`; new text files passed a trailing-whitespace check and
`git diff --check` passed. No Flutter code or tests were changed in this revision.

## Captures

- [Connected walkthrough at the beginning](workflow-start.png)
- [Booking invitation](workflow-booking-invite.png)
- [Editable manual review](workflow-review.png)
- [Imported example after simulated Annual completion](workflow-finished.png)
- [Postponed booking / unknown dates at 320 px](workflow-later-small.png)
- [Example flight review at 320 px](workflow-flight-small.png)
- [Smoothed pass video playing at 320 px](workflow-pass-playing.png)

The film itself and its geometry correction are documented in
[motion provenance](../onboarding-booking-handoff-v1/motion-polish-v2.json).
No new generated art or film was used to connect these studies.


## Account scene revision — 9 October 2026

The owner approved the new account stills and choreography. New generated
entry/waiting/email and distinct linked/guest desk handoffs are now connected
before the paywall. [Detailed account motion QA](../onboarding-account-motion-v1/QA.md)
records playback, interruption, outcome and small-screen checks.

Edited example PDF **Coral Cove Stay**, 8 November 2026, 15:00, Ubud Bali,
retained its checked details through the new guest account route, Annual-only
desk for unknown dates, free completion and reload. Postponing bookings entered
the account invitation directly without a card-filing film and completed with
no invented booking. The 320 px email view retained its state after reload;
its guest control now fits by extending the paper surface. Sign-in, email and
purchase outcomes remain fixtures. No native route or service was changed.

The standalone account tab had no captured warnings/errors. The connected
tab recorded two unattributed MutationObserver errors without source URLs;
these sources do not use MutationObserver, and attribution is unconfirmed.
Navigation and state retention completed despite those entries. This revision
does not claim a clean whole-browser console or live authentication.
