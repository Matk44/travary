# More art: onboarding backgrounds, nine cities, seven countries and the stamps (ChatGPT)

Written 14 October 2026, after the 21 top cities (`GPT_TOP_CITIES_2026-10-13.md`)
were built into packs. This is the next batch, in the order it's worth doing.
**163 pictures in four waves.** Every wave stands alone and the app already
copes without any of it: a place with no art of its own falls back to its
region's, then its country's, then the trip's look, then the neutral pictures.
So stop after any wave and nothing is half-done.

| Wave | What | Pictures |
|---|---|---|
| **C** | Onboarding backgrounds for Antalya, Phuket, Milan and Taipei | 4 |
| **D** | Nine cities that have a background but no cards yet | 9 × 6 = 54 |
| **E** | Seven countries with no art at all (E1), then three more (E2) | 7 × 7 + 3 × 6 = 67 |
| **F** | Documents stamps for the 25 country packs (F1) and 13 US places (F2) | 25 + 13 = 38 |

Wave order: **C, D, E1, F1, E2, F2.**

**Status (15 October 2026): all 163 pictures drawn, checked and integrated.**
C: four backgrounds bundled. D: nine city packs. E1 and E2: ten country
packs, and E1's seven backgrounds bundled. F1 and F2: a Documents stamp
added to the 25 older country packs and the 13 US city and region packs (new
versions). Catalog v234, 83 packs, **published on 15 October 2026**.

## The message to send

> Make more art for my travel app, Travary. The list, sizes and rules are in
> `docs/art_requests/GPT_MORE_ART_2026-10-14.md`: read it, and the files it
> points to, first. Then work through Wave C, then D, E1, F1, E2 and F2, one
> place at a time. Save everything where the document says. Tell me when each
> wave is done. Stop and ask if a rule can't be met rather than bending it.

## Read first

1. `docs/art_requests/GPT_TOP_CITIES_2026-10-13.md`: the last request. The
   sizes, the six pictures and the "Rules for every picture" below are the
   same.
2. `art_packs/staging/top-cities-wave-a-2026-10-13/README.md` and
   `art_packs/staging/top-cities-wave-b-2026-10-13/README.md`: how those 126
   pictures were made and checked, with their tools (`export_cards.cjs`,
   `export_city.py`, `finalize.py`, `stamp-template.png`). Reuse them.
3. **`art_packs/staging/key-card-backdrop-fix-2026-10-14/README.md`: use its
   `export_cards_clean_backdrop.cjs`, not the old `export_cards.cjs`.** Four
   of the 21 key cards came back with stray speckle in the part that must stay
   blank, because the old script read scenery bleed into the card's paper. The
   rule that prevents it is under "Rules for every picture".
4. `art_packs/staging/top-cities-wave-a-2026-10-13/overview.png` and
   `top-cities-wave-b-2026-10-13/overview.png`: the approved look. Match it.
   For the US, also `art_packs/staging/new_york/`.

## Rules for every picture

Everything in the last request still holds. In short:

- **Card templates:** `art_packs/prompts/city_card_references/` (`featured_ticket`,
  `room_card`, `reservation_card`). Same canvas, outline, notches, perforations,
  barcode stub, cord and brass grommet; only the scene and the thin stripe and
  tag colour change. Mechanical template compositing is authorised.
- **Sizes**, PNG RGBA 8-bit, embedded sRGB, real transparency outside the
  object:

  | File | Size |
  |---|---|
  | `featured_ticket.png` | 1774 × 887 |
  | `room_card.png` | 1774 × 887 |
  | `reservation_card.png` | 1983 × 793 |
  | `countdown_postcard.png` | 1122 × 1402 (portrait) |
  | `trip_postcard.png` | 1536 × 1024 (landscape) |
  | `documents_destination_stamp.png` | 1024 × 1280 |
  | `onboarding_stage_v1.png` | 851 × 1848, opaque (Wave C and the E1 stages) |

- **Blank areas stay blank:** the ticket's left 42%, the key card's left 38%,
  the middle of the reservation card, and the stamp's label band.
- **The key card's picture is full height** (top to bottom of the card,
  starting about 43% across, like the Paris card), and **nothing but paper
  left of it**: no speckle, haze, texture or a faint echo of the scene in the
  left 38%. The compositor (`export_cards_full.cjs`, 15 Oct 2026) takes the
  card's paper from the generated image's x 430–630 (of 1774) and lays the
  rest straight on from x 690, so keep the generated key-card image **pure
  paper left of x 700**. (An earlier export squeezed the picture into a small
  corner patch to keep the left 62% empty; that looked too small and was
  replaced.) Run the speckle check below on every key card, and look at a
  contact sheet of the right 60% of all of them before calling a wave done.
- **Words:** no text, letters, numbers, logos, brand names, flags or
  pseudo-text anywhere, **including decorative script** (no hieroglyphs,
  Arabic or Chinese lettering, even as pattern). The app prints the place name
  live. No real people's faces and no copyrighted characters; people as small
  silhouettes are fine.
- **Style:** mid-century travel poster, screen-printed: flat layered shapes,
  fine paper grain, warm low sun, never photographic. One set of six per place
  should feel like one set: the same light, palette and landmarks.
- Use each place's famous landmarks freely. Where a building is marked "not an
  exact copy", evoke it without reproducing it.
- Postcards: `art_packs/prompts/postcards.md` (deckled cream edge, soft shadow,
  quiet upper-right for the luggage tag; on the landscape one the key subject
  in the left 60%). Stamp: the Paris stamp's paper, perforations and keyline,
  with the picture fitted into the measured box and the label band left blank
  (the Wave A/B README and `stamp-template.png` have the numbers).
- Resize only uniformly. Generate again rather than repairing with heavy
  editing.

## Wave C: four onboarding backgrounds

The onboarding story plays on a painted stage for the traveller's destination.
Antalya, Phuket, Milan and Taipei have cards now but no stage of their own, so
they show their country's (Taiwan has none, so it shows the neutral one).

**How:** exactly as the earlier city stages, from
`docs/onboarding/IMAGEGEN_CITY_BATCH_HANDOFF.md` (its prompt, composition
zones and workflow) and the "Reusable generation brief" in
`docs/ONBOARDING_DESTINATION_ART.md`. References for each: the clean Bali
stage (`docs/mockups/onboarding-folio-motion-v1/bali-stage-prop-free-v1.png`),
the place's own countdown postcard (`art_packs/staging/<folder>/countdown_postcard.png`),
and a sibling stage already in the app (`assets/onboarding/stages/`) so the set
stays even. One image per place, **851 × 1848**, opaque, no Travi, folio,
tickets, text or UI. Measure the real size; don't assume.

| Place | Save as | Show (from its own postcard) | Match |
|---|---|---|---|
| Antalya | `art_packs/pending/onboarding/city_tr_antalya/onboarding_stage_v1.png` | an old stone harbour and walls, a fluted minaret, cliffs over a turquoise sea, the Taurus mountains, palms and sailboats | `city_tr_istanbul.webp` |
| Phuket | `art_packs/pending/onboarding/region_th_phuket/onboarding_stage_v1.png` | limestone islands rising from a green-blue sea, longtail boats, a white beach, palms | `country_th.webp` |
| Milan | `art_packs/pending/onboarding/city_it_milan/onboarding_stage_v1.png` | a Gothic cathedral's white spires (not an exact copy), a glass-roofed arcade, a yellow tram, warm shopfront colour | `city_it_rome.webp` |
| Taipei | `art_packs/pending/onboarding/city_tw_taipei/onboarding_stage_v1.png` | a bamboo-shaped tower, night-market lanterns, green mountains, a temple roof | `city_kr_seoul.webp` |

(Phuket is a region in the app, which is why its folder says `region_`.) Log
the prompts and sources the way the earlier batch did, in
`docs/mockups/onboarding-city-stages-v1/`, and update
`docs/onboarding/DESTINATION_ART_REGISTER.md` and its JSON ledger.

## Wave D: nine cities, six pictures each

All nine already have an onboarding background, so travellers see their city
on the first screen and then plain country cards from then on. The six
pictures are the same as for the 21: `featured_ticket`, `room_card`,
`reservation_card`, `countdown_postcard`, `trip_postcard` and
`documents_destination_stamp`. Save in `art_packs/staging/<folder>/`.

"Stripe and tag" is the three colours for the thin decorative stripe and the
luggage tag (the earlier request called them the palette).

| City | Folder | What to show | Stripe and tag |
|---|---|---|---|
| Edinburgh | `edinburgh` | a castle on its black volcanic rock above a garden valley, the Royal Mile's tall stone tenements, a Gothic monument spire, a green crag-topped hill, a piper's silhouette, thistles, gold-grey northern light | slate blue, thistle purple, heather gold |
| Sydney | `sydney` | a white sail-roofed opera house on the harbour, a steel arch bridge, a ferry, jacaranda in bloom, a gold harbour sunset | harbour blue, jacaranda violet, sandstone gold |
| Melbourne | `melbourne` | a yellow-domed Victorian railway station with a clock, a green-and-cream tram, a laneway café with abstract colourful murals (nothing readable), rowing sheds on the river, the skyline | tram green, laneway orange, plum |
| Florence | `florence` | a red-tiled cathedral dome with a striped bell tower, the river with a covered bridge of little shops, cypress hills, terracotta roofs, golden hour | terracotta, cypress green, cream gold |
| Athens | `athens` | the Parthenon on its rock, whitewashed old-quarter houses stepping down with bougainvillea, olive and pine, a pine-clad hill with a small chapel, deep Aegean light | Aegean blue, olive green, gold |
| Vancouver | `vancouver` | glass towers on a harbour backed by snowy mountains, a seaplane, a white sail-roofed waterfront pavilion, the seawall and tall cedars, a ferry, autumn colour | spruce green, ocean teal, maple red |
| Cape Town | `cape_town` | a flat-topped mountain under a tablecloth of cloud, a cable car, a street of brightly painted hillside houses, penguins on a granite beach, proteas, a Cape Dutch gable | ocean blue, protea pink, sunlit gold |
| Queenstown | `queenstown` | a long mountain lake with a vintage steamship, the jagged Remarkables-like range with snow, a gondola on the slope, autumn poplars in gold, a jet boat's wake | alpine blue, autumn gold, pine green |
| San Francisco | `san_francisco` | the Golden Gate Bridge in orange-red with fog rolling through, a cable car climbing a steep street, a row of painted Victorian houses, a pier with sea lions, a pyramid-topped skyline, an island prison silhouette in the bay | bridge orange-red, fog grey-blue, Victorian teal |

`country_us` (v4) deliberately has no Golden Gate, so San Francisco's own
set is where the bridge belongs and it can be the hero. The US rules about
leaving out theme parks, the Hollywood sign, the Space Needle and Cloud Gate
still hold. For the US set, `art_packs/staging/new_york/` is the
nearest reference.

## Wave E: countries with no art

A country pack is what a trip to a whole country, or to any place in it
without its own pack, shows: **all six pictures, drawn for the country as a
whole**, so the scene is two or three landmarks or landscapes, a plant or an
animal and the light (see how `art_packs/prompts/postcards.md` does it for
the 25 countries already done: "Scenes for the 25 country packs"). Save in
`art_packs/staging/country_<cc>/`.

### E1: seven countries, each six pictures and an onboarding background

These are the most-visited countries in the app's own list that have nothing
yet. Also draw each one's onboarding background (country-first coverage is
the owner's rule: one broad scenic stage per country), saved as
`art_packs/pending/onboarding/country_<cc>/onboarding_stage_v1.png`, 851 × 1848,
made as in Wave C and logged the same way, with the country's own postcard as
the content reference. That is 7 pictures per country.

| Country | Folder | Scene | Places it has to suit | Stripe and tag |
|---|---|---|---|---|
| Austria | `country_at` | a turquoise Alpine lake below snow-topped peaks, a village with an onion-domed church tower, a yellow-and-white Baroque palace with a formal garden, a vintage tram, gentians in the foreground | Vienna, Salzburg, the Tyrol | alpine teal, Baroque gold, rose |
| Croatia | `country_hr` | a walled, terracotta-roofed Adriatic old town on a headland with a bell tower and stone harbour, a turquoise bay with white sailboats, cypress and pine, lavender, a limestone island beyond | Dubrovnik, Split, Hvar | Adriatic turquoise, terracotta, cypress green |
| Ireland | `country_ie` | tall green sea cliffs above a deep blue Atlantic, a round stone tower and a ruined abbey arch, dry-stone walls round small green fields, a whitewashed thatched cottage, sheep, a rainbow after a soft shower (no shamrocks, harps or leprechauns) | Dublin, Galway | emerald, stone grey, soft gold |
| Vietnam | `country_vn` | an emerald bay of limestone towers with a red-sailed wooden junk, a lantern-hung old-town street with a covered bridge, terraced rice hills, a lotus pond, conical hats as shapes (no faces) | Hanoi, Ho Chi Minh City, Ha Long Bay, Hoi An | jade green, lantern red, lotus pink |
| Morocco | `country_ma` | a rose-red walled medina with a tall square minaret at sunset, a keyhole-arched doorway tiled in abstract geometric patterns, a camel train on golden dunes, palms, mounds of coloured spice (no script, even as pattern) | Marrakech | rose red, indigo blue, saffron |
| Egypt | `country_eg` | three stepped-triangle pyramids at golden hour on the desert's edge, a felucca with a white sail on the Nile, date palms, a temple with papyrus-bud columns, a camel silhouette, a strip of turquoise Red Sea (no hieroglyphs) | Cairo, Luxor, Sharm El Sheikh, Hurghada | desert gold, Nile turquoise, lapis blue |
| Hungary | `country_hu` | a grand riverside Gothic Revival parliament-like building with a dome and many spires (not an exact copy) reflected in a wide river, a chain suspension bridge, a hilltop castle, a steaming domed thermal bath, strings of red paprika, a yellow tram | Budapest | Danube blue, paprika red, gold |

### E2: three more, six pictures each (lowest priority)

Places whose only art today is one city. A trip to "Czechia", "Malaysia" or
"Taiwan" as a whole, or to anywhere else in them, gets the neutral look.
**These must not repeat the city that already has a pack.** No onboarding
background is needed (their city stage stands in).

| Country | Folder | Scene |
|---|---|---|
| Czechia | `country_cz` | a fairy-tale castle on a rocky bluff above a looping river and a red-roofed old town (the south Bohemian kind, not Prague), hop fields and birch woods, a Baroque church spire, a spa colonnade |
| Malaysia | `country_my` | limestone islets and a white beach with palms, a rainforest canopy with a hornbill, a colourful old-port shophouse street with a trishaw, a gold-domed mosque, tea-plantation hills (no twin towers: Kuala Lumpur has its own pack) |
| Taiwan | `country_tw` | terraced tea hills in mist, a narrow-gauge mountain train through bamboo, a marble gorge with a suspension bridge, a lantern-lit mountain village street, sky lanterns rising (no bamboo-shaped tower: Taipei has its own pack) |

Stripe and tag: Czechia garnet, hop green and old gold; Malaysia rainforest
green, songket gold and hibiscus red; Taiwan tea green, lantern amber and
temple red.

## Wave F: Documents stamps

The Documents tab's heading shows a stamp for the traveller's current or next
trip, **only** from that trip's own city, region or country pack. Today the 5
older packs and the 21 new ones have one; none of the 25 country packs does,
and only Orlando among the US places. A trip to a whole country, or to a place
in it with no pack of its own, shows no stamp at all. Each stamp is one
picture, 1024 × 1280, on the Paris stamp's paper with a blank label band.

### F1: the 25 country packs (do these first)

`AE AU BR CA CH CN DE ES FR GB GR ID IN IT JP KR MX NL NZ PT SG TH TR US ZA`.
The scene for each is that country's row in "Scenes for the 25 country packs"
in `art_packs/prompts/postcards.md`, recomposed for a portrait frame with one
clear subject (a stamp is small: bold shapes, no fine detail). Save as
`art_packs/staging/country_<cc>/documents_destination_stamp.png`, lower-case
code (`country_ae`, `country_au`, and so on).

### F2: 13 US places (after E2)

Each place's stamp is its ticket scene from the table in
`art_packs/prompts/city_cards.md` (pick the one or two best-known subjects).
Save as `documents_destination_stamp.png` in the place's existing staging
folder: `new_york`, `las_vegas`, `washington_dc`, `chicago`, `boston`,
`new_orleans`, `nashville`, `seattle`, `florida`, `california`, `hawaii`,
`arizona`, `alaska`. (Orlando has one already.)

## Checks before saying a wave is done

For every picture: exact size, RGBA, embedded sRGB, real alpha (not a colour
key), transparent corners, and the earlier checks (card alpha and protected
pixels identical to the template, barcode stub and eyelet, blank reservation
centre, blank stamp label). `finalize.py` in the Wave B folder does these.
Then the new one, for every `room_card.png`, `featured_ticket.png` and
`reservation_card.png`. It counts stray pixels in the part that must be blank.
Zero is the target; a handful is fine; **more than about 10 means look at it
and redo it**. (Prague's, before it was fixed, scored 1,849.)

```python
from PIL import Image, ImageChops, ImageFilter

ZONES = {  # left, right as fractions of the width
    "featured_ticket": (0.08, 0.42),
    "room_card": (0.10, 0.36),
    "reservation_card": (0.30, 0.62),
}

def stray_pixels(path, kind):
    left, right = ZONES[kind]
    m = Image.open(path).convert("RGBA")
    box = (int(m.width * left), int(m.height * 0.18), int(m.width * right), int(m.height * 0.82))
    crop = m.crop(box)
    rgb = crop.convert("RGB")
    r, g, b = ImageChops.difference(rgb, rgb.filter(ImageFilter.MedianFilter(7))).split()
    noisy = ImageChops.lighter(ImageChops.lighter(r, g), b).point(lambda v: 255 if v > 30 else 0)
    inside = crop.getchannel("A").point(lambda a: 255 if a > 250 else 0)
    return ImageChops.multiply(noisy, inside).histogram()[255]
```

Also make, for each wave, one contact sheet of every new key card's right 60%
on a paper-coloured background, and look at it. Light/dark review sheets per
city as before.

## What to deliver

- The pictures where each wave says (staging for cards, postcards and stamps;
  `art_packs/pending/onboarding/` for backgrounds). Don't touch the existing
  21 cities' folders or any pack source, catalogue or WebP.
- A README per wave in `art_packs/staging/<wave-folder>/` (for example
  `more-art-wave-d-2026-10-14/`) in the Wave A/B style: what's there, the
  validation results and hashes, the exact prompts and sources, anything you
  rejected and why, and any rule you couldn't meet.
- A short note to Claude at the end of each README, like Wave B's.
- Nothing in `lib/`, `assets/` or `art_packs/sources/`: app integration and
  publishing are separate.

## After it's drawn (for the developer, not ChatGPT)

- **Wave D:** a pack per city, `art_packs/sources/city_<cc>_<city>/`
  (`city_gb_edinburgh`, `city_au_sydney`, `city_au_melbourne`, `city_it_florence`,
  `city_gr_athens`, `city_ca_vancouver`, `city_za_cape_town`, `city_nz_queenstown`,
  `city_us_san_francisco`) with its country's palette and a `catalog-entry.json`
  `{"countryCodes": ["<CC>"], "cities": ["<slug>"]}`, exactly as for the 21
  (`docs/ART_PACKS.md`, "The world's most-visited cities"). San Francisco's
  pack outranks California's. Slugs checked against `lib/logic/destinations.dart`.
- **Wave E:** `country_<cc>` packs, each with a new palette written from the
  landscape and crafts, never a flag (`DestinationPalette`: contrast 4.5:1).
  Czechia, Malaysia and Taiwan can reuse their city pack's palette
  (`czechia_garnet_roofs`, `malaysia_rainforest_songket`, `taiwan_jade_lantern`).
  The seven stages go into `onboardingCountryStages` in
  `lib/logic/onboarding_art.dart` (851 wide WebP in `assets/onboarding/stages/`)
  (Czechia and Malaysia keep their city stage as the stand-in in
  `onboardingCountryCities`, since E2 draws no background for them).
- **Wave C:** Antalya, Milan and Taipei into `onboardingCityStages`. Phuket is
  a region, and `onboardingStage` only looks up cities and the Bali exception,
  so it needs a small region lookup first.
- **Wave F:** each stamp joins its existing pack as `documents_destination_stamp`,
  which means a **new version of every pack that gets one** (`country_ae`
  v3 → v4 and so on, and the US city and region packs v1 → v2: a published
  version never changes). Check `test/tool/art_pack_sources_test.dart` and
  `test/logic/world_city_packs_test.dart`, extend
  `test/visual_qa/world_city_cards_test.dart` for the new cities, and check
  every new key card for speckle as above.
- Convert and build one pack at a time. Publish only with the owner's go-ahead.

## Not in this request

Holiday regions (Santorini, Mallorca, the Algarve, Amalfi, the Côte d'Azur,
Tenerife, Scotland, Cappadocia, the Riviera Maya), more cities (Mexico City,
Berlin, Vienna, Dubrovnik, Budapest, Marrakech, Cairo, Hanoi, Porto, Seville,
Nice, Toronto and so on) and the remaining countries in the popular list
(Iceland, Malta, Cyprus, Poland, Belgium, the Nordics, Sri Lanka, the
Caribbean). Ask before starting any of them.
