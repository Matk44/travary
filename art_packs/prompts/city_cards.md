# City and region card art (ChatGPT)

## Status (11 October 2026)

Waves 1 and 2 are drawn (`art_packs/staging/<folder>/`, with the generation and
validation records beside them) and integrated as packs: see "City and region
cards (United States)" in `docs/ART_PACKS.md`. Built into the catalog, not yet
published. The Lake District is still to do; San Francisco uses California's.

## The message to send

> Make city and region card art for my travel app. Everything is in
> `art_packs/prompts/city_cards.md`: read it first, then work through the
> places in "Wave 1". For each place, take the three template cards in
> `art_packs/prompts/city_card_references/` and make a new version of each
> for that place, following the rules in that file. Save them as PNGs in
> `art_packs/staging/<folder>/` named `featured_ticket.png`, `room_card.png`
> and `reservation_card.png`. Tell me when a place is done.

## Rules for every card

Each template is a finished card. The new one keeps everything except the
picture, because the app prints live text in the blank areas and skips a
card whose shape has changed (it then shows the country's card instead).

- Same canvas size as its template (ticket and key card 1774 × 887,
  reservation card 1983 × 793) and a transparent background.
- The outline, corners, shadow, paper texture, notches, perforations,
  barcode stub, cord, brass grommet and tag stay exactly where they are.
- Every blank area stays blank: the ticket's left 42% (plain navy), the key
  card's left 62% (ivory paper), the middle of the reservation card.
- Only the illustrated scene changes, inside the area it fills now, plus the
  thin decorative stripe and the tag, recoloured to the place.
- **Ticket:** the scene flows out of the navy panel towards the barcode stub.
- **Key card:** the view from a hotel window, fading softly into the paper
  on its left edge.
- **Reservation card:** only the small framed picture at the far right.
- Style: mid-century travel poster, screen-printed. Flat layered shapes,
  fine paper grain, warm low sun, the same palette family as the template.
  Not photographic.
- Use each place's famous landmarks freely: they give it its character.
  Leave out only theme-park attractions (Disney and Universal castles, rides
  and characters), the Hollywood sign, the Space Needle, Chicago's Cloud
  Gate sculpture and casino buildings. Big buildings sit within the skyline
  rather than as the single hero.
- Nothing readable anywhere: no text, letters, numbers, signs, logos or
  flags. No recognisable faces.

## Places

Wave 1 covers most American holidays. Regions cover every city in them
unless that city has its own pack (Orlando's beats Florida's).

| Place (folder) | Kind | Colours | Ticket scene | Window view | Vignette |
|---|---|---|---|---|---|
| Orlando (`orlando`) | city | lagoon teal, sunset coral, palm green, gold | an original fairy-tale castle (not any park's) on a palm-lined lake under fireworks, Lake Eola's fountain, a rocket rising from the Space Coast | resort pool and palms, fireworks far off over the lake | airboat and alligator among cypress, or the Lake Eola fountain at dusk |
| Florida (`florida`) | region | sea turquoise, flamingo pink, sand, palm green | Miami Beach's art deco hotels, the Seven Mile Bridge over turquoise water, a lighthouse, pelicans | turquoise sea, white sand and a striped lifeguard hut | lifeguard hut, palms and a flamingo |
| New York (`new_york`) | city | taxi yellow, brick red, steel blue, navy | the Manhattan skyline, the Brooklyn Bridge, the Statue of Liberty in the harbour, the Flatiron Building, autumn in Central Park | brownstone rooftops, a wooden water tower and the skyline beyond | the Brooklyn Bridge with the skyline behind |
| Las Vegas (`las_vegas`) | city | neon pink, desert gold, dusk violet, teal | the Strip glowing at dusk (neon without words), the diamond-shaped welcome sign without lettering, dancing fountains, Red Rock Canyon | desert mountains at sunset over glittering lights | the welcome sign's shape against red rocks |
| California (`california`) | region | Pacific blue, poppy orange, sand, eucalyptus green | the Golden Gate Bridge, Big Sur's Bixby Bridge on the coast road, a pier with a Ferris wheel, Half Dome above a valley | palm trees and a pier on the Pacific at sunset | a cable car, or the pier and Ferris wheel |
| Hawaii (`hawaii`) | region | lagoon blue, hibiscus red, volcanic green, gold | Diamond Head above Waikiki, an outrigger canoe, surfers, the Na Pali cliffs | Waikiki beach, palms and Diamond Head | outrigger canoe, palms and hibiscus |

Wave 2, when wave 1 is in:

| Place (folder) | Kind | Ticket scene, window view, vignette |
|---|---|---|
| Washington DC (`washington_dc`) | city | the Capitol, the Washington Monument, the Lincoln Memorial, cherry blossom round the Tidal Basin |
| Chicago (`chicago`) | city | the skyline with Willis Tower, river bridges, the elevated train, Buckingham Fountain, the Navy Pier wheel (not Cloud Gate) |
| Boston (`boston`) | city | the Old North Church steeple, the Zakim Bridge, brownstones, a tall ship in the harbour, autumn leaves |
| New Orleans (`new_orleans`) | city | St. Louis Cathedral, French Quarter iron balconies, a green streetcar, a paddle steamer on the Mississippi |
| Nashville (`nashville`) | city | Broadway's neon at dusk without words, a guitar, the pedestrian bridge over the Cumberland, the skyline |
| Seattle (`seattle`) | city | Mount Rainier over the sound, green-and-white ferries, the waterfront market, the skyline (no Space Needle) |
| Arizona (`arizona`) | region | the Grand Canyon at sunset, Horseshoe Bend, saguaro cacti, an empty desert road |
| Alaska (`alaska`) | region | Denali, a glacier meeting the fjord, a cruise ship, a bald eagle |

San Francisco needs nothing: the United States cards already show it.

Outside the US, the Lake District's cards are still London's (Big Ben).
Its templates are the United Kingdom cards in
`art_packs/sources/country_gb/common/` (`featured_ticket.webp`,
`room_card.webp`, `reservation_card.webp`), saved to
`art_packs/staging/lake_district/`: lakes and fells, a stone cottage, a
wooden rowing boat, drystone walls, sheep.
