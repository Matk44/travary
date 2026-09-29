# Trips postcard directions — round 2

Generated with the built-in ImageGen workflow using the approved Travary
Today, countdown and Postcard Journey references. These are composition
studies, not production UI assets.

## 01 — Split correspondence postcards

The clearest and most information-dense option. Every row reuses one
horizontal deckled postcard shell: resolved destination artwork occupies the
left panel and live Flutter copy occupies the quiet correspondence panel on
the right. A stamp shell, cancellation lines and chevron are reusable layers.

## 02 — Hanging-tag postcards

The most direct sibling of the approved Today countdown. Existing destination
postcards remain visually dominant while one compact blank luggage-tag shell
carries the live countdown, destination, dates, duration and booking count.
The tag may rotate slightly per card, but its geometry and text zones remain
fixed.

## 03 — Postcard pockets

The most tactile and collectible option. Each destination postcard slides
into the same cream travel-album pocket. The pocket front provides a stable,
responsive zone for live trip facts while the artwork can keep its natural
postcard crop.

## Production layering

Whichever direction is selected, keep these layers separate:

1. Existing destination postcard or destination-pack raster.
2. One reusable blank postcard, tag or pocket shell raster.
3. Optional reusable stamp, cord, eyelet and status-tab pieces.
4. Live Flutter text, semantic icons, hit targets and accessibility labels.

Do not generate a complete flattened raster for every trip. Resolve the
destination artwork with the existing ranked art catalog, and let Flutter
compose it with the shared shell and real trip data.
