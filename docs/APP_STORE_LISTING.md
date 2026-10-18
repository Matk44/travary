# Travary App Store listing draft

Prepared 16 October 2026 from the owner's supplied screenshot pack, the [passport icon prompt](mockups/travi-passport-app-icon-v1/PROMPT.md), current implementation and public support copy. This is a local review package: nothing has been uploaded or published, and artwork approval has not been recorded.

18 October update: all eleven iPhone frames now have real app captures and final composites in `docs/mockups/app-store-screenshots-v1/`. The [generation log](mockups/app-store-screenshots-v1/GENERATION_LOG.md) records the latest capture work. A [proposed ten-frame upload selection](app-store/PROPOSED_SCREENSHOT_SELECTION.json) swaps frame 05's flight-entry demonstration for frame 11's widget; owner confirmation is still pending. Header v4's complete theatre within the safe area is owner-approved as a still. [Search v5](mockups/app-store-creative-v1/review/index.html) retains the cleaner cream material and native 3840 × 2560 composition, correcting postcard/tag transparency and shadow edges with an isolated ImageGen asset. Genuine app UI, headline and Travi pixels are preserved. The owner approved the correction and existing-performance reuse on 18 October (“much better, lets go ahead and do the rest”). Header v4 and search v5 now have locally assembled 7-second, 30-fps silent loops (loop revision 2 corrects the size pulse at the joins) and opaque still fallbacks in [the creative delivery folder](mockups/app-store-creative-v1/exports/delivery-manifest.json). Final playback and actual placement review remain before upload.

## Review and copy

- [Open the listing review](app-store/review.html): all ten generated stills, supplied layout references and locale-specific metadata.
- [Metadata JSON](app-store/metadata.json): English (UK), English (Australia) and English (US).
- [UK copy](app-store/en-GB/description.txt), [Australian copy](app-store/en-AU/description.txt), [US copy](app-store/en-US/description.txt).
- [Generated stills and exact prompts](mockups/app-store-screenshots-v1/GENERATION_LOG.md).

| Field | UK / Australia | US |
|---|---|---|
| App name | Itinerary App - Travary (23/30) | Itinerary App - Travary (23/30) |
| Subtitle | Holiday planner & organiser (27/30) | Vacation & trip organizer (25/30) |
| Keywords | 97/100 UTF-8 bytes | 99/100 UTF-8 bytes |
| Promotional text | 151/170 characters | 151/170 characters |
| Description | 3416/4000 characters | 3424/4000 characters |

The owner-supplied plan selects “itinerary app” as the target term. Its Astro figures were not independently verified, and no ranking or conversion improvement is claimed. Name availability has not been checked in App Store Connect. Travel is the proposed primary category; the proposed copyright line uses the maker named in the project's legal pages.

## Copy decisions

The description matches the current allowances: 2 lifetime free Smart Imports and 2 ticket files per free holiday; existing saved tickets stay accessible. Annual Pass is a yearly auto-renewing subscription. Holiday Pass is a one-off purchase for one holiday up to 30 days, with pass features through 7 days after it ends. Family sharing includes the organiser within the maximum of 6 people. Personal travel documents stay local and are not shared or sent to Smart Import.

No fixed prices, trials, instantaneous-alert promises, widgets, Live Activities, email-forwarding claims, gates or baggage-belt promises were added. Flight lookup is described with schedule availability; alerts are described with flight-data availability. The current close-up app icon was reused in the review, without changing platform assets.

## Screenshot story

| # | Headline | Capture needed | Disclosure / Travi |
|---|---|---|---|
| 01 | Your holiday, / sorted into days. | Today, fictional Orlando trip, day 3 at 8:20 | Hello pose |
| 02 | Counting down / to the next one. | Lake District countdown | App's own peek |
| 03 | It spots / what's missing. | Kyoto trip with missing stay / return flight | No exterior mascot |
| 04 | Hand Travi / the confirmation. | Smart Import reading a fictional confirmation | “2 free, then a pass” |
| 05 | Just the / flight number. | Flight finder with available schedule | No exterior mascot |
| 06 | Everyone on / the same page. | A shared trip with fictional members | “With a pass”; envelope |
| 07 | Tickets that work / with no signal. | Documents with saved ticket files | “Saved bookings and tickets, on every plan.” |
| 08 | Your passport stays / on your phone. | Unlocked fictional travel documents | No exterior mascot |
| 09 | Packed / together. | Packing list with some items ticked | “One packing list. Share it with a pass.”; proud |
| 10 | Every trip gets / its own postcard. | Trips with destination postcards | Passport replaces folio in waving pose |
| 11 | Your next trip, / on your home screen. | Real medium countdown widget on the simulator home screen | Small Travi checking his watch; widget pop-out uses authentic capture pixels |

The supplied layouts and screens are design references. They are not release captures. Frame 07's supporting line was clarified to refer to saved tickets; frame 09 explicitly discloses that sharing needs a pass. Frame 10 follows the passport replacement details in the owner's referenced prompt.

## Remaining work before upload

1. Confirm which ten of the eleven frames to use for the main listing. The current proposal replaces frame 05 with frame 11, preserving the flight frame as an alternate.
2. Review the actual final composites at both iPhone sizes. Frame 04's lower half is plain cream while Smart Import reads; this is authentic app UI and the proposal keeps it. Frame 10's crop and frame 11's pop-out processing are documented in the generation log.
3. Validate release behavior and finish remaining launch/device checks in [LAUNCH_CHECKLIST.md](LAUNCH_CHECKLIST.md). Existing captures are debug demo/cloud captures using fictional travel data.
4. Prepare separate iPad screenshots for the universal app. This project's final screenshot folder currently contains the two iPhone export sizes.
5. Enter the reviewed metadata, confirm product pricing and App Privacy answers, and upload the approved screenshot selection in App Store Connect. After any remaining app captures/recordings, clear the simulator status-bar override using the command in the proposed-selection record.

The supplied pack's original header/search brief remains a reference. The owner approved the initial concepts on 18 October and subsequently approved header v4's complete-scene safe-area layout. [Current creative review](mockups/app-store-creative-v1/README.md) pairs that header with search v5's quiet cream paper, regenerated transparent postcard/tag and padded shadows. The real Today UI, headline and existing Travi are pixel-identical to v4. A native tag close-up documents the edge correction. The owner approved continuing local reuse; both composed header/search loops are now rendered with matching still fallbacks. Full-file decode, dimensions, 30-fps cadence, supported duration, join-window scale and wrap continuity are checked in [the playback QA report](mockups/app-store-creative-v1/review/motion-qa-report-v2.json). Owner final playback approval and App Store Connect Preview remain before upload. No new paid video generation occurred; any new paid Travi clip requires consultation first. Any newly proposed scene/transition remains subject to AGENTS.md's artwork approval rule.

## Apple references checked on 16 October 2026

[Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) supplies the metadata limits: 170 promotional-text characters, 4000 description characters and 100 keyword bytes. Name/subtitle fields use 30-character limits.

[App Review Guidelines, section 2.3](https://developer.apple.com/app-store/review/guidelines/#accurate-metadata) require accurate product representation, actual app use in screenshots and disclosure of featured purchases. This is why the green-screen plates and supplied mockups remain review assets until captures are inserted.

[Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) currently name the medium Dynamic Island iPhone display as required, accept 1206 × 2622 there and 1320 × 2868 for the large display, and require 13-inch iPad screenshots when iPad is supported. The source pack's “6.3-inch” shorthand is retained only in its archived source document.
