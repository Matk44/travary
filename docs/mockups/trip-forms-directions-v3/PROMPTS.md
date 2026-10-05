# Travary refined screens — round 3

Created 5 October 2026 with the built-in ImageGen tool.

## Current user brief

D and E were too boring. Return to the character of A–C, simplify the icons and visible controls, retain the actual woven background so the pages flow with the existing app, and preserve the passport book illustration as the upload shortcut.

## Refinement decisions

- Restore the actual `assets/art/common/linen.png` as the woven reference and the comparison viewer background.
- Keep the destination postcard and one hanging tag, cream paper, navy serif, screen-print art and subtle physical construction.
- Remove category icons and miniature keepsakes from manual booking choices and itinerary rows.
- Preserve the recognisable navy passport book for Passport & documents uploads.
- Keep travellers and card style behind Trip details; further booking types and form fields unfold when needed.
- Show one flight-finder board, with the editable review following Use this flight.
- A2 keeps compact physical ticket slips and a small stay preview. C2 uses one journal sheet and makes the stay form itself the key-card object.

## Reference inputs

1. `../trip-forms-directions-v1/01-classic-folio.png`
2. `../trip-forms-directions-v1/03-quiet-ledger.png`
3. `../../../assets/art/common/linen.png`

All data are illustrative. These are concept mockups, not production rasters or implemented controls.

## A2 · Refined folio

Output: `06-refined-folio.png`

```text
Use case: ui-mockup.
Asset type: refined Travary mobile screen style board.
Primary request: refine the original A/C travel-object designs into something catchy, clean and user friendly. The user DISLIKED the stripped-flat D/E round as boring. They like the character of A–C, want fewer decorative category icons, want the existing WOVEN BACKGROUND IMAGE preserved throughout, and specifically want the NAVY PASSPORT BOOK ICON for passport uploads. Maintain personality and tactile travel paper while making the information hierarchy simpler.

Input images:
Image 1 = original A Classic folio: positive reference for richness, postcard/tag, cream paper, navy serif and passport book.
Image 2 = original C Quiet ledger: positive reference for alignment, compact components and legibility.
Image 3 = the ACTUAL APP WOVEN LINEN BACKGROUND IMAGE. Use this visible oatmeal weave for the background of EVERY screen and bottom sheet. This is an essential invariant: continuous woven linen behind all cards and controls. It should visibly match this supplied image, at natural fine weave scale, calm and even. DO NOT replace it with plain cream, smooth beige, blank white or generic paper grain.

Composition: ONE landscape comparison board with FOUR complete portrait phone-screen canvases in a row, equal 390:844 proportions, all visible without cropping. Small direction title at top and four captions. No device hardware, perspective, shadows around entire phones or desk photography. Screens dominate most of the canvas. Each screen shows naturally spaced UI at real mobile scale. Use approx 24px side padding, 16–24px between groups, at least 48px touch rows, navy Source Serif 4 heading 28–30px, clear Inter secondary text 14–16px. No giant titles consuming the screen. Strong navy #1C2A47, cream paper #F8F4EC, teal #1E5B70, coral #E5785B, small mustard accents. Resolved flat layered travel screen-print art with fine grain ON ART/OBJECTS. Keep objects aligned and low rotation. Subtle contact shadows only on a few physical objects; clean and restrained around them.

Core UX: one main task and one focal travel object per screen. Icons only where helpful: normal back/close/chevrons, camera for booking import, the specifically loved passport book, calendar if needed, and the familiar app bottom navigation ON THE TRIP SCREEN ONLY. Remove all decorative airplane/bed/fork/compass icons from booking choices and itinerary rows. No brass passenger rings, no individual traveller tags, no chips for card styles, no three empty ghost-ticket slots, no eight miniature keepsakes, no category badge on every row. People and style live behind "Trip details". Other booking types and optional form fields are folded away.

Same four screens for both refinements:
1 caption "Trip".
Top back link "Trips", a quiet "Trip details" control at right. A compact richly illustrated Japan destination postcard with Mount Fuji, one pagoda, coral sun and maple branches, thin cream paper edge. ONE actual hanging ivory/kraft luggage tag at the upper-right, with natural twine/one brass eyelet, containing "Japan", "11–30 Oct 2026", "6 days to go". Tag must be small enough to leave most of art visible, readable at mobile size. Do NOT add another Japan heading outside the tag. Below "Your plan": exactly three chronological entries with small 11 OCT, 12 OCT, 13 OCT dates, titles "Sydney → Tokyo", "Kyoto House", "Kyoto Railway Museum", and respective one-line details "QF25 · 20:55", "12–14 Oct · 2 nights", "10:00 · 2 tickets". No category icons or art stamp repeated on the rows. Then ONE quiet row "Stay needed · 14–16 Oct" with "Add" text link. Leave comfortable woven gaps between groups. Familiar Travary bottom navigation: Today, Trips selected teal, central coral +, Documents, Profile, on the existing cream fabric tabs and SLIM navy stitched base. This central + is the add-booking action; don't duplicate it with an extra big button on this page. No "Who's coming" or card-style section in this initial view.

2 caption "Add a booking".
A real bottom sheet: short softly dimmed slice of the trip above it; sheet body woven linen matching Image 3, small drag handle and close x. Serif "Add a booking". ONE prominent cream import slip "Snap a booking", support text "Photo, screenshot or PDF", a single small camera or flat polaroid thumbnail at left and chevron at right. Below small heading "Add manually". Show just four common options "Flight", "Stay", "Tickets", "Dining", with TEXT ONLY: no airplane, hotel fob, admission object or cutlery icon next to these labels. The layout of these options is direction-specific below. A quiet "More booking types" collapsed row holds Transport, Activity, Event and Note; do not render those options yet. At the bottom a distinct cream paper row with the original SMALL CLOSED NAVY PASSPORT BOOK illustration, gold emblem, approx 38–42px tall, next to "Passport & documents" and small "Upload passport, visa or insurance" beneath, plus chevron. This passport is a recognisable tappable upload shortcut, not a generic document glyph. No persistent five-tab nav across this sheet.

3 caption "Add a stay".
Top simple back arrow and "Add a stay", small "Japan · 11–30 Oct" trip context. Tactile key-card / paper-slip composition with warm cream on woven linen; its specific construction is direction-specific. Visible essential controls ONLY: "PROPERTY NAME" value "Kyoto House"; "LOCATION" value "Kyoto, Japan"; "CHECK-IN" value "12 Oct 2026" and "CHECK-OUT" value "14 Oct 2026" in one row; small "2 nights" between/below dates; one folded "More details" row for reference, guests, notes and attachments. Crisp navy labels and values on hairline rules, no big outlined grey Material boxes, no field icon on every row, NO brass fob or hanging bed tag. Dates readable live text inside light stamp-style keylines, no heavy ink distress. One navy "Add stay" primary action with subtle ticket notches near bottom, plenty of woven breathing room. No separate trip postcard selector, no paperclip row, no all-optional-fields list, no five-tab nav here.

4 caption "Find your flight".
Back, serif "Find your flight", small trip context "Japan · 11–30 Oct". A SINGLE navy/teal split-flap flight finder is the focal object, drawn crisp like actual UI: top controls label "FLIGHT NUMBER" value "QF25", label "DEPARTURE DATE" value "11 Oct 2026"; result clear "QF 25" in a modest row of split-flap tiles, route "Sydney → Tokyo" in regular cream text, time "20:55". All inside one board, separated by clean spacing; not a massive matrix of big airport-code tiles. Beneath the board a quiet line "Details stay editable". Exactly one navy "Use this flight" primary action near bottom and plain "Enter flight manually" secondary text. This action opens the editable review, so no duplicate FROM/TO fields or giant boarding-pass preview below/above this result. All calm woven linen around the one board. No airline logo, destination postmark, barcode, icons by each field or five-tab nav.

Hard requirements: actual woven image character visible behind EVERY screen and the add sheet; warm cream physical paper; navy editorial type; original travel charm; dedicated recognisable navy passport book upload row. Fewer icons and fewer initially visible decisions, not a generic flat minimal banking app. No wax seals, scrapbook collage, dangling accessories everywhere, duplicate scenery on every row, empty white forms or smooth ivory backgrounds. All data illustrative. Exactly four screens in given order with correct readable text.
Direction-specific refinement:
Board title "A2 · Refined folio", subtitle "The original character, with fewer competing elements."
Keep closest to A's warm tactile objects and visually exciting postcard art. Trip hero postcard about 195 phone pixels tall; beautifully rich teal/coral print but tag restrained at right. Itinerary entries are three simple CREAM TICKET SLIPS (no large pictures or category icons), each with one tiny subtle perforation seam between date and title, soft small shadow and ample linen between. Slip text title navy serif, detail clean sans. Woven visible in all gutters and spaces.
Add-manual choices are four small clean cream paper buttons in a 2x2 layout, consistent surfaces and serif text labels only, roughly 60px tall, no icons, no decorative notches on each tile. Snap/import and passport are the only two illustrated shortcuts.
Stay: a COMPACT elegant live key-card preview about 100 phone pixels tall at top, cream with one teal side band and a small Kyoto vignette occupying only the right quarter; "Kyoto House" and "12–14 Oct · 2 nights". No dangling accessories. Below ONE clean cream form slip with the essential fields stated above, plain straight paper edges, no heavily perforated frame. All controls aligned; reduce card preview size to avoid crowding. Primary button navy and subtly notched, typography sans for actions.
Flight board gently physical with a fine frame and a narrow split-flap strip for QF25; cream labelled entry fields above result within the same panel. Navy panel about 240 phone pixels tall max, no giant airport-code typography. User should immediately recognise kinship with the approved A screen while finding it easier to scan.
```

## C2 · Refined ledger

Output: `07-refined-ledger.png`

```text
Use case: ui-mockup.
Asset type: refined Travary mobile screen style board.
Primary request: refine the original A/C travel-object designs into something catchy, clean and user friendly. The user DISLIKED the stripped-flat D/E round as boring. They like the character of A–C, want fewer decorative category icons, want the existing WOVEN BACKGROUND IMAGE preserved throughout, and specifically want the NAVY PASSPORT BOOK ICON for passport uploads. Maintain personality and tactile travel paper while making the information hierarchy simpler.

Input images:
Image 1 = original A Classic folio: positive reference for richness, postcard/tag, cream paper, navy serif and passport book.
Image 2 = original C Quiet ledger: positive reference for alignment, compact components and legibility.
Image 3 = the ACTUAL APP WOVEN LINEN BACKGROUND IMAGE. Use this visible oatmeal weave for the background of EVERY screen and bottom sheet. This is an essential invariant: continuous woven linen behind all cards and controls. It should visibly match this supplied image, at natural fine weave scale, calm and even. DO NOT replace it with plain cream, smooth beige, blank white or generic paper grain.

Composition: ONE landscape comparison board with FOUR complete portrait phone-screen canvases in a row, equal 390:844 proportions, all visible without cropping. Small direction title at top and four captions. No device hardware, perspective, shadows around entire phones or desk photography. Screens dominate most of the canvas. Each screen shows naturally spaced UI at real mobile scale. Use approx 24px side padding, 16–24px between groups, at least 48px touch rows, navy Source Serif 4 heading 28–30px, clear Inter secondary text 14–16px. No giant titles consuming the screen. Strong navy #1C2A47, cream paper #F8F4EC, teal #1E5B70, coral #E5785B, small mustard accents. Resolved flat layered travel screen-print art with fine grain ON ART/OBJECTS. Keep objects aligned and low rotation. Subtle contact shadows only on a few physical objects; clean and restrained around them.

Core UX: one main task and one focal travel object per screen. Icons only where helpful: normal back/close/chevrons, camera for booking import, the specifically loved passport book, calendar if needed, and the familiar app bottom navigation ON THE TRIP SCREEN ONLY. Remove all decorative airplane/bed/fork/compass icons from booking choices and itinerary rows. No brass passenger rings, no individual traveller tags, no chips for card styles, no three empty ghost-ticket slots, no eight miniature keepsakes, no category badge on every row. People and style live behind "Trip details". Other booking types and optional form fields are folded away.

Same four screens for both refinements:
1 caption "Trip".
Top back link "Trips", a quiet "Trip details" control at right. A compact richly illustrated Japan destination postcard with Mount Fuji, one pagoda, coral sun and maple branches, thin cream paper edge. ONE actual hanging ivory/kraft luggage tag at the upper-right, with natural twine/one brass eyelet, containing "Japan", "11–30 Oct 2026", "6 days to go". Tag must be small enough to leave most of art visible, readable at mobile size. Do NOT add another Japan heading outside the tag. Below "Your plan": exactly three chronological entries with small 11 OCT, 12 OCT, 13 OCT dates, titles "Sydney → Tokyo", "Kyoto House", "Kyoto Railway Museum", and respective one-line details "QF25 · 20:55", "12–14 Oct · 2 nights", "10:00 · 2 tickets". No category icons or art stamp repeated on the rows. Then ONE quiet row "Stay needed · 14–16 Oct" with "Add" text link. Leave comfortable woven gaps between groups. Familiar Travary bottom navigation: Today, Trips selected teal, central coral +, Documents, Profile, on the existing cream fabric tabs and SLIM navy stitched base. This central + is the add-booking action; don't duplicate it with an extra big button on this page. No "Who's coming" or card-style section in this initial view.

2 caption "Add a booking".
A real bottom sheet: short softly dimmed slice of the trip above it; sheet body woven linen matching Image 3, small drag handle and close x. Serif "Add a booking". ONE prominent cream import slip "Snap a booking", support text "Photo, screenshot or PDF", a single small camera or flat polaroid thumbnail at left and chevron at right. Below small heading "Add manually". Show just four common options "Flight", "Stay", "Tickets", "Dining", with TEXT ONLY: no airplane, hotel fob, admission object or cutlery icon next to these labels. The layout of these options is direction-specific below. A quiet "More booking types" collapsed row holds Transport, Activity, Event and Note; do not render those options yet. At the bottom a distinct cream paper row with the original SMALL CLOSED NAVY PASSPORT BOOK illustration, gold emblem, approx 38–42px tall, next to "Passport & documents" and small "Upload passport, visa or insurance" beneath, plus chevron. This passport is a recognisable tappable upload shortcut, not a generic document glyph. No persistent five-tab nav across this sheet.

3 caption "Add a stay".
Top simple back arrow and "Add a stay", small "Japan · 11–30 Oct" trip context. Tactile key-card / paper-slip composition with warm cream on woven linen; its specific construction is direction-specific. Visible essential controls ONLY: "PROPERTY NAME" value "Kyoto House"; "LOCATION" value "Kyoto, Japan"; "CHECK-IN" value "12 Oct 2026" and "CHECK-OUT" value "14 Oct 2026" in one row; small "2 nights" between/below dates; one folded "More details" row for reference, guests, notes and attachments. Crisp navy labels and values on hairline rules, no big outlined grey Material boxes, no field icon on every row, NO brass fob or hanging bed tag. Dates readable live text inside light stamp-style keylines, no heavy ink distress. One navy "Add stay" primary action with subtle ticket notches near bottom, plenty of woven breathing room. No separate trip postcard selector, no paperclip row, no all-optional-fields list, no five-tab nav here.

4 caption "Find your flight".
Back, serif "Find your flight", small trip context "Japan · 11–30 Oct". A SINGLE navy/teal split-flap flight finder is the focal object, drawn crisp like actual UI: top controls label "FLIGHT NUMBER" value "QF25", label "DEPARTURE DATE" value "11 Oct 2026"; result clear "QF 25" in a modest row of split-flap tiles, route "Sydney → Tokyo" in regular cream text, time "20:55". All inside one board, separated by clean spacing; not a massive matrix of big airport-code tiles. Beneath the board a quiet line "Details stay editable". Exactly one navy "Use this flight" primary action near bottom and plain "Enter flight manually" secondary text. This action opens the editable review, so no duplicate FROM/TO fields or giant boarding-pass preview below/above this result. All calm woven linen around the one board. No airline logo, destination postmark, barcode, icons by each field or five-tab nav.

Hard requirements: actual woven image character visible behind EVERY screen and the add sheet; warm cream physical paper; navy editorial type; original travel charm; dedicated recognisable navy passport book upload row. Fewer icons and fewer initially visible decisions, not a generic flat minimal banking app. No wax seals, scrapbook collage, dangling accessories everywhere, duplicate scenery on every row, empty white forms or smooth ivory backgrounds. All data illustrative. Exactly four screens in given order with correct readable text.
Direction-specific refinement:
Board title "C2 · Refined ledger", subtitle "Woven linen, travel paper, and a clearer rhythm."
Keep closest to C's organised correspondence style but RETAIN woven background and tactile cream objects. The Japan postcard and single luggage tag stay rich and visible, around 170 phone pixels high. The itinerary is ONE continuous cream journal sheet with three unboxed chronological rows and thin rules, DATE column at left; little soft sheet shadow and wide woven margin. No individual illustrations or category icons. More generous rhythm than A2, typography still navy serif for section headings and booking titles.
Add-manual options are one cream sheet with four full-width text rows Flight, Stay, Tickets, Dining, thin dividers and just a small chevron at right. No option icons or separate tiles. Snap a booking is its own small cream import slip above; passport remains a separate clear row at the bottom with the SAME navy passport illustration.
Stay: make the editable form itself ONE elegant cream HOTEL KEY CARD / REGISTRATION SLIP, no separate preview on top. A slim teal band across its top reads "YOUR STAY"; a tiny Japanese scenic corner detail occupies at most 45x45 phone pixels. The four essential fields on hairline rules fill this one meaningful object; dates are very light stamp-keyline halves with "2 nights" between. No duplicate Kyoto House summary. Strongly Travary through real paper, typography, linen and key-card construction, yet highly usable.
Flight finder: one deep teal-navy departures board with modest split-flap QF25, crisp cream controls and ordinary route/time text. Clean aligned ink and slightly lighter shadow than A2, no logos or extra pictures. Essential content should fill only about 60 percent of the available vertical space; let linen breathe. One navy notched primary button shared with stay.
Overall: crafted and calm, not stark or generic; key-card form and journal sheet make the tactile motif purposeful.
```

