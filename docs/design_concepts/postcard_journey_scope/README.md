# Travary Postcard Journey — scoped screen concepts

Generation mode: built-in ImageGen, reference-matched `ui-mockup` generation
with targeted `precise-object-edit` corrections.

## Locked product states

- **Trips:** Postcard Journey is the selected visual direction.
- **Documents:** uses the same postal materials, but keeps rows deliberately
  slim and scannable.
- **Today while travelling:** remains the existing approved itinerary screen.
- **Today between trips:** switches to a destination-led hero and countdown.

## Trips

`trips_postcard_selected.png` uses a destination screen-print panel on the
left and quiet cream correspondence stock for live trip copy on the right.
Current, upcoming, and past states use a wax dot, clean future postcard, and
faded cancellation treatment respectively.

## Documents

`documents_postal_ledger.png` keeps the current search, filters, grouping, and
dense list. The search field becomes a postal-directory label, filters become
perforated stamp chips, and each document becomes a slim cream correspondence
slip. Dates use text-free postmark discs; category icons use miniature
single-ink stamps. Scenic illustrations are intentionally omitted from rows so
the screen remains fast to scan.

## Alternate Today countdowns

### 01 — Hero Postcard

One dominant destination postcard with the scenic illustration filling most
of the surface. A large scalloped postage stamp carries the countdown. A
single shallow action strip sits beneath it. This is the most direct and
eye-catching option.

### 02 — Split Postcard

A 62/38 postcard: destination artwork on the left and a structured countdown
panel on the right. A compact information strip and ticket-shaped `View trip`
button make it the most conventionally functional option.

### 03 — Postcard Stack

A slightly rotated scenic postcard overlaps a separate countdown card, held
with a brass paperclip and washi. This is the most tactile and playful option,
but also the busiest.

## Production-layer requirement

The mockups communicate composition only. Production must separate:

1. Destination scene raster from the installed destination/look pack.
2. Blank postcard, stamp, postmark, row, and button shells.
3. Live Flutter destination, date, booking, countdown, search, and action text.
4. Real semantic icons and accessible hit targets.

Never bake the destination name, dates, countdown number, search text, or
booking data into reusable shell assets.

## Shared prompt direction

Preserve the supplied screen hierarchy and Travary's woven linen, cream cotton
paper, navy typography, coral/teal/sage/mustard accents, risograph destination
art, deckled/perforated edges, aged brass, and raised selected navigation tab.
Avoid glassmorphism, gradients, stock photography, flags, people, logos,
watermarks, fake handwriting, and flat generic Material colour tiles.
