# Date tag → first booking: motion rehearsal

**Current revision:** [v2 uses a flat full-screen folio](../onboarding-folio-motion-v2/README.md) after the owner flagged the angled working page/text mismatch. This v1 study is retained for history; its angled focus treatment is superseded for the next review.

6 October 2026. The owner liked the folio art direction and asked to visualise continuity, folio focus and an AeroDataBox flight-board branch before commissioning more film. This is an interactive native-motion rehearsal with **example data only**. No file picker, upload, extraction, lookup, booking save, purchase or Flutter integration runs here. No new video was generated.

Preview: **http://127.0.0.1:55372/**. The same fragment is shown in the conversation. Start with **Replay transition**, then choose **Add a screenshot or PDF**, or **Enter a booking myself → Flight**. Stay and Activity also lead to editable example reviews. The booking title, date, time and location are editable; preview confirmation carries the same values to the example itinerary day. Dates outside the example holiday are flagged. Back/cancellation and adding bookings later preserve the holiday context. Still version removes transforms and waiting motion; the system reduced-motion preference is respected too.

## Choreography to take forward

Times are proposed direction, not measured conversion optima. Actions remain available during decoration; a tap settles the entrance and proceeds. **The finished date tag is a short connecting beat, not another compulsory Continue screen.** In production, saving dates can lead directly into the folio invitation; the rehearsal starts at the existing completed-tag frame so the transition can be replayed deliberately.

| Trigger / beat | Motion and acting | Approximate duration |
|---|---|---|
| Dates confirmed | Dates settle, one coral stamp lands; Travi gives a small pleased reaction. | 200–300 ms |
| Move to first booking | The real destination/date tag travels to the sky as a compact keepsake. The same scenery stays behind it. | 650–800 ms |
| Invitation | Folio comes forward from the lower-left, opens, settles with a slight overshoot. Travi presents it. In the finished performance he notices and straightens one crooked paper corner, then waits attentively. | 700–950 ms, overlapping the tag movement |
| Headline | Short Paper words rise after the physical movement, cream with one coral accent. Leave copy and controls still afterwards. | 300–450 ms; start around 800 ms |
| Import or manual chosen | The open folio grows toward the viewer. Its right paper page becomes the usable working surface; destination art remains at the edges. Travi yields the space. | 450–650 ms |
| File selected | One paper settles into the folio. Travi follows it with an attentive glance. Reading state tracks the actual service; review appears as soon as available. | 250–350 ms entrance; no artificial service delay |
| Flight details returned | Number tiles flip once left-to-right, then route and scheduled local times settle. Travi perks up once; no endless random board cycling. | 250–400 ms plus a small tile stagger |
| Editing | Paper, fields, dates and all decorations stop moving. | Static until action |
| Save succeeds | A brief satisfied nod; the **same saved booking** moves onto its actual itinerary day. Celebrate successful save, not successful lookup or extraction alone. | 550–800 ms |

The repertoire is **anticipation → attentive help → earned satisfaction**. Travi is a capable holiday porter. Waiting motion is sparse: a slight shift or blink on a roughly 6–8 second cycle, with long still intervals. He never competes with typing, error messages or ticket details. Sound is optional: one gentle paper swish or quiet mechanical clack per event; silent by default.

## Route treatment

**Screenshot/PDF:** selecting the option opens the real platform picker immediately; never make someone wait for the camera move. Cancellation returns to the open folio. The study uses an explicit sample-PDF button instead of uploading a file. Extraction yields the existing editable review, including uncertainty and multiple-booking handling. Service timing is real in production; the study's timed sample reading is illustration only.

**Manual:** the same folio focus reveals Flight, Stay and Activity. Choosing a type changes the working page without replaying the scenery or the large zoom. Use the existing booking editor and actual trip context in native integration. The study's compact fields illustrate the handoff; they are not the full editor or a flight-arrival form.

**Flight:** put the departures board inside the focused folio. In this version it lives under **Enter a booking myself → Flight**, preserving the three clear invitation choices. It is a number/date lookup for an already booked flight, not flight shopping or ticket purchase. A usable future result shows schedule data; gate, terminal and delay appear only when supplied by the service and appropriate near departure. Never create a boarding pass/barcode or infer a reservation from a public schedule. “Use this flight” fills an editable draft; explicit save is still required.

## Existing product capability and release dependency

The app already implements this visual language in [FlightFinder](../../../lib/features/booking/flight_finder.dart) and [DepartureBoard / FlapText](../../../lib/design/widgets/departure_board.dart). FlightFinder debounces valid number/date input for 700 ms, handles multiple legs, not-found and unavailable states, and calls `flightFill` after the traveller chooses a result. Reuse those states and components.

[Bootstrap](../../../lib/app/bootstrap.dart) currently supplies the service only for `cloud && kDebugMode`; its comment records the free-plan commercial-use constraint. The backend currently accepts dates from 7 days ago to 365 days ahead. Neither that validation nor this rehearsal guarantees a result for every airline/date. Vendor schedule availability depends on coverage and subscription; [AeroDataBox's current pricing/coverage table](https://aerodatabox.com/pricing) describes 180/365-day limits on listed direct plans and commercial-use options (checked 6 October 2026). Confirm the actual marketplace subscription and release enablement before exposing lookup in shipping onboarding. When service is absent or data is unavailable, retain manual entry with a calm explanation. No credentials or billable live calls were used for this study.

## Reusable art and performance limits

Generated two shared preparation assets with built-in imagegen: [prop-free Bali plate](bali-stage-prop-free-v1.png) and [closed folio](closed-folio-v1.png). Exact prompts/reference roles/source paths are in [GENERATION.md](GENERATION.md); inspection and encoding provenance are in [delivery-manifest.json](delivery-manifest.json). Open folio and Travi poses reuse the previously selected masters unchanged. The clean plate is still the Bali **region exception**, not an Indonesia country illustration. Country-first coverage remains unchanged.

The study uses whole-layer moves, pose crossfades and a closed/open dissolve. **It does not contain articulated cover unfolding, independent eyes/hands/wheels, or the proposed ticket-corner gesture.** After choreography review, author shared hinged cover/page pieces and the necessary Travi performance states once; then reuse them across country plates. All text, inputs, actual data and response timing stay native. New destination plates require one prop-free scenery image per country, not a new film.

## Source and preview

[motion-fragment.template.html](motion-fragment.template.html) is the literal editable fragment, with placeholders for the five existing media layers. [encode_preview.py](encode_preview.py) creates delivery-only WebP derivatives and embeds them into the thread's inline source (under 1 MB), preserving the masters. The skill's `render.py --serve --port 55372` wraps the fragment in its sandbox for browser inspection. This server holds the rendered source at launch; restart it after source edits.

Browser QA and proof images are recorded in [QA.md](QA.md). Production integration remains governed by [the booking-scene brief](../../ONBOARDING_BOOKING_FOLIO.md), including actual saved booking identity, multiple results, no-date drafts, interruptions and failure states.
