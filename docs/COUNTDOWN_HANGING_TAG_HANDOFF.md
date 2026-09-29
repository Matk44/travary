# Empty Today — hanging luggage tag hand-off

The approved state is shown only when the selected Today date has no itinerary
items and a future trip exists. It celebrates the earliest future trip; it does
not replace the existing Today itinerary while travelling.

## Production assets

All five postcards are `1122 x 1402` transparent PNGs with the same physical
silhouette, deckled edge, shadow and upper-right tag-safe composition. Their
common asset key is `countdown_postcard`.

| Scope | File |
| --- | --- |
| Lake District region, GB | `art_packs/pending/countdown_postcards/region_gb_lake_district/common/countdown_postcard.png` |
| Orlando city, US | `art_packs/pending/countdown_postcards/city_us_orlando/common/countdown_postcard.png` |
| Kyoto city, JP | `art_packs/pending/countdown_postcards/city_jp_kyoto/common/countdown_postcard.png` |
| Paris city, FR | `art_packs/pending/countdown_postcards/city_fr_paris/common/countdown_postcard.png` |
| Bali region, ID | `art_packs/pending/countdown_postcards/region_id_bali/common/countdown_postcard.png` |

The pending directory is intentional: add each image to its complete city or
region pack rather than creating a partial pack that would outrank a fuller
country pack. Each final `pack.json` entry should declare:

```json
{
  "file": "common/countdown_postcard.png",
  "kind": "common",
  "name": "countdown_postcard",
  "width": 1122,
  "height": 1402
}
```

The shared blank tag is:

`assets/art/common/countdown_luggage_tag.png`

It is a `1024 x 1536` transparent PNG. It contains only the warm-ivory cotton
tag, aged-brass eyelet, braided cord and restrained physical shadow. All copy
is live Flutter content.

## Resolver contract

1. If Today has at least one booking, keep the existing Today itinerary.
2. Otherwise select the future trip with the earliest start date.
3. Build `TripArtContext` from that trip's verified visual profile.
4. Resolve `common/countdown_postcard` through the existing ranked art catalog.
5. Prefer city, then region, then country/look fallbacks according to existing
   resolver rules. Never show a postcard for a different verified place.
6. If no suitable postcard exists yet, keep the existing safe empty state; do
   not substitute Lake District or another arbitrary destination.

## Flutter composition

- Draw the destination postcard with `BoxFit.contain`; never crop its deckled
  edge. Its intrinsic aspect ratio is `1122 / 1402`.
- Overlay the complete countdown tag stack at the postcard's upper-right.
- Size the tag to about `44–48%` of the postcard width.
- Rotate the complete stack—shell and live copy together—about `6–8°`
  clockwise. Do not rotate only the raster shell.
- The tag may extend slightly beyond the postcard's top and right edges; use a
  non-clipping Stack with enough surrounding layout space.
- Inside the tag, reserve the upper `21–24%` for the eyelet and cord. Use about
  `10–12%` horizontal padding and keep all text centred.
- Live tag hierarchy: `NEXT TRIP`, large whole-day countdown, `DAYS TO GO`,
  divider, destination name, formatted trip date range.
- Use navy ink and real text. Scale the destination name down safely rather
  than truncating it. Do not bake a destination icon or postmark into the tag.
- Keep the selected mockup's three live fact labels below the hero (`duration`,
  `booking count`, `opening/start date`) and the existing generated
  ticket-shaped `View trip` action.
- The postcard, tag, fact labels and CTA are raster material layers; text,
  semantic labels and hit targets remain Flutter widgets.

## Motion and accessibility

- On entry, allow a restrained postcard lift/fade and a delayed tag settle of
  only a few degrees. Honour reduced-motion settings.
- The entire hero opens the trip, as does the explicit `View trip` button.
- Expose a semantic summary such as `Lake District, 58 days to go, 25 to 28
  November 2026`.
- Calculate the countdown from local calendar dates rather than raw 24-hour
  duration so timezone and daylight-saving changes cannot shift the number.

## ImageGen prompt contract

Built-in ImageGen was used in reference-matched generation mode. Every
postcard prompt locked the approved near-square portrait silhouette, thin
deckled cream edge, transparent exterior, tactile mid-century screen-print
finish, and a quiet upper-right overlay zone. Each prompt prohibited text,
numbers, stamps, tags, people, flags, logos, UI and surrounding background.
The tag prompt requested a front-facing blank warm-ivory cotton label with an
upper-right brass eyelet, cream cord, transparent exterior and a large clean
live-copy zone.

## Implementation

- Wording and the calendar-date count: `lib/logic/countdown_text.dart`
  (`CountdownText`, tested in `test/logic/countdown_text_test.dart`).
- Postcard resolution: `TravelStore.countdownPostcardFor`
  (`ArtCatalog.commonArt('countdown_postcard')` with the trip's
  `artContextForPlan`), tested in `test/state/countdown_postcard_test.dart`.
- The hero: `lib/design/widgets/countdown_trip_hero.dart`; measurements in
  `CountdownGeometry`, sizes and timings in `CountdownLayout`
  (`lib/design/tokens.dart`). The tag is `SurfaceSlot.countdownTag`; the
  fact tags and button look up `countdown_fact_tag` and `countdown_button`
  and use plain stand-ins until those rasters exist
  (`docs/ART_ASSET_GAPS.md`).
- Today: `lib/features/today/today_screen.dart` shows it only between
  trips, when today is empty and a postcard resolves; otherwise Today is
  unchanged. Screen tests: `test/widget/countdown_today_test.dart`.
- The postcard is capped at half the screen's height so everything fits
  above the home tabs on a 390 × 844 phone; wider or taller screens get up
  to 460 points.
