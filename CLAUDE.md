# Travary: Holiday Organiser

Add your bookings; Travary sorts them into days and opens each morning on what
you need right now, with tickets one tap away. Flutter (iOS + Android),
Firebase. Rebuilt from scratch in Sept 2026; the old app is archived in
`legacy_v0_2026-09-27.zip`. Product and pricing plan: `docs/PRODUCT_PLAN.md`.

## Principles

- **Super simple for the traveller.** Bookings first: creating a trip is
  never required. Trips form automatically from dates
  (`logic/trip_assignment.dart`). "New trip" (Trips tab pill, the empty
  Today and Trips screens) can start one first with a name and dates
  (`features/trips/trip_details_sheet.dart`, also editing a trip: tap its
  tag or "Trip details"); its
  planned dates keep it when empty, widen it, but never cut a booking out.
  The destination is read from the name as it's typed ("Japan holiday",
  "Disney World") by `logic/destinations.dart`: every country plus
  well-known regions and cities, offline, with suggestions for a half-typed
  place and a picker; never required (a "Grandma's" trip is left to the
  classifier and its bookings). Trips started by a booking get the same
  detection from their suggested name. Only title + date are required on
  any form.
- **Today is the product.** Opens on today during a trip, else the first day of
  the next trip: the greeting, then the day's cards down a time rail (each
  timed card's time and a dot on its left, joined by a line): the featured
  ticket in its place in time, the hotel's key card after it, the day's
  tagged cards; finished ones fold under "Earlier" (`logic/day_layout.dart`,
  mockup `docs/mockups/today-time-rail/01-left-time-rail.webp`). Past and
  future stay one tap away (swipe, or tap the date pill or "Day 3 of 7" for
  the trip calendar; Trips, Documents).
  Between trips, Today counts down to the next trip instead
  (`CountdownTripHero`: its destination's postcard, else the neutral one,
  as large as the screen allows, with a luggage tag over its lower right
  corner, about half of it below the card; tapping
  it opens the trip). Each time Today comes into view (its tab, back from
  the background, a screen closed over it: `HomeShell` ticks `shown`) the
  postcard lifts in and the tag is slapped on, swings and settles. On the Trips tab a
  coming trip with a landscape postcard shows on it with the same tag
  (`UpcomingTripPostcard`); other rows stay plain.
- **Inside a trip** (C2 "refined ledger", `docs/ART_DIRECTION_SCREENS.md`,
  mockup `docs/mockups/trip-ledger-c2/`): its postcard with the luggage tag,
  "Your plan" as ledger rows by date (`CardSize.ledger`, tickets on the
  row), what it still needs as dashed rows with Add and "Not needed"
  (`logic/trip_gaps.dart`), who's coming, and a notched "Add a booking".
  The trip itself (name, dates, family, card style, delete) is under "Trip
  details". Forms are a paper ticket in the trip's colours; a new flight
  starts on the departures board (`FlightFinder`) when flight data is on.
- **Never lock someone's tickets.** Tickets and bookings are always reachable,
  offline, whatever their plan.
- **Travel documents stay on the phone.** Passports, visas, insurance and
  the like (`TravelDocument`) are personal, not bookings: they belong to a
  person, not a trip. Stored only on this phone (`LocalTravelDocumentRepository`,
  the app's private support folder), behind the phone's own lock
  (`DocumentLock`: Face ID, fingerprint or passcode), and locked again
  whenever the app goes to the background (`HomeShell`). Never written to
  Firestore or Storage, never sent to Smart Import or Gemini, never shared
  with a trip's family (only "Send a copy", asked first), never logged
  (analytics carry the type only), never gated by a plan. Numbers stay
  masked until asked; the number field never lets the keyboard learn.
  Expiry checks against the next trip (`logic/travel_documents.dart`:
  passports need 6 months left after it). Ways in: the "Travel documents"
  pill leading the Documents tab's chips (a count, never contents), the +
  sheet's "Passport, visa or insurance" row, and Profile.
- **The look is swappable.** A unique hand-made interface ("travel ephemera":
  tickets, key cards, luggage tags, see the v1 mockup) goes on top of this
  build. Keep logic out of `design/` and styling out of `logic/`.

## Architecture

```
lib/
├── domain/     Plain data: Booking, BookingKind (+ KindSpec), Trip, LocalDate/ClockTime,
│               visual_profile (ExperienceTheme, ThemeSource, TripVisualProfile),
│               art_pack (selectors), country_codes (ISO allow-list),
│               palette (DestinationPalette + validation), weather (optional pill input),
│               travel_document (passports etc.: on this phone only)
├── logic/      Pure Dart rules, fully unit-tested:
│               day_plan (done/now/next), day_layout (Today's rows and time rail),
│               trip_plan (+ focus), trip_calendar (the calendar's weeks), trip_assignment,
│               destinations (places a trip's name can mean: detection, suggestions, picker),
│               travel_documents (expiry checks against the next trip, masking, wording),
│               flight_status_text (when live flight status shows, its wording),
│               flight_fill (a found flight → the add-flight form, board wording),
│               trip_gaps (what a trip still needs: nights without a stay, the
│               flight home), trip_hero_text (a trip's tag), booking_form_text,
│               card_text (all card wording), countdown_text (the countdown's
│               wording, calendar-date count), trip_postcard_text (a coming
│               trip's tag), formatters, art_pack_selection
│               (trust rules, pack ranks, downloads), visual_profile_request
│               (classifier payload, meaningful edits)
├── data/       TravelRepository interface; Memory (demo/tests) + Firestore;
│               demo_data; attachment_store (ticket files, offline);
│               visual_profile_service; art packs: art_pack_catalog (formats +
│               validation, shared with tool/), art_pack_archive (safe zip),
│               art_pack_store (disk), art_pack_service (download manager);
│               travel_document_repository (local only) + document_lock (local_auth);
│               auth_service (guest, Apple/Google sign-in, delete account)
├── state/      TravelStore (ChangeNotifier): the single source of truth for screens;
│               ArtCatalogController (bundled + installed packs), VisualProfileCoordinator,
│               TravelDocumentsStore (documents + lock), AppSession (account + uid)
├── design/     THE SKIN: tokens, trip_chrome (palette colours + chrome art), kind_style,
│               cards/ (BookingCard → FeaturedTicketCard / RoomKeyCard /
│               TaggedReservationCard on ShellFrame, DocumentStampCard, LedgerRowCard),
│               art/ (catalog, resolver, document_stamps,
│               card_shells, art_slots), widgets/ (nav_bar, today_header, time_rail, trip_calendar,
│               countdown_trip_hero, upcoming_trip_postcard, fitted_place_name,
│               the C2 ledger look: ledger (paper panels, rows, TicketButton, linen),
│               trip_hero, plan_gap_row, paper_form (form ticket, fields, date boxes),
│               departure_board (board, split-flap tiles))
├── features/   Screens: today, trips (trip, trip details), wallet (the "Documents" tab),
│               booking (form, flight finder, detail, viewer), profile,
│               travel_documents (list, form, document, the tab's entry pill),
│               account (Profile's sign-in card)
└── app/        bootstrap (backend choice), app, home_shell (tab pages + add button)
tool/           art_packs.dart: builds, validates and publishes art packs (operator only)
art_packs/      pack sources (+ catalog.json once published)
rules-tests/    Firestore/Storage rules tests; test_emulator/: art-pack end to end
```

Dependencies flow downward only: `features → state → logic/data → domain`.
`design` may use `domain`/`logic` types; `logic` never imports Flutter UI.

### Rules that keep it reskinnable

1. Screens show bookings **only** through `BookingCard` (`hero` / `standard` /
   `compact` / `document` / `ledger`) and `OngoingStrip`. Never style a
   booking inline in a screen.
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
   experience art (`docs/ART_PACKS.md`; sources are WebP, converted with
   `dart run tool/art_packs.dart webp`, PNG masters in `art_packs/originals/`;
   30 destination packs are published). `ArtResolver` takes a
   `TripArtContext` and tries the subject from the city → region → country
   pack → the trip's look → secondary look → core, then generics, stable per
   booking and never repeating side by side. Pictures are `ArtImageRef`s
   (bundled or file); `ArtPanel` draws both and shows the placeholder if a
   file can't load. Featured cards and Documents use the scene, normal
   cards the vignette; each format is picked separately by those ranks, so
   a picture drawn only as a scene never fills a vignette's place (the
   best vignette stands in). Use `ArtChoice.variant % n` for non-image
   variety.
4. Cards are complete **raster shells** with live text on top, never
   drawn lookalikes. Next up (`CardShells.featuredFor`): flights on the
   `boarding_pass`, restaurants on `featured_reservation`, transport on
   `travel_ticket` (each shows the booking's scene through a transparent
   window, drawn beneath the shell), notes on `note_paper`, stays on the key
   card, everything else on the look's `featured_ticket`. In the day's list
   (`standardFor`): stays on the key card (`room_card`), notes on
   `note_paper`, everything else on a tagged reservation card (the look's
   complete `reservation_card`, else `reservation_card_blank` + the
   booking's vignette). A hire car in progress is on the `ongoing_tag`. In
   the Documents list (`CardSize.document`, `DocumentStampCard`): a paper
   row drawn in Flutter with the live date in the `documents_postmark`
   ring, its `documents_cancel_lines`, and one of three stamp frames
   (`documents_stamp_01`–`03`, `StampDesign.forVariant` = `variant % 3`)
   over the booking's scene, which is cropped under the frame's measured
   window (`StampGeometry`); the kind's icon sits on a small badge. The
   heading shows the focused trip's `documents_destination_stamp`, only
   ever from its own verified city, region or country pack
   (`TravelStore.destinationStampFor`), the place name live. `ShellResolver`
   (`design/art/card_shells.dart`) picks them by the same ranks as card art
   (packs, then bundled `<look>_<role>.png`, then a stand-in look); text,
   buttons and tag icons sit at measured fractional anchors (`ShellGeometry`),
   and shells are never stretched. Icons and interface surfaces (tabs, linen,
   leather, pill, stamp) resolve through `ArtSlots` (`design/art/art_slots.dart`).
   A missing file gets its documented stand-in; list every gap in
   `docs/ART_ASSET_GAPS.md`. The countdown postcard
   (`common/countdown_postcard`, `TravelStore.countdownPostcardFor`) and
   its landscape Trips companion (`common/trip_postcard`,
   `TravelStore.tripPostcardFor`) come only from a pack that suits the trip,
   never another place's. When the next trip's place has none, Today counts
   down on the bundled, place-neutral `countdown_postcard_anywhere`
   (`TravelStore.neutralCountdownPostcard`); the Trips tab keeps that trip's
   plain row. A trip's own screen (`TripHero`) shows its `trip_postcard`,
   else its countdown postcard cropped to landscape, and only for a trip
   with no place art the bundled `trip_postcard_anywhere`
   (`TravelStore.neutralTripPostcard`). Prompts for new destinations: `art_packs/prompts/postcards.md`.
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
trips/{tripId}                        title, theme, themeSource, destination, ownerId, memberIds[], plannedStart/End,
                                      hiddenGaps[] (plan gaps marked "Not needed", for everyone),
                                      memberNames{}, invite{} (server-only), premium (server-only),
                                      visualProfile, visualProfileUpdatedAt, visualProfileRequest (server-only)
trips/{tripId}/bookings/{bookingId}   Booking.toJson() + a copy of the trip's memberIds[]
invites/{code}                        tripId, createdBy, expiresAt (server-only)
users/{uid}                           purchases + Smart Import / classification usage (server-only)
```

A trip's look: `themeSource` `auto` (the classifier's profile decides;
`Trip.effectiveTheme`) or `manual` (the traveller's chip; the server never
overwrites it). The app never writes `theme` for an automatic trip. Its
place: `destination` (app-written, `TripDestination`: country code, names,
art-pack slugs) when the traveller set or confirmed one, else the
classifier's location (`Trip.effectiveLocation`). The traveller's counts as
verified for place art (postcards, stamps, destination packs).

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
| Cloud (default) | `flutter run` | Firestore, real trips: a guest account until the traveller signs in |
| Demo | `flutter run --dart-define=TRAVARY_BACKEND=demo` | Sample Orlando/Lake District/Paris trips built around today; resets on restart |
| Emulators | add `--dart-define=TRAVARY_EMULATOR_HOST=127.0.0.1` | Local Firebase emulators (`docs/ART_PACKS.md`) |

Cloud mode starts as an anonymous guest (enabled in the Firebase console for
`travary-444`); rules and index are deployed. Sign in with Apple or Google
works only in cloud mode (see Accounts).

Design tools (debug builds, Profile tab): **Preview a different time** shows
cards before, during and after their time; **Reset sample trips**; **Card
gallery** (every kind and size per look, with the shells chosen).

The Today screen's target is `docs/reference/travary_today_reference.png`
(813 × 1933: a 390-point phone). It predates the time rail: its cards are
full width with the timeline under them, so card positions and sizes now
differ from it by design (the rail's own mockup is in
`docs/mockups/today-time-rail/`). `tool/visual_qa.sh` renders the canonical
fixture (`test/support/canonical_today.dart`) at that size with the app's
real fonts and writes `build/visual_qa/today_{actual,overlay,diff}.png`,
plus the countdown between trips (`test/support/countdown_today.dart`,
target `docs/mockups/today-empty/02-hanging-luggage-tag.png`) as
`countdown_actual.png` and `countdown_844_actual.png`, the Trips tab's
coming trips (`test/support/trip_postcards.dart`, target
`docs/mockups/trips-postcards-v2/02-hanging-tag-postcards.png`) as
`trips_actual.png`, and the Documents tab's stamps on the demo data
(`test/support/documents_stamps.dart`, target
`docs/mockups/documents-themed-v2/02-collectible-scenic-stamps.png`) as
`documents_actual.png` (Orlando), `documents_lakes_actual.png` (the Lake
District) and `documents_halo_{light,dark}.png` (rows on light and dark
backdrops, to catch alpha halos). The same two lists are goldens in
`test/widget/goldens/` (test font; update with `--update-goldens`).
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
encoding error, run it with `LANG=en_US.UTF-8`. The travel documents' lock
(`local_auth`) needs `NSFaceIDUsageDescription` (Info.plist), a
`FlutterFragmentActivity` (Android `MainActivity`) and an AppCompat
`LaunchTheme`. On the simulator, enrol Face ID with
`xcrun simctl spawn booted notifyutil -s com.apple.BiometricKit.enrollmentChanged 1`
(then `-p` the same name) and match with
`xcrun simctl spawn booted notifyutil -p com.apple.BiometricKit_Sim.pearl.match`.

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
- Prices and product IDs: `domain/pricing.dart` ($34.99/yr, $7.99 Trip
  Pass). Price wording: `logic/price_text.dart`.
- **No free trial, and no trial reminders.** Premium sells itself at the
  moment it's needed (sharing with family, Smart Import, never missing
  anything), never with a trial or a countdown to a charge.
- Funnel events: `state/analytics.dart` (`track()`), debug-print for now.

**Before launch:** Terms and Privacy links on the paywall, analytics wired
to a real service, and a server function that mirrors purchases to
`users/{uid}` and stamps `premium` on trips.

## Accounts (Sign in with Apple / Google)

- Everyone starts as an anonymous **guest**; Profile's `AccountCard`
  (`features/account/`) offers "Continue with Apple" / "Continue with
  Google" (the platform's own first). Signing in **links** the guest, so
  the uid and every trip stay as they are. Never required.
- If that Apple/Google login already has an account (another phone), the
  app switches to it and calls `adoptGuestTrips` with the guest's ID token:
  the server moves the guest's trips (members, owner, names, every
  booking's `memberIds` copy, invites) and deletes the guest.
- `AppSession` (`state/app_session.dart`) holds the uid. `TravaryApp`
  rebuilds `TravelStore`, `PremiumStore` and the `MaterialApp` per uid
  (`KeyedSubtree`); `TravelDocumentsStore` and `AppSession` sit above it,
  so travel documents never change with the account. The message after a
  switch ("Signed in with Google. 2 trips…") is taken by `HomeShell`.
- **Sign out** starts a new guest. **Delete account** (required by both
  stores): the `deleteAccount` callable deletes trips only they are on
  (bookings, invites, ticket files), leaves or hands over shared ones
  (`tripFateOnAccountDeletion`), then `users/{uid}` and the auth user. On
  iOS an Apple account first re-authenticates and revokes Apple's token.
- Auth lives behind `AuthService` (`data/auth_service.dart`,
  `FirebaseAuthService`); tests use `FakeAuthService`
  (`test/support/session.dart`). Server: `functions/src/account.ts`.
- Setup (done): Apple App ID capability + `Runner.entitlements`; Services
  ID `com.travary.app.signin` (return URL
  `https://travary-444.firebaseapp.com/__/auth/handler`); Sign in with
  Apple key `CLLWJ9Q78P` in Firebase's Apple provider; Google's iOS client
  ID in `_googleIosClientId` and its reversed scheme in Info.plist
  `CFBundleURLTypes`; the web client ID is `serverClientId`. Android needs
  each signing SHA-1/256 (debug, upload, Play App Signing) in Firebase,
  then a fresh `google-services.json`: a new signing key breaks Google
  sign-in until it's added.

## Family sharing and ticket backup

- **Invites**: callable `createTripInvite` gives a 6-character code (14 days,
  no 0/O/1/I/L); `joinTrip` adds the caller; `removeTripMember` removes
  someone (organiser) or yourself (leave). Max 6 people. All in
  `functions/src/sharing.ts`: only the server changes `memberIds`,
  `memberNames` and `invite`, and it updates every booking's `memberIds`
  copy in the same transaction. The app can't (rules).
- **UI**: trip screen "Who's coming" (invite, remove, leave), Trips →
  "New trip" → "Join a trip" (or the empty Trips tab). Inviting is gated by `requirePremium(familySharing)`; the
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
  deployed with its Places key secret; a separate Gemini call classifies a
  whole trip into an experience theme,
  setting, moods and destination, verified with Places Text Search (New)
  (`GOOGLE_MAPS_PLATFORM_KEY` secret). Cached by a source hash; one shared
  retry policy with Smart Import (`geminiRetry.ts`). Vocabulary lives in
  `functions/src/visualVocabulary.ts`, mirrored in
  `lib/domain/visual_profile.dart` (a test keeps them equal). Only place IDs
  and 30-day coordinates from Places are stored (Google's terms).

## Live flight status (testing)

- **AeroDataBox** through API.Market (key in Secret Manager as
  `AERODATABOX_API_KEY`, header `x-api-market-key`). Callable `flightStatus`
  (`functions/src/flightStatus.ts`, pure logic in `flightStatusLogic.ts`)
  takes a flight number, local departure date (a week back to a year ahead)
  and optional departure IATA. It returns the traveller's leg and every leg:
  airports, cities, schedule, and close to the day the gate, terminal,
  check-in desk, baggage belt and delays, all as airport-local times. Predicted times are AeroDataBox's guess, so
  they're not shown.
- Answers are cached in `flightStatus/{NUMBER_date}` (server-only, shared by
  everyone on the flight). The cache lasts 10 min near departure and up to
  6 h once landed (`cacheLifetimeMs`). There's a per-traveller daily cap.
  Logs never name the flight.
- **Adding a flight:** a new flight opens on the departures board,
  `FlightFinder` (`features/booking/flight_finder.dart`). The flight
  number and departure date find the flight in the airline's schedule (up
  to a year ahead, by departure date) and flip it onto split-flap tiles.
  "Use this flight" fills in the ticket: the title ("London to Tokyo"),
  departure and landing times, and the departure airport with its code
  (`logic/flight_fill.dart`). "Enter flight manually" skips to the ticket.
  It searches once typing pauses on a whole flight number. Editing or a
  Smart Import draft goes straight to the ticket. A trip's "Flight out" or
  "Flight home" gap opens the board on that day.
- **On the day:** the flight's page shows `FlightStatusPanel` from 3 days
  before take-off to the day after landing (`logic/flight_status_text.dart`:
  `flightLookupFor`, all wording). Design tools have a "Flight status test"
  for any real flight.
- **Debug builds only** (`Dependencies.flightStatus`). The free plan doesn't
  allow commercial use, so release builds need a paid plan first (about
  $7.50/month), plus premium gating and, later, alerts by webhook.

## Conventions

- snake_case files, PascalCase classes, `_private` members, `const` wherever possible.
- New booking wording → `logic/card_text.dart` with a test in `test/logic/`.
- New rule about time/trips → `logic/` with a unit test. Keep `logic/` pure.
- Dispose controllers/subscriptions; never use `context` in `dispose()`
  (keep a reference from `initState`).
- Layouts must survive long titles and small phones: tests run at iPhone size
  and fail on overflow.
- **Home tabs are pages of one `PageView`** (`app/home_shell.dart`). A nav tap
  slides through every tab in between (`NavLayout.switchDuration` 500 ms,
  `switchCurve` `easeOutBack`: the overshoot is the bobble, smaller for
  neighbours, none at the first/last tab). Keep `NeverScrollableScrollPhysics`
  (nav taps only, no swiping), the keep-alive wrapper (a `PageView` builds only
  visible pages) and each page's own linen (pages slide as whole cards). Reduced
  motion jumps instead. The nav bar stays in `bottomNavigationBar`, so pages
  need no extra bottom padding. Tests that just want a tab on screen use
  `openTab` (`test/support/open_tab.dart`); the slide is covered by
  `test/widget/tab_transition_test.dart`. Scope scroll finders to the screen
  (`find.descendant(of: find.byType(TripsScreen), ...)`): the first `Scrollable`
  in the tree is now the `PageView`'s.
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
- Bundle ID / Android application ID: `com.travary.app` (Firebase apps
  `ios:3d6150…` and `android:ccb966…` in travary-444).
