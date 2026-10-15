# Top cities — Wave A delivery

Completed 13 October 2026: **10 cities, 60 final PNGs** from `docs/art_requests/GPT_TOP_CITIES_2026-10-13.md`.

[Review gallery](index.html) · [Overview](overview.png) · [Full prompts](generation.json) · [Validation](validation.json)

## Files

Each city folder below is under `art_packs/staging/` and contains all six files.

| City | Folder | Files |
|---|---|---|
| London | [london/](../london/) | 6 PNGs |
| Tokyo | [tokyo/](../tokyo/) | 6 PNGs |
| Bangkok | [bangkok/](../bangkok/) | 6 PNGs |
| Rome | [rome/](../rome/) | 6 PNGs |
| Barcelona | [barcelona/](../barcelona/) | 6 PNGs |
| Dubai | [dubai/](../dubai/) | 6 PNGs |
| Istanbul | [istanbul/](../istanbul/) | 6 PNGs |
| Amsterdam | [amsterdam/](../amsterdam/) | 6 PNGs |
| Hong Kong | [hong_kong/](../hong_kong/) | 6 PNGs |
| Seoul | [seoul/](../seoul/) | 6 PNGs |

| File in each city folder | Exact pixels | Alpha |
|---|---|---|
| `featured_ticket.png` | 1774 × 887 | Transparent outside original shell |
| `room_card.png` | 1774 × 887 | Transparent outside original shell |
| `reservation_card.png` | 1983 × 793 | Transparent outside original shell |
| `countdown_postcard.png` | 1122 × 1402 | Transparent outside paper/shadow |
| `trip_postcard.png` | 1536 × 1024 | Transparent outside paper/shadow |
| `documents_destination_stamp.png` | 1024 × 1280 | Transparent outside paper/shadow |

Every deliverable is RGBA8 PNG with an embedded sRGB profile. File hashes and checks are recorded in `validation.json` and the per-city validation files.

## Generation and export

Every illustration was made with the built-in imagegen tool. No CLI/API fallback, animation or video was used. The owner's earlier authorization of template compositing remains the basis of the card export workflow.

Cards start from `art_packs/prompts/city_card_references/`. The compositor retains original alpha, exterior/shadow pixels, notches, perforations, stub/barcode, cord, eyelet and protected paper. Generated city scenes are uniformly fitted to the illustration regions, with unprinted paper/ink extended to enforce the ticket's 42% and key card's 62% blank text boundaries. Existing stripe geometry is retained and recoloured; reservation tags are blank, without the template's flag.

Postcards retain generated paper edges and true alpha. A few nearly invisible alpha values of 4/255 or less are cleared during export; no colour-key background removal is used. All resizing is uniform, with centring/cropping where needed, never axis stretching.

The ten destination stamps use the original Paris stamp's paper, perforations and keyline, with its old illustration removed using native-scale copies of its own blank ivory paper. Each new generated illustration is uniformly fitted into the measured box `(123,115)-(901,947)`. The live label region `(123,986)-(901,1152)` stays exactly blank ivory from the shared stamp template. This avoids generating inconsistent stamp geometry and accidental text in labels.

London's portrait postcard received a targeted correction to remove tiny bridge flags. Its landscape received an alpha-focused edit. Seoul's featured ticket received a targeted correction to remove the small palace signboard. The original attempts and correction prompts remain in `records/`; the selected final PNGs are in the city folders.

## Checks and review

All 60 files pass exact canvas, RGBA, sRGB, real-alpha and transparent-corner checks. All 30 card alpha channels match their templates exactly, protected shell/exterior pixels match, and barcode stubs and brass eyelets are checked separately. All ten stamp label bands match the blank reference.

Generated subjects and final city contact sheets were visually inspected for coherent style, blank text areas, readable lettering, flags, logos, faces and excluded attractions. The gallery offers light/dark backgrounds; both per-city contact sheets are available alongside it.

To repeat all delivery checks and rebuild the gallery, run from the project root:

```sh
python3 art_packs/staging/top-cities-wave-a-2026-10-13/finalize.py
```

Only staging artwork and its generation/review records were created by this task. App integration, runtime asset changes, pack building and publishing were not performed. Unrelated ongoing working-tree changes were preserved.

## Handoff to Claude

The 60 Wave A PNGs are ready for review and developer integration. Follow the original guide's “After it's drawn” instructions: create each city pack using the country's palette, add the correct catalogue entry and destination slug, convert to WebP, and build one pack at a time. Run the relevant art-pack and visual checks. Publish only with the owner's go-ahead, as required by the guide.

Wave A covers London, Tokyo, Bangkok, Rome, Barcelona, Dubai, Istanbul, Amsterdam, Hong Kong and Seoul.

**Wave B remains:** Osaka, Venice, Lisbon, Madrid, Prague, Cancún, Kuala Lumpur, Antalya, Phuket, Milan and Taipei (66 further PNGs). No Wave B artwork was created in this Wave A delivery.
