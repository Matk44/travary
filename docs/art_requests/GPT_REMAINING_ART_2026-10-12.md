# Remaining artwork for launch (ChatGPT)

Written 12 October 2026. Everything Travary still needs drawn before launch,
in one request. No new Travi poses or films are needed: his extra moments
reuse films that already exist.

## The message to send

> Make the remaining artwork for my travel app, Travary. The full list,
> sizes and rules are in `docs/art_requests/GPT_REMAINING_ART_2026-10-12.md`:
> read it first, then work through the items in order. Match the existing
> "travel ephemera" look: printed paper, letterpress ink, warm vintage travel
> posters. Save every file as a PNG in `art_packs/staging/` under the folder
> each item names (never over the app's own files). Tell me when each item
> is done, and stop if a rule can't be met rather than bending it.

## Rules for everything

- PNG, exactly the size given. Transparent background wherever it says so.
- No words, letters, numbers, logos or brand names anywhere in the art. The
  app prints all text live.
- No real trademarks, park characters or recognisable attractions (no
  castles that look like a real theme park's, no named rides).
- Keep to the existing palette and finish: look at the files named under
  "Look at first" before drawing.

## 1. Cards: two places

Follow every rule in `art_packs/prompts/city_cards.md` ("Rules for every
card"). Start each card from its template in
`art_packs/prompts/city_card_references/` and change only the picture: the
outline, notches, perforations, stub, cord, grommet, tag and every blank
area stay exactly where they are. Ticket and key card 1774 × 887,
reservation card 1983 × 793, transparent background.

**1a. The Lake District** → `art_packs/staging/lake_district/`
`featured_ticket.png`, `room_card.png`, `reservation_card.png`.
The pack currently reuses Great Britain's cards. Picture: fells and a still
lake (Windermere-like), a wooden launch or rowing boats, dry-stone walls,
slate cottages, a few Herdwick sheep, soft English light.

**1b. The United States, place-neutral** → `art_packs/staging/united_states/`
`featured_ticket.png`, `room_card.png`, `reservation_card.png`.
These replace the country's current cards, which show the Golden Gate Bridge
and look wrong on an Orlando or New York trip (cities with their own pack
keep theirs). Picture: Americana that belongs to no one city: an open
two-lane highway, a roadside diner or motel sign without lettering, wide sky,
a little flag bunting, a mix of landscape. No recognisable bridge, skyline,
monument or park.

## 2. Interface pieces → `art_packs/staging/interface/`

Save each under the path given (it mirrors `assets/art/`).

| File | Size | What it is |
|---|---|---|
| `common/leather.png` | 1536 × 1024, tiles seamlessly left to right | A strip of dark navy leather with a line of cream stitching 12% from the top. It fills the bottom edge under the home tabs. |
| `common/pill.png` | 1536 × 512, transparent | A raised, empty cream paper pill with a soft shadow, for the header's date or weather. |
| `icons/weather_sunny.png` | 1024 × 1024, transparent | A sun, full colour allowed, in the letterpress style of the other icons. Content about 50% of the canvas. |
| `icons/weather_cloudy.png` | as above | A cloud. |
| `icons/weather_rain.png` | as above | A cloud with rain. |
| `icons/weather_snow.png` | as above | A cloud with snowflakes. |
| `icons/checklist.png` | 1024 × 1024, transparent, one colour (navy ink) | A luggage label or note with two ticked lines, matching `icons/passport.png`. |
| `dining/themepark_castle_01_vignette.png` | 1024 × 1024, transparent | A fairytale castle dining room, generic (not any real park's castle), for a theme-park restaurant. |
| `dining/themepark_castle_01_scene.png` | 1536 × 1024 | The same subject as a full scene. |
| `dining/themepark_grill_01_vignette.png` | 1024 × 1024, transparent | A tropical grill: palms, low sun, waves. Its scene already exists: match it. |

Vignette and scene rules: `docs/ART_BRIEF.md`.

## 3. The neutral countdown postcard → `art_packs/staging/interface/common/`

`countdown_postcard_anywhere.png`, 1122 × 1402. The postcard Today shows
before a trip whose place has no postcard of its own. The current one is a
stand-in. Follow the prompt in `art_packs/prompts/postcards.md`: a
place-neutral travel scene, no landmark that names a country.

## Look at first

- `art_packs/prompts/city_card_references/` and `art_packs/staging/*/`:
  the card style and the US cities already drawn.
- `assets/art/icons/` (`passport.png`, `nav_today.png`): the letterpress icons.
- `assets/art/common/linen.png`, `tab.png`, `tab_selected.png`: the surfaces.
- `assets/art/dining/`: existing vignettes and scenes.
- `docs/ART_ASSET_GAPS.md`: where each piece shows in the app.

## After it's drawn (for the developer, not ChatGPT)

- Cards: convert and build as in `docs/ART_PACKS.md` (Lake District into
  `region_gb_lake_district`, the US cards into `country_us`, bump each
  pack's version), then publish with the owner's go-ahead.
- Interface pieces: move into `assets/art/` at the same paths; the app
  picks them up with no code change (`docs/ART_ASSET_GAPS.md`). Update that
  file's table.
- Postcard: convert to WebP as `assets/art/common/countdown_postcard_anywhere.webp`.
