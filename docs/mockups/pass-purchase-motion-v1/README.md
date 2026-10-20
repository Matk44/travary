# Pass purchase: confirmation motion plan (v1)

20 October 2026. **Status: films made and processed, awaiting the owner's
review** before `export.py` and the app integration. The static confirmation is built and shipping (below).
Frame 18 came from ChatGPT on 20 October ([still](frame-18-pass-hold.png),
[prompts](PROMPTS.md), [provenance](generation.json)), reviewed and
registered the same day (below). The films wait for the owner's go-ahead.

## What ships now (static, no new artwork)

Once the store confirms a pass, the pass desk (`OnboardingPassPanel`), on
the paywall and on onboarding's desk, turns into a confirmation:

| | |
|---|---|
| Travi | `present` → `cheer`, the **existing** `cheer` film (`traviCuesForPassConfirmed`) |
| Words | "Enjoy your / **holiday!**" · "Your Holiday Pass is on." / "Every holiday, / **sorted!**" · "Your Annual Pass is on." / a restore: "Welcome / **back!**" (`passConfirmedWords`) |
| Floor | the bought pass's foil badge (`PassBadge`, 250 pt max) slapped on (live UI, 560 ms, easeOutBack, settles 1° askew; reduced motion: no movement), what it covers ("Japan holiday" · "3–12 Nov · covered until 19 Nov 2026", or "Every holiday" · "Renews on 20 Oct 2027 · cancel anytime"; `passCoverageFor`), and **Carry on** / **Open my holiday** where the desk's button was |
| Leaving | Carry on, Close and Back all mean "bought": the booking, file or invite that opened the desk goes ahead |

The trip then carries the badge tucked onto its postcard's top-left corner
(`TripHero.badge`), as well as on Today and the Trips tab.

A payment the server hasn't recorded yet keeps the desk's "Payment
received…" line and is never celebrated. Shared access from someone else's
pass is never shown as theirs.

## The animated version (to make)

One locked camera, as in onboarding: Travi stands on his mark while the
stage stays still. The props he handles are **blank** in the films; the
app's live UI takes over as they leave his hands (`TraviFilm.handoff`), as
the dates' luggage tag and the saved booking card already do.

### Storyboard

| # | Beat | Travi (film / key frame) | Live UI | Time |
|---|---|---|---|---|
| 0 | The desk | `present` idle (exists) | the two passes on the floor | — |
| 1 | Store confirms | **F1 `pass-up`**: `present` → **18 `pass-hold`**. He reaches down to the desk, lifts a blank foil ticket and holds it up to the viewer, delighted | the paper passes slide down off the floor as he reaches; the words change | ≈ 2.6 s |
| 2 | Shows it | `pass-hold` held still | the real badge (Holiday or Annual) is drawn **over the blank ticket in his hands**, measured to its box, exactly as `ProofCardWords` writes on the saved booking card | ≈ 1 s hold |
| 3 | Slaps it down | **F2 `pass-toss`**: `pass-hold` → `cheer` (exists). He flicks the ticket down toward the desk; it leaves his hands at the handoff | **handoff ≈ 0.5 s**: the badge leaves his hands as live UI, falls to the floor and is slapped on (the shipping stamp-in) over what it covers | ≈ 2.2 s |
| 4 | Celebrates | `cheer` held (optional **F3 `cheer-idle`** loop) | Carry on (on screen from beat 1: controls never wait for motion) | — |
| 5a | Paywall, from the trip page | `cheer` → `wave` (`wave-paid`, exists) as the desk closes | the badge flies from the floor to its corner of the trip's postcard (a Flutter `Hero` between the desk badge and `TripHero.badge`) | ≈ 0.6 s |
| 5b | Onboarding | `wave` → `folioFull` (`finale`, exists), then the holiday opens | the holiday's postcard already wears the badge | — |

Why the badge is drawn over a blank prop, not painted in: the Holiday Pass
is gold and the Annual Pass teal and gold, and their lettering must be
crisp and correct. One blank prop serves both, and only one key frame and
two films are needed instead of four.

### New key frame: 18 `pass-hold`

**Made and registered (20 Oct 2026).** Review: the same Travi; one blank
cream ticket with a gold edge, notched ends and a perforation, held level by
both ends with the face clear; a delighted closed-mouth smile. He faces the
camera more squarely than in `present` (as in `cheer`, where the toss film
ends), so `pass-up` turns him; the by-eye folio and wheel offsets were
corrected by registration. `build_keyframes.py 18-pass-hold` (frames can now
be named, leaving the approved ones untouched) wrote
`../onboarding-keyframes-v1/registered/18-pass-hold.png`: scale 0.93, wheels
on the shared floor line (y 1176), the canonical folio in its place.

**The ticket's box on the registered frame** (941 × 1672), gold edge
included: x 398–644, y 892–989 (246 × 97, 2.54:1; as fractions left 0.423,
top 0.533, width 0.261, height 0.058). His thumbs overlap its two ends, so
the overlay sits just inside them. The badges are 2.5:1, so either pass
covers the blank face.

The prompt it was made from:

Same inputs and shared prompt as frames 02–16 (`../onboarding-keyframes-v1/BATCH-PROMPTS.md`):
Image 1 is `~/Desktop/Travi-ChatGPT/image-1-camera.png`, 941 × 1672, green
close to #00B140. Paste the **shared prompt** from that file, then:

```text
18 — pass-hold

Travi proudly holds up ONE blank miniature boarding ticket in front of his chest with BOTH folded-paper hands, facing the viewer squarely and perfectly level so the app can lay artwork over it.
The ticket: a horizontal card about 2.5 times as wide as it is tall, roughly 70% of his body width, with a small semicircular notch cut into the middle of each short end and a dotted perforation line dividing a narrow stub on the left from the main face. A plain warm-gold foil edge and an EMPTY flat cream face: no words, no airplane, no logo, no numbers, no pattern.
His hands hold it by the two short ends so the face is fully visible; his fingers do not cover the face.
Delighted, proud expression: eyes bright, big closed-mouth smile, eyebrows lifted, looking at the viewer.
Wheels stay on the source baseline; body size and position as in Image 1. The navy folio stands at the left as in Image 1. Hanging tag unchanged.
No other props. No glow, sparkles or motion lines.
```

If the first result is close but the ticket is tilted, ask once for "the
same image, ticket perfectly level and facing the camera". Small colour or
texture differences are fine; Travi's design, size and position must match.
After approval, add it to `build_keyframes.py` as `pass-hold` so it lands on
the shared camera (`registered/pass-hold.png`), then measure the ticket's
face box on the registered frame for the overlay.

### Films for Scene Studio

**Made 20 Oct 2026** (Scene Studio, Seedance 2.0) and processed:

| Film | Result |
|---|---|
| `pass-up` | clean: he turns from presenting, reaches down, lifts the blank ticket and holds it up level (2.7 s, no jumps) |
| `pass-toss` | the "tiny bounce" came out as two hops (1.42–1.71 s and 1.83–2.17 s, wheels up to 120 px off the floor). Cut 1.40–2.21 s (`cut`, `keep` 0–2.6 s fixed): the ticket drops, he cheers on the floor, about 3 frames cross-fade at the join (1.8 s) |
| `cheer-idle` | hopped three times; looped as a `palindrome` to 0.7 s instead (1.4 s: eyes open, fists pump, back), one small 30 px bounce |

Preview of the chain over the Tokyo and Switzerland stages:
`../onboarding-films-v2/preview-pass-up-pass-toss-cheer-idle-cheer-idle.mp4`.
If either fix doesn't read well on a phone, a re-roll of that film with
"wheels never leave the floor" is the alternative.

**Now in `../onboarding-films-v2/shots.json`** as `pass-up`, `pass-toss`
(handoff 0.45 s) and `cheer-idle` (a loop, optional), written in that file's
house style; its shared identity and green-screen block is added to each
prompt. Not submitted. To make them, with Scene Studio running
(`~/Documents/video_generator`, `npm run dev`, port 3717):
`python3 docs/mockups/onboarding-films-v2/films.py submit pass-up pass-toss cheer-idle`,
then collect, `process.py` and `export.py` as for every film. The first
drafts below are kept for reference.

```json
{
  "pass-up": {
    "from": "13-present",
    "to": "18-pass-hold",
    "seed": 410481,
    "keep": [0.0, 2.6],
    "prompt": "ONE continuous four-second shot from the supplied first frame (Travi presenting with an open palm, hands empty) to the supplied last frame (Travi holding a blank foil ticket up to the viewer with both hands).\n0-0.3s: hold the first frame.\n0.3-1.2s: he looks down at the desk below the frame with a delighted gasp, leans a touch and reaches down with both paper hands out of the bottom of the frame.\n1.2-2.0s: he lifts a small blank ticket card with a gold foil edge and a plain cream face up into view and raises it to chest height, turning it to face the viewer, beaming.\n2.0-4s: hold the EXACT supplied last frame perfectly still (one soft blink at most). The ticket face stays completely blank throughout.",
    "keep_fixed": true
  },
  "pass-toss": {
    "from": "18-pass-hold",
    "to": "14-cheer",
    "seed": 410482,
    "keep": [0.0, 2.2],
    "prompt": "ONE continuous four-second shot from the supplied first frame (Travi holding a blank foil ticket up with both hands) to the supplied last frame (Travi cheering, both arms up, hands empty).\n0-0.2s: hold the first frame.\n0.2-0.6s: with a quick, happy flick he sends the ticket straight down and toward the viewer; it leaves his hands and drops out of the bottom of the frame, gone by 0.6s.\n0.6-1.6s: both arms go up in a joyful cheer, eyes squeezed happy, a tiny bounce, wheels stay on the floor line.\n1.6-4s: hold the EXACT supplied last frame perfectly still (one soft blink at most).",
    "keep_fixed": true,
    "handoff": 0.5
  },
  "cheer-idle": {
    "from": "14-cheer",
    "to": "14-cheer",
    "seed": 410483,
    "keep": [0.0, 3.0],
    "prompt": "ONE continuous three-second loop that starts and ends on the EXACT supplied frame (Travi cheering, both arms up). He gives a small happy bounce on his wheels and one soft blink, arms staying up, and settles back exactly into the first frame. Wheels stay on the floor line. No new props.",
    "keep_fixed": true
  }
}
```

Then, as for every film: `films.py` submits and collects through Scene
Studio's API, `process.py` keys and trims to `keep`, `export.py` writes the
animated WebP and regenerates `lib/logic/onboarding_film_assets.dart` (never
hand-edited). The app side, once the films are in:

- `traviCuesForPassConfirmed()` → `pass-hold` (with a hold), then `cheer`;
  `traviRoute` finds `pass-up` and `pass-toss`.
- An overlay on `pass-hold` (like `ProofCardWords` on `card`) draws the
  bought `PassBadge` in the measured ticket box; it fades as he winds up the
  flick.
- `pass-toss`'s handoff starts the floor badge's flight from his hands to
  the floor (the shipping stamp-in, started from the handoff point instead
  of above the floor).
- Leaving the paywall from the trip page: a `Hero` from the floor badge to
  `TripHero.badge`.
- Reduced motion: today's static confirmation. Tests keep
  `TraviPlayer.playback = false`.

### Checkpoints for the owner

1. Approve the static confirmation on a phone (TestFlight).
2. Make frame 18 in ChatGPT from the prompt above; approve it.
3. Go-ahead to submit `pass-up` and `pass-toss` (and optionally `cheer-idle`)
   to Scene Studio; review the films.
4. Then the app integration above.
