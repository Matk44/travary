# Account motion review checks — 9 October 2026

This is creative/browser QA, not native authentication, live email, provider,
RevenueCat or production billing verification. The owner's existing review tab
was left intact; checks used separate review tabs.

## Video and playback

- All six sources rendered through local Scene Studio. Full-frame contact
  sheets were inspected before deliveries were connected.
- Six delivery files fully decoded without FFmpeg errors. All are silent
  720×1280 H.264, 60 fps, yuv420p, with fast-start metadata.
- Entry/idle/email deliveries are 3.966667 seconds. Each desk handoff is
  4.35 seconds. The short text-free reel joins entry, one idle and success.
- Source success/guest cuts were detected at 2.708333 / 2.375 seconds. After
  the recorded alignment/dissolve, neither desk delivery had a framing-cut
  detection above FFmpeg scene score 0.10. This is a supporting check, not
  proof of imperceptible motion; dense seam contact sheets were also inspected.
- Invitation and email waiting loops both played with readyState 4, advancing
  currentTime and loop enabled. Separate successful/guest films loaded with
  readyState 4 and advancing time, then settled into live pass controls.
- Settled-stills switching paused both account players and retained controls.
  Skip animation during entry worked. Guest → Continue with free during a
  running handoff immediately reached the same booking with both films paused.
- An immediate email choice while entry was running reached the email loop;
  stale entry callbacks did not resume or pause its replacement.

## Outcome and state checks

- Apple/Google/email are review controls only. Email submission entered an
  explicitly labelled demo waiting state. Opening the demo link with cancelled
  or failed outcomes kept the invitation, message and guest/retry choices.
  Only simulated success started tag-linking acting. No email was sent.
- The standalone guest route played its distinct tag-aside handoff without
  Signed in. Both outcomes landed on the exact approved desk with live
  $14.99 Holiday / $34.99 Annual example text; these are not store responses.
- Connected example PDF: edited **Coral Cove Stay**, 8 November 2026, 15:00,
  Ubud, Bali, survived proof → account → guest → passes → free holiday.
  Reload preserved completion and that same checked booking.
- Unknown dates kept Holiday Pass disabled while Annual remained available.
- Postponing the first booking entered the settled account invitation directly
  without playing card-filing. Email → guest → passes → free finished with
  no fictional booking/date. The invitation/email were reviewed at 320 px;
  a clipped email guest link was fixed by extending the paper surface without
  rescaling the scene. Reload resumed the email view.
- The standalone review's captured console contained no error/warning entries.
  The connected tab retained two unattributed MutationObserver errors without
  a source URL during iframe testing. No MutationObserver is used by these
  review sources; attribution is unconfirmed. The tested navigation and state
  retention completed. This does not establish a clean whole-browser console.
- Seven browser JavaScript sources (including inline scripts) parsed with
  node --check. No Flutter source/test was changed for this motion revision.

## Captures and remaining checks

- [Live invitation and controls](account-invitation-playing-v1.png)
- [320 px direct invitation, no filing](account-320-guest-entry-v1.png)
- [320 px email loop with reachable guest continuation](email-320-playing-v1.png)
- [Success seam contact sheet](account-success-pass-smooth-contact-v1.jpg)
- [Guest seam contact sheet](account-guest-pass-smooth-contact-v1.jpg)

Physical-device decoding, native auth ownership/background interruption,
software keyboard, accessibility/large text, expired-link return, existing UID
adoption and real billing need native/service checks. Browser poster fallback
and reduced-motion handling are implemented; error/media-timeout injection and
OS reduced-motion switching were not separately exercised in this run.
Opaque Bali films remain review assets, not a country-independent character rig.
