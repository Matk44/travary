# 9 October onboarding art delivery

**31/31 stills generated with built-in imagegen. New artwork awaits owner approval. No new video was generated, and these new masters have not been integrated or published.**

[Review gallery](index.html) · [Manifest, measured sizes and hashes](manifest.json) · [Read-only measurements](QA.json) · [Original request](../../onboarding/ART_REQUESTS_2026-10-09.md)

Local review: <http://127.0.0.1:55380/docs/mockups/onboarding-art-requests-2026-10-09/>. The gallery offers country filters, full-size views, and Original / Generated / 50% overlay comparisons for green plates and Kyoto. It displays source masters without modifying their pixels.

## Files for Claude

| Delivery | Count | Master location | Current state |
|---|---:|---|---|
| Reusable Travi green plates | 5 | `docs/mockups/onboarding-green-plates-v1/green-{folio,proof,account,email,pass}-v1.png` | Generated drafts; technical preparation needed before films |
| Place-neutral Anywhere stage | 1 | `art_packs/pending/onboarding/anywhere/onboarding_stage_v1.png` | Ready for owner art review |
| Country stages | 24 | `art_packs/pending/onboarding/country_<code>/onboarding_stage_v1.png` | Ready for owner art review |
| Prop-free Kyoto replacement | 1 | `art_packs/pending/onboarding/city_jp_kyoto/onboarding_stage_v1.png` | Ready for owner art review; old native Kyoto is preserved |

Country codes: **US, GB, FR, IT, ES, JP, AU, MX, TH, GR, PT, DE, CA, TR, AE, NL, ID, NZ, KR, CH, IN, CN, BR, ZA**. Singapore reuses its existing integrated city stage. No new Singapore image or per-destination film is required.

The countries use the prop-free Bali plate for camera, theatre wings, central sky and floor. Each also uses its own country postcard for content. Scenes represent broad symbolic country landscapes; they are not literal views of every selected city. They contain no Travi, booking folio, tickets, prices, UI or destination names. The new Anywhere scene avoids country-specific landmarks. Kyoto removes the baked-in folio, loose tickets and their floor shadows.

## Technical findings before films

These are **unmodified generated masters**, not production chroma plates. The five foreground performances remain visually close to their references, but generated foreground pixels are not identical. A same-coordinate RGB measurement is recorded in `QA.json`; it is a heuristic, not proof of exact geometry or a validated alpha matte. Use the comparison gallery and check hand/card edges, folio base and wheel positions before accepting registration.

The requested key was perfectly flat **#00B140**, RGB **(0, 177, 64)**. The model produced slight colour variation instead. In the clear upper rectangle (x200–599, y40–149), measured modal colours are:

| Plate | Mode RGB | Distinct RGB values in sample |
|---|---|---:|
| Folio | (1, 179, 68) | 55 |
| Proof | (2, 182, 67) | 72 |
| Account | (1, 183, 68) | 66 |
| Email | (2, 182, 73) | 56 |
| Pass | (1, 178, 64) | 72 |

This is a sample, not a whole-frame uniformity guarantee. **Prepare/validate a clean matte or normalize the background before feeding these into Scene Studio.** Preserve coral/navy/cream foreground detail, including handle gaps and finger edges. Do not rely on exact equality to #00B140 to key the raw masters. Chroma spill, moving edges and compressed-video key quality still need film QA.

Measured dimension exceptions:

- **Green proof: 940 × 1672**, matching the original proof plate's width, rather than the requested 941 × 1672. Resolve its canvas registration deliberately; stretching the character could shift the handoff.
- **Greece: 851 × 1847**, one row shorter than the 851 × 1848 stage contract. Normalize only in a separate delivery rendition and recheck the floor boundary; preserve this PNG master.
- The other four green plates are **941 × 1672**. The other 25 scenery masters are **851 × 1848**.

The green pass retains the original **two blank pass shells and blank navy bottom ticket strip** as physical foreground artwork. Pass names, localized prices, selection state and buttons remain live UI. Coordinate shell visibility with the final handoff so native shells do not appear twice.

All 31 PNGs decode and match their generated source hashes. Visual review found clear lower floors, central headline space, dimensional paper materials and no baked-in character/UI in the scenery. These are composition checks; actual short/tall phones, overlays, safe areas, large text, keyboard, reduced motion and matte registration have not been validated by this art task. Turkey's balloons sit high at the left edge; check headline clearance with the live typography.

The browser gallery loaded all 31 masters successfully. Country filtering, full-size inspection and green Original / Generated / 50% overlay controls were checked. [Gallery preview](review-preview.png).

## Exact prompts and references

Every `requests-*.json` here records the exact submitted prompt, reference paths and selected generated source PNG. `manifest.json` maps every output to its requested location, dimensions and SHA-256. Originals in `.codex/generated_images/` were retained; workspace masters are unchanged copies.

| Prompt log | Images |
|---|---|
| [01](requests-01.json) | Green folio, proof |
| [02](requests-02.json) | Green account, email, pass |
| [03](requests-03.json) | Anywhere, prop-free Kyoto |
| [04](requests-04.json) | US, GB, FR, IT |
| [05](requests-05.json) | ES, JP, AU, MX |
| [06](requests-06.json) | TH, GR, PT, DE |
| [07](requests-07.json) | CA, TR, AE, NL |
| [08](requests-08.json) | ID, NZ, KR, CH |
| [09](requests-09.json) | IN, CN, BR, ZA |

The five exact green prompts are also collected alongside their images in [onboarding-green-plates-v1/PROMPTS.json](../onboarding-green-plates-v1/PROMPTS.json). Tool mode: **built-in image_gen**, referenced-image generation/editing, opaque background, one call per distinct image. No CLI generation, local video tool or raster postprocessing was used in this batch. Python helpers only copied files, read pixels/dimensions, computed hashes and wrote metadata.

## Next step after owner approval

1. Resolve the green cleanup and registration findings above, using the approved originals as the authority for foreground geometry.
2. Scene Studio regenerates the nine shared shots from the existing booking/account job prompts, using reviewed green first/last frames. Keep a locked camera and flat key throughout. The owner approves new transitions before motion, as recorded in `AGENTS.md` and the request.
3. Claude keys/packages the films, aligns foreground feet/folio to the country floor, and integrates approved country / Anywhere / Kyoto delivery renditions. Keep city → country → Anywhere fallback behaviour and the neutral pre-destination arrival films.
4. Preserve live Apple / Google / email-link sign-in, live RevenueCat offers and localized prices. No prices, labels or sign-in controls should be baked into art.

The planning register and JSON ledger have been updated for this batch. New country and shared candidate entries remain separate from existing native integration. This delivery does not certify film compositing, authentication or purchase behaviour.

To restart this gallery from the project root: `python3 docs/mockups/onboarding-intro-v1/serve.py --port 55380 --directory .`.
