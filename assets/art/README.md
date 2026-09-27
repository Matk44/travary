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
- **theme**: `classic`, `tropical`, `city`, `snow`, `countryside`, `themepark`, or `any`
- **subject**: from the vocabulary in `lib/logic/art_subjects.dart` (or `generic`)
- **format**: `scene` (1536×1024, left side calm) or `vignette` (1024×1024,
  transparent); leave off to use one image for both
- `common/`: textures and objects (`linen`, `paper`, `kraft`, `foil`,
  `leather`, `tag`, `stamp`, `tab`…) · `icons/`: kind and nav icons

A booking's subject comes from Smart Import (Gemini picks it) or from
keywords in its name. See the chosen picture for every kind in
**Profile → Design tools → Card gallery**.
