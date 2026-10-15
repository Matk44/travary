# Travary — more art, Wave E1

Completed 14 October 2026: **49 final PNGs**. Built-in imagegen, one call per illustration/asset; independent assets were generated concurrently within the same place. Places were completed one at a time. Artwork is **review_ready**, awaiting owner approval. App integration and publishing are separate.

[Review gallery](index.html) · [Overview](overview.png) · [All key cards, right 60%](key-card-right-60-percent.png) · [Exact prompts and source paths](generation.json) · [Validation and SHA-256 hashes](validation.json) · [Speckle counts](speckle-validation.json)

| Place | Final staging folder | Pictures |
|---|---|---|
| Austria | [country_at/](../country_at/) | 6 |
| Croatia | [country_hr/](../country_hr/) | 6 |
| Ireland | [country_ie/](../country_ie/) | 6 |
| Vietnam | [country_vn/](../country_vn/) | 6 |
| Morocco | [country_ma/](../country_ma/) | 6 |
| Egypt | [country_eg/](../country_eg/) | 6 |
| Hungary | [country_hu/](../country_hu/) | 6 |

| Filename | Exact pixels |
|---|---|
| featured_ticket.png | 1774 × 887 |
| room_card.png | 1774 × 887 |
| reservation_card.png | 1983 × 793 |
| countdown_postcard.png | 1122 × 1402 |
| trip_postcard.png | 1536 × 1024 |
| documents_destination_stamp.png | 1024 × 1280 |

Seven additional **851 × 1848 opaque onboarding stages** are in `art_packs/pending/onboarding/country_<cc>/onboarding_stage_v1.png`. [Stage overview](stages-overview.png) · [Stage validation/prompts/hashes](stages-validation.json). Both destination registers are updated as review_ready, with approval/integration pending. The stages use their own new postcards as geographic references, the clean Bali theatre as material/layout reference, and the specified sibling stages. Original stage masters and exact prompt logs are preserved under `docs/mockups/onboarding-city-stages-v1/more-art-2026-10-14/`. Stage exports use uniform scaling/centred cropping only where needed to deliver exact dimensions.

## Export and checks

All six-picture deliverables are PNG RGBA8 with embedded sRGB, genuine alpha outside the object and transparent corners. The approved clean-backdrop compositor preserves original card alpha, outlines, notches, perforations, barcode stub, cord, brass eyelet and protected shell/exterior pixels; existing stripe geometry is retained and recoloured, tags left unprinted. The key-card backdrop samples only x430–630, avoiding scenery bleed. All card text areas pass the requested median-filter speckle check (counts recorded above). The final right-60% key-card sheet and each place's light/dark sheet were visually inspected for clean paper, scenery placement and halos.

Postcards use uniformly scaled, centred exports, never independent-axis stretching. Generated alpha at or below 4/255 is cleared as in the approved workflow; no colour-key removal. Stamps use the shared Paris paper/perforation/keyline template, with generated scenery uniformly fitted into (123,115)–(901,947); the label band (123,986)–(901,1152) stays exactly blank ivory. Card protected pixels, barcode, eyelet, blank reservation centre and stamp label checks pass. Every source illustration and final contact sheet was visually inspected for style, geographic scope, forbidden text/script/flags/faces and excluded attractions.

`records/` retains exact prompts, input paths, original tool output paths, acceptance notes and any corrections. `originals/` preserves generated masters; `normalised/` contains mechanical donors, not extra deliverables. `export_city.py`, `finalize.py` and the clean-backdrop compositor document the export/validation workflow.

## Rejected attempts and corrections

- `country_at/documents_destination_stamp`: Small route-board/badge-like marks on tram; remove all potential text/logos and keep windows empty.
- `country_hu/documents_destination_stamp`: Close-up exposed faint route-number-like marks in tram roof display.
- `country_eg/reservation_card`: Extra small foreground pyramid made four rather than three.
- `country_at/countdown_postcard`: Small route-board/badge-like marks on tram; remove all potential text/logos and keep windows empty.
- `country_at/room_card`: Small route-board/badge-like marks on tram; remove all potential text/logos and keep windows empty.
- `country_eg/room_card`: Four pyramids rather than requested three.
- `country_at/featured_ticket`: Small route-board/badge-like marks on tram; remove all potential text/logos and keep windows empty.
- `country_hu/room_card`: Close-up exposed faint route-number-like marks in tram roof display.
- `country_at/trip_postcard`: Small route-board/badge-like marks on tram; remove all potential text/logos and keep windows empty.
- `country_ma/onboarding_stage_v1/earlier-attempt-1`: Square minaret finial intruded in central headline sky.
- `country_at/onboarding_stage_v1/earlier-attempt-1`: Church/left clouds intruded into quiet headline sky.

No unresolved delivery-rule exceptions. New artwork approval remains pending. No animation/video was created.

## Handoff to Claude

> Wave E1's 49 final PNGs are complete and checked. Use the final named staging PNGs (and E1 pending onboarding PNGs where applicable), with the hashes and source records above. Do not use rejected originals or intermediate donors. Follow the original brief's developer instructions for source packs, selectors/palettes, WebP/building and onboarding integration. This artwork delivery changed no runtime assets, source packs, catalogue, WebP or publication; preserve unrelated working-tree changes. Owner still approval is separate, and animation/video requires scene approval before production. Publish only when authorized.
