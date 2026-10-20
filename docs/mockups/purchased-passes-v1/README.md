# Purchased pass badges — 19 October 2026

Final still artwork selected by the owner on 20 October 2026: retain the original gold Holiday Pass and teal-and-gold Annual Pass after comparing four alternatives. Generated with the built-in image_gen tool. No animation or video was created or approved by this selection.

## Implementation handoff

The final assets below are ready for Claude. Both PNG masters are 1983 × 793 with genuine transparency; use the corresponding WebP files in the app and preserve their aspect ratio. Existing source integration is already present in `lib/design/widgets/pass_badge.dart`, the Today/Trips/trip screens, Profile's Annual Pass card and `AccessPolicy.purchasedPassFor`. Review and continue that integration rather than duplicating it. The selection in this handoff does not imply a new build, install or production billing verification.

## Assets

- PNG master: `art_masters/bundled/art/common/holiday_pass_badge_v1.png`
- PNG master: `art_masters/bundled/art/common/annual_pass_badge_v1.png`
- Bundled WebP: `assets/art/common/holiday_pass_badge_v1.webp`
- Bundled WebP: `assets/art/common/annual_pass_badge_v1.webp`

WebP copies use q88, exact alpha, original dimensions. Never edit the compressed copies.

## Placement and state

- Today: below the date/weather pill, to the right of the holiday subtitle.
- Trips: above the postcard's top-right edge; plain rows carry the badge above their title.
- Trip page: tucked onto the postcard's top-left corner, a little askew (`TripHero.badge`, 20 Oct 2026; it was above the hero at the right, on a row of its own).
- Purchase confirmation: the pass desk shows the bought pass large (up to 250 pt) once the store confirms; see `../pass-purchase-motion-v1/README.md`.
- Profile: active Annual Pass artwork alongside the subscription information.
- These identify the signed-in traveller's active purchases. Annual takes priority over Holiday when both are active; Holiday only appears on its own trip and follows the existing pass date/grace rules.
- A shared trip's server premium stamp has no product type. It continues to grant access but is not labelled as an Annual or Holiday purchase by this UI.
- Free, expired, unclaimed and revoked purchases show no badge. Existing bookings/tickets remain accessible.
- Accessible names and tooltips identify each pass as active; lettering on the physical ticket is raster artwork.

## Actual Flutter screen renders

Run `TRAVARY_PASS_QA=1 flutter test --no-pub test/widget/pass_badge_test.dart` after placing the app's Source Serif 4 and Inter fonts in `build/visual_qa/fonts/` (see `tool/visual_qa.sh`).

The test writes `holiday-today.png`, `holiday-trips.png`, `annual-today.png`, and `annual-trips.png` here using demo data at 20:21 on 19 October 2026 and simulated purchase state. These are real widget renders, not a real charge or a production purchase verification.

## Final prompts

Validation: `flutter analyze --no-pub` clean; all 1,349 Flutter tests passed.
The badge tests also check live purchase/revocation updates and a 320-point
phone at 2× text size. The four saved previews were visually inspected.

### Holiday Pass (generate, transparent background)

```text
Use case: stylized-concept
Asset type: production raster UI badge for Travary, a tactile vintage travel organiser.
Primary request: one beautiful gold foil airplane boarding ticket icon, representing a purchased Holiday Pass.
Scene/backdrop: genuinely transparent background, isolated clean cutout.
Subject: a single horizontal miniature boarding ticket, width about 2.5 times its height, semicircular notches in both short edges, a dotted perforation dividing a small left stub from the main right section. On the left stub one bold embossed airplane silhouette angled slightly upward. Main right section has clear two-line dark navy serif lettering.
Text (verbatim): "HOLIDAY" on the first line and "PASS" on the second. No other text.
Style/medium: exquisite physical travel ephemera, photographed straight-on from above, real reflective gold foil on thick card, subtle foil crinkles and warm hammered texture, gently worn edges, elegant embossed double-line border. Metallic gold ranges from deep amber shadows to pale champagne highlights; navy lettering crisp and large. Luxurious but warm and handmade, compatible with cream linen, paper luggage tags, teal vintage postcards.
Composition/framing: ticket level, flat frontal silhouette, centered and filling most of wide canvas with a small transparent margin. Keep all edges in view. Shallow edge shadow only, no floor.
Constraints: must read as one tiny tangible gold ticket at 110px wide. Strong simple plane, readable large words, clear notch silhouette. Preserve genuine alpha. No background, no decorative scene, no hands, no jewelry, no glitter particles, no sparkle stars, no ribbons, no perspective tilt, no extra typography, no watermark.
```

### Annual Pass (edit of Holiday Pass master, transparent background)

```text
Use case: precise-object-edit
Asset type: matching Annual Pass raster UI badge for Travary.
Input image: the gold HOLIDAY PASS ticket is the edit target and exact shape/material reference.
Primary request: produce its matching Annual Pass variant. Preserve the ticket's dimensions, flat frontal camera, silhouette, semicircular side notches, dotted vertical perforation, embossed airplane on left stub, double-line border, genuine transparent background and sharp clean cutout.
Change only: the interior ticket face becomes rich deep petrol teal with a finely textured vintage paper finish; retain luxurious reflective gold foil on the complete outer border, inset border, left-stub airplane and perforation detailing. Replace the navy HOLIDAY PASS lettering with large warm metallic gold lettering reading "ANNUAL" on the first line and "PASS" on the second in the same bold serif style and placement. Lettering must have strong contrast and remain readable at 110px badge width.
Gold should still be substantial and precious: a gold foil edged ticket with gold plane and gold words against deep teal, visually distinct from the fully gold Holiday Pass.
Text (verbatim): "ANNUAL" and "PASS". No other words.
Constraints: single ticket, same family as input, no rotation, no perspective, no extra marks, no extra props, no background, no watermark, real transparent alpha. Keep every edge visible.
```

