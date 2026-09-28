# Card artwork

Drop images into these folders and rebuild: they're matched to bookings
automatically. The full brief, with ready-to-paste GPT prompts, is in
`docs/ART_BRIEF.md`.

```
assets/art/<type>/<theme>_<subject>_<number>_<format>.png

dining/any_pizza_01_scene.png        a pizza scene for any trip (featured ticket)
dining/any_pizza_01_vignette.png     its corner decoration (normal cards)
attraction/themepark_castle_01.png   one image used for both formats
```

- **type**: `flight`, `stay`, `attraction`, `dining`, `transport`, `activity`, `event`, `note`
- **theme**: `classic_travel`, `coastal_resort`, `urban_modern`, `urban_heritage`, `alpine`,
  `countryside`, `outdoor_adventure`, `themepark`, `cruise`, `roadtrip`, `wellness_retreat`,
  or `any` (older names `classic`, `tropical`, `city`, `snow` still load)
- **subject**: from the vocabulary in `lib/logic/art_subjects.dart` (or `generic`)
- **format**: `scene` (1536×1024, left side calm) or `vignette` (1024×1024,
  transparent); leave off to use one image for both
- `common/`: card shells per look (`<look>_featured_ticket`, `_room_card`,
  `_reservation_card`, plus `reservation_card_blank`; see the brief) and
  interface surfaces (`linen`, `leather`, `tab`, `tab_selected`, `tab_add`,
  `pill`, `stamp`) · `icons/`: kind, nav, weather and timeline icons
- What's still missing, and what stands in: `docs/ART_ASSET_GAPS.md`

A booking's subject comes from Smart Import (Gemini picks it) or from
keywords in its name. This folder is the core art that ships with the app;
destination and extra experience art comes as downloadable art packs
(`docs/ART_PACKS.md`). See the chosen picture for every kind in
**Profile → Design tools → Card gallery**.
