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
| `common/linen.png` (`linen`) | 1024 × 1024, seamless tile | Behind every home screen, tiled at 3× density | Flat `#EFE8DC` (**visible**: no weave) | Make it (brief batch 1) |
| `common/leather.png` (`leather`) | 1536 × 1024, tiles left to right, stitching 12% from the top | The strip under the home tabs, filling the bottom safe area (34 pt on the reference phone), `BoxFit.cover`, top-aligned | Nothing is drawn. Per the spec the strip appears only when the raster exists (**visible**: tabs run to the screen edge) | Make it |
| `common/tab.png` (`tab`) | 720 × 1024 (≈ 0.7:1), cream canvas file tab, rounded top corners; the top 60% shows, the foot runs under the leather | Trips, Documents and Profile tabs. Drawn `BoxFit.cover`, top-aligned, never stretched | Flat cream rounded tab with a soft shadow (**visible**) | Make it |
| `common/tab_selected.png` (`tab_selected`) | 720 × 1024, the same tab in a **neutral near-white** fabric | The selected tab, multiplied by the trip palette's `ui.primary` (teal for Travary's own palette) | Flat `ui.primary` tab (**visible**) | Make it neutral so any palette can tint it |
| `common/tab_add.png` (`tab_add`) | 720 × 1024, coral `#E5785B` fabric tab | The central add tab | Flat coral tab (**visible**) | Make it |
| `common/pill.png` (`pill`) | 1536 × 512 (3:1), raised cream pill, empty | Header weather or countdown pill, drawn 35 pt tall at its own aspect | Flat cream pill with a soft shadow (**visible**) | Make it |
| `icons/nav_wallet.png` (`nav_wallet`) | 1024 × 1024, one-colour navy ink, transparent, content ≈ 50% of the canvas like `nav_today` | Documents tab (the ticket wallet) | Material `description` glyph (**visible**) | A document/ticket-wallet icon |
| `icons/nav_profile.png` (`nav_profile`) | as above | Profile tab | Material `person` glyph (**visible**) | Make it |
| `icons/nav_add.png` (`nav_add`) | as above, a bold plus | Add tab | Material `add` glyph (**visible**) | Make it |
| `icons/weather_sunny.png` (`weather_sunny`) | 1024 × 1024, full colour allowed (drawn untinted) | Header pill when a forecast is given ("28° Sunny") | Material sun glyph in coral (**visible**) | Make it; also `weather_cloudy`, `weather_rain`, `weather_snow` |
| `icons/timeline_stop.png` (`timeline_stop`) | 256 × 256, one-colour ink dot, tinted `ui.secondary` | Day timeline stops | Plain round dot (**visible**, matches the reference closely) | Optional |
| `icons/timeline_now.png` (`timeline_now`) | 256 × 256, one-colour ring, tinted `ui.highlight` | The stop happening now | Plain dot with a halo (not in the morning reference) | Optional |
| `dining/themepark_castle_01_vignette.png` (+ `_scene`) | 1024 × 1024 transparent (scene 1536 × 1024) | "Be Our Guest Restaurant" (subject `castle`) on a theme-park trip | The generic `dining/any_bistro_01_vignette.png` (**visible**: the reference shows a castle) | In the brief's start list |
| `dining/themepark_grill_01_vignette.png` (+ `_scene`) | as above | "Ohana" (subject `grill`) on a theme-park trip: palm, low sun, waves | The bistro vignette (**visible**) | Make it |

Present and used: every shell family (below), `icons/dining.png`,
`icons/flight.png`, `icons/nav_today.png`, `icons/nav_trips.png`, and all
eight `any_*`/`themepark_*`/`tropical_*` scene and vignette pairs.

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
| `common/boarding_pass.png` | 1774 × 887 | Flights that are "next up" use the look's featured ticket | Yes, on travel days |
| `common/travel_ticket.png` | 1983 × 793 | Transport uses the tagged card | Yes |
| `common/note_paper.png` | 1983 × 793 | Notes use the tagged card | Yes |
| `common/stamp.png` | 1536 × 464 (the printed frame's 3.3:1), empty inked stamp frame | "Show tickets" on tickets that don't print a frame (every family but the theme-park anchor): a plain paper button with an ink border | Yes, on non-theme-park trips |

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
