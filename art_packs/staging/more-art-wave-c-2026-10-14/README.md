# Travary — more art, Wave C

Completed 14 October 2026: **four onboarding scenery stills**, generated with the built-in imagegen tool. All are **review_ready**, awaiting owner approval. Integration and publishing are separate.

[Review gallery](index.html) · [Overview](overview.png) · [Exact selected prompts and source paths](generation.json) · [Validation and SHA-256 hashes](validation.json)

| Place | Final PNG | Exact delivery size |
|---|---|---|
| Antalya | [city_tr_antalya](../../pending/onboarding/city_tr_antalya/onboarding_stage_v1.png) | 851 × 1848 |
| Phuket | [region_th_phuket](../../pending/onboarding/region_th_phuket/onboarding_stage_v1.png) | 851 × 1848 |
| Milan | [city_it_milan](../../pending/onboarding/city_it_milan/onboarding_stage_v1.png) | 851 × 1848 |
| Taipei | [city_tw_taipei](../../pending/onboarding/city_tw_taipei/onboarding_stage_v1.png) | 851 × 1848 |

All four are PNG RGBA8 with embedded sRGB and fully opaque alpha. They preserve the approved layered-cardstock theatre framing, quiet central headline sky, scenery across the middle and cream control floor near 65%. Each was inspected individually and in the overview. No Travi, folio, tickets, type, UI or flags are baked in. Geographic references were the places' existing countdown postcards; Bali supplied the camera/material contract and the requested sibling stages supplied family consistency.

## Provenance and corrections

Full exact prompts, original tool output paths, references, checks and hashes are in `generation.json` and `records/`. The earlier-batch-style prompt logs, records and unmodified originals are also preserved in [the onboarding log](../../../docs/mockups/onboarding-city-stages-v1/more-art-2026-10-14/). The [Markdown register](../../../docs/onboarding/DESTINATION_ART_REGISTER.md) and [JSON ledger](../../../docs/onboarding/destination-art-registry.json) record these as review-ready additions.

Antalya and the corrected Milan raw masters measured 851 × 1847. Their final PNGs use **uniform LANCZOS cover and a subpixel centre crop**, never axis stretching, to deliver exactly 851 × 1848. Phuket and corrected Taipei already matched the required dimensions. All original outputs remain intact.

Milan's first attempt was rejected for inscription-like arcade marks, tram passenger shapes and an over-tall spire. A targeted imagegen edit removed the marks/passengers and shortened the spire. Taipei's first attempt was rejected because the tower entered the heading zone; a targeted imagegen edit lowered it. Rejected originals and exact correction prompts are retained. No unresolved delivery-rule exceptions.

`export_stages.py` contains the mechanical export and checks. Its `finalize` action also appends new registry entries, so it is a one-time delivery action and should not be rerun against the completed ledger. Validation results are retained in `validation.json`. Stage alpha is intentionally opaque; transparent-corner/card/stamp checks do not apply to this wave. No new key cards exist in Wave C, so the key-card contact sheet and speckle check are not applicable.

## Handoff to Claude

> Wave C's four still stages are complete and ready for owner review. Use the exact final PNGs in `art_packs/pending/onboarding/`, with their prompts, references and hashes above. Owner artwork approval remains pending; animation/video requires approval of the scene before production. Follow the original brief's developer steps for onboarding integration only when authorized. No runtime assets, source packs, catalogue, WebP, animation or publication were changed by this delivery. Preserve unrelated ongoing changes. Remaining waves continue in order D, E1, F1, E2, F2.
