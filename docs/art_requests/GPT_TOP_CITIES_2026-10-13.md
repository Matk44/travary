# The world's most-visited cities: city art (ChatGPT)

Written 13 October 2026. The aim is a complete look for the 30 cities
travellers visit most. Nine of them already have it; this asks for the
other 21, six pictures each.

Places without their own art keep working as they do now. The app tries
the city's pack, then its region's, then its country's, then the trip's
look (beach, city, alpine, theme park and so on), then the generic
pictures. Postcards fall back to the neutral "anywhere" postcard. Nothing
else is needed for the rest of the world.

**Status, 14 October 2026:** all 21 cities are drawn (126 PNGs, Waves A
and B) and built into packs (`docs/ART_PACKS.md`, "The world's most-visited
cities"); publishing waits for the owner's go-ahead. Still to draw:
onboarding backgrounds for Antalya, Phuket, Milan and Taipei (see the end).
The next batch is `docs/art_requests/GPT_MORE_ART_2026-10-14.md`.

## The message to send

> Make city art for my travel app, Travary. The list, sizes and rules are
> in `docs/art_requests/GPT_TOP_CITIES_2026-10-13.md`: read it first, then
> work through Wave A, one city at a time. For each city make the six
> pictures it lists and save them as PNGs in `art_packs/staging/<folder>/`.
> Tell me when each city is done. Stop and ask if a rule can't be met
> rather than bending it.

## The six pictures for each city

| File | Size | Rules |
|---|---|---|
| `featured_ticket.png` | 1774 × 887, transparent | `art_packs/prompts/city_cards.md`, "Rules for every card", starting from its template in `art_packs/prompts/city_card_references/` |
| `room_card.png` | 1774 × 887, transparent | as above |
| `reservation_card.png` | 1983 × 793, transparent | as above |
| `countdown_postcard.png` | 1122 × 1402 (portrait) | `art_packs/prompts/postcards.md`, countdown postcard |
| `trip_postcard.png` | 1536 × 1024 (landscape) | `art_packs/prompts/postcards.md`, the Trips companion |
| `documents_destination_stamp.png` | 1024 × 1280, transparent | `docs/DOCUMENTS_STAMPS_IMAGEGEN_BRIEF.md`, the destination stamp |

Everywhere: no words, letters, numbers, logos or brand names (the app
prints the place name live), no real people's faces, and no copyrighted
characters. The six pictures for one city should feel like one set: the
same light, palette and landmarks. Match the cities already done; look at
`art_packs/sources/city_fr_paris/common/` and
`art_packs/staging/new_york/` first.

## Wave A: the biggest gaps (10 cities)

| City | Folder | What to show |
|---|---|---|
| London | `london` | Tower Bridge and the Thames, a red double-decker bus, a black cab, Georgian terraces, soft grey-gold light |
| Tokyo | `tokyo` | Shibuya-style crossing lights, Tokyo Tower in red and white, cherry blossom, a bullet train, neon after dusk |
| Bangkok | `bangkok` | Temple spires along the river (Wat Arun-like), long-tail boats, tuk-tuks, a floating market, warm evening sun |
| Rome | `rome` | The Colosseum, umbrella pines, terracotta roofs, a Vespa, a fountain, golden light |
| Barcelona | `barcelona` | Gaudí-style mosaic curves and spires (no exact copy of the Sagrada Família), the beach, palms, warm stone |
| Dubai | `dubai` | A needle-like tower skyline, desert dunes at the edge, a dhow on the creek, a sail-shaped hotel silhouette |
| Istanbul | `istanbul` | Domes and minarets over the Bosphorus, a ferry, gulls, a bridge at sunset, a spice market's colours |
| Amsterdam | `amsterdam` | Canal houses with gables, bicycles on a bridge, a canal boat, tulips |
| Hong Kong | `hong_kong` | Victoria Harbour skyline, a red-sailed junk, a Star Ferry-like boat, the Peak's green slopes |
| Seoul | `seoul` | A palace gate with curved roofs, Namsan tower on its hill, hanok rooftops, autumn maples |

## Wave B (11 cities)

| City | Folder | What to show |
|---|---|---|
| Osaka | `osaka` | A castle keep on stone walls, canal-side neon and food stalls, a lantern street |
| Venice | `venice` | The Grand Canal, gondolas, striped mooring poles, a domed basilica, pastel palazzi |
| Lisbon | `lisbon` | A yellow tram on a hill, tiled façades, terracotta roofs down to the river, a suspension bridge in the distance |
| Madrid | `madrid` | A grand plaza with arcades, a royal palace façade, a park lake with rowing boats, warm stone |
| Prague | `prague` | A stone bridge with statues, a castle on the hill, red roofs, Gothic spires |
| Cancún | `cancun` | Turquoise sea, white sand, palms, a Maya stepped pyramid in the jungle |
| Kuala Lumpur | `kuala_lumpur` | Twin towers, a rainforest edge, a market street, a colourful temple stair |
| Antalya | `antalya` | An old harbour with stone walls, cliffs over a turquoise sea, the Taurus mountains, palms |
| Phuket | `phuket` | Limestone islands rising from the sea, long-tail boats, a white beach, palms |
| Milan | `milan` | A Gothic cathedral's spires (not an exact copy), a glass-roofed arcade, a tram, fashion-window colour |
| Taipei | `taipei` | A bamboo-shaped tower, night market lanterns, green mountains, a temple roof |

## Already covered (nothing to make)

Paris, Kyoto, New York, Orlando and Las Vegas have city packs. Los Angeles
uses California's, Miami uses Florida's and Bali has its own region pack.
Singapore is a city-state, so its country pack is its city art.

## After it's drawn (for the developer, not ChatGPT)

- For each city: a new pack, `art_packs/sources/city_<cc>_<city>/`, holding
  the six PNGs, its country's palette and a `catalog-entry.json` with
  `{"countryCodes": ["<CC>"], "cities": ["<slug>"]}`. The slug must match
  the place's slug in `lib/logic/destinations.dart`. Then `webp` and
  `build` as in `docs/ART_PACKS.md`, one pack at a time, and publish only
  with the owner's go-ahead.
- Hong Kong, Malaysia, Czechia and Taiwan have no country pack, so their
  city packs carry their own postcards (they do anyway). Other places in
  those countries use the trip's look.
- Every Wave A city and most of Wave B already have an onboarding
  background in `assets/onboarding/stages/`. Antalya, Phuket, Milan and
  Taipei don't: they use their country's (Taiwan uses Anywhere) until
  backgrounds are made under `docs/ONBOARDING_DESTINATION_ART.md`.
