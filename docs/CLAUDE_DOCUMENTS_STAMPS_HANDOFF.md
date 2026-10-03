# Claude handoff: collectible scenic-stamp Documents ledger

## Approved direction

Implement the Documents tab from:

- `docs/mockups/documents-themed-v2/02-collectible-scenic-stamps.png`
- `docs/mockups/documents-themed-v2/documents-stamps-production-preview.png`

This replaces the illustrated-ticket-ledger direction. Do not use
`documents_ticket_01.png`–`03.png` for this screen.

Preserve the current search, kind filters, chronological sections, booking
actions, offline behaviour, semantics, and bottom navigation. The row remains
a single accessible button.

## Assets and measured geometry

The exact prompt history, final sizes, alpha checks, and measured body/window
fractions are in:

- `docs/documents_stamps_prompts.md`

Shared row assets:

- `assets/art/common/documents_stamp_01.png`
- `assets/art/common/documents_stamp_02.png`
- `assets/art/common/documents_stamp_03.png`
- `assets/art/common/documents_postmark.png`
- `assets/art/common/documents_cancel_lines.png`

Kind icons:

- `assets/art/icons/stay.png`
- `assets/art/icons/attraction.png`
- `assets/art/icons/transport.png`
- `assets/art/icons/activity.png`
- `assets/art/icons/event.png`
- `assets/art/icons/note.png`
- Continue using the existing `flight.png` and `dining.png`.

Destination headers are supplied as
`common/documents_destination_stamp.png` in the Orlando, Lake District,
Kyoto, Paris, and Bali source packs. Add them to each pack manifest as a common
asset named `documents_destination_stamp`, size 1024 × 1280.

## Row composition

Draw the cream row card, chevron, live text, and small icon badge in Flutter.
Do not bake text or dates into raster assets.

1. Centre `documents_postmark.png` in the date area and draw the live day/month
   inside its empty centre.
2. Draw `documents_cancel_lines.png` independently, extending from the ring
   toward the scenic stamp. It may be faded or hidden without changing the ring.
3. Choose `documents_stamp_0N.png` deterministically with `art.variant % 3`.
4. Resolve the booking's normal `scene` through `ArtResolver` and crop it with
   `BoxFit.cover` beneath the selected stamp's measured transparent window.
5. Draw the stamp frame above the scene so perforations and keylines remain
   crisp.
6. Draw the booking-kind icon inside a separate small cream badge at the
   stamp's top-right corner.
7. Draw title, metadata, and chevron as live UI to the right.

Use a small typed geometry object for the three measured window rectangles;
do not scatter fractional literals through the widget tree.

The date/postmark group, stamp, copy, and chevron must shrink or rearrange
responsively without reducing the text column below its current usable width.
Keep title and metadata ellipsis behaviour. Preserve the existing past-entry
opacity treatment and all `InkWell`, focus, hover, and semantics behaviour.

## Destination header

Resolve `documents_destination_stamp` from the selected/current trip's own
destination pack. Draw the place name as live text in its blank ivory label
band. Never show a stamp from a different destination. If the trip has no
destination stamp, use a neutral composed fallback or omit the header stamp;
do not borrow another place's art.

## Missing-art fallback

If a booking scene is missing, retain the paper stamp frame and place the
theme's calm placeholder treatment inside its window. Never display black in
transparent areas and never hide the whole row.

## Tests and visual QA

- Test stable variant selection using `art.variant % 3`.
- Test that scenes sit beneath each measured transparent window.
- Test all eight booking-kind icons and fallback behaviour.
- Test long titles, text scaling, past opacity, semantics, and tap actions.
- Test destination-pack resolution and ensure cross-destination borrowing is
  impossible.
- Add a golden for an Orlando list matching the approved concept and a second
  golden on a different destination to prove the scene/header changes.
- Compare on both light and dark debug backdrops to catch alpha halos.
