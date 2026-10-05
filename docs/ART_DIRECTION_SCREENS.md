# Trip, add and flight screens: art direction

**Chosen: C2, "refined ledger"** (October 2026). The reference mockup is in
`docs/mockups/trip-ledger-c2/01-refined-ledger.webp`: woven linen, travel
paper, and a clearer rhythm. It's a guide, not a pixel target: the build
follows it where it helps the traveller and departs where the app needs
more (gaps you can dismiss, who's coming, tickets on every row).

## The idea

**Every screen is a travel object you hold, not a form you fill in**, with
texture on the objects and calm chrome around them. That's the lesson of
the rejected "more tactile" round: no leather, wax seals or stamps
everywhere.

| Screen | Object | Built in |
|---|---|---|
| A trip | Its postcard with the luggage tag (name, dates, "6 days to go"), then "Your plan" as a ledger: a date column, the title and one line per booking | `features/trips/trip_screen.dart`, `design/widgets/trip_hero.dart`, `design/cards/ledger_row_card.dart` (`CardSize.ledger`) |
| What's missing | Dashed inset rows under the plan ("Stay needed · 13–16 Oct · 3 nights", "Flight home") with Add, and "Not needed" in their menu | `logic/trip_gaps.dart`, `design/widgets/plan_gap_row.dart` |
| Trip details | Paper panels: name and dates, who's coming, card style, Plus, delete or leave | `features/trips/trip_details_screen.dart` |
| Adding | "Add a booking": Snap a booking, four common kinds (the rest folded away), Passport & documents | `KindPickerSheet` in `features/booking/booking_actions.dart` |
| A booking's form | A paper ticket: a band in the trip's colour ("YOUR STAY") with the booking's picture, labels in small capitals over ruled lines, dates printed in boxes, "2 nights" between them, a perforation, then "More details" | `features/booking/edit_booking_screen.dart`, `design/widgets/paper_form.dart` |
| A new flight | A departures board: the flight number and date in white boxes, the found flight on split-flap tiles, its route, and "Use this flight" | `features/booking/flight_finder.dart`, `design/widgets/departure_board.dart` |
| A booking's page | Its card, live status on the same board, details on paper | `features/booking/booking_detail_screen.dart` |

One primary button everywhere: flat ink with ticket notches cut into each
end (`TicketButton`). Shared pieces live in `design/widgets/ledger.dart`.
The top bars keep their text to 1.3×, like iOS's own (`BarText`).

**Drawn, so nothing to make:** paper panels and rows, the date column, gap
rows, the form ticket and its notches, the perforation, the notched button,
the board, its rivets and flap tiles. They take the trip's palette (the
form's band is Japan's vermilion on a Japan trip).

## Images to make with GPT

Seven files, in order of how much they show. File names matter: drop each
into the folder named and the app uses it on the next build. No code is
needed (stand-ins are listed in `docs/ART_ASSET_GAPS.md`).

Paste the **Style block** from `docs/ART_BRIEF.md` before the illustration
prompts. Upload the C2 mockup and an approved postcard as references and
say *"same app, same style, same palette"*.

### 1. `assets/art/common/add_snap.png`: "Snap a booking"

> {Style block} Transparent background PNG, 768 × 768. A polaroid-style
> instant photo of a printed travel booking: a boarding pass and a hotel
> confirmation slightly overlapping inside the photo, its white border
> with a wider bottom edge, a small brass paperclip on the top edge, the
> photo slightly curled and rotated −6°, soft realistic contact shadow.
> Printed details are abstract lines and blocks only: no letters, numbers
> or logos. Centred with a sixth of the canvas empty on each side.

### 2. `assets/art/common/add_passport.png`: "Passport & documents"

> {Style block} Transparent background PNG, 768 × 768. A closed passport in
> deep navy #1C2A47 with a faded gold-foil emblem (an abstract globe, no
> words or national symbols) and slightly worn corners, rotated 4°, with a
> small cream insurance card peeking out from behind it. Soft realistic
> contact shadow. No letters, numbers or flags. Centred with a sixth of the
> canvas empty on each side.

### 3. `assets/art/common/trip_postcard_anywhere.png`: a trip's postcard with no place

The landscape companion to `countdown_postcard_anywhere` (open it as the
reference), for trips whose place has no postcard yet.

> {Style block} Transparent background PNG, 1536 × 1024, 3:2 landscape. A
> vintage travel postcard with a complete deckled cream paper border,
> lying flat, soft shadow, inside a transparent margin. The scene is the
> same as the reference portrait postcard, recomposed for landscape:
> place-neutral travel (sky, sea or hills, a small plane or sailboat), with
> **no landmark, flag or recognisable place**. Keep the upper-right quarter
> calm (sky): a luggage tag hangs there. No text, stamps or postmarks.

### 4–8. Icons: `assets/art/icons/{name}.png`

Batch 3's icon prompt from `docs/ART_BRIEF.md` (letterpress navy #1C2A47,
1024 × 1024, a quarter of the canvas empty on each side):

| File | {object} |
|---|---|
| `attach.png` | a paperclip |
| `invite.png` | a person with a small plus beside them |
| `clock.png` | a round clock face showing ten past ten |
| `passport.png` | a closed passport booklet |
| `look.png` | a postage stamp with a perforated edge |

The older gaps still open are `nav_wallet`, `nav_profile` and `nav_add`
(same prompt).

### Already done

- **The 25 country trip postcards** (`art_packs/generated/trip_postcards/`)
  are installed in their packs (`common/trip_postcard`, version 3) and
  built. Publishing them puts them on every country trip's header and
  Trips row.

### Next for the packs

- `documents_destination_stamp` for the 25 country packs (1024 × 1280),
  for the Documents heading. Only the 5 city and region packs have one.
