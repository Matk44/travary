# Art packs: authoring, publishing, delivery

The core art (`assets/art/`) ships with the app and always works offline.
Destination and extra experience art ships as **art packs**: versioned zips
in Firebase Storage that the app downloads when a trip needs them. Gemini
never picks files or packs: the server classifies a trip into a profile
(`docs/VISUAL_PROFILES.md`), and the app matches that profile to the
validated catalog.

```
art-packs/catalog.json                  the only discovery point (≤ 2 MiB)
art-packs/<pack-id>/<version>/pack.zip  pack.json + images
```

Signed-in travellers can read `art-packs/**`; nobody can write it from an
app (`storage.rules`). Publishing is an operator action with this repo's
tool and the operator's own Google credentials.

## A pack's source

```
art_packs/sources/<pack-id>/
  pack.json            the manifest that goes into the zip
  catalog-entry.json   how the catalog lists the pack
  <folder>/<image>     every image pack.json declares, and nothing else
```

Folders: `common`, `icons`, `flight`, `stay`, `attraction`, `dining`,
`transport`, `activity`, `event`, `note`. Images are PNG, WebP or JPEG only,
named `[a-z0-9][a-z0-9_-]*.<ext>`. No SVG, HTML, scripts, fonts, binaries,
sub-folders, symlinks or `.DS_Store` files.

`pack.json` describes every image explicitly (the app never infers meaning
from folder names):

```json
{
  "schemaVersion": 1,
  "packId": "city_jp_kyoto",
  "version": 3,
  "palette": {
    "id": "kyoto_autumn",
    "anchors": {"ink": "#1C2A47", "paper": "#F8F4EC"},
    "accents": ["#9B4F3F", "#C58A3A", "#647A5E", "#6A3F5F"],
    "ui": {"primary": "#6A3F5F", "secondary": "#647A5E", "highlight": "#C58A3A", "onPrimary": "#F8F4EC"}
  },
  "assets": [
    {
      "file": "transport/urban_heritage_train_01_scene.webp",
      "kind": "transport",
      "theme": "urban_heritage",
      "subject": "train",
      "group": "urban_heritage_train_01",
      "format": "scene",
      "width": 1536,
      "height": 1024
    },
    { "file": "icons/dining.png", "kind": "icon", "name": "dining", "width": 1024, "height": 1024 },
    { "file": "common/tag.png", "kind": "common", "name": "tag", "width": 1024, "height": 1536 }
  ]
}
```

- `kind`: a booking kind (the file must be in that folder), or `icon`
  (`icons/`) / `common` (`common/`) with a `name`.
- `theme`: an experience theme (`lib/domain/visual_profile.dart`) or `any`.
- `subject`: a subject for that kind (`lib/logic/art_subjects.dart`) or
  `generic`.
- `format`: `scene` (landscape, left side calm), `vignette`, or `both`.
  One scene and one vignette per group at most.
- `width`/`height`: the image's real size; the publisher checks it.
- `common` names the app looks up: the card shells `featured_ticket`
  (1774 × 887), `room_card` (1774 × 887), `reservation_card` (1983 × 793,
  a tagged card with its illustration printed in),
  `reservation_card_blank` (1983 × 793), `boarding_pass`,
  `featured_reservation`, `travel_ticket` (1774 × 887, with a transparent
  picture window), `note_paper` (1983 × 793), `ongoing_tag` (1983 × 466),
  the Documents list's stamp frames `documents_stamp_01`, `_02` and `_03`
  (1024 × 896, with a transparent scene window in the same place as the
  bundled ones), its `documents_postmark` (1024 × 1024) and
  `documents_cancel_lines` (1536 × 384, both one-colour ink), the
  Documents heading's `documents_destination_stamp` (1024 × 1280,
  destination packs; see below), the interface surfaces
  `linen`, `tab`, `tab_selected`, `tab_add`, `pill` and `stamp`,
  and the countdown to the next trip (Today between trips):
  `countdown_postcard` (1122 × 1402, destination packs; see below),
  `trip_postcard` (1536 × 1024, its landscape companion on the Trips tab),
  `countdown_luggage_tag` (1024 × 1536), the three distinct fact tickets
  `countdown_fact_duration`, `countdown_fact_bookings`, and
  `countdown_fact_opens` (each 1024 × 512), and `countdown_button`
  (1536 × 460). The older shared `countdown_fact_tag` key is still accepted
  as a fallback when a pack does not provide the three individual tickets.
  Shells are made to the same template as the bundled ones (same size and
  zones, no text); a shell of another size is ignored. `icon` names:
  booking kinds (`dining`, `flight`…), `nav_today`, `nav_trips`,
  `nav_wallet`, `nav_profile`, `nav_add`, `weather_sunny`/`_cloudy`/
  `_rain`/`_snow`, `calendar`, `countdown_bookings`, `timeline_stop`,
  `timeline_now`. Sizes and what's still missing from the bundled set:
  `docs/ART_ASSET_GAPS.md`.

- `themes` (optional, on `common` and `icon` entries): the looks a shared
  picture is drawn for, e.g. `["urban_heritage", "classic_travel"]`. Without
  it the picture suits every trip the pack suits. A country isn't a style:
  Japan's historic-city ticket shouldn't dress an Okinawa beach week. Card
  pictures already say this with `theme`: in a destination pack, a picture
  drawn for one look is used only on trips with that look (primary or
  secondary); `any` suits every trip there. A place with several looks gets
  region or city packs (they outrank the country's).

### What goes in a destination pack

Only what changes with the place: complete featured tickets, key cards and
tagged cards with the destination printed on, booking scenes and
vignettes, trip-cover stickers and look emblems, the countdown and Trips
postcards, and the palette.
Everything universal stays bundled and is never duplicated per country:
navigation, kind, weather and timeline icons; linen, tabs, pill
and stamp; the windowed boarding pass, restaurant and travel tickets
(their windows already show the destination's scenes); note paper and the
key tag. A pack may still override any of these by name, in the same
ranks.

### City and region cards (United States)

Thirteen US places have their own featured ticket, key card and tagged
reservation card (mid-century poster scenes on the shared templates, made
from `art_packs/prompts/city_cards.md`), as small place packs on top of
the country's:

| Pack | Scope | Selectors |
|---|---|---|
| `city_us_orlando` (v2) | city | `orlando` |
| `city_us_new_york`, `_las_vegas`, `_washington_dc`, `_chicago`, `_boston`, `_new_orleans`, `_nashville`, `_seattle` | city | `new_york`, `las_vegas`, `washington_dc`, `chicago`, `boston`, `new_orleans`, `nashville`, `seattle` |
| `region_us_florida` | region | `florida`, `florida_keys` |
| `region_us_california` | region | `california` |
| `region_us_hawaii` | region | `hawaii`, `maui` |
| `region_us_arizona`, `region_us_alaska` | region | `arizona`, `alaska` |

Each of these carries what `country_us` has (both postcards and its
palette) beside its three new shells, so a New York trip never loses the US
postcard or colours even before `country_us` (now downloaded beside it, to
fall back on) arrives. Orlando's
city pack outranks Florida's; every other Florida city (Miami, Tampa, the
Keys) gets Florida's, every California city but San Francisco (which has
its own pack, `city_us_san_francisco`: see below) gets California's, and a
US place with neither (Texas, Austin, Denver) stays on the country's
cards. A verified or traveller-chosen place is needed, as
everywhere (`test/logic/us_place_packs_test.dart` pins every case, for the
classifier's places and for "Where to?"). Every one of them has a
Documents stamp too (the 13 drawn on 14 October 2026 are their packs' v2).

Adding a place: put its three PNGs in a new `art_packs/sources/<pack-id>/common/`
with `country_us`'s postcards, a `pack.json` (version 1, the country's
palette, PNG names for the shells), a `catalog-entry.json`, then
`webp` and `build` as below. Replacing a published pack's shells needs a new
version (Orlando went 1 → 2). The WebP step moves each PNG to
`art_packs/originals/<pack-id>/common/`, **replacing a master of the same
name**: keep an old master in git (or copy it away) first.
`test/visual_qa/us_city_cards_test.dart` renders Today on each place's
shells with the real fonts (`tool/visual_qa.sh`,
`build/visual_qa/us_cards_<place>.png`) and checks each card is drawn on the
pack's shells with its live text inside their text zones.

### The world's most-visited cities

Thirty more places have the same six pictures each: a featured ticket,
key card and tagged reservation card, both postcards and a Documents
destination stamp (`art_packs/prompts/city_cards.md` and `postcards.md`; the
briefs were `docs/art_requests/GPT_TOP_CITIES_2026-10-13.md` and, for the
last nine, `GPT_MORE_ART_2026-10-14.md`; the PNGs came from
`art_packs/staging/top-cities-wave-{a,b}-2026-10-13/` and
`more-art-wave-d-2026-10-14/`). Each is a small
place pack like `city_fr_paris`: the six pictures and its country's palette,
nothing else, since a trip also downloads its country's pack to fall back
on.

| Pack | Scope | Selectors | Palette from |
|---|---|---|---|
| `city_gb_london` | city | `london` | `country_gb` |
| `city_jp_tokyo`, `city_jp_osaka` | city | `tokyo`, `osaka` | `country_jp` |
| `city_th_bangkok` | city | `bangkok` | `country_th` |
| `region_th_phuket` | **region** | `phuket` | `country_th` |
| `city_it_rome`, `_venice`, `_milan` | city | `rome`, `venice`, `milan` | `country_it` |
| `city_es_barcelona`, `_madrid` | city | `barcelona`, `madrid` | `country_es` |
| `city_ae_dubai` | city | `dubai` | `country_ae` |
| `city_tr_istanbul`, `_antalya` | city | `istanbul`, `antalya` | `country_tr` |
| `city_nl_amsterdam` | city | `amsterdam` | `country_nl` |
| `city_kr_seoul` | city | `seoul` | `country_kr` |
| `city_pt_lisbon` | city | `lisbon` | `country_pt` |
| `city_mx_cancun` | city | `cancun` | `country_mx` |
| `city_gb_edinburgh` | city | `edinburgh` | `country_gb` |
| `city_au_sydney`, `_melbourne` | city | `sydney`, `melbourne` | `country_au` |
| `city_it_florence` | city | `florence` | `country_it` |
| `city_gr_athens` | city | `athens` | `country_gr` |
| `city_ca_vancouver` | city | `vancouver` | `country_ca` |
| `city_za_cape_town` | city | `cape_town` | `country_za` |
| `city_nz_queenstown` | city | `queenstown` | `country_nz` |
| `city_us_san_francisco` | city | `san_francisco` | `country_us` |
| `country_hk` | **country** | (none; `HK`) | its own: `hong_kong_harbour_junk` |
| `city_cz_prague` | city | `prague` | its own: `czechia_garnet_roofs` |
| `city_my_kuala_lumpur` | city | `kuala_lumpur` | its own: `malaysia_rainforest_songket` |
| `city_tw_taipei` | city | `taipei` | its own: `taiwan_jade_lantern` |

The scope follows how `lib/logic/destinations.dart` models the place, so a
traveller's "Where to?" picks the pack: Phuket is a region there (Thailand's
pack covers Krabi and Koh Samui) and Hong Kong is a country, so its pack
selects `HK` alone. Hong Kong, Czechia, Malaysia and Taiwan have no country
pack, so their palettes are their own (from the harbour at dusk and a junk's
sails, Prague's roof tiles and garnet, rainforest and songket gold, tea
mountains and lantern amber); the other places in those countries keep the
trip's look. `test/logic/world_city_packs_test.dart` pins every case against
the real selectors and the destination list; `test/visual_qa/world_city_cards_test.dart`
renders Today on each pack's shells (`build/visual_qa/world_cards_<place>.png`)
and checks the live text sits inside their zones.

**Key cards are full height.** The key card's picture is the view from a hotel
window, as big as the template's: top to bottom of the card, beginning about
43% of the way across (the Paris, Kyoto and country cards are 78-80% of the
card's height). The first export of the 30 city cards squeezed each picture
into a small bottom-right patch (about 40% of the height, starting at 64%) to
keep the left 62% empty; that looked too small, so on 15 October 2026 all 56
key cards drawn that way (the 30 city and 10 country cards, and the 16 US and
Lake District ones) were made again with the generated picture laid on at its
own size (`export_cards_full.cjs`, `art_packs/staging/key-card-backdrop-fix-2026-10-14/`),
from the original generated images. Their masters in `originals/` are the new
ones; the PNGs in `staging/` are as GPT delivered. The text zone runs to 60%
of the width, so a very long hotel name can reach the picture's soft edge (it
can on Paris too). A new key card is checked for stray speckle in the left
36% (the check in `docs/art_requests/GPT_MORE_ART_2026-10-14.md`) and for its
picture height (70% or more).

### Countries drawn as a whole

Ten countries are packs of their own, drawn for the country (two or three
landmarks or landscapes, a plant or an animal, the light; the briefs are in
`docs/art_requests/GPT_MORE_ART_2026-10-14.md`), each with the same six
pictures. They serve a trip to the whole country and every place in it
without a pack of its own (Vienna, Dubrovnik, Hanoi, Penang and so on); a
city pack, where there is one, still comes first and the country's is
downloaded beside it.

| Pack | Colours | Places it serves |
|---|---|---|
| `country_at` | `austria_alpine_baroque` | Vienna, Salzburg, the Tyrol |
| `country_hr` | `croatia_adriatic_terracotta` | Dubrovnik, Split, Hvar |
| `country_ie` | `ireland_emerald_atlantic` | Dublin, Galway |
| `country_vn` | `vietnam_jade_lantern` | Hanoi, Ho Chi Minh City, Ha Long Bay, Hoi An |
| `country_ma` | `morocco_medina_indigo` | Marrakech |
| `country_eg` | `egypt_nile_lapis` | Cairo, Luxor, Sharm El Sheikh, Hurghada |
| `country_hu` | `hungary_danube_paprika` | Budapest |
| `country_cz` | `czechia_garnet_roofs` (Prague's) | everywhere in Czechia but Prague |
| `country_my` | `malaysia_rainforest_songket` (Kuala Lumpur's) | Penang, Langkawi, the rest of Malaysia |
| `country_tw` | `taiwan_jade_lantern` (Taipei's) | everywhere in Taiwan but Taipei |

Their palettes are written from the landscape and crafts, never a flag. The
seven with no city pack also have an onboarding background (see
`lib/logic/onboarding_art.dart`). Czechia, Malaysia and Taiwan reuse their
city pack's palette and keep its onboarding background as the stand-in.

**Every country pack, and every US city and region pack, now has a Documents
stamp** (the 25 older country packs went v3 → v4, `country_us` v4 → v5, the
13 US places v1 → v2), so a trip to a whole country, or to a place in it
without its own pack, has a stamp for the Documents heading.

### The countdown postcard

Between trips, Today counts down to the next one on its destination's
postcard with a luggage tag hung on the corner
(`lib/design/widgets/countdown_trip_hero.dart`; hand-off:
`docs/COUNTDOWN_HANGING_TAG_HANDOFF.md`). The postcard is
`common/countdown_postcard.png`, 1122 × 1402, a transparent PNG with the
card, its deckled edge and shadow, and a quiet upper-right corner for the
tag. No text, numbers, stamps or tags in the picture: every word is live.

```json
{ "file": "common/countdown_postcard.png", "kind": "common", "name": "countdown_postcard", "width": 1122, "height": 1402 }
```

It resolves like every shared picture (`TravelStore.countdownPostcardFor`):
the trip's city pack, then region, then country, then its look, then the
core. Nothing is bundled, so a trip with no suitable pack keeps Today's
usual first-day view: it never shows another place's postcard.

Five are installed in complete place-pack sources: Lake District and Bali
regions, and Orlando, Kyoto and Paris cities. Each pack contains the full
asset set of its corresponding country pack plus both postcard formats, so
the more specific pack never displaces fuller destination art.

Its landscape companion, `common/trip_postcard.png` (1536 × 1024, the same
scene recomposed, with a quiet upper-right corner), puts a coming trip on
the Trips tab with the same blank tag hung on its right edge
(`lib/design/widgets/upcoming_trip_postcard.dart`; hand-off:
`docs/TRIPS_HANGING_TAG_HANDOFF.md`). It resolves the same way
(`TravelStore.tripPostcardFor`), and a trip without one keeps its plain
row: the portrait countdown postcard is never cropped to stand in.

```json
{ "file": "common/trip_postcard.png", "kind": "common", "name": "trip_postcard", "width": 1536, "height": 1024 }
```

The five landscape postcards live in the same complete packs as their
countdown postcards under `art_packs/sources/`.

The Documents heading's destination stamp, `common/documents_destination_stamp.png`
(1024 × 1280: a perforated portrait stamp with the place's picture and a
blank ivory label band under it, where the app prints the place's name), is
stricter still: it comes only from the trip's own city, region or country
pack (`TravelStore.destinationStampFor`), never a look pack or bundled
art, so a trip without one shows none rather than another place's. The
every pack carries one (the five complete place packs, the 30 city packs,
every country pack and every US city and region pack).

```json
{ "file": "common/documents_destination_stamp.png", "kind": "common", "name": "documents_destination_stamp", "width": 1024, "height": 1280 }
```

These helpers add a stricter gate than general art selection: the
trip location must be `verified`. Demo trips and locations marked
`unverified`, `conflict` or `skipped` keep the existing Today view and plain
Trips rows even when a country or experience pack is installed.

### The palette

A pack may give the trip's interface its colours (optional: packs without
one are valid and the next-ranked palette is used). The destination's
landscape, architecture, crafts, season or time of day suggest it. Never
take it from a flag, and never sample it from pictures. Navy `#1C2A47` and
warm cream `#F8F4EC` are Travary's own anchors.

- `id`: a lowercase slug, like pack IDs.
- `anchors`: exactly `ink` and `paper`.
- `accents`: two to four illustrative colours.
- `ui`: exactly `primary` (the selected home tab, the day chosen in the
  trip calendar), `secondary` (still required, but not drawn at the moment:
  the day's time rail uses `ink`, as a strong accent was too loud down a
  whole screen), `highlight` (category labels, the current stop, today in
  the calendar, focus rings)
  and `onPrimary` (text and icons on `primary`).
- Every colour is an uppercase `#RRGGBB`. No colour repeats within
  `anchors`, `accents` or `ui` (a UI token may reuse an accent or anchor,
  as above). `onPrimary` on `primary` must reach 4.5:1 (WCAG AA, normal
  text). No other keys are allowed.
- A palette that is present but invalid rejects the whole pack: the
  publisher refuses it and the app won't install it
  (`DestinationPalette.parse` in `lib/domain/palette.dart`).

One palette colours the whole trip screen: the best-ranked installed pack
that has one, in the trip's rank order (city → region → country → look →
secondary look → classic; for an unverified destination the look comes
before the country). Otherwise Travary's own palette applies (teal
`#1E5B70` selection, navy `#1C2A47` ink and time rail, coral `#E5785B`
highlights).
Only interface chrome takes these colours; full-colour artwork is never
tinted (`TripColors` in `lib/design/trip_chrome.dart`).

`catalog-entry.json`:

```json
{
  "priority": 400,
  "selectors": {
    "countryCodes": ["JP"],
    "regions": ["kansai"],
    "cities": ["kyoto"],
    "themes": ["urban_heritage"],
    "subjects": ["gardens", "landmark", "train", "bistro"]
  },
  "minAppBuild": 1
}
```

A pack's **scope** is its most specific place selector: `cities`, then
`regions`, then `countryCodes`; with none it's an **experience** pack for its
`themes`. City and region packs must name their country (place names
repeat). Slugs are lowercase ASCII with underscores (`cote_d_azur`); the
server derives the same slugs from the trip's place names. Countries are
ISO 3166-1 alpha-2.

## How the app chooses packs

For each current or coming trip (`lib/logic/art_pack_selection.dart`):

| Location status | Destination packs | Order |
|---|---|---|
| `verified` | city, else region, else country | destination before the trip's look |
| `unverified` (location confidence ≥ 0.8) | country only | the look's pack first |
| `conflict`, `skipped`, no profile | none | |

It downloads, in order: the trip's best destination pack and one pack for
its look (ties: drawn for the look, then priority, then subjects covered,
then ID), then the best destination pack of every other place its bookings
are in, then the country pack of each, for what a city's or region's pack
doesn't draw. Classic art is bundled and never downloaded. A pack matches
only at its own scope, so a Kyoto pack never stands in for Tokyo. Cards then
resolve city → region → country → look → secondary look → core, by subject
first, then generic (`lib/design/art/art_resolver.dart`).

**A trip through several places.** Each card's ranks are at the place its
booking is in (`TripRoute.placeOf`, `lib/logic/trip_route.dart`): where a
transfer arrives, else its address or name, else where the traveller is
staying at its time (a move splits its day at the train's arrival or the
hotel's check-in). On Osaka, Kyoto and Tokyo, Kyoto's days take
`city_jp_kyoto` then `country_jp`, and Osaka's and Tokyo's `country_jp`
until they have packs. Only places in the trip's own country count, or
another that two of its bookings name. The trip's own art (postcards,
palette, Documents stamp) is at `tripArtLocation`: the trip's place, or the
country (or the one region they share) when it stays in several places
there and the traveller didn't choose one.
Card shells, icons and interface surfaces follow the same ranks
(`ArtCatalog.commonArt`/`iconArt`, `ShellResolver`): a destination pack's
`featured_ticket` replaces the bundled ticket, and bundled shells are
chosen by the look (`coastal_resort_featured_ticket.png`).

## Delivery on the phone

`lib/data/art_pack_store.dart` and `lib/data/art_pack_service.dart`:

1. Download to `archives/<id>-<version>.zip.part` (Firebase Storage
   `writeToFile`, signed in).
2. Exact size, then SHA-256 (constant-time compare) against the catalog.
3. Read the zip's directory before inflating anything: entry count and
   total size must equal the catalog's; paths must be plain; no directories,
   symlinks, encryption, ZIP64 or overlapping entries.
4. Inflate each entry as a stream that stops past its declared size, and
   check its CRC-32 and real image signature, into
   `staging/<id>-<version>-<nonce>/`.
5. `pack.json` must name this exact pack and version and declare exactly
   the files present.
6. Atomic rename to `packs/<id>/<version>/`, atomic rewrite of
   `installed.json`, then the old version and the `.part` file go.

Hard limits (`ArtPackLimits`): 100 MiB compressed, 300 MiB expanded, 500
files per pack, 2 MiB catalog, 1 MiB `pack.json`. One download per pack
version at a time; transient failures retry after 2 s and 4 s, then rest
10 minutes; integrity, format, permission and not-found failures aren't
retried in that session.

At startup, installed packs are checked offline (records, `pack.json`, every
file's size); a damaged one is quarantined and downloaded again when
needed. Packs used by current and coming trips are pinned; others count
against a 200 MiB budget and the least recently used go, only after the
catalog has loaded that session. The catalog is refreshed in the background
after sign-in and when the app returns after 6 hours; a malformed, oversized
or older catalog is ignored and the last valid one kept. Installing or
evicting a pack redraws cards at once (`ArtCatalogController`).

## Publishing

Generated art arrives as large PNGs. Convert a new or changed source to
WebP first (needs `cwebp`: `brew install webp`):

```bash
dart run tool/art_packs.dart webp art_packs/sources/<pack-id> [more sources...] [--dry-run]
```

Each PNG that `pack.json` declares becomes a same-size `.webp` (colour at
quality 88, transparency kept exactly, so windows, deckled edges and
shadows stay clean), `pack.json` changes only those file names, and the PNG
original moves to `art_packs/originals/<pack-id>/` (masters, never built or
published). Packs shrink by about 85%: a country pack is about 1 MB, a city
or region pack with postcards about 2.5 MB.

```bash
dart run tool/art_packs.dart build art_packs/sources/<pack-id> --dry-run
```

`build` validates everything the app will (with the same code), checks each
image's real format and size, refuses undeclared or unexpected files,
builds a byte-for-byte reproducible zip (stored, fixed timestamps), extracts
it with the app's own extractor, then writes
`build/art_packs/art-packs/<id>/<version>/pack.zip` and updates
`art_packs/catalog.json` (no duplicate IDs; versions only go up; a published
version never changes; `catalogVersion` goes up by one). Commit
`art_packs/catalog.json` with the source.

```bash
dart run tool/art_packs.dart publish --bucket travary-444.firebasestorage.app --production --dry-run
dart run tool/art_packs.dart publish --bucket travary-444.firebasestorage.app --production
```

`publish` checks every local archive against the catalog, refuses if the
bucket's catalog is newer than yours (pull it first), uploads missing
archives, and uploads `catalog.json` last, so the app never sees a catalog
pointing at a missing archive. It uses `$ART_PACKS_ACCESS_TOKEN` or
`gcloud auth print-access-token`: the operator's own credentials, never
stored in the repository. `--dry-run` reads and writes nothing remote.

Published so far (3 October 2026, catalog v30): 25 country packs, the
Paris, Kyoto and Orlando city packs, and the Lake District and Bali region
packs, all in WebP. Catalog **v96 published 13 October 2026** (43 packs):
Orlando v2, the 13 US city and region packs above, `country_us` v4 and
`region_gb_lake_district` v2. **Catalog v234 published 15 October 2026**
(83 packs, 80 new archives; checked against the bucket afterwards: the
bucket's catalog is identical to `art_packs/catalog.json` and every archive
is there at the right size): the 30 city packs above and the 10 country
packs below, all v1, plus a new version of each of the 25 older country
packs and 13 US city and region packs (now with a Documents stamp and new
key cards; Orlando and the Lake District are v3 because their v2 was
already published). `publish` needs every archive in the bucket or in
`build/art_packs/`, and `build` regenerates a missing archive from its
source without changing the catalog (the zips are reproducible).
`seed_themepark` is for tests and local development only and is never
published.

## Local development with the emulators

```bash
firebase emulators:start --only auth,firestore,functions,storage --project travary-444
dart run tool/art_packs.dart build art_packs/sources/seed_themepark --catalog build/art_packs/catalog.json
dart run tool/art_packs.dart publish --catalog build/art_packs/catalog.json --emulator 127.0.0.1:9199 --bucket travary-444.firebasestorage.app
flutter run --dart-define=TRAVARY_EMULATOR_HOST=127.0.0.1
```

(From the Android emulator use `10.0.2.2`.) The functions emulator needs
`functions/.secret.local` with `GEMINI_API_KEY` and
`GOOGLE_MAPS_PLATFORM_KEY` to classify; `*.local` is git-ignored.
`art_packs/sources/seed_themepark` is a small theme-park pack built from the
approved sample icons, for tests and local development.

All emulator suites (demo project, no credentials):

```bash
tool/run_emulator_tests.sh
```
