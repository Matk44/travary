# Trip visual profiles (automatic looks)

Each trip is classified into an **experience theme** (its look) plus a
setting, moods and a destination, so cards get fitting artwork. Countries
and cities are location metadata, never themes: a Kyoto and a Paris city
break can both be `urban_heritage` while local art packs give each its
identity (`docs/ART_PACKS.md`). The design handoff is
`docs/VISUAL_PROFILE_API_HANDOFF.md`.

## The `classifyTripVisuals` function

`functions/src/classifyTripVisuals.ts`, beside Smart Import (which still
picks each booking's `artSubject`):

1. Signed-in caller who is a member of the trip (`not-found` if the trip
   hasn't reached the server yet; the app retries).
2. The app sends a sanitized snapshot: trip ID and title, and per booking
   only ID, kind, title, place, picture subject and dates
   (`lib/logic/visual_profile_request.dart`). Never references, notes,
   tickets, times, seats, rooms, guests, prices or names. The server
   re-validates every field and bound (`visualProfileRequest.ts`) and drops
   anything else.
3. SHA-256 of the canonical snapshot plus `VISUAL_CLASSIFIER_VERSION`. If
   it matches the stored profile, that profile comes back (`cached: true`)
   without calling Gemini. Bump the version when prompt semantics or
   normalisation change.
4. Otherwise: 30 classifications per traveller per UTC day, 15 seconds
   between classifications of one trip (`resource-exhausted`, with
   `retryAfterSeconds` for the cooldown).
5. One Gemini call (structured output, `visualProfileSchema.ts`), with the
   same retry and fallback policy as Smart Import (`geminiRetry.ts`).
   Models: `VISUAL_PROFILE_MODEL` / `VISUAL_PROFILE_FALLBACK_MODEL` in
   `functions/.env`.
6. Everything Gemini returns is normalised: known values only, no
   duplicates, confidences clamped, ISO country allow-list, bounded text,
   location dropped below 0.55, `classic_travel` below 0.55 overall,
   evidence without references or contact details.
7. Places Text Search (New) checks the destination when there is a
   confident query (below).
8. Saved to the trip, unless a newer request for the trip started meanwhile
   (`aborted`). An automatic trip's `theme` follows; a manual one's never
   does.

Logs hold IDs, timings, model, attempts, tokens, confidences and statuses
only: never titles, places, evidence or the request.

## Stored on the trip

```text
theme                    effective theme (wire name); the traveller's for a manual trip
themeSource              "auto" | "manual"
visualProfile            the profile (server only)
visualProfileUpdatedAt   server timestamp (server only)
visualProfileRequest     {hash, at, by}: cooldown and last-request-wins (server only)
users/{uid}.visualClassification   {day, today, total} (server only)
```

`firestore.rules` stop the app writing the three `visualProfile*` fields and
only accept `themeSource` of `auto`/`manual`. Old trips: a classic theme (or
none) without `themeSource` is automatic, anything else manual; legacy names
(`tropical`, `city`, `snow`, `classic`) read as their new looks and are
rewritten only by a later edit. The app never bulk-migrates trips.

## Places verification and Google's terms

`PlacesLocationResolver` (behind the `LocationResolver` interface):
`POST places:searchText`, field mask
`places.id,places.displayName,places.formattedAddress,places.addressComponents,places.location,places.types`,
`pageSize: 1`, `languageCode: en`, 5-second timeout; one extra try for
network errors and 429/5xx, none for timeouts or other 4xx.

| Status | When | Stored |
|---|---|---|
| `verified` | a coherent place (country, ID, coordinates) whose country matches Gemini's and whose locality/area names Gemini's city | the itinerary's names + place ID + coordinates |
| `conflict` | Places' country differs from Gemini's | the itinerary's names; no destination art |
| `unverified` | nothing acceptable found, or Places failed | the itinerary's names; a confident country may pick country art |
| `skipped` | location confidence < 0.55 or no query | whatever confident parts remain |

Places never changes the experience theme. Google Maps Platform terms
(Service Specific Terms §14.3 and the Places API policies, reviewed Sept
2026) allow place IDs to be stored indefinitely and coordinates for 30
days, and no other Places content to be cached. So Places' address names
are only compared, never stored; coordinates carry
`coordinatesExpireAt` and the daily `purgeExpiredPlaceCoordinates` function
deletes them after 30 days. Nothing from Places is shown in the app, so no
attribution is needed; if a screen ever shows Places data, add Google Maps
attribution first. Customers billed in the EEA have separate terms.

## When the app classifies

`lib/state/visual_profile_coordinator.dart`, cloud mode only:

- after a booking is added, deleted, moved, or edited in a way the
  classifier reads (kind, name, place, subject, dates);
- after a trip is created or renamed (once it has bookings or a telling
  name);
- once per trip after a multi-booking import has finished saving;
- at once when the traveller taps **Automatic** under Card style.

Never during build, on opening Today, for cosmetic edits (times,
references, notes, tickets, picked art), or while a batch is saving. Edits
are debounced (4 s) and a payload identical to the last one sent isn't
sent again; the server hash is the final guard. Failures never block
anything: the trip keeps its look, and only the explicit Automatic tap shows
a (friendly) message.

## Operator checklist (billable services)

The app works without any of this: bundled art stays, and the Automatic
chip explains that it can't choose a look right now.

1. Enable **Places API (New)** for `travary-444`:
   `gcloud services enable places.googleapis.com --project travary-444`.
2. Create a **server-side** Maps Platform key restricted to Places API
   (New) only (Google Cloud console → APIs & Services → Credentials →
   Create API key → API restrictions: Places API (New); application
   restrictions: none/IP as appropriate for Cloud Functions). Never an
   Android/iOS key, never in the app.
3. Store it as a secret: `firebase functions:secrets:set GOOGLE_MAPS_PLATFORM_KEY`
   (paste the key when asked). Never put it in `functions/.env`, source
   control, dart-defines or generated config.
4. Confirm the Storage bucket `travary-444.firebasestorage.app` and the
   Blaze plan; scheduled functions also use Cloud Scheduler (enabled on
   first deploy).
5. Deploy rules: `firebase deploy --only firestore:rules,storage`.
6. Deploy functions: `npm --prefix functions test` then
   `firebase deploy --only functions` (adds `classifyTripVisuals` and
   `purgeExpiredPlaceCoordinates`; Smart Import is redeployed with the
   shared retry module).
7. Build the packs and dry-run the publisher (no credentials needed):
   `dart run tool/art_packs.dart build art_packs/sources/<pack> --dry-run`,
   then without `--dry-run` (writes the archive under `build/art_packs/`
   and updates `art_packs/catalog.json`), then
   `dart run tool/art_packs.dart publish --bucket travary-444.firebasestorage.app --production --dry-run`.
8. Upload the catalog and packs with your own credentials (`gcloud auth
   login`; needs `storage.objects.create` on the bucket):
   `dart run tool/art_packs.dart publish --bucket travary-444.firebasestorage.app --production`.
   Commit `art_packs/catalog.json`.
9. On a staging device (`flutter run --dart-define=TRAVARY_BACKEND=cloud`):
   add a few bookings, wait a few seconds, check the trip's Card style says
   "Automatic · …", and that matching pack art appears.
10. Check logs hold timings and statuses only:
    `gcloud logging read 'resource.labels.service_name="classifytripvisuals"' --project travary-444 --limit 20`.
