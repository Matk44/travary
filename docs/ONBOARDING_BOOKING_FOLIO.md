# Next scene: got a booking for me?

5 October 2026, updated 6 October. Creative brief for the scene after destination and dates. The approved direction now has a [first native Flutter integration](ONBOARDING_NATIVE.md), using real holiday creation, booking forms, import and flight-service paths.

The owner authorised still generation before animation, then responded positively to the [opening composition, open folio and receiving Travi pose](mockups/onboarding-booking-folio-v1/README.md). On 6 October they requested a transition rehearsal, folio focus and a flight-board branch, then flagged the mismatch between the angled folio and horizontal text. They subsequently accepted the [full-screen folio direction](mockups/onboarding-folio-motion-v2/README.md), requested clearer review wording and confirmed flight lookup should use their real AeroData service. The browser study remains a labelled-example rehearsal; the native integration reuses its existing artwork and films.

## The job of this scene

Turn holiday anticipation into a useful outcome: **one booking the traveller recognises, checks and can find in their actual itinerary**. Keep their chosen destination, dates and draft. No extra preference questionnaire is needed before this task.

Country scenery is the default coverage strategy, recorded in [the destination guide](ONBOARDING_DESTINATION_ART.md). The folio, Travi's acting, buttons and booking-card transition work across every country.

## Opening frame and copy

Stay in the same colourful paper world. The completed departure tag remains as a smaller visible keepsake. The navy folio from the lower-left floor moves into the working area and opens to a blank cream ticket space. Travi presents it, nudges one paper corner neatly into place and gives the traveller an expectant look. This small useful gesture is the humour; the scene should make him a capable porter.

**Headline:** “Got a booking for me?”

**Supporting copy:** “A flight, stay or activity—let's put your first booking in your plan.”

| Choice | Action and result |
|---|---|
| **Add a screenshot or PDF** | Open the device's specific file/photo picker and use the existing Smart Import capability. Keep the holiday context. |
| **Enter a booking myself** | Open the existing manual booking flow with destination/trip context where applicable. |
| **I'll add bookings later** | Preserve the holiday setup and continue into its planner/draft. Do not require a booking or invent one. |

For a new eligible traveller, a quiet line can say **“Your first 3 Smart Imports are free.”** Read the real allowance; never show that line as a fresh allowance for someone who has already used it. Import supports images and PDFs, not an inbox connection or email-forwarding promise. Reuse existing access decisions and retain manual entry if import is unavailable.

## Performance tied to real states

| State | Travi and the folio | Live interface behaviour |
|---|---|---|
| Waiting for input | Attentive, open-eyed presentation pose; restrained idle | All three choices immediately available; decorative entrance can settle on action |
| File selected and reading | Selected paper settles into the folio; Travi looks attentively at it | Honest “Reading your booking…” status follows the actual service. No invented progress percentages, results or success stamps |
| Draft available | Travi becomes quieter and yields the main space | “Let's check the details.” Editable booking review shows dates, local times, type, location and uncertain fields, with the source accessible |
| Traveller confirms a successful save | A satisfied nod; Travi squares the ticket | “Added to your holiday.” The SAME saved booking card moves into its actual date on the itinerary |
| Cancelled, unreadable or offline | Calm helpful pose | Preserve setup. Offer retry, another file, manual entry or later; never celebrate a failed operation |

Use Paper words for the short scene heading, cream with one coral accent, then leave it still. Let the folio movement finish before the heading enters. Stop decorative motion while reviewing details. Actual dates, times, source documents and buttons stay readable and motionless.

**Working-page direction, revised 6 October:** keep the angled folio as the invitation prop. When import/manual entry begins, turn it square to the viewer and expand it into a flat full-screen cream page with navy binding and brass stitching. Reveal horizontal text/fields after flattening; never paste a working form onto an angled illustrated page. Travi peeks over the header and yields the paper. The flight board uses this same surface. Successful save returns to the colourful holiday world. These shared native surfaces require no additional destination images. Picker access and real response timing remain immediate, independent of decorative motion.

**Review copy:** use “Check your booking” for general booking review and “Check your flight” for flights, replacing “Make it yours”. Flight lookup starts with “Find your flight” and “Flight number and the day it leaves.” The selected result becomes an editable draft; the final action remains “Add to my holiday”.

## Flight lookup integration

Reuse the existing [FlightFinder](../lib/features/booking/flight_finder.dart), [CloudFlightStatusService](../lib/data/flight_status_service.dart) and server-side [flightStatus callable](../functions/src/flightStatus.ts). A new flight entered by number follows the real service, not the study's fixed example route:

1. Ask for the flight number and **local departure date**; let the traveller change the holiday-derived starting date.
2. Call `FlightStatusService.find` with that number/date. Existing input debounce and stale-answer protection remain; board animation follows the returned data, not a fabricated success timer.
3. Show returned route and scheduled airport-local departure/arrival times, including a different arrival day. Let the traveller select the matching leg when several are returned. Lookup is a schedule match, not proof of a reservation.
4. “Use this flight” passes the actual selected leg through `flightFill` into editable review. Retain departure airport/code, number, both dates and scheduled times. Do not invent missing values, gates, terminals or delays.
5. Explicit save adds that reviewed booking to the selected holiday. Preserve not-found, unavailable and manual-entry paths; discard stale results after number/date changes.

The backend already uses `dateLocalRole=Departure` and keeps the API key server-side. Native bootstrap enables the cloud service in debug by default, with explicit `TRAVARY_FLIGHT_LOOKUP` release configuration once the deployment/provider plan is ready. No API key was read and no live lookup was run for this work. The browser demonstration remains restricted to its labelled TV123/12 December example; the native flow uses the injected service and actual selected response.

One file may yield multiple bookings. Show all extracted drafts and let the traveller review/select what to save; do not silently discard extras or claim one file equals one booking. Confirm the holiday assignment and any date conflicts rather than overwriting the dates already chosen. Unknown holiday dates stay unknown until the traveller confirms appropriate dates; no guessed dates are stamped into the draft.

## The payoff and branches

After saving, show the actual booking's day. A hotel stay can appear on its real check-in date; a flight can appear at its actual departure time. Do not fabricate a morning-to-evening itinerary or a boarding/admission barcode. Give the traveller one useful action: **Open your booking**, or **Show your ticket** when a source attachment exists.

If they have not booked yet or choose later, give a warm handoff: **“Your holiday has a home. Add plans whenever you're ready.”** Keep their real destination and dates. An optional product example may be explicitly labelled **Example** and must not be saved into their holiday. Empty setup is a valid outcome and does not trigger an automatic closing paywall.

The Holiday/Annual Pass offer follows practical proof from a real booking, with a visible free continuation. The pass scene extends the utility they experienced—more Smart Import, sharing and booking-file backup. The first booking invitation itself is not a purchase gate for an eligible new traveller.

## Art to create next

1. **One opening composition still** for reviewing this scene: existing scenic stage, existing departure tag, open folio, Travi presenting, and proposed copy/control placement. This is a review image, not a production UI background.
2. **One clean open navy folio shell**, with blank cream ticket/page spaces and real transparency for native compositing. Its recognisable material and hardware should match the closed folio already in the scene.
3. **One transparent Travi offering/receiving pose**, same coral ribbed spinner identity, eager eyes, complete hands/handles/wheels and coherent light.

The existing [asset register](onboarding/DESTINATION_ART_REGISTER.md) already lists the folio and offering pose. Checking and proud handoff poses remain later shared additions, briefed against the review/day composition. No new country or city illustration is required for this scene. Prototype folio/ticket motion with native transforms before commissioning another film.

## Product handoff and review

Use [SmartImportScreen](../lib/features/import/smart_import_screen.dart) and [EditBookingScreen](../lib/features/booking/edit_booking_screen.dart) as product building blocks. Preserve the current extraction, editable review, attachment and access-policy behaviour. The local browser prototype cannot silently become a production import service.

The native integration carries holiday context through import and save, exposes form save failures and persists setup with a reserved trip ID. Unknown dates create a real undated holiday. Setup and confirmed booking identity resume; unconfirmed review/form edits still have only route lifetime and are not restored after a process kill. Richer review persistence is a remaining refinement.

`SmartImportOutcome` now also returns the actual `SaveResult` objects, including booking/trip IDs. Onboarding uses the real saved booking for its day/card and opens its holiday. Multiple extracted drafts remain available for review and saving.

Review the opening composition, then prove **choose file/manual → review → confirm save → same booking on its actual day**. Include no-booking, multiple-booking, cancellation and failure branches. Only then refine performance/video where it improves the real interaction.
