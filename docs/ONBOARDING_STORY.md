# Travary onboarding: bring your holiday together

Discussion proposal, 5 October 2026. This builds on the approved paper-theatre art direction and suitcase performance studies. The owner's latest wording uses **Travi**, which this proposal adopts; older asset filenames and the acting guide use Tavi. Alternative characters are explorations, not a selected replacement.

**Character decision:** the owner has confirmed Travi as the main mascot and selected **C — Ribbed spinner** in **Coral**. The [suitcase shape and colour exploration](mockups/travi-suitcase-exploration-v1/README.md) records this selected design. The alternative characters below remain an exploration record; the interactive story is still a proposal for discussion.

## The story in one paragraph

You have a holiday to look forward to, and plans scattered across confirmations. Travi welcomes you into a little departure workshop and helps bring that holiday together. Choosing a place opens its world. Choosing dates gives it a departure tag. Adding one checked booking gives that world something useful to hold. The same booking becomes part of your actual day plan. Travi hands the holiday back to you, ready to keep building and, if wanted, share with your companions.

The traveller is the protagonist. Travi is the eager, capable porter for their plans. His recurring job is to turn loose pieces into something organised; his small mishaps make that job charming. The story has a purpose beyond meeting a mascot: by the end, the traveller understands how their own bookings become a usable holiday companion.

## The emotional arc

**Anticipation → personal ownership → useful proof → confidence → shared excitement.**

There are two important reveals. The destination unfolding makes the holiday feel personal. The first booking arriving in the actual day plan proves what Travary does. The purchase offer comes after that practical proof, and the sendoff works for free users too. A single saved booking is a good beginning; it does not mean every holiday task is complete.

## The story, controls and motion are one sequence

These are narrative beats within a continuous scene, not a requirement for six full screens. Native pickers, file selection and booking review can temporarily take focus. The same objects, character and scene connect the transitions.

| Beat | Copy and action | Travi and the stage | Actual outcome |
|---|---|---|---|
| Meet your porter | “Where are we off to?” Destination input is already available | Travi rolls in, brakes a little too eagerly, recovers and offers a tag | A clear holiday setup route; joining/import-first alternatives |
| Give the holiday a world | Confirm a destination; then “When do we leave?” | His lid opens; that destination unfolds around him. Selected dates become a stamped departure tag | A personal holiday draft; a real dated trip once validly saved |
| Bring a plan in | “Got a booking for me?” Select screenshot/PDF, enter manually, or postpone | He brings a small folio onto the desk in the same world. Selected paper enters it while the real import runs | A reviewable draft; no claim of a saved booking yet |
| See it come together | Check the details and confirm; “There. One less thing to juggle.” | He straightens the confirmed booking card. That SAME card moves into its date on the day rail | One real saved booking, visible in its actual day, with its source accessible |
| Bring others along | Optional group/share context | One folio unfolds towards companion cases. For solo travellers, the scene stays personal | A clear sharing preview; actual invitations use the normal covered/purchase/account flow |
| Carry it into your holiday | “You're off to a good start.” Enter the real trip | The landscape settles into the trip's postcard; Travi hands over its folio | The same destination, dates and booking remain in the product |

The workshop, folio, tag and ticket have continuing roles. They do not disappear after a beautiful cinematic opening. The suitcase world gives way to a recognisable trip postcard; the ticket becomes a recognisable booking card; the departure tag becomes a useful countdown. This is how the story carries into the actual app.

## Where the existing films fit

The current twelve-second combined cut is a review film containing two separate moments:

1. **Arrival:** starts on the first destination screen, alongside live input. It ends in an attentive pose and waits for the traveller. The film never determines when someone can type or continue.
2. **World unfolding:** begins because the traveller confirms a destination. It changes the scene into that holiday and introduces the date prompt. Date controls can be available while decorative motion settles; advancing can settle the scene immediately.

Keep a small steady **Travary** wordmark. A useful static descriptor can say “Your bookings, days and tickets together.” A flashing app title or a full-screen brand film would spend the traveller's attention before they have participated. The place they choose should cause the signature reveal.

The existing four- and eight-second shots establish character acting and the world transformation. Their timing, framing and UI space need adapting for the interactive product. Initial prototype targets are around 1–2 seconds for entry and 2–3 seconds for the main unfold, with interaction available throughout. These are design targets to assess, not researched conversion benchmarks.

**Reusable reveal proposal:** after welcoming the new arrival still, the owner raised the cost of making destination-specific videos and suggested reusing the earlier background. [Shared motion with destination stills](ONBOARDING_REVEAL.md) proposes one reveal choreography over existing matching illustrations, with Travi animated separately. Prototype whole-picture motion first; independently unfolding scenery requires additional layers. The Balinese reference stays specific to Bali, with a place-neutral fallback for unsupported destinations.

The [integration mockup](mockups/onboarding-story-v1/integrated-states-v1.png) shows two states of this same interface: destination controls with the arriving closed case, then dates within the revealed world. It uses the earlier wide suitcase as an exploration reference. The [new arrival screen](mockups/onboarding-arrival-v1/README.md) carries forward the selected coral ribbed spinner in a destination-neutral workshop, with one luggage-tag destination selector and booking-first/joining links. The owner requested still-art approval before generating its video. All typography and controls in these images are composition studies; production text and controls remain live native UI.

## How motion becomes part of doing the task

The task owns the state; motion makes the state change tangible:

- **A destination choice causes a landscape change.** The film cannot run ahead and imply an unchosen holiday. Unsupported destinations receive a beautiful neutral world rather than another place's landmarks.
- **Valid dates cause a stamped tag.** The date picker remains a reliable native control; the tag's date and countdown are live data.
- **A selected document begins a real operation.** While waiting, use a quiet character state and honest status. Duration follows the service, not an invented movie timeline.
- **A confirmed save causes a ticket reveal.** The card represents that saved booking, with the original source still accessible. It does not fabricate a valid boarding pass or admission barcode.
- **A sharing action creates its own next state.** A visual group demonstration is a preview until the real invitation succeeds.

Use three complementary forms of motion. Short videos can provide finite, repeatable scenic transformations. A controllable character/layer animation supplies reactions, waiting poses, interrupted actions and optional gestures. Native UI motion moves actual tags, booking cards and day entries. A video alone cannot supply all of that responsiveness.

Plan the stage with quiet header and control zones, keyboard space, flexible layouts and a settled state for each beat. The current film should not simply be placed full-screen under arbitrary overlays. The static mockup shows the intended visual relationship; the next prototype must prove it works at actual phone sizes and with large text.

## The pass offer belongs to the story

After the traveller has seen their first booking in a real day, Travi can open his little travel desk and ask **“Shall I help with the rest?”**

The offer extends the useful behaviour they have just experienced: Smart Import for more bookings, shared plans for companions and booking-file backup. Two paper passes express the scope clearly: **this holiday** or **holidays through the year**. Prices, renewal and benefits stay readable and motionless while being compared. The existing pricing research remains a separate discussion; this story proposal does not change store offerings.

The departure world and character remain welcoming after “Continue with free.” If someone skipped booking setup, let them continue building the holiday and introduce the offer at a relevant later action. A covered invitee enters their organiser's trip rather than buying already-covered benefits.

## Character directions

The [comparison board](mockups/onboarding-story-v1/character-directions-v1.png) places four options in the same art direction and stage lighting. These assessments are design judgements, not user-study findings.

| Character | What its body naturally lets it do | Strength | Tradeoff |
|---|---|---|---|
| Travi, suitcase | Roll in, open a holiday world, carry a folio, attach a departure tag | Immediate holiday association and broad physical acting; current lead recommendation | Keep its helpful-plan role clear so the metaphor does not become a packing checklist |
| Fold, map | Fan out routes, reveal terrain, point to a place | Strong destination and unfolding mechanics | Less immediate connection to booking-file organisation; may suggest navigation |
| Pip, paper bird | Fly between objects, carry a tag, land and react | Most different silhouette; a graceful memorable motion language | Needs a separate container for the holiday/folio; organising behaviour is less evident |
| Folio, journal | Open pages, hold bookings, sort cards, reveal days | Closest connection to the app's itinerary and travel artefacts; strongest alternate recommendation | A quieter sense of departure; must retain expressive acting when opening pages |

My recommendation is to keep Travi as the lead for now and test Folio as the serious alternative. Select one main character after comparing how each welcomes, helps with a booking and hands over a day plan. An isolated cute pose is insufficient for that decision. More characters need not become more cast members in the shipping app.

## Story shortcuts preserve the traveller's intent

Someone with a booking can start by selecting it. Confirm extracted details, use confirmed destination/dates to form the holiday, and reveal that world at the appropriate moment. Do not ask them to re-enter data that has already been checked.

Someone with unknown dates keeps an explicit draft or imports a booking to establish them; never invent dates. Someone joining a holiday receives a warm quick entry into that existing trip. Restored/returning travellers go to their actual plans. Interrupted onboarding resumes its existing objects rather than replaying the story and creating another trip.

## The next creative unit

Build a small playable prototype of **arrival → destination choice → unfolding → date selection → one booking review/save → actual day handoff**. Include an optional offer and free continuation. That will answer whether the character feels like a companion and whether the motion helps people understand the product.

With Travi's coral ribbed spinner design selected, review the interaction mapping before commissioning more shot sequences. The next film assets should be derived from real task states, framing and timing, rather than expanding the cinematic reel independently.
