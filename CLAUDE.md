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
  the next trip. Past and future stay one tap away (day strip, Trips, Wallet).
- **Never lock someone's tickets.** Tickets and bookings are always reachable,
  offline, whatever their plan.
- **The look is swappable.** A unique hand-made interface ("travel ephemera":
  tickets, key cards, luggage tags, see the v1 mockup) goes on top of this
  build. Keep logic out of `design/` and styling out of `logic/`.

## Architecture

```
lib/
├── domain/     Plain data: Booking, BookingKind (+ KindSpec), Trip, LocalDate/ClockTime
├── logic/      Pure Dart rules, fully unit-tested:
│               day_plan (done/now/next), trip_plan (+ focus), trip_assignment,
│               card_text (all card wording), formatters
├── data/       TravelRepository interface; Memory (demo/tests) + Firestore;
│               demo_data; attachment_store (ticket files, offline)
├── state/      TravelStore (ChangeNotifier): the single source of truth for screens
├── design/     THE SKIN: tokens, kind_style, cards/, art/, widgets/
├── features/   Screens: today, trips, wallet, booking (form/detail/viewer), profile
└── app/        bootstrap (backend choice), app, home_shell (tabs + add button)
```

Dependencies flow downward only: `features → state → logic/data → domain`.
`design` may use `domain`/`logic` types; `logic` never imports Flutter UI.

### Rules that keep it reskinnable

1. Screens show bookings **only** through `BookingCard` (`hero` / `standard` /
   `compact`) and `OngoingStrip`. Never style a booking inline in a screen.
2. Cards receive **`CardText`** (already worded: eyebrow, title, when, detail,
   place, stub, reference) and **`ArtChoice`**. Cards never format dates or
   decide wording; add fields to `CardText` instead.
3. Visual variety comes from `ArtChoice.variant` (stable per booking) and
   artwork in `assets/art/<kind>/<theme>_*.png` (see `assets/art/README.md`).
   Use `variant % n` for any non-image variety (tilt, stamp position, palette).
4. Each kind maps to a physical object (`CardShape` in `design/kind_style.dart`):
   flight = boarding pass, stay = key card, attraction/activity/event = ticket,
   dining = reservation card + luggage tag, transport = travel ticket, note = paper.
5. Colours and type live in `design/tokens.dart` only.

### Time model

Bookings use **floating local time** (the time printed on the ticket, no zone):
`LocalDate` + optional `ClockTime`. The phone adopts the destination's zone on
arrival, so comparing with the device clock is right during the trip. No start
time = all day. `endDate` after `startDate` = multi-day (check-in/out,
pick-up/drop-off, overnight flights): start and end appear as entries on their
days; days in between show an `OngoingStrip`.

### Data (Firestore)

```
trips/{tripId}                        title, theme, ownerId, memberIds[], plannedStart/End
trips/{tripId}/bookings/{bookingId}   Booking.toJson() + a copy of the trip's memberIds[]
```

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

Cloud mode uses anonymous sign-in (enabled in the Firebase console for
`travary-444`); rules and index are deployed.

Design tools (debug builds, Profile tab): **Preview a different time** shows
cards before, during and after their time; **Reset sample trips**.

```bash
flutter analyze
flutter test
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

## AI

AI features use **Google AI Studio (Gemini API)**, called only from Firebase
Cloud Functions with the key in Secret Manager, never from the app. Project
`travary-444` is on the Blaze plan.

## Conventions

- snake_case files, PascalCase classes, `_private` members, `const` wherever possible.
- New booking wording → `logic/card_text.dart` with a test in `test/logic/`.
- New rule about time/trips → `logic/` with a unit test. Keep `logic/` pure.
- Dispose controllers/subscriptions; never use `context` in `dispose()`
  (keep a reference from `initState`).
- Layouts must survive long titles and small phones: tests run at iPhone size
  and fail on overflow.
- Never hardcode secret keys in the app; AI runs server-side (see AI).

## Roadmap

- **Now:** design phase (the graphic interface on top of this build).
- **v1.0 launch** (in this order): premium plumbing ✓ → Smart Import
  (screenshot/PDF → Gemini in a Cloud Function → draft to confirm) → family
  sharing + ticket backup → RevenueCat + store products → onboarding with the
  paywall. See `docs/PRODUCT_PLAN.md`.
- **Later:** flight alerts, Live Activity / widgets, email-forward import,
  memories and recap, referrals.
- Bundle ID is still `com.travary.travaryTemp`; change before release (needs
  new Firebase app registrations).
