# Key-card backdrop fix (14 October 2026)

Four Wave A/B key cards (`prague`, `barcelona`, `london`, `phuket`) were
delivered with stray speckle (Prague's a visible dithered strip) inside the
card's left 62%, which must stay blank for the app's text. Cause: in
`export_cards.cjs` the paper backdrop is read from the generated image's
x 430–700 (mirrored past x 1100), and those four generated images' scenery
begins to bleed in at about x 640.

`export_cards_clean_backdrop.cjs` is that script with the backdrop read from
x 430–630 only (two lines changed). Run against `fix_jobs.json` (the four
`room_card` jobs from the cities' `*-card-export.json`) it gave the masters
now in `art_packs/originals/<pack>/common/room_card.png`. Checked: alpha
unchanged, the picture and the left paper byte-identical, speckle 0.

    mkdir -p /tmp/fixroot/art_packs/prompts
    ln -s "$PWD/art_packs/prompts/city_card_references" /tmp/fixroot/art_packs/prompts/
    node art_packs/staging/key-card-backdrop-fix-2026-10-14/export_cards_clean_backdrop.cjs \
      /tmp/fixroot art_packs/staging/key-card-backdrop-fix-2026-10-14/fix_jobs.json

The PNGs in `art_packs/staging/<city>/` are untouched, as delivered.

## Full-height key cards (15 October 2026)

The first fix above kept the picture inside the strip right of x 1100 (the
"left 62% blank" rule), which shrank every generated picture to about 53% and
tucked it into the bottom-right corner (about 40% of the card's height; the
older Paris, Kyoto and country cards are about 78%). The owner chose the
picture as GPT drew it, **full height, at its own size and position** (it
begins at 40-48% of the width, with its own soft stippled edge).

`export_cards_full.cjs` is the same compositor with a `KEYCARD_FULL` mode: from
x 690 the generated image is laid straight onto the card (feathered in over 60
px, clean paper behind it), the card's alpha, outline, stripe geometry and left
paper untouched. `full_jobs.json` lists all 56 key cards (the 40 new ones from
their `normalised/` donors in the wave folders, and the 16 older US and Lake
District cards from their original generated images, copied here into
`donors/`; their provenance is in `art_packs/staging/wave1_generation.json`,
`wave2_generation.json` and `remaining-art-2026-10-13/`). Run it from the
repository root: the paths in `full_jobs.json` are relative to it.

    mkdir -p /tmp/fixroot/art_packs/prompts
    ln -s "$PWD/art_packs/prompts/city_card_references" /tmp/fixroot/art_packs/prompts/
    KEYCARD_FULL=1 KEYCARD_X0=690 KEYCARD_FEATHER=60 node \
      art_packs/staging/key-card-backdrop-fix-2026-10-14/export_cards_full.cjs \
      /tmp/fixroot art_packs/staging/key-card-backdrop-fix-2026-10-14/full_jobs.json

Checked on all 56: alpha unchanged, picture 67-79% of the card's height,
starting at 40-48%, nothing in the left 36% but paper (0 speckle). The text
zone runs to 60% of the width, so a very long hotel name can reach the
picture's soft edge, as on the Paris card.
