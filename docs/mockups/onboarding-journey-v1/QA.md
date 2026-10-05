# Connected journey review

5 October 2026. Checked the local prototype in Codex's in-app browser using the range-aware server at port 55370. These checks concern browser behaviour and composition, not the installed Flutter app.

## Verified interactions

- Restart plays the one-time entrance, then changes to the repeating idle. Actual `requestVideoFrameCallback` counters recorded **97 entrance frames**, then **221 idle frames** and **one loop wrap** during the final sequence check. This verifies decoded video frames rather than only changing posters.
- Destination selection is available during arrival and pauses the film while the sheet is open. Bali and Kyoto both lead to their matching full-stage background with live destination copy and date controls.
- The reveal hands off to a single foreground Travi pose. The underlying poster becomes the empty workshop so a second baked-in character is not visible during the reveal. The world image has no inline-baseline gap at the floor.
- A valid **12–19 December 2026** range updates both date tags and the stamped departure tag. Reload restores destination and dates in the settled scene.
- **12 December → 5 December 2026** is rejected with “Return needs to be on or after departure.” An empty submission is rejected with “Choose a departure and return date.”
- A same-day **12 December 2026** selection is accepted and displays a single date on the final tag.
- **Dates not decided** clears both draft date values, uses “Dates to come / To be continued” and survives reload without inventing dates.
- Editing the destination retains the previously chosen dates until the traveller changes them or explicitly selects undecided dates.
- **Paris** uses the neutral workshop, keeps its real name and does not falsely show the Bali scene.
- Still mode settles the scene immediately: computed world mask `inset(0px)` and Travi animation `none`. Paused motion leaves the undecided stamp visible at opacity 1 and the character animation paused. Reduced-motion handling is implemented; the actual OS setting was not toggled during this review.
- **Bring in a booking** presents an explicit review handoff to the next unit. It does not claim to import or save a booking.
- Final browser console inspection showed no captured errors or warnings.

## Layout and assets

Reviewed the complete Bali composition at the normal desktop browser size and the date sheet/tag layouts at a **320 × 780** viewport. At 320 pixels, the body client width and scroll width were both **305 pixels** (the remaining width was the scrollbar), with no horizontal overflow. The 273-pixel-wide screen's ready controls ended **11.8 pixels above its bottom**; the booking and edit buttons were **48** and **44 pixels** high. A compact date range and removal of a redundant small label keep the narrow departure tag within the stage. The viewport override was reset after testing.

The selected Travi asset is 1254 × 1254 RGBA with genuine alpha spanning 0–255; 51.7% of pixels are fully transparent. Visually checked the complete handle, twin rails, short grab handle, two arms/hands, four wheels, face and tag. Bali and Kyoto plates are 851 × 1848 RGB and contain no text, controls or character.

[Normal-size Bali preview](journey-bali-preview-v1.jpg) records the live date step. [Generation inputs](PROMPTS.md) record the selected assets. JavaScript passed `node --check` after the final date-format and draft-consistency edits.

## Remaining production checks

The scene and mascot move as whole bitmap layers; eyes, hands, wheel swivels and scenery are not independently rigged. Generated movie-to-pose framing is a prototype handoff, not a guaranteed seamless native transition. Validate deliberate crop/aspect ratios, texture/colour consistency and the exact handoff during Flutter implementation.

Real-device frame rate, video-controller lifecycle, app accessibility and OS date-picker behaviour have not been validated. Real trip persistence, imports, invitations, accounts and purchases are outside this local prototype. The next useful product unit is the booking folio, detail review and first itinerary day.
