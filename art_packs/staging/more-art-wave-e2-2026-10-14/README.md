# Travary — more art, Wave E2

Completed 14 October 2026: **18 final PNGs**. Built-in imagegen, one call per illustration/asset; independent assets were generated concurrently within the same place. Places were completed one at a time. Artwork is **review_ready**, awaiting owner approval. App integration and publishing are separate.

[Review gallery](index.html) · [Overview](overview.png) · [All key cards, right 60%](key-card-right-60-percent.png) · [Exact prompts and source paths](generation.json) · [Validation and SHA-256 hashes](validation.json) · [Speckle counts](speckle-validation.json)

| Place | Final staging folder | Pictures |
|---|---|---|
| Czechia | [country_cz/](../country_cz/) | 6 |
| Malaysia | [country_my/](../country_my/) | 6 |
| Taiwan | [country_tw/](../country_tw/) | 6 |

| Filename | Exact pixels |
|---|---|
| featured_ticket.png | 1774 × 887 |
| room_card.png | 1774 × 887 |
| reservation_card.png | 1983 × 793 |
| countdown_postcard.png | 1122 × 1402 |
| trip_postcard.png | 1536 × 1024 |
| documents_destination_stamp.png | 1024 × 1280 |

## Export and checks

All six-picture deliverables are PNG RGBA8 with embedded sRGB, genuine alpha outside the object and transparent corners. The approved clean-backdrop compositor preserves original card alpha, outlines, notches, perforations, barcode stub, cord, brass eyelet and protected shell/exterior pixels; existing stripe geometry is retained and recoloured, tags left unprinted. The key-card backdrop samples only x430–630, avoiding scenery bleed. All card text areas pass the requested median-filter speckle check (counts recorded above). The final right-60% key-card sheet and each place's light/dark sheet were visually inspected for clean paper, scenery placement and halos.

Postcards use uniformly scaled, centred exports, never independent-axis stretching. Generated alpha at or below 4/255 is cleared as in the approved workflow; no colour-key removal. Stamps use the shared Paris paper/perforation/keyline template, with generated scenery uniformly fitted into (123,115)–(901,947); the label band (123,986)–(901,1152) stays exactly blank ivory. Card protected pixels, barcode, eyelet, blank reservation centre and stamp label checks pass. Every source illustration and final contact sheet was visually inspected for style, geographic scope, forbidden text/script/flags/faces and excluded attractions.

`records/` retains exact prompts, input paths, original tool output paths, acceptance notes and any corrections. `originals/` preserves generated masters; `normalised/` contains mechanical donors, not extra deliverables. `export_city.py`, `finalize.py` and the clean-backdrop compositor document the export/validation workflow.

## Rejected attempts and corrections

No rejected illustration attempts in this wave.

No unresolved delivery-rule exceptions. New artwork approval remains pending. No animation/video was created.

## Handoff to Claude

> Wave E2's 18 final PNGs are complete and checked. Use the final named staging PNGs (and E1 pending onboarding PNGs where applicable), with the hashes and source records above. Do not use rejected originals or intermediate donors. Follow the original brief's developer instructions for source packs, selectors/palettes, WebP/building and onboarding integration. This artwork delivery changed no runtime assets, source packs, catalogue, WebP or publication; preserve unrelated working-tree changes. Owner still approval is separate, and animation/video requires scene approval before production. Publish only when authorized.
