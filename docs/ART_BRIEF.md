# Travary art brief: prompts for GPT image generation

Everything the Today screen needs, in the order to make it. File names matter:
they tell the app which booking each picture belongs to (see "Naming").

## How to work with GPT

1. Start one chat for all Travary art. Upload the v1 mockup and say:
   *"This is the look for a travel app. Every image I ask for must match this
   style exactly. Keep this style for the whole conversation."*
2. Paste the **Style block** in front of every prompt.
3. When one image is right, say *"Use this image as the style reference for
   the rest"* so the set stays consistent.
4. Ask for **PNG**, and **transparent background** where noted.
5. No text in any image. The app adds all words itself.

### Style block (paste before every illustration prompt)

> Illustration for a premium travel app, vintage travel-poster screen-print
> style: flat layered shapes, soft risograph grain, gentle cream paper texture,
> limited palette of deep teal #1E5B70, navy #1C2A47, coral #E5785B, sage
> green #9DB29C, mustard #D7A443 and warm cream #F8F4EC. Calm, elegant and
> uncluttered. No text, letters, numbers or logos. No people's faces. No border.

---

## Batch 1: materials (make these first)

Textures are tiled or stretched behind everything, so they must be quiet.

| File | Size | Prompt |
|---|---|---|
| `common/linen.png` | 1024×1024 | Seamless tileable texture: top-down photo of natural oatmeal linen, fine even weave, soft diffuse light, very low contrast, colour #EFE8DC. Tiles seamlessly on every edge. No folds, shadows or vignette. |
| `common/paper.png` | 1024×1024 | Seamless tileable texture of thick cream cotton paper with faint fibres, very low contrast, colour #F8F4EC. Tiles seamlessly. No shadows. |
| `common/kraft.png` | 1024×1024 | Seamless tileable kraft paper texture, warm tan #C9A77D, fine fibres and slight mottling. Tiles seamlessly. |
| `common/foil.png` | 1024×1536 | Iridescent holographic foil texture in soft pastel pink, peach and lilac, fine rainbow sheen and diagonal shimmer, like the security strip on a theme-park ticket. Fills the frame edge to edge. |
| `common/leather.png` | 1536×1024 | Top-down close-up of navy leather #1C2A47, subtle grain, even light, with one row of cream saddle stitching running horizontally 12% below the top edge. Tiles seamlessly left to right. |

## Batch 2: objects (transparent background)

| File | Size | Prompt |
|---|---|---|
| `common/tag.png` | 1024×1536 | Transparent background PNG. A blank kraft-paper luggage tag with a brass grommet near the top and a loop of natural twine, straight-on view, rotated 4°, soft realistic drop shadow. Plain surface, no printing (an icon is placed on it). |
| `common/stamp.png` | 1536×464 | Transparent background PNG. An empty rectangular rubber-stamp border in navy ink, double line, rounded corners, uneven ink with speckles and small gaps like a real stamp impression, rotated −3°. Empty inside. Fills the frame edge to edge (the "Show tickets" button on tickets that don't print a frame). |
| `common/tab.png` | 720×1024 | Transparent background PNG. A soft cream canvas fabric tab shaped like a file-folder tab: rounded top corners, straight sides running off the bottom edge, stitched edge, gentle shadow. Empty. Only the top 60% shows; the rest runs under the leather strip. |
| `common/tab_selected.png` | 720×1024 | Same as the tab above in a **neutral near-white** cotton, slightly raised. The app tints it with the trip palette's primary colour (teal #1E5B70 by default), so keep it colourless. |
| `common/tab_add.png` | 720×1024 | Same tab in coral #E5785B cotton. |
| `common/pill.png` | 1536×512 | Transparent background PNG. An empty raised cream pill, soft shadow, like a paper badge. Drawn 35 pt tall behind the weather or countdown. |

## Batch 3: icons (transparent background)

One prompt, repeated per icon:

> Transparent background PNG, 1024×1024. A single **{object}** icon printed
> like letterpress ink on paper: solid navy #1C2A47 with slightly rough ink
> edges and faint speckle, a simple bold silhouette readable at 24 pixels,
> centred with generous padding. No text, no background, no box.

| File | {object} |
|---|---|
| `icons/flight.png` | airplane taking off |
| `icons/stay.png` | hotel bed |
| `icons/attraction.png` | admission ticket |
| `icons/dining.png` | fork and knife |
| `icons/transport.png` | car |
| `icons/activity.png` | compass |
| `icons/event.png` | theatre masks |
| `icons/note.png` | pinned note |
| `icons/nav_today.png` | small house |
| `icons/nav_trips.png` | suitcase |
| `icons/nav_wallet.png` | a document with folded corner (the Documents tab) |
| `icons/nav_profile.png` | person silhouette |
| `icons/nav_add.png` | plus sign |
| `icons/calendar.png` | small calendar page |
| `icons/timeline_stop.png` | a round ink dot (256×256) |
| `icons/timeline_now.png` | a ringed ink dot (256×256) |

Weather icons for the header pill may be full colour (they're drawn
untinted), 1024×1024: `icons/weather_sunny.png` (coral sun with rays),
`weather_cloudy.png`, `weather_rain.png`, `weather_snow.png`.

Every one-colour icon keeps about a quarter of the canvas empty on each
side, like `nav_today.png`: the app sizes icons by their canvas.

## Batch 4: booking artwork (the "smart" pictures)

Each subject comes in **two formats**:

- **Scene**: for the featured "Next up" ticket (1536×1024). Prompt:
  > {Style block} Landscape scene: **{subject}**. Put the main subject in the
  > right third with a low horizon. Keep the left 40% calm and open (plain sky
  > or water) so white text can sit on it. Deep teal-to-navy sky, a large
  > coral sun low on the horizon.
- **Vignette**: the small decoration on normal cards (1024×1024, transparent). Prompt:
  > {Style block} Transparent background PNG. A single decorative vignette of
  > **{subject}** in sage and coral with navy accents, gathered in the bottom-right
  > corner and fading out towards the top-left, like the corner print on a
  > luxury hotel key card. No background colour, no shadow.

### Start with these (they cover the Orlando sample trip)

| Scene file | Vignette file | {subject} |
|---|---|---|
| `attraction/themepark_castle_01_scene.png` | `attraction/themepark_castle_01_vignette.png` | a fairytale castle with tall spires among palm trees, reflected in a lagoon |
| `attraction/any_waterpark_01_scene.png` | `attraction/any_waterpark_01_vignette.png` | a water park with twisting slides, a lazy river and palm trees |
| `attraction/any_rollercoaster_01_scene.png` | `…_vignette.png` | a looping wooden rollercoaster against the sunset |
| `stay/coastal_resort_resort_01_scene.png` | `…_vignette.png` | a Polynesian-style resort with thatched roofs, palms and hibiscus |
| `dining/themepark_castle_01_scene.png` | `…_vignette.png` | an elegant castle dining hall glimpsed through arched windows |
| `dining/coastal_resort_grill_01_scene.png` | `…_vignette.png` | a beachside grill at dusk with lanterns and palm trees |
| `dining/any_pizza_01_scene.png` | `…_vignette.png` | a wood-fired pizza oven and a rustic pizza on a board |
| `dining/any_breakfast_01_scene.png` | `…_vignette.png` | a stack of pancakes with berries and a steaming coffee |
| `flight/any_plane_01_scene.png` | `…_vignette.png` | a passenger plane climbing over soft clouds |
| `transport/any_car_01_scene.png` | `…_vignette.png` | a vintage convertible on a coastal road |
| `activity/any_boat_01_scene.png` | `…_vignette.png` | a small tour boat gliding through reeds and mangroves |
| `event/any_show_01_scene.png` | `…_vignette.png` | a grand theatre stage with velvet curtains and spotlights |
| `note/any_generic_01_scene.png` | `…_vignette.png` | a pinned paper note with a small compass and a sprig of leaves |

Then fill in the rest of the vocabulary below, for more themes and more
variety (`_02`, `_03` of the same subject are used in turn).

---

## Card shells

Each look has a family of complete card objects with no text: the app sets
every word on top at measured positions (`lib/design/art/card_shells.dart`).

| File | Size | What |
|---|---|---|
| `common/<look>_featured_ticket.png` | 1774×887 | The "next up" ticket: the look's scene printed on the left 75%, security strip, tear-off stub with a barcode, blank left 42% for text |
| `common/<look>_room_card.png` | 1774×887 | Hotel key card: blank left 60%, illustration lower right, a band near the right edge |
| `common/<look>_reservation_card.png` | 1983×793 | Tagged card: blank tag (for the category icon), blank centre, a small illustration right of a thin rule |
| `common/reservation_card_blank.png` | 1983×793 | The neutral tagged card with an empty right panel (the booking's own vignette goes there) |

`<look>` is an experience theme's wire name (`coastal_resort`,
`urban_heritage`…). The first families use two longer names, read as
aliases: `alpine_adventure_*` → `alpine`, `countryside_escape_*` →
`countryside`. The unprefixed `featured_ticket.png` and `room_card.png`
are the theme-park anchors. Make every shell at exactly its size and to
the same zones as the existing ones, and add its measured anchors to
`ShellGeometry` (a test fails otherwise). Looks without a family borrow
one until theirs is made: see `docs/ART_ASSET_GAPS.md`.

## Naming: how the app matches pictures to bookings

```
assets/art/<type>/<theme>_<subject>_<number>_<format>.png
```

- **type**: the folder: `flight`, `stay`, `attraction`, `dining`, `transport`,
  `activity`, `event`, `note`.
- **theme**: the trip's look (its experience theme): `classic_travel`,
  `coastal_resort`, `urban_modern`, `urban_heritage`, `alpine`,
  `countryside`, `outdoor_adventure`, `themepark`, `cruise`, `roadtrip`,
  `wellness_retreat`, or **`any`** for pictures that suit every trip. The
  older names still load: `classic`, `tropical` (coastal resort), `city`
  (modern city), `snow` (alpine). No theme at all counts as classic.
- **subject**: one word from the vocabulary below (or `generic`).
- **number**: `01`, `02`… More numbers = more variety.
- **format**: `scene` or `vignette`. Leave it off if one image should do both.

Bundled art is the core set that is always on the phone. Destination and
extra experience art ships as downloadable **art packs** (see
`docs/ART_PACKS.md`): same subjects and formats, described in each pack's
`pack.json` rather than by file name.

How a picture is chosen for a booking (`lib/design/art/art_resolver.dart`):
1. A picture the traveller picked themselves, if any.
2. The **subject** (chosen by Smart Import, or by keywords in the name:
   "Harbour Pizza Co." → `pizza`) from, in turn: the trip's city pack, region
   pack, country pack, the trip's look (packs and bundled art for it), a
   secondary look, then theme-free/classic art.
3. No subject match: a `generic` picture, in the same order.
4. Anything that suits the trip, then anything bundled.
5. Nothing at all: the drawn placeholder you see today.

A trip's look is chosen automatically from its bookings (Gemini, on the
server) unless the traveller picks one. The same booking always gets the
same picture, and neighbouring cards never repeat.

### Vocabulary (subjects per type)

| Type | Subjects |
|---|---|
| flight | `plane` |
| stay | `resort`, `hotel`, `cottage`, `chalet`, `villa`, `camping` |
| attraction | `castle`, `rollercoaster`, `waterpark`, `museum`, `zoo`, `aquarium`, `landmark`, `gardens` |
| dining | `castle`, `fine`, `pizza`, `asian`, `burger`, `breakfast`, `seafood`, `grill`, `bar`, `dessert`, `bistro` |
| transport | `car`, `train`, `bus`, `ferry`, `taxi`, `bike` |
| activity | `boat`, `hiking`, `snorkel`, `spa`, `safari`, `space`, `citytour`, `class` |
| event | `show`, `concert`, `sport`, `fireworks`, `festival` |
| note | `generic` |

Every type also accepts `generic` (used when nothing more specific fits).

## Checking your images in the app

Drop files into the folders and rebuild. Then open **Profile → Design tools →
Card gallery**: every type in every size and state, switchable by trip
theme, with the chosen picture's file name shown on each section.
