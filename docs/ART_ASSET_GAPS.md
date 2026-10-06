# Art asset gaps

The Today screen and home tabs are built to draw every distinctive object
from supplied raster art (`docs/ART_BRIEF.md`). This file tracks requested
art, completed deliveries, what stands in while art is missing, and
what must be made before the screen can be signed off against
`docs/reference/travary_today_reference.png`.

All stand-ins sit behind one typed resolver each, so adding the file is the
whole fix: no code changes.

- Shells: `ShellResolver` in `lib/design/art/card_shells.dart`.
- Icons and interface surfaces: `IconSlot` / `SurfaceSlot` / `ArtSlots` in
  `lib/design/art/art_slots.dart`.
- Card pictures: `ArtResolver` in `lib/design/art/art_resolver.dart`.

An installed art pack can supply any of these under the same key
(`docs/ART_PACKS.md`).

Visual QA: `tool/visual_qa.sh` renders the canonical screen at 813 × 1933
and writes `build/visual_qa/today_{actual,overlay,diff}.png` and
`today_metrics.txt`. **The current render isn't pixel-perfect.** The gaps
below account for most of the remaining difference.

## Visible in the canonical Today screen

| File (key) | Size | Where | Stand-in now (visible?) | Needed for sign-off |
|---|---|---|---|---|
| `common/leather.png` (`leather`) | 1536 × 1024, tiles left to right, stitching 12% from the top | The strip under the home tabs, filling the bottom safe area (34 pt on the reference phone), `BoxFit.cover`, top-aligned | Nothing is drawn. Per the spec the strip appears only when the raster exists (**visible**: tabs run to the screen edge) | Make it |
| `common/pill.png` (`pill`) | 1536 × 512 (3:1), raised cream pill, empty | Header weather or countdown pill, drawn 35 pt tall at its own aspect | Flat cream pill with a soft shadow (**visible**) | Make it |
| `icons/nav_wallet.png` (`nav_wallet`) | 1024 × 1024, one-colour navy ink, transparent, content ≈ 50% of the canvas like `nav_today` | Documents tab (the ticket wallet) | Supplied letterpress document icon; Material glyph remains the fallback | **Supplied, 5 Oct 2026** |
| `icons/nav_profile.png` (`nav_profile`) | as above | Profile tab | Supplied letterpress person icon; Material glyph remains the fallback | **Supplied, 5 Oct 2026** |
| `icons/nav_add.png` (`nav_add`) | as above, a bold plus | Add tab | Supplied letterpress plus icon; Material glyph remains the fallback | **Supplied, 5 Oct 2026** |
| `icons/weather_sunny.png` (`weather_sunny`) | 1024 × 1024, full colour allowed (drawn untinted) | Header pill when a forecast is given ("28° Sunny") | Material sun glyph in coral (**visible**) | Make it; also `weather_cloudy`, `weather_rain`, `weather_snow` |
| `icons/timeline_stop.png` (`timeline_stop`) | 256 × 256, one-colour ink dot, tinted `ui.secondary` | Day timeline stops | Plain round dot (**visible**, matches the reference closely) | Optional |
| `icons/timeline_now.png` (`timeline_now`) | 256 × 256, one-colour ring, tinted `ui.highlight` | The stop happening now | Plain dot with a halo (not in the morning reference) | Optional |
| `dining/themepark_castle_01_vignette.png` (+ `_scene`) | 1024 × 1024 transparent (scene 1536 × 1024) | "Be Our Guest Restaurant" (subject `castle`) on a theme-park trip | The generic `dining/any_bistro_01_vignette.png` (**visible**: the reference shows a castle) | In the brief's start list |
| `dining/themepark_grill_01_vignette.png` | as above | "Ohana" (subject `grill`) on a theme-park trip: palm, low sun, waves | The bistro vignette (**visible**). Its scene exists and is used on featured cards and in Documents | Make it |

Present and used: the woven `linen` (tiled behind the four home tabs) and
the home tabs `tab`, `tab_selected` (finished petrol teal, drawn as it is
and never tinted; a pack may override it) and `tab_add`, placed by their
measured edges (`SurfaceSlot.body`); every shell family (below), `icons/dining.png`,
`icons/flight.png`, `icons/nav_today.png`, `icons/nav_trips.png`, and all
eight `any_*`/`themepark_*`/`tropical_*` scene and vignette pairs.

## Today between trips (the countdown)

`CountdownTripHero` (`lib/design/widgets/countdown_trip_hero.dart`, target
`docs/mockups/today-empty/02-hanging-luggage-tag.png`). Visual QA:
`tool/visual_qa.sh` also writes `build/visual_qa/countdown_actual.png`
(the reference canvas) and `countdown_844_actual.png` (390 × 844 with a
status bar).

| File (key) | Size | Where | Stand-in now (visible?) | Needed for sign-off |
|---|---|---|---|---|
| `common/countdown_postcard.png` (`countdown_postcard`), per destination pack | 1122 × 1402 | The postcard | Only place packs carry one (Lake District, Orlando, Kyoto, Paris and Bali so far). Any other trip counts down on the neutral postcard below | A postcard per destination pack: prompts and per-country scenes in `art_packs/prompts/postcards.md` |
| `common/countdown_postcard_anywhere` (`countdown_postcard_anywhere`), bundled | 1122 × 1402 | The postcard for a trip whose place has none | **A stand-in**: the bundled plane scene inside the Lake District postcard's frame (visible) | The real neutral postcard (prompt in `art_packs/prompts/postcards.md`) |

Since 3 October 2026 the countdown shows only the postcard and its tag:
the fact tickets (`countdown_fact_duration`, `countdown_fact_bookings`,
`countdown_fact_opens`, legacy `countdown_fact_tag`) and `countdown_button`
are no longer drawn. They stay bundled in case they return; remove them to
save about 3.6 MB if not.

Present and used: `common/countdown_luggage_tag.png` (the blank tag; its
card is `SurfaceSlot.countdownTag.body`, the eyelet is
`CountdownGeometry.eyelet`); the individually drawn
`common/countdown_fact_duration.png`, `common/countdown_fact_bookings.png`,
and `common/countdown_fact_opens.png`; `common/countdown_button.png`; and
`icons/calendar.png`, `icons/countdown_bookings.png`, and
`icons/attraction.png`. The legacy `countdown_fact_tag` key remains a pack
fallback, but is not bundled. The mockup's tree and postmark motif on the
large tag isn't drawn: the tag stays blank and every word on every surface
is live.

## Shells

Complete families exist for theme park (the unprefixed anchors
`featured_ticket.png` and `room_card.png`, with `reservation_card_blank.png`),
`coastal_resort_*`, `urban_heritage_*`, `alpine_adventure_*` (read as
`alpine`) and `countryside_escape_*` (read as `countryside`). Each file's
anchors are measured in `ShellGeometry`. A test fails if a bundled shell
has no anchors or isn't its role's exact pixel size.

| Missing | Size | Stand-in now | Visible? |
|---|---|---|---|
| `common/classic_travel_featured_ticket.png`, `…_room_card.png`, `…_reservation_card.png` | 1774 × 887, 1774 × 887, 1983 × 793 | Urban heritage ticket and key card; blank tagged card with the booking's vignette | Yes, on classic (and unclassified) trips |
| The same three for `urban_modern` | as above | Urban heritage | Yes, on modern-city trips |
| … `outdoor_adventure` | as above | Alpine | Yes |
| … `cruise`, `wellness_retreat` | as above | Coastal resort | Yes |
| … `roadtrip` | as above | Countryside | Yes |
| `common/stamp.png` | 1536 × 464 (the printed frame's 3.3:1), empty inked stamp frame | "Show tickets" on tickets that don't print a frame (every family but the theme-park anchor): a plain paper button with an ink border | Yes, on non-theme-park trips |

Round 2 added five universal shells, all present and measured:
`boarding_pass` (a flight that's next up), `featured_reservation` (a
restaurant), `travel_ticket` (train, coach, ferry, car pick-up) each with a
transparent picture window the booking's scene shows through;
`note_paper` (notes, next up or not) and `ongoing_tag` (a hire car or
multi-day pass in progress, and the fallback for a stay whose key card is
missing). The train scene (`transport/any_train_01_*`) isn't made yet, so a
train's window shows the car picture (visible).

Tag ink: the bundled blank, coastal, urban and countryside tags are light,
so their icon prints navy. The alpine tag is dark, so its icon prints
cream. Pack reservation cards are assumed to have dyed dark tags (every
current country pack does), so icons on them print cream.

## Icons for booking kinds

`icons/<kind>.png`, 1024 × 1024, one-colour navy ink (tinted per tag), for
the tagged cards' luggage tags, compact rows and the Documents stamps'
badges. All eight are present, drawn as one set of solid letterpress
silhouettes: `flight` and `dining` set the style; `stay`, `attraction`,
`transport`, `activity`, `event` and `note` were drawn to match them.
`calendar` (the header pill and countdown facts) and the countdown's
`countdown_bookings` are outline icons. The reference's dinner tag prints a hibiscus. That's a
decorative motif, not a kind icon, so it isn't modelled; dinner tags show the
dining icon.

## Brief materials not used by this build

`common/paper.png`, `common/kraft.png` and `common/foil.png` are baked into
the complete shells, so nothing looks them up. `common/tag.png` exists but
isn't used: every tagged shell includes its tag.

## Differences that art alone won't close

- **Card proportions.** The supplied featured ticket's physical ticket is
  2.40:1 and the key card 2.22:1. In the reference they're about 2.0:1.
  Shells are never stretched, so at the reference width the ticket is 155
  pt tall (reference 185) and the key card 161 pt (reference 177). The
  screen spaces cards evenly, so centres stay within about 12 pt of the
  reference. Taller variants (1774 × 1000 or so) would close this.
- **Headline serif.** The reference's headings are a condensed,
  high-contrast display serif. The app uses Source Serif 4 (the text optical
  size Google Fonts serves). Titles run wider, so long ones shrink to fit one
  line (down to 66%) or wrap. The featured ticket prints time and details on
  one line ("9:00am · 2 tickets") because its stamp frame leaves room for
  no more.
- **Wording.** The reference reads "Park opens 9:00am". The app writes the
  booking's time, "9:00am", and doesn't invent that the time is an opening
  time. The key card's small line is live data ("CHECK-OUT IN 4 DAYS"),
  where the reference prints "ALOHA".

## Documents: stamp rows

`DocumentStampCard` (`lib/design/cards/document_stamp_card.dart`) and the
heading's `DestinationStamp` (`lib/design/widgets/destination_stamp.dart`),
target `docs/mockups/documents-themed-v2/02-collectible-scenic-stamps.png`
(assets: `docs/documents_stamps_prompts.md`). Visual QA: `tool/visual_qa.sh`
also writes `build/visual_qa/documents_actual.png` (Orlando on 28 September
2026, at the mockup's 851 × 1848), `documents_lakes_actual.png` and
`documents_halo_{light,dark}.png`.

Present and used: the three stamp frames `common/documents_stamp_01.png`
(classic), `_02` (airmail) and `_03` (vintage), 1024 × 896, their windows
measured in `StampGeometry` (a test checks the window is clear and the
frame solid where the geometry says); `common/documents_postmark.png` and
`common/documents_cancel_lines.png` (one-colour ink, tinted); every booking
kind's icon; the destination stamps (1024 × 1280) in the Orlando, Lake
District, Kyoto, Paris and Bali packs, their label band measured in
`DestinationStampGeometry`; and the scenes, including the four made for the
first Documents design: `dining/themepark_generic_02_scene.png`,
`dining/themepark_grill_01_scene.png`, `note/themepark_generic_01_scene.png`
and `activity/themepark_boat_01_scene.png`. Scenes are cropped a little
right of centre, where the brief puts their subject.

| Missing | Size | Stand-in now | Visible? |
|---|---|---|---|
| `…_vignette.png` for the three dining and activity scenes above (the note scene needs none: note paper shows no picture) | 1024 × 1024 transparent | Tagged cards on Today use the best vignette there is: the bistro for dining, `any_boat_01` for the airboat | Yes, on Today's normal cards |
| `common/documents_destination_stamp.png` for every other destination | 1024 × 1280, same template | No stamp beside the heading | Only on trips without one |

No longer used: the ticket-ledger shells `common/documents_ticket_01.png`
to `_03` (the first Documents design, replaced by the stamps) are still in
the bundle; delete them to save about 1.9 MB.

Differences that art alone won't close:

- **Headline serif.** The mockup's titles are a condensed display serif;
  Source Serif 4 runs wider, so the longest titles shrink a little and then
  end in an ellipsis.
- **Header postmark.** The mockup prints "JOURNEY INSPIRE EXPLORE MORE"
  round its header postmark; art carries no text, so the ring is plain.

## Trips: coming trips' postcards

`UpcomingTripPostcard` (`lib/design/widgets/upcoming_trip_postcard.dart`,
target `docs/mockups/trips-postcards-v2/02-hanging-tag-postcards.png`).
Visual QA: `tool/visual_qa.sh` also writes
`build/visual_qa/trips_actual.png`.

| File (key) | Size | Where | Stand-in now (visible?) | Needed for sign-off |
|---|---|---|---|---|
| `common/trip_postcard.png` (`trip_postcard`), per destination pack | 1536 × 1024 | A coming trip's row under "Coming up" | None bundled on purpose. Without a suitable installed pack the trip keeps its plain row | Complete place packs exist for Lake District, Orlando, Kyoto, Paris and Bali under `art_packs/sources/` (`docs/ART_PACKS.md`) |

The tag is the countdown's blank `common/countdown_luggage_tag.png`
(`SurfaceSlot.countdownTag`), drawn smaller; no second tag raster. The
mockup's destination motifs on the tag (trees, a maple leaf, a palm) aren't
drawn: the tag stays blank and every word on it is live.

## Travel documents

| File (key) | Size | Where | Stand-in now (visible?) | Needed for sign-off |
|---|---|---|---|---|
| A passport-cover shell for a document row | about 1983 × 793 | `TravelDocumentCard` (the travel documents list) | A plain paper row with the kind's icon on a palette-coloured medallion (visible) | Optional: a blank passport/ID cover in the travel-ephemera style, with a clean live-text zone |

## Sign in (Profile)

| File (key) | Size | Where | Stand-in now (visible?) | Needed for sign-off |
|---|---|---|---|---|
| Google's official "G" logo | SVG or 3× PNG, about 60 × 60 | `GoogleSignInButton` (`design/widgets/sign_in_buttons.dart`) | A four-colour G drawn in Flutter (`_GoogleGPainter`), close to Google's mark (visible) | Google's own logo file from its branding guidelines, unaltered |
| Apple's logo | n/a | `AppleSignInButton` | Material's `Icons.apple` on Apple's black button (visible) | Fine as is; for Apple's own artwork, swap in `sign_in_with_apple`'s button or Apple's HIG resources |

## Trip, add sheet and forms (C2 "refined ledger")

The trip screen, Trip details, the add sheet, the booking forms, the flight
board and a booking's page (`docs/mockups/trip-ledger-c2/`) are mostly
**drawn**: paper panels, plan rows, gap rows, the form ticket and its
notches, the perforation, the notched button, the departures board and its
split-flap tiles. They need no raster. The eight shared assets below and
the three navigation icons above were supplied on 5 October 2026. Exact
generation prompts and checks are in
[`c2_screen_assets_prompts.md`](c2_screen_assets_prompts.md).

| File (key) | Size | Where | Stand-in now (visible?) | Needed for sign-off |
|---|---|---|---|---|
| `common/add_snap.png` (`SurfaceSlot.addSnap`) | 768 × 768, transparent | Add sheet, "Snap a booking" | Supplied polaroid with abstract travel bookings | **Supplied** |
| `common/add_passport.png` (`SurfaceSlot.addPassport`) | 768 × 768, transparent | Add sheet, "Passport & documents" | Supplied navy passport with gold globe and cream card | **Supplied** |
| `common/trip_postcard_anywhere.png` (`tripPostcardAnywhereArt`) | 1536 × 1024, the card in a transparent margin | Top of a trip whose place has no `trip_postcard` | Supplied landscape companion to the neutral portrait postcard | **Supplied** |
| `icons/attach.png` (`IconSlot.attach`) | 1024 × 1024, transparent | "Attach your ticket" on forms and booking pages | Supplied letterpress paperclip | **Supplied** |
| `icons/invite.png` (`IconSlot.invite`) | 1024 × 1024, transparent | "Who's coming · Invite" on the trip, Trip details | Supplied letterpress person with plus | **Supplied** |
| `icons/look.png` (`IconSlot.look`) | 1024 × 1024, transparent | Card style (Trip details) | Supplied letterpress perforated stamp | **Supplied** |
| `icons/clock.png` (`IconSlot.clock`) | 1024 × 1024, transparent | Times on the form ticket | Supplied letterpress clock at 10:10 | **Supplied** |
| `icons/passport.png` (`IconSlot.passport`) | 1024 × 1024, transparent | Travel documents rows | Supplied letterpress passport booklet | **Supplied** |
| `icons/checklist.png` (`IconSlot.checklist`) | 1024 × 1024, transparent, one-colour navy ink like `passport` | "Add something to do" on a trip's "Before you go" checklist | Material checklist glyph in the trip's ink (**visible**) | Make it: a letterpress luggage label or note with two ticked lines, matching the other C2 icons |
| Country packs' `common/trip_postcard` | 1536 × 1024 | Trip headers and Trips rows for the 25 countries | The place's countdown postcard, cropped | **Published** 5 Oct 2026 (packs v3, catalog v80) |
