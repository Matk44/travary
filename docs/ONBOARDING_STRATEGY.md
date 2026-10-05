# Travary onboarding and monetisation strategy

Research and product review: 4 October 2026. Prices below are USD, confirmed by the owner. This is a proposal for review; it does not change the app's prices or existing product decisions.

**Creative direction updated:** [Your holiday, unfolding](ONBOARDING_CREATIVE_DIRECTION.md) supersedes this document's original visual treatment and fixed chapter presentation. Use its character-led paper theatre, generated art and motion brief. The product audit, research, activation logic and pricing analysis below remain the functional foundation.

## Recommendation

Build onboarding around **“Watch your holiday take shape.”** Someone chooses their holiday, adds one real booking, checks the details, and sees that booking become a beautiful, usable ticket in their actual day plan. Their destination postcard and countdown make the upcoming experience tangible. Then offer to make the holiday easier for the whole group.

The activation goal is **one real booking saved, its day plan viewed, and its attachment opened when present**. Creating an empty trip is a useful beginning, but insufficient proof of Travary's value. A sample demonstration is a separate outcome, never counted as real activation.

Start with a pricing hypothesis of **Holiday Pass $14.99 once / Travary Plus $39.99 per year**. Test the annual price against $29.99 after the flow works. $14.99 is plausible for a group holiday organiser, but willingness to pay has not been demonstrated. Keep the current $7.99 / $34.99 configuration available as a baseline; change store offerings only after validation.

The functional progression is **Your holiday → First booking → Your day → Make it effortless**. Present it through the continuous character-led scene in the updated creative direction; it is not a requirement for four screens. Group preferences and commercial steps are optional. Aim for roughly 60–120 seconds of active setup for someone with a booking at hand, excluding file retrieval and variable import latency. This is a design target, not a research benchmark or a promise to users.

## What Travary actually sells

Travary is a holiday organiser and companion. It takes bookings the traveller already made and makes them useful throughout the holiday. It is especially well suited to family resort and theme-park trips, where one organiser carries the admin for several travellers.

| Layer | What the traveller gets | Role in onboarding |
|---|---|---|
| Emotional | Anticipation, a holiday that feels real, pleasure in seeing their own plans | Destination postcard, luggage tag, meaningful ticket reveal |
| Practical | Today's plan, bookings in time order, tickets easy to reach | Show the real first booking on its date; open the original attachment |
| Paid convenience | Less typing, shared plans and tickets, ticket backup | Demonstrate the relevant benefit immediately before its purchase decision |

The organiser buys reduced admin and confidence that the group can find what it needs. Other travellers should have a fast invitation path and inherit the trip's premium access when covered. A frequent organiser buys convenience across several holidays.

Keep the free product credible: unlimited manual bookings and trips, Today, locally available tickets, and personal travel documents. The current policy gives three lifetime free Smart Imports. The distinctive artwork should remain part of the experience; monetise utility rather than withholding the initial delight.

### Product audit and constraints

Reviewed `docs/PRODUCT_PLAN.md`, `CLAUDE.md`, `lib/app/app.dart`, `lib/app/bootstrap.dart`, `lib/domain/pricing.dart`, `lib/domain/premium.dart`, `lib/logic/access.dart`, `lib/features/premium/paywall_screen.dart`, `lib/features/trips/trip_details_sheet.dart`, `lib/features/import/smart_import_screen.dart`, sharing, purchase and analytics services, and the current art references. This is a code and design audit, not a live-device usability test.

- Existing building blocks: guest access; manual trip creation; trips formed from bookings; destination detection; destination art packs; animated countdown postcard; Smart Import with editable drafts; family invitations; ticket backup and offline downloads; shared premium policy; contextual paywall.
- The current new-trip form requires dates. An honest “dates not decided” path needs a lightweight draft or sample exploration; do not silently invent dates or route an undated draft into the pass checkout.
- Smart Import currently accepts images and PDFs. It is not a general inbox integration or email-forwarding flow. Do not advertise connecting Gmail or forwarding confirmations during v1 onboarding.
- One file can produce several booking drafts. Review all extracted bookings and dates before saving. Do not treat “one import” and “one booking” as interchangeable.
- Purchases currently use `TestPurchaseService`; production billing, durable entitlements, trip stamping and server-side allowance enforcement remain launch dependencies. Analytics currently prints in debug.
- Cloud bootstrap currently awaits anonymous sign-in before the main app opens. First-run startup latency and failure need attention: show a local welcome/draft or an understandable retry state while authentication completes. A local draft is not a cloud-saved trip; Smart Import still requires the network.
- The release flag sells Smart Import, family sharing and ticket backup. Flight status work is present/in progress, but `flightAlerts.released` is false. A live status lookup is distinct from a push alert. Exclude flight alerts, Live Activities, widgets and leave-by reminders from paid claims until their complete user flows ship.
- Public read-only share links appear in the product plan but were not found as a released end-to-end sharing flow in the audited implementation. Do not make onboarding depend on them.
- Passports, visas and insurance remain personal documents on the phone, behind its lock. Keep them out of first-run onboarding, cloud import, group previews and purchase demonstrations.
- Current default prices are $7.99 per trip and $34.99/year. The paywall preselects annual and uses a “Best value” badge. Replace the unconditional recommendation with wording appropriate to the context, such as “For all your holidays.”

## Evidence and what it supports

These sources inform the design; none establishes Travary's optimal price, screen count or conversion uplift. Research findings, platform guidance and product hypotheses have different levels of certainty.

| Evidence | Finding and limitation | Application to Travary |
|---|---|---|
| [Kumar, Killingsworth & Gilovich, 2014](https://pubmed.ncbi.nlm.nih.gov/25147143/) | Four studies found greater enjoyment in anticipating experiences than material purchases. They did not test app onboarding or subscription conversion. | Make the traveller's own destination, dates and upcoming experiences visible early. |
| [Nawijn et al., 2010](https://pmc.ncbi.nlm.nih.gov/articles/PMC2837207/) | A pre/post study of 1,530 Dutch participants associated vacationing with higher pre-trip happiness; anticipation was a possible explanation. It is not causal evidence that a countdown increases happiness. | Treat anticipation as a plausible source of value; test whether the postcard earns return visits. |
| [Ryan & Deci, 2000](https://selfdeterminationtheory.org/SDT/documents/2000_RyanDeci_SDT.pdf) | Self-determination theory identifies autonomy, competence and relatedness as important motivational needs. It is a broad framework, not an app conversion formula. | Allow skipping; make one booking easy to complete; show how the plan helps companions. |
| [Norton, Mochon & Ariely, 2012](https://dash.harvard.edu/entities/publication/73120378-ce76-6bd4-e053-0100007fdf3b) | Experiments found higher valuation of self-made objects when construction succeeded. Failure/completion boundaries matter; the tasks were physical products. | Let people create a useful personal holiday artefact with minimal effort. Do not add labour just to manufacture investment. |
| [Nunes & Drèze, 2006](https://doi.org/10.1086/500480) | Endowed progress affected persistence in goal completion, including a loyalty-program setting. This does not validate fake onboarding completion percentages. | Show genuine milestones earned by destination choice and a confirmed booking. |
| [Scheibehenne et al., 2010](https://doi.org/10.1086/651235) and [Chernev et al., 2015](https://myscp.onlinelibrary.wiley.com/doi/full/10.1016/j.jcps.2014.08.002) | Choice overload is conditional. An earlier meta-analysis found a near-zero average effect; the later analysis identified complexity, uncertainty and decision difficulty as moderators. | Make the two purchase options easy to compare. Avoid the simplistic claim that fewer choices always convert better. |
| [Sundararajan & Adesope, 2020](https://link.springer.com/article/10.1007/s10648-020-09522-4) | A meta-analysis found irrelevant interesting details can hinder learning. Its context was learning material, not holiday apps. | As a design inference, concentrate effects on the action and its result; avoid distractions around date review and prices. |
| [Apple onboarding guidance](https://developer.apple.com/design/human-interface-guidelines/onboarding?changes=_7) | Recommends interactive, brief, optional onboarding, deferred setup, and letting people experience value before purchase prompts. Platform guidance, not a controlled conversion study. | Teach by adding a booking and opening a ticket; avoid a feature slideshow or mandatory account creation. |
| [Apple motion guidance](https://developer.apple.com/design/human-interface-guidelines/motion?changes=l_9_3) | Recommends purposeful, brief, optional, cancellable motion. | Give each effect a job; respect Reduce Motion and allow interaction before animations finish. |
| [RevenueCat, State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps) | Reports 10.7% versus 2.1% download-to-paid conversion for hard-paywall versus freemium apps, and 28.2% of Travel conversions after week six. These are observational app cohorts, include differing products/trials, and do not establish causality. | Do not assume day zero is the only buying window or transplant the hard-paywall comparison into Travary. Measure later contextual conversion as well as onboarding. |

Avoid “dopamine hacks,” invented readiness scores, manufactured scarcity and generic loss-aversion scripts. Travary can use anticipation, agency and competence while giving people an honest choice.

## The onboarding experience

### Entry paths

Use one welcoming screen with a dominant **“Set up my holiday”** action and concise alternatives:

- **“Already have a booking? Add it first.”** File selection and review can create the trip automatically. Do not ask the traveller to re-enter information already read from their booking.
- **“Joining a holiday?”** Enter the invite code; land in that trip. Skip organiser setup and suppress the purchase prompt when the organiser already covers it.
- **“Have a look around.”** Clearly labelled sample, isolated from real data and excluded from activation metrics.

Restored accounts and returning guests with trips should enter their actual home screen. If onboarding was interrupted, offer to continue the existing setup without duplicating a trip. A member already travelling should get their tickets immediately.

### Chapter 1: Your holiday

**Headline:** “Where are you off to?”

One destination/name field, a date-range picker, and an optional compact “Who are you travelling with?” choice: solo, partner, family, friends. Ask for no names, contacts, ages, budget or travel personality. Default artwork and theme intelligently; offer later editing rather than another styling decision.

As a recognised destination is confirmed, a postcard slides into place. Choosing dates attaches the luggage tag and produces a real countdown. Unknown destinations use the existing neutral postcard. Generic art must never imply a destination we have not verified.

Save a real dated trip before continuing. If dates are unknown, preserve a local draft and offer to explore a sample or import a booking; do not force a date guess. The draft is not a paid-pass candidate.

### Chapter 2: First booking

**Headline:** “Let's bring your first booking in.”

Primary: screenshot/PDF. Secondary: add manually. Tertiary: do this later. Explain the free allowance without turning the screen into a quota warning: “Your first 3 Smart Imports are free.”

The device picker should let someone select a specific file without requesting broad photo-library, inbox, contacts or location access. Show the chosen document entering the holiday folio while it is read. Show honest status, not made-up percentages or simulated completed stages. If it is slow, offer to continue setup and return to the result where supported; otherwise preserve the file and offer a clear exit/manual path. Do not discard a result on navigating back.

Present a concise review of the extracted booking with date, local time, destination, booking type and uncertain fields prominent. Advanced fields can remain optional. Never imply a confirmation PDF is necessarily a boarding pass or valid admission barcode. Preserve the original source as an attachment and ask the traveller to check it.

After confirmation, the booking becomes a Travary ticket and slots into its date. **Copy:** “Added to your holiday.” Count the free use once per successful extraction under the current policy, not on file selection or network failure; deduplicate retries. Decide explicitly whether a successfully extracted but abandoned review consumes a use—the current implementation does.

### Chapter 3: Your day

**Headline:** “Here's how [destination] is taking shape.”

Show the actual booking day using the existing Today/cards system. If it is not the first holiday day, label the actual date; never invent a Day 1 morning itinerary. A trip with one hotel booking gets that hotel booking, not a fabricated flight, restaurant or attraction.

Give one task: **“Open your booking”**, or **“Show your ticket”** when an attachment is present. This is the proof moment. The traveller has converted a scattered file into something they can use. Then return to the destination countdown. It is okay to have only one booking; avoid saying the whole holiday is ready.

If the booking step was skipped, show the postcard and the honest message **“Your holiday is started. Add a booking when you're ready.”** Offer adding a booking as the next action; suppress the automatic commercial reveal for this path.

### Chapter 4: Make it effortless

After successful real activation, test a single dismissible offer. It can arrive from a small invitation on the success screen or as a closing offer in the experiment described below.

For family/friends: **“Less holiday admin. More holiday.”** Show the traveller's existing booking beside a group-plan illustration, labelled as a preview until an invite is accepted. Benefits: imports instead of typing; the plan and tickets on the group's phones; backed-up booking files.

For solo travel: **“Keep the bookings coming.”** Emphasise Smart Import and backup. Do not require a family preview to sell a solo traveller a pass.

Display **Holiday Pass** and **Travary Plus** together with the total prices, scope and renewal status. Keep **“Continue free”** visible. Upon dismissal, land in the real home/countdown with the saved work intact.

After a confirmed purchase, stamp the purchased entitlement, then perform the action that opened the paywall: invite flow, next import or backup. A cancellation returns to the same state. A delayed entitlement shows “Confirming your purchase” with restore/support paths; do not celebrate an unverified payment or assert no charge unless the store confirms that.

### Accounts and permissions

Keep guest setup. Offer Apple/Google sign-in when someone wants continuity across phones or begins sharing/backup. Explain the concrete benefit and preserve their trip on linking. Purchasing should work through store identity where supported; never make a redundant registration form part of checkout.

Request notification permission when someone turns on a shipped notification feature, with an example of the actual notification. Do not request notifications simply because onboarding ended or premium was purchased. [Android's guidance](https://developer.android.com/develop/ui/compose/notifications/notification-permission) likewise recommends asking in the context of the feature. The current alerts release state makes this a later step, not a launch prerequisite for onboarding.

## Motion and art direction

The initial treatment below is retained as an implementation reference. Its restrained postcard choreography has been superseded by [the Tavi creative brief](ONBOARDING_CREATIVE_DIRECTION.md), including a richer destination transformation and an articulated character. Functional accessibility and honest operation status still apply.

The visual language is a **departure desk**: linen, printed postcards, paper tickets, luggage tags, stamps and a holiday folio. Reuse Travary's art and card shells so the onboarding reveal becomes the real product the traveller lands in.

| Moment | Motion concept | Proposed starting duration | Meaning |
|---|---|---|---|
| Destination confirmed | Postcard lifts onto the desk | 350–500 ms | This is your holiday |
| Dates selected | Tag attaches with one brief settling movement | 450–700 ms | The holiday now has dates |
| Import in progress | Source file moves into a folio; quiet ongoing status | Entry 200–350 ms | Your booking is being read |
| Booking confirmed | Ticket prints/slides out and receives one stamp | 500–800 ms | Your checked booking is saved |
| Day-plan reveal | Same ticket moves into its date on the time rail | 350–550 ms | This is where to find it |
| Group benefit preview | Existing ticket appears on companion phone silhouettes | 300–450 ms | Shared trip access, clearly a preview |
| Purchase confirmed | One entitlement stamp | 250–400 ms | The selected plan is active |

These durations are design starting points. Validate them on device. Compose effects so the core flow remains usable immediately and a rapid tap can advance without waiting. The existing countdown entry is 2.2 seconds; shorten or interrupt it for onboarding rather than copying its full duration into every chapter.

Use at most one main animated object at a time. Dates, extracted details, corrections and price choices should settle completely while being read. Sound is off by default; optional light haptics mark save and selection. No looping confetti, background fireworks, tilt requirements, camera sweeps, mandatory drags, or flight-map interludes.

Reduce Motion removes swings, parallax and object travel; use a brief opacity change or instant state. Keep identical functionality and milestones. Provide visible button equivalents for every gesture, screen-reader descriptions, sufficient text contrast and layouts that grow with large text. Never bake booking text or pricing into raster artwork.

For Flutter, use existing raster shells with live text and native transforms/opacity/clip animations for controls and travel artefacts. The revised Tavi concept needs articulated character acting: evaluate a rig and compare it with layered paper animation in a prototype. Use generated video to establish the signature reveal's art and timing. Bundle the neutral art needed for first run; destination packs can arrive in the background and must not block setup.

## Paywall strategy

Sell the next useful step. The first offer follows proof of value; later offers appear on a premium action. Respect the existing decision against free trials.

| Context | Offer message | Recommendation |
|---|---|---|
| Activated organiser, one holiday | “Make [holiday] easier for everyone” | Holiday Pass initially selected; annual alternative clearly visible |
| Family invite | “The plan and tickets on everyone's phone” | Return to the invite flow after purchase; one payer covers up to six including organiser |
| Fourth Smart Import | “Add the rest without the typing” | State that the three free imports were used; retain manual entry |
| Ticket backup | “Back up this holiday's booking files” | Separate local offline access from cloud recovery; never imply free tickets are unsafe to open |
| Second holiday or repeated paid-pass intent | “Plus covers every holiday this year” | Annual recommendation; explain the actual price difference |
| Invited covered member | “Your organiser has covered this holiday” | No upsell for already covered benefits |
| Skipped import / sample only / unfinished setup | Useful next setup action | No automatic closing paywall |

Allow only one unsolicited closing offer during initial setup. After “Continue free,” use explicit premium actions for the rest of that session. A trip preparation screen can later offer an upgrade, but do not create a hard paywall when opening tickets, during the holiday, or because a holiday deadline is approaching.

Replace the proposed numerical “Trip Readiness” score with factual statuses: booking added, ticket downloaded on this device, invitation accepted, file backed up. Do not claim “100% ready” from sparse bookings; do not imply passport or travel-rule readiness. Payment is not completion of holiday preparation.

### Example commercial screen

**Less holiday admin. More holiday.**

Keep adding bookings without the typing. Give your group the plan and booking files on their phones. Back up this holiday's tickets.

**Holiday Pass — $14.99 once**

For [holiday]. Up to 6 travellers, including you. From purchase through [trip end + 7 days]. No renewal.

**Travary Plus — $39.99/year**

The same benefits for all your holidays while your membership is active. Up to 6 travellers on each covered trip. Billed $39.99 today; renews annually unless cancelled.

Primary button reflects the selected plan and total charge. Secondary: **Continue free**. Restore purchases, Terms and Privacy are easy to find. If a holiday has no dates, show only the applicable annual option or defer the commercial step.

At $39.99/year, do not claim annual saves money at two holidays; two passes total $29.98. Annual first becomes cheaper than buying separate $14.99 passes at three holidays. Use “For all your holidays” rather than an unconditional “Best value.” For subscriptions, [Apple's presentation guidance](https://developer.apple.com/app-store/subscriptions/) calls for the total billed amount to be clear; monthly equivalents can be secondary context.

## Pricing analysis

### Market references checked on 4 October 2026

| Product | Public reference | Implication |
|---|---|---|
| [TripIt Pro](https://www.tripit.com/web/pro/pricing) | Public web price $49/year; free tier already organises/imports itineraries and shares plans | Travary cannot sell “organised bookings” as inherently premium |
| [Tripsy Pro](https://tripsy.app/pro) | Public web one-year option $59, shareable with family | Paid family convenience has competition; Travary's design and group workflow must earn the choice |
| [Wanderlog US App Store](https://apps.apple.com/us/app/wanderlog-travel-planner/id1476732439) | Multiple annual IAP listings including $39.99, $49.99 and $59.99; these listings do not identify which offering every new user receives | Supports a broad annual price reference, not one definitive current price |

The public web prices and US store listings are reference points; app-store country, offer and channel can differ. These are broader and more mature products, not matched willingness-to-pay evidence for Travary. [Wanderlog describes free collaboration](https://wanderlog.com/blog/2024/09/12/the-19-best-travel-planning-apps-for-every-type-of-traveler-2/). [Tripsy also supports differentiated guest roles](https://tripsy.app/) and [browser itinerary viewing for Android users](https://tripsy.app/android), although it says a native Android app is not yet available. Update the product plan's broad “nobody does this” assertions: the stronger proposition is a beautiful, focused holiday companion across native iOS and Android.

### The relationship between the two plans

| Price pair | Annual/pass ratio | First trip count at which annual is cheaper | Strategic role |
|---|---:|---:|---|
| Current $7.99 / $34.99 | 4.38× | 5 | Low-friction pass; annual for frequent use |
| Proposed $14.99 / $29.99 | 2.00× | 3, with two passes only $0.01 cheaper | Very strong near-two-pass annual anchor |
| Recommended test $14.99 / $39.99 | 2.67× | 3 | More annual revenue; clear one-holiday role for pass |
| Later test $14.99 / $49.99 | 3.33× | 4 | Requires stronger repeated-use value and confidence |

$29.99 annual is a legitimate option if it materially increases paid organiser adoption or renewal. I would not make it the untested ceiling. Start by testing $39.99 against it. Keep $49.99 for later evidence and a stronger released product. Avoid monthly, weekly or lifetime offers in the initial onboarding; the holiday pass already serves episodic use.

At unchanged plan mix and costs, $39.99 can retain approximately 75% of $29.99's buyer conversion and produce the same gross revenue per eligible organiser. Likewise $14.99 needs about 53% of $7.99's pass conversion to match gross pass revenue. These arithmetic thresholds exclude refunds, taxes, fees, usage costs, annual/pass cannibalisation and renewal; they are not forecasts.

Measure **net contribution per eligible organiser**, using actual store proceeds less refunds and attributable import/storage/notification costs, as well as paid activation and group participation. AI already has a daily server cap; do not promise literal unlimited usage without an explicit fair-use policy consistent with the service.

### Pass-to-annual upgrade

Make a pass feel like a safe first commitment. A later upgrade can recognise the pass purchase, particularly when the organiser creates a second holiday. Explore a first-year annual offer equivalent to crediting $14.99, subject to the actual store/RevenueCat implementation. Do not promise a cash credit or dynamic subtraction from a store price before it exists. Show the real offer price and subsequent renewal price.

Defer this incentive from v1 if implementing it would delay reliable billing. A clear pass and annual choice is more valuable than a complicated upgrade promotion.

## Measurement and testing

### Funnel

Record: onboarding started → route chosen → dated trip created (if needed) → file selected/manual entry → import returned → draft reviewed → real booking saved → day viewed → attachment opened (if present) → premium intent/offer shown → plan selected → store purchase confirmed → entitlement active → requested action completed.

Keep sample exploration, empty-trip creation and real activation as separate metrics. Identify organiser and invited-member paths. Use coarse lead-time buckets and group type; do not send raw destination/title, file names, ticket contents, references, traveller names, document numbers or invitation codes to analytics. Reconcile purchases with the server to deduplicate retries and restored transactions.

Primary user outcome: real booking activation. Primary commercial outcome: net contribution per eligible organiser over a prespecified observation window. Supporting outcomes: time to first saved booking; import correction/abandonment; attachment retrieval; invite acceptance; paying-organiser conversion; plan mix; refunds; entitlement failures; return use relative to departure date.

A traveller leaving after setup may be behaving normally if their holiday is months away. Evaluate returns and ticket use around trip dates, not only generic daily retention. Preserve 60–90-day commercial observation where feasible, given travel's buying lag; do not declare a revenue winner solely from onboarding checkout taps.

### Sequence

1. **Qualitative usability first:** Recruit roughly 6–8 target organisers and 3–4 invited travellers with real upcoming holidays, including mixed-phone groups and at least some accessibility needs. These are formative sessions, not a statistical validation sample. Observe completing one booking, identifying the free option, understanding pass scope/annual renewal, and finding the attachment again.
2. **Resolve import friction:** Check where people source their files, what fields they correct, and whether the reveal helps them understand the day. Compare the postcard-first route and booking-first shortcut in sessions.
3. **Paywall placement experiment:** A: closing dismissible offer after real activation. B: no automatic closing offer; contextual premium intent only. Prices and creative held constant. Randomise at organiser/trip ownership level, exclude inherited-premium members, and retain assignments on resume.
4. **Annual price experiment:** With placement fixed, compare $14.99 pass + $29.99 annual versus $14.99 pass + $39.99 annual. Use store-supported offerings and stable experiment IDs.
5. **Pass price experiment:** If needed, test $12.99 versus $14.99 at the chosen annual price; use the existing $7.99 baseline when the question is whether the larger increase pays off. Avoid changing prices, motion and timing simultaneously.
6. **Motion refinement:** Compare a restrained treatment with the full purposeful reveal, while respecting the user's system motion setting. Track completion, delay, comprehension and crashes—not “wow” reactions alone.

Calculate sample requirements from observed baseline conversion, variance in contribution and the smallest worthwhile improvement. Predefine the analysis window and stopping rule. Low traffic may support qualitative decisions and wide uncertainty intervals rather than a confident A/B winner.

Guardrails: preserved ticket access; no duplicate trips or charges; import accuracy/correction burden; refunds; purchase failures; accessibility task completion; latency/jank; free activation and invitation acceptance. Do not improve checkout conversion by degrading those outcomes.

## Production plan

### Phase A: Storyboard and clickable concept

Use the new creative brief, hero, six-beat storyboard and Scene Studio motion test as the visual starting point. Produce a playable continuous scene with holiday setup, booking-first shortcut, covered invite path, day reveal, both commercial options, and failure/skip states. The original four-chapter interactive concept is superseded. Review the new experience with real organisers before building the full destination and character animation library.

### Phase B: Functional onboarding

Add `features/onboarding/` and a resumable onboarding state/controller, with a persisted version, route, draft, created trip ID, activation state and closing-offer dismissal. Keep it separate from `TravelStore`, `PremiumStore` and the pure access policy. Reuse existing trip creation, import review, booking cards, artwork and paywall gates.

Bootstrap should route based on restored trips/membership and persisted completion. Persist a created trip before transition; retries and restarts must be idempotent. Add a simple unknown-dates draft if included at launch, with explicit conversion into a real trip when dates arrive. Clear and merge onboarding state correctly when a guest links an account.

Make first-run welcome content and draft entry independent of remote art downloads and classification. If anonymous authentication has not completed, preserve the draft locally and make the cloud save/retry state explicit. Do not fake a saved trip, an import result or premium eligibility while waiting for the backend.

Avoid a new generic questionnaire engine or duplicated booking forms. Do not fabricate bookings to complete the success screen. Save the currently selected trip through the import and purchase path.

### Phase C: Billing and claims

Replace `TestPurchaseService` with production purchases. Use actual localised store prices, not launch defaults, to initiate checkout. Unavailable offers get a retry/free path. Persist repeatable Holiday Pass grants against their purchased trip IDs; choose appropriate repeat-purchase store products and implement restore/recovery mapping. Verify entitlements server-side, stamp shared trips, and enforce free import allowances there.

Specify how altered dates, merged trips, subscription expiry during an active holiday, refunds and group membership changes affect paid grants. Keep the simple pass promise: active from purchase through the covered holiday plus seven days. Avoid a premium grant silently moving to an unrelated trip, or endlessly extending through date edits. Preserve owned bookings and downloaded attachments when premium expires.

Add Terms/Privacy, confirmed annual renewal copy, actual restore behaviour, pending-payment states, deduplicated analytics and a way to disable the closing offer remotely. Avoid release-only claims based on debug previews.

### Phase D: Motion polish and device verification

Use the duration proposals as initial values. Verify on a lower-end Android phone and an iPhone, in release/profile builds, with large text, Reduce Motion, keyboard/screen reader and slow/offline networks. Test first-run art availability and memory use. Make motion cancellable without losing an operation or allowing duplicate save/purchase actions.

### Acceptance criteria

- A traveller can reach one real booking and reopen its attachment without an account or payment.
- Booking-first does not demand duplicate destination/date entry.
- Invited travellers reach an existing covered trip without an irrelevant upsell.
- Skips, back navigation, app termination and account linking preserve completed work.
- Imported local times and uncertain fields are checked before saving.
- Prices and scope are understood; annual renewal and Continue free are visible.
- Successful purchases unlock the right trip and resume the premium action; failed/pending purchases do not lose tickets or falsely claim success.
- No unsupported alerts, sharing mode or inbox integration is advertised.
- Reduced-motion and large-text paths complete the same tasks.
- Experiment events distinguish samples, organisers, members, activation and confirmed purchases.

The first release should prove the transformation from booking to useful holiday companion. Add further spectacle only where it makes that transformation clearer or more enjoyable.
