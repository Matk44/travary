# Travi close-up app icon — exact prompts

Created on 12 October 2026 using the built-in `image_gen` tool in edit mode. Both calls used `transparent_background: true`. The generated PNGs and alpha are retained unchanged under `assets/branding`.

## Close-up portrait

Input: the existing approved turquoise passport icon, now archived as [previous-icon.png](previous-icon.png), used as the sole edit target.

```text
Use case: precise-object-edit
Asset type: regenerated Travary app icon artwork, one square 1024 x 1024 close-up portrait.
Input image 1: EDIT TARGET, the currently approved Travi passport icon. Preserve this exact mascot's identity, materials and colors.
Primary request: recompose the artwork as a dramatically closer view of Travi's TOP HALF holding the passport. The existing full-body mascot is too small on a phone. His cheerful face must be approximately TWICE as wide in the icon: his coral shell and face are the dominant forms. Show the upper half of the suitcase only, with the lower shell intentionally continuing past the bottom edge. NO wheels, lower corners, feet or full body. Do not place a small complete character floating inside generous margins.
Composition: tight and bold square crop. Travi's large face fills the center and right; the navy passport is held upright, raised beside his face on the viewer's left, with the existing hand naturally gripping its top edge. Bring the passport inward closer to his body so it fits the close-up instead of being at the end of a long outstretched arm. The passport should occupy about one quarter of the canvas width. Keep both big eyes, eyebrows and full open smile unobscured, and keep the whole passport cover visible. Retain the friendly raised waving hand on viewer's right if space permits, tucked closer to his shell; peripheral handle and fingertips may approach the edges. Preserve the white luggage tag with navy palm tree near the upper right of the shell. The navy-and-yellow suitcase handle remains recognizable behind his upper shell but must not force a distant crop.
Subject invariants: same coral-orange vertically ribbed suitcase, huge navy-and-white eyes, navy eyebrows, open delighted red-tongued smile, slightly tilted three-quarter view, dark navy clamshell edge, gold hardware, tactile faceted handmade 3D style, navy textured passport with gold globe and exact gold uppercase word "PASSPORT". Do not redesign or restyle the mascot.
Background: genuinely transparent alpha around the portrait and through the handle. It will be exported onto the approved flat turquoise blue #35C5DA. Keep clean antialiased edges; the lower coral shell reaches and is cropped by the bottom edge, with no artificial flat edge visible above the canvas boundary.
Avoid: wheels, full-body view, large empty margins, centered miniature character, folio, extra props, duplicate passports, borders, pre-rounded tile, shadows around the tile, text outside the passport, watermarks, changed expression or new character.
```

Output: [travi_passport_closeup_source.png](../../../assets/branding/travi_passport_closeup_source.png), 1254 × 1254 RGBA.

## Android lower-body bleed

Input: the newly generated close-up source above, used as the sole edit target.

```text
Use case: precise-object-edit
Asset type: transparent Android adaptive-icon foreground source with downward bleed.
Input image 1 is the EDIT TARGET: the newly generated square close-up of Travi holding his passport.
Primary request: EXTEND THE CANVAS DOWNWARD ONLY, to a 2:3 portrait image. Preserve the entire existing square image in the TOP TWO THIRDS at the same scale and position. Do not zoom out or recenter the existing artwork. Outpaint only the extra lower third by continuing Travi's coral vertically ribbed suitcase shell and navy right clamshell edge naturally downward. His body continues through the new bottom edge. This is extra lower bleed for launcher masking, not a new composition.
Keep the existing top portion visually identical: exact large smiling face, both eyes, brows, white palm-tree luggage tag, navy-and-yellow handle, raised waving hand and navy passport with gold globe and exact "PASSPORT" text, all at their current size and position. Retain the same tactile faceted 3D style and coral/navy/gold colors. No wheels or lower suitcase corners in the added area.
Background: genuinely transparent alpha, preserving transparency around the character and through the handle. No background, shadow, caption, border or additional prop. Never shrink the mascot into the new taller canvas. The original square close-up stays at the very top; the only new pixels are below it. Output one 2:3 portrait image.
```

Output: [travi_passport_closeup_bleed_source.png](../../../assets/branding/travi_passport_closeup_bleed_source.png), 1024 × 1536 RGBA. Its lower shell continues below the visible Android viewport, preventing a flat crop edge inside the launcher mask.

The export script performs only resizing, positioning, solid-background compositing and preview assembly. It does not repaint the generated artwork.
