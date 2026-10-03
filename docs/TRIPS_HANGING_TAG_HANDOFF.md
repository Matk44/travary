# Trips — hanging-tag postcards hand-off

The selected direction is the art-first hanging-tag concept:

`docs/mockups/trips-postcards-v2/02-hanging-tag-postcards.png`

This round covers **upcoming trips**. Happening-now and past-trip rows keep
their current behaviour and presentation until those states are designed.

## Production assets

Five landscape destination postcards were generated as companions to the
existing portrait countdown postcards. Every image is a `1536 x 1024` RGBA
PNG with a complete 3:2 postcard, thin deckled cream edge, restrained shadow,
transparent exterior and a quieter upper-right overlay zone.

| Scope | File |
| --- | --- |
| Lake District region, GB | `art_packs/sources/region_gb_lake_district/common/trip_postcard.png` |
| Orlando city, US | `art_packs/sources/city_us_orlando/common/trip_postcard.png` |
| Kyoto city, JP | `art_packs/sources/city_jp_kyoto/common/trip_postcard.png` |
| Paris city, FR | `art_packs/sources/city_fr_paris/common/trip_postcard.png` |
| Bali region, ID | `art_packs/sources/region_id_bali/common/trip_postcard.png` |

Each asset is now in the same complete city or region pack as its portrait
countdown postcard. Those packs retain the corresponding country pack's full
asset set; none is a sparse postcard-only pack. Each `pack.json` entry is:

```json
{
  "file": "common/trip_postcard.png",
  "kind": "common",
  "name": "trip_postcard",
  "width": 1536,
  "height": 1024
}
```

No new tag raster is needed. Reuse:

`assets/art/common/countdown_luggage_tag.png`

It is already exposed as `SurfaceSlot.countdownTag`; its measured physical
body is `FractionRect(0.170, 0.261, 0.788, 0.982)`. The raster remains blank.
All trip data is live Flutter content.

## Resolver contract

1. Add the common-art key `trip_postcard` beside `countdownPostcardArt`.
2. Require `LocationVerification.verified`; demo, missing-profile,
   unverified, conflict and skipped trips keep their plain rows.
3. Resolve it through `ArtCatalog.commonArt` with
   `TravelStore.artContextForPlan(plan)`.
4. Expose a `TravelStore.tripPostcardFor(TripPlan)` helper parallel to
   `countdownPostcardFor`.
5. Preserve the existing city → region → country → look/core rank order.
6. Never use an asset from a different verified destination.
7. If no suitable landscape postcard is installed, render the existing
   `_TripTile`; do not substitute Lake District or crop the portrait
   `countdown_postcard`.

## Upcoming-card composition

- Replace only rows in the `Coming up` section with the new composition.
- Draw `common/trip_postcard` with `BoxFit.contain`; never crop the artwork or
  deckled edge. Its intrinsic aspect ratio is `1536 / 1024`.
- Overlay the reusable countdown tag at the postcard's right edge.
- Target the tag's physical card body at about `29–32%` of postcard width.
  Account for the transparent cord/margin around `SurfaceSlot.countdownTag`.
- Let the cord extend above/right with a non-clipping `Stack` and enough list
  spacing. Rotate the complete tag stack, shell and live copy together, about
  `3–5°` clockwise. A small stable per-trip variation is acceptable.
- Keep the card's full row tappable and open `TripScreen(tripId: plan.id)`.
- The whole card gets one semantic button label; exclude duplicate semantics
  from the decorative image and the tag's child text.

Use a compact live hierarchy on the tag:

```text
58
DAYS
────────
Lake District
25–28 Nov 2026
4 days · 3 bookings
```

- Use `DAY` for one day and `DAYS` otherwise.
- Use navy ink and centred text.
- Reserve the tag's upper `21–24%` for the cord and eyelet, with about
  `10–12%` horizontal copy padding.
- Scale long trip names down safely or wrap to two lines; never truncate.
- Do not add a destination icon, stamp, postmark or baked wording to the tag.
- Reuse the existing `LocalDate` countdown and formatting logic. A small
  Trips-specific text model may reuse `countdownTextFor`; do not calculate
  countdowns from a raw `DateTime` duration.

## Responsive behaviour

- Keep the existing `Trips` heading, `Join a trip` action, section grouping,
  scrolling and fixed selected Trips tab.
- Preserve sensible card width on narrow phones and cap it on tablets.
- The postcard must stay readable at enlarged text settings. Scale the tag's
  copy block as a unit only after text has wrapped within its measured zone.
- Do not animate every card while scrolling. If an entry settle is added,
  make it restrained and honour `MediaQuery.disableAnimationsOf(context)`.
- Avoid decoding duplicate full-resolution images repeatedly; use normal
  Flutter image caching and an appropriately resized provider where useful.

## Suggested code shape

- Add a focused reusable widget such as `UpcomingTripPostcard` under
  `lib/design/widgets/`.
- Move trip-row text wording into a small logic model, as the existing
  `CountdownText` and booking-card text models do.
- Keep `TripsScreen` responsible for grouping plans and choosing between the
  art-first upcoming card and the safe existing tile.
- Reuse `artImageProvider`, `SurfaceSlot.countdownTag.body`, the existing
  countdown tag measurements and trip chrome instead of duplicating raster
  loading or hard-coding file paths.

## Verification

Add tests for:

- upcoming trips use their ranked `common/trip_postcard`;
- city and region ranking, and no cross-destination leakage;
- missing postcard falls back to the existing `_TripTile`;
- active and past sections remain unchanged;
- countdown, date range, duration and booking count are live and correct;
- tomorrow uses `1 DAY`, and DST boundaries remain correct via `LocalDate`;
- long trip names, narrow phones and enlarged text do not overflow;
- one semantic button label contains destination, countdown and dates;
- tapping the postcard opens the matching `TripScreen`;
- the complete deckled card is rendered with `BoxFit.contain`.

Run `dart format`, `flutter analyze` and `flutter test` after implementation.

## ImageGen prompt contract

Built-in ImageGen was used in reference-matched style-transfer mode, once per
destination, followed by a background-extraction pass. Each prompt treated
the existing portrait postcard as the authoritative subject, palette and
screen-print reference, then recomposed it laterally into a 1536 x 1024
postcard. Prompts locked the deckled cream edge, transparent exterior,
risograph texture, tag-safe upper-right zone and prohibited text, stamps,
tags, people, flags, logos, UI and surrounding backgrounds.

## Implementation

- Wording: `lib/logic/trip_postcard_text.dart` (`TripPostcardText`, built
  on `countdownTextFor`, so the count is between calendar dates); tested in
  `test/logic/trip_postcard_text_test.dart`.
- Resolution: `TravelStore.tripPostcardFor`
  (`ArtCatalog.commonArt('trip_postcard')` with `artContextForPlan`);
  tested in `test/state/trip_postcard_test.dart`, including that a pack
  with only the portrait countdown postcard never stands in.
- The row: `lib/design/widgets/upcoming_trip_postcard.dart`. The tag is
  `SurfaceSlot.countdownTag` resolved for the trip, its card 31% of the
  postcard's width, turned 3–5° (stable per trip, `stableHash` of its ID)
  from the eyelet with its words. Sizes in `TripPostcardLayout`
  (`lib/design/tokens.dart`); tag measurements shared with the countdown
  (`CountdownGeometry`). Postcard and tag decode at their shown size
  (`ResizeImage`). No entry animation: a list shouldn't move as it scrolls.
- `TripsScreen` builds "Coming up" itself and falls back to the plain row
  for a trip without dates or without a suitable postcard; "Happening now"
  and "Past trips" are unchanged. Screen tests:
  `test/widget/trips_postcards_test.dart`.
