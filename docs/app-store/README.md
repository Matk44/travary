# Travary App Store listing draft

Prepared 16 October 2026. [Open the review](review.html), inspect the ten stills and select UK, Australian or US English for the metadata. Each field is also available as a plain `.txt` file under its locale folder and in [metadata.json](metadata.json).

The images are draft green-screen artwork, generated with built-in ImageGen using the supplied pack and Travi's passport-icon reference. [Exact prompts and generation record](../mockups/app-store-screenshots-v1/GENERATION_LOG.md). Artwork approval has not been recorded. No motion or store upload was performed.

[Listing decisions and capture plan](../APP_STORE_LISTING.md) records what remains: real app captures, compositing, final opaque iPhone exports at 1320 × 2868 and 1206 × 2622, and separate iPad screenshots for the current universal app. The review's source-layout mode shows design mockups, not release captures.

## Bundle

`output/app-store/travary-app-store-listing-draft-v1.zip` includes this metadata, review, still images, supplied references, prompt records and the branding files needed by the review. Extract it and open `docs/app-store/review.html`. Source renderer scripts and the original pack's relative stage/art paths are retained for use from the Travary project; the bundle does not include all runtime artwork or an app build.

## Validation

All 18 metadata text exports match the JSON and satisfy field character/UTF-8 byte limits. All ten selected stills are RGB and match the intended portrait aspect ratio to within 0.18%. The review's gallery/detail view and US/Australian locale switching were checked in the in-app browser. No native app code was changed; no app build or production-feature validation was run for this listing draft.
