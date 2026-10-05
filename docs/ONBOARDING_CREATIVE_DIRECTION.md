# Travary: Your holiday, unfolding

Creative reset, 4 October 2026. This replaces the visual direction and fixed chapter presentation in the initial onboarding proposal. The product audit, activation definition and pricing research in [ONBOARDING_STRATEGY.md](ONBOARDING_STRATEGY.md) remain useful. No production app code or store pricing has changed.

**Current direction, 5 October:** the owner selected **Travi, coral ribbed spinner**. [Bring your holiday together](ONBOARDING_STORY.md) develops the cohesive narrative and shows how motion fits within live onboarding controls. The [new first-screen still](mockups/onboarding-arrival-v1/README.md) awaits art-direction approval before video generation, as the owner requested. Older Tavi/vintage-case descriptions and assets below remain the creative development record; the interactive flow remains a proposal for discussion.

**Performance refinement:** [Tavi's acting guide](TAVI_PERFORMANCE.md) establishes the more enthusiastic character requested after reviewing the film: a wheeled entrance, bright attentive eyes, brief comic recovery and delighted holiday reveal. Its v3 references supersede the earlier prolonged half-lidded acting.

## Why the first concept felt generic

It organised information before inventing an experience. Each input changed some UI; little happened in the traveller's world. The destination art sat behind a familiar sequence of forms. There was no protagonist, comic timing or signature transformation someone could remember afterwards.

Travary already has an unusually coherent visual vocabulary: postcards, tickets, tags, stamps and hotel key cards. That vocabulary can become a physical world with its own character and mechanics. The creative ambition should shape the interaction from the beginning.

## The central idea

**Your holiday lives inside a little suitcase. You bring it to life.**

The traveller meets Tavi, a coral vintage carry-on with a slightly mischievous expression and a talent for organising paper. Their destination unfolds from inside its lid as a dimensional paper landscape. Their departure becomes a stamped luggage tag. Their checked booking becomes a real ticket in the actual holiday plan. Their companions join the scene.

One persistent stage changes in response to choices. Native controls can slide into the lower part of the scene as needed; the scene retains its geography and character. The storyboard depicts six narrative beats, not six mandatory screens. File selection and accurate booking review use familiar native surfaces.

The signature moment is the destination unfolding. Build and test that moment first. It should make Travary recognisable in a short clip even with its wordmark removed.

## Meet Tavi

Tavi is a working name, pending naming and brand clearance. The proposed character is a capable holiday porter who is delighted about the holiday and excellent at the paperwork. His humour comes from physical timing and small recoveries. He likes solving travel admin and takes pride in getting things into order.

- **Silhouette:** squat coral carry-on, navy trim, brass corners, cream luggage tag, folded-paper arms and little wheels. The front panel carries the face; the rear-hinged lid can open without swallowing it.
- **Performance:** bright attentive eyes, an eager entrance, brief delighted surprise, a small glance towards an object, a proud nod, an arm stretched just too far to collect a receipt. Small acting choices give him personality; avoid sustained half-lidded eyes as the default.
- **Voice:** short, useful and lightly playful. “Where are we off to?” “When do we leave?” “Paperwork. My speciality.” “There. One less thing to juggle.”
- **Role after onboarding:** the same folio, tags and ticket mechanics continue in the product. Tavi can help with the first empty day, a successful import or preparing a group invitation. It retreats while people read, correct details or retrieve a ticket quickly.

The humour comes from useful actions: a calendar leaf sticks to its hand after stamping; it neatly straightens a wonky ticket; a paper plane tangles with its handle. A small library of authored reactions will establish more character than endless random wobbling.

## The playable story

| Beat | Traveller action | The world responds | Useful result |
|---|---|---|---|
| Hello | Starts a holiday; alternatives for joining or adding a booking first | Tavi rolls onto the stage, brakes with a tiny comic recovery and greets the traveller eagerly | Establishes an inviting helper and a clear route |
| Somewhere | Chooses a destination | The case opens; layered terrain, landmarks, water and sun unfold | The destination feels personal; a draft exists |
| When | Chooses dates | Tavi stamps their real departure onto a tag; the countdown appears | A dated holiday can be saved |
| Booked | Selects an image/PDF or adds manually, checks and confirms | Tavi collects the source, then prints and files the confirmed booking | A real booking is available in its actual day |
| Together | Indicates a group or previews sharing | Companion cases arrive; one paper plan extends between them | Shows why a shared holiday helps; invitation remains optional |
| Off you go | Chooses convenience or continues free | Tavi offers two pass tickets, then sends the traveller into their holiday | A clear purchase choice and entry into the product |

**Destination interaction.** Suggestions have small poster swatches. Once a destination is selected, the unfolding begins and their live destination name appears separately from the art. A tap advances immediately; the reveal never holds up typing or navigation. Bali is the first art test. Build several recognisable environments and a beautiful neutral fallback, then expand the set around actual destination demand. Avoid inventing a local landmark for an unsupported place.

**Dates interaction.** Use a reliable date-range picker. Its selected dates become live text on the tag when the picker closes. The animation stamps once and reveals the countdown. “Dates not decided” preserves a draft and opens exploration or booking import; it needs explicit draft support in the app.

**Booking interaction.** The playful feed-and-print sequence surrounds an honest process. The document enters the folio while extraction runs. Tavi watches the machine or tidies paper in a quiet short idle. The review panel then settles; date, time, type and uncertainty remain readable. Printing happens only after the traveller confirms a saved booking. Open the attachment and show its position in the real day plan before treating onboarding as activated.

**Group interaction.** A solo traveller gets a calm personal scene; a group organiser sees the shared plan extend to companions. Extra cases represent the sharing concept, not successfully invited members. Actual invitations require the normal identity and premium steps. A covered invitee bypasses organiser setup and lands in the existing trip.

**Skip and failure interactions.** A postponed booking leaves a tidy empty folio with an obvious later action. A failed import returns the source to the desk and explains what happened. Tavi remains composed. The animation never implies a file has been saved or shared when the operation failed.

## Small interactions worth discovering

The world should invite a little play between useful actions. These are authored prototype ideas, not existing app features:

- **Lift the lid.** After choosing a destination, dragging the lid directly controls the paper world's unfolding. Tavi's eyes follow the moving lid. A tap on “Make it mine” performs the same reveal; no gesture is compulsory. This requires a controllable rig/layer animation rather than an uninterruptible video.
- **Flip the departure tag.** One side shows the real departure date; a tap or short flick turns it over to show the countdown. It feels like a little travel souvenir and remains useful after onboarding.
- **Send the paper plane.** A discretionary tap sends it across the sky. Tavi ducks slightly, then catches it by the tail. Keep this short, discoverable and irrelevant to completion, with a static equivalent under Reduce Motion.
- **Watch the world respond.** Preview supported destination swatches before committing. Terrain and props change within the same stage; Tavi glances towards the new landscape. Unsupported destinations use the neutral world rather than borrowing another place's imagery.

The first prototype should include the lid and tag. Add the plane once the character's timing works. Keep these optional moments away from extracted booking details and purchase decisions. They provide room for personality without adding required setup work.

## The commercial scene

After useful proof, Tavi opens a small travel desk in the same world. Headline: **“Want a hand with the holiday admin?”** Supporting copy: **“Less typing. Shared plans. Backed-up booking files.”**

Two stable, readable ticket options carry live prices and clear scope:

- **Holiday Pass — $14.99 once.** This holiday, through seven days after its end. Smart Import, family sharing for up to six people including the organiser, and booking-file backup, subject to the shipped entitlement policy.
- **Annual — $39.99 per year.** The same convenience across holidays during the subscription. Display renewal and the actual billed total clearly. $39.99 is the current proposal to test against $29.99; it is not a changed store offering.

For a first single holiday, initially select Holiday Pass and keep annual visible. A repeat organiser can receive an annual recommendation. At these prices, annual costs less than three separate passes; it does not save money on two. For $29.99 annual, two passes total $29.98. Do not make an unsupported savings claim.

The free action reads **“Continue with free.”** Tavi gives the same warm sendoff, and the destination world stays beautiful. Smart Import's existing three free uses explain how the first real booking can demonstrate convenience. Family sharing is demonstrated before purchase without falsely claiming that an invitation has already been sent.

Payment is for less admin and broader convenience. The character, initial destination reveal, manual planning and access to existing local tickets remain part of the free experience. Covered invitees receive no offer for already covered benefits. Never sell flight alerts, widgets or other unfinished features in this scene.

## Art and motion production

The supplied art is a visual target: textured cut paper, warm physical lighting, editorial travel-poster colours and visibly crafted objects. Production controls, booking details and prices remain live UI text. The rendered title in the hero is a composition reference only.

Use three complementary production methods:

1. **Generated stills** establish Tavi, environments, key poses and the transformation's start/end compositions. Maintain a reference bible covering the handle, lid hinge, eyes, tag and colours.
2. **Scene Studio video** explores the big magical reveal and cinematic physical timing. The local generator is configured with Seedance 2.0 and first/last-frame input. The initial test is a silent six-second, 720p portrait shot; the refined request uses an eight-second shot with a more expansive ending frame. Requests and prompts are saved with the artwork. Video provides a motion reference and may supply carefully selected decorative clips after device testing.
3. **Articulated character and native interaction** handle buttons, selections, stamps, tickets and reactive acting. Prototype paper-layer transforms in Flutter; evaluate an authored rig such as Rive when Tavi needs pose blending and reliable state transitions. There is enough character motion here to justify evaluating a rig rather than deciding against it in advance.

The shipping experience should respond at the user's pace. Separate the reveal's anticipation, unfolding and settled states so an input or navigation change can advance safely. Keep the complete video as a creative reference; a six-second render is not a mandatory six-second wait. A short optional “play again” moment can preserve the spectacle for people who enjoy it.

Author sound as a small optional layer: wheel tick, lid clasp, paper flutter, soft stamp. Use independent effects rather than generated speech; sound is off initially and haptics are restrained. During booking review and checkout, hold the scene still enough for comfortable reading. Reduce Motion uses the same beautiful settled art with a brief dissolve and identical controls.

## Shot production brief

| Shot | Staging and action | Starting production target |
|---|---|---|
| Arrival | Tavi rolls in, catches the dangling plane, raises one eyebrow | 1–2 seconds, skippable entry |
| Holiday unfolds | Lid opens backwards; terrain fans up, palms open, sun settles | 4–8-second film test; tune interactive timing afterwards |
| Departure stamp | Close view of tag; one stamp and calendar-leaf gag | Around 1 second; native dates |
| First booking | Paper enters folio; after confirmation a ticket prints and seats in its day | Separate waiting loop and successful save action |
| Travelling together | Companion cases gather around one unfolding itinerary | 1–2-second optional preview |
| Sendoff | Character straightens the folio and offers it to the traveller | Under 1 second after the user's decision |

For every generated shot, keep Tavi's canonical reference, palette and paper material consistent. Prefer locked framing and one readable action. Give the video model artwork without text. Never generate a film containing a user's booking details, payment options or permission controls. Review eye placement, hands, lid mechanics and identity drift before selecting a clip.

## Why this may work, and what to test

The creative application is an inference from the existing research, not evidence of a guaranteed conversion gain. Anticipation research suggests a useful emotional opportunity; visualising the person's destination gives that anticipation something concrete. Autonomy is expressed through meaningful choices and easy exits. Competence comes from a correctly saved booking. Relatedness becomes tangible when the same plan reaches companions. The character makes these actions coherent and memorable.

The first study should ask organisers to do a real task with the art-led prototype: create a holiday and add a booking. Watch where attention goes, whether they understand what is saved, whether the acting feels charming or juvenile, and whether they recall the core promise the next day. Ask what made the holiday feel personal. Test the closing offer for comprehension of scope, renewal and group coverage.

Use activation, time to usable ticket, errors, skips and later return visits alongside purchase contribution. A short enthusiastic reaction to a film is useful creative feedback, but insufficient evidence that the onboarding works. Keep pricing experiments separate from the first creative treatment test.

## Deliverables and next build

The current selected performance is [the v3 entrance and reveal](mockups/onboarding-v3/tavi-arrival-and-reveal-v1.mp4). It adds the requested wheeled arrival and a brighter, more enthusiastic face throughout. [V3 prompts and requests](mockups/onboarding-v3/PROMPTS.md) preserve the exact generation instructions; [Tavi's acting guide](TAVI_PERFORMANCE.md) defines the behaviour for the interactive app. The v2 artwork and films below remain the original art-direction and motion-development record.

- [Hero](mockups/onboarding-v2/hero-v1.png): full visual target with Tavi and the destination world.
- [Storyboard](mockups/onboarding-v2/storyboard-v1.png): six narrative beats in the continuous paper theatre.
- [Motion first frame](mockups/onboarding-v2/motion-first-frame-v1.png): clean text-free reference for the opening transformation.
- [Motion final frame](mockups/onboarding-v2/motion-last-frame-v1.png): the intended scale and richness of the completed holiday world.
- [First motion study](mockups/onboarding-v2/holiday-reveal-v1.mp4): six-second Seedance render. Character identity and lid mechanics work; the miniature landscape is simpler and smaller than the hero target. Use it as a motion study rather than final production art.
- [Refined motion study](mockups/onboarding-v2/holiday-reveal-v2.mp4): completed eight-second render using the clean first/last frames. The world now expands around the character with much richer scenery. It is the selected motion treatment; paper fan placement and facial acting still need authored cleanup for production.
- [Prompts](mockups/onboarding-v2/PROMPTS.md): exact built-in imagegen prompts and Scene Studio motion prompt.
- [Video request](mockups/onboarding-v2/video-request-v1.json): render settings and local first-frame reference.
- [Refined video request](mockups/onboarding-v2/video-request-v2.json): first/last-frame setup for the more expansive reveal.
- [Production handoff](mockups/onboarding-v2/PRODUCTION_HANDOFF.md): character states, rig parts, world layers and the Scene Studio workflow.

Next build: a playable single-world prototype with the reveal, live destination/date controls, one real booking path and the closing pass choice. Establish Tavi's performance and the personal transformation first, then integrate production imports, purchases and resumable state. Preserve the existing product's travel artefacts so the holiday folio handed over in onboarding is recognisable in the app.
