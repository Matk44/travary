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
  planned dates keep it when empty and keep its bookings to them
  (`logic/trip_window.dart`): the form's date pickers offer only its days
  and two travel days either side, an edit or import whose dates leave a
  trip goes to the trip they fit (a typo'd month's stray trip folds back),
  a trip that formed on its own asks before a booking stretches it well
  past its bookings, new trip dates can't leave a booking out, and a new
  trip on another's dates offers to open that one. Adding a stay or flight
  from a trip starts on what it still needs (`firstGapFor`).
  The destination is read from the name as it's typed ("Japan holiday",
  "Disney World") by `logic/destinations.dart`: every country plus
  well-known regions and cities, offline, with suggestions for a half-typed
  place and a picker; never required (a "Grandma's" trip is left to the
  classifier and its bookings). A trip that forms from its bookings is
  named after where they go (`readTripPlace` in `logic/trip_route.dart`:
  where the traveller stays, else where transfers go, never home or a
  stopover: London→Dubai→Osaka is "Osaka"), and its name and place keep
  following them (`Trip.autoName`: "Osaka" becomes "Japan" once Kyoto and
  Tokyo are booked) until the traveller changes either; that rename writes
  only the name and place (`TravelRepository.renameTrip`), never the dates
  a Holiday Pass goes by. A flight home from another city of the trip
  joins it (`findReturnFlightTrip`: in to Osaka, home from Tokyo). Flights
  and transport keep where they arrive (`DetailKeys.arrivesAt`, from the
  departures board and Smart Import); airports are read as the places they
  serve (`logic/airports.dart`: Kansai is Osaka). Only title + date are
  required on any form.
- **Today is the product.** Opens on today during a trip, else the first day of
  the next trip: the greeting, then the day's cards down a time rail (each
  timed card's time and a dot on its left, joined by a line): the featured
  ticket in its place in time, the hotel's key card after it, the day's
  tagged cards; finished ones fold under "Earlier" (`logic/day_layout.dart`,
  mockup `docs/mockups/today-time-rail/01-left-time-rail.webp`). Past and
  future stay one tap away (Trips, Documents): Today is one sheet of pages
  side by side that follows the finger (`logic/today_sheet.dart`): drag
  left for the next day, right for the one before; let go and it settles
  on the nearest with a little bobble (`TodayLayout.daySettle`). It runs
  from the first day of the trip you're on through every trip to come, each
  one's countdown between the last day of the trip before it ("After
  Orlando") and its own first day, and ends on "Where to next?" (Travi,
  folio open); before its first page it stops, as past trips live on
  Trips. A day picked in the trip calendar (tap the date pill or "Day 3 of
  7") slides in from the day beside it with the tabs' curve. Every trip to
  come counts down before its first day whatever is on today (never gated
  on today's bookings), and the greeting is on the page that is today only:
  another day is headed by its name (`dayHeading`: "Tomorrow", "Yesterday",
  the weekday), held to the greeting's height so the days line up as they
  slide; a countdown after another trip and "Where to next?" have no big
  heading (`TodayHeader.title`, `titleLike`).
  Between trips, Today counts down to the next trip instead
  (`CountdownTripHero`: its destination's postcard, else the neutral one,
  as large as the screen allows, with a luggage tag over its lower right
  corner, about half of it below the card; tapping
  it opens the trip). Each time Today comes into view (its tab, back from
  the background, a screen closed over it: `HomeShell` ticks `shown`) the
  postcard lifts in and the tag is slapped on, swings and settles. On the Trips tab a
  trip you're on or coming to, with a landscape postcard, shows on it with
  the same tag (`UpcomingTripPostcard`: "DAYS TO GO", or "DAYS LEFT" and
  "Day 3 of 7" for the trip you're on); other rows stay plain.
- **Inside a trip** (C2 "refined ledger", `docs/ART_DIRECTION_SCREENS.md`,
  mockup `docs/mockups/trip-ledger-c2/`): its postcard with the luggage tag,
  "Your plan" as ledger rows by date (`CardSize.ledger`, tickets on the
  row), what it still needs as dashed rows with Add and "Not needed"
  (`logic/trip_gaps.dart`: a flight within the trip, Osaka to Sapporo, is
  neither the flight out nor home; a night on a sleeper train needs no
  stay), "Before you go" (the trip's shared checklist:
  to-dos that aren't bookings, like the visa or the dog sitter, with an
  optional "by" date that may be before the trip, `logic/checklist.dart`),
  the packing list (one row opening `PackingListScreen`: things to take,
  shared, ticked as they're packed, one-tap ideas, an empty list can start
  from the last trip's; `logic/packing.dart`, `Trip.packing`), who's
  coming, and a notched "Add a booking". The countdown says how the
  packing list stands under its postcard (`CountdownNote`), opening it;
  under that, until the widget is on the home screen, "Home screen · Add
  this countdown" opens the widget's setup sheet (see Home-screen countdown
  widget).
  The trip itself (name, dates, family, card style, delete) is under "Trip
  details". Forms are a paper ticket in the trip's colours; a new flight's
  ticket is headed by the departures board (`FlightFinder`) when flight
  data is on, its number filling in the rest (else the number heads it).
- **Never lock someone's tickets.** Tickets and bookings already in are
  always reachable, editable and deletable, offline, whatever their plan.
  Only adding past a free holiday's bookings before it starts needs a pass
  (see Premium).
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
│               travel_document (passports etc.: on this phone only),
│               checklist (a trip's to-dos)
├── logic/      Pure Dart rules, fully unit-tested:
│               onboarding_films (Travi's key frames, films, cues, routes),
│               travi_cameos (where Travi turns up outside onboarding: poses, peeks,
│               the countdown's reactions, once-a-day greeting; generated travi_cameo_assets),
│               day_plan (done/now/next), day_layout (Today's rows and time rail),
│               today_sheet (Today's pages: the trip's days, countdowns, where to next),
│               trip_plan (+ focus), trip_calendar (the calendar's weeks), trip_assignment,
│               destinations (places a trip's name can mean: detection, suggestions, picker),
│               travel_documents (expiry checks against the next trip, masking, wording),
│               flight_status_text (when live flight status shows, its wording, the live line),
│               flight_alerts (which flights alerts cover, when to ask, the page row),
│               flight_fill (a found flight → the add-flight form, board wording),
│               trip_route (where each booking is: its city by day, the trip's own
│               place for art, where a trip goes for its name), airports (codes and
│               names as the places they serve), transport (hire car, journey or pass),
│               trip_window (the days a trip's bookings may use, where a booking
│               goes: placeBooking, trip dates that leave bookings out, overlaps),
│               checklist ("Before you go": order, wording, ideas),
│               pass_confirmation (a bought pass confirmed: the stage's words, what it covers),
│               ai_consent (asking before anything goes to Google's Gemini: wording, offers),
│               packing (the packing list: wording, ideas, which list to reuse),
│               countdown_widget (the home-screen widget's every day ahead, worded),
│               countdown_widget_setup (who is offered the widget, the setup sheet's wording),
│               trip_gaps (what a trip still needs: nights without a stay, the
│               flight home), trip_hero_text (a trip's tag), booking_form_text,
│               card_text (all card wording), countdown_text (the countdown's
│               wording, calendar-date count), trip_postcard_text (a coming
│               trip's tag), formatters, photo_shrink (which ticket photos
│               are shrunk as they're added, and to what size), art_pack_selection
│               (trust rules, pack ranks, downloads), visual_profile_request
│               (classifier payload, meaningful edits)
├── data/       TravelRepository interface; Memory (demo/tests) + Firestore;
│               demo_data; attachment_store (ticket files, offline) +
│               photo_shrinker (camera photos shrunk once, as they come in);
│               visual_profile_service; art packs: art_pack_catalog (formats +
│               validation, shared with tool/), art_pack_archive (safe zip),
│               art_pack_store (disk), art_pack_service (download manager);
│               travel_document_repository (local only) + document_lock (local_auth);
│               push_service (flight alerts: permission, this phone's token, taps);
│               reminder_scheduler + reminder_settings (local reminders, this phone);
│               shared_files (files shared in from other apps);
│               countdown_widget_bridge (the home-screen widget's folder + redraw, and
│               asking the phone whether it's added or to place it); countdown_widget_art
│               (its pictures, written no larger than it draws them); countdown_widget_settings
│               ("Not now" and "has been added", this phone);
│               ai_consent_record (the answer about Google's AI, this phone);
│               auth_service (guest, Apple/Google/email-link sign-in, delete account);
│               onboarding_record (users/{uid}.onboardingCompleted, every phone);
│               free_plan_limits (config/freePlan: a free holiday's bookings)
├── state/      TravelStore (ChangeNotifier): the single source of truth for screens;
│               OnboardingStore (account-specific setup and actual saved booking identity),
│               ArtCatalogController (bundled + installed packs), VisualProfileCoordinator,
│               TravelDocumentsStore (documents + lock), AppSession (account + uid),
│               NotificationsStore (flight alerts on this phone),
│               RemindersStore (free reminders), ShareInbox (a shared file waiting),
│               AiConsentStore (may Smart Import and trip looks use Google's AI),
│               CountdownWidgetSync (keeps the home-screen widget in step)
│               CountdownWidgetStore (is the widget on the home screen, the offer on Today)
├── design/     THE SKIN: tokens, trip_chrome (palette colours + chrome art), kind_style,
│               cards/ (BookingCard → FeaturedTicketCard / RoomKeyCard /
│               TaggedReservationCard on ShellFrame, DocumentStampCard, LedgerRowCard),
│               art/ (catalog, resolver, document_stamps,
│               card_shells, art_slots), widgets/ (nav_bar, today_header, time_rail, trip_calendar,
│               countdown_trip_hero, upcoming_trip_postcard, fitted_place_name,
│               the C2 ledger look: ledger (paper panels, rows, TicketButton, linen),
│               trip_hero, plan_gap_row, checklist_row, paper_form (form ticket,
│               fields, date boxes),
│               departure_board (board, split-flap tiles), live_flight_strip (Today's
│               live line under a flight),
│               travi_cameo (Travi small, cropped to his mark; TraviMessage for snackbars;
│               TraviLounge; TraviPopUp), travi_clip_player (cameo films and holds))
├── features/   Screens: today, trips (trip, trip details, checklist sheet), wallet (the "Documents" tab),
│               booking (form, flight finder, detail, viewer), profile,
│               travel_documents (list, form, document, the tab's entry pill),
│               account (Profile's sign-in card, sign-in sheet, email-link form),
│               onboarding (Travi scenes, sign-in before the pass desk, home gate),
│               ai (the consent sheet, the trip page's looks offer),
│               widget (the home-screen countdown widget's setup sheet)
└── app/        bootstrap (backend choice), app, home_shell (tab pages + add button)
tool/           art_packs.dart: builds, validates and publishes art packs, and converts
                bundled art to WebP (`bundled-webp`) (operator only)
art_packs/      pack sources (+ catalog.json once published)
art_masters/    bundled/: the PNG masters of the bundled WebP art (never bundled)
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
3. Artwork: `assets/art/<kind>/<theme>_<subject>_<nn>_<scene|vignette>.webp`
   (brief and prompts: `docs/ART_BRIEF.md`). **Bundled art is WebP** (the
   store download limit: PNG made it 245 MB): lossy colour at q88, alpha
   exact, pixel-for-pixel the same size, encoded like the art packs. The PNG
   masters live in `art_masters/bundled/` (the same path without `assets/`,
   never bundled); edit a master, never a WebP. New bundled art: drop its
   PNG in the bundled folder, run `dart run tool/art_packs.dart bundled-webp`
   (every PNG the pubspec bundles becomes a `.webp` and its PNG moves to the
   masters), and look for it by name without extension. Never bundle a PNG
   (`assets/branding/` isn't bundled). Themes are `ExperienceTheme`
   wire names (`urban_heritage`), legacy `tropical`/`city`/`snow`/`classic`
   still load. A booking's **subject** ("pizza", "castle") comes from Smart
   Import (Gemini picks it: `artSubject`) or from keywords
   (`logic/art_subjects.dart`, mirrored in `functions/src/artSubjects.ts`;
   a test keeps them equal). Downloaded **art packs** add destination and
   experience art (`docs/ART_PACKS.md`; sources are WebP, converted with
   `dart run tool/art_packs.dart webp`, PNG masters in `art_packs/originals/`;
   catalog v234 is published (15 October 2026): 83 packs, including 30
   city packs for the world's most-visited cities, 10 whole-country packs,
   and a Documents stamp on every country and US pack; their key cards are
   full height, see `docs/ART_PACKS.md`). `ArtResolver` takes a
   `TripArtContext` and tries the subject from the city → region → country
   pack → the trip's look → secondary look → core, then generics, stable per
   booking and never repeating side by side. Each booking's context is at
   the place it's in (`TravelStore.artContextOf`, `TripRoute.placeOf`): on
   Osaka, Kyoto and Tokyo, Kyoto's days take the Kyoto pack then Japan's,
   the others Japan's; the trip's own art is at `tripArtLocation` (the
   country when it stays in several places nobody chose). Downloads take
   every place's pack and each country's to fall back on. Pictures are `ArtImageRef`s
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
   booking's vignette). A complete tagged card has its picture printed on
   it, so beside another on the same shell the later card takes the blank
   shell and its own vignette (`ArtResolver.resolveAll`, which Today feeds
   in the order the cards are shown, `tagged` saying which are tagged
   cards). A hire car in progress is on the `ongoing_tag`. A button on a
   shell keeps a 48-point tap target but draws its face at the anchor's own
   size (`ShellAnchor`), so it never covers the line above. In
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
   (packs, then bundled `<look>_<role>.webp`, then a stand-in look); text,
   buttons and tag icons sit at measured fractional anchors (`ShellGeometry`),
   and shells are never stretched. Icons and interface surfaces (tabs, linen,
   pill, stamp) resolve through `ArtSlots` (`design/art/art_slots.dart`).
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
days; days in between show an `OngoingStrip`. A stay or hire car you've
checked in to stays on Today the evening you arrive; a flight or journey
that has left (a sleeper train) is finished, not a key tag (`buildDayPlan`).
Transport is a hire car, a journey or a pass (`transportSortOf`), each
with its own ends: "Pick-up"/"Drop-off", "Departs"/"Arrives",
"Starts"/"Ends" (`bookingEvents`); a key tag drops the company before it
cuts the countdown short. Times follow the phone's 12 or
24-hour setting (`ClockStyle`, set at the app's root from
`MediaQuery.alwaysUse24HourFormatOf`); dates are day-first and Monday-first
everywhere, the date pickers included (`showTravaryDatePicker`).

### Data (Firestore)

```
trips/{tripId}                        title, theme, themeSource, destination, autoName (the app named it:
                                      name and place follow the bookings), ownerId, memberIds[], plannedStart/End,
                                      hiddenGaps[] (plan gaps marked "Not needed", for everyone),
                                      checklist{} (to-dos by id: text, done, due, createdAt; any
                                      member, one item per write via `checklist.<id>`, max 100),
                                      packing{} (the packing list, the same shape, no due; max 100),
                                      memberNames{}, invite{} (server-only), premium (server-only),
                                      visualProfile, visualProfileUpdatedAt, visualProfileRequest (server-only),
                                      liveFlights{bookingId: leg + checkedAt} (flight alerts, server-only)
trips/{tripId}/bookings/{bookingId}   Booking.toJson() + a copy of the trip's memberIds[]
invites/{code}                        tripId, createdBy, expiresAt (server-only)
config/freePlan                       bookingsPerHoliday (set by hand in the console; every signed-in
                                      phone reads it); the rest of config/ is server-only
users/{uid}                           plus{expiresAt, willRenew}, tripPasses{tripId: {start, end}},
                                      Smart Import / classification usage, tester (set by hand in
                                      the console: premium for reviewers and debug phones) (server-only);
                                      onboardingCompleted, onboardingCompletedAt (the app's: only
                                      true + the server's time, nothing else on the doc)
tripPasses/{purchaseId}               a claimed Holiday Pass: uid, tripId, start, end, store,
                                      refundedAt once refunded (server-only)
watchedFlights/{NUMBER_date}          flight alerts' watch list; flightStatus/{NUMBER_date} the shared
                                      answer; flightUsage/{period} units used; pushTokens/{sha256}
                                      {uid, token, platform}; config/flightAlerts (all server-only)
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
file name (never absolute paths), camera photos shrunk once as they're added;
shared and paid trips back them up (see Family sharing and ticket backup).

## Running

| Mode | How | Data |
|---|---|---|
| Cloud (default) | `flutter run` | Firestore, real trips: a guest account until the traveller signs in |
| Demo | `flutter run --dart-define=TRAVARY_BACKEND=demo` | Sample Orlando/Lake District/Paris trips built around today; resets on restart |
| Emulators | add `--dart-define=TRAVARY_EMULATOR_HOST=127.0.0.1` | Local Firebase emulators (`docs/ART_PACKS.md`) |
| Real purchases | add `--dart-define-from-file=config/revenuecat.local.json` | RevenueCat's public SDK keys (git-ignored); without them, purchases are simulated (a release build refuses to start) |
| Store builds | `tool/build_release.sh [android\|ios\|both]` | The App Bundle and .ipa with RevenueCat's keys and flight lookup (`FLIGHT_LOOKUP=false` leaves it out); checks the upload key and build number. An Archive from Xcode adds whichever of those the last flutter command didn't pass (`tool/xcode_dart_defines.sh`, the Runner's Flutter build phase), and fails without the keys file |
| Email sign-in | add `--dart-define=TRAVARY_EMAIL_LINKS=true` | Passwordless links on `travary-444.firebaseapp.com` (or `TRAVARY_EMAIL_LINK_DOMAIN`); off until the app opens them (`docs/EMAIL_LINK_SIGN_IN.md`) |
| Analytics in debug | add `--dart-define=TRAVARY_ANALYTICS=true` | Debug runs send nothing otherwise; release builds always send (`docs/ANALYTICS.md`) |
| Flight alerts off | add `--dart-define=TRAVARY_FLIGHT_ALERTS=false` | They're on in every build by default; this hides them (a build-time kill switch); see Flight alerts |

Cloud mode starts as an anonymous guest (enabled in the Firebase console for
`travary-444`); rules and index are deployed. Signing in (Apple, Google,
email) works only in cloud mode (see Accounts).

Design tools (debug builds, Profile tab): **Preview a different time** shows
cards before, during and after their time; **Reset sample trips**; **Card
gallery** (every kind and size per look, with the shells chosen); **Travi
cameos** (every peek, the lounge, each pose cameo, and the sync-error
snackbar, live).

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
backdrops, to catch alpha halos); and Today on each US city and region pack's
shells (`test/visual_qa/us_city_cards_test.dart`) as `us_cards_<place>.png`, and on each of the world's 30 city packs and 10 country packs
(`test/visual_qa/world_city_cards_test.dart`) as `world_cards_<place>.png`; and the paywall on six
phones and an iPhone SE (`test/visual_qa/paywall_fit_test.dart`, which also checks nothing scrolls) as
`paywall_<w>x<h>.png`. The two card lists are goldens in
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

- **Purchased pass badges** (19 Oct 2026): `AccessPolicy.purchasedPassFor`
  identifies active personal purchases (Annual first, else this holiday's
  Holiday Pass). `PassBadge` shows their generated foil tickets on Today,
  Trips, the trip page (tucked onto the postcard's top-left corner,
  `TripHero.badge`, read out with the trip), and the active Annual Pass in
  Profile. Shared premium access has no product type and is never labelled
  as a personal purchase. Still artwork and prompts:
  `docs/mockups/purchased-passes-v1/`; owner selected both original v1
  designs on 20 Oct 2026 after comparing four alternatives.
- **A bought pass is confirmed** (20 Oct 2026): once the store confirms,
  the pass desk (`OnboardingPassPanel`, on the paywall and both onboarding
  desks) stamps the pass's badge onto its floor over what it covers
  (`passCoverageFor`: the holiday and "covered until", or every holiday and
  when the Annual Pass renews), the stage's words change
  (`passConfirmedWords`: "Enjoy your holiday!", "Every holiday, sorted!", a
  restore "Welcome back!") and Travi cheers (`traviCuesForPassConfirmed`,
  the existing `cheer` film). One button hands back ("Carry on" on the
  paywall, "Open my holiday" in onboarding); Close and Back after paying
  also count as bought, so the gated action goes ahead. A restore of their
  own pass for this holiday is confirmed the same way; a payment the server
  hasn't recorded (`pending`) keeps "Payment received…" and is never
  celebrated. Analytics `pass_confirmed` (kind, restored, source). The
  animated version (a new `pass-hold` key frame, `pass-up` and `pass-toss`
  films, the badge handed off as live UI) is planned, not made:
  `docs/mockups/pass-purchase-motion-v1/README.md`.
- Rules live in one pure class: `logic/access.dart` (`AccessPolicy`). Plus
  unlocks everything; a Trip Pass unlocks one trip of at most 30 days,
  bought for the dates it had then (`TripPass`, `newTripPassFor`), until 7
  days after it ends. It grows with the same holiday (the flight home added
  later, up to 30 days) but never moves to another one, and a trip moved or
  stretched back before the dates bought for isn't covered (`tripPassLastDay`,
  mirrored in `functions/src/tripPass.ts`; both run
  `functions/src/tripPassCases.json`);
  a trip stamped `premium` by the server unlocks it for everyone on it ("Plus
  travels with the trip"); free gets 2 Smart Imports (lifetime,
  `Pricing.freeSmartImports`, mirrored by `FREE_SMART_IMPORTS` on the server)
  and 2 ticket files per holiday (the files attached to bookings: photos and
  PDFs, not the bookings or notes themselves; the two
  numbers match because each import keeps its file;
  `Pricing.freeTicketFiles`, `canAttachTickets`, `ticketFilesIn`:
  one file kept on several bookings counts once). Files already attached
  always stay; adding more goes through `requireTicketRoom`, counted
  against the trip saving will put the booking in (the form's
  `placeBooking(booking:)`, Smart Import's `TravelStore.importPlaces`, the
  same `placeImport` the batch save uses). Every way past the limit opens
  the paywall (owner, 14 Oct 2026: it pops up for every free-limited
  action): adding a file, and a Smart Import whose file has no room (over
  the form for one booking, before saving for several); without a pass the
  booking saves without its file and says so, the form still offering it.
  The 2 free files are the owner's call (13 Oct 2026) to lift conversion,
  kept on purpose: raising the limit later is easy, taking files back isn't.
  Travel documents are never counted: they have no limit.
- **12 bookings per free holiday until it starts** (owner, 20 Oct 2026: the
  free plan gave away the whole core, so nothing grew with how much a
  traveller relies on Travary). `AccessPolicy.bookingsLeft`,
  `canAddBookings`, `bookingsCountedIn`: notes never count
  (`countsTowardsFreePlan`), nor do the checklist, packing list or travel
  documents (not bookings). Only adding is limited: what's in always
  opens, edits and deletes, and deleting one frees a place. From the
  holiday's first day nothing is ever blocked (someone abroad adding
  tonight's dinner never meets a paywall); a new holiday starts empty, and
  a pass, Plus or Plus travelling with the trip has no limit. The form's
  save (`requireBookingRoom`, source `add_booking`, after the stretch
  question so it counts the trip it lands in) opens the pass desk
  (`PremiumFeature.everyBooking`: "Room for every booking?"); "Not now"
  leaves the form as typed. Smart Import's review list checks every
  holiday the ticked bookings land in before saving any
  (`import_bookings`); "Not now" saves none and says how many fit
  (`bookingsOverText`), so they can untick some. A new trip made by one
  import isn't checked. The trip page counts them over "Add a booking"
  once 3 or fewer are left (`bookingCountShown`,
  `Pricing.bookingCountShownWithin`: "9 of 12 free bookings used"), tapping
  to the desk (`booking_count`). The number is
  `config/freePlan.bookingsPerHoliday` in Firestore (set by hand in the
  console; every signed-in phone reads it, nobody writes it; 5 to 1000,
  else the default `Pricing.freeBookingsPerHoliday`), so it moves without
  a release (`FirestoreFreePlanLimits` → `PremiumStore.limits`). Enforced
  by the app only, like the files: rules can't count a trip's bookings
  cheaply.
- **Gate every premium entry point with `requirePremium()`**
  (`features/premium/premium_gate.dart`): it returns the decision or opens
  the paywall. Never check entitlements ad hoc in a screen.
- **Never gate** what a traveller has already put in (bookings, tickets),
  Today or Wallet. Adding is gated only by the free holiday's bookings above.
- `PremiumFeature.released` controls what the paywall sells; unreleased
  features only show (marked "soon") in debug builds.
- Purchases go through `PurchaseService`. With RevenueCat's keys (cloud
  builds) it's `RevenueCatPurchaseService`, one per account
  (`Dependencies.purchasesFor`); otherwise `TestPurchaseService` (simulated,
  nothing charged; plan switcher in Profile → Design tools).
- Store products, the same IDs on both stores: the Annual Pass
  `travary_annual_pass` (Google base plan `travary-annual-pass`, $34.99/yr)
  is RevenueCat's `plus` entitlement; the Holiday Pass `holiday_pass`
  ($14.99) is a consumable in no entitlement. RevenueCat project "Travary",
  offering `default` (packages `$rc_annual`, `holiday_pass`, `pass_desk`
  metadata). Offline preview prices: `domain/pricing.dart`. Store prices
  and pass names come from `RevenueCatOfferCatalog`
  (`docs/REVENUECAT_OFFER_CATALOG.md`). Price wording: `logic/price_text.dart`.
- The app never records a purchase. `users/{uid}`, `tripPasses` and
  `Trip.premium` are server-written only (rules enforce this); trip writes
  use merge so the app never clobbers `premium`. Server:
  `functions/src/purchases.ts` (rules in `purchasesLogic.ts`):
  - After the store charges for a Holiday Pass, the app calls
    `claimTripPass(tripId, transactionId)`; the server checks it with
    RevenueCat, records it once (`tripPasses/{purchaseId}`) with the trip's
    dates **read from Firestore**, mirrors it to `users/{uid}.tripPasses`
    and stamps `premium` on the trip. Retries are safe; an unclaimed pass is
    kept on the phone (`PendingPassClaims`) and claimed again at launch and
    on Restore, and the app says "Payment received", never "failed". An
    automatic trip with a pass keeps its dates when emptied
    (`TravelStore.keepWhenEmpty`) instead of being removed.
  - The Annual Pass is read live from the SDK; `syncPurchases` (after
    buying, on Restore) and `revenueCatWebhook` (renewals, expiry) mirror it
    to `users/{uid}.plus` and stamp every trip its owner organises.
  - Triggers restamp a trip when its dates or organiser change: a pass grows
    with its holiday (`tripPassLastDay`), Plus covers new trips. `until` is
    the end of the last day everywhere (`afterDay`).
  - Free Smart Imports used are the server's count (`smartImport.total`).
  - The server enforces premium too (`hasPremium`): Smart Import past the
    free ones (the app sends the trip whose pass allowed it,
    `AccessDecision.tripId`) and `createTripInvite`. It goes by the Plus
    mirror, the trip's stamp or `users/{uid}.tester`, else asks RevenueCat
    (and mirrors the answer), so a purchase moments ago is never refused.
    Debug builds with simulated purchases need `tester: true` on the
    account for more than the free imports or for inviting.
  - A refunded Holiday Pass (webhook CANCELLATION of `holiday_pass`) is
    marked `refundedAt` and stops counting; REFUND_REVERSED restores it.
  - Guest adoption moves passes; account deletion deletes them.
  - Secrets: `REVENUECAT_API_KEY` (RevenueCat secret key) and
    `REVENUECAT_WEBHOOK_AUTH` (the webhook's Authorization header).
- **No free trial, and no trial reminders.** Premium sells itself at the
  moment it's needed (sharing with family, Smart Import, never missing
  anything), never with a trial or a countdown to a charge.
- Funnel events: `state/analytics.dart` (`track()`): action types and counts
  only, never names, places, documents or anything typed. Release builds send
  them to Firebase Analytics (`useFirebaseAnalytics` in `app/bootstrap.dart`;
  collection is off in Info.plist/AndroidManifest until then, and there's no
  advertising ID on either platform). RevenueCat gets the analytics ID so its
  Firebase integration can send purchases there too. `docs/ANALYTICS.md`.
- Crash reports: **Firebase Crashlytics** from release builds
  (`useCrashReporting`: Flutter, Dart and native crashes), off in the
  platform config until then like analytics, never linked to an account
  (no user ID is set; the store forms say "not linked"). Android needs the
  Crashlytics Gradle plugin or the SDK won't start; iOS release builds
  upload their dSYMs in the "[Crashlytics] Upload symbols" phase.
  `test/tool/platform_config_test.dart` keeps all of that in place.

**Public pages** (support, privacy, terms, delete your data) live on
travary.app: `/support`, `/privacy`, `/terms`, `/delete-account`, built
from `website/content/legal/` (moved 15 Oct 2026; the old GitHub Pages
copies at matk44.github.io/travary_support now return 404). The app links
to them through `TravaryLinks` (`domain/links.dart`): Profile's "Help and
legal" and the pass desk's Terms of Use and Privacy Policy links; the store
listings and the Google sign-in branding (OAuth consent screen, verified
with a logo) use the same addresses. They name **Dream Prayer Developer**
(the Google Play developer) as who makes Travary. Support email
`dreamprayer.dev@gmail.com`. When the app starts collecting something new
(analytics, a new provider), update the privacy policy before releasing.
Search Console: travary.app is verified by both Google accounts (two
`google-site-verification` tags in `website/build.py`; never remove
either), because the OAuth branding needs the Cloud project's owner,
dreamprayer.dev@gmail.com, to own the domain.

**What the stores check on the pass desk** (Apple's Schedule 2 §3.8(b)
and guideline 3.1.2, Google Play's subscriptions policy): each pass shows
its title, price, period and whether it renews ("Renews yearly. Cancel
anytime."); Restore, Terms of Use and Privacy Policy stay on one line under
the button (`paywall_fit_test`); Profile's pass card has "Manage or cancel"
(the store's subscriptions page) for Annual Pass holders, which Google
asks for. App Store Connect also needs the Terms of Use link in the App
Description (`https://travary.app/terms`), as the app uses Apple's
standard EULA alongside its own terms.

**Before launch:** the store privacy forms updated for analytics and push
tokens (`docs/ANALYTICS.md`; Google Analytics is linked to `travary-444`);
the Annual Pass priced in App Store Connect; and a sandbox purchase of each
pass checked end to end on both stores. (Purchase functions, secrets,
webhook and Play credentials are done; the privacy policy still needs the
Analytics retention period written in. Full list: `docs/LAUNCH_CHECKLIST.md`.)

## Accounts (Sign in with Apple / Google / email)

- Everyone starts as an anonymous **guest**. Sign-in is offered just before
  onboarding's pass desk, by "I already have an account" on its first screen
  (`showSignInSheet`) and on Profile's `AccountCard` (`features/account/`):
  "Continue with Apple" / "Continue with Google" (the platform's own first)
  / "Continue with email". Signing in **links** the guest, so the uid and
  every trip stay as they are. Never required.
- **Email** is a passwordless link (`AuthService.sendSignInLink`,
  `EmailLinkForm`): the address waits on this phone (`auth/pending_email.txt`,
  never sent anywhere) until the link opens the app (`AppSession` listens to
  `app_links`). A sent link isn't a sign-in. Links come from the project's
  own Hosting domain (`travary-444.firebaseapp.com`; a custom one is
  optional), which must be an Associated Domain / App Link. Offered only with
  `TRAVARY_EMAIL_LINKS=true`: setup in `docs/EMAIL_LINK_SIGN_IN.md`.
- Every sign-in (linked or switched) sets `users/{uid}.onboardingCompleted`
  (`OnboardingRecord`), as does finishing onboarding, so that account skips
  onboarding on any other phone (`logic/onboarding_rules.dart`).
- If that login already has an account (another phone), the
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
- **Photos are shrunk once, on import** (`AttachmentStore.import`; rules in
  `logic/photo_shrink.dart`, the work in `data/photo_shrinker.dart`): a JPEG
  over about 1.5 MB or 2,500 px long, and every HEIC/HEIF, is stored as a
  JPEG at most 2,500 px on its long edge, quality 85, turned upright and
  with no EXIF (no GPS). The phone decodes it (HEIC by ImageIO on iOS,
  ImageDecoder on Android 9+), an isolate scales and encodes it. PDFs, PNG,
  WebP and GIF come in byte for byte, so barcodes stay as sharp as they
  came; a JPEG that wouldn't get smaller, or a photo that can't be read,
  stays as it came. That one file is what opens on the phone, backs up and
  the family downloads: never a second, lesser copy (a blurred barcode at
  the gate; the free-file count matches copies by name and size, and one
  import kept on several bookings is the same bytes). HEIC becomes JPEG
  because Flutter shows HEIC on Android only from Android 9 (minSdk is 24).
- Storage rules read Firestore, which needs the Storage service agent to have
  `roles/firebaserules.firestoreServiceAgent` (granted on travary-444). A
  new project needs it too, or every upload returns 403.
- **Invite links:** `https://travary.app/join/ABC234` (`logic/invite_link.dart`,
  shared with a QR code from the invite sheet). With the app, the link opens
  it (iOS associated domain `applinks:travary.app`, Android App Link with
  `autoVerify`; Flutter's own deep linking is off so `app_links` handles it):
  `AppSession.pendingInviteCode` → `OnboardingGate` opens the join sheet with
  the code filled in, skips setup for someone new, then opens the trip.
  Without the app, the site's `/join` page shows the code and how to get it.
  `website/build.py` writes the page, the `_redirects` rewrite and both
  association files (`APPLE_APP_ID`, `ANDROID_CERT_SHA256`: add the Play App
  Signing and upload keys' SHA-256 before launch). The site must be deployed
  for links to open the app.

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
- **Asked first** (Apple 5.1.2(i): explicit permission before personal
  data goes to a third-party AI): nothing goes to Gemini, from Smart
  Import or automatic looks, until the traveller allows it on the sheet
  (`askAiConsent`, `features/ai/ai_consent_sheet.dart`: a ticket saying
  what's sent and what never is, Travi popping up over it holding a "MAY
  I?" card). One answer on this phone covers both (`AiConsentStore`,
  `logic/ai_consent.dart`). Asked at Smart Import before the file is
  chosen (a declined shared file can still be typed in), by a trip page's
  offer (`TripLooksOffer`, ahead of the reminders offer), at Trip details'
  "Automatic", and from Profile's switch; never at launch. Until it's
  allowed, `VisualProfileCoordinator` sends nothing and trips keep their
  look; allowing it schedules every trip.
- Trip grouping for imports: bookings from one file share a trip within
  30 days (a trip already there that the file joins included), a new one
  named after where the whole file goes; a return flight ("Lisbon to
  London", or home from another city of the trip) joins the trip its
  outbound flight started.
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
  `AERODATABOX_API_KEY`, header `x-api-market-key`), behind the
  `FlightProvider` interface (`functions/src/flightProvider.ts`) so it can
  be swapped or joined by a gate source. Callable `flightStatus`
  (`functions/src/flightStatus.ts`, pure logic in `flightStatusLogic.ts`)
  takes a flight number, local departure date (a week back to 180 days ahead:
  the Pro plan refuses later dates, `FLIGHT_LOOKUP_DAYS_AHEAD`, mirrored by
  `flightLookupDaysAhead`)
  and optional departure IATA. It returns the traveller's leg and every leg:
  airports, cities, schedule, and close to the day the gate, terminal,
  check-in desk, baggage belt and delays, all as airport-local times. Predicted times are AeroDataBox's guess, so
  they're not shown.
- Answers are cached in `flightStatus/{NUMBER_date}` (server-only, shared by
  everyone on the flight). The cache lasts 10 min near departure and up to
  6 h once landed (`cacheLifetimeMs`). There's a per-traveller daily cap.
  Logs never name the flight.
- **Adding a flight:** a new flight's ticket is headed by the departures
  board, `FlightFinder` (`features/booking/flight_finder.dart`), the ticket
  right under it and editable all along (owner, 14 Oct 2026: the number at
  the top fills in the rest, typing by hand still works). The flight
  number and departure date find the flight in the airline's schedule (up
  to 180 days ahead, by departure date; further out the board says the
  schedule isn't out yet and asks nothing) and flip it onto split-flap tiles;
  the found flight fills in the ticket at once: the title ("London to
  Tokyo"), departure and landing times, and both airports with their codes
  (`logic/flight_fill.dart`). `refillFlight` keeps whatever the traveller
  typed, and takes the last flight's details out again when the number or
  board date changes. It searches once typing pauses on a whole flight
  number. Without the service, editing, or a Smart Import draft, the
  flight number heads the ticket instead. A trip's "Flight out" or "Flight
  home" gap opens the form on that day.
- **On the day:** the flight's page shows `FlightStatusPanel` from 3 days
  before take-off to the day after landing (`logic/flight_status_text.dart`:
  `flightLookupFor`, all wording). Design tools have a "Flight status test"
  for any real flight.
- **Debug enabled by default** (`Dependencies.flightStatus`). Explicit
  `TRAVARY_FLIGHT_LOOKUP` enables/disables the cloud service.
  `tool/build_release.sh` turns it on for store builds, so the AeroDataBox
  plan must be bought first (or build with `FLIGHT_LOOKUP=false`).

## Flight alerts (paid trips)

Plan, tests and provider research: `docs/FLIGHT_ALERTS_PLAN.md`. Sold as
**flight changes**: delays, new times, schedule moves, cancellations,
diversions, check-in open, boarding, gate closed, taken off, landed. Gates
and belts are a bonus shown and announced only when the data has them
(AeroDataBox has none at LHR, LGW, MCO, LAX): never promise them.

- **Server** (`functions/src/flightAlerts.ts`, pure rules in
  `flightAlertsLogic.ts`, fully tested): triggers keep `watchedFlights/{NUMBER_date}`
  (one doc per flight per day, shared by every trip on it): a flight
  booking saved or removed, a trip's `premium` or members changing, a
  user's Plus or `tester` flag changing (`syncTripFlights`). Only trips
  where someone has premium (`alertRecipients`, the same rule as
  `hasPremium`) are watched: checked on the server, never the app.
- **Checking:** `checkWatchedFlights` runs every 5 minutes, one request a
  second, and looks up flights that are due (`nextCheckAt`: 3 days before,
  the day before, every 4 h on the day, every 40 then 20 min in the last 3 h,
  30 min before landing and every 10 until landed, the belt for 45 min;
  about 20 checks, 40 units, a flight). Each answer is diffed with what was
  last announced (`flightChanges`: 5-minute threshold, drifts add up, the
  first answer is silent unless it's a cancellation), worded
  (`alertText`, airport-local times like the ticket) and pushed to every
  phone of everyone on the trip with premium (FCM, `pushTokens/{sha256}`).
  The answer also refreshes the flight page's `flightStatus` cache and the
  trip's `liveFlights.{bookingId}` (server-only) for Today.
- **Units:** every lookup (page and alerts) counts in `flightUsage/{period}`.
  `budgetLevel` slows checks when spending runs ahead of the month
  (`tight`), keeps only the last 3 hours and the flight itself under 10%
  (`low`), and stops below a reserve for the flight page (`out`). Params in
  `functions/.env`: `FLIGHT_ALERTS_ENABLED`, `FLIGHT_UNITS_PER_MONTH`
  (5000), `FLIGHT_RATE_PER_SECOND` (1), `FLIGHT_BILLING_DAY` (the day of
  the month the paid plan starts and renews, 1–28; it only paces the unit
  budget, so 1 does no harm until the plan starts). Kill switch without a
  deploy: Firestore
  `config/flightAlerts` `{paused: true}`.
- **App:** `data/push_service.dart` (`firebase_messaging`, registers this
  phone with `registerPushToken`), `state/notifications_store.dart`. The
  flight's page has a "Flight alerts" row (`FlightAlertsRow`,
  `logic/flight_alerts.dart`): on a paid trip, opening a flight is when the
  phone is asked, once, never at launch; on a free trip the row sells it
  (`requirePremium(flightAlerts)`). Today's flight card shows the live line
  under its ticket (`LiveFlightStrip`, `liveFlightLineFor`). A tapped alert
  opens its flight (`HomeShell`); on Android one arriving in the app shows
  as a snackbar. Free users keep the flight page's on-demand status.
- **On sale** in every build (`flightAlertsReleased` defaults to true;
  `--dart-define=TRAVARY_FLIGHT_ALERTS=false` hides it). Functions and rules
  were deployed 13 Oct 2026 (`checkWatchedFlights`, `registerPushToken` and
  the three `watchFlightsOn…` triggers). The APNs key is in Firebase (13 Oct
  2026: the team's key `8PPPQAD22W`, in both the Development and Production
  slots of `com.travary.app`; Push Notifications is on its App ID), so iOS
  builds, TestFlight included, can receive alerts; Android needs nothing
  more. A test push reached the iOS simulator (15 Oct 2026); not yet
  tried on a real iPhone. The AeroDataBox Pro plan ($7.50, 5,000 units, 1
  request a second, schedules 180 days ahead) was bought on API.Market
  (15 Oct 2026) and the key works. `FLIGHT_BILLING_DAY=15` is set in
  `functions/.env`; it takes effect when the functions are next deployed.
- Native: iOS `aps-environment` in `Runner.entitlements` (Push
  Notifications capability on the App ID); Android `POST_NOTIFICATIONS`,
  the `flight_changes` channel (made in `MainActivity`) and
  `ic_stat_flight`.

## Reminders and sharing in (free for everyone)

- **Reminders** are local notifications, never sent to a server
  (`logic/reminders.dart`, pure and tested): each trip day's plan in the
  morning (8:00, or an hour before an earlier start, never before 6:00) and
  a nudge before each timed booking (flights 3 h, notes at their time, most
  others 1 h; stays and the ends of things are in the morning's plan).
  Floating times on the phone's clock; nothing is set past the landing of
  the next flight that may change the clock (not one within a country on
  one time zone: `keepsTheClock`), and everything is set again when the app returns to
  the foreground, so they follow the traveller across time zones. At most
  50, two weeks ahead.
- Asked for only from the trip page's `ReminderOffer` (Travi waving, once a
  trip has a booking) or Profile's switch, never at launch or in
  onboarding. "Not now" hides the offer for good. `RemindersStore` keeps
  them in step with the trips; "Preview a different time" never sets any.
  Design tools: "Send a test reminder". iOS shows them as banners in the
  foreground (`AppDelegate`); Android uses the `reminders` channel and
  `ic_stat_reminder`, kept from shrinking by `res/raw/keep.xml`.
- **Sharing in**: a booking's screenshot, photo or PDF shared from another
  app is read like Smart Import (`importSharedFile`); with no Smart
  Import left it opens the add sheet ("Add this booking"), never the
  paywall, and the file stays as the ticket. `receive_sharing_intent` is
  pinned to **1.8.1** (1.9 is Swift Package Manager only); its Java target
  is set in `android/build.gradle.kts`.
- iOS: our own `ios/ShareExtension` (no Flutter code in it) copies the file
  into the App Group `group.com.travary.app` (`CUSTOM_GROUP_ID`), lists it
  where the plugin looks and opens `ShareMedia-com.travary.app:share`.
  Device builds need the App Group and the extension's App ID
  (`com.travary.app.ShareExtension`) in the Apple Developer account.
- Android: `SEND` filters for images and PDFs on `MainActivity`, now
  `singleTask`; `MainActivity.dropUnreadableShare` drops a share Travary
  can't read, which would otherwise crash the plugin.

## Home-screen countdown widget (free for everyone)

Today's postcard and luggage tag on the home screen (`docs/COUNTDOWN_WIDGET.md`):
iOS WidgetKit (`ios/CountdownWidget/`, iOS 17+, small/medium/large) and an
Android app widget (`android/.../widget/`, resizable). The widget runs
without the app, so `logic/countdown_widget.dart` works out every day ahead
(Today's `focusFor`, the Trips tab's wording, Travi's `countdownReactionFor`)
and `CountdownWidgetSync` writes it, with the trip's postcards, tag, linen,
ink and Travi's stills, to the widget's folder (iOS: the App Group;
Android: the app's files) only when it changes. The tag is written in the
app's own fonts (`assets/widget/fonts/`, the files google_fonts downloads).
**A widget has about 30 MB** before the phone stops it, which the simulator
never does (a widget that only ever worked there shows blank on a real
iPhone): reading a picture costs three to four times its decoded size, so
the app writes each one as a PNG no larger than the largest widget draws it
(`CountdownWidgetArtSize`, `shrinkForWidget`; the linen tile is drawn 341
points across whatever its pixels), and the preview in the widget gallery
uses small copies inside the extension (`ios/CountdownWidget/SampleArt/`),
not the app's full-size bundled art. Measure a change with `footprint -p`
on the extension's process (`phys_footprint_peak`); keep a fresh process's
peak well under 30 MB (`docs/COUNTDOWN_WIDGET.md`, "Memory").
Travi pops up each morning until noon and when the tag is tapped (four
seconds; iOS 17 App Intent, Android a broadcast); a tap elsewhere opens the
trip (`travary://trip/<id>` → `AppSession.pendingWidgetTarget` → `HomeShell`).
Widgets can't play films: iOS animates between timeline entries, Android
flips Travi's drawn layer. The file's version, channel and folder are
mirrored in Swift and Kotlin (`test/tool/countdown_widget_config_test.dart`).
Its App ID, `com.travary.app.CountdownWidget`, is registered with the App
Group (16 Oct 2026); not yet tried on a real iPhone.

**Getting it onto the home screen** (`logic/countdown_widget_setup.dart`,
`features/widget/countdown_widget_sheet.dart`): an app can't see the home
screen, only whether a widget of its own is on it, and only Android can be
asked to place one. So there is one setup sheet and two ways in, never a
modal at launch or in onboarding:
- **Today's countdown** (between trips): a second `CountdownNote` beside the
  tag, under "Packing list", "Home screen · Add this countdown ›". It sits
  there, not under the hero, because the countdown fills the phone to the
  tabs (a row below it is off screen on a 390 × 844 phone), and its title is
  that short because the room beside the tag cuts "Home screen widget" off.
  Shown only while the widget can be had, isn't on the home screen, never
  was (someone who took it off knows it exists), and wasn't turned down
  (`offersCountdownWidget`). The sheet's "Not now" (only from Today) puts it
  away for good; Profile keeps the way in.
- **Profile → "Home screen" → "Countdown widget"**: always there where the
  phone can have the widget (not iOS 15 or 16), with a tick once it's on.
- **The sheet** follows `CountdownWidgetStore`: Android asks the launcher to
  place it (`requestPinAppWidget`, one button, the launcher's own dialog);
  iOS has no such call, so it shows three steps; an Android launcher that
  can't be asked, or refuses, gets Android's steps. When the app comes back
  (`HomeShell`'s resume) the store asks the phone again, and an open sheet
  turns into "It's on your home screen". Detection: Android
  `getAppWidgetIds`, iOS `WidgetCenter.getCurrentConfigurations` (kind
  `CountdownWidget`). `status` and `pin` on the `travary/countdown_widget`
  channel, mirrored by `test/tool/countdown_widget_config_test.dart`.
- Per phone: `countdown_widget_settings` (`declined`, `everAdded`).
  Analytics (kinds only): `countdown_widget_sheet_opened` (from),
  `_pin_asked` (shown), `_declined`, `_added` (first time it's seen there).

## Travi onboarding

- `OnboardingGate` shows first-run setup only to an account that hasn't been
  through it on this phone or any other (`users/{uid}.onboardingCompleted`)
  and has no plans (`onboardingNeeded`); a setup under way here resumes.
  Demo home stays available; `TRAVARY_PREVIEW_ONBOARDING=true` forces the
  native preview.
- Conversion direction approved 7 Oct 2026: `docs/ONBOARDING_CONVERSION.md`
  is project memory. Keep the short story; strengthen successful booking proof
  and future paid value rather than adding questions to create sunk cost.
  Keep **Postcard first** and **Paper words**. Travi is the coral ribbed spinner.
- Implemented native flow (9 Oct 2026): shared roll-in/idle → destination →
  explicit dates or unknown dates → booking invitation → full-screen
  folio/manual/import/flight review → actual saved card/day/confirmation →
  “Let’s sort the rest” → optional sign-in (“Keep your holiday with you.”,
  guests in cloud mode) → pass desk → pass/free choice → holiday
  (`OnboardingOfferFlow`). Bookings later and Explore take the same route.
  On Android the system Back button steps back, dates → destination and
  booking → dates (`stepBackFrom`, `OnboardingStore.stepBack`, which lets
  go of the holiday's empty trip so the new dates make a fresh one); it
  leaves the app only from the first screen or once a booking is saved.
  The first booking offers Flight, Stay and Activity and "Something else"
  (the other five kinds); a stay starts on the holiday's dates
  (`firstBookingDates`); a typed-in form doesn't ask to be checked
  (`onboardingFormSubtitle`); with no sign-in offered Travi goes straight
  to the desk without taking out the ID tag (`TraviCue.direct`). Manual/import proof is distinct;
  a saved booking is a start, not a claim of a complete holiday. Native services
  and premium decisions are reused. Controls never wait for decorative motion.
- Owner update 8 Oct 2026: remove the free bypass from booking success. All
  new-holiday continuations, including later booking setup and Explore, visit
  the pass desk; “Continue with free” belongs there. Existing coverage gets a
  ready state, and returning-account/shared-invite entry retains its own flow.
- The optional purchase at the pass desk (`OnboardingPassScreen`) uses the actual
  holiday and saved booking when present, with Back/free/restore outcomes.
  No holiday yet means the Annual Pass only; do not fabricate dates or a Holiday Pass. Its shared proud pose and blank paper passes are review assets;
  see `docs/ONBOARDING_PASS_DESK.md`.
- **The paywall is the pass desk** (owner, 12 Oct 2026): `PaywallScreen`
  puts `OnboardingPassPanel` on the trip's onboarding stage with Travi
  presenting, a headline for the feature reached for (`paywallWordsFor`),
  the benefits (`passBenefits`) and "Not now". Profile opens it
  for the trip on now or coming next. Nothing to scroll and Travi never
  moves (owner, 14 Oct 2026): the desk's floor starts just under his shadow
  (`snugFloor`) and a `FitColumn` (`design/widgets/fit_column.dart`) fits
  the room the stage gives it (`OnboardingFloorSpace`): the passes, the
  button and one row of "Not now" · Restore · Terms · Privacy always show,
  the benefits only while they fit, never a lesser one in a greater one's
  place. Most phones (a 13 mini to a 16) have room for one, so the first
  line carries what a pass is bought for (owner, 20 Oct 2026): "Unlimited
  bookings, and the plan on every phone" (family and
  `PremiumFeature.everyBooking` share it; one line on a 13 mini, checked by
  the fit test); the line reached for leads instead when it's another.
  Only an iPhone SE scrolls (`test/visual_qa/paywall_fit_test.dart`).
- **Two names only** (owner, changed 13 Oct 2026: "Annual Pass" says plainly
  that it's a yearly subscription, so it replaces the "Travary Plus" chosen
  on 12 Oct): **Annual Pass** (the yearly plan, `travary_annual_pass`) and
  **Holiday Pass** (one holiday, `holiday_pass`). `Offer.displayTitle`
  always says these, whatever the store's product titles; never "Trip
  Pass", "Travary Plus" or "Plus" alone in the app (code names like
  `tripPass` and `plus` stay). Scope and localized prices
  stay live from RevenueCat; Holiday Pass defaults to USD $14.99. No fixed
  “US”, fake savings, invented testimonials, trial or ticket-access lock.
- Sign-in sits immediately before the paywall (owner, 9 Oct 2026; stills
  and choreography in `docs/ONBOARDING_ACCOUNT_SCENE.md`). Keep it optional;
  plan access across phones is its benefit, not free premium file backup.
  Switching to an existing account rebuilds the app; `AppSession` carries the
  holiday so `OnboardingGate` opens its pass desk (with the "Signed in…"
  notice on the desk, not a snackbar over it), then the holiday.
- **One continuous animated story** (owner, 10 Oct 2026;
  `docs/onboarding/STORYBOARD_V2.md`). One locked camera: Travi stands on
  the same mark from the roll-in to the goodbye while the world changes
  behind him. Every pause is a **key frame** (17 poses, ChatGPT stills lined
  up to one camera by `docs/mockups/onboarding-keyframes-v1/build_keyframes.py`)
  and every move is a **film between two key frames** made in the owner's
  Scene Studio (Seedance 2.0, first + last frame, on green), so any chain
  joins seamlessly. Films: `docs/mockups/onboarding-films-v2/` (`shots.json`
  prompts, `films.py` submits/collects, `process.py` keys and trims,
  `export.py` writes `assets/onboarding/travi/{films,stills}/` as animated
  WebP with alpha and generates `lib/logic/onboarding_film_assets.dart`;
  never hand-edit it). `logic/onboarding_films.dart`: `TraviPose`,
  `traviCuesFor(beat)`, `traviRoute` (fewest films between poses; no film →
  dissolve). `design/widgets/travi_player.dart` plays them, loops each pose's
  idle, never cuts a move short, and holds still under sheets. Tests run
  with `TraviPlayer.playback = false` (`test/flutter_test_config.dart`).
- **Cameos around the app** (`docs/onboarding/HANDOVER_2026-10-10.md`):
  small, never delaying content, never on tickets, flight status, travel
  documents or a busy Today. On the paywall he presents the passes, as at
  the onboarding desk.
  `logic/travi_cameos.dart` holds the rules. Onboarding's poses
  (`TraviMoment`, `TraviCameo`): reading in Smart Import (the only one that
  moves: it's the progress), folio open on the empty Today and Trips
  states, oops when Smart Import fails or finds nothing and on the
  sync-error snackbar; still cameos load no films (`TraviPlayer.moves`).
  Peeks (`TraviPeek`, films in `assets/travi/cameos/` from
  `docs/mockups/travi-cameos-v1/`, `export.py` generates
  `travi_cameo_assets.dart`; each duck is its pop-up reversed): he hides
  behind the countdown postcard's top right (the card covers his cut),
  waves once the entry settles if it's his first greeting today
  (`TraviGreetings`, on this phone), and tapping the tag brings him up by
  days left (`countdownReactionFor`; the rest of the postcard still opens
  the trip). The New trip sheet has him waving over its top edge (it draws
  its own `SheetHandle`); a trip just created cheers in from behind its
  plan (`TripScreen.celebrate`). A free day lounges (`TraviLounge`): one
  sip with the day's greeting, another on tap.
- **Props become live UI.** What Travi throws is blank in the films; the
  app's version takes over as it leaves the frame (`TraviFilm.handoff`):
  the dates' luggage tag (`CountdownLuggageTag`), and the saved booking,
  written on the card he holds (`ProofCardWords`), then landing as its
  ledger row. Forms open out of the folio he lifts to the camera. Smart
  Import reads on the stage (the reading pose) before the check opens.
- **The world follows the destination.** `logic/onboarding_art.dart` picks
  the stage (city → region (Phuket) → Bali/Kyoto → country → a stand-in
  city for Czechia and Malaysia → Anywhere; 31 cities, Phuket, 33 countries
  and Anywhere bundled as WebP in `assets/onboarding/stages/`). Travi rolls into the paper workshop
  (`onboardingWorkshopStage`); the chosen place folds up over it like a
  pop-up page (`OnboardingScene`). Text and controls are always live UI.
- First-booking handoff still board approved 8 Oct 2026: flat folio → Travi
  straightens the saved card → approved pass desk. Motion is now authorized
  for those compositions; new compositions still need artwork approval.
  See `docs/mockups/onboarding-booking-handoff-v1/README.md`.
- Connected browser review: `docs/mockups/onboarding-workflow-v1/README.md`
  links welcome, dates, folio, approved acting, the pre-pass account scene,
  smooth pass films and an example holiday. Browser imports/flights/sign-in/
  email/billing are fixtures. New acting films
  remain browser-only; use the native preview for actual app behavior.
- Conversion events go to Firebase Analytics from release builds once Google
  Analytics is on for the project (see Premium). No production conversion
  results yet.
- Setup persists per uid, reserving the trip ID before creation. Dates stay
  null when unknown. Unsaved form/import edits keep route lifetime only.
- New places: add the stage (WebP, 851 wide, floor at 1.41 widths) to
  `onboardingCountryStages`, `onboardingCityStages` or (a region with no
  city, like Phuket) `onboardingRegionStages` in
  `logic/onboarding_art.dart`; cities inherit their country's. Unillustrated
  places use Anywhere. See
  `docs/ONBOARDING_NATIVE.md` and the destination art register.

## Conventions

- **One name for it: Smart Import** (the + sheet's row, the onboarding
  button, the paywall, errors). Never "Snap a booking" or "Add a
  screenshot or PDF" as a name; those words describe the input.
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
  visible pages) and each page's own linen (pages slide as whole cards).
  Tabs not chosen hold their animations (`TickerMode`), so nothing (Travi's
  daily wave) plays unseen. Reduced
  motion jumps instead. The nav bar stays in `bottomNavigationBar`, so pages
  need no extra bottom padding. Tests that just want a tab on screen use
  `openTab` (`test/support/open_tab.dart`); the slide is covered by
  `test/widget/tab_transition_test.dart`. Scope scroll finders to the screen
  (`find.descendant(of: find.byType(TripsScreen), ...)`): the first `Scrollable`
  in the tree is now the `PageView`'s. Today's day sheet is a second
  `PageView` inside the first tab (find the tabs' by its
  `NeverScrollableScrollPhysics`, and a day's own list as Today's vertical
  `Scrollable`).
- Never hardcode secret keys in the app; AI runs server-side (see AI).
- Mirrors kept equal by tests: art subjects, the visual vocabulary and ISO
  country list (Dart ↔ TypeScript), Trip Pass coverage (shared cases in
  `functions/src/tripPassCases.json`), `appBuildNumber` ↔ pubspec's `+N`,
  the countdown widget's file version and channel (Dart ↔ Swift ↔ Kotlin).
- The Firebase CLI shadows `node` inside `emulators:exec`; scripts use
  `$npm_node_execpath`.

## Roadmap

- **Now:** design phase (the graphic interface on top of this build).
- **v1.0 launch** (in this order): premium plumbing ✓ → Smart Import ✓
  (screenshot/PDF → Gemini in a Cloud Function → draft to confirm) → family
  sharing + ticket backup ✓ → RevenueCat + store products (+ server-side
  entitlements, trip premium stamping) ✓ (sandbox checks left). Travi
  onboarding now has its first native integration; richer rigged acting
  and launch/device checks remain.
  See `docs/PRODUCT_PLAN.md`.
- **Flight alerts:** server deployed 13 Oct 2026 and the APNs key is in
  Firebase; the real billing day is still to do (see Flight alerts).
- **Later:** a gate source for flight alerts, Live Activity / widgets, email-forward import,
  memories and recap, referrals.
- Bundle ID / Android application ID: `com.travary.app` (Firebase apps
  `ios:3d6150…` and `android:ccb966…` in travary-444).
