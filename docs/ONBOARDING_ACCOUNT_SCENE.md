# Travi account scene — 9 October 2026

## Owner request and status

The owner now requests Google, Apple and email sign-in **immediately before
the paywall**, with Travi involved and a smooth connection to neighbouring
scenes. This placement supersedes the earlier post-pass account proposal.
The owner explicitly requested still images and transition direction for
approval before animation. **Owner approved these stills and the connecting
direction on 9 October 2026 and requested animation.** Motion preparation and
generation are recorded in [the motion review](mockups/onboarding-account-motion-v1/README.md).
Runtime authentication/placement remains separate from that creative approval.

[Account invitation](mockups/onboarding-account-scene-v1/account-invitation-v1.png),
[email branch](mockups/onboarding-account-scene-v1/email-link-entry-v1.png), and
[four transition keyframes](mockups/onboarding-account-scene-v1/transition-keyframes-v1.png)
were generated with built-in imagegen. Exact prompts and asset provenance are
in [the still review folder](mockups/onboarding-account-scene-v1/README.md).

## Proposed account invitation

Lead with **“Keep your holiday with you.”** Supporting copy:
**“Sign in to find your plan on another phone.”** This promises account-linked
plans rather than free premium document backup. Signing in remains free and
optional; **Continue as a guest** advances to the same pass desk. On that desk,
**Continue with free** remains available. Cancellation/failure keeps the
holiday and returns to the invitation with retry/guest choices.

Use the same colourful country stage, cream/coral headings and coral ribbed
spinner. Travi offers a cream identity luggage tag next to the navy holiday
folio, with the just-filed booking corner visible. The physical metaphor is
linking that holiday to its traveller. Avoid giant locks, vaults, cloud-upload
graphics or messages suggesting unverified file backup/security guarantees.

Provider controls stay familiar, flat and readable. Apple comes first on iOS;
Google first on Android. Render supported providers only. In production these
are real controls, not baked-in art. Headings, account names, holiday context,
status and prices also remain live UI. The draft's Bali stage is a specific
reference; use the real destination's country plate or neutral fallback.

## Email branch proposal

The requested email option is represented as a **passwordless email-link
proposal**, not an existing feature. Travi offers a small paper envelope;
the scene retains the same folio and scenery. One email field and **“Email me
a sign-in link”** replace the provider choices. Return and guest choices stay
available. The field/form must remain reachable above the software keyboard;
reduce or scroll the decorative hero rather than obscuring the field.

Sending the email would only mean a link was sent, not that sign-in succeeded.
A future sent state must distinguish delivery request, inbox opening, resend,
email correction, expired/invalid link and successful authentication. A link
return must resume the exact holiday before its pass desk. Do not animate
account-linked success while waiting for the user to open the email.

## Proposed transition and acting

1. **Leave booking proof:** on the traveller's continuation, Travi slips that
   same checked booking into the navy folio. For postponed bookings/Explore,
   omit the booking/card-filing claim and bring the invitation in directly.
2. **Invite:** he offers the identity tag and looks to the traveller. Live
   sign-in controls fade in while the decorative action settles. A quiet blink
   and tiny tag adjustment supply a waiting performance.
3. **Actual sign-in success:** he tucks the identity tag into the folio and
   clicks its brass clasp with a proud smile. The board's **“Signed in”** is a
   short inline response to a successful service result, not another question
   or required confirmation screen. Preserve the selected holiday after an
   existing-account UID switch before opening its offer. Guest continuation
   omits this linking claim and receives an equally warm handoff.
4. **Pass desk:** the same folio stays at left; Travi straightens and opens his
   palm towards the passes. Reuse the exact approved desk landing and dynamic
   ticket controls. Keep camera, horizon, hero anchors and crop consistent;
   fade live text in place only after paper settles. Do not stretch a film
   while fixed overlays remain visible. The board is a composition/acting
   proposal, not a pixel-matched replacement atlas or approved production
   endpoint.

Pause motion while native authentication owns the UI or the app backgrounds.
Cancellation/failure must not play a success beat. Reduced motion and playback
failure use the settled invitation/desk. Decorative timing never invents
auth completion or blocks usable controls. Exact timings, loops, entry/exit
keyframes and bridge films are now authorized within this approved direction.
A newly proposed scene or different choreography still requires its own review.

## Actual implementation

9 October: implemented natively before the pass desk; details and checks in
[ONBOARDING_NATIVE.md](ONBOARDING_NATIVE.md#native-account-scene--9-october).
Apple and Google sign-in are live services. Email is the passwordless-link
branch described above, built and tested with a fake service, and hidden
until the project's link domain opens the app
([EMAIL_LINK_SIGN_IN.md](EMAIL_LINK_SIGN_IN.md)). Purchases go through
RevenueCat with the account's Firebase uid, so signing in before the desk
means a pass belongs to the signed-in account from the start. Bali plays the
approved films; other places show their own stage with the settled Travi
until the shared green-screen films exist.
