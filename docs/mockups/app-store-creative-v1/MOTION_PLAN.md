# Travi as an independent animation layer

18 October 2026. Both scene stills are owner-approved. The owner prefers generating Travi's animation separately and compositing it onto the approved scenery. The owner subsequently approved local reuse of the presented performances on 18 October: “much better, lets go ahead and do the rest”. No new transition or paid generation is authorized by that approval.

## Preparation history before the latest approval

Earlier preparation: the owner authorized continuing with existing footage, requiring consultation before new paid animations. [Version 3's stills and acting storyboards](review/index.html) are now ready for review. Existing `tag-idle` and `present-idle` are viable candidates; the old folio has been masked away. The header uses the held-tag pose, while search mirrors the presenter towards the phone. No new paid clips are needed for this proposed first pass.

The official PSD templates were retrieved and their art-safe bounds recorded in [apple-safe-areas.json](references/apple-safe-areas.json). Their central safe areas required revising the initial layout: raise the header floor and group text/Travi centrally; recompose search's headline, postcard/tag, presenter and phone inside its safe area. These revised layouts and acting samples need owner review before local video assembly. Original approved concepts are preserved.

Header layout preparation: fit the complete header image inside the safe area, like search. [Header v4](review/header-start-v4.png) now fits the full panoramic theatre and all three destinations, headline, existing Travi pose and countdown into the safe area. Its surrounding canvas continues the navy wall and cream floor. No source-scene cropping or new generation is used, apart from a small perimeter feather to blend the paper edges. Search remains v3. This request was a layout revision, not approval to assemble motion; revised artwork approval remains pending.

Search material preparation: the owner approved header v4's still and asked for cleaner cream in search. [Search v4](review/search-start-v4.png) replaces enlarged fabric with quiet fine paper, matched to the screenshot cream; it preserves the normalized layout and composes lettering/UI directly at 3840 × 2560. The postcard/tag's old rectangular linen backing has been masked away. Existing fine-paper source and Travi footage are reused; no generation costs or motion assembly occurred. The revised search still is awaiting review before local motion assembly.

Edge correction: the owner's native close-up exposed a remnant matte and a clipped shadow in v4. [Search v5](review/search-start-v5.png) uses a separately regenerated transparent postcard/tag/twine asset (built-in ImageGen), crisp local countdown text and padded shadows whose boundary alpha is zero. The [native close-up](review/search-tag-closeup-v5.png) is included in review. The app UI and existing Travi are unchanged. This is a still-art correction; no paid character/video job or motion assembly occurred, and revised scene approval remains pending.

## Delivered local assembly

[Header v4](exports/travary-header-v4-loop-v2.mp4) and [search v5](exports/travary-search-v5-loop-v2.mp4) are rendered, using only existing `tag-idle` and `present-idle` footage. The first 8.1-second pass revealed a scale pulse: the original onboarding processor faded into a roughly 2% smaller registered still. The current repair uses only unblended source frames 5–91, applies one fixed similarity transform, and overlaps three calm matching-pose frames. The resulting 84-frame / 24-fps cycle repeats twice, producing exactly 7 seconds / 210 frames at 30 fps. The body is not fitted separately per frame, so the presenting arm cannot drive a false zoom. There is no new scene transition, prop/background animation or character generation. Header tag type is registered to its cream face for each source frame; search type and genuine UI remain static.

Matching opaque still fallbacks and [delivery metadata](exports/delivery-manifest.json) are in `exports/`. The [playback and scale QA report](review/motion-qa-report-v2.json) records format, full decode, unchanged pixels outside the character, join-window scale and natural wrap motion. Identical endpoints alone are not proof of a smooth surrounding join. Current tools: `repair_loop_scale.py` then `package_repaired_motion.py`; original videos remain preserved for comparison. The [review page](review/index.html) provides playable safe-area inspection crops and complete upload canvases. Owner final playback approval and actual App Store Connect placement checks remain before upload. The preparation history above records earlier review gates; they were satisfied by the latest approval for this reuse pass.

## Finish the tags (preparation notes)

The tags are intentionally blank in the generated stills so their lettering can be added sharply and edited/localized independently. They should have finished text in the final assets. Suggested demonstration wording: a large “30” with “DAYS TO GO”, consistent with the Lake District countdown capture. The approved delivered artwork uses this wording.

The header's tag is held by Travi. Keep its face readable and its movement small; composite lettering with the tag's tracked perspective. If tracking proves unreliable, use a separately composited tag registered to his hand. Static text over an independently moving generated tag would slide and look wrong. The search scene's resting tag can be typeset directly.

## Confirmed local pipeline

- Scene Studio: `/Users/khairofamily/Documents/video_generator`; `npm run dev` serves port 3717.
- The current video route supports first and last frame references. The configured default provider in source is `replicate-seedance-2`. Its README describes an older scaffold; the provider source and Travary's existing submitter confirm the working integration.
- [films.py](../onboarding-films-v2/films.py) already submits Travi against a green background with first/last frames and audio disabled. Paid requests are recorded before submission; ambiguous submissions must be checked rather than blindly retried.
- [process.py](../onboarding-films-v2/process.py) keys green to RGBA, removes edge spill and eases film ends into registered stills. It is currently tailored to the onboarding/cameo frame sizes; use a separate marketing configuration so app runtime assets remain untouched.
- Collected `source/tag-idle.mp4`, `source/present-idle.mp4`, `source/hello-idle.mp4` and `source/cheer.mp4` exist in the onboarding films folder. Their source poses include a folio and differ from the approved scenes. Reuse is a candidate to inspect, not an established visual match.

## Proposed production order

1. Prepare clean background plates by removing the baked-in Travi, his held prop where applicable, and his contact shadow. Preserve the approved layouts, scenery and phone geometry. Keep the approved originals intact.
2. Finish editable tag text and insert genuine app UI in the search phone. The current green phone is a compositing placeholder. Keep headlines and UI outside the generative video.
3. Prepare isolated Travi stills matching each approved scene's perspective, lighting, scale and pose, on flat chroma green. Leave room for every gesture, handle, hand and wheel. Present the acting keyframes/storyboard for owner approval before new animation, as required by [AGENTS.md](../../../AGENTS.md).
4. Inspect existing clips for useful performances. If they cannot match without changing the approved compositions, generate one short matching performance per scene in Scene Studio. Start with one shot and inspect it before committing the second; avoid a speculative batch.
5. Key Travi to alpha, add a separate soft contact shadow and composite him onto the approved plate. Keep props and screen content stable; optional simple tag/postcard transforms can be rendered locally. No generated scenery animation is needed for the first pass.
6. Check full-size edges, identity, hands, tag lettering, grounding, occlusion of the phone, loop joins and safe-area crops. Export an opaque finished video and static fallback for each placement.

Proposed header acting: Travi glances at the countdown, brightens with a small eyebrow lift, and settles into the same presenting pose. Proposed search acting: a blink, a welcoming gesture towards the phone, and a small pleased nod, returning to the same pose. The existing performances shown in review are now approved for the delivered reuse pass. Neither introduces a scene transition; no new acting generation was needed.

## Cost and output

The main saving is reuse: scenery, lettering, app content and final framing can change without paying to regenerate the character performance. A tighter character canvas can also permit a smaller source resolution; quote/choose resolution based on Travi's actual final pixel size. Isolating the character alone does not guarantee a lower per-job price at an unchanged model, duration and resolution.

The current film processor uses 24 fps. Final App Store exports must be rendered at a supported 30 or 60 fps and checked for motion cadence. Apple's current specifications list 5–30 second videos, a 3840 × 1646 header and a 3:2 search asset from 1920 × 1280 to 3840 × 2560. Both loop; search is silent. Internal character alpha is useful, but the final store image/video must be flattened over the artwork.

[Apple creative specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications), verified 18 October 2026. The concept PNGs are not final export sizes. The finished videos are local composites of existing footage, with no new provider generation. No further Claude Code handoff is needed for this delivery.
