# Pass-hold generation prompts

20 October 2026. Built-in imagegen; stills only.

## Initial generation

Edit target: `/Users/khairofamily/Desktop/Travi-ChatGPT/image-1-camera.png`.
Shared prompt from `../onboarding-keyframes-v1/BATCH-PROMPTS.md`, followed by frame 18 from the pass-purchase motion brief and one clarification resolving the perforation/held-tag constraints.

```text
Use case: identity-preserve / precise-object-edit.
Asset: one still keyframe for Travary onboarding, in the supplied folded-paper craft style.
Image 1 (image-1-camera.png) is ALWAYS the edit target and master camera reference. Edit Image 1. Any second image is a limited acting/prop reference ONLY, as identified below.

For normal pose frames, preserve Image 1's 941 x 1672 portrait framing, camera, lighting, character scale and position BY EYE. Travi stays in the right half of the image, his handle around the source height and wheels around the source baseline; the body must not be enlarged, moved to the centre or reframed to resemble a supporting reference. Only acting, hands and held props change. Frame 7 has its explicitly requested raised, full-frame folio composition instead.

Travi is the SAME coral ribbed-spinner suitcase mascot as Image 1: coral folded-paper body with vertical ribs, navy trim and corner caps, gold telescopic handle with navy grip, navy top carry handle, black spinner wheels with gold hubs, big friendly cartoon eyes and navy brows, articulated folded-paper hands. Keep his cream luggage tag with navy palm tree hanging from his handle in the same way as Image 1. Keep the character design and rich paper materials recognisable and consistent. Fit gestures within the canvas while retaining the body's size and spot.

Unless the frame explicitly says Travi holds the folio, the navy holiday folio stands at the lower left as in Image 1, matching its scale, angle and position by eye, with its cream palm emblem, brass clasp, gold corners and cream paper peeking out.

BACKGROUND: plain, even chroma green close to #00B140, edge to edge, with nothing else in it. Slight texture and small colour variation are fine. No scenery, visible floor, horizon, cast shadows, reflections, gradient or vignette. No green spill on the character or props.
Held writing surfaces are blank cream paper, without text, numbers, logos, lines or symbols, except the small person silhouette explicitly required in frame 12. Retain the permanent palm emblems on his hanging tag and navy folio. No added text, labels, UI, buttons, prices or watermark. Crisp edges, no motion blur.

Produce one image only, for the frame below.

18 — pass-hold

Travi proudly holds up ONE blank miniature boarding ticket in front of his chest with BOTH folded-paper hands, facing the viewer squarely and perfectly level so the app can lay artwork over it.
The ticket: a horizontal card about 2.5 times as wide as it is tall, roughly 70% of his body width, with a small semicircular notch cut into the middle of each short end and a dotted perforation line dividing a narrow stub on the left from the main face. A plain warm-gold foil edge and an EMPTY flat cream face: no words, no airplane, no logo, no numbers, no pattern.
His hands hold it by the two short ends so the face is fully visible; his fingers do not cover the face.
Delighted, proud expression: eyes bright, big closed-mouth smile, eyebrows lifted, looking at the viewer.
Wheels stay on the source baseline; body size and position as in Image 1. The navy folio stands at the left as in Image 1. Hanging tag unchanged.
No other props. No glow, sparkles or motion lines.

The dotted perforation is the sole exception to the shared no-lines instruction. Remove the separate HELD identity tag from Image 1; retain only the permanent hanging palm tag.
```

## Single refinement — selected review image

Edit target: the initial generated pass-hold still (source recorded in generation.json).

```text
Use case: precise-object-edit.
Asset: frame 18 pass-hold, a still keyframe for Travary.
Image 1 is the edit target: the generated pass-hold still.
The same image, ticket perfectly level and facing the camera. Make the ticket's top and bottom edges exactly horizontal, its left and right ends equal in height, its cream face a flat frontal plane without perspective skew. Retain the existing warm-gold foil edge, semicircular notches at the short ends, dotted perforation line defining a narrow LEFT stub, blank cream face and approximate 2.5:1 width-to-height. Both hands grip only the short ends, with fingers clear of the blank face.
Change only the ticket's alignment and the minimum finger/wrist adjustment needed to hold it level. Keep Travi's design, body scale and position, wheels and baseline, bright eyes and closed-mouth smile, eyebrows, handle and permanent hanging palm tag, standing navy folio at the left, paper materials, lighting, plain green background and portrait framing unchanged. No letters, numbers, logos, icons, patterns, scenery, shadows, glow, sparkles or motion. Keep the existing palm emblems on the hanging tag and navy folio. Produce one still image only, no animation.
```

