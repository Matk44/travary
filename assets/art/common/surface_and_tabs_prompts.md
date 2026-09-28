# Travary Woven Surface and Home Navigation Tabs

Generated with the built-in ImageGen workflow from the approved Travary Documents, Trips, and countdown screen references.

## `linen.png`

- Delivery: 1024 x 1024 opaque PNG.
- Purpose: seamless full-screen Flutter background tile.
- Prompt contract: warm ivory/cream fine open-weave linen-cotton; straight-on material scan; quiet beige warp and weft; subtle fibre irregularity; flat diffuse lighting; no gradient, vignette, folds, stains, objects, text, or UI.
- QA: inspected as a 2 x 2 repeat with no hard edge or obvious tile grid.

## `tab.png`

- Delivery: 720 x 1024 transparent PNG.
- Purpose: blank resting/unselected bottom-navigation shell.
- Prompt contract: warm near-white cotton-paper tab; softly rounded top corners; straight sides; bottom continues beneath the leather rail; subtle tactile edge and contact shadow; no icon or text.

## `tab_selected.png`

- Delivery: 720 x 1024 transparent PNG.
- Purpose: blank raised active-tab shell.
- Prompt contract: the same shell geometry in tactile deep petrol-teal cotton canvas; visibly elevated; no icon or text.

## `tab_add.png`

- Delivery: 720 x 1024 transparent PNG.
- Purpose: blank centre Add-tab shell.
- Prompt contract: the same shell geometry in warm sun-faded coral cotton canvas; gently elevated; no plus sign, icon, or text.

## Composition rule

Flutter places the generated raster shell as the material layer, then overlays the generated raster icon plus real label and hit target. Existing navy icons remain unchanged for cream resting tabs. Selected teal tabs use separate cream raster icon variants; do not flatten text or interaction into the shell assets.
