# Art asset gaps

The Today screen and home tabs are built to draw every distinctive object
from supplied raster art (`docs/ART_BRIEF.md`). This file lists every file
the build looks for that doesn't exist yet, what stands in meanwhile, and
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
| `icons/nav_wallet.png` (`nav_wallet`) | 1024 × 1024, one-colour navy ink, transparent, content ≈ 50% of the canvas like `nav_today` | Documents tab (the ticket wallet) | Material `description` glyph (**visible**) | A document/ticket-wallet icon |
| `icons/nav_profile.png` (`nav_profile`) | as above | Profile tab | Material `person` glyph (**visible**) | Make it |
| `icons/nav_add.png` (`nav_add`) | as above, a bold plus | Add tab | Material `add` glyph (**visible**) | Make it |
| `icons/weather_sunny.png` (`weather_sunny`) | 1024 × 1024, full colour allowed (drawn untinted) | Header pill when a forecast is given ("28° Sunny") | Material sun glyph in coral (**visible**) | Make it; also `weather_cloudy`, `weather_rain`, `weather_snow` |
| `icons/timeline_stop.png` (`timeline_stop`) | 256 × 256, one-colour ink dot, tinted `ui.secondary` | Day timeline stops | Plain round dot (**visible**, matches the reference closely) | Optional |
| `icons/timeline_now.png` (`timeline_now`) | 256 × 256, one-colour ring, tinted `ui.highlight` | The stop happening now | Plain dot with a halo (not in the morning reference) | Optional |
| `dining/themepark_castle_01_vignette.png` (+ `_scene`) | 1024 × 1024 transparent (scene 1536 × 1024) | "Be Our Guest Restaurant" (subject `castle`) on a theme-park trip | The generic `dining/any_bistro_01_vignette.png` (**visible**: the reference shows a castle) | In the brief's start list |
| `dining/themepark_grill_01_vignette.png` (+ `_scene`) | as above | "Ohana" (subject `grill`) on a theme-park trip: palm, low sun, waves | The bistro vignette (**visible**) | Make it |

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
| `common/countdown_postcard.png` (`countdown_postcard`), per destination pack | 1122 × 1402 | The postcard | None bundled on purpose. Without a suitable pack Today keeps its first-day view, so the countdown isn't seen yet | Five made (Lake District, Orlando, Kyoto, Paris, Bali), waiting in `art_packs/pending/countdown_postcards/` for their complete city/region packs (`docs/ART_PACKS.md`) |
| `common/countdown_fact_tag.png` (`countdown_fact_tag`) | 1024 × 512, eyelet and string in the left fifth, words in `CountdownGeometry.factCopy` | The three facts under the postcard | A plain paper label with a soft shadow (**visible** with the countdown) | Make it |
| `common/countdown_button.png` (`countdown_button`) | 1536 × 460, petrol-teal ticket with notched ends and stitching, words in `CountdownGeometry.buttonCopy` | "View trip" | A flat ticket in the palette's primary colour with notched ends (**visible**) | Make it |
| `icons/calendar.png`, `icons/attraction.png` | as the kind icons | The "4 days" and "Opens 25 Nov" facts | Material glyphs (**visible**) | Listed below too |

Present and used: `common/countdown_luggage_tag.png` (the blank tag; its
card is `SurfaceSlot.countdownTag.body`, the eyelet is
`CountdownGeometry.eyelet`) and `icons/nav_trips.png` (the bookings fact).
The mockup's tree and postmark motif on the tag isn't drawn: the tag stays
blank and every word on it is live.

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
the tagged cards' luggage tags and compact rows. Present: `flight`,
`dining`. **Missing:** `stay`, `attraction`, `transport`, `activity`,
`event`, `note`, and `calendar` (the header pill on days without a
forecast). The kind's Material glyph stands in (visible wherever that kind
shows a tag or row). The reference's dinner tag prints a hibiscus. That's
a decorative motif, not a kind icon, so it isn't modelled; dinner tags show
the dining icon.

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
