# Art pack sources

One folder per pack under `sources/` (`pack.json`, `catalog-entry.json`,
images). `catalog.json` appears here after the first `build` and is the
record of what's published: commit it with the sources.

`sources/seed_themepark` is a small theme-park pack made from the approved
sample icons, used by tests and local development.

How to author, build and publish: `docs/ART_PACKS.md`.

`pending/` holds finished art waiting for the complete pack it belongs to
(for now, the five countdown postcards). Nothing there is built or
published; move each file into its pack's source when that pack is made.
