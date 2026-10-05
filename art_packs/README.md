# Art pack sources

One folder per pack under `sources/` (`pack.json`, `catalog-entry.json`,
images). `catalog.json` appears here after the first `build` and is the
record of what's published: commit it with the sources.

`sources/seed_themepark` is a small theme-park pack made from the approved
sample icons, used by tests and local development.

How to author, build and publish: `docs/ART_PACKS.md`.

Onboarding destination stages have a separate [expansion guide](../docs/ONBOARDING_DESTINATION_ART.md)
and [asset register](../docs/onboarding/DESTINATION_ART_REGISTER.md). Reuse the approved clean
stage template and the destination's own references; log each needed stage there. The proposed
`onboarding_stage` key is not yet integrated or published. New onboarding masters remain in
`pending/onboarding/<destination-id>/` until a deliberate app/pack integration task.

The five portrait countdown postcards, their five landscape Trips
companions and the five Documents destination stamps live in complete city
or region sources alongside the full contents of their corresponding
country pack. `pending/` is reserved for
finished art that does not yet have a complete pack and is never built or
published.
