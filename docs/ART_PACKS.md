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
  `linen`, `leather`, `tab`, `tab_selected`, `tab_add`, `pill` and `stamp`,
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
navigation, kind, weather and timeline icons; linen, leather, tabs, pill
and stamp; the windowed boarding pass, restaurant and travel tickets
(their windows already show the destination's scenes); note paper and the
key tag. A pack may still override any of these by name, in the same
ranks.

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
five complete place packs carry one.

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

It downloads the smallest set that covers the trip: one destination pack and
one pack for the trip's look (ties: drawn for the look, then priority, then
subjects covered, then ID). Classic art is bundled and never downloaded. A
pack matches only at its own scope, so a Kyoto pack never stands in for
Tokyo. Cards then resolve city → region → country → look → secondary look
→ core, by subject first, then generic (`lib/design/art/art_resolver.dart`).
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
packs, all in WebP. `seed_themepark` is for tests and local development
only and is never published.

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
