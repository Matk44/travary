# Onboarding conversion decisions

Approved by the owner on 7 October 2026. This is continuing project memory;
read it alongside [the story](ONBOARDING_STORY.md), [native implementation](ONBOARDING_NATIVE.md)
and [approved pass desk](ONBOARDING_PASS_DESK.md).

## The decision

Keep the short, colourful journey with coral ribbed-spinner **Travi**.
Its emotional appeal is strong; the paid-value argument needs practical proof.
Build ownership through a successfully created holiday, not extra questions
whose only purpose is making the traveller invest more effort.

The traveller should reach the offer thinking: **“Travi just sorted my first
confirmation. I want that help with the rest of this holiday.”**

1. Destination and dates make the holiday personal. Unknown dates stay unknown.
2. Promote the first screenshot/PDF import so the traveller experiences useful
   assistance. They check the extracted details before saving. Manual entry,
   later continuation and import-first shortcuts remain valid.
3. Celebrate an actual save: the same booking arrives on its real day, Travi
   reacts proudly, and the original confirmation can be opened when attached.
   A manual booking must not be presented as an AI import.
4. Use the existing success scene to connect this completed job to more
   confirmations, one shared plan and booking-file backup. Do not add a long
   quiz, pretend bookings, fabricated time savings or false trip-readiness percentages.
5. Owner update **8 October 2026**: every new-holiday continuation reaches
   the pass desk, including postponed bookings and “Explore Travary first”.
   “Let’s sort the rest” is the single booking-success continuation; remove
   “Open my holiday with free” there. Keep **“Continue with free” on the desk**.
   Existing pass holders get a ready state without another purchase. Returning
   travellers and joining an organiser’s existing trip keep their entry flow.
   There is no unexpected advance on a timer.
6. Account signup and purchase need separate reasons. **Owner request,
   9 October 2026:** put the account invitation immediately **before** the
   paywall, with Apple/Google/email options and Travi involved. This replaces
   the earlier post-pass placement. The [new account stills and transition](ONBOARDING_ACCOUNT_SCENE.md)
   were approved on 9 October and are now animated in the connected browser
   review. Sign-in remains free and optional in that review so the traveller
   can reach the desk as a guest. Do not
   imply that free sign-in includes premium booking-file backup. Actual native
   placement is still after pass/free and supports Apple/Google only; email is
   a new proposed feature, not an implemented provider.

## Art, copy and commercial constraints

**Explicit owner approval workflow, reaffirmed 7 October 2026:** show generated
still images/keyframes and the proposed creative direction first. The owner
chooses or requests revisions. Only after approval of that scene may its
animation/video be produced. Reusing approved artwork does not imply approval
of new choreography or connecting compositions. The earlier first-booking handoff
rehearsal remains exploration. The owner explicitly approved the subsequent
three-frame still board on **8 October 2026**, authorizing its motion. A new
day-rail composition would still require its own artwork review.

- Keep the approved scenic paywall composition. Pass titles, scope and localized
  prices remain live catalog data; never bake them into artwork or add a fixed “US”.
- The current USD Holiday Pass default is **$14.99**. Annual prices and offers
  follow the catalog rather than being fixed by this conversion work.
- Shared destination plates and native object movement are enough for this
  iteration. No per-destination film library is required. The owner-approved 8 October
  character handoff can be explored as shared acting; opaque Bali films are
  review plates and cannot replace other countries’ native scenery.
- Preserve the approved **Postcard first** route and **Paper words** text motion.
- Controls are usable during motion; reduced motion shows the settled state.
- Bookings/tickets remain reachable on free. Never threaten to delete the
  holiday or imply that a first saved booking completes all holiday planning.
- No trial, charge countdown, invented testimonials or unreleased flight alerts.

## Research and limits

- [Norton, Mochon and Ariely (2012), The IKEA Effect](https://dash.harvard.edu/entities/publication/73120378-ce76-6bd4-e053-0100007fdf3b):
  successful assembly increased valuation in the studied tasks; failed or
  destroyed work did not. Using this to design Travary is a hypothesis,
  not evidence of Travary subscription conversion.
- [Flighty onboarding archive](https://applode.ai/flows/ios/onboarding/flighty/):
  three introductory screens in a capture archived 10 August 2026. It does
  not include the separate flight-entry flow or prove a fixed screen count
  for every user/version.
- [Flighty's first-flight policy](https://flighty.com/help/complimentary-flighty-pro-flight):
  core Pro tracking is automatically available for a first flight, without
  a card or trial activation. Calendar/email/TripIt import is excluded.
- [Mercury's Flighty customer story (15 May 2026)](https://mercury.com/blog/flighty-app-case-study):
  reports over four million users and a profitable, growing business. It does
  not disclose revenue. Do not repeat third-party monthly estimates as verified figures.
- [RevenueCat's ElevenLabs mobile case](https://www.revenuecat.com/customers/how-elevenlabs-hit-1m-arr-in-just-16-days):
  reports $1m ARR in 16 days. ARR is an annualized recurring run rate, not
  money collected in those 16 days. Its established brand and different
  onboarding prevent treating it as an exact Travary benchmark.
- [Applica's Five Minute Journal experiment (23 October 2024)](https://www.revenuecat.com/blog/growth/five-minute-journal-onboarding-redesign-arpu):
  reports 20% higher ARPU after changing personalization, benefits and social
  proof together. It does not isolate onboarding length as the cause.

Short onboarding can support a substantial business. These examples do not
prove that shortness caused the revenue or that our current price will convert.

## Implementation and next checks

8 October: the [connected browser walkthrough](mockups/onboarding-workflow-v1/README.md)
now lets the owner review the approved Bali welcome → dates → full-screen
folio → saved-booking reaction → smoothed pass presentation → example holiday
without switching studies. Checked example booking details survive that route;
later does not fabricate a booking. Imports, flight results and purchases are
controlled examples. This does not change native service integration or ship
the new acting films in Flutter.

9 October: the approved account stills and choreography are animated in
[the account motion review](mockups/onboarding-account-motion-v1/README.md)
and connected before passes in the browser walkthrough. It includes a tag
waiting loop, envelope gesture/waiting loop, cancelled/failed outcome controls
and separate linked/guest desk films. These are visual fixtures; native
placement, email authentication and purchase identity wiring remain pending.

The first iteration uses a finite card arrival/day stamp/Travi hop, an attached
confirmation shortcut, source-aware success copy, a primary offer handoff and
an optional account folio. Existing-account linking must reopen the actual
adopted holiday after the app rebuilds its navigator.

Funnel events distinguish manual/import saves, offer entry, account exposure,
sign-in/cancellation/failure/skip and completion. They contain action types,
not destination names, document contents or booking references.
`state/analytics.dart` still only prints debug events. **No production
analytics collection, conversion result or live billing result is claimed.**

Before a commercial experiment, connect the chosen analytics service and
update the public privacy disclosure before release. Compare purchases and
revenue per new user, first-booking completion, account linking and subsequent
booking activity—not just paywall conversion among exposed users. Measure
refunds/cancellations as well. The stronger success CTA is an initial variant;
compare this desk-first flow against a dismissible offer after proof
when real measurement is available. Keep free access in every variant.

Remaining creative work: a rigged receive/sort/stamp reaction rather than only
whole-pose movement, and an approved interactive Smart Import example for
manual-entry users who have not seen import assistance. Do not represent the
current native hop as independently animated facial/hand acting.

The implemented first iteration and its verification are recorded in
[the native screenshots and widget references](mockups/onboarding-conversion-v1/README.md).

The first-booking character handoff has **owner-approved still direction
(8 October 2026)**: [three keyframes and approval scope](mockups/onboarding-booking-handoff-v1/README.md).
The approved acting studies are generated. The earlier **8 October paywall
fix** removed the film to eliminate fixed-overlay/crop glitches, but the owner
explicitly rejected the resulting static cut: **a smooth actual video handoff
is required**. The review now reuses the approved pass-presentation footage
full-frame. It keeps the proof still underneath until playback, hides live
comparison text while the paper moves, then crossfades its final pose into the
exact approved desk plate. The owner's subsequent request to smooth the
upward jerk is implemented in a **local derivative of the existing footage**:
`pass-presentation-smooth-v2.mp4` (4.35 s, 60 fps), with a softened source seam
and eased hero framing. The final plate blend is now 600 ms and the live offer
group fades in place without translation. Free/Back and Skip animation remain
available. Stills are a reduced-motion/failure fallback, not the default. No
new artwork or remote video generation was commissioned; original footage
and approved art are preserved. Keep this browser polish distinct from
reusable native character delivery. [Checks and processing](mockups/onboarding-booking-handoff-v1/MOTION_QA_v1.md#smooth-pass-landing--8-october).
