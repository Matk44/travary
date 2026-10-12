# Travi passport app icon — exact ImageGen prompt

Generated on 9 October 2026 with the built-in `image_gen` tool in edit mode, with `transparent_background: true`.

The sole input was the owner's [screenshot](reference.png), used as the edit target. The previous airplane icon was inspected for project context but was not an ImageGen input.

```text
Use case: precise-object-edit
Asset type: production mascot artwork for the Travary iOS and Android app icon, square 1024 x 1024 PNG.
Input image 1 is the EDIT TARGET: the user's screenshot of Travi on bright chroma green. Edit this exact character, not a redesign.
Primary request: replace ONLY the large navy travel folio held in Travi's hand on the viewer's left with a clearly recognizable navy-blue PASSPORT booklet. Remove the folio completely, including its flap, fastening strap, button, corner protectors and palm-tree cover mark. Make the passport a little smaller than the old folio, upright in portrait proportions with a navy textured cover, subtle cream page edges, simple gold globe emblem and the exact word "PASSPORT" in small gold uppercase letters above the globe. The existing hand should naturally grip the passport's upper edge; match the original perspective and lighting.
Subject invariants: preserve Travi's exact cheerful coral-orange vertically ribbed suitcase body, slightly tilted three-quarter pose, huge expressive eyes and navy brows, open delighted smile, extended yellow telescoping handle with navy grip, coral arms and five-finger waving hand on viewer's right, dark spinner wheels with yellow hubs, and white luggage tag with navy palm-tree symbol. Preserve the handmade faceted 3D material, orange/coral color variation, face proportions, accessories, pose and personality of the input.
Background: genuinely transparent alpha. Remove all green backdrop, white vertical and horizontal guide lines and screenshot artifacts, including inside the open handle and between fingers. No green spill or opaque background. Retain clean antialiased edges.
Composition: one complete character and passport, centered together on a square transparent canvas, with comfortable even padding around the full silhouette. Keep the entire waving hand, handle, wheels and passport visible. Render clean and crisp at high resolution while keeping the same tactile style. Passport stays on viewer's left and never obscures the face.
Avoid: new props, tickets, extra characters, badges, borders, rounded-corner tile, icon mockup, drop shadow outside the character, watermark, captions or text outside the passport. No redesign, different expression, different pose, metallic suitcase, extra fingers or missing wheels.
```

Backgrounds and platform exports were produced mechanically from the generated transparent cutout using [export_app_icons.py](../../../tool/export_app_icons.py). The generated source and its alpha are retained unchanged in [travi_passport_source.png](../../../assets/branding/travi_passport_source.png).
