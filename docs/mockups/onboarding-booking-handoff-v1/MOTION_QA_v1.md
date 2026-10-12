# Approved handoff — motion review

8 October 2026. Owner-approved board: `still-keyframes-v1.png`.
The approval was “yes, lets move forward...looks awesome”.

## Delivered review

`motion-review-v1.html` is a local, tap-through acting study. Run:

```sh
python3 docs/mockups/onboarding-intro-v1/serve.py --port 55375 --directory docs/mockups/onboarding-booking-handoff-v1
```

Open `http://127.0.0.1:55375/motion-review-v1.html`.
`booking-handoff-study-v1.mp4` is the historical eight-second reel containing
both generated acting beats. It still contains the reframing pass clip; it is
not the corrected active interface. The review waits for a tap after proof.

The byte-range-aware server is required for reliable browser replay/seek.
Scene Studio's media endpoint currently returns a full stream without Range support.

1. Check/edit the example booking and select **Add to my holiday**. The
   interface page layer withdraws over 650 ms. `card-reaction-v1.mp4` plays once:
   Travi fusses with the paper corner, smiles and settles.
2. The example booking name and dates remain live text on the cream card.
   It stays on this proof screen until an action. There is no timed offer jump.
3. Select **Let’s sort the rest**. `pass-presentation-smooth-v2.mp4` plays full-frame:
   Travi files the card, presents his open palm and brings in the blank passes.
   The final video frame blends into `pass-text-free-v1.png` over 600 ms.
   The live offer group fades in over 600 ms after a 120 ms delay, without translation. Free, Back and Skip animation stay available.
4. There is no free bypass on proof. **Continue with free** on the desk carries
   the same example booking onward. Back preserves it. Purchase/restore only open a preview
   notice; no external account, import, save or purchase is performed.

The review's catalog is explicitly example data: USD $14.99 Holiday and
$34.99 Annual. It is not a RevenueCat client. Production already uses the
existing native catalog. No names, booking dates, amounts, currency prefixes
or selection marks are burned into any newly generated film.

## Generation and selection

Built-in imagegen derived three text-free frames from the approved board.
`production-frame-prompts-v1.json` contains exact edit prompts;
`production-frames-v1.json` preserves source paths, hashes and upload names.
Original files and approved board remain unchanged.

The owner's local **Scene Studio** at `/Users/khairofamily/Documents/video_generator`
submitted first/last frames to **ByteDance Seedance 2.0 via Replicate**, using
its configured account. Rendering happened remotely; the local app saved MP4s.
No credentials were printed or changed. Detailed requests/jobs/status and
`video-generation-v1.json` preserve provenance and delivery metadata.

- `save-reaction-source-v1.mp4`: first cinematic pullback experiment. Put
  aside because the oversized folio reshapes and duplicates while closing.
  It is not used by the current review.
- `card-reaction-v1.mp4`: tighter acting replacement, identical first/last
  reference and locked scene. More stable card and background; the interface
  controls folio withdrawal.
- `pass-presentation-v1.mp4`: card filing and open-palm presentation. Its
  reframing conflicted with the earlier fixed-ticket mask. The source remains preserved; the current review uses the locally smoothed
  derivative described below, then blends to the exact plate for live comparison.

All three original outputs: silent H.264, 720 × 1280, 24 fps, 97 frames,
4.041667 seconds. Delivery processing is a lossless faststart remux only.
No reverse/boomerang, fake idle loop, retiming or semantic repair was applied
to those original deliveries. The current smoothed derivative is separate.

## Original review checks, before the paywall correction

These describe the earlier version. Proof/free and pass-film behavior below
is historical; the current checks are recorded in the following section.

- All selected clips decode fully with ffmpeg without errors; JavaScript
  syntax passes Node's parser. Every film has an eight-sample contact sheet
  spanning its performance, plus an extracted final frame.
- Browser card playback reached readyState 4, 720-pixel video width and
  advancing time. It completed at 4.041667 s, kept scene=`proof`, removed
  the withdrawing page and left both offer/free actions available.
- Replay restarted near 0.38 s with playback active. An immediate free
  action during replay paused the video and removed its active layer,
  preserving `Lagoon Retreat` in the example plan.
- Offer playback completed and settled. Holiday/Annual selection updated
  the selection mark and CTA. Browser console had no error/warning entries.
- Edited example `Palm Garden Stay`, 14–15 Nov: proof showed the changed
  name/range and Saturday day label. Free continuation preserved booking
  data. Stills mode uses settled art without waiting for a film.
- A 320 × 900 browser viewport exposed date overflow and ticket-copy
  overlap. Dates now stack; tickets expand with their art crops and larger
  copy areas. Rechecked visually: no overlapping ticket text, both dates
  fit and page scrollWidth was 305 at innerWidth 320. Viewport override reset.
- HTTP Range request returned 206, correct Content-Range and 1024 bytes.

`motion-review-proof-v1.png`, `motion-review-pass-v1.png`,
`review-narrow-v1.png` and `card-reaction-playing-v1.png` are browser evidence.
The narrow screenshot records the expanded ticket layout; it is not an
iPhone simulator capture. No Flutter production code or runtime bundle was
changed, so previous native test results are not presented as video validation.

## Earlier static correction and flow checks — 8 October

This temporary static workaround is superseded by the video restoration below.

The owner reported a wrongly framed paywall before the final still arrived.
The opaque transition changes Travi’s size and scenery under fixed controls;
a clip mask cannot reconcile those compositions. The desk now uses the
approved still from entry, preloads its plate, suppresses the film layer and
replays only native heading/ticket entrance. No media was regenerated.
A new character performance requires approved composition/choreography first.

Browser checks: immediate desk entry and Replay both use
`pass-text-free-v1.png`, with film hidden, paused and inactive. Holiday/Annual
selection updates the CTA. Free continues with the same Lagoon Retreat/date
range; Back returns to proof with one next-help action. At 320 × 900,
scrollWidth is 305 and the plate is fully loaded. Viewport override reset.
[First entry](pass-stable-first-v2.png), [Replay](pass-stable-replay-v2.png),
[narrow view](pass-stable-narrow-v2.png) and
[settled desk](pass-stable-settled-v2.png) are browser captures.

Flutter now routes saved-proof, postponed bookings and Explore through the
pass desk before completion. A dated holiday may buy before a booking; Explore
can offer Annual without inventing a trip. Existing coverage gets a ready
state. Pricing still uses PremiumStore’s current remote catalog.
The full suite passes **747 tests** with one separate pre-existing build-number
mismatch (`visual_profile_test.dart`: app build 1 vs pubspec build 2).
All **27 onboarding/pass tests pass**; analysis reports no issues.
The review’s generated acting remains separate from Flutter runtime media.

## Video handoff restored — 8 October

Owner instruction: “i want a nice video transition though without the glitch”.
The existing approved clip is reused unchanged: silent H.264, 720 × 1280,
4.041667 s. SHA256 remains
`bc7d772870802615106cb4caa4b87c74cdfeb0cbc107b211dd8284ff5cabab31`.

The review keeps the proof plate underneath until the video is playing,
shows the full frame with no hero-region clip, and withholds fixed ticket
labels during motion. Once it ends, the final frame blends to the exact
approved plate over 350 ms; live comparison text enters over 500 ms. The
viewport's hero origin stays fixed when the footer appears. Skip immediately
settles, without crossfading an early character pose behind fixed prices.
Reduced-motion/stills and playback failure use the settled desk instead.

Browser verification: full-frame playback reached readyState 4, video width
720 and advancing time 0.35 s, with clipPath=none and live offers hidden.
Completion reached 4.041667 s, cleared presenting/active state, used the exact
pass plate and exposed both live offers/CTA. Replay and Skip settle correctly.
Free during the movie stops its active layer and preserves Lagoon Retreat,
8–9 Nov. Stills mode exposes the offers immediately. At 320 × 900, the video remains uncropped at 296 × 526.22
CSS pixels, playback advances, and the settled expanded tickets remain
readable. Viewport override reset; the browser log has no warnings/errors. JavaScript parser and
whitespace checks pass. Flutter code and bundled media were not changed by
this restoration, so earlier widget counts remain historical verification.

[Playing](pass-video-playing-v3.png), [settled](pass-video-settled-v3.png),
[narrow playback](pass-video-narrow-v3.png) and
[narrow settled](pass-video-narrow-settled-v3.png)
are browser captures; they are not a newly rendered movie. The existing film
still has generated scene reframing, now displayed as the full transition.
A locked reusable foreground rig/matte remains native production work.

## Smooth pass landing — 8 October

The owner reported an upward jerk as the cards appear. The original has a
hard hero reframe between source frames 68 and 69 (2.875 s), while the paper
is already nearly in place. The old live ticket labels also translated up
12 px on arrival, adding another rise at completion.

The active review now uses **`pass-presentation-smooth-v2.mp4`**. This is a
local FFmpeg derivative, not a new AI generation or a lossless remux. Originals,
approved artwork and the historical eight-second reel remain unchanged.
Processing compensates the first post-cut hero framing, dissolves the seam
for 300 ms, then eases its zoom back to the final framing over 750 ms. The
lower ticket region retains its original geometry. Each side of the cut is
motion-interpolated separately to 60 fps so a large optical-flow warp is not
created across the cut. The brief scene dissolve is intentional; this is
still an opaque review film, not a seamless reusable foreground rig.

Delivery: silent H.264, 720 × 1280, 60 fps, 261 frames, **4.35 s**.
SHA256: `714ee1d5f21703f126c9f21fee328490b948ddc71bb73fe72a2adc6103ba66db`.
[`motion-polish-v2.json`](motion-polish-v2.json) records source/output hashes,
exact FFmpeg arguments, easing, interface timing and verification. The final
browser frame blends to the exact approved plate over 600 ms. The whole
live offer group and CTA fade in place over 600 ms with a 120 ms delay; this
also gently reveals the expanded ticket artwork at narrow widths. There is
no ticket-label translation. Skip still settles immediately; reduced-motion
and stills keep their immediate usable state.

Verification: complete decode passes. Dense landing frames were inspected
for ticket/hand edges and abrupt framing changes. Actual browser playback
used the new file with readyState 4, advancing time and duration 4.35 s;
completion paused it at 4.35 s on the approved plate. Stage origin remained
-57.5 CSS px through completion (the page was scrolled). Offer-group and
ticket transforms are `none`. Replay, immediate Skip, free continuation
during playback and still mode were exercised. Free preserves Lagoon Retreat,
8–9 Nov. At 320 × 900, the new film plays full-frame at 296 × 526.22 CSS px;
scrollWidth equals innerWidth (320), and settled tickets are 96 px high with
readable copy. The viewport override was reset. Browser logs have no errors
or warnings. JavaScript parsing and whitespace checks pass. No Flutter code
or runtime media was changed by this polish.

[Landing frames](pass-landing-contact-v2.png),
[settled regular layout](pass-smooth-settled-v4.png) and
[narrow layout](pass-smooth-narrow-v4.png) are review evidence. These checks
do not claim an iOS/Android runtime integration or final owner approval.

## Production boundary and next step

These are **opaque Bali review films**, not alpha character overlays. Do not
use them behind another destination's label or commission one movie per city.
Production needs a character/prop rig or a validated foreground matte so the
same acting can sit over country stills and native booking cards. Inspect
matte edges, hand/card alignment, end-pose continuity and interruption before
integration; video-on-a-country-background is not equivalent to that work.

Review the acting/timing, then implement it in the existing successful-save
and explicit offer-action paths, with actual SaveResult identity, dynamic
RevenueCat text, reduced motion, background/route pause, decode-failure stills
and immediately usable controls. The visual day-rail placement is still a
separate unapproved composition; this study depicts holding/straightening
the card, not placing it into a rail. Country-first art coverage is unchanged.
