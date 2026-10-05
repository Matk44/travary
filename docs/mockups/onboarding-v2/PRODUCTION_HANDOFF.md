# Tavi and the holiday theatre — production handoff

## Files and tools

The art was generated with built-in imagegen, using the same hero as the character and material reference. Exact prompts are in `PROMPTS.md`. Motion uses the existing local Scene Studio at `/Users/khairofamily/Documents/video_generator`, through its Seedance 2.0 adapter. No generator source, keys or provider configuration were changed.

The first render is `holiday-reveal-v1.mp4`: 6.04 seconds, H.264, 720 × 1280, silent. The job is `1a9de8daa7ecb193`, seed `140991`. It succeeds at character consistency, opening the lid and unfolding a simple miniature landscape. Its scenery is smaller and less detailed than the art target.

The selected refined render is `holiday-reveal-v2.mp4`: 8.04 seconds, H.264, 720 × 1280, silent. Its job is `cadb99c3a367e795`, seed `140992`. `video-request-v2.json` uses both `motion-first-frame-v1.png` and `motion-last-frame-v1.png`. The ending frame sets the intended world scale and richer paper materials. Review confirmed the world expands around Tavi and reaches the richer ending. Mid-reveal paper fan placement and facial acting need cleanup in an authored version. The clip is a film treatment; shipping interaction timing should be authored separately.

Scene Studio's cast library includes **Travary — Tavi paper suitcase v1**. Its local image is the clean opening frame. The uploaded images and videos remain in Scene Studio's library as well as the Travary project copies. The server was started on `http://localhost:3717`; if it stops, run `npm run dev` from the generator folder. `/cast` holds the reference; `/library` holds the renders.

The requests save first/last-frame filenames from this Scene Studio installation. Those names are local media references. For another installation, upload the project PNGs and replace the corresponding paths. The JSON contains no credentials.

## Character asset and rig brief

Establish one canonical Tavi turntable and parts sheet before producing many scenes. Preserve the squat carry-on silhouette, front-panel face, navy leather trim, brass corners, cream luggage tag and folded-paper hands. The lid opens backwards independently of the face. Maintain an eye-level camera and warm contact shadow.

Articulated parts should include: main body, rear-hinged lid and interior, left/right arms with paper folds, brows, eye whites and pupils, mouth poses, handle, hanging tag, left/right wheels and ground shadow. The type printed on a tag is live UI content, not part of the character texture.

Prototype these authored states:

| State | Acting | Trigger |
|---|---|---|
| Meet | Roll in, glance towards traveller, eyebrow lift | First local welcome |
| Listen | Small eye movement towards the chosen destination | Destination selection |
| Reveal | Reach for lid, open, present expanding world | Confirmed destination |
| Departure | One purposeful stamp; calendar leaf briefly sticks to hand | Dates confirmed |
| Read | Quiet attentive pose, tidy one loose paper | Import actually running |
| Check | Character rests while the review surface stays still | Draft review |
| Filed | Straighten the checked ticket, small satisfied nod | Successful save |
| Together | Extend shared folio; greet companion cases | Sharing preview |
| Recover | Return source to desk, calm helpful gesture | Failed or cancelled operation |
| Sendoff | Offer folio, small wave | Free continue or confirmed purchase |

A rig should blend between states and accept interruptions without losing the chosen trip or pending operation. No action should depend on a video completing. Avoid random perpetual bouncing: the acting communicates attention and competence.

## World asset brief

Start with Bali and one neutral travel theatre to prove the production method. Build further environments from the app's actual destination distribution and existing art packs. Suggested visual tests are a city, a coast and a family resort/theme-park environment, with licensed or original landmarks and no implied booking.

Each world needs closed/packed, unfolding and settled arrangements, plus separate foreground, middle terrain, skyline, sky and small ambient elements. Maintain a consistent character camera and a usable quiet typography area. The detailed hero is the quality target; the first video is a movement study.

The same landscape remains after free continuation. Later trip screens inherit the user's postcard, tags, folio and ticket material so the onboarding world's objects become familiar tools.

## Three interaction rules that carry the concept

**Actions physically change the scene.** Destination expands the world. Dates produce a tag. A confirmed booking becomes a filed ticket. Selecting a sharing benefit unfolds one itinerary towards companions. Text-field focus alone does not trigger a major spectacle.

**Useful information earns calm space.** The full character performance surrounds a task. Booking correction, travel dates, times, allowances and billed prices remain stable and readable. Let people interrupt the reveal, undo an input and return without repeated ceremonial delays.

**The character's warmth follows the traveller.** Tavi is equally helpful for manual entry, skipped setup, failed import, covered membership and free continuation. Purchase changes access to specific conveniences, with an explicit status; it does not purchase the character's approval.

## Motion acceptance before integration

Review every generated take for identity, eye/mouth stability, arm count, tag consistency, wheel contact and lid mechanics. Check that scenery unfolds physically and has coherent scale, rather than appearing as a background replacement. Review the beginning, transition and settled ending, then watch the whole clip for discontinuities.

For the app prototype, verify that destination/date controls respond during motion, reduced-motion uses the settled artwork, and the complete task works with large text and a screen reader. Measure first usable input, first saved booking and first opened attachment separately from film playback.

The purchase scene shows two real-price tickets and a visible free action. Keep illustrative tickets separate from a traveller's actual transport/admission documents. Successful import and purchase acting must follow real operation outcomes.
