# Travary art brief, round 2: the rest of the app

Today now draws its cards from raster shells (`docs/ART_BRIEF.md`,
`docs/ART_ASSET_GAPS.md`). Everywhere else still uses flat panels and
Material icons, which is why the hire-car row looks out of place next to
the ticket and the key card. This brief lists every remaining picture, in
priority order, with ready-to-paste prompts for GPT image generation.

Files marked **(new slot)** need a small code change before the app can use
them; everything else drops straight in. Implement after the art is
approved.

## How to work with GPT

Use the same chat and method as round 1 (`docs/ART_BRIEF.md`, "How to work
with GPT"). Attach these as the style references for every request:

1. `docs/reference/travary_today_reference.png` (the whole-screen look).
2. `assets/art/common/featured_ticket.png`, `room_card.png` and
   `reservation_card_blank.png` (finish, shadows, blank text zones).
3. `assets/art/icons/dining.png` and `nav_today.png` (the icon ink).

Then paste the right style block in front of each prompt.

### Style block A: objects and shells

> Shippable raster asset for a premium travel app in the "travel ephemera"
> style: tactile printed stationery (thick warm-cream cotton paper, kraft,
> linen, leather, brass), vintage travel-poster screen-print illustration
> with soft risograph grain, soft realistic layered shadow. Palette: deep
> teal #1E5B70, navy #1C2A47, coral #E5785B, sage #9DB29C, mustard #D7A443,
> warm cream #F8F4EC. Straight-on view, the complete object with all edges
> visible and comfortable padding, genuinely transparent background outside
> the object. Every area meant for words is left completely blank: no
> letters, numbers, pseudo-text, logos, flags, people or faces.

### Style block B: one-colour icons

> Transparent background PNG, 1024×1024. A single **{object}** printed like
> letterpress ink on paper: solid navy #1C2A47, slightly rough ink edges and
> faint speckle, a simple bold silhouette readable at 20 pixels, centred,
> filling about half the canvas (a quarter of the canvas empty on every
> side). No text, no background, no box, no shadow.

The app tints these icons (navy on light paper, cream on dark tags and the
selected tab), so keep them one flat colour.

### Style block C: small illustrations

> Transparent background PNG. A small vintage travel-poster screen-print
> vignette of **{subject}**, flat layered shapes, soft risograph grain,
> palette deep teal #1E5B70, navy #1C2A47, coral #E5785B, sage #9DB29C,
> mustard #D7A443 and warm cream #F8F4EC, gathered in the centre and fading
> softly at the edges. Calm and uncluttered. No text, letters, numbers,
> logos or faces.

---

## P1: what looks out of place today

**Delivered and implemented:** `ongoing_tag`, `boarding_pass`,
`featured_reservation`, `travel_ticket` and `note_paper` (prompt record:
`docs/art_prompts/round2_p1_prompts.md`); `linen`, `tab`, `tab_selected`
and `tab_add` (`docs/art_prompts/surface_and_tabs_prompts.md`). The rest
of P1 is still to make.

### Things in progress (why the hire car looks wrong)

A hotel you're staying at gets its key card. A hire car, a multi-day park
pass or a rail pass still shows a flat row. It needs its own physical
object.

| File | Size | Where |
|---|---|---|
| `common/ongoing_tag.png` **(new slot)** | 1983×466 | Today, under the featured ticket: a hire car or multi-day pass you're in the middle of ("Car hire · Alamo · Drop-off in 4 days") |

> {Style block A} Asset type: a wide horizontal "in use" key tag for a
> hire car or multi-day pass, about 4.3:1. A cream cotton-card label with
> softly rounded corners. On its left end, a short navy leather strap loops
> through an aged-brass split ring holding a small blank brass key blank
> (no brand, no logo). Keep the whole label blank for three lines of live
> text, and keep a clear round 1:1 blank spot at the left of the label for
> a category icon. Add one thin sage rule near the right edge. Match
> the tactility and shadow of the reference key card and tagged card.
> Avoid car brands, key-fob buttons, number plates and glossy plastic.

Later, per look: `<look>_ongoing_tag.png`, with a small corner
illustration like the reservation cards.

### Featured cards for other kinds of booking

Today, a flight, dinner or train that's "next up" is printed on the
look's admission ticket (a castle ticket for dinner). These three shells
have an **empty picture window**. The app places the booking's own scene
in it (the existing `*_scene.png` files are made for this), so one shell
serves every destination.

| File | Size | Where |
|---|---|---|
| `common/boarding_pass.png` **(new slot)** | 1774×887 | Featured flight |
| `common/featured_reservation.png` **(new slot)** | 1774×887 | Featured restaurant booking |
| `common/travel_ticket.png` **(new slot)** | 1774×887 | Featured train, coach, ferry, transfer or car pick-up |

> {Style block A} Asset type: a featured **boarding pass** shell, about
> 2:1, in the same family as the reference featured ticket. A deep navy
> printed pass with a tear-off cream stub at the right (scalloped
> perforation, a blank vertical barcode zone, a thin mother-of-pearl
> security strip). The left 42% is calm deep navy for live white text. The
> area from 42% to the stub is a **fully transparent rectangular window**
> with softly rounded corners and a fine printed keyline border, where
> the app will place a scene. A small blank rounded stamp frame sits in the
> lower left for a live "Show tickets" button. No airline marks, no seat
> grid, no text.

Use the same prompt with:
- **Restaurant reservation:** "a featured restaurant reservation card:
  heavy cream menu-card stock with a deep teal left panel, a deckled edge,
  a small tear-off 'table' stub at the right with a blank round
  table-number disc instead of a barcode".
- **Travel ticket:** "a featured rail and coach travel ticket: sage-green
  printed stock with a guilloche-pattern border, a punched-hole stub at the
  right with a blank ticket-number strip".

### Notes

| File | Size | Where |
|---|---|---|
| `common/note_paper.png` **(new slot)** | 1983×793 | A note (standard and featured) |

> {Style block A} Asset type: a note card in the tagged-card family,
> about 2.5:1. A sheet of warm cream writing paper with faint blue ruled
> lines and a deckled right edge, held by an aged-brass paperclip at the
> top left and a small torn strip of washi tape at the top right. Lined
> area blank for live text. Keep a clear 1:1 blank spot near the paperclip
> for a small icon.

### Surfaces and icons the home screen is already asking for

Already specified in `docs/ART_BRIEF.md` and `docs/ART_ASSET_GAPS.md`:
make these first, they're on screen all the time.

- `common/linen.png` (1024×1024 tile)
- `common/leather.png` (1536×1024)
- `common/tab.png`, `common/tab_selected.png` (finished teal, never tinted),
  `common/tab_add.png` (720×1024 each)
- `common/pill.png` (1536×512)
- `common/stamp.png` (1536×464)
- `icons/nav_wallet.png`, `nav_profile.png`, `nav_add.png`, `calendar.png`,
  `weather_sunny.png` (plus `_cloudy`, `_rain`, `_snow`), `timeline_stop.png`,
  `timeline_now.png`
- `dining/themepark_castle_01_{scene,vignette}.png`,
  `dining/themepark_grill_01_{scene,vignette}.png`

For a matched set, regenerate `nav_today.png` and `nav_trips.png` as **outline**
icons like the reference (a house outline, a suitcase outline) alongside the
three new ones.

### Booking-kind icons

On every tag, list row and chip. `icons/flight.png` and `icons/dining.png`
exist. Use style block B:

| File | {object} |
|---|---|
| `icons/stay.png` | a hotel key on a round key tag |
| `icons/attraction.png` | an admission ticket with a tear-off stub |
| `icons/transport.png` | a small car seen side-on |
| `icons/activity.png` | a compass |
| `icons/event.png` | theatre masks |
| `icons/note.png` | a pinned note |

Transport varies most, so give it subject icons **(new slot)**: the tag then
shows a train for a train and a car for car hire.

| File | {object} |
|---|---|
| `icons/transport_car.png` | a small vintage car, side-on |
| `icons/transport_train.png` | a steam-era locomotive front, three-quarter view |
| `icons/transport_bus.png` | a rounded coach, side-on |
| `icons/transport_ferry.png` | a small ferry on two wave lines |
| `icons/transport_taxi.png` | a car with a small roof sign (blank sign) |
| `icons/transport_bike.png` | a bicycle |

---

## P2: Trips and the trip screen

### Trip covers: one luggage sticker per look

The Trips list and trip header use a flat colour block and a Material icon
today. Replace them with vintage luggage stickers, one per look. Destination
packs can add city stickers later under the same name.

| File **(new slot)** | Size | Sticker |
|---|---|---|
| `covers/classic_travel.png` | 1024×1024 | round sticker: winged suitcase over a globe |
| `covers/coastal_resort.png` | 1024×1024 | oval sticker: sailboat under a coral sun, palms |
| `covers/urban_modern.png` | 1024×1024 | tall shield: modern skyline at dusk |
| `covers/urban_heritage.png` | 1024×1024 | round: dome, arch and a small tram |
| `covers/alpine.png` | 1024×1024 | pennant-shaped: snowy peaks and a cable car |
| `covers/countryside.png` | 1024×1024 | oval: patchwork hills and a cottage |
| `covers/outdoor_adventure.png` | 1024×1024 | badge: tent under peaks and pines |
| `covers/themepark.png` | 1024×1024 | round with a scalloped edge: castle spires and a ferris wheel |
| `covers/cruise.png` | 1024×1024 | lifebuoy ring: an ocean liner |
| `covers/roadtrip.png` | 1024×1024 | rounded rectangle: convertible on a winding road |
| `covers/wellness_retreat.png` | 1024×1024 | round: lotus, steam and a calm lake |

> {Style block A} Asset type: a single die-cut **vintage luggage sticker**
> for the "{look}" look: {sticker}. Printed paper with a thin white die-cut
> border, slight wear and a soft shadow as if stuck on a suitcase, very
> slightly rotated. The illustration only; any banner or ribbon on the
> sticker stays blank. The set must look like one series.

### Look emblems (Card style chips)

Small one-colour versions of the stickers for the 11 look chips on the trip
screen (a sticker is too detailed at 20 points). Style block B, files
`icons/look_<look>.png` **(new slot)**:

| Look | {object} |
|---|---|
| `classic_travel` | a winged suitcase |
| `coastal_resort` | a sailboat |
| `urban_modern` | three skyscrapers |
| `urban_heritage` | a domed building |
| `alpine` | two peaks |
| `countryside` | a cottage on a hill |
| `outdoor_adventure` | a tent |
| `themepark` | a ferris wheel |
| `cruise` | an ocean liner |
| `roadtrip` | a winding road |
| `wellness_retreat` | a lotus |

Add `icons/look_auto.png` for the "Automatic" chip: a compass rose with a
small spark.

### Trip list tile and trip header

| File **(new slot)** | Size | Where |
|---|---|---|
| `common/trip_folder.png` | 1983×576 | Each trip on the Trips list (the sticker goes on it) |
| `common/trip_folder_header.png` | 1774×700 | The top of a trip's own screen |

> {Style block A} Asset type: a **kraft travel-document wallet** lying
> flat, about 3.4:1: a warm kraft folder with a stitched edge, a navy elastic
> band across its right third and a small brass eyelet. The left quarter is a
> clean kraft area where a round luggage sticker will be placed. The rest of
> the face is blank for the trip's name, dates and booking count. No text.

For the header, use the same folder seen from the top with its flap open, a
blank cream title label on the flap and a sticker spot at the top left.

### Who's coming and invites

| File **(new slot)** | Size | Where |
|---|---|---|
| `common/avatar_frame.png` | 512×512 | Each traveller's initials: a round postage-stamp frame with a perforated edge, blank cream centre |
| `common/invite_card.png` | 1774×1100 | Invite and Join sheets: a vintage postcard with a blank stamp box top right, a blank address area and a large blank panel for the 6-letter code |
| `common/button_add_round.png` | 512×512 | The trip screen's add button: a coral round wax-seal stamp, blank centre for the plus |

### Day list rows

The trip screen, Documents, "Earlier" on Today and the Smart Import review
list all use the same one-line row. It needs a slim physical object:

| File **(new slot)** | Size | Where |
|---|---|---|
| `common/list_slip.png` | 1983×354 | Every one-line booking row |

> {Style block A} Asset type: a slim **filed ticket stub**, about 5.6:1:
> warm cream card with a fine perforated tear line near the right end and a
> softly rounded left end. At the left, a small blank round ink-stamped
> circle (1:1) for a category icon. The rest is blank for a date, a title
> and one line of detail. Very subtle paper fibres, soft small shadow. No
> barcode, no text.

---

## P3: Documents and booking detail

| File | Size | Where |
|---|---|---|
| `common/list_slip.png` | as above | Every document row |
| `common/search_slip.png` **(new slot)** | 1983×300 | The search field: a strip of cream paper tucked under a brass clip at the left, blank |
| `common/wallet_header.png` **(new slot)** | 1536×640 | Beside the Documents title: an open navy leather travel wallet with ticket edges, a boarding-pass corner and a passport peeking out (style block C, all blank) |
| `common/file_pdf.png` **(new slot)** | 768×1024 | A PDF ticket's thumbnail frame: a folded cream document with a dog-eared corner and a paperclip, face blank (the app shows the first page inside) |
| `common/file_photo.png` **(new slot)** | 1024×1200 | A photo ticket's thumbnail frame: an instant-photo print with a thick cream border, image window transparent |

The filter chips reuse the kind icons.

Booking-detail row icons (style block B, `icons/<name>.png`, **new slots**):

| File | {object} |
|---|---|
| `icons/when.png` | a pocket watch |
| `icons/place.png` | a map pin |
| `icons/map.png` | a folded map |
| `icons/details.png` | a small ticket stub with lines |
| `icons/reference.png` | a barcode on a luggage tag |
| `icons/notes.png` | a notepad with a pencil |
| `icons/trip.png` | a suitcase with a luggage tag |
| `icons/attach.png` | a paperclip |
| `icons/download.png` | a cloud with a down arrow |
| `icons/offline_ready.png` | a cloud with a tick |
| `icons/edit.png` | a fountain pen nib |
| `icons/share.png` | a paper plane |
| `icons/copy.png` | two stacked tickets |

---

## P4: Add, Smart Import, sharing

| File | Size | Where |
|---|---|---|
| `common/kind_tile.png` **(new slot)** | 840×1024 | The 8 tiles in "What have you booked?": a small cream luggage label with a brass grommet at the top, blank face for an icon and a word |
| `common/import_banner.png` **(new slot)** | 1983×360 | The Smart Import button: a navy linen band with cream saddle stitching, blank |
| `icons/scan.png` | 1024×1024, style B | The Smart Import icon: a ticket under a magnifying glass with a small spark |
| `common/import_hero.png` **(new slot)** | 1536×1024 | Smart Import screen: a flat lay of a boarding pass, a hotel confirmation and a theatre ticket under a camera viewfinder frame, everything blank (style C) |
| `common/sheet_paper.png` **(new slot)** | 1024×1024 tile + 1983×120 top edge | Bottom sheets: warm cream paper tile, and a deckled torn top edge strip |
| `icons/invite.png`, `icons/leave.png` | style B | A person with a plus; a person with an arrow out of a door |

The add sheet currently shows Material glyphs even for Flight and Dining,
which already have raster icons. That's fixed in code with the kind icons
above; no extra art is needed.

---

## P5: Profile, Travary Plus, paywall

| File **(new slot)** | Size | Where |
|---|---|---|
| `common/plus_card.png` | 1774×1000 | The Travary Plus card on Profile and the Plus option on the paywall: a navy leather membership card with a fine gold-foil border and an embossed compass-rose seal in one corner, blank text area |
| `common/trip_pass.png` | 1774×887 | The Trip Pass option: a coral single-trip day pass with a tear-off stub and a blank round punch mark |
| `icons/seal_plus.png` | 1024×1024 | The Plus rosette: a coral and mustard rosette seal with ribbon tails, blank centre (full colour, drawn untinted) |
| `common/paywall_hero.png` | 1536×1024 | Top of the paywall: a flat lay of four suitcases of different sizes in a row (a family), luggage stickers, a passport and tickets, left 40% calm (style C) |

Paywall and profile icons (style B, `icons/<name>.png`):

| File | {object} |
|---|---|
| `icons/unlock.png` | an open padlock |
| `icons/reminder.png` | a desk bell |
| `icons/renews.png` | a calendar page with a tick |
| `icons/smart_import.png` | a spark over a ticket |
| `icons/family.png` | three luggage tags on one ring |
| `icons/backup.png` | a ticket inside an envelope with a small shield |
| `icons/restore.png` | a circular arrow around a ticket |
| `icons/demo.png` | a flask |
| `icons/gallery.png` | a fanned hand of three cards |
| `icons/time_travel.png` | an hourglass |

---

## P6: empty states and system moments

Style block C, 1024×768, transparent. These replace the plain icons over
each empty-state message.

| File **(new slot)** | {subject} | Shown when |
|---|---|---|
| `common/empty_first_trip.png` | an open suitcase with a folded map, a passport and sunglasses, a low coral sun behind | No bookings yet ("Where are you off to?") |
| `common/empty_free_day.png` | a striped deckchair under a parasol on a quiet shore | A day with nothing booked ("A free day") |
| `common/empty_nothing_coming.png` | a small desk globe beside a closed notebook | No trips coming up |
| `common/empty_documents.png` | an empty open leather wallet | Documents has nothing yet |
| `common/empty_no_matches.png` | a magnifying glass resting on a map | A search with no results |
| `common/empty_tickets.png` | an envelope with a ticket half out | A booking without ticket files |
| `common/offline.png` | a paper plane resting on a cloud | Sync errors and start-up problems |

---

## P7: more card art

The shells and scenes that widen coverage, from round 1:

1. **Shell families** for the looks that borrow another's today
   (`docs/ART_ASSET_GAPS.md`). Make `featured_ticket`, `room_card` and
   `reservation_card` for `classic_travel`, `urban_modern`,
   `outdoor_adventure`, `cruise`, `roadtrip` and `wellness_retreat`, using
   the round 1 prompts in `docs/art_prompts/theme_anchor_prompts.md`.
   Classic comes first: every unclassified trip uses it.
2. **Taller variants** closer to the reference's proportions (optional):
   `featured_ticket` at about 1774×1000 and `room_card` at 1774×960.
3. **Scenes and vignettes** from round 1's start list not made yet:
   `attraction/any_waterpark_01`, `attraction/any_rollercoaster_01`,
   `stay/coastal_resort_resort_01`, `dining/any_pizza_01`,
   `dining/any_breakfast_01`, then `transport/any_train_01`,
   `event/any_fireworks_01`, `activity/any_hiking_01`.

## Counts

| Priority | Pictures |
|---|---|
| P1 (Today and home) | 5 new shells, 7 surfaces, 12 home and header icons (2 are outline redraws), 6 kind icons, 6 transport icons, 2 scene/vignette pairs |
| P2 (Trips) | 11 stickers, 12 emblems, 2 folders, 3 sharing objects, 1 list slip |
| P3 (Documents, detail) | 4 objects, 13 icons |
| P4 (Add, import) | 3 objects, 3 icons, sheet paper (tile + edge) |
| P5 (Plus) | 3 objects, 1 seal, 10 icons |
| P6 (empty states) | 7 illustrations |
| P7 (coverage) | 18 shells (+2 optional taller variants), 8 scene/vignette pairs |

## What stays standard

Keep the platform's own back arrow, close, more (…), chevrons and
checkmarks. They carry meaning people already know, and they don't need
to look like printed objects. Text fields keep their cursor and keyboard
behaviour; only their surface changes.
