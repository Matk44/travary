# Night flight ticket border refinements

Built-in imagegen edits of [Night flight](../app-icon-v7/20-night-flight.png), focused on separating the internal ticket from the near-black background. The aircraft, stripes, perforation and square background were preserved. The iOS and Google Play corner masks belong to the platforms; neither option adds a border around the square canvas.

## Options

- **Ivory keyline:** [1024 px](24-ivory-keyline.png) · [64 px](24-ivory-keyline-64.png) · [32 px](24-ivory-keyline-32.png). Cleanest separation at small size; recommended of the two.
- **Brass edge:** [1024 px](25-brass-edge.png) · [64 px](25-brass-edge-64.png) · [32 px](25-brass-edge-32.png). Warmer print finish; visually closer to the mustard stripe.

Both final icons are opaque 1024 × 1024 PNGs. Generated 1254 px sources are retained. They are concepts; launcher assets and store listings have not been changed.

## Store-readiness notes

- Apple asks for a clear, recognizable app icon and square 1024 px source. The system masks corners. [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/app-icons/)
- Apple accepts a flattened image, while layered artwork gives more control over system effects. Inspect automatic dark and tinted appearances before release. [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/app-icons/)
- Google Play's listing icon is 512 × 512 px, sRGB, 32-bit PNG, maximum 1 MB, full square; Play supplies its own mask and outer shadow. This 1024 px concept needs a separate compliant Play export. [Google Play specification](https://developer.android.com/distribute/google-play/resources/icon-design-specifications)
- A plane and ticket clearly signal travel. Because Travary covers the whole holiday rather than flights alone, the store subtitle and first screenshot should explain the daily itinerary and booking wallet. This is a design inference, not a platform rule.
- Measure conversion with [Apple Product Page Optimization](https://developer.apple.com/help/app-store-connect/create-product-page-optimization-tests/configure-test-treatments) and [Google Play listing experiments](https://support.google.com/googleplay/android-developer/answer/12053285?hl=en). For Apple's icon test, alternate icons must be included in the current app binary.

## Exact edit prompts

### Ivory keyline

```text
Use case: precise-object-edit.
Asset type: revised Travary app icon.
Input image 1 is the EDIT TARGET: the exact Night flight vertical ticket concept. Keep the plane silhouette, its location and scale, all perforations and ticket notches, the orange and mustard diagonal stripes, ticket navy fill, outer near-black navy background, square crop, paper texture, lighting and all other details exactly as in the input. Change ONLY the separation between the outer perimeter of the ticket and the surrounding dark background.
Keep the finished image a full square with opaque navy background filling all four edges. No pre-rounded app mask or new frame around the square. No glow, vignette, halo, 3D bevel, text, additional illustration, new colours inside the ticket, or altered airplane. The added edge should read at 32 pixels without becoming a heavy cartoon outline.
Specific edit: create one continuous slim warm-ivory letterpress keyline following the COMPLETE die-cut ticket perimeter, including the clipped upper corners, side semicircular tear notches and lower corners. Keep it just inside the ticket edge, about 12-14 px thick at 1024 px export size, with subtly imperfect print edges. Preserve a small navy gap between the keyline and every plane/stripe element. The result is a tactile cream printed border that gives the ticket a clean silhouette against the darker background.
```

### Brass edge

```text
Use case: precise-object-edit.
Asset type: revised Travary app icon.
Input image 1 is the EDIT TARGET: the exact Night flight vertical ticket concept. Keep the plane silhouette, its location and scale, all perforations and ticket notches, the orange and mustard diagonal stripes, ticket navy fill, outer near-black navy background, square crop, paper texture, lighting and all other details exactly as in the input. Change ONLY the separation between the outer perimeter of the ticket and the surrounding dark background.
Keep the finished image a full square with opaque navy background filling all four edges. No pre-rounded app mask or new frame around the square. No glow, vignette, halo, 3D bevel, text, additional illustration, new colours inside the ticket, or altered airplane. The added edge should read at 32 pixels without becoming a heavy cartoon outline.
Specific edit: create one continuous muted aged-brass / warm mustard printed edge along the COMPLETE ticket contour, including clipped upper corners, both tear notches and lower corners. The edge is about 15-18 px thick at 1024 px export size and slightly uneven as if ink caught on the cut paper. Keep it matte, quiet and warm, visibly separating the dark ticket from the near-black background. No cream keyline, metallic shine, drop shadow, glow or extra border line.
```


