# Travary booking artwork generation prompts

These are the production prompt rules used for the first reusable booking-art
library. Generation mode: built-in ImageGen, with the original Travary screen
and the appropriate approved shell assets supplied as visual references.

## Palette system

The original teal/coral palette is the universal fallback, not a restriction
for every destination.

- Stable family anchors: navy #1C2A47 and warm cream #F8F4EC.
- Default accents: deep teal #1E5B70, coral #E5785B, sage #9DB29C, and
  mustard #D7A443.
- Destination packs may replace the accent colours with two to four colours
  derived from the destination's landscape, architecture, craft materials,
  season, and time of day.
- Example evening pack: aubergine #6A3F5F, jade #3F7C6B, lantern gold
  #E1B45D, and dusty rose #C96F6B.
- Never derive a destination palette only from its flag.
- Avoid national stereotypes. The texture, print language, negative-space
  rules, typography zones, and navy/cream anchors keep the set recognisably
  Travary.

## Shared fallback style

    Premium Travary vintage travel-poster screen-print illustration: flat
    layered shapes, soft risograph grain, gentle cream-paper texture, limited
    palette of deep teal #1E5B70, navy #1C2A47, coral #E5785B, sage green
    #9DB29C, mustard #D7A443 and warm cream #F8F4EC. Calm, elegant, tactile
    and uncluttered.

## Shared destination-variable style

    Premium Travary vintage travel-poster screen-print illustration: flat
    layered shapes, soft risograph grain, gentle cream-paper texture, calm
    elegant composition and tactile imperfect ink. Preserve Travary navy
    #1C2A47 and warm cream #F8F4EC as anchors, but use the destination pack's
    selected accent colours. The accents should feel intentional and
    noticeably different from the fallback set.

## Scene format block

    Use case: stylized-concept
    Asset type: shippable Flutter booking artwork — featured scene
    Composition/framing: landscape 3:2 full-bleed illustration. Place the main
    subject and strongest detail in the right third. Keep the left 40% calm,
    dark, and low-detail so white Flutter text remains legible. Use a low
    horizon and clear silhouettes at mobile size.
    Constraints: artwork only; no ticket, card, tag, stub, barcode, frame, or
    drop shadow. No text, letters, numbers, pseudo-text, logos, brands,
    watermark, border, people, or faces. No photorealism, 3D render, glossy
    vector gradient, or device mockup.

## Vignette format block

    Use case: stylized-concept
    Asset type: shippable Flutter booking artwork — transparent card vignette
    Composition/framing: square 1:1 transparent PNG. Gather the complete
    vignette in the bottom-right, with density strongest in that corner and
    shapes tapering toward the top-left. Keep generous transparent padding and
    a silhouette readable around 64 pixels.
    Constraints: genuinely transparent background; decorative artwork only;
    no paper rectangle, card, tag, ticket, outer shadow, or full background
    scene. No text, letters, numbers, pseudo-text, logos, brands, watermark,
    border, people, or faces. No photorealism, 3D render, or glossy vector
    gradient.

## Subject prompt set

### flight/any_plane_01

Scene:

    A graceful unbranded passenger aeroplane climbing above layered soft clouds
    toward a large low coral sun, with faint distant land and atmospheric
    cloud bands. Place the plane and strongest clouds in the right third.
    Mood: optimistic early-morning departure, quiet rather than dramatic.

Vignette:

    One small unbranded passenger aeroplane rising diagonally above two layered
    cloud forms, with a restrained coral sun disc and two fine motion arcs.

### stay/tropical_resort_01

Scene:

    An elegant low-rise tropical resort beside a calm lagoon, with airy
    pavilion roofs, palms, hibiscus, a short timber jetty, layered water
    reflections and a large coral sun. Avoid any specific hotel or culture.
    Mood: warm tranquil sunset arrival, premium and restorative.

Vignette:

    A small airy resort pavilion with two palms, a coral hibiscus, layered
    lagoon ripples and a coral sun, without culture-specific ornament.

### attraction/themepark_castle_01

Scene:

    An original fanciful castle with elegant varied spires above palms and
    layered garden foliage, reflected in a calm lagoon beneath a large coral
    sun. Invent a unique silhouette with no resemblance to a trademarked
    castle. Mood: sophisticated golden-hour anticipation.

Vignette:

    One original elegant castle silhouette with varied slender spires, two
    palms, a coral sun and three lagoon reflection strokes. Unique unbranded
    architecture.

### dining/any_bistro_01

Scene:

    An inviting sheltered bistro terrace with one beautifully set table,
    simple plates and glasses, an arched doorway, linen awning, warm pendant
    lanterns and restrained potted greenery. No readable menu or cuisine-
    specific branding. Mood: intimate early-evening reservation.

Vignette:

    A small round set table with two plates, two simple glasses, folded
    napkins, a warm pendant lantern, one arched doorway line and a restrained
    leafy plant. No food specificity and no menu.

### transport/any_car_01

Scene:

    An elegant unbranded vintage-inspired convertible travelling along a
    winding coastal-country road, with layered hills, a glimpse of water,
    slender trees and a large coral sun. No visible driver or licence plate.
    Mood: freedom and gentle golden-hour movement.

Vignette:

    One unbranded vintage-inspired convertible on a single curved road ribbon,
    with a coral sun, two slender trees and three layered hill shapes. No
    visible driver or licence plate.

### activity/any_boat_01

Scene:

    A small unbranded open tour boat gliding through calm water bordered by
    reeds and mangrove-like foliage, with distant low hills, subtle wake lines
    and a large coral sun. No people visible. Mood: quiet discovery at sunset.

Vignette:

    One small unbranded open tour boat on three layered water ripples, with
    reeds, two mangrove-like branches and a restrained coral sun. No people.

### event/any_show_01

Use the destination-variable evening palette.

Scene:

    An elegant grand theatre stage seen from the auditorium, with layered
    aubergine velvet curtains, a jade proscenium arch, warm lantern-gold
    footlights, subtle spotlight beams and abstract stage scenery. Empty
    stage, no performers. Mood: anticipation just before curtain-up.

Vignette:

    An elegant aubergine stage curtain drawn open around a jade proscenium
    arch, three lantern-gold footlights and two restrained spotlight beams.
    Empty stage, no performers.

### note/any_generic_01

Use the destination-variable evening palette.

Scene:

    A completely blank cream paper note pinned to a softly textured aubergine
    travel-board area, accompanied by a small brass compass, one jade leafy
    sprig, a loop of natural twine and two abstract layered paper shapes.
    Mood: thoughtful trip planning, personal and quietly premium.

Vignette:

    One completely blank warm-cream pinned paper note, a small lantern-gold
    brass compass, a jade leafy sprig, a short natural-twine loop and one
    aubergine paper corner. The note contains absolutely no marks.
