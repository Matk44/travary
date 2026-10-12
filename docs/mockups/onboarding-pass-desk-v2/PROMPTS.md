# Pass desk v2 — exact imagegen prompts

6 October 2026. Both edits use the built-in imagegen tool. Originals are retained unchanged; Flutter slices the clean atlas at runtime. No prices or product names remain in the runtime art.

## Approved composition, lettering removal

Reference: `approved-reference.png` (owner attachment).

```text
Use case: precise-object-edit.
Asset type: production text-free paywall artwork for the Travary Flutter app.
Input image 1 is the EDIT TARGET and the user's approved exact design. Preserve its precise framing, portrait 851×1848 aspect ratio, all physical object shapes, detailed embossed paper texture, teal header space, lush Balinese scenery, coral sun, coral ribbed spinner Travi on the RIGHT with this exact face/expression/gesture/handle/tag/wheels, navy folio on the LEFT, cream foreground floor, TWO perfectly horizontal paper tickets (coral stub then navy stub), their cream palm-tree emblems, brass eyelets, notches and perforations, separator rules, and the large navy notched paper button. Do not resize Travi, shrink the scenic section, reinterpret the scene or change ticket positions.
Primary request: remove ALL typography and digits from the entire image, filling only those exact lettering pixels with matching underlying paper/landscape texture. Erase Travary, both headline lines, subtitle, Bali holiday on the folio, every ticket title/scope/price/terms, the benefit line, button title, Continue with free and Restore purchases, including their underlines. Preserve the cream palm-tree decoration on the navy folio and the palm-tree decorations on the coloured ticket stubs.
Also remove the two selection controls: the coral circular check on the first ticket and the navy outlined circle on the second; restore plain warm cream paper at those two locations. Keep the fine vertical separator rule before each selection zone.
The result must be the same illustration as the input with ONLY text and selection controls removed. Ticket text areas and button are absolutely blank, clean and suitable for native dynamic text overlays. No new letters, numbers, prices, badges, selection icons, watermarks, gradient sheets, UI cards or extra objects. Keep composition, colours, exact lighting, paper grain and character identity unchanged. Opaque portrait image.
```

## Shared transparent foreground

Reference: the clean atlas original returned by imagegen.

```text
Use case: background-extraction.
Asset type: shared transparent Travi-and-folio foreground layer for every country’s paywall.
Input image 1 is the edit target. Keep ONLY the complete coral ribbed spinner Travi and the complete navy folio from this exact approved composition, with their cream palm emblems, brass hardware, extended handle, wheels, hands, expression and materials unchanged. Remove all landscape, trees, sky, sun, curtains, cream floor and every ticket/button. No lettering remains on the folio.
Preserve the exact positions and proportions of Travi at the right and folio at the left, including Travi’s presenting gesture. Keep the original full 851×1848 portrait canvas and object coordinates, with all removed regions genuinely transparent. Retain a restrained contact shadow at their original feet only. This is a clean sprite layer of those two existing objects; do not redraw/reinterpret the mascot, add objects, change expression, crop wheels/handle/tag/hands or leave scenery. True alpha transparency. No text or checkerboard.
```

The Bali layout uses the clean atlas directly to preserve the approved composition. Other countries use their own stage and the shared foreground. This cutout is a separate generated edit; geographic combinations and matte edges require visual review when a new country plate is introduced.
