# Travi cameo stills

Seven cameos generated sequentially with built-in imagegen on 10 October 2026, using the supplied character references. The first six share the generated peek-hello composition and use the bottom canvas edge as Travi's hiding edge. Lounge is the separate full-body deckchair composition. These are stills for owner review; no animation or app integration was created, and no pixel editing was performed.

[Review gallery](review.html) · [Prompt set](PROMPTS.md) · [Full generation provenance and exact per-image prompts](generation.json)

All seven selected PNGs open successfully. The generator returned 1254 × 1254 square masters despite the requested 1024 × 1024; they are preserved unedited for subsequent cleanup/resizing by Claude.

| # | Still | Format |
| --- | --- | --- |
| 1 | [peek-hello](peek-hello.png) | Peek |
| 2 | [peek-wave](peek-wave.png) | Peek |
| 3 | [peek-cheer](peek-cheer.png) | Peek |
| 4 | [peek-packing](peek-packing.png) | Peek |
| 5 | [peek-ready](peek-ready.png) | Peek |
| 6 | [peek-today](peek-today.png) | Peek |
| 7 | [lounge](lounge.png) | Lounge |

`peek-hello-draft-01.png` is an earlier crop attempt; the selected `peek-hello.png` extends the coral body to the actual bottom canvas edge. Minor green and pixel differences are accepted for subsequent cleanup outside this image-generation task.

## Lined up for the films (Claude, 10 October 2026)

`build_cameos.py` checks the six peeks share one mark (they do: the handle's
grip is within 1 px in all six, and his body runs into the bottom edge in
every one), flattens the green to #00B140, scales to 1024 × 1024 and adds
`peek-empty` (plain green). Output in [`registered/`](registered/):
[contact sheet](registered/contact.png) and
[in place](registered/in-place.png) (peeking from behind the countdown
postcard at 90 points, approved; 120 ran into the date pill). In the app he
sits behind the card, sunk about 6 points so its deckled edge covers his cut
and his fingertips: never a straight cut on top of the card
([close up](registered/in-place-detail.png)).

### Clips (made 10 October 2026: 6 paid, 480p, 1:1, 4 s; prompts in [`shots.json`](shots.json))

He pops straight up into a moment and ducks back from it: each duck is its
pop-up played backwards (`reversed` in shots.json), so only the ups were
paid for. Made with `films.py --set cameos`, processed with
`process.py --set cameos` (keyed frames in the git-ignored `keyed/`), and
reviewed in place with `preview.py` ([preview.mp4](preview.mp4)).

| Clip | From → to | Plays when |
|---|---|---|
| wave-up (wave-down) | empty → wave | First open of the day |
| cheer-up (cheer-down) | empty → cheer | Countdown tag tapped, a month or more to go |
| packing-up (packing-down) | empty → packing | About a week to go |
| ready-up (ready-down) | empty → ready | The day before |
| today-up (today-down) | empty → today | Departure day |
| lounge-idle | lounge ↺ | A free day mid-trip |

Seedance had him leap clear of the edge (wheels showing) on the way up in
cheer, packing, ready and today, against the prompt; in place it reads as a
jump for joy over the postcard, so they're kept unless the owner says
otherwise. The lounge snapped its drink back at 3.17 s: rather than re-roll it, the
loop plays its calm first 1.4 s forward and back (`palindrome`), so it
returns to the first frame with no snap.
