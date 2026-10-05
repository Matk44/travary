# Connected onboarding — exact selected image prompts

5 October 2026. Built-in imagegen mode. All selected outputs were copied into this project. No CLI fallback or new video rendering was used.

The approved reveal screen is the reference for Bali's scene and Travi. Kyoto combines that clean stage template with the existing `art_packs/originals/city_jp_kyoto/common/countdown_postcard.png`. Referenced files were inspected before editing.

## Bali scenery

```text
Use case: precise-object-edit.
Asset type: clean BALI scenic background plate for the approved Travary onboarding reveal.
Input image 1 is the EXACT approved edit target. Preserve its full portrait framing and composition.
Primary request: remove ONLY the suitcase character Travi, his arms, tag, handles, wheels and contact shadow, and remove ALL text and interface elements: Travary wordmark, headline, Bali subtitle, Departure and Return tags with eyelets/icons/arrows, Set my dates button and Dates not decided link. Reconstruct removed areas seamlessly.
Invariants: KEEP the lush FULL-STAGE layered paper Bali world unchanged: towering palms and foliage on the left, tiered shrine and split temple gate, green rice terraces, volcanic mountain, huge coral sun, cream paper clouds, vivid turquoise sea and rocky coast, plants at lower edges. Keep the parted teal paper-theatre wings at the far sides, quiet petrol-teal paper sky in the upper quarter, warm cream stage floor and clean lower control floor. Preserve exactly the warm physical lighting, dimensional folded cardstock, fine paper grain, camera and perspective. Keep the CLOSED navy-teal travel folio and blank cream tickets at lower left.
Where Travi was standing, reconstruct the coastline, sea and cream floor naturally. Retain the original floor/scenery boundary at around 65% of the portrait. Preserve the blank calm top sky and bottom cream floor for live UI. The scenery remains magnificent, rich, expansive and immersive, extending edge-to-edge behind the character's future position, not inside a small postcard or frame.
Constraints: background plate only, no character, no text or UI, no suitcase trace or extra objects, no new destination, no borders/device frame, no glossy plastic. This is an exact removal edit, not a redesign.
```

## Kyoto scenery

```text
Use case: compositing.
Asset type: clean KYOTO scenic background plate for the same Travary onboarding paper theatre.
Input image 1 is the exact BALI stage template: use its full portrait canvas, calm teal top sky, parted teal theatre wings, cream stage/control floor, folio and blank tickets, camera, lighting and dimensional paper materials.
Input image 2 is the existing KYOTO illustration: use its actual Japanese setting, distinctive pagoda, red torii, stone lantern, traditional tiled town roofs and stairs, autumn red/orange maples, distant mountains and warm sunset as the content reference. Do not keep its cream postcard border.
Primary request: replace ONLY the Bali destination landscape in image 1 with a beautifully rich dimensional layered-paper KYOTO world derived from image 2. It must fill the same immersive middle stage from about 28% through 65% of the portrait, edge-to-edge behind a future foreground character, with cut-cardstock folds, physical layered depths, intricate roof/pagoda edges, warm grazing light and delicate paper grain matching image 1. Foreground autumn maples frame the lower left; the pagoda and torii occupy the left/middle; stepping lanes and old rooftops lead through the right; mountains and sunset behind. This is Kyoto's own world, no tropical palms, Bali gate, rice terraces, sea or volcano.
Invariants: retain template camera and full portrait proportions, large quiet petrol-teal upper sky for text, subtle parted side wings, exact cream floor boundary at about 65%, closed navy-teal folio and blank cream tickets at lower left, clean lower cream control area, warm light and sophisticated travel-poster palette. Keep buildings and busy foliage out of the central upper headline area. The lush scenic stage remains full size.
Constraints: scenery plate only, no character, no text, no UI or button, no frames or postcard border, no photorealism, plastic or extra props. Preserve the same composition architecture so ONE native reveal animation works with both landscapes.
```

## Selected transparent Travi (v2)

```text
Use case: background-extraction.
Asset type: reusable transparent Travi character cutout for a native animated paper-theatre scene.
Input image 1 is the approved mascot identity and pose reference. Extract only the coral ribbed spinner character in its lower-right area.
Primary request: produce the SAME complete character, including BOTH complete paper hands/arms, all four grounded caster assemblies, twin telescopic pull rails and navy grip, short grab handle, navy zipper edge, cream palm tag, tiny brass hardware and the delighted open-eyed face. Preserve the exact shell proportions, vertical sculpted paper ribs, warm lighting, coral colour and tactile folded-cardstock detail.
Framing: a SQUARE transparent canvas, approximately 1200 × 1200. Fit Travi's ENTIRE silhouette into the canvas, with around FIVE PERCENT clear transparent padding on ALL FOUR sides. His hands, pull handle and wheels must be completely inside the canvas. Centre the whole silhouette. Keep the character large in the square; no large unused band above him. This is a tightly framed complete character asset; original screen coordinates are not needed.
Remove ALL background scenery, floor, folio, tickets, text, UI and other objects. Keep a very soft low-opacity contact shadow just under his wheels, with genuine transparency around it and no floor patch. Background must have actual alpha, not white, black or printed checkerboard.
Constraints: same character and happy pose, no cropped hand or handle, no extra fingers/arms, no redesign, no sideways trunk, no front pocket, no huge baby eyes, no gloss, no lettering. Exactly one complete character on a transparent square canvas with clean paper edges.
```

## Selected outputs

| Workspace file | Generated source filename | Size |
|---|---|---|
| bali-stage-v1.png | exec-0de4caa9-b93d-46ed-97f2-760c60424ce4.png | 851 × 1848, RGB |
| kyoto-stage-v1.png | exec-b777df8f-56b3-4d8e-a4a4-9e8ab864c22c.png | 851 × 1848, RGB |
| travi-cutout-v2.png | exec-cfe2720f-b240-4715-bbf0-e62ff9bbe021.png | 1254 × 1254, RGBA |

The generated originals remain in `/Users/khairofamily/.codex/generated_images/01a10645-84b8-7482-bc0f-5b5d42d880ca/`. The selected character PNG has real alpha (0–255), with about 51.7% of pixels fully transparent. The previous extraction attempt was not selected because it had excessive empty canvas and a poor silhouette fit. The selected square asset includes the complete character and is positioned by CSS; it is not a full-screen alpha plate with reference coordinates.

The entrance, idle loop, rendered-frame posters and empty workshop are delivery copies from `../onboarding-intro-v1/`. Their exact video requests and processing are recorded there. The prototype animates whole scenic/character layers with CSS; it does not generate internal scene layers or an articulated character rig.
