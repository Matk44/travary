# App Store listing still generation

Generated 16 October 2026 with built-in ImageGen, opaque backgrounds. All generated frames are draft stills, not owner-approved artwork or upload-ready screenshots. No animation/video was generated.

Input pack: `/Users/khairofamily/Downloads/travary-app-store-screenshots-v1/`. Its prompts and plans were used as design references under the owner's request to generate a listing.

The [passport icon prompt](../travi-passport-app-icon-v1/PROMPT.md) and unchanged `assets/branding/travi_passport_source.png` establish Travi's identity. Screenshot-specific pose and placement come from the supplied layouts. The current store icon is the later close-up in `assets/branding/travary_app_icon_master.png`; it was not replaced.

## Frame 01 — exact prompt

```text
Use case: compositing / identity-preserve
Asset type: first STILL artwork for Travary's iOS App Store screenshot series, frame 01 Today. Opaque PNG, portrait 1320 x 2868 pixels, or closest output preserving the exact 9:19.5 aspect ratio.
Input image 1 is the EDIT TARGET: 01-today-green.jpg. Keep its composition and geometry exactly. This is a finish/polish edit, never a redesign.
Input image 2 is the STYLE REFERENCE: style-board.jpg. Use only its palette, type and travel-ephemera finish; do not reproduce its labels or panels.
Input image 3 is CHARACTER IDENTITY REFERENCE: travi_passport_source.png, the exact Travi from the owner's passport icon prompt. Preserve his cheerful coral-orange vertically ribbed suitcase shell, faceted handmade material, big expressive navy-and-white eyes, navy brows, open delighted smile, yellow/brass handle posts with navy grip, coral arms and five-finger waving hand, navy trim and corner guards, dark spinner wheels with yellow hubs, cream luggage tag with navy palm tree on brass chain. Preserve his identity and proportions. The icon's passport is only a character reference; do not add the passport or any other prop to this frame. Keep the existing hello/open-arm pose and placement from input 1.
Primary request: finish this layout into premium, warm, tactile App Store marketing artwork. Make the linen weave refined and softly lit, phone silver edge crisp, integration of Travi clean and on-model, with a soft contact shadow.
Background: warm linen #EFE8DC filling the entire canvas, subtle natural weave and soft daylight from upper left. Keep the faded navy postmark ring behind the phone's left edge and the coral palm-tree postmark behind its right edge subtle and mostly occluded. No extra props.
Phone invariant: one Silver iPhone in exactly the target's location, straight-on, no tilt or perspective; outer edge x130–1190 y590–2809 on a 1320x2868 canvas; screen x166–1154 y626–2773, smoothly rounded corners, thin even black bezel, same black Dynamic Island. Warm soft shadow. No Apple logo.
SCREEN MUST STAY PERFECTLY FLAT CHROMA GREEN #00B140. No UI, words, reflection, glare, gradient, texture or image in the screen. The black Dynamic Island stays black. Travi stays in front at the lower-right corner, same size as target, overlapping only the lower portion, never upper two-thirds. No character elsewhere.
Text, verbatim with exactly these line breaks and positions from target:
Your holiday,
sorted into days.
Flights, stays, tickets and tables, in order.
Headline in Source Serif 4 Bold, first line ink #1C2A47, second line coral #CF5F3C. Supporting line in Inter Medium, soft ink #56617A. Centered above phone, unchanged size and hierarchy.
Keep everything in-frame and keep the exact portrait composition. Gentle handmade gouache/papercraft sensibility, calm and premium. No glossy plastic redesign, neon, stock photos, people, badges, pricing, ratings, watermarks, extra words, extra devices or invented objects. Still image only.
```

Output: `chatgpt/01-today.png`. Original generated image retained in Codex's generated_images directory. Screen remains green for later real simulator compositing; no fictional UI was generated.

## Selected ten-frame set

Every selected file is listed in [manifest.json](manifest.json), with dimensions, hash, prompt path and explicit draft/capture/approval status. All ten are opaque RGB PNGs. ImageGen returned 850–851 px widths and 1848–1850 px heights; the aspect-ratio deviation from 1320 × 2868 is at most 0.18%. They have not yet been resized or composited for the store.

| Frame | Selected output | Exact built-in prompt |
|---|---|---|
| 01 | [Today](chatgpt/01-today.png) | [01.txt](generation-prompts/01.txt) |
| 02 | [Countdown](chatgpt/02-countdown.png) | [02.txt](generation-prompts/02.txt) |
| 03 | [Trip gaps](chatgpt/03-trip.png) | [03.txt](generation-prompts/03.txt) |
| 04 | [Smart Import](chatgpt/04-smart-import.png) | [04.txt](generation-prompts/04.txt), then [04-correction.txt](generation-prompts/04-correction.txt) |
| 05 | [Flight finder](chatgpt/05-flight.png) | [05.txt](generation-prompts/05.txt) |
| 06 | [Family](chatgpt/06-family.png) | [06.txt](generation-prompts/06.txt) |
| 07 | [Offline tickets](chatgpt/07-tickets.png) | [07.txt](generation-prompts/07.txt) |
| 08 | [Personal documents](chatgpt/08-passport.png) | [08.txt](generation-prompts/08.txt) |
| 09 | [Packing](chatgpt/09-packing.png) | [09.txt](generation-prompts/09.txt) |
| 10 | [Trips and passport wave](chatgpt/10-trips.png) | [10.txt](generation-prompts/10.txt) |

Images 02–10 use their supplied green layout as edit target, the style board as reference and a generated draft as finish reference. Linen frames use draft 01; navy frames use draft 02. Neither draft was represented as owner-approved. Frames 06, 09 and 10 additionally use the supplied envelope, proud and wave poses. Frame 10 also uses the original passport-icon source to replace the folio with the navy passport, gold globe, cream page edges and PASSPORT title.

The first frame-04 generation incorrectly used linen above the phone. It is retained as `chatgpt/04-smart-import-v1-background-drift.png`, excluded from the selected manifest. A targeted ImageGen correction restores the navy wall and cream/coral text without moving the phone or removing the pass tag.

Two supporting lines were clarified from the source pack: 07 now says “Saved bookings and tickets, on every plan.”; 09 says “One packing list. Share it with a pass.” No prices or trial offers were invented. The generated phone screens remain green; no source mockup was passed off as a current app capture.

## Verification and next step

All ten stills were visually inspected for headline/supporting text, background alternation, Travi's identity/pose, pass disclosures and phone placement. Exact pixel geometry and final compositing edges still need checking after real captures are added. The metadata fields for all three locales pass their character/byte limits; every plain-text export matches the JSON. The local review was checked in the in-app browser.

Review [the listing](../../app-store/review.html) and [capture plan](../../APP_STORE_LISTING.md). No artwork approval, motion, store upload, release or new production-feature validation is implied by this draft set.

## Captures — 17 October 2026

Frame 04's tag was re-lettered on a copy, `chatgpt/04-smart-import-tag-fixed.png`
([retag_04.py](retag_04.py)): ImageGen had clipped the comma and the "a" of
"2 free, then a pass". The original plate is unchanged; the manifest selects the copy.

Frame 11 (the home-screen widget) has its green layout,
`references/green/11-widget-green.jpg`, drawn by `layout.html` like the other ten,
and its prompt, [generation-prompts/11.txt](generation-prompts/11.txt). Its plate
is not generated yet.

The demo frames are captured from a debug demo build
(`--dart-define=TRAVARY_BACKEND=demo`) on the iPhone 17 Pro Max simulator (iOS 26.1,
1320 × 2868, light mode, English (US) so times read "8:20am"), status bar set with
`xcrun simctl status_bar … override --time "8:20"` (Wi-Fi, full bars, battery 100%,
not charging). Each went into its plate with `compose.py`; `final/` has both sizes.

| Frame | Capture | How |
|---|---|---|
| 01 | `captures/01-today.png` | Day 3 of Orlando, previewed at 8:20am. The hire car's company ("Alamo") cleared in the app's own edit form first |
| 02 | `captures/02-countdown.png` | Previewed Sat 14 Nov 8:20am: 30 days to the Lake District. Travi's first-of-the-day wave, one frame of a 40-screenshot burst |
| 07 | `captures/07-tickets.png` | The Documents tab, same morning as 01 |
| 08 | `captures/08-passport.png` | Travel documents after Face ID, three made-up documents added in the app: your passport (UK, expires 3 Mar 2027, so it shows "under 6 months after Orlando"), a "Family policy" travel insurance (12 Sep 2027) and Alex's passport (UK, 19 Aug 2031). No document numbers |

The cloud frames are captured from a debug cloud build (`flutter build ios --simulator
--debug`) on a fresh guest account (uid `CXtc0imUWrMbvQh1mzk9gKgMc3z1`, never signed in,
free plan), same simulator and status bar. Onboarding made the "Kyoto holiday" (10–16 Apr
2027); everything in it is made up.

| Frame | Capture | How |
|---|---|---|
| 04 | `captures/04-smart-import.png` | Onboarding's Smart Import on a made-up confirmation ("Lantern House Kyoto", drawn for this, added to the simulator's Photos), after allowing Google's AI on the app's consent sheet. Travi's reading pose, one frame of a 60-screenshot burst. Composed on `04-smart-import-tag-fixed.png` |
| 05 | `captures/05-flight.png` | Add a flight from the trip: QF 25 on 10 Apr 2027, found live (Sydney → Tokyo, 20:30, lands 5:25am) |
| 03 | `captures/03-trip.png` | The trip page once the hotel and flight were saved: "Stay needed 14–16 Apr" and "Flight home 16 Apr" |
| 09 | `captures/09-packing.png` | The trip's packing list: six ideas plus "Walking shoes", four ticked ("4 of 7 packed") |
| 10 | `captures/10-trips.png` | The Trips tab after adding "Lisbon" (22–29 May 2027) and "Lake District" (12–19 Jun 2027) with New trip |

Frame 10's plate has a slightly shorter phone screen than the layout (972 × 2097 at
175,624; the others are about 982 × 2142), so its capture loses a few rows top and bottom.

| Frame | Capture | How |
|---|---|---|
| 06 | `captures/06-family.png` | 18 Oct: with `tester: true` set on the guest's `users/{uid}` (by the owner) and Design tools' test plan on Plus, "Invite" made code ZYV 5GR as "Sam". Three more fresh guests ("Alex", "Mia", "Jo") joined from the iPhone 17 simulator (app reinstalled and keychain reset between them). Trip details' "Who's coming" |

All ten frames are in `final/` at 1320 × 2868 and 1206 × 2622. Left on Firebase: the
four test guests and their Kyoto, Lisbon and Lake District trips; the organiser still
has `tester: true`.
