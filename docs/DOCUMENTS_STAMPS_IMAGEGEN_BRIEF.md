# Documents stamps: ImageGen asset brief

The art for the "Collectible scenic stamps" Documents design
(`docs/mockups/documents-themed-v2/02-collectible-scenic-stamps.png`),
written for ChatGPT with image generation.

## Before you paste (for you)

1. Start a new ChatGPT chat and attach these six files:
   - `docs/mockups/documents-themed-v2/02-collectible-scenic-stamps.png` (the layout)
   - `assets/art/attraction/themepark_castle_01_scene.png` (illustration style)
   - `assets/art/transport/any_car_01_scene.png` (a scene that will sit in a stamp)
   - `assets/art/common/documents_ticket_01.png` (paper colour and edge quality)
   - `assets/art/icons/flight.png` and `assets/art/icons/dining.png` (icon style)
2. Paste everything below the line.
3. Work batch by batch. When a batch passes its checks, download it before
   starting the next one.
4. Unzip the result at the repo root (the paths match), then send Claude the
   measurements table from `documents_stamps_prompts.md`.

---

# Brief: production art for the Travary Documents screen

You're making production raster assets for Travary, a Flutter travel app
whose interface is built from real-looking paper ephemera. The app draws
**every word and number live** on top of your images and positions
everything by measuring your files, so the files must be exact: the right
size, true transparency, and **no text of any kind**.

**Tools.** Generate every image with **/imagegen**. Use Python (Pillow) to
post-process and check each one: exact canvas size, clean alpha, recolouring
ink and measuring. Never fake transparency (no painted checkerboard, no
white background removed by colour key). If the image tool returns an
opaque background, generate it again with a transparent background.

**The attached references:**
- `02-collectible-scenic-stamps.png` is the approved layout. Take the
  composition and proportions from it, never its pixels. Its baked-in
  words ("TRAVARY EXPLORE MORE", "ORLANDO", the dates) are placeholders
  for live text: none of them appear in your art.
- `themepark_castle_01_scene.png` and `any_car_01_scene.png` show the
  illustration style. The app puts these existing scenes inside your
  stamps, so the stamp frames must suit them.
- `documents_ticket_01.png` shows the paper: warm ivory cotton stock, fine
  fibres, crisp die-cut edge, faint contact shadow.
- `flight.png` and `dining.png` define the icon style exactly.

## Rules for every file

- PNG, RGBA, 8-bit, sRGB, exactly the stated pixel size.
- True transparent background. Only the object and, where stated, its soft
  contact shadow have alpha.
- No letters, numbers, words, pseudo-text, logos, watermarks, signatures,
  country names or stamp denominations.
- Straight on and upright: no perspective, no rotation, no curl, never cut
  off by the canvas edge.
- Calm and restrained. No ornaments, flourishes, stars, glitter or
  gradients beyond what's described.
- Generate a file again rather than repairing it with heavy editing. Resize
  only uniformly (LANCZOS), never stretch one axis.

### Style block (paste before every illustration prompt)

> Illustration for a premium travel app, vintage travel-poster screen-print
> style: flat layered shapes, soft risograph grain, gentle cream paper
> texture, limited palette of deep teal #1E5B70, navy #1C2A47, coral
> #E5785B, sage green #9DB29C, mustard #D7A443 and warm cream #F8F4EC.
> Calm, elegant and uncluttered. No text, letters, numbers or logos. No
> people's faces. No border.

### Paper block (paste before every stamp prompt)

> A single real paper postage stamp photographed straight on, isolated on a
> fully transparent background. Warm ivory cotton paper (#F3ECE2) with very
> fine fibres, crisp clean perforated edges, and a faint soft contact shadow
> down and to the right (no other shadow). Matches the paper of the
> attached ticket reference. No text, numbers, letters, symbols or
> denomination anywhere.

### Ink block (paste before every postmark, line or icon prompt)

> One flat ink colour only, navy #1C2A47, on a fully transparent
> background, like a slightly worn rubber stamp or letterpress print: tiny
> breaks and uneven ink density, expressed only as transparency. No
> gradients, no second colour, no shadow, no text.

---

## Batch 1: the stamp frames (3 files)

The picture window of each stamp is **transparent**. The app draws the
booking's scene underneath the stamp and your frame on top, so the
perforations, border and keyline stay crisp. On a phone a stamp is drawn
about 66 × 57 points (about 200 px wide), so perforations and keylines
must be bold enough to read at that size.

| File | Variant |
|---|---|
| `assets/art/common/documents_stamp_01.png` | **Classic**: clean round perforations, plain warm-ivory border, one thin navy keyline just outside the window |
| `assets/art/common/documents_stamp_02.png` | **Airmail**: same perforations, a quiet double keyline (navy outer, coral inner). No stripes, no words |
| `assets/art/common/documents_stamp_03.png` | **Vintage**: slightly softer, less regular perforations, aged ivory with faint mustard toning near the edges, one thin sage keyline |

**Size:** exactly **1024 × 896** px (landscape, 8:7).

**Geometry** (fractions of the final canvas, left, top, right, bottom). All
three share it so they're interchangeable:

| Part | Target | Tolerance |
|---|---|---|
| Body (perforation tips, alpha > 128) | 0.040, 0.045, 0.960, 0.955 | ± 0.010 |
| Transparent window | 0.150, 0.160, 0.850, 0.840 | ± 0.015 |

That makes the window about 1.18:1. Other requirements:
- About 16 evenly spaced perforations along the long edges and 14 along
  the short ones, with quarter-perforations at the corners, like a real
  stamp.
- Window corners square or very slightly rounded (radius at most 1.5% of
  the width).
- Nothing printed inside the window. It is 100% transparent except for the
  anti-aliased edge.
- The soft shadow stays within the margin, at most 50/255 alpha.

**Prompt** (fill in the variant):

> {Paper block} A landscape postage stamp, slightly wider than tall (about
> 8:7), centred with a small even margin around it. {Variant description}.
> The stamp's centre is an empty rectangular window cut clean through the
> paper, showing the transparent background: about 70% of the stamp's
> width and 68% of its height, centred, with an even ivory border around
> it. Nothing inside the window: no picture, no pattern, no colour.

**Post-process:**
1. Crop to the alpha > 8 bounding box.
2. Scale uniformly so the body (alpha > 128) is 942 px wide.
3. Centre it on a transparent 1024 × 896 canvas.
4. Measure (see Checks). If the window misses its target, generate the
   image again. Don't redraw the window.

## Batch 2: postmark and cancellation lines (2 files)

The live date ("26 / Sep") sits inside the postmark ring, at the left end
of each row. The wavy lines run from the ring towards the stamp. The app
tints both, and fades or hides the lines, so they are separate files.

**`assets/art/common/documents_postmark.png`**, **1024 × 1024**:
- A circular date postmark, centred.
- Outer ring: solid, about 3.5% of the canvas thick, outer diameter 0.86 of
  the canvas.
- Inner ring: finely dashed or dotted, about 1% thick, diameter 0.72.
- **The whole centre inside the inner ring is empty.** Nothing on the rim
  either: no words, dates, stars or bars.

> {Ink block} A round postal date postmark made of two concentric rings:
> a solid outer ring and a finely dashed inner ring. The centre and the
> band between the rings are completely empty. Perfectly round, centred,
> upright.

**`assets/art/common/documents_cancel_lines.png`**, **1536 × 384**:
- Four parallel wavy cancellation lines running left to right, evenly
  spaced across the middle 70% of the height.
- Each line about 9 px thick, with gentle waves (about three full waves
  across).
- Crisp at the left edge, fading to fully transparent by about 92% of the
  width.

> {Ink block} Four parallel horizontal wavy postal cancellation lines,
> evenly spaced, gentle regular waves, starting crisp at the left edge and
> fading out smoothly to nothing towards the right edge.

Generate at 1536 × 1024, then crop to 1536 × 384 centred on the lines.

**Post-process both:**
1. Set every pixel's RGB to exactly #1C2A47 and keep its alpha.
2. Check that the ink is one colour and nothing but the ink has alpha.

## Batch 3: booking-kind icons (6 files)

These sit in a small paper badge on each stamp's corner, and on the
luggage tags of Today's cards, at 14 to 18 points. They must look like
the same hand as the attached `flight.png` and `dining.png`:
- solid filled silhouettes (never outlines);
- rounded, bold, simple shapes;
- faint letterpress grain;
- upright.

| File | Subject |
|---|---|
| `assets/art/icons/stay.png` | a bed seen from the side, with a pillow (a hotel sign) |
| `assets/art/icons/attraction.png` (**replaces the current outlined, tilted ticket**) | an admission ticket, horizontal and upright, solid, with a semicircle notch in each short side and a small row of punched perforation dots |
| `assets/art/icons/transport.png` | a compact car seen from the front, like a road sign |
| `assets/art/icons/activity.png` | a compass: a round case with a four-point needle |
| `assets/art/icons/event.png` | two overlapping theatre masks (comedy and tragedy) |
| `assets/art/icons/note.png` | a sheet of notepaper with a folded top-right corner and three short lines cut out as negative space |

**How to make them match:**
1. Generate all six in **one image**, a 3 × 2 grid with generous space
   between the icons, 1536 × 1024, transparent background:

   > {Ink block} A matching set of six solid silhouette icons in a 3 × 2
   > grid with wide even spacing: {the six subjects, in order}. Exactly the
   > same style, weight and corner rounding as the attached plane and fork
   > and knife icons: filled shapes, not outlines, bold and simple enough
   > to read at 16 pixels, upright.

2. Split the sheet into six files. For each:
   - crop to the ink's alpha > 128 bounding box;
   - scale uniformly so the longest side is 696 px (0.68 of the canvas);
   - centre on a transparent 1024 × 1024 canvas;
   - set RGB to #1C2A47 and keep the alpha.
3. Compare all eight side by side (yours plus flight and dining) on
   #F8F4EC. If one looks heavier, lighter or more detailed than the rest,
   generate it again.

## Batch 4 (optional): destination stamps for the header (5 files)

A larger stamp beside the "Documents" heading for the traveller's current
or next trip. It comes from that destination's art pack, so a trip never
shows another place's stamp.
- It uses the same paper, perforations and keyline as `documents_stamp_01`.
- The illustration is printed on it (no transparent window).
- A blank ivory label band at the bottom takes the live place name.

**Size:** exactly **1024 × 1280** px (portrait, 4:5). Generate at
1024 × 1536, then scale and centre as in Batch 1.

| Part | Target fractions (left, top, right, bottom) |
|---|---|
| Body (perforation tips) | 0.040, 0.035, 0.960, 0.965 |
| Printed illustration | 0.120, 0.090, 0.880, 0.740 |
| Blank label band (plain ivory, nothing on it) | 0.120, 0.770, 0.880, 0.900 |

> {Paper block} A portrait postage stamp (4:5), centred with a small even
> margin, with a printed illustration in its upper three quarters inside a
> thin navy keyline, and a plain empty ivory band below the illustration
> for a label (leave it completely blank). The illustration: {Style block}
> {subject}, composed for a portrait frame, main subject centred, large
> coral sun.

| File | {subject} |
|---|---|
| `art_packs/sources/city_us_orlando/common/documents_destination_stamp.png` | a fairytale castle with tall spires among palm trees, reflected in a lagoon |
| `art_packs/sources/region_gb_lake_district/common/documents_destination_stamp.png` | green fells around a still lake, a small steamer boat, a dry-stone wall |
| `art_packs/sources/city_jp_kyoto/common/documents_destination_stamp.png` | a five-storey pagoda among maple trees, a vermilion torii in the foreground |
| `art_packs/sources/city_fr_paris/common/documents_destination_stamp.png` | the Eiffel Tower above the Seine with a stone bridge and plane trees at dusk |
| `art_packs/sources/region_id_bali/common/documents_destination_stamp.png` | stepped green rice terraces with a split temple gate and palm trees |

## Don't make these (the app draws or already has them)

- The row's paper card, the icon badge's small square, the chevron: drawn
  by the app.
- Stamp scenes: the app crops the existing scenes into the window.
- Any words or numbers, including the dates, place names and the
  "TRAVARY EXPLORE MORE" postmark text in the mockup.

---

## Checks (run on every file before delivering)

```python
from collections import deque
from PIL import Image

NAVY = (0x1C, 0x2A, 0x47)

def measure(path, window=False):
    """Size, corner alpha, body and (for stamp frames) window, as fractions."""
    im = Image.open(path).convert("RGBA")
    W, H = im.size
    alpha = im.getchannel("A")
    a = alpha.load()
    frac = lambda box: tuple(round(v / d, 4) for v, d in zip(box, (W, H, W, H)))
    out = {
        "size": (W, H),
        "corner_alpha": (a[0, 0], a[W - 1, 0], a[0, H - 1], a[W - 1, H - 1]),
        "body": frac(alpha.point(lambda v: 255 if v > 128 else 0).getbbox()),
    }
    if window:
        cx, cy = W // 2, H // 2
        seen, queue = {(cx, cy)}, deque([(cx, cy)])
        x0 = x1 = cx
        y0 = y1 = cy
        while queue:
            x, y = queue.popleft()
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < W and 0 <= ny < H and (nx, ny) not in seen and a[nx, ny] < 250:
                    seen.add((nx, ny))
                    queue.append((nx, ny))
                    x0, x1, y0, y1 = min(x0, nx), max(x1, nx), min(y0, ny), max(y1, ny)
        out["window_centre_alpha"] = a[cx, cy]
        out["window"] = frac((x0, y0, x1 + 1, y1 + 1))
    return out

def ink_check(path, tolerance=6):
    """Share of visible pixels that aren't navy (should be 0 for ink files)."""
    im = Image.open(path).convert("RGBA")
    ink = [p for p in im.getdata() if p[3] > 16]
    off = sum(1 for p in ink if max(abs(p[i] - NAVY[i]) for i in range(3)) > tolerance)
    return {"ink_pixels": len(ink), "off_colour_share": round(off / max(len(ink), 1), 4)}
```

A file passes when:
- **Every file:** exact size; all four corner alphas are 0.
- **Stamp frames:** body and window within tolerance of Batch 1's
  targets; `window_centre_alpha` is 0; the window doesn't leak to the
  outside (its fractions stay inside the body).
- **Postmark, lines and icons:** `off_colour_share` is 0.
- **Every file, by eye:** no letters or numbers anywhere, and no halo on
  a dark background.

## Deliver

1. **`travary_documents_stamps.zip`**, with the files at the paths above
   (`assets/art/...`, `art_packs/sources/...`) so it unzips at the
   project root.
2. **`documents_stamps_prompts.md`** inside the zip, holding:
   - the exact prompts you used;
   - this table, one row per file:

     | File | Size | Body (l, t, r, b) | Window (l, t, r, b) | Notes |
     |---|---|---|---|---|

3. **A preview sheet** (not in the zip):
   - every file on cream #F8F4EC and again on navy #1C2A47 (to show
     halos);
   - one mock row at 3× phone scale: the postmark and lines at the left,
     `documents_stamp_01` with the attached car scene cropped behind its
     window (cover, aligned right of centre), and the new `transport` icon
     on a small paper badge at the stamp's top-right corner.
