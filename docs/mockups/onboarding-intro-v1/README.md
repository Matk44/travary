# Meet Travi — entrance and waiting loop

5 October 2026. The owner approved the coral ribbed spinner and requested an idle loop after his roll-in, followed by work on the intro. The attached Bali/date-screen frame belongs to the later destination reveal. This intro uses the approved destination-neutral departure workshop.

## Review

Open [index.html](index.html) through the included local video server. The running review is at `http://127.0.0.1:55369/`. To reopen later, run `python3 docs/mockups/onboarding-intro-v1/serve.py` from the project root. This server supports byte-range requests for browser video seeking/replay; the original generic Python server did not.

Travi rolls in once, brakes a little eagerly, greets the traveller and enters a repeating idle. The cream headline rises into place with a short word stagger; “off to?” carries the coral accent. It begins after the main wheeled arrival, at 2.45 seconds into the entrance, and becomes still. The destination tag and shortcut links are available immediately. Words and controls are live HTML/CSS, separate from the film.

Opening destination search pauses motion immediately. Cancelling resumes the current clip; confirming a choice keeps motion paused and reports the proposed handoff to destination reveal/dates. Booking and joining links demonstrate interruption and handoff only. No trip is saved, no geocoding is performed and no booking import, invitation or account action occurs. These will use real app flows when the reviewed intro is integrated.

Review controls provide replay, pause/resume and a still version. The prototype honours `prefers-reduced-motion`, uses the settled frame for still/error/autoplay fallback, and pauses video when the document is hidden. The app needs equivalent lifecycle behaviour in Flutter.

## Assets

| File | Use |
|---|---|
| travi-entrance-v1.mp4 | One-time arrival, 4.0417 s / 97 frames |
| travi-entrance-playback-v1.mp4 | Same entrance, losslessly repackaged with faststart for browser playback |
| travi-idle-loop-v1.mp4 | Repeating waiting state, 6 s / 144 frames |
| travi-intro-review-v1.mp4 | Finite review: arrival plus two idle passes, 16.0417 s |
| travi-idle-source-v1.mp4 | Original unmodified 6.0417 s render |
| travi-settled-v1.png | Selected text-free end keyframe |
| empty-stage-v1.png | Matching empty start keyframe |
| entrance-start-v1.png, idle-start-v1.png | Actual rendered-frame posters used by the preview |

All MP4s are silent H.264, 720 × 1280, 24 fps. Although the request used the provider's `adaptive` setting, it returned 9:16. The review maps that artwork into the approved taller screen composition. Production needs a deliberate viewport/crop strategy, device testing and export tuning; these clips are full opaque scenes, not transparent character overlays.

## Performance and loop inspection

The entrance shows a wheeled approach from the left theatre wing, a small braking rock and an eager greeting. The idle includes restrained body/wrist/tag movement, changing open/closed smiles, eye direction and brief cheerful blinks. He returns to an attentive, open-eyed pose; no extended half-lidded expression was selected.

Both clips share the same target pose. Actual entrance end, idle start and idle end frames were extracted and compared visually. The source idle's extra endpoint frame was omitted for the delivered six-second loop. The final-to-first mean RGB difference is 1.7508 on a 0–255 scale; the entrance-to-idle difference is 2.0406. Those are inspection signals, not a guarantee of pixel identity. Fine generated texture and hardware movement remain visible. No dissolve, reversing or boomerang is used to hide the seam.

Contact sheets, face crops and [seam-metrics-v1.json](seam-metrics-v1.json) preserve this review. Browser verification covered actual entrance-to-idle playback, repeating idle, action interruption, selection staying paused, cancellation resuming, replay, still fallback, readable controls and layout at a 320-pixel viewport. Native app performance, battery use, accessibility settings and video-controller handoff remain to be verified during implementation.

## Generation and scope

The keyframes were edited with built-in imagegen. Your local Scene Studio submitted the custom prompts to Seedance 2.0 on Replicate and saved the completed videos locally; rendering used the configured Replicate account remotely. [PROMPTS.md](PROMPTS.md) and the request/job JSON files record the exact inputs and settings without credentials.

After the owner reported replay displaying only endpoint images, the local review was hardened: range-aware serving, a faststart entrance copy, fresh media loading on explicit replay, the active video made visible before playback, and stale play-promise results ignored. Per-frame browser callbacks record presented-frame counters in DOM data attributes for inspection. The original generated clips remain unchanged; no further video generation was used for this repair. The exact cause in the owner's browser was not reproduced conclusively; these repairs address observed serving and playback weaknesses.

This is a concrete intro asset set and local playable prototype. It does not modify Flutter onboarding, existing trip data, purchase flows, prices or the parked launcher icon. The destination landscape still appears only after the traveller chooses a place; later reveal choreography can use existing artwork without generating a movie per destination.
