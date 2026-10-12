# Travi account motion — 9 October 2026

The owner approved the account invitation, email-link branch and connecting
storyboard on 9 October: **“beautiful!! Love it… let's go with the animation
for it”**. This authorizes motion of those compositions and beats. New creative
directions still require their own still review.

This folder records production preparation, Scene Studio requests and review
deliveries. Approved artwork is in
[the account still folder](../onboarding-account-scene-v1/README.md).
The clips are browser reviews; they do not implement real email authentication
or move the native sign-in route by themselves. All labels/buttons/prices
remain live UI. Existing approved media masters are preserved.

Status: generated, smoothed and connected to the browser review; native wiring
is still pending.

[Try this scene](http://127.0.0.1:55378/onboarding-account-motion-v1/) ·
[Try the whole walkthrough](http://127.0.0.1:55378/onboarding-workflow-v1/)

## Acting and deliveries

- **Entry:** the same checked booking goes into the folio; Travi offers a
  separate identity tag. Four-second source, 3.967-second review delivery.
- **Invitation idle:** gentle blink and tiny tag adjustment; loops until action.
- **Email gesture / idle:** offers an envelope, then waits while the form or
  demo-link waiting state stays usable. Sending a link is not sign-in success.
- **Successful handoff:** tucks the tag into the folio, then presents passes.
- **Guest handoff:** puts the tag aside, then presents the same passes without
  an account-linking celebration. Both handoffs deliver 4.35 seconds.

All six deliveries are silent H.264, 720×1280, 60 fps with fast-start metadata.
`account-animation-reel-v1.mp4` joins entry, one waiting cycle and the successful
handoff for a short text-free creative review. The actual browser has live
headings, provider buttons, forms, status, pass labels and prices.

## Generation and smoothing

Generated using the owner's local **Scene Studio** at port 3717 with its
configured Replicate / `bytedance/seedance-2.0` provider. Each shot used approved
first/last plates and a four-second request, with audio disabled. Scene Studio
saved completed movies locally; original `*-source-v1.mp4` files are preserved.
`requests.json` records exact prompts and `jobs.json` records job IDs/hashes.
`scene_studio_jobs.py` records local API preparation/collection without secrets.

Two built-in imagegen edits removed mockup labels/buttons to create clean plates;
the envelope plate retains identical scene anchors. Exact prompts are in
`PLATE_PROMPTS.json`. No new character/direction was introduced by those edits.

Generated success/guest sources contained framing cuts. `process_videos.py`
uses a 300 ms dissolve and a 64 px vertical compensation eased over 800 ms,
then motion interpolation to 60 fps. The guest delivery uses its own early
acting followed by the **neutral presentation tail** of the success source;
that tail starts after the linking gesture. This removes a floating-ticket
artifact without giving guests a linked-account celebration. All source clips
remain available. `processing.json` records the exact commands and hashes.

The final browser blends each pass film into the exact approved desk poster
for 600 ms while the live controls appear in place. It does not rescale the
film or move the ticket controls. Entry/idle use alternating video elements
so the held frame remains while the next file loads.

## Boundaries and checks

[Recorded QA and screenshots](QA.md). Provider results, email verification and
billing are fixtures. Native account placement and email auth still require
implementation. These opaque Bali review films are not a reusable transparent
rig or country atlas; preserve country-first scenery in production. A small
soft dissolve remains around the source framing correction. Native software
keyboard, process/auth return, physical-device playback and production billing
need their own checks.

Rebuild the standalone HTML with `python3 build_review.py`; the shared JS/CSS
are loaded directly. The connected workflow's builder references them too.
Serve `docs/mockups` using the existing range-aware preview server on 55378.
