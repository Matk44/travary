# Claude implementation prompt: Travary reference-exact visual build

Copy everything below this line into Claude from the repository root.

---

You are the lead Flutter and Firebase engineer for Travary. Work directly in
this existing repository and implement the finished product, not merely a
proposal or design plan.

## Mission

Construct Travary so its Today screen and home navigation reproduce the
canonical reference image at:

`docs/reference/travary_today_reference.png`

The reference is 813 × 1933 pixels. It is the required visual target, not a
loose mood board. Match its hierarchy, proportions, spacing, tactile depth,
paper/linen character, card order, typography, timeline placement, and raised
five-part navigation as closely as the supplied raster assets permit.

At the same time, finish integrating the visual-profile, Places verification,
downloadable art-pack, deterministic art-resolution, and destination-palette
contracts already documented and partly implemented in this repository.

Do not stop after analysis. Inspect, implement, test, render, compare, iterate,
and leave the working tree in a verified state.

## Read before changing code

Read these files completely and treat them as the project specification:

1. `CLAUDE.md`
2. `docs/ART_BRIEF.md`
3. `docs/VISUAL_PROFILE_API_HANDOFF.md`
4. `docs/VISUAL_PROFILES.md`
5. `docs/ART_PACKS.md`
6. `assets/art/README.md`
7. `assets/art/booking_art_prompts.md`
8. `assets/art/common/theme_anchor_prompts.md`
9. `assets/art/common/coastal_resort_prompts.md`

Then inspect the implementation before editing, especially:

- `lib/features/today/today_screen.dart`
- `lib/app/home_shell.dart`
- `lib/design/cards/booking_card.dart`
- `lib/design/cards/ongoing_strip.dart`
- `lib/design/cards/card_parts.dart`
- `lib/design/widgets/nav_bar.dart`
- `lib/design/widgets/day_strip.dart`
- `lib/design/art/art_catalog.dart`
- `lib/design/art/art_resolver.dart`
- `lib/design/tokens.dart`
- `lib/domain/art_pack.dart`
- `lib/domain/visual_profile.dart`
- `lib/logic/art_pack_selection.dart`
- `lib/data/art_pack_catalog.dart`
- `lib/data/art_pack_service.dart`
- `lib/state/art_catalog_controller.dart`
- `lib/state/visual_profile_coordinator.dart`
- `functions/src/classifyTripVisuals.ts` and its supporting files
- `tool/` and the art-pack tests

The visual-profile classifier, Places verification, safe pack download, and
art resolver already exist substantially. Audit them against the handoff and
extend them; do not create parallel replacements or rewrite working systems.

## Non-negotiable visual rule

Every visually distinctive object is a supplied raster asset. Flutter supplies
real text, responsive layout, semantics, focus states, hit targets, clipping,
masking, and interaction over those assets.

Do not recreate the reference using Flutter-drawn faux paper, linen, ticket
notches, tags, twine, foil, leather, stamps, barcodes, navigation tabs, travel
illustrations, gradients, or decorative icons. In final rendering paths,
remove or bypass the current `PhysicalShape`, `TicketClipper`, drawn
`LuggageTag`, `StubBarcode`, decorative `CustomPainter`, flat placeholder
shells, and Material-icon approximations wherever a corresponding raster asset
exists.

Do not bake dynamic user-facing text into images. All titles, times, room
numbers, labels, ticket actions, navigation labels, and accessibility content
remain real Flutter text and semantics.

Do not stretch an asset non-uniformly. Preserve aspect ratio and use fractional
overlay anchors derived from each asset. Use `AspectRatio`, `LayoutBuilder`,
`Stack`, `Positioned`, and clipping/masking as needed. Keep text zones clear.

## Existing raster assets to use

### Complete shell assets

Theme-park/sample anchors:

- `assets/art/common/featured_ticket.png`
- `assets/art/common/room_card.png`
- `assets/art/common/tag.png`
- `assets/art/common/reservation_card_blank.png`

Coastal resort:

- `assets/art/common/coastal_resort_featured_ticket.png`
- `assets/art/common/coastal_resort_room_card.png`
- `assets/art/common/coastal_resort_reservation_card.png`

Urban heritage:

- `assets/art/common/urban_heritage_featured_ticket.png`
- `assets/art/common/urban_heritage_room_card.png`
- `assets/art/common/urban_heritage_reservation_card.png`

Alpine (`ExperienceTheme.alpine`):

- `assets/art/common/alpine_adventure_featured_ticket.png`
- `assets/art/common/alpine_adventure_room_card.png`
- `assets/art/common/alpine_adventure_reservation_card.png`

Countryside (`ExperienceTheme.countryside`):

- `assets/art/common/countryside_escape_featured_ticket.png`
- `assets/art/common/countryside_escape_room_card.png`
- `assets/art/common/countryside_escape_reservation_card.png`

Build one typed shell resolver that maps `TripArtContext`,
`ExperienceTheme`, booking kind, and card role to the best bundled or
downloaded common asset. Explicitly map the filename aliases
`alpine_adventure → alpine` and `countryside_escape → countryside`. A matching
downloaded city/region/country pack common asset must be able to override the
bundled shell through `ArtCatalog.common(name, context: ...)`.

Suggested common keys are `featured_ticket`, `room_card`,
`reservation_card`, and `reservation_card_blank`; keep compatibility with the
existing bundled filenames through the resolver rather than renaming files
recklessly.

### Booking scenes and vignettes

Use the existing `ArtResolver` and its scene/vignette pairing:

- `flight/any_plane_01_*`
- `stay/tropical_resort_01_*`
- `attraction/themepark_castle_01_*`
- `dining/any_bistro_01_*`
- `transport/any_car_01_*`
- `activity/any_boat_01_*`
- `event/any_show_01_*`
- `note/any_generic_01_*`

Featured scenes are 1536 × 1024 with the left 40% reserved for text.
Vignettes are 1024 × 1024 transparent corner artwork. Never place a dark
rectangle behind a vignette or accidentally render transparency as black.

When a complete shell already contains its destination illustration, use it as
the final shell background and do not double-layer another scene over it.
Use the blank tagged reservation shell plus the resolved transparent vignette
for generic dining, car hire, transfers, activities, events, and notes when a
complete matching reservation shell is unavailable.

### Existing raster icons

Resolve icons through `ArtCatalog.icon(name, context: ...)` so installed packs
can override them:

- `assets/art/icons/flight.png`
- `assets/art/icons/dining.png`
- `assets/art/icons/nav_today.png`
- `assets/art/icons/nav_trips.png`

Use `Image`/`ImageIcon` with the correct bundled-or-file `ImageProvider`, not
hard-coded `AssetImage` assumptions.

## Missing-asset gate

Audit `assets/art/` before implementation. Some ART_BRIEF assets are not yet
present, including likely linen/paper/kraft/foil/leather textures, stamp and
tab shells, several booking-kind icons, `nav_wallet`, `nav_profile`,
`nav_add`, weather-pill treatment, and timeline progress marks.

Do not silently counterfeit a missing final raster with a hand-drawn Flutter
lookalike. Continue implementing the complete layout, responsive overlay
geometry, semantics, animation, resolver, and asset slots. Put any unavoidable
temporary fallback behind a single typed resolver and document every missing
filename in `docs/ART_ASSET_GAPS.md`, including:

- intended size/aspect ratio;
- where it appears;
- exact common/icon key;
- whether the temporary fallback is visible;
- what must be regenerated before pixel-perfect sign-off.

The application must remain functional while assets are missing, but the final
report must not call a fallback pixel-perfect.

## Required Today-screen composition

At the reference viewport, reproduce this exact vertical hierarchy:

1. Full-screen oatmeal linen background.
2. Header: large serif greeting at upper left; `Day N of M · Destination`
   directly beneath it; compact raised weather/info pill at upper right.
3. Large featured ticket with a live eyebrow, title, divider, time/detail,
   real `Show tickets` button, and live rotated stub label where applicable.
4. Large hotel room-card shell for the ongoing stay, with live `HOTEL`, hotel
   name, room number, and any small supporting label placed in its clear zone.
5. Upcoming standard reservation cards, each using the full raster card/tag
   shell, a real category icon placed on the blank tag, real category/title/
   time/detail text, and the correct right-hand vignette or baked illustration.
6. A horizontal itinerary timeline after the cards, matching the reference
   line, dots, and labels for that day’s significant entries.
7. Five-part bottom navigation: Today, Trips, central Add, Documents, Profile.
8. Navy leather/footer strip at the very bottom when the raster asset exists.

Do not show the current boxed day-chip strip or extra `Today`/`Still to come`
section headers in the canonical Today composition. Preserve day navigation
without visually diverging from the reference: support horizontal day swipe
and/or make the `Day N of M` subtitle open an accessible day chooser. The
itinerary timeline represents the selected day’s bookings; it is not the trip-
day picker.

The bottom navigation remains fixed while Today content scrolls if needed.
Respect device safe areas. The reference viewport should compose like the
reference; narrower or shorter phones may scroll rather than crush cards.

Visible navigation terminology must match the reference: display `Documents`
for the existing wallet/ticket repository tab while retaining its underlying
ticket functionality.

## Shell overlay geometry

Create role-specific widgets rather than one generic row that approximates
everything:

- `FeaturedTicketCard`: complete ticket raster plus live text/action overlays.
- `RoomKeyCard`: complete room-card raster plus live stay/room overlays.
- `TaggedReservationCard`: complete or blank tagged raster plus live icon,
  text, and optional vignette overlay.
- Keep a compact accessible fallback for completed items, but it must use
  raster icon/art when available.

Store overlay positions as documented fractional anchors or centralized design
tokens, never scattered magic numbers. Ensure long titles, text scaling, RTL
safety where practical, and 320/390/430 logical-pixel widths do not overflow.
Do not shrink body text below accessible sizes merely to force a match.

The reference fixture should show the equivalent of:

- Good morning
- Day 3 of 7 · Orlando
- 28° Sunny
- Magic Kingdom / park opens 9:00am / 2 tickets
- Disney’s Polynesian Resort / Room 2214
- Be Our Guest Restaurant / 12:30pm / Table for 4
- Ohana / 7:15pm

Use a dedicated design/golden fixture for this canonical content if shipping
demo data should remain generic. Do not corrupt production domain logic merely
to force screenshot text. Real app content must remain data-driven through
`CardText` and the existing booking/trip models.

Weather is not currently a complete product service. Model the pill as an
optional presentation input with the canonical fixture using `28° Sunny` and
a safe date/countdown fallback in real data. Do not add an unrequested paid
weather API.

## Home-navigation interaction

Implement the requested tactile pop transition:

- selected tab rises approximately 8–12 logical pixels;
- use a spring-like scale/translation and shadow response;
- selected raster tab/icon changes to the destination palette;
- adjacent tabs settle naturally without layout jump;
- central Add remains a coral raised tab;
- duration roughly 320–450 ms with an ease-out-back or spring curve;
- honor `MediaQuery.disableAnimations` and accessible reduced-motion settings;
- maintain at least 48 × 48 logical-pixel hit targets and correct selected
  semantics.

Do not use the current underline as the selected-state design.

## Visual-profile and API integration

Implement or verify every requirement in
`docs/VISUAL_PROFILE_API_HANDOFF.md`, but extend the existing system rather
than duplicating it.

Required invariants:

- Gemini classifies semantic experience theme, setting, moods, and location
  hints only.
- Places Text Search verifies location server-side.
- Gemini never returns asset filenames, pack IDs, or raw colours.
- Pack selection is deterministic and follows verified city → region → country
  → primary theme → secondary theme → bundled core.
- A traveller’s manually selected theme is never overwritten.
- Classification and pack failures are non-blocking and bundled art remains
  available offline.
- Downloaded common shells and icons participate in the same ranked context as
  scenes/vignettes.
- No itinerary content, evidence, ticket data, or personal information appears
  in logs.

### Destination palettes

The handoff now defines a palette in `pack.json`. Implement it end-to-end if
the current code does not yet support it:

- domain model and tolerant JSON parser;
- catalog/pack validation;
- archive validation;
- publisher/build tooling;
- installed-pack loading;
- ranked palette resolution;
- trip-level UI palette exposed to the design layer;
- tests in Dart and tooling.

Validate uppercase six-digit hex colours, documented keys only, two anchors,
two-to-four accents, all four UI tokens, no duplicates, and WCAG AA contrast
between `ui.primary` and `ui.onPrimary`. Missing palette metadata remains valid
for legacy packs and falls through to the next-ranked palette.

Use one resolved palette for the whole trip screen. Navy/warm cream are the
bundled anchors; destination packs may change accents based on landscape,
architecture, craft, season, or time of day. Never infer palettes from flags
and never sample raster pixels at runtime.

Apply the resolved `ui.primary`, `ui.secondary`, and `ui.highlight` tokens to
live UI accents such as the selected home tab, timeline, focus indicators, and
appropriate labels without tinting full-colour raster artwork.

Update `docs/ART_PACKS.md` and any source examples so the implemented pack
contract and documentation agree.

## Architecture constraints

Preserve the repository’s dependency direction and rules in `CLAUDE.md`:

- screens continue to receive booking text from `CardText`;
- booking/date wording stays in pure logic, not widgets;
- state and repositories remain the source of truth;
- `design/` remains the skin;
- no secrets or AI calls in Flutter;
- no direct client writes to server-owned visual-profile fields;
- existing ticket access, offline behavior, premium gates, family sharing,
  imports, and Firestore behavior must not regress.

Prefer small composable widgets and typed value objects. Do not create a giant
Today widget, duplicate art resolver, or one-off asset-path conditionals spread
across screens.

## Verification and visual QA

Add tests before declaring completion.

At minimum:

1. Unit tests for shell mapping and fallback order.
2. Unit tests for destination palette parsing, validation, ranking, legacy
   fallback, and contrast rejection.
3. Widget tests proving the canonical Today hierarchy and all real text.
4. Widget tests for raster asset use, missing-asset fallback isolation, tab
   semantics, tap behavior, and reduced motion.
5. Responsive widget tests at 320, 390, and 430 logical-pixel widths, with
   large text scale, asserting no overflow.
6. Existing functional tests updated only where the intentional UI contract
   changed; do not weaken their behavioral assertions.
7. A deterministic canonical rendering at the reference 813 × 1933 viewport.

Render a screenshot and compare it with
`docs/reference/travary_today_reference.png`. Produce temporary QA outputs
under `build/visual_qa/`:

- `today_actual.png`
- `today_overlay.png`
- `today_diff.png`

Inspect the overlay/diff and iterate on geometry, card scale, baseline
alignment, spacing, shadows, and navigation height. Do not update or replace
the reference image to make a mismatch pass. Do not claim an exact replica
without performing this comparison and reporting remaining visible
differences.

Run and pass:

- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `npm --prefix functions test`
- the relevant art-pack tool and emulator tests where the environment permits
  them

If an environment dependency prevents a test, report the exact command and
blocker; do not silently omit it.

## Required final response

When implementation and verification are complete, report:

- the outcome first;
- key files changed;
- which generated shells, icons, scenes, and vignettes are now used;
- visual-profile/API and destination-palette work completed;
- visual comparison result and remaining measurable differences;
- every still-missing raster asset from `docs/ART_ASSET_GAPS.md`;
- all commands run and whether they passed.

Do not return only a plan. Do not stop after a partial mock-up while safe,
in-scope implementation or verification work remains.
