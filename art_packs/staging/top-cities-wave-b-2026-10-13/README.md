# Travary — top cities, final Wave B

Completed 13 October 2026: **11 cities, 66 final PNGs**. Wave A already contains 10 cities and 60 PNGs; the requested 21-city / 126-image artwork brief is now complete. Artwork is staged for owner review; app integration and publishing are separate.

## Review and provenance

- [Review gallery](index.html), with full-size PNG links and light/dark backgrounds.
- [All eleven cities](overview.png).
- [Validation and SHA-256 manifest](validation.json).
- [Exact prompt set and source paths](generation.json). Mode: built-in imagegen, one call per asset; no API/CLI fallback.
- [Wave A handoff](../top-cities-wave-a-2026-10-13/README.md).

Final deliverables are in `/Users/khairofamily/AndroidStudioProjects/Travary/art_packs/staging/<folder>/`. Helper files, intermediate normalized donors and review sheets in this review directory are not additional deliverables.

## City folders

| City | Folder | Final PNGs |
|---|---|---|
| Osaka | [osaka](../osaka/) | 6 |
| Venice | [venice](../venice/) | 6 |
| Lisbon | [lisbon](../lisbon/) | 6 |
| Madrid | [madrid](../madrid/) | 6 |
| Prague | [prague](../prague/) | 6 |
| Cancún | [cancun](../cancun/) | 6 |
| Kuala Lumpur | [kuala_lumpur](../kuala_lumpur/) | 6 |
| Antalya | [antalya](../antalya/) | 6 |
| Phuket | [phuket](../phuket/) | 6 |
| Milan | [milan](../milan/) | 6 |
| Taipei | [taipei](../taipei/) | 6 |

Each city folder contains:

| Filename | Exact size |
|---|---|
| featured_ticket.png | 1774 × 887 |
| room_card.png | 1774 × 887 |
| reservation_card.png | 1983 × 793 |
| countdown_postcard.png | 1122 × 1402 |
| trip_postcard.png | 1536 × 1024 |
| documents_destination_stamp.png | 1024 × 1280 |

All are PNG RGBA8 with embedded sRGB and genuine transparency outside the paper/card. Source images were visually inspected. Lisbon's final room card uses a front-on, unlettered tram; the two failed local edits are recorded as rejected. Kuala Lumpur's final landscape postcard corrects an extra tower to exactly two matching towers.

## Export and validation

Used the owner's previously authorized mechanical template-compositing workflow. Generated scenery is uniformly scaled/cropped into the measured printable areas. Original card silhouettes, alpha, notches, perforations, shadows, barcode stub, cord and brass eyelet are preserved pixel-for-pixel outside the permitted print/recolour areas. Existing stripe pattern geometry is retained and recoloured; reservation tags remain blank.

Postcard exports use uniform scaling and transparent centring where needed, never independent-axis stretching. Alpha values at or below 4 are cleared to remove faint exterior noise. Stamp exports retain the Paris reference's perforated paper, navy keyline and blank label geometry; original blank ivory paper is copied at native scale behind the new illustration. These steps preserve generated alpha and do not use colour-key removal.

The final validation checks exact dimensions, RGBA, real alpha, transparent corners, embedded sRGB, protected card pixels, barcode stub, eyelet, blank reservation centre and blank stamp labels. Light/dark review sheets are saved for every city. No application code, catalogue, source packs, WebP builds or publication was changed by this artwork task.

## Claude handoff

> The city artwork brief in `docs/art_requests/GPT_TOP_CITIES_2026-10-13.md` is complete: Wave A has 10 cities / 60 PNGs and Wave B has 11 cities / 66 PNGs. Read both staging handoff READMEs and validation manifests. Use the final six PNGs in each named city staging folder; do not use intermediate donor images or rejected variants. Follow the brief's developer steps and `docs/ART_PACKS.md`: verify each destination slug against `lib/logic/destinations.dart`, create its city source pack and catalogue entry with the appropriate country palette, then convert and build one pack at a time. Preserve unrelated working-tree changes. Publishing still requires the owner's go-ahead. Antalya, Phuket, Milan and Taipei onboarding backgrounds remain a separate brief and were not generated here.

