# City scenery review and file audit

7 October 2026. All 30 requested cities completed in six batches of five using built-in imagegen; 36 generation/edit calls produced 30 selected masters. All are **review_ready**, with owner approval pending. There were no queue substitutions.

[Gallery](gallery.html) · [Selected masters](README.md#selected-masters) · [Exact prompts and sources](PROMPTS.md) · [Manifest](batch-manifest.json) · [Machine-readable file audit](validation.json)

Paris and Rome were inspected against the approved prop-free Bali reference before continuing. Every result was visually inspected for geographic cues, layered/folded paper, central teal headline space, cream control floor, right foreground clearance and baked-in characters/props/type. Symbolic compositions combine real city cues; they are not surveyed literal viewpoints. The floor boundary is approximately 65% throughout.

## Corrections selected

| City | Selected revision | Reason |
|---|---|---|
| Venice | v2 | Removed tiny pedestrians from the Rialto bridge. |
| Prague | v2 | Removed pedestrians; retained fixed historical bridge statues. |
| New York City | v2 | Lowered/scaled the skyline to protect headline space. |
| Tokyo | v2 | Reduced Tokyo Tower to protect headline space. |
| Kuala Lumpur | v2 | Reduced the Petronas towers/skybridge to protect headline space. |
| Melbourne | v2 | Removed small pedestrian shapes and lowered the distant skyline antenna. |

Selected v2 masters use sibling versioned filenames. All initial and revision prompts, original output paths and selection decisions are retained in the manifest and batch result records. Superseded originals remain in the built-in generated-image directory.

## Measured file results

- 30 unique opaque PNG masters saved under `art_packs/pending/onboarding/<canonical-city-id>/`.
- 23 masters measure **851 × 1848**; seven measure **851 × 1847**. Actual measurements are recorded individually; no resizing or re-encoding was applied.
- Every selected file has the same SHA-256 as its original built-in output.
- All 36 exact prompt files match the submitted prompt records; input paths and original outputs exist.
- All 30 city ledger entries match the manifest's selected paths, dimensions, hashes, selectors, prompts and sources.
- The gallery contains 30 unique image previews in six batch sections; all 120 local image/master/prompt links resolve.
- The 25 country baseline rows remain `needed`; existing Bali and Kyoto retain `integrated`. Existing Paris and Orlando source-reference records remain present.

## Review notes and separate next work

Some peripheral spires or foliage extend above the approximate scenery band; central headline fields remain quiet. These exceptions and scene-specific geographic notes are recorded per city. Architectural statues, clock faces, bridges, empty trams and harbour vessels are fixed scenery. Folios, tickets, labels, prices, Travi and animation remain separate shared assets.

Osaka's selected blossom scene reads as early/mid spring, despite a later-spring prompt. Queenstown's gold foliage reads as an early-autumn alpine impression, despite a late-spring prompt. Both retain a coherent local season; the exact requested prompts and visual observations are recorded without claiming an exact seasonal match.

Hong Kong uses `HK/hong_kong`; Singapore uses `SG/singapore`. Their city-state selector handling needs a deliberate resolver decision during separate integration. New York reuses the existing `new_york` slug.

Remaining work is owner art review, then application integration and live text/Travi/device/accessibility overlay QA if authorized. Publication is separate. This scenery task changes no application code, pricing, billing or animation and preserves the country and neutral fallback policy.
