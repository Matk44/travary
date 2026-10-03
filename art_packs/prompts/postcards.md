# Postcards and stamps for any destination

Every destination pack can carry three pictures that make it feel like
somewhere: the **countdown postcard** (Today, between trips), its
**landscape companion** (the Trips tab) and the **destination stamp** (the
Documents heading). Without them a trip still works: Today counts down on
the neutral postcard and the other two simply don't appear. The five
finished examples are the Paris, Kyoto, Orlando, Lake District and Bali
packs (`art_packs/originals/<pack>/common/`), so use them as visual references.

After generating: put the PNGs in the pack's `common/` folder, declare them
in `pack.json` (snippets below), then run:

```bash
dart run tool/art_packs.dart webp art_packs/sources/<pack-id>
dart run tool/art_packs.dart build art_packs/sources/<pack-id>
dart run tool/art_packs.dart publish --bucket travary-444.firebasestorage.app --production
```

A pack that is already published needs its `version` raised in `pack.json`
before `build`.

## Shared style block (paste first)

> Tactile mid-century travel-poster illustration, screen-printed gouache and
> risograph texture, slightly imperfect ink registration, warm limited
> palette, soft paper fibres. Original artwork: no real logos, brand marks,
> flags, signage or recognisable copyrighted characters. No text, letters,
> numbers, pseudo-text, stamps, postmarks, tags, people's faces, UI or
> watermark. Transparent background outside the object (true alpha).

## 1. Countdown postcard: `common/countdown_postcard.png`, 1122 × 1402

> A single upright vintage postcard, near-square portrait, with a thin
> deckled warm-cream paper edge (about 2% of the width) and a soft drop
> shadow, centred on a transparent background. The picture fills the card
> inside the edge: [SCENE]. Keep the upper-right quarter quiet (open sky or
> soft texture, no key subject): a luggage tag hangs there. Main subject in
> the left and lower two-thirds.

```json
{ "file": "common/countdown_postcard.png", "kind": "common", "name": "countdown_postcard", "width": 1122, "height": 1402 }
```

## 2. Trips postcard: `common/trip_postcard.png`, 1536 × 1024

> The same postcard recomposed in landscape 3:2: thin deckled warm-cream
> edge, soft shadow, transparent outside. The picture: [SCENE], with the key
> subject in the left 60%. Keep the right 35% quieter, especially the upper
> right: a luggage tag hangs over it.

```json
{ "file": "common/trip_postcard.png", "kind": "common", "name": "trip_postcard", "width": 1536, "height": 1024 }
```

## 3. Destination stamp: `common/documents_destination_stamp.png`, 1024 × 1280

> A single portrait postage stamp with perforated edges and a soft shadow on
> a transparent background. The upper 80% is a miniature of [SCENE]; under
> it, a blank warm-ivory label band across the full width (the app prints
> the place's name there, so leave it completely empty).

```json
{ "file": "common/documents_destination_stamp.png", "kind": "common", "name": "documents_destination_stamp", "width": 1024, "height": 1280 }
```

## The neutral postcard (bundled, no place)

`assets/art/common/countdown_postcard_anywhere` (1122 × 1402, WebP or
PNG). Today counts down on it when the next trip's place has no postcard.
It must not suggest any particular country. The current file is a stand-in
made from the bundled plane scene inside the Lake District postcard's frame;
replace it with:

> [Countdown postcard prompt above] with the scene: a vintage propeller or
> jet airliner climbing through warm sunrise clouds over a gentle, generic
> coastline and distant hills, a few birds, open teal sky. Nothing that
> places it: no palms, landmarks, flags or distinctive buildings.

## Scenes for the 25 country packs

Paste into [SCENE]. Each is the country as a whole (a city or region pack
can later give, say, Tokyo or Okinawa its own).

| Pack | Scene |
|---|---|
| `country_ae` | dunes at golden hour, a dhow on a calm creek, wind-tower houses and a slender modern skyline far behind |
| `country_au` | red-earth outback rock at sunset beside a calm harbour of white sail-like roofs, eucalyptus and a kookaburra |
| `country_br` | a granite sugarloaf peak over a curved bay, rainforest hills, colourful hillside houses and a toucan |
| `country_ca` | a turquoise glacial lake below snowy peaks, pines, a red canoe and a moose silhouette at the shore |
| `country_ch` | an alpine meadow, a snow-capped pyramid peak, a red mountain train on a viaduct and a chalet |
| `country_cn` | karst limestone peaks over a misty river, a bamboo raft, a pagoda and a winding wall on the ridge |
| `country_de` | a fairy-tale castle on a forested crag above a river valley, half-timbered village and vineyards |
| `country_es` | whitewashed hill town above olive groves, a flamenco-red sunset, terracotta roofs and a distant sea |
| `country_fr` | lavender fields, a stone village with a church spire, a cypress line and soft hills (no Eiffel Tower: Paris has its own pack) |
| `country_gb` | rolling green patchwork hills, a dry-stone wall, a red telephone-box-style kiosk without signage and a stone cottage |
| `country_gr` | white cube houses and a blue-domed chapel on a cliff above an Aegean bay, a windmill and bougainvillea |
| `country_id` | stepped green rice terraces, a split temple gate, a volcano on the horizon and palms |
| `country_in` | a white marble domed mausoleum-like palace reflected in a long pool, marigolds and a soft pink dusk |
| `country_it` | a cypress-lined road through golden Tuscan-like hills to a hill town, a pastel coastal village below |
| `country_jp` | a snow-capped conical mountain over a lake, red maples, a pagoda roofline and a red sun disc |
| `country_kr` | a palace gate with curved tiled roofs, cherry blossom, layered blue mountains and a lantern |
| `country_mx` | a stepped stone pyramid in jungle, a cenote pool, papel-picado colours as abstract shapes and agave |
| `country_nl` | tulip fields in stripes, a windmill by a canal, a bicycle and gabled canal houses far off |
| `country_nz` | a deep fjord with waterfalls, sheep on green hills, a snowy range and a fern frond |
| `country_pt` | a yellow tram on a steep cobbled hill, azulejo-patterned walls as abstract tiles, an ocean cliff |
| `country_sg` | a garden of tall tree-like sculptures at dusk, a waterfront skyline, orchids |
| `country_th` | a golden temple roof with tiered eaves, a longtail boat on turquoise water, limestone islands |
| `country_tr` | hot-air balloons over fairy-chimney rock valleys at sunrise, a domed mosque silhouette far behind |
| `country_us` | a desert mesa and canyon at sunset, a highway curving away, saguaro cactus (no Orlando castle: that's its own pack) |
| `country_za` | a flat-topped mountain over a bay, protea flowers, an elephant silhouette on the savannah |

For a new destination, write one line in the same spirit (two or three
landmarks or landscapes, a plant or animal, the light), add a row here, and
use the three prompts above.
