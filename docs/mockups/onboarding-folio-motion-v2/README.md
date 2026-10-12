# Full-screen folio: alignment revision

6 October 2026. The owner found horizontal text on the angled folio unconvincing and suggested a full-screen working surface. They subsequently accepted this direction, requested clearer review wording and confirmed that flight lookup must use the real AeroData service. **Creative direction accepted; the first native integration is described in [ONBOARDING_NATIVE](../../ONBOARDING_NATIVE.md).** This folder remains the original browser rehearsal.

Preview: **http://127.0.0.1:55373/**. Replay the transition, choose screenshot/PDF or manual entry, and inspect the flat page. The study uses labelled examples; no upload, extraction, live lookup, booking save or purchase takes place.

Review now says **“Check your booking”**, or **“Check your flight”** for a flight. Lookup says **“Find your flight”**. The flight example only matches TV123 on 12 December; other inputs never receive the fixed Sydney–Bali route. Manual flight entry leaves route/time empty for entry. Native lookup must use the existing service and selected response as described in [the integration brief](../../ONBOARDING_BOOKING_FOLIO.md#flight-lookup-integration).

## Revised choreography

1. Keep the angled illustrated folio as a physical prop in the colourful invitation scene.
2. On a booking action, the folio turns square to the viewer and expands to fill the phone. Its navy binding, brass stitching, folded corner and cream paper establish the working surface. The short camera move takes approximately 550 ms.
3. The straight heading and controls enter after the page has substantially flattened, with a short 180 ms rise/fade. All text, date tags, fields and flight-board content share the same horizontal plane. Later review/type changes stay on this page without repeating the large move.
4. Travi yields the working space and peeks over the navy header. He stays still while the traveller reads and edits. The destination/date tag remains on the paper.
5. A successful save pulls back into the colourful holiday world and carries the same booking values onto their actual itinerary date. Cancellation returns to the invitation; adding bookings later remains valid.

The native screenshot/PDF action must open the platform picker immediately. Camera movement is decoration and must never block that action. Actual service timing and successful-save identity still follow [the scene brief](../../ONBOARDING_BOOKING_FOLIO.md).

## Art and source

This revision reuses the five delivery WebPs from [v1](../onboarding-folio-motion-v1/README.md). No new artwork or video was generated. The full-screen binding, paper and fold are native interface styling, so they require **no per-country image**. Country-first scenery coverage and the existing masters remain unchanged. Genuine hinged cover/page animation and independent Travi eye/hand acting are still later production work; this study demonstrates whole-layer motion and pose changes.

[motion-fragment.template.html](motion-fragment.template.html) is the editable fragment. [build_preview.py](build_preview.py) embeds the reused images into the adjacent inline fragment, `travary-folio-fullscreen.html`. The skill renderer serves that source at port 55373; restart after rebuilding. V1 remains available as historical comparison.

## Verification

Checked the normal 354 px phone and a 320 px browser viewport, whose phone is 273 px wide and 680 px tall. The narrow review stacks date/time fields; measured heading, tag, fields and save action all remain inside the phone and cream paper. No horizontal overflow or tilted working form was visible.

Verified manual review, editing a booking title/date and transferring those values onto Monday 14 December; example PDF reading through editable review; Back navigation; and the example flight-board result. Still version applies the static state, and the system reduced-motion guard remains. Captured browser logs contained no warnings/errors. These checks cover the browser study, not real-device keyboard/safe-area behaviour or native service integration.

After the copy revision, verified both review headings, rejection of a non-fixture flight number, and blank manual flight route/time surviving reload. Captured console remained clear. The visual preview does not verify the real provider's response; native flight service code was inspected, not modified or called.

Current review frame: [Check your booking](fullscreen-review-copy-v2.jpg). Earlier alignment frame: [full-screen booking page](fullscreen-review-v2.jpg).
