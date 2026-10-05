# C2 production screen assets — generation prompts

Generated with the built-in ImageGen tool for the implemented C2 design described in `ART_DIRECTION_SCREENS.md`. Scope: three shared images, five ledger/document icons, and three missing navigation icons. Country-pack destination stamps remain listed as the next pack project in the source brief.

## Delivery requirements

- Genuine transparent PNGs, with no text or labels baked into the art.
- The two add-sheet keepsakes are 768×768; the neutral trip postcard is 1536×1024; icons are 1024×1024.
- Neutral postcard continues the existing portrait composition and leaves the upper-right quarter calm for the live luggage tag.
- Icons match the existing navy letterpress set, including approximately one-quarter canvas padding on each side.
- User-visible words and data are drawn by the app. The supplied woven background is unchanged.

## Supplied files and verification

Delivered on **5 October 2026**. All files are RGBA PNGs at the requested
export dimensions. Each has an alpha range starting at 0, a solid subject
(maximum alpha at least 250), transparent corner pixels, and its visible
subject fully inside the canvas. The generated postcard's surrounding
cream RGB pixels have transparent alpha; they are not a background panel.

| Installed file | Export dimensions | Generated source filename |
|---|---|---|
| `assets/art/common/add_snap.png` | 768 × 768 | `exec-b5cd867c-02ff-4c5a-bc15-960d6faed6f3.png` |
| `assets/art/common/add_passport.png` | 768 × 768 | `exec-d21e40c9-06da-43e2-84c5-10ae9bccfc22.png` |
| `assets/art/common/trip_postcard_anywhere.png` | 1536 × 1024 | `exec-c0f6236e-d34e-4a83-bc65-99b1c31fe6ee.png` |
| `assets/art/icons/attach.png` | 1024 × 1024 | `exec-34f32bf6-45c1-4d10-b614-3d71d6c61443.png` |
| `assets/art/icons/invite.png` | 1024 × 1024 | `exec-c216e7fb-fc98-4cfa-836f-96e33cc6a30c.png` |
| `assets/art/icons/clock.png` | 1024 × 1024 | `exec-59efdc64-a65e-4751-8da8-d41334adaa2e.png` |
| `assets/art/icons/passport.png` | 1024 × 1024 | `exec-af22f618-eed8-4519-aae0-2c2f450fa2ff.png` |
| `assets/art/icons/look.png` | 1024 × 1024 | `exec-2b28a8b8-b1bc-43cf-8c43-d146dcce26f5.png` |
| `assets/art/icons/nav_wallet.png` | 1024 × 1024 | `exec-6875020b-6730-4d89-9806-45a331a6c58a.png` |
| `assets/art/icons/nav_profile.png` | 1024 × 1024 | `exec-2c4a4588-13ca-4e23-b9cb-a3c12674dac6.png` |
| `assets/art/icons/nav_add.png` | 1024 × 1024 | `exec-d1219de2-41b3-43be-9f39-11c1d91f4516.png` |

Original outputs are retained under
`/Users/khairofamily/.codex/generated_images/01a10a13-19f2-7802-a976-b446478510b3/`.
ImageGen returned the square source canvases at 1254 × 1254; macOS `sips`
resampled each full canvas to its required export size, preserving alpha.
The postcard was copied at its native 1536 × 1024 size. There was no
cropping, background replacement, or other post-generation art editing.

Visual review confirmed the navy/gold passport, abstract booking print,
neutral postcard composition with calm upper-right sky, and the navy
letterpress icon set. PNG dimensions, alpha, and content bounds were
measured read-only with Pillow.

**Integration check:** `flutter build bundle --debug` passed. All 11
installed paths are present in `build/flutter_assets/AssetManifest.bin`,
and each bundled PNG matches its source file byte-for-byte. The existing
`pubspec.yaml` directory entries and art catalogue discover them without
app-code changes. This verifies the asset bundle; it is not a device
screenshot review of the implemented screens.

## Exact prompts

### `assets/art/common/add_snap.png`

Required export: 768×768, PNG with alpha.

References:
- `docs/mockups/trip-ledger-c2/01-refined-ledger.webp`
- `assets/art/common/countdown_postcard_anywhere.webp`

```text
Illustration for a premium travel app, vintage travel-poster screen-print style: flat layered shapes, soft risograph grain, gentle cream paper texture, limited palette of deep teal #1E5B70, navy #1C2A47, coral #E5785B, sage green #9DB29C, mustard #D7A443 and warm cream #F8F4EC. Calm, elegant and uncluttered. No text, letters, numbers or logos. No people's faces.
Use case: product-mockup. Asset type: one production PNG cutout for the Travary "Snap a booking" shortcut.
Reference image 1 is the approved C2 screen for object construction and palette only; image 2 is a supporting screen-print palette reference. Create ONLY the small keepsake, not the screen or a UI label.
Transparent background PNG, exactly 768 x 768. A polaroid-style instant photo of a printed travel booking: a boarding pass and a hotel confirmation slightly overlapping INSIDE the photo, its white/cream border with a wider bottom edge, a small brass paperclip on the top edge, the photo slightly curled and rotated minus 6 degrees, soft restrained realistic contact shadow. The photo's image is a simple flat lay of the two cream booking documents on a dark teal surface, NOT a scenic holiday photo. The boarding pass is readable as a ticket through a perforated stub and abstract blocks; the confirmation is recognisable through simple ruled lines. Printed details are abstract lines and blocks ONLY, no typography, pseudo-writing, digits, airport codes or logos. Center the complete photo with about one sixth of the canvas empty on every side; object main body approx x17–83%, y17–83%. All shadows contained with clear transparent outer margin. Genuine alpha outside the cutout, no linen, no white backing rectangle, no checkerboard painted into the image. Compact, bold enough to read in a 72px UI square.
```

### `assets/art/common/add_passport.png`

Required export: 768×768, PNG with alpha.

References:
- `docs/mockups/trip-ledger-c2/01-refined-ledger.webp`
- `assets/art/common/countdown_postcard_anywhere.webp`

```text
Illustration for a premium travel app, vintage travel-poster screen-print style: flat layered shapes, soft risograph grain, gentle cream paper texture, limited palette of deep teal #1E5B70, navy #1C2A47, coral #E5785B, sage green #9DB29C, mustard #D7A443 and warm cream #F8F4EC. Calm, elegant and uncluttered. No text, letters, numbers or logos. No people's faces.
Use case: product-mockup. Asset type: one production PNG cutout for Travary "Passport & documents".
Reference image 1 shows the approved small navy passport book and its physical finish. Preserve its recognisable navy booklet and faded gold globe, while removing all cover lettering. Image 2 is supporting palette and grain only.
Transparent background PNG, exactly 768 x 768. A CLOSED passport in deep navy #1C2A47 with a faded gold-foil abstract globe emblem (a simple round latitude/longitude mark, no words or national symbols) and slightly worn corners, rotated 4 degrees clockwise. A small cream insurance card peeks from behind its upper-right edge; only a few short abstract navy rules on the insurance card. One compact keepsake, top-down and mostly flat, no dramatic 3D perspective. A fine understated paper/page edge at right, matte lightly grained cover, soft restrained contact shadow. NO letters, numbers, pseudo-text, flags, national crests or logos. Center the entire book+card with a sixth of the canvas empty on each side; silhouette main extents approx17–83% of canvas. True alpha outside all objects/shadow, no coloured background, linen or white backing. Readable as a small navy passport at 64px canvas size, restrained physical details, not a luxury wallet.
```

### `assets/art/common/trip_postcard_anywhere.png`

Required export: 1536×1024, PNG with alpha.

References:
- `assets/art/common/countdown_postcard_anywhere.webp`
- `docs/mockups/trip-ledger-c2/01-refined-ledger.webp`

```text
Illustration for a premium travel app, vintage travel-poster screen-print style: flat layered shapes, soft risograph grain, gentle cream paper texture, limited palette of deep teal #1E5B70, navy #1C2A47, coral #E5785B, sage green #9DB29C, mustard #D7A443 and warm cream #F8F4EC. Calm, elegant and uncluttered. No text, letters, numbers or logos. No people's faces.
Use case: style-transfer. Asset type: production neutral landscape trip-postcard PNG.
Image 1 is the EXISTING portrait neutral travel postcard, the exact scene/palette/grain reference. Recompose its scene into a landscape companion, not a different destination. Image 2 is the approved C2 app and physical postcard finish.
Transparent PNG, exactly 1536 x 1024, 3:2 LANDSCAPE canvas. One COMPLETE landscape vintage travel postcard, straight-on, flat. Preserve the neutral scene: cream passenger plane ascending diagonally over layered cream/sage clouds at LEFT, a large coral sunset sun near lower-middle, abstract teal hills and a calm sea low in the frame, a few generic navy palms near lower-left. Plane shape and warm screen-print finish should be siblings of the portrait. Keep the upper-right QUARTER quiet clear deep-teal sky for a luggage tag overlay; put all major plane/cloud shapes at left or lower half. No identifiable landmarks, named places, flags, humans, airline branding, letters, numbers, stamps or postmarks. A complete thin DECKLED CREAM PHYSICAL PAPER EDGE around all four sides, with gentle fibres, soft very subtle contact shadow, and EVEN TRANSPARENT MARGIN about4% around the whole postcard. This required physical paper border is an exception to the style block's usual unframed illustration treatment. All four edges and corners must be visible and uncropped. True alpha beyond the paper/shadow; no checkerboard, scattered white pixels, linen or coloured backing. The paper body itself is a landscape 3:2 postcard; keep it broad rather than making a portrait poster on a wide canvas.
```

### `assets/art/icons/attach.png`

Required export: 1024×1024, PNG with alpha.

References:
- `assets/art/icons/nav_today.png`
- `assets/art/icons/nav_trips.png`
- `assets/art/icons/dining.png`

```text
Use case: logo-brand. Asset type: one production letterpress raster UI icon for Travary.
Reference images 1–3 are the EXISTING Travary house, suitcase, and fork/knife icons. Match their navy ink weight, bold filled silhouette, modest rounded corners, light letterpress speckle and canvas padding. Reference exteriors are transparent; do not copy any black display backing.
Transparent background PNG, EXACTLY 1024 x 1024. A SINGLE icon of a single classic paperclip, a bold simple rounded U-loop and return loop, slightly diagonal, with the open negative spaces truly transparent.
One ink colour, navy #1C2A47, with slightly rough printed edges and faint speckle. Bold solid form, not fine wire outline, except necessary internal negative spaces. Readable at 24px UI size, very simple geometry. Center in both axes and leave roughly a QUARTER of the canvas empty on EACH side: overall longest icon extent approx 500–540px, centered near x512,y512. Preserve about50% total transparent canvas width/height like the existing icons. Tiny texture breaks may be alpha holes, not a second ink colour. Entire background and all interior cutouts genuinely transparent. No cream paper, solid background, white or black backing rectangle, box, badge, shadow, gradients, realistic 3D, text, letters, numbers, logo, watermark, extra symbol or decorative scene. Create ONE isolated icon, not a sheet.
```

### `assets/art/icons/invite.png`

Required export: 1024×1024, PNG with alpha.

References:
- `assets/art/icons/nav_today.png`
- `assets/art/icons/nav_trips.png`
- `assets/art/icons/dining.png`

```text
Use case: logo-brand. Asset type: one production letterpress raster UI icon for Travary.
Reference images 1–3 are the EXISTING Travary house, suitcase, and fork/knife icons. Match their navy ink weight, bold filled silhouette, modest rounded corners, light letterpress speckle and canvas padding. Reference exteriors are transparent; do not copy any black display backing.
Transparent background PNG, EXACTLY 1024 x 1024. A SINGLE icon of one person with a round head and solid shoulders/bust, and a small bold plus beside the right shoulder; one person only, no faces.
One ink colour, navy #1C2A47, with slightly rough printed edges and faint speckle. Bold solid form, not fine wire outline, except necessary internal negative spaces. Readable at 24px UI size, very simple geometry. Center in both axes and leave roughly a QUARTER of the canvas empty on EACH side: overall longest icon extent approx 500–540px, centered near x512,y512. Preserve about50% total transparent canvas width/height like the existing icons. Tiny texture breaks may be alpha holes, not a second ink colour. Entire background and all interior cutouts genuinely transparent. No cream paper, solid background, white or black backing rectangle, box, badge, shadow, gradients, realistic 3D, text, letters, numbers, logo, watermark, extra symbol or decorative scene. Create ONE isolated icon, not a sheet.
```

### `assets/art/icons/clock.png`

Required export: 1024×1024, PNG with alpha.

References:
- `assets/art/icons/nav_today.png`
- `assets/art/icons/nav_trips.png`
- `assets/art/icons/dining.png`

```text
Use case: logo-brand. Asset type: one production letterpress raster UI icon for Travary.
Reference images 1–3 are the EXISTING Travary house, suitcase, and fork/knife icons. Match their navy ink weight, bold filled silhouette, modest rounded corners, light letterpress speckle and canvas padding. Reference exteriors are transparent; do not copy any black display backing.
Transparent background PNG, EXACTLY 1024 x 1024. A SINGLE icon of a round clock face showing TEN PAST TEN (10:10), a bold rim and two clear hands pointing roughly up-left toward 10 and up-right toward 2; just four strong hour ticks, no numerals.
One ink colour, navy #1C2A47, with slightly rough printed edges and faint speckle. Bold solid form, not fine wire outline, except necessary internal negative spaces. Readable at 24px UI size, very simple geometry. Center in both axes and leave roughly a QUARTER of the canvas empty on EACH side: overall longest icon extent approx 500–540px, centered near x512,y512. Preserve about50% total transparent canvas width/height like the existing icons. Tiny texture breaks may be alpha holes, not a second ink colour. Entire background and all interior cutouts genuinely transparent. No cream paper, solid background, white or black backing rectangle, box, badge, shadow, gradients, realistic 3D, text, letters, numbers, logo, watermark, extra symbol or decorative scene. Create ONE isolated icon, not a sheet.
```

### `assets/art/icons/passport.png`

Required export: 1024×1024, PNG with alpha.

References:
- `assets/art/icons/nav_today.png`
- `assets/art/icons/nav_trips.png`
- `assets/art/icons/dining.png`

```text
Use case: logo-brand. Asset type: one production letterpress raster UI icon for Travary.
Reference images 1–3 are the EXISTING Travary house, suitcase, and fork/knife icons. Match their navy ink weight, bold filled silhouette, modest rounded corners, light letterpress speckle and canvas padding. Reference exteriors are transparent; do not copy any black display backing.
Transparent background PNG, EXACTLY 1024 x 1024. A SINGLE icon of one CLOSED upright passport booklet, solid rounded book cover with a simple abstract globe cut out as transparent negative space; no page spread, words, flags or national emblems.
One ink colour, navy #1C2A47, with slightly rough printed edges and faint speckle. Bold solid form, not fine wire outline, except necessary internal negative spaces. Readable at 24px UI size, very simple geometry. Center in both axes and leave roughly a QUARTER of the canvas empty on EACH side: overall longest icon extent approx 500–540px, centered near x512,y512. Preserve about50% total transparent canvas width/height like the existing icons. Tiny texture breaks may be alpha holes, not a second ink colour. Entire background and all interior cutouts genuinely transparent. No cream paper, solid background, white or black backing rectangle, box, badge, shadow, gradients, realistic 3D, text, letters, numbers, logo, watermark, extra symbol or decorative scene. Create ONE isolated icon, not a sheet.
```

### `assets/art/icons/look.png`

Required export: 1024×1024, PNG with alpha.

References:
- `assets/art/icons/nav_today.png`
- `assets/art/icons/nav_trips.png`
- `assets/art/icons/dining.png`

```text
Use case: logo-brand. Asset type: one production letterpress raster UI icon for Travary.
Reference images 1–3 are the EXISTING Travary house, suitcase, and fork/knife icons. Match their navy ink weight, bold filled silhouette, modest rounded corners, light letterpress speckle and canvas padding. Reference exteriors are transparent; do not copy any black display backing.
Transparent background PNG, EXACTLY 1024 x 1024. A SINGLE icon of one upright near-square POSTAGE STAMP with a regular perforated edge and a simple rectangular inset cut out as transparent negative space; no lettering, denomination, picture or scene.
One ink colour, navy #1C2A47, with slightly rough printed edges and faint speckle. Bold solid form, not fine wire outline, except necessary internal negative spaces. Readable at 24px UI size, very simple geometry. Center in both axes and leave roughly a QUARTER of the canvas empty on EACH side: overall longest icon extent approx 500–540px, centered near x512,y512. Preserve about50% total transparent canvas width/height like the existing icons. Tiny texture breaks may be alpha holes, not a second ink colour. Entire background and all interior cutouts genuinely transparent. No cream paper, solid background, white or black backing rectangle, box, badge, shadow, gradients, realistic 3D, text, letters, numbers, logo, watermark, extra symbol or decorative scene. Create ONE isolated icon, not a sheet.
```

### `assets/art/icons/nav_wallet.png`

Required export: 1024×1024, PNG with alpha.

References:
- `assets/art/icons/nav_today.png`
- `assets/art/icons/nav_trips.png`
- `assets/art/icons/dining.png`

```text
Use case: logo-brand. Asset type: one production letterpress raster UI icon for Travary.
Reference images 1–3 are the EXISTING Travary house, suitcase, and fork/knife icons. Match their navy ink weight, bold filled silhouette, modest rounded corners, light letterpress speckle and canvas padding. Reference exteriors are transparent; do not copy any black display backing.
Transparent background PNG, EXACTLY 1024 x 1024. A SINGLE icon of one upright DOCUMENT with folded upper-right corner, a bold rounded filled silhouette and exactly two short horizontal transparent rules in its lower half; no wallet or envelope.
One ink colour, navy #1C2A47, with slightly rough printed edges and faint speckle. Bold solid form, not fine wire outline, except necessary internal negative spaces. Readable at 24px UI size, very simple geometry. Center in both axes and leave roughly a QUARTER of the canvas empty on EACH side: overall longest icon extent approx 500–540px, centered near x512,y512. Preserve about50% total transparent canvas width/height like the existing icons. Tiny texture breaks may be alpha holes, not a second ink colour. Entire background and all interior cutouts genuinely transparent. No cream paper, solid background, white or black backing rectangle, box, badge, shadow, gradients, realistic 3D, text, letters, numbers, logo, watermark, extra symbol or decorative scene. Create ONE isolated icon, not a sheet.
```

### `assets/art/icons/nav_profile.png`

Required export: 1024×1024, PNG with alpha.

References:
- `assets/art/icons/nav_today.png`
- `assets/art/icons/nav_trips.png`
- `assets/art/icons/dining.png`

```text
Use case: logo-brand. Asset type: one production letterpress raster UI icon for Travary.
Reference images 1–3 are the EXISTING Travary house, suitcase, and fork/knife icons. Match their navy ink weight, bold filled silhouette, modest rounded corners, light letterpress speckle and canvas padding. Reference exteriors are transparent; do not copy any black display backing.
Transparent background PNG, EXACTLY 1024 x 1024. A SINGLE icon of one PERSON silhouette: round head above solid rounded shoulders and chest, no face, no extra people.
One ink colour, navy #1C2A47, with slightly rough printed edges and faint speckle. Bold solid form, not fine wire outline, except necessary internal negative spaces. Readable at 24px UI size, very simple geometry. Center in both axes and leave roughly a QUARTER of the canvas empty on EACH side: overall longest icon extent approx 500–540px, centered near x512,y512. Preserve about50% total transparent canvas width/height like the existing icons. Tiny texture breaks may be alpha holes, not a second ink colour. Entire background and all interior cutouts genuinely transparent. No cream paper, solid background, white or black backing rectangle, box, badge, shadow, gradients, realistic 3D, text, letters, numbers, logo, watermark, extra symbol or decorative scene. Create ONE isolated icon, not a sheet.
```

### `assets/art/icons/nav_add.png`

Required export: 1024×1024, PNG with alpha.

References:
- `assets/art/icons/nav_today.png`
- `assets/art/icons/nav_trips.png`
- `assets/art/icons/dining.png`

```text
Use case: logo-brand. Asset type: one production letterpress raster UI icon for Travary.
Reference images 1–3 are the EXISTING Travary house, suitcase, and fork/knife icons. Match their navy ink weight, bold filled silhouette, modest rounded corners, light letterpress speckle and canvas padding. Reference exteriors are transparent; do not copy any black display backing.
Transparent background PNG, EXACTLY 1024 x 1024. A SINGLE icon of one bold PLUS SIGN with equal horizontal and vertical arms, thick rounded strokes, perfectly upright and symmetrical.
One ink colour, navy #1C2A47, with slightly rough printed edges and faint speckle. Bold solid form, not fine wire outline, except necessary internal negative spaces. Readable at 24px UI size, very simple geometry. Center in both axes and leave roughly a QUARTER of the canvas empty on EACH side: overall longest icon extent approx 500–540px, centered near x512,y512. Preserve about50% total transparent canvas width/height like the existing icons. Tiny texture breaks may be alpha holes, not a second ink colour. Entire background and all interior cutouts genuinely transparent. No cream paper, solid background, white or black backing rectangle, box, badge, shadow, gradients, realistic 3D, text, letters, numbers, logo, watermark, extra symbol or decorative scene. Create ONE isolated icon, not a sheet.
```
