# Profile Annual Pass: pleading Travi — 15 October 2026

The owner supplied `approved-travi.png` in this chat and explicitly requested
slight begging animation using the local video generator, followed by Profile
integration. This authorizes this pose's motion; no new scene or transition
was introduced.

## Generation and export

- Local tool: Scene Studio at `127.0.0.1:3717`, the same app used in
  **Plan female hair transformation ad**. Provider: Seedance 2.0 via its
  configured Replicate adapter. One four-second 720p request, no audio.
- Scene Studio job: `376fb8dad179e35e`, seed `15102026`. Full motion prompt,
  frame filenames and settings: [request.json](request.json).
- The supplied transparent artwork was placed on a flat green generator
  frame with FFmpeg; its character design was not regenerated. The same
  frame was supplied as both start and end.
- The returned [source clip](source/plea.mp4) preserves the clasped hands,
  puppy eyes, luggage tag, handle and planted wheels. Motion is a small
  pleading lift, expression change and slow blink.
- [process.py](process.py) uses Travary's existing green-difference key,
  eases into the exact approved pose at both ends, crops all frames to one
  shared transparent region and encodes at 12 fps. A two-second quiet hold
  follows the gesture. [processing.json](processing.json) records the
  dimensions, endpoint and motion measurements.
- Runtime assets: `assets/travi/cameos/films/profile-plea.webp` (943 KB,
  approximately six seconds per loop) and
  `assets/travi/cameos/stills/profile-plea.webp` (the static fallback).
  PNG masters and source video stay here, outside bundled assets.

## Integration

`ProfileTravi` fills the existing 112 × 124 reserved slot in `PlusCard`.
The cream ticket, native text/buttons, compact spacing and paper shadows
are unchanged. On narrow screens and at large text sizes, the decorative
mascot is omitted to keep the controls and copy readable. Annual Pass
holders see their plan information without the pleading upsell.

Reduce Motion selects the approved still without loading the animation.
Flutter's Image pauses its codec under the home tab's existing TickerMode
when Profile is hidden. The decorative art adds no accessibility controls.

## Actual app review

- [iPhone screenshot](iphone-profile-preview.png)
- [Close preview of the Annual Pass animation](annual-pass-preview.mp4)
- [Eight-second recording from the running iPhone simulator](iphone-profile-animation.mp4)
- [Native motion contact sheet](native-motion-review.png)
- [Real-font widget render](profile-widget-render.png)

The native recording confirms the animation plays with transparent edges,
stays clear of the copy/button, and leaves the ticket's soft shadow visible.

## Verification

- iPhone 17 Pro simulator debug build and runtime visual review complete.
- Focused Profile/account/document/reminder suite: **27 tests pass**.
- Full Flutter suite: **1,243 tests pass**.
- Static analysis: no issues; Dart formatting and diff whitespace checks pass.
- Existing small-phone and subscription tests also check that Travi is
  omitted where inappropriate; the new check covers Reduce Motion and
  animation selection beneath a disabled TickerMode.

No purchase, sign-in, reminder toggle or external message was triggered
during the simulator review. Unrelated working-tree changes were retained.
