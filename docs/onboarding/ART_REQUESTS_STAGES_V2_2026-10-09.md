# Destination stages v2 — every place its own world (9 October 2026)

The first stages were all made from one Bali template: the same teal wall,
arches, orange sun and cream floor, with only the scenery band changing. So
they read as the same picture with different landmarks. Travi is now a
separate cut-out layer, so a stage no longer has to match any other stage.
This brief keeps only what the app needs and frees everything else.

## What every stage must keep (the technical contract)

- **Canvas:** 851 × 1848 portrait PNG.
- **The ground line:** the ground Travi stands on starts at **y ≈ 1200 px**
  (between 1185 and 1215) and continues to the bottom of the image. Travi's
  wheels and the folio stand on this line. Keep it roughly level across the
  width.
- **Travi's spot:** right side, x ≈ 360–830, standing on the ground line,
  about 600 px tall. He's drawn on top, so scenery behind him is fine. Don't
  put anything in front of that spot.
- **Folio's spot:** left side on the ground, x ≈ 0–260. Keep it clear of
  props.
- **Calm top (y 0–560):** the headline sits here in cream and coral letters.
  Keep it soft and low in detail: sky, gradient, gentle clouds. Taller
  landmarks may rise into its lower part, not its middle.
- **Calm, light ground (y 1260 to bottom):** the buttons sit here in navy.
  A pale, quiet surface: sand, snow, pale stone, light boards, matting. No
  strong pattern, nothing dark.
- **Nothing written:** no characters, people, text, signs, numbers, logos,
  flags or watermark.
- **Same family:** keep Travary's handmade folded-paper craft look:
  layered cardstock, paper grain, warm physical light, dimensional depth.
  That shared material is what makes them a family; everything else is
  the place's own.

## What should be the place's own

1. **The stage frame.** Replace the teal wall and arches with a frame that
   belongs to the place: noren curtains and timber beams for Japan,
   whitewashed walls and blue shutters for Greece, a carved chalet balcony
   for Switzerland. Or no frame at all, an open landscape.
2. **Sky, light, season and time of day.** Each its own: Iceland at night
   under the aurora, Dubai at golden dusk, Switzerland on a crisp snowy
   morning. **No shared orange sun.** A sun or moon only where it belongs,
   and never in the same place twice.
3. **The ground.** The real surface of the place, kept pale and calm in its
   lower part: white sand, pale cobbles, snow, a wooden pier, terracotta.
4. **Colour.** Each place's own palette, not teal and cream everywhere.
5. **Depth.** Foreground, middle and far planes, so the place feels deep
   when it folds up behind Travi.

## Direction per place

| Place | Frame | Sky, light, season | Ground | Signature |
|---|---|---|---|---|
| Anywhere | Open, no frame | Soft dawn pastel sky, a few paper birds | Pale sand path | Rolling hills, a winding road to a far coast, a hot-air balloon. No landmark from any country |
| United States | Desert mesa framing | Big blue morning sky | Pale red-sand | Canyon country, a long open road; a distant city skyline on the horizon |
| United Kingdom | Painted theatre flats in muted green | Soft grey-blue sky breaking to sunshine | Pale cobbles | Rolling green fields, dry-stone walls, a village church, red phone box |
| France | Wrought-iron balcony edge, flower boxes | Lavender dusk | Pale stone | Provence lavender rows, hilltop village; a far Eiffel silhouette |
| Italy | Terracotta loggia arches | Warm late-afternoon gold | Terracotta tiles | Tuscan cypresses, vineyards, a hill town, a far dome |
| Spain | Moorish tiled arch | Hot clear afternoon | Pale terracotta | Andalusian white village, orange trees, a far Sagrada-like spire |
| Japan | Noren curtains, timber beams | Spring morning, cherry blossom | Raked pale gravel | Fuji, a pagoda, a torii in water, falling petals |
| Australia | Eucalyptus framing | Dazzling noon blue | Pale beach sand | Sweeping bay, red-rock outback in the distance, a sail-roofed silhouette |
| Mexico | Bright papel-picado bunting | Saturated sunset pink and orange | Sun-bleached plaster | Colonial domes, agave fields, a Caribbean cove |
| Thailand | Carved gilded temple eaves | Warm evening, paper lanterns | Pale teak boards | Limestone islands, a longtail boat, a golden stupa |
| Greece | Whitewashed walls, blue shutters | Brilliant noon light | White stone | Santorini blue domes, Aegean sea, bougainvillea |
| Portugal | Azulejo-tiled wall | Soft Atlantic morning | Pale calçada stones | Lisbon hills, a yellow tram, Algarve cliffs |
| Germany | Half-timbered gables | Fresh spring morning | Pale cobbles | A fairytale castle on a forested hill, Rhine vineyards |
| Canada | Pine-log frame | Clear cold morning, early snow on peaks | Pale lakeshore pebbles | Turquoise mountain lake, Rockies, a canoe |
| Turkey | Ottoman arch with lantern | Dawn, pink sky | Pale stone | Cappadocia rock chimneys with hot-air balloons, a far mosque |
| United Arab Emirates | Carved mashrabiya screen | Golden desert dusk | Pale dune sand | Desert dunes rolling into a gleaming city skyline |
| Netherlands | Canal-house gables | Soft spring sky | Pale brick | Tulip stripes, windmills, a canal with bicycles parked (no riders) |
| Indonesia | Carved Javanese wood frame | Misty sunrise | Pale volcanic sand | Rice terraces, a temple gate, a smoking volcano |
| New Zealand | Fern fronds | Clear alpine afternoon | Pale shingle | Fiords, a waterfall, snowy peaks |
| South Korea | Hanok roof eaves | Crisp autumn, red maples | Pale wooden floor | A palace pavilion, maple hills, a far city of lights |
| Switzerland | Carved chalet balcony | Snowy winter morning | Fresh snow | The Matterhorn, a red mountain train, chalets |
| India | Scalloped palace arch | Pink dawn | Pale marble | A white-domed palace over water, Rajasthan forts, marigolds |
| China | Moon gate, red lacquer | Misty morning | Pale stone | Karst peaks, a river, a pagoda, the Great Wall on a ridge |
| Brazil | Tropical leaves | Bright humid afternoon | Pale beach sand | Rio's Sugarloaf bay, rainforest, a far statue on a peak |
| South Africa | Protea and fynbos framing | Clear Cape light | Pale granite | Table Mountain, a coast road, a far savanna with acacias |

The 30 city stages (Paris, Tokyo, London …) follow the same rules with the
city's own frame, light and ground. Bali keeps its approved stage.

## How to make them

1. **Start with three tests:** Japan, Greece and Switzerland. Claude puts
   them in the app and sends screenshots with Travi standing in them.
2. Once you like the direction, do the rest of the countries, then
   Anywhere, then the cities.
3. Save as `art_packs/pending/onboarding/<id>/onboarding_stage_v2.png`
   (e.g. `country_jp`), with the prompt in the same folder.

### Prompt template (one per place)

```text
Create a portrait 851 x 1848 scenic stage for the Travary travel app's
onboarding, in a handmade folded-paper craft style: layered cardstock,
paper grain, warm physical light, deep foreground, middle and far planes.

Place: [PLACE]. Frame: [FRAME]. Sky and light: [SKY]. Ground: [GROUND].
Signature: [SIGNATURE].

Layout rules:
- The ground the character will stand on starts at y = 1200 px and runs to
  the bottom, roughly level. Below y = 1260 it is pale and calm with no
  strong pattern (buttons go there).
- The top 560 px is calm sky with little detail (a headline goes there).
- Keep the right side (x 360-830) on the ground line free of objects in
  front; a character is placed there later. Keep the left ground
  (x 0-260) clear too.
- This place's own palette, light and frame. No generic orange sun, no teal
  wall with arches.
- No people, animals in the foreground, text, signs, numbers, logos, flags
  or watermark.
```

## What the app adds (no images needed)

Gentle life per place, drawn in code over the stage: falling petals for
Japan and Korea, snow for Switzerland, drifting balloons for Turkey,
lanterns swaying for Thailand, sparkles on the water for Greece. And the
pop-up reveal: the new place folds up behind Travi when it's chosen.
