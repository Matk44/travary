# Travary: Holiday Organiser

Add your bookings; Travary sorts them into days and opens each morning on what
you need right now, with tickets one tap away. Flutter (iOS + Android),
Firebase. Rebuilt from scratch in Sept 2026; the old app is archived in
`legacy_v0_2026-09-27.zip`. Product and pricing plan: `docs/PRODUCT_PLAN.md`.

## Principles

- **Super simple for the traveller.** Bookings first: no "create a trip"
  step. Trips form automatically from dates (`logic/trip_assignment.dart`).
  Only title + date are required on any form.
- **Today is the product.** Opens on today during a trip, else the first day of
  the next trip: greeting, featured ticket, the hotel's key card, the day's
  tagged cards, then the day's timeline. Past and future stay one tap away
  (swipe or tap "Day 3 of 7" for the day chooser, Trips, Documents).
  Between trips, when a destination postcard suits the next trip, Today
  counts down to it instead (`CountdownTripHero`: the postcard with a
  luggage tag hung on it, three facts, "View trip"). On the Trips tab a
  coming trip with a landscape postcard shows on it with the same tag
  (`UpcomingTripPostcard`); other rows stay plain.
- **Never lock someone's tickets.** Tickets and bookings are always reachable,
  offline, whatever their plan.
- **The look is swappable.** A unique hand-made interface ("travel ephemera":
  tickets, key cards, luggage tags, see the v1 mockup) goes on top of this
  build. Keep logic out of `design/` and styling out of `logic/`.

## Architecture

```
lib/
├── domain/     Plain data: Booking, BookingKind (+ KindSpec), Trip, LocalDate/ClockTime,
│               visual_profile (ExperienceTheme, ThemeSource, TripVisualProfile),
│               art_pack (selectors), country_codes (ISO allow-list),
│               palette (DestinationPalette + validation), weather (optional pill input)
├── logic/      Pure Dart rules, fully unit-tested:
│               day_plan (done/now/next), trip_plan (+ focus), trip_assignment,
│               card_text (all card wording), countdown_text (the countdown's
│               wording, calendar-date count), trip_postcard_text (a coming
│               trip's tag), formatters, art_pack_selection
│               (trust rules, pack ranks, downloads), visual_profile_request
│               (classifier payload, meaningful edits)
├── data/       TravelRepository interface; Memory (demo/tests) + Firestore;
│               demo_data; attachment_store (ticket files, offline);
│               visual_profile_service; art packs: art_pack_catalog (formats +
│               validation, shared with tool/), art_pack_archive (safe zip),
│               art_pack_store (disk), art_pack_service (download manager)
├── state/      TravelStore (ChangeNotifier): the single source of truth for screens;
│               ArtCatalogController (bundled + installed packs), VisualProfileCoordinator
├── design/     THE SKIN: tokens, trip_chrome (palette colours + chrome art), kind_style,
│               cards/ (BookingCard → FeaturedTicketCard / RoomKeyCard /
│               TaggedReservationCard on ShellFrame), art/ (catalog, resolver,
│               card_shells, art_slots), widgets/ (nav_bar, today_header, day_timeline,
│               countdown_trip_hero, upcoming_trip_postcard, fitted_place_name)
├── features/   Screens: today, trips, wallet (the "Documents" tab), booking (form/detail/viewer), profile
└── app/        bootstrap (backend choice), app, home_shell (tabs + add button)
tool/           art_packs.dart: builds, validates and publishes art packs (operator only)
art_packs/      pack sources (+ catalog.json once published)
rules-tests/    Firestore/Storage rules tests; test_emulator/: art-pack end to end
```

Dependencies flow downward only: `features → state → logic/data → domain`.
`design` may use `domain`/`logic` types; `logic` never imports Flutter UI.

### Rules that keep it reskinnable

1. Screens show bookings **only** through `BookingCard` (`hero` / `standard` /
   `compact`) and `OngoingStrip`. Never style a booking inline in a screen.
2. Cards receive **`CardText`** (already worded: eyebrow, title, when, detail,
   place, stub, reference) and **`ArtChoice`**. Cards never format dates or
   decide wording; add fields to `CardText` instead.
3. Artwork: `assets/art/<kind>/<theme>_<subject>_<nn>_<scene|vignette>.png`
   (brief and prompts: `docs/ART_BRIEF.md`); themes are `ExperienceTheme`
   wire names (`urban_heritage`), legacy `tropical`/`city`/`snow`/`classic`
   still load. A booking's **subject** ("pizza", "castle") comes from Smart
   Import (Gemini picks it: `artSubject`) or from keywords
   (`logic/art_subjects.dart`, mirrored in `functions/src/artSubjects.ts`;
   a test keeps them equal). Downloaded **art packs** add destination and
   experience art (`docs/ART_PACKS.md`). `ArtResolver` takes a
   `TripArtContext` and tries the subject from the city → region → country
   pack → the trip's look → secondary look → core, then generics, stable per
   booking and never repeating side by side. Pictures are `ArtImageRef`s
   (bundled or file); `ArtPanel` draws both and shows the placeholder if a
   file can't load. Featured cards use the scene, normal cards the vignette.
   Use `ArtChoice.variant % n` for non-image variety.
4. Cards are complete **raster shells** with live text on top, never
   drawn lookalikes. Next up (`CardShells.featuredFor`): flights on the
   `boarding_pass`, restaurants on `featured_reservation`, transport on
   `travel_ticket` (each shows the booking's scene through a transparent
   window, drawn beneath the shell), notes on `note_paper`, stays on the key
   card, everything else on the look's `featured_ticket`. In the day's list
   (`standardFor`): stays on the key card (`room_card`), notes on
   `note_paper`, everything else on a tagged reservation card (the look's
   complete `reservation_card`, else `reservation_card_blank` + the
   booking's vignette). A hire car in progress is on the `ongoing_tag`. `ShellResolver`
   (`design/art/card_shells.dart`) picks them by the same ranks as card art
   (packs, then bundled `<look>_<role>.png`, then a stand-in look); text,
   buttons and tag icons sit at measured fractional anchors (`ShellGeometry`),
   and shells are never stretched. Icons and interface surfaces (tabs, linen,
   leather, pill, stamp) resolve through `ArtSlots` (`design/art/art_slots.dart`).
   A missing file gets its documented stand-in; list every gap in
   `docs/ART_ASSET_GAPS.md`. The countdown postcard
   (`common/countdown_postcard`, `TravelStore.countdownPostcardFor`) and
   its landscape Trips companion (`common/trip_postcard`,
   `TravelStore.tripPostcardFor`) come only from a pack that suits the trip
   and are never bundled: no postcard, no countdown or postcard row, never
   another place's.
5. Colours and type live in `design/tokens.dart` only. A trip's interface
   colours come from its palette (`TravaryChrome.of(context).colors`: the
   best-ranked installed pack's `palette`, else Travary's own); chrome uses
   them, artwork is never tinted.

### Time model

Bookings use **floating local time** (the time printed on the ticket, no zone):
`LocalDate` + optional `ClockTime`. The phone adopts the destination's zone on
arrival, so comparing with the device clock is right during the trip. No start
time = all day. `endDate` after `startDate` = multi-day (check-in/out,
pick-up/drop-off, overnight flights): start and end appear as entries on their
days; days in between show an `OngoingStrip`.

### Data (Firestore)

```
trips/{tripId}                        title, theme, themeSource, ownerId, memberIds[], plannedStart/End,
                                      memberNames{}, invite{} (server-only), premium (server-only),
                                      visualProfile, visualProfileUpdatedAt, visualProfileRequest (server-only)
trips/{tripId}/bookings/{bookingId}   Booking.toJson() + a copy of the trip's memberIds[]
invites/{code}                        tripId, createdBy, expiresAt (server-only)
users/{uid}                           purchases + Smart Import / classification usage (server-only)
```

A trip's look: `themeSource` `auto` (the classifier's profile decides;
`Trip.effectiveTheme`) or `manual` (the traveller's chip; the server never
overwrites it). The app never writes `theme` for an automatic trip.

Built for family sharing (`memberIds`). Bookings load with one
collection-group query on `memberIds` (index in `firestore.indexes.json`), so
reads never look up the trip: a lookup fails for a trip created moments ago.
**When trip members change, update every booking's `memberIds` copy in the
same batch.** Rules are in `firestore.rules`; deploy rules + index with
`firebase deploy --only firestore` (`.firebaserc` targets `travary-444`).
Empty automatic trips remove themselves. Writes
aren't awaited (Firestore's offline cache applies them at once); sync failures
surface via `TravelRepository.errors`. Attachment files are stored locally by
file name (never absolute paths). Cloud backup of files is a future Plus feature.

## Running

| Mode | How | Data |
|---|---|---|
| Demo (default) | `flutter run` | Sample Orlando/Lake District/Paris trips built around today; resets on restart |
| Cloud | `flutter run --dart-define=TRAVARY_BACKEND=cloud` | Firestore + anonymous auth |
| Emulators | add `--dart-define=TRAVARY_EMULATOR_HOST=127.0.0.1` | Local Firebase emulators (`docs/ART_PACKS.md`) |

Cloud mode uses anonymous sign-in (enabled in the Firebase console for
`travary-444`); rules and index are deployed.

Design tools (debug builds, Profile tab): **Preview a different time** shows
cards before, during and after their time; **Reset sample trips**; **Card
gallery** (every kind and size per look, with the shells chosen).

The Today screen's target is `docs/reference/travary_today_reference.png`
(813 × 1933: a 390-point phone). `tool/visual_qa.sh` renders the canonical
fixture (`test/support/canonical_today.dart`) at that size with the app's
real fonts and writes `build/visual_qa/today_{actual,overlay,diff}.png`,
plus the countdown between trips (`test/support/countdown_today.dart`,
target `docs/mockups/today-empty/02-hanging-luggage-tag.png`) as
`countdown_actual.png` and `countdown_844_actual.png`, and the Trips tab's
coming trips (`test/support/trip_postcards.dart`, target
`docs/mockups/trips-postcards-v2/02-hanging-tag-postcards.png`) as
`trips_actual.png`.
Never edit the reference to make a comparison pass.

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
npm --prefix functions test
tool/run_emulator_tests.sh     # functions store, security rules, art packs end to end
tool/visual_qa.sh              # Today vs the reference image
flutter run
```

iOS minimum is 15.0 (Firebase SDK 12). If `pod install` crashes with an
encoding error, run it with `LANG=en_US.UTF-8`.

## Premium (Free / Trip Pass / Plus)

- Rules live in one pure class: `logic/access.dart` (`AccessPolicy`). Plus
  unlocks everything; a Trip Pass unlocks one trip until 7 days after it ends;
  a trip stamped `premium` by the server unlocks it for everyone on it ("Plus
  travels with the trip"); free gets 3 Smart Imports.
- **Gate every premium entry point with `requirePremium()`**
  (`features/premium/premium_gate.dart`): it returns the decision or opens
  the paywall. Never check entitlements ad hoc in a screen.
- **Never gate** a traveller's own bookings, tickets, Today or Wallet.
- `PremiumFeature.released` controls what the paywall sells; unreleased
  features only show (marked "soon") in debug builds.
- Purchases go through `PurchaseService`. Today it's `TestPurchaseService`
  (simulated, nothing charged; plan switcher in Profile → Design tools).
  RevenueCat replaces it in step 4.
- `Trip.premium` and `users/{uid}` are server-written only (rules enforce
  this); trip writes use merge so the app never clobbers `premium`.
- Prices and product IDs: `domain/pricing.dart` ($34.99/yr with a 14-day
  trial, $7.99 Trip Pass). Price wording: `logic/price_text.dart`.
- Funnel events: `state/analytics.dart` (`track()`), debug-print for now.

**Before launch (promises the paywall makes):** a day-12 trial reminder
notification, Terms and Privacy links on the paywall, analytics wired to a
real service, and a server function that mirrors purchases to `users/{uid}`
and stamps `premium` on trips.

## Family sharing and ticket backup

- **Invites**: callable `createTripInvite` gives a 6-character code (14 days,
  no 0/O/1/I/L); `joinTrip` adds the caller; `removeTripMember` removes
  someone (organiser) or yourself (leave). Max 6 people. All in
  `functions/src/sharing.ts`: only the server changes `memberIds`,
  `memberNames` and `invite`, and it updates every booking's `memberIds`
  copy in the same transaction. The app can't (rules).
- **UI**: trip screen "Who's coming" (invite, remove, leave), Trips →
  "Join a trip". Inviting is gated by `requirePremium(familySharing)`; the
  Plus check moves server-side with RevenueCat.
- **Tickets**: `Attachment.remotePath`; `TravelStore.syncTickets()` backs up
  tickets for shared or Plus trips and downloads the family's tickets for
  current/upcoming trips so they open offline. `TicketFileBuilder` fetches
  on demand. Files live at `trips/{tripId}/attachments/{fileName}` in Cloud
  Storage (bucket `travary-444.firebasestorage.app`, us-central1), guarded
  by `storage.rules` (members only, images/PDF, < 20 MB).
- Storage rules read Firestore, which needs the Storage service agent to have
  `roles/firebaserules.firestoreServiceAgent` (granted on travary-444). A
  new project needs it too, or every upload returns 403.
- Invite links are codes shared as text for now; universal/app links (hosting
  page that opens the app) come later.

## AI / Smart Import

AI features use **Google AI Studio (Gemini API)**, called only from Firebase
Cloud Functions with the key in Secret Manager (`GEMINI_API_KEY`), never from
the app. Project `travary-444` is on the Blaze plan.

- **Server** (`functions/`, TypeScript, Node 22): callable `smartImport`.
  Screenshot/photo/PDF → Gemini with a JSON schema → `normaliseBookings`
  validates everything → draft bookings. Models in `functions/.env`
  (`SMART_IMPORT_MODEL`, `SMART_IMPORT_FALLBACK_MODEL`); busy errors
  (429/500/503) retry, then fall back. Per-user daily cap. Logs never
  contain document contents.
- **Keep the response schema simple**: Gemini rejects schemas past a
  complexity limit (400 "invalid argument"). Enforce limits in
  `normaliseBookings` instead, with a test.
- **App**: `data/smart_import_service.dart` → `features/import/smart_import_screen.dart`.
  One draft opens the pre-filled form; several show as a review list.
  Dates/times and uncertain fields are always outlined for checking.
  Nothing is saved unchecked. The source file becomes the ticket.
- Build/test/deploy the server: `npm --prefix functions test`, then
  `firebase deploy --only functions`. Read logs with
  `gcloud logging read 'resource.labels.service_name="smartimport"' --project travary-444`
  (`firebase functions:log` lags).
- Trip grouping for imports: bookings from one file share a trip within
  30 days; a return flight ("Lisbon to London") joins the trip its outbound
  flight started.
- **Automatic looks** (`classifyTripVisuals`, `docs/VISUAL_PROFILES.md`):
  a separate Gemini call classifies a whole trip into an experience theme,
  setting, moods and destination, verified with Places Text Search (New)
  (`GOOGLE_MAPS_PLATFORM_KEY` secret). Cached by a source hash; one shared
  retry policy with Smart Import (`geminiRetry.ts`). Vocabulary lives in
  `functions/src/visualVocabulary.ts`, mirrored in
  `lib/domain/visual_profile.dart` (a test keeps them equal). Only place IDs
  and 30-day coordinates from Places are stored (Google's terms).

## Conventions

- snake_case files, PascalCase classes, `_private` members, `const` wherever possible.
- New booking wording → `logic/card_text.dart` with a test in `test/logic/`.
- New rule about time/trips → `logic/` with a unit test. Keep `logic/` pure.
- Dispose controllers/subscriptions; never use `context` in `dispose()`
  (keep a reference from `initState`).
- Layouts must survive long titles and small phones: tests run at iPhone size
  and fail on overflow.
- Never hardcode secret keys in the app; AI runs server-side (see AI).
- Mirrors kept equal by tests: art subjects, the visual vocabulary and ISO
  country list (Dart ↔ TypeScript), `appBuildNumber` ↔ pubspec's `+N`.
- The Firebase CLI shadows `node` inside `emulators:exec`; scripts use
  `$npm_node_execpath`.

## Roadmap

- **Now:** design phase (the graphic interface on top of this build).
- **v1.0 launch** (in this order): premium plumbing ✓ → Smart Import ✓
  (screenshot/PDF → Gemini in a Cloud Function → draft to confirm) → family
  sharing + ticket backup ✓ → RevenueCat + store products (+ server-side
  entitlements, trip premium stamping) → onboarding with the paywall.
  See `docs/PRODUCT_PLAN.md`.
- **Later:** flight alerts, Live Activity / widgets, email-forward import,
  memories and recap, referrals.
- Bundle ID is still `com.travary.travaryTemp`; change before release (needs
  new Firebase app registrations).
