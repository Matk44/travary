# Profile stationery — 14 October 2026

**15 October refinement:** the owner's depth/spacing correction and styling
of all remaining profile sections are implemented in
[profile-polish-v2](../profile-polish-v2/README.md). That record describes the
current shadows, compact pass spacing and responsive Travi reservation.

The owner approved `profile-travi-still-v1.png` and requested implementation,
keeping their already updated home navigation without its leather strip.
They will animate Travi themselves; the app intentionally leaves his area
empty. The inner Travel documents invitation also uses the passport art.

## Implemented

- Profile heading with coral palm postmark and the approved subtitle.
- Navy-spined account folio with live Apple/Google/email controls where
  supported, plus the existing signed-in and demo states.
- Cream Annual Pass ticket, live remaining import allowance, navy ticket
  button and restore action. Active subscriptions still show their renewal
  or end date; Holiday Pass names are retained.
- Profile's passport pocket opens the existing travel document flow.
- The standalone Travel documents invitation uses the same existing navy
  passport illustration (`assets/art/common/add_passport.png`) on linen.
  Large text and narrow phones put the picture above the copy. Document
  storage, device authentication, number masking and add/edit/delete remain
  on their existing paths.

All labels and controls are native. The paper backgrounds expand using
nine-slice painting. Home navigation changes from the other ongoing work
are preserved; this implementation does not touch the navigation widget.

## Travi delivery and future animation

`travi-pleading-transparent-v1.png` is the separate full-body **1142 × 1377
transparent PNG** for the owner to animate. It has the approved puppy eyes
and clasped hands, without UI, lettering or a speech scrap.

This file is kept outside the app's asset bundle and is not loaded by the
profile. `PlusCard` reserves a genuinely empty `profile-travi-slot` beside
the benefits, approximately 120 × 150 logical points; it flows below them
on narrow phones or at large text sizes. Integrate the owner's animation
there later. No new animation/video has been produced.

## Files and provenance

Built-in `image_gen` produced the character and text-free raster surfaces
from the approved still. Full prompts: [ASSET_PROMPTS.md](ASSET_PROMPTS.md).
The original mockup prompt is in [PROMPT.md](PROMPT.md).

Runtime assets:

- `assets/art/common/profile_account_folio.png` — 1612 × 976, transparent.
- `assets/art/common/profile_annual_pass.png` — 1484 × 1060, transparent.
- `assets/art/common/profile_pass_button.png` — 2172 × 724, transparent.
- `assets/art/common/profile_postmark.png` — 1536 × 1024, transparent.

These are registered as surface slots. The button's transparent margins are
cropped at runtime; no price, content or Travi is painted into its artwork.

## Review captures and checks

Real-font widget renders at 402 × 874 points (iPhone 17 Pro size), and the
document invitation at 320 × 568 with 2× text:

- [Profile](profile-implemented-v1.png).
- [Profile after scrolling to its document pocket](profile-documents-implemented-v1.png).
- [Inner Travel documents screen](travel-documents-implemented-v1.png).
- [Inner screen with large text](travel-documents-large-type-v1.png).

23 focused widget tests pass: profile navigation to the pass desk, the empty
Travi slot, passport invitation navigation, small-phone action reachability,
Annual Pass renewal/restore, account linking/sign-out/delete, document locking,
masking/add/delete, paywall and reminder flows. `flutter analyze --no-pub`
reports no issues. The iOS simulator debug build succeeds. These are local
UI checks; no production purchase or sign-in is claimed.

The full `flutter test --no-pub` suite also passes **1,182 tests**. The
profile checks run both with the normal test font and the app's real fonts.
