# Batch prompt: landscape Trips postcards for the 25 country packs

For ChatGPT image generation. Paste the **Master prompt** once at the start of
a new chat, attach the three reference images it lists, then send one short
"Next" message per country with that country's portrait postcard attached.
Background: `art_packs/prompts/postcards.md` (section 2),
`docs/ART_PACKS.md`, `docs/TRIPS_HANGING_TAG_HANDOFF.md`.

## What to attach

Once, with the master prompt (the worked example of the job):

1. `art_packs/originals/city_jp_kyoto/common/countdown_postcard.png` (portrait, the input)
2. `art_packs/originals/city_jp_kyoto/common/trip_postcard.png` (landscape, the finished result)

Per country, with each "Next" message:

- `art_packs/originals/country_<xx>/common/countdown_postcard.png`

## Missing (25 country packs, none has a `trip_postcard`)

`ae au br ca ch cn de es fr gb gr id in it jp kr mx nl nz pt sg th tr us za`

Already done (do not redo): Paris, Kyoto, Orlando, Lake District, Bali.
`seed_themepark` is not a destination.

## Master prompt (paste once)

```
I'm building a travel app with illustrated vintage postcards. I need you to
make a LANDSCAPE companion for each PORTRAIT postcard I send, one country at
a time, as a worked batch of 25.

I've attached a finished example of the job: the Kyoto portrait postcard (the
input) and the Kyoto landscape postcard (the finished result). Study how the
landscape one is the SAME picture recomposed, not a crop and not a different
scene: same palette, same screen-printed texture, same motifs, same deckled
cream paper edge, re-drawn so the scene fills a wide frame.

For every country I send, produce ONE image:

- 1536 x 1024 pixels (3:2 landscape), PNG.
- A single complete postcard with a thin deckled warm-cream paper edge
  (about 2% of the width) and a restrained soft drop shadow, centred, with
  TRANSPARENT background outside the card (true alpha). If you cannot output
  transparency, use a plain solid pure-white (#FFFFFF) background with no
  shadow and tell me you did.
- The picture is the attached portrait postcard's scene recomposed for
  landscape. Keep its subjects, colours, light and printing style. Put the key
  subject in the LEFT 60% of the picture. Keep the RIGHT 35% quieter (open sky,
  water, soft texture, distant hills), especially the UPPER RIGHT: a luggage
  tag will hang over it in the app, so nothing important may be there.
- Never crop or stretch the portrait image to make it fit. Redraw it.

Style rules (same for every image): tactile mid-century travel-poster
illustration, screen-printed gouache and risograph texture, slightly imperfect
ink registration, warm limited palette, soft paper fibres. Original artwork:
no real logos, brand marks, flags, signage or recognisable copyrighted
characters. No text, letters, numbers, pseudo-text, stamps, postmarks, tags,
luggage tags, people's faces, UI or watermark. The result must look like
the same artist and the same set as the portrait postcard I attach.

Where the attached portrait postcard and my one-line scene description differ,
the attached postcard wins. The description is only a reminder of the subject:

ae: dunes at golden hour, a dhow on a calm creek, wind-tower houses and a slender modern skyline far behind
au: red-earth outback rock at sunset beside a calm harbour of white sail-like roofs, eucalyptus and a kookaburra
br: a granite sugarloaf peak over a curved bay, rainforest hills, colourful hillside houses and a toucan
ca: a turquoise glacial lake below snowy peaks, pines, a red canoe and a moose silhouette at the shore
ch: an alpine meadow, a snow-capped pyramid peak, a red mountain train on a viaduct and a chalet
cn: karst limestone peaks over a misty river, a bamboo raft, a pagoda and a winding wall on the ridge
de: a fairy-tale castle on a forested crag above a river valley, half-timbered village and vineyards
es: whitewashed hill town above olive groves, a flamenco-red sunset, terracotta roofs and a distant sea
fr: lavender fields, a stone village with a church spire, a cypress line and soft hills (no Eiffel Tower)
gb: rolling green patchwork hills, a dry-stone wall, a red telephone-box-style kiosk without signage and a stone cottage
gr: white cube houses and a blue-domed chapel on a cliff above an Aegean bay, a windmill and bougainvillea
id: stepped green rice terraces, a split temple gate, a volcano on the horizon and palms
in: a white marble domed mausoleum-like palace reflected in a long pool, marigolds and a soft pink dusk
it: a cypress-lined road through golden Tuscan-like hills to a hill town, a pastel coastal village below
jp: a snow-capped conical mountain over a lake, red maples, a pagoda roofline and a red sun disc
kr: a palace gate with curved tiled roofs, cherry blossom, layered blue mountains and a lantern
mx: a stepped stone pyramid in jungle, a cenote pool, papel-picado colours as abstract shapes and agave
nl: tulip fields in stripes, a windmill by a canal, a bicycle and gabled canal houses far off
nz: a deep fjord with waterfalls, sheep on green hills, a snowy range and a fern frond
pt: a yellow tram on a steep cobbled hill, azulejo-patterned walls as abstract tiles, an ocean cliff
sg: a garden of tall tree-like sculptures at dusk, a waterfront skyline, orchids
th: a golden temple roof with tiered eaves, a longtail boat on turquoise water, limestone islands
tr: hot-air balloons over fairy-chimney rock valleys at sunrise, a domed mosque silhouette far behind
us: a desert mesa and canyon at sunset, a highway curving away, saguaro cactus (no Orlando castle)
za: a flat-topped mountain over a bay, protea flowers, an elephant silhouette on the savannah

Workflow: I'll send "Next: <code>" with that country's portrait postcard
attached. Reply with only the one image and one line saying which country it
is. Don't ask questions; if something is ambiguous, follow the attached
postcard. Don't batch several countries into one image. Wait for my next
message before making the next one.

Confirm you understand by replying "Ready", then wait for my first country.
```

## Per-country message (send 25 times, attach that country's portrait)

```
Next: jp
```

(Change the code. Say "again, keep the right side quieter" or "again, more
like the attached postcard" if a result strays.)

## Checking each result before keeping it

- 3:2 landscape, full postcard visible, deckled cream edge all the way round.
- Same scene as the portrait, not a new one; same palette and print texture.
- Upper-right and right third calm: no landmark, animal or bright focal point.
- No text, flags, logos, faces, tags or watermark. France has no Eiffel Tower,
  the US has no Orlando castle.
- Transparent outside the card (or plain white, which I'll cut out).

## Handing back

Save each as `<code>.png` (for example `jp.png`) in one folder and tell me the
path. For each I will put it at
`art_packs/sources/country_<code>/common/trip_postcard.png` (and keep the
master in `art_packs/originals/`), cut out a white background if needed,
declare it in `pack.json`, raise the pack's `version`, run
`dart run tool/art_packs.dart webp` and `build`, and add a test that a trip
for that country resolves a postcard. Publishing to production is a separate
step I'll ask you about first.
