# Claude handoff: illustrated Documents tickets

> **Superseded:** do not implement this direction. The approved direction is
> now the collectible scenic-stamp ledger in
> `docs/CLAUDE_DOCUMENTS_STAMPS_HANDOFF.md`.

## Approved direction

Implement the Documents tab using the illustrated ticket-ledger concept in:

- `docs/mockups/documents-themed-v2/01-illustrated-ticket-ledger.png`

Preserve the current search, filters, chronological sections, booking actions,
semantics, offline behaviour, and bottom navigation. This is a visual restyle
of compact document rows, not a new information architecture.

## Production assets

### Reusable ticket shells

All three files are 1983 × 354 RGBA PNGs. The area outside the physical ticket
and the scenic window inside the right side are transparent.

- `assets/art/common/documents_ticket_01.png` — classic scalloped admission slip
- `assets/art/common/documents_ticket_02.png` — railway coupon with half-moon end notches
- `assets/art/common/documents_ticket_03.png` — quiet deckled voucher

Choose the shell deterministically with `art.variant % 3`; do not randomize on
rebuild. Approximate scene-window rectangles as fractions of the complete PNG:

| Shell | Left | Top | Right | Bottom |
| --- | ---: | ---: | ---: | ---: |
| 01 | 0.645 | 0.205 | 0.945 | 0.790 |
| 02 | 0.665 | 0.225 | 0.940 | 0.755 |
| 03 | 0.657 | 0.180 | 0.940 | 0.800 |

Render the booking scene underneath the shell and crop it with `BoxFit.cover`.
Render the shell over it so the paper lip, perforation, and edge treatment stay
crisp. Never place text inside the raster image.

### Scene mapping for the approved sample

The first three scenes already existed and should be reused. The last four are
newly generated for this screen.

| Document | Scene asset |
| --- | --- |
| Car hire | `assets/art/transport/any_car_01_scene.png` |
| Lagoon Resort | `assets/art/stay/tropical_resort_01_scene.png` |
| Sunshine Park | `assets/art/attraction/themepark_castle_01_scene.png` |
| Sunshine Terrace | `assets/art/dining/themepark_generic_02_scene.png` |
| Lagoon Grill | `assets/art/dining/themepark_grill_01_scene.png` |
| Fireworks from the beach | `assets/art/note/themepark_generic_01_scene.png` |
| Everglades airboat tour | `assets/art/activity/themepark_boat_01_scene.png` |

The new scene filenames follow the existing `ArtCatalog` contract and can be
resolved by `ArtResolver`. The Documents card should request the `scene`
format, not the transparent `vignette` format.

## Flutter layout contract

Add a Documents-specific compact ticket card rather than changing every
compact booking card globally unless visual QA confirms all other consumers.
The row remains one semantic button.

- Target visual aspect ratio: 1983 / 354 (about 5.60:1).
- Suggested rendered height: 88–96 logical pixels, responsive to available width.
- Date column: approximately 14% of the row width.
- Category medallion: approximately 8%, after the date divider.
- Live-copy area: approximately 37%; title is one line, metadata is one line.
- Scenic window: approximately 30%, using the per-shell rectangles above.
- Keep the existing kind icon and all text live, localized, accessible, and
  independent from the raster shell.
- Keep title ellipsis and metadata ellipsis. The scene must never squeeze the
  minimum text width below the current compact-card behaviour.
- Use the current `EntryStatus.done` opacity treatment for past documents.
- Keep `InkWell`, focus/hover colours, tap behaviour, ticket actions, and
  `Semantics` from the existing `BookingCard` path.

Prefer a small data object for the three shell geometries rather than scattered
magic numbers. Add a widget/golden test proving that each variant selects the
same stable booking, the scene appears beneath the transparent window, long
titles ellipsize, and missing art falls back without a black rectangle.

## Missing-art fallback

If no scene resolves, keep the ticket shell but fill its image window with the
current theme's calm teal/linen placeholder treatment and kind icon. Do not
hide the entire ticket and do not render transparent pixels as black.

## Asset-generation prompt summary

Built-in ImageGen was used. The ticket prompts specified isolated blank warm
ivory cotton-paper objects, 5.6:1 intent, genuine alpha outside and inside the
right scenic window, blank live-copy zones, and no embedded words, numbers,
icons, barcodes, or scenery. The scene prompts specified edge-to-edge 3:2
mid-century travel-poster illustrations with flat screen-printed shapes,
restrained risograph grain, deep petrol/navy, sage, cream and coral, composed
to survive a wide 1.8:1 centre crop.
