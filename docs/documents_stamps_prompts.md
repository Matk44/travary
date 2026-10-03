# Travary Documents scenic stamps — prompts and measurements

Generated with the built-in ImageGen workflow from the approved
`02-collectible-scenic-stamps.png` concept and the existing Travary paper,
scene, and icon references. Pillow was used only for uniform scaling,
centering, exact canvas sizing, alpha-preserving ink recolouring, splitting
the generated icon sheet, preview composition, and measurement.

## References supplied to ImageGen

- `docs/mockups/documents-themed-v2/02-collectible-scenic-stamps.png`
- `assets/art/attraction/themepark_castle_01_scene.png`
- `assets/art/transport/any_car_01_scene.png`
- `assets/art/common/documents_ticket_01.png`
- `assets/art/icons/flight.png`
- `assets/art/icons/dining.png`
- Each destination's existing `common/trip_postcard.png`

## Stamp-frame prompt set

The final selected frame geometry came from this exact near-square correction
prompt, with the finish sentence changed for each variant:

> Use case: precise-object-edit. Asset type: production scenic postage-stamp
> frame. Image 1 is the approved UI layout showing the desired almost-square
> row stamps; Image 2 is the prior frame to preserve for paper, perforation and
> line quality while correcting shape. Primary request: make one [VARIANT],
> straight-on and isolated on true transparency. CRITICAL SHAPE: this must be
> an ALMOST SQUARE postage stamp, not a landscape ticket. The paper body is
> exactly 1.16 times as wide as it is tall—only sixteen percent wider.
> Visually it should resemble a near-square 8:7 stamp. Make the stamp
> substantially taller than Image 2 while retaining its width. Body edges must
> land near 4% and 96% of canvas width and 4.5% and 95.5% of canvas height,
> with similarly narrow margins on all four sides. Window: a genuinely
> transparent rectangular cutout centered from about 15%–85% of canvas width
> and 16%–84% of canvas height. The window is also almost square, about 1.18:1,
> and completely empty. Perforations: about 16 along top/bottom and 14 along
> left/right, with corner quarter-perforations. Warm cotton fibres and only a
> faint down-right contact shadow. Constraints: genuine alpha outside and in
> window; no scene; no text; no letters; no numbers; no pseudo-text; no
> symbols; no denomination; no logo; no watermark; no background; no
> rotation; no perspective; no crop. Do not repeat the wide proportions of
> Image 2.

Variant finish sentences:

- Classic: `classic warm-ivory paper, regular perforations, and one thin navy #1C2A47 keyline`.
- Airmail: `airmail warm-ivory paper, regular perforations, and two clearly distinct thin keylines: navy outer and coral inner`.
- Vintage: `vintage lightly mustard-toned ivory paper, subtly irregular perforations, and one thin sage keyline`.

Classic and airmail intentionally share the exact same ImageGen-generated
geometry. The classic file was derived from the generated airmail frame by
recolouring only the coral keyline back to warm ivory while preserving alpha.

## Postmark prompt

> Use case: product-mockup. Asset type: shippable Travary date-postmark ink
> overlay. One flat ink colour only, navy #1C2A47, on a genuinely fully
> transparent background, like a slightly worn rubber stamp or letterpress
> print. Tiny breaks and uneven ink density are expressed only as transparency.
> A perfectly round postal date postmark made only of two concentric rings,
> centred and upright. Solid outer ring with outer diameter about 86% of canvas
> and stroke about 3.5% of canvas. Finely dashed inner ring with diameter about
> 72% and stroke about 1%. The entire centre inside the inner ring and the
> entire band between rings are empty apart from the two rings themselves. No
> writing or rim decoration. No gradients, second colour, shadow, text,
> letters, numbers, pseudo-text, logo, watermark, or opaque background.

## Cancellation-lines prompt

The final selected correction prompt was:

> Use case: precise-object-edit. Asset type: production Travary postal
> cancellation-lines overlay. Preserve exactly four parallel lines, their
> current horizontal length, left alignment, three-wave rhythm, even vertical
> spacing, central 35%-height band, worn letterpress alpha texture, navy color,
> and fade to complete transparency near the right edge. Change only stroke
> thickness: make every line approximately 40% of its current thickness,
> delicately thin and crisp. The normalized 1536-pixel-wide production asset
> must have strokes about 9 pixels thick. Keep the four lines separate and do
> not move them closer or farther apart. Genuinely transparent background. No
> circle, text, letters, numbers, bars, shadow, logo, watermark, or extra lines.

## Icon-sheet prompt

> Use case: logo-brand. Asset type: source sheet for six shippable Travary
> booking-kind icons. Images 1 and 2 are strict icon style, weight, grain, and
> rounded-corner references; Image 3 shows the approved small badge use. One
> flat ink colour only, navy #1C2A47, on a genuinely fully transparent
> background, like a slightly worn rubber stamp or letterpress print. Create
> exactly six separate solid filled silhouette icons arranged in a precise
> 3-column by 2-row grid with very generous, equal transparent spacing and each
> icon fully contained in its own equal cell. Top row: a bed seen from the side
> with one pillow; a horizontal upright admission ticket with semicircle
> notches and a small row of punched perforation dots; a compact car seen from
> the front. Bottom row: a compass with round solid case and bold four-point
> needle; two overlapping theatre masks; a sheet of notepaper with folded
> top-right corner and exactly three short horizontal lines cut out as negative
> space. Match the attached plane and fork/knife: solid filled, never outline,
> rounded, bold, simple at 16 pixels, upright, same visual weight. No cell
> borders, labels, dividers, text, or extra icons.

## Destination-stamp prompt

Shared exact prompt:

> Use case: product-mockup. Asset type: shippable Travary destination header
> postage stamp. Image 1 is the approved UI placement; Image 2 is the classic
> paper stamp frame reference; Image 3 is this destination's existing artwork
> and composition reference; Image 4 is the strict Travary illustration
> palette, screen-print grain, and silhouette reference. A single portrait
> paper postage stamp, physical body exactly 4:5, straight-on, upright and
> centred with a narrow even transparent margin. Warm ivory cotton paper
> #F3ECE2, fine fibres, clean round perforations, one thin navy #1C2A47
> keyline, faint soft contact shadow down-right only. Printed destination
> illustration occupies about 12%–88% of canvas width and 9%–74% of canvas
> height. Below it, a plain warm-ivory rectangular label band from about
> 12%–88% width and 77%–90% height, completely empty for live Flutter text.
> Premium vintage travel-poster screen print: flat layered shapes, soft
> risograph grain, deep teal #1E5B70, navy #1C2A47, coral #E5785B, sage
> #9DB29C, mustard #D7A443, warm cream #F8F4EC. Calm, uncluttered portrait
> composition with a large coral sun and main subject centred. Genuine
> transparent background outside the complete stamp. No words, letters,
> numbers, pseudo-text, country name, denomination, logo, symbols, watermark,
> people, faces, perspective, rotation, curl, or crop.

Destination subject lines:

- Orlando: `a fairytale castle with tall spires among palm trees, reflected in a lagoon`.
- Lake District: `layered green fells around a still lake, one small classic steamer boat, and a dry-stone wall`.
- Kyoto: `a five-storey pagoda among red and sage maple trees, with a vermilion torii gate in the foreground`.
- Paris: `the Eiffel Tower above the Seine, one elegant stone bridge, plane trees along the banks at dusk`.
- Bali: `stepped green rice terraces, a traditional split temple gate, tropical palms, and distant volcanic hills`.

## Measurements

Fractions are measured from the final canvas. Corner alpha is zero for every
file. All postmark, cancellation-line, and icon visible pixels have exact navy
RGB `#1C2A47` (`off_colour_share = 0.0`).

| File | Size | Body (l, t, r, b) | Window (l, t, r, b) | Notes |
|---|---|---|---|---|
| `assets/art/common/documents_stamp_01.png` | 1024×896 | 0.0400, 0.0547, 0.9590, 0.9453 | 0.1387, 0.1741, 0.8604, 0.8270 | Classic; centre alpha 0 |
| `assets/art/common/documents_stamp_02.png` | 1024×896 | 0.0400, 0.0547, 0.9590, 0.9453 | 0.1387, 0.1741, 0.8604, 0.8270 | Airmail; centre alpha 0 |
| `assets/art/common/documents_stamp_03.png` | 1024×896 | 0.0400, 0.0536, 0.9600, 0.9453 | 0.1357, 0.1708, 0.8643, 0.8359 | Vintage; centre alpha 0 |
| `assets/art/common/documents_postmark.png` | 1024×1024 | 0.0703, 0.0762, 0.9307, 0.9248 | — | Exact navy ink |
| `assets/art/common/documents_cancel_lines.png` | 1536×384 | 0.0339, 0.1927, 0.9232, 0.8099 | — | Exact navy ink; 4 lines |
| `assets/art/icons/stay.png` | 1024×1024 | 0.1602, 0.2695, 0.8398, 0.7305 | — | Exact navy ink |
| `assets/art/icons/attraction.png` | 1024×1024 | 0.1602, 0.3018, 0.8398, 0.6982 | — | Exact navy ink; replaces prior icon |
| `assets/art/icons/transport.png` | 1024×1024 | 0.1592, 0.2363, 0.8408, 0.7627 | — | Exact navy ink |
| `assets/art/icons/activity.png` | 1024×1024 | 0.2119, 0.1602, 0.7881, 0.8398 | — | Exact navy ink |
| `assets/art/icons/event.png` | 1024×1024 | 0.1611, 0.2812, 0.8398, 0.7197 | — | Exact navy ink |
| `assets/art/icons/note.png` | 1024×1024 | 0.2178, 0.1602, 0.7822, 0.8398 | — | Exact navy ink |
| `art_packs/sources/city_us_orlando/common/documents_destination_stamp.png` | 1024×1280 | 0.0400, 0.0383, 0.9609, 0.9609 | — | Blank label band |
| `art_packs/sources/region_gb_lake_district/common/documents_destination_stamp.png` | 1024×1280 | 0.0400, 0.0273, 0.9609, 0.9727 | — | Blank label band |
| `art_packs/sources/city_jp_kyoto/common/documents_destination_stamp.png` | 1024×1280 | 0.0391, 0.0312, 0.9600, 0.9688 | — | Blank label band |
| `art_packs/sources/city_fr_paris/common/documents_destination_stamp.png` | 1024×1280 | 0.0400, 0.0398, 0.9600, 0.9594 | — | Blank label band |
| `art_packs/sources/region_id_bali/common/documents_destination_stamp.png` | 1024×1280 | 0.0400, 0.0266, 0.9600, 0.9742 | — | Blank label band |

## Implementation note

The app should draw a booking scene underneath one of the three transparent
stamp windows and draw the stamp frame above it. Place the live booking-kind
icon on a separate small paper badge. The live date belongs inside the empty
postmark centre; place the cancellation-line asset independently so it can be
hidden or faded. Destination names remain live text in the blank label band.
