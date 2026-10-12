# Onboarding storyboard v2: one continuous story

Proposal, 9 October 2026, after the owner's review of the single-stage build:
every screen must flow into the next as one animated story, never Travi
jumping between places; make it engaging, not just fixed. Key frames for
ChatGPT: [`chatgpt-poses/PROMPT.md`](chatgpt-poses/PROMPT.md).

## What to keep, what to change

**Keep** (from `docs/ONBOARDING_STORY.md`): Travi is the traveller's porter,
the traveller is the hero; each choice changes something real; the first
booking is the proof; the passes come after the proof; it ends inside their
actual holiday. The continuing objects stay: the folio, the tag, the card.

**Change:**

1. **It plays like a form with a mascot beside it.** Travi poses, you fill
   in fields. Now every answer makes something happen on stage, and Travi
   does the task with you.
2. **The big moments are flat or missing.** The world arrives as a fade,
   the dates turn into nothing, the booking proof is a card in his hand and
   the end is a cut to the app. Each becomes a moment: the world pops up,
   the dates ink onto a tag that slaps onto the screen and counts down, the
   booking flies into a real Day 1, and Travi hands you the folio, which
   opens into your trip.
3. **The ask is the dullest part.** Sign-in and the passes are where we ask
   for something, so Travi acts most there: the ID tag, the stamp, the cheer.
4. **No momentum.** The departure tag stays on screen from the dates on and
   gains a stamp for each thing done (place, dates, first booking): progress
   you can see, with no step counter.

## Rules for the whole thing

- **One camera, start to finish.** Travi stands on the same mark from the
  roll-in to the goodbye; the world changes behind him (stage plates,
  in-app pop-up). The workshop becomes a plate too, so the opening is on
  the same camera (no pull-back).
- **Every pause is a held key frame with an idle loop; every tap plays a
  film from that frame to the next.** Films start and end exactly on key
  frames, so any chain of them is seamless.
- **Props become UI.** Anything that carries the traveller's own words
  (tag, card, passes) is blank in the films. When Travi tosses it to the
  viewer, the live version (real place, dates, booking, prices) takes over:
  the tag slaps onto the screen, the card flies into Day 1.
- **Never wait for decoration.** Controls appear as a film starts; a tap
  skips to the next key frame. Reduced motion shows the key frames only.
- **Feel it.** A light haptic on the tag slap and stamps, a success haptic
  when the booking lands in Day 1. Optional soft paper sounds, never with
  the ringer off.
- **The place is alive.** A light ambient layer per destination over its
  stage (petals or maple leaves for Japan, snow for Switzerland and
  Iceland, lanterns, sparkle on the sea), drawn in the app.

## The story

| # | Scene | The traveller | Travi (films) | The magic (live, in-app) |
|---|---|---|---|---|
| 1 | Hello | Opens the app | Rolls into the paper workshop, brakes a little too keenly, waves. *Where are we off to?* | — |
| 2 | The world arrives | Picks a place | Spins to look as the world rises behind him, gasps, arms up | The workshop folds flat, the destination pops up like a pop-up book page, its ambience starts. *Tokyo! I've always wanted to go.* |
| 3 | The tag | Picks dates (or "not decided") | Whips out a blank departure tag, holds it up; then flicks it to you | The place and dates ink onto the tag, it slaps onto the screen and swings: *24 sleeps to go*. First stamp |
| 4 | Got a booking? | Screenshot/PDF, type it in, or later | Opens the folio to you. Reading: a magnifying glass while Smart Import works. Typing: the folio comes up to fill the screen | The form and the flight board are the folio's pages |
| 5 | Day one, sorted | Saves the booking | Pulls the new card from the folio, shows it off, flicks it to you, hands on hips | The card (real booking) flies onto a Day 1 strip that unrolls across the floor. Success haptic. Second stamp. *That's day one sorted.* |
| 6 | Keep it with you | Signs in, email, or guest | Offers an ID tag; tucks it into the folio (signed in) or pockets it with a smile (guest) | *Keep your holiday with you.* |
| 7 | The paywall: "Shall I help with the rest?" | Picks a pass, or "Continue with free" | Presents the floor (frame 13); a cheer if they buy | The approved pass desk: the two paper passes and the navy button slide onto the floor with live RevenueCat names and prices; a bought pass gets a stamp. The last decision in onboarding |
| 8 | Off we go | Nothing to do: it plays after either choice | Waves and holds the folio out to you; it comes up and opens | Not a screen, the hand-off: the folio's pages become the trip screen; the stage settles into the trip's postcard |

Unknown dates: the tag reads "Dates to come". Later (no booking): Travi
closes the folio with a shrug and a smile, hands on hips, and the story goes
on to scene 6. Something goes wrong: the oops shrug, then back to proud.

## Key frames (17 new images + Image 1)

01 empty · 02 hello · 03 wow · 04 tag · 05 toss · 06 folio-open ·
07 folio-full · 08 reading · 09 card · 10 proud · id-tag (Image 1, kept) ·
11 envelope · 12 linked · 13 present · 14 cheer · 15 wave · 16 oops ·
17 workshop (the opening's backdrop plate).

The old plates (proof, email, pass, folio) aren't on one camera (Travi and
the folio sit in different places in each), so they're redrawn from Image 1.
Destination backdrops are a separate set: `ART_REQUESTS_STAGES_V2_2026-10-09.md`.

## Films (Scene Studio, Seedance 2.0, first and last frame)

Seedance renders at least 4 s; each film is acted early and then retimed to
its length, keeping the exact end frame.

| Film | From → to | Length | Plays when |
|---|---|---|---|
| Roll in | empty → hello | 3 s | App opens |
| World arrives | hello → wow | 2.5 s | Place chosen |
| Tag out | wow → tag | 1.5 s | Straight after |
| Tag toss | tag → toss | 1 s | Dates chosen / not decided |
| Folio up | toss → folio-open | 2 s | Straight after |
| Reading | folio-open → reading | 1.5 s | File chosen |
| Got it | reading → folio-open | 1.5 s | Draft ready |
| Folio in / out | folio-open ↔ folio-full | 1 s | Type it in, flight, review (reversed to come back) |
| Card out | folio-open → card | 2 s | Booking saved |
| Card toss | card → toss | 1 s | After the card's moment |
| Proud | toss → proud | 1.5 s | Straight after |
| Later | folio-open → proud | 1.5 s | "Later" |
| ID tag | proud → id-tag | 1.5 s | "Let's sort the rest" |
| Envelope | id-tag → envelope | 1.5 s | Email |
| Linked | id-tag → linked | 2 s | Signed in (and the email link opened) |
| To the desk | linked → present | 1.5 s | Straight after |
| Guest | id-tag → present | 2 s | Continue as a guest |
| Cheer | present → cheer | 1.5 s | Pass bought |
| Wave | cheer → wave, present → wave | 1.5 s | Bought / free |
| Finale | wave → folio-full | 1.5 s | Straight after; then the trip |
| Oops, and back | proud ↔ oops | 1.5 s | An error |

Idle loops (first frame = last frame, 4 s): hello, tag, folio-open,
folio-full, reading, card, proud, id-tag, envelope, present, oops.

That's 23 transitions and 11 loops. Pilot first: **tag toss** and **folio
up** (one hand-off, one prop pick-up) plus the **tag idle**, keyed over two
stages, to prove the green keys cleanly and the joins don't show, before
the rest.

## In-app work around the films

- Workshop plate as a stage; the destination pops up from it (no pull-back).
- A film player that chains key-frame films and loops, skippable by tap.
- The departure tag: place and dates ink in, slap and swing (reusing
  `CountdownLuggageTag`), stamps for place / dates / first booking.
- The Day 1 strip the booking card flies onto.
- The folio pages as the form's and flight board's paper.
- The finale: the folio's pages into the trip screen, the stage into the
  trip's postcard.
- Destination ambience layers; haptics.

## Status, 10 October 2026

Wired into the app (`OnboardingScreen`, `TraviPlayer`) and complete: every
move between key frames has a film. The last ten were made on 10 October:
linked, envelope-linked, to-desk, cheer, wave-paid, wave-free and oops, the
present and id-tag idles, and a re-roll of the folio-open idle (the first
closed the folio mid-loop). Three more are films played backwards
(`REVERSED` in `export.py`): folio-out, envelope-back, oops-back. wave-free's
take swung the folio round to his far side and back; that detour is cut in
processing (`cut` in shots.json).

Deliberately not made, to save generations: the card idle (he holds the
card under 2 s), the envelope idle (the traveller is usually in their mail)
and the oops idle (rare). He holds the key frame there.
