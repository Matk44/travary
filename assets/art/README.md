# Card artwork

Drop images into these folders and they appear on cards automatically. No
code changes are needed, just a rebuild (a hot reload won't pick up new assets).

## Folders = booking kinds

| Folder        | Used for                               | Card shape         |
|---------------|----------------------------------------|--------------------|
| `flight/`     | Flights                                | Boarding pass      |
| `stay/`       | Hotels, rentals                        | Hotel key card     |
| `attraction/` | Theme parks, museums, tickets          | Admission ticket   |
| `dining/`     | Restaurants                            | Reservation card   |
| `transport/`  | Transfers, trains, car hire            | Travel ticket      |
| `activity/`   | Tours, experiences                     | Admission ticket   |
| `event/`      | Shows, concerts, sport                 | Admission ticket   |
| `note/`       | Reminders                              | Paper note         |
| `common/`     | Shared textures (e.g. `linen.png`)     | —                  |

## File names = trip themes

Start the file name with a trip theme, then anything you like:

```
dining/tropical_01.png
dining/tropical_02.png
dining/city_01.png
attraction/themepark_castle.png
stay/snow_chalet.png
```

Themes: `classic`, `tropical`, `city`, `snow`, `countryside`, `themepark`.
A file without a theme prefix counts as `classic`. A trip's theme is picked
on its Trip screen ("Card style").

## How artwork is chosen

- Each booking gets one image from its kind + theme, **chosen by its ID**, so
  it keeps the same picture on every device and every launch.
- Cards of the same kind next to each other never repeat an image.
- No image for that theme → `classic` → any theme → a drawn placeholder.
- More images per folder = more variety. 3–5 per kind/theme is plenty.

## Image specs

One image serves every card size. The hero card shows it full-bleed, and
smaller cards show the **right-hand side** of it.

- Landscape **1200 × 720 px** (5:3), PNG or WebP.
- Keep the **left 45% calm and plain**: text sits there on the big card.
- Put the subject (castle, palm, plate, plane) in the **right third**.
- No text or logos in the artwork; the app adds the words.
- Match the v1 mockup: cream / navy / coral / teal / sage, soft paper texture.

## Where it's wired up

- `lib/design/art/art_catalog.dart`: finds files by the naming rules above.
- `lib/design/art/art_resolver.dart`: picks one per booking.
- `lib/design/cards/`: draws the cards (restyle here).
