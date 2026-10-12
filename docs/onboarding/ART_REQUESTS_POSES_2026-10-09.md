# Travi key poses — art request, 9 October 2026

Onboarding is being rebuilt as **one stage with a locked camera**: the
destination stays behind, Travi always stands in the same spot on the floor,
and only his pose, what he holds, the words and the controls change. These
poses are the still for each beat. They're shown directly (with in-app
motion between them) and later become the first/last frames of the films.

Four already exist and stay as they are (cleaned green plates in
`docs/mockups/onboarding-green-plates-v1/`): **holding the booking card**
(`green-proof-clean-v1.png`), **offering the ID tag** (`green-account-clean-v1.png`),
**offering the envelope** (`green-email-clean-v1.png`) and the **full-screen
open folio** (`green-folio-clean-v1.png`). This request is the rest.

## How to make them

One ChatGPT chat for all of them, so Travi stays identical:

1. Attach **Input 1**: `docs/mockups/onboarding-green-plates-v1/green-account-clean-v1.png`
   (it sets the camera, Travi's size and spot, the folio and the green).
2. Paste the **shared rules** below once.
3. Then paste each pose prompt, one per image, attaching **Input 2** where a
   pose lists one.
4. Save each image as named, in `docs/mockups/onboarding-poses-v1/`.

If an image comes out at a different size (e.g. 1024 × 1536), that's fine:
Claude lines each one up by Travi's wheels and the folio. What matters is
that Travi and the folio don't move between poses.

### Shared rules (paste once)

```text
You're making key poses for Travi, the coral ribbed-spinner suitcase mascot
of the Travary travel app. In the app Travi always stands in the same spot on
a stage while the destination changes behind him, so every pose must line up
exactly with Input 1. Each image is a green-screen plate the app keys out.

For every image:
- Edit Input 1. Keep its exact canvas (941 x 1672 portrait), camera, scale,
  lighting and folded-paper craft look.
- Travi is the same character as in Input 1: coral ribbed spinner suitcase,
  navy trim and corner caps, gold telescopic handle with a navy grip, navy
  top carry handle, black wheels with gold hubs, a cream luggage tag with a
  navy palm tree hanging from his handle, big friendly cartoon eyes and
  brows, folded-paper hands.
- Travi stands exactly where he is in Input 1: same size, same position,
  wheels on the same floor line. Only his arms, face and what he holds
  change, unless the pose says so.
- The navy holiday folio (palm emblem, brass clasp, gold corners) stands at
  the left exactly as in Input 1, unless the pose says Travi is holding it.
- Everything else is one perfectly flat, evenly lit chroma green, #00B140,
  edge to edge: no floor, horizon, shadow, reflection, gradient, vignette,
  scenery or texture. No green tones or green spill on Travi or the props.
- Anything Travi holds that the app will write on (tags, cards, paper) is
  completely blank: no text, numbers, logos, lines or symbols.
- No text, labels, UI, buttons, prices, logos or watermark anywhere.
- Crisp edges, no motion blur.
```

### The poses

**0. `pose-arrived-v1.png`: the hand-off from the arrival film**
Input 2: `assets/onboarding/travi-settled-v1.png` (the film's last frame)

```text
Pose: copy Travi's pose and expression from Input 2 exactly: his left arm
reaching out to the side with an open hand, his right arm raised in a wave,
the same friendly closed-mouth smile and eyes on the viewer, the same tag.
Keep Input 1's camera, size, position and floor line, not Input 2's. The
folio stands at the left as in Input 1. No workshop, arches or tickets.
```

The app cross-fades the arrival film onto this pose as the destination
folds up behind Travi, then pops him into the hooray pose. The closer it
matches Input 2, the less the hand-off shows.

**1. `pose-hooray-v1.png`: the destination appears**

```text
Pose: Travi has just arrived somewhere wonderful. Both arms thrown up in
delight, eyes bright and wide, big open happy smile, a slight joyful lean
back on his wheels (wheels still on the same floor line). Hands empty. The
folio stands at the left as in Input 1.
```

**2. `pose-tag-v1.png`: "When do we leave?"**

```text
Pose: Travi proudly holds up a large blank departure luggage tag in front of
his chest with both hands, facing the viewer squarely so it can be written
on. The tag is cream card, a rounded rectangle about 60% of his body width,
with a brass grommet hole at the top and a short loop of twine. Perfectly
blank. He looks at the viewer, excited. The folio stands at the left.
```

**3. `pose-folio-open-v1.png`: "Got a booking for me?"**

```text
Pose: Travi now holds the navy folio himself, open toward the viewer with
both hands like presenting a fresh notebook: its two inside pages are blank
cream paper, with a small paper pocket on the left page. The open folio is
roughly front-on and about as wide as his body, held at chest height. No
folio standing at the left any more. Warm, inviting smile.
```

**4. `pose-reading-v1.png`: while a screenshot or PDF is being read**

```text
Pose: Travi studies a blank sheet of cream paper held up in one hand, with a
small brass magnifying glass in the other, one eyebrow raised in
concentration and the tip of his tongue out. The folio stands at the left.
```

**5. `pose-linked-v1.png`: "Your holiday. Linked to you."**
Input 2: `docs/mockups/onboarding-poses-v1/ref-linked-storyboard.png`

```text
Pose: match the acting of Input 2 (the approved storyboard frame): Travi
tucks the cream identity tag (person silhouette) into the top of the navy
folio, which he holds against his side; eyes closed in a happy, proud
smile. Keep Input 1's camera, size, position and floor line, not Input 2's.
```

**6. `pose-present-v1.png`: "Shall I help with the rest?"**
Input 2: `docs/mockups/onboarding-green-plates-v1/green-pass-clean-v1.png`

```text
Pose: the same as Input 2: Travi presenting with an open palm toward the
floor in front of him, the folio standing at the left. But nothing at all
on the floor in front of him: no passes, no tickets, no bar. Keep Input 1's
camera, size, position and floor line.
```

**7. `pose-sendoff-v1.png`: "Your holiday's ready"**

```text
Pose: Travi waves goodbye with one arm held high, and with the other hand
holds the navy folio out toward the viewer as if handing it over. Joyful,
"have a wonderful trip" expression. No folio standing at the left any more.
```

**8. `pose-oops-v1.png`: when something doesn't work (offline, cancelled)**

```text
Pose: Travi gives a sheepish shrug, one hand rubbing the back of his handle,
a small apologetic smile and raised brows. The folio stands at the left.
```

## Before handing over

- Flip between each pose and Input 1: the wheels and (where present) the
  folio sit in exactly the same place.
- Tags, cards and paper are blank; nothing green is left on Travi.
- Record the exact prompt for each image in
  `docs/mockups/onboarding-poses-v1/PROMPTS.json`.

## What Claude does with them

Keys each onto transparency, lines it up to the stage floor, and builds the
single-stage onboarding: the destination pops up behind Travi, he moves from
pose to pose, live text sits on the blank tag and card, and the passes slide
onto the floor in front of him. No films are needed for this; the films come
afterwards, animating between these exact poses.
