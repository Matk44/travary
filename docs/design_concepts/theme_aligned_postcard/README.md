# Theme-aligned Postcard Journey concepts

Generation mode: built-in ImageGen, reference-matched `ui-mockup` generation.

The implemented Today and Documents screenshots were treated as the strict
source of truth. The earlier scrapbook-style exploration is superseded by this
set.

## Corrected visual rules

- Flat warm ivory-beige page background with almost no visible texture.
- Existing navy serif/sans typography hierarchy and spacing.
- Large rounded cream cards with subtle cotton-paper grain and low shadows.
- Coral, sage and teal used as restrained accents rather than full surfaces.
- Destination imagery stays inside a controlled card region.
- Existing search, filters, navigation and raised selected-tab behaviour stay
  recognisable.
- No deckled or scalloped card edges, stamps, postmarks, wax, washi,
  paperclips, rotated layers, cords, scrapbook collage or script typography.

## Trips

Postcard Journey now means a simple rounded destination card with a 35/65
image-and-information split. The outer shape and material match the existing
room and reservation cards. A thin coral, sage or muted-grey state accent
distinguishes current, upcoming and past trips.

## Documents

This is a refinement of the implemented screen, not a redesign. Search and
filter shapes remain intact. Rows keep the existing date, icon and text rhythm,
with only subtle paper depth, softly tinted icon medallions, a fine sage rule
and a navy chevron.

## Alternate Today countdown

The countdown is a direct sibling of the existing room card: one horizontal
rounded cream object, live information on the left, destination scene on the
right, and the same deep-teal binding band. It appears only between trips; the
active-trip itinerary screen is unchanged.

## Production layering

The mockups are composition references. Final implementation should layer a
blank raster shell, destination scene artwork, live Flutter copy, semantic
icons and accessible hit targets. Destination names, dates, booking counts and
the countdown number must not be baked into reusable assets.
