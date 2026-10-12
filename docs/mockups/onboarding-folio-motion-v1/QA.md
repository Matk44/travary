# Motion-study verification

6 October 2026. Browser checks on the sandbox-wrapped fragment at `http://127.0.0.1:55372/`. This is creative/prototype QA, not testing the Flutter application or a live import/flight API.

- Completed date frame → invitation: native buttons available; the destination and actual example date range remain on the compact tag. One folio and one visible Travi; full colour scenery remains behind both.
- Import: choosing import focuses the right page. Explicit sample PDF enters reading and reaches editable review. Back cancels timed transitions; stale timers do not replace the new scene. State-update echoes no longer reset the sample reading scene.
- Save preview: edited a stay title to `My Bali stay` and date to `2026-12-14`. Confirmation displayed those values on **Monday 14 December**, with the same time and place on the same booking-card element. No actual booking was saved.
- Flight: manual choice → Flight → sample lookup flips `TV123`, with explicitly labelled sample `SYD → DPS` schedule. Use this example flight populates an editable Flight review. Back returns to the board. No external lookup was made.
- Narrow viewport: temporary browser width 320 px; iframe content width 273 px. No horizontal overflow. Phone minimum height 680 px keeps flight/manual controls inside the screen. Review fields stack; all visible input/button rectangles fit, with **52 px** below the normal review confirmation button in the measured layout. The enlarged paper surface accommodates the stacked fields.
- Date conflict: a date outside the example holiday keeps review open and presents a readable error. No success/day animation runs. The shorter final message is “Outside this holiday. Choose 12–19 Dec to preview.”
- Still version: the pressed control sets the still class; CSS disables all layer transitions/animations. The same routes remain available. A `prefers-reduced-motion` rule and JS guard are present; the OS preference was not changed during this check. Animation enumeration was unavailable in the browser's read-only inspection API, so no animation-count result is claimed.
- The sandbox disallows form submission. Preview confirmation therefore uses a labelled native button and a local handler, with Enter handled locally as well; it sends no form or network request.
- Static JavaScript parsed successfully; all five embedded image sources have delivered masters/derivatives in the manifest. Fragment remains under 1 MB and includes no document wrapper or image placeholders. Browser captured no page errors/warnings during the reviewed routes.
- Temporary viewport override reset before delivery. Earlier intro, journey and still-art servers remain separate. The motion preview server is left running for review.

## Saved proof

- [Flight board example](motion-study-flight-v1.jpg): native browser screenshot of the complete board and surrounding folio/holiday scene. The image explicitly says Example data.
- [Mobile review](motion-study-mobile-v1.jpg): narrow viewport screenshot, including editable Flight review and the expanded paper.

## Remaining production work

This proof does not animate separate covers, hands or facial features. It does not demonstrate true file-picker cancellation, service failures, multiple extraction results, uncertain fields, live multi-leg flight results, date-less trip creation, native keyboard insets, accessibility on a real phone, or a confirmed persistent booking save. The native product integration must validate those states using its existing services and actual saved booking/trip IDs. The study does not add flight shopping, fare estimates, boarding barcodes or paid flight alerts.
