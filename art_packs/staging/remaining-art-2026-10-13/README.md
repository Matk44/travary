# Remaining launch artwork — 13 October 2026

All 17 PNG deliverables are staged. Artwork is ready for owner review, not integrated or published.

[Review gallery](index.html) · [Full generation prompts](generation.json) · [Validation](validation.json)

## Delivery

Paths below are relative to `art_packs/staging/`.

| File | Pixels |
|---|---|
| [lake_district/featured_ticket.png](../lake_district/featured_ticket.png) | 1774 × 887 |
| [lake_district/room_card.png](../lake_district/room_card.png) | 1774 × 887 |
| [lake_district/reservation_card.png](../lake_district/reservation_card.png) | 1983 × 793 |
| [united_states/featured_ticket.png](../united_states/featured_ticket.png) | 1774 × 887 |
| [united_states/room_card.png](../united_states/room_card.png) | 1774 × 887 |
| [united_states/reservation_card.png](../united_states/reservation_card.png) | 1983 × 793 |
| [interface/common/leather.png](../interface/common/leather.png) | 1536 × 1024 |
| [interface/common/pill.png](../interface/common/pill.png) | 1536 × 512 |
| [interface/icons/weather_sunny.png](../interface/icons/weather_sunny.png) | 1024 × 1024 |
| [interface/icons/weather_cloudy.png](../interface/icons/weather_cloudy.png) | 1024 × 1024 |
| [interface/icons/weather_rain.png](../interface/icons/weather_rain.png) | 1024 × 1024 |
| [interface/icons/weather_snow.png](../interface/icons/weather_snow.png) | 1024 × 1024 |
| [interface/icons/checklist.png](../interface/icons/checklist.png) | 1024 × 1024 |
| [interface/dining/themepark_castle_01_vignette.png](../interface/dining/themepark_castle_01_vignette.png) | 1024 × 1024 |
| [interface/dining/themepark_castle_01_scene.png](../interface/dining/themepark_castle_01_scene.png) | 1536 × 1024 |
| [interface/dining/themepark_grill_01_vignette.png](../interface/dining/themepark_grill_01_vignette.png) | 1024 × 1024 |
| [interface/common/countdown_postcard_anywhere.png](../interface/common/countdown_postcard_anywhere.png) | 1122 × 1402 |

## Generation and export

Built-in imagegen was used for every illustration. No API/CLI fallback was used.
The owner authorized template compositing on 13 October after the first whole-card edit altered protected pixels.
The first rejected draft remains as a historical record; its lake illustration was reused as a donor for the final featured ticket.

The six cards start from `art_packs/prompts/city_card_references/`, as specified in the 12 October remaining-art guide. Their exact original alpha, exterior, shadow, notch geometry, stub/barcode, cord and brass eyelet are preserved. Generated scenes are uniformly fitted into the reserved picture regions, with plain paper extended to meet the 42% ticket and 62% key-card text boundaries. Decorative stripes and blank tag faces are recoloured. The old flag on the reservation template's tag is removed.

Interface exports retain generated artwork and alpha. Icons are uniformly fitted to a 512px maximum content extent on 1024px transparent canvases. The pill is uniformly downsampled to its requested 3:1 size. Vignettes are downsampled to 1024px. The leather uses a small end-gap crop and 16px seam blend of its generated texture; its row of stitching is centred at y=123, and the left/right edge columns match exactly. Details are recorded in [interface-export.json](interface-export.json).

## Checks

- All 17 PNGs match required dimensions.
- Every requested transparent asset has real alpha; leather and full castle scene are opaque.
- All six card alpha channels match their original templates byte-for-byte.
- Protected card regions, complete brass eyelets and original exterior/shadow pixels match their templates.
- Icons occupy about 50% of their canvas, with centred transparent padding.
- Leather's edge columns match and stitching sits at 12% height.
- Final contact sheets inspected on cream and navy backgrounds. No readable text, logos, named attractions or city-specific US landmarks observed.

Reproduce checks with `python3 art_packs/staging/remaining-art-2026-10-13/validate.py` from the project root. The exporter and review builder are kept alongside this record. These are art checks; the app has not been rebuilt because no runtime assets or code were changed.

App integration, WebP conversion, pack versioning and publishing remain the separate developer steps in the original request.
