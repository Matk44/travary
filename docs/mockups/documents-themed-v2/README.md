# Themed Documents concepts

These mockups explore how the Documents tab can inherit the selected trip theme while keeping search, filters, booking details, and offline access easy to scan. They are concept images, not production assets.

## 01 — Illustrated Ticket Ledger

Each document becomes a compact ticket with a wide, category-specific illustration panel. The layout stays close to the existing flat list, so this is the lowest-risk way to add highly visible art.

Production model:

- Reusable ticket-row shell in Flutter.
- Live text for dates, titles, categories, references, and notes.
- Separate vignette slot resolved from destination plus booking type.
- Existing artwork can be cropped into the right-side panel; missing combinations can fall back to category art.

## 02 — Collectible Scenic Stamps

Each document uses a small illustrated postage stamp paired with a date postmark. This preserves the highest information density and gives the list a collectible travel-journal character.

Production model:

- Reusable paper-row, postmark, and perforated-stamp shells.
- Live text throughout.
- Square scenic stamp image resolved from destination plus booking type.
- A destination stamp near the title reflects the currently selected trip.

## 03 — Illustrated Destination Dossier

Documents are grouped into expandable trip folders. Each folder receives destination header artwork, and the open trip contains compact document slips with category-specific illustrated windows.

Production model:

- Reusable expandable dossier and document-slip components.
- Destination pack supplies the wide header image.
- Existing artwork resolver supplies the booking vignettes.
- Live text remains separate from imagery.
- Best suited to users with several trips, but it introduces the largest interaction and layout change.

## Recommendation

Start with **01 — Illustrated Ticket Ledger**. It gives the artwork enough space to feel exciting and theme-specific, reuses the existing list mental model, and maps cleanly onto the current art-resolver approach. A small destination stamp from concept 02 could be added later as a secondary accent.

## ImageGen brief used

The mockups were generated as high-fidelity portrait mobile UI concepts using the current Documents screen and Travary artwork as references. The prompts required warm ivory linen, navy editorial type, coral and teal accents, tactile paper construction, readable live UI text, separate replaceable image slots, the existing navigation structure, and no photorealism or scrapbook clutter.
