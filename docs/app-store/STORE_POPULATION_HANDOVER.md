# Store listing population: handover for a browser session

21 October 2026. For a new local Claude session that fills in App Store
Connect and Google Play Console from Chrome (Claude in Chrome), as **drafts**.
Read this file first; it says what's approved, where to stop, and answers
the questions the 18 October study left blocked.

## 0. Read in this order

1. This file.
2. [`aso-study/BROWSER_HANDOVER.md`](aso-study/BROWSER_HANDOVER.md): the route
   map for both consoles (pages, sections, labels, what was observed on
   18 Oct) and the logging rules. Follow it step by step.
3. [`aso-study/listing-fields.json`](aso-study/listing-fields.json): **the
   single source of truth** for every value (504 records, each with its
   `.txt` source file, limits and status). Read each value from its source
   file; never retype long copy.
4. [`aso-study/asset-map.json`](aso-study/asset-map.json): every image, its
   console bucket, upload order and SHA-256.

**Superseded, don't use:** the "Words" table in `docs/APP_STORE_LISTING.md`
and the older `docs/app-store/en-*/` files and `metadata.json` (16 Oct). The
18 Oct study replaced them (Apple subtitle "Trip planner & offline tickets",
new keywords, the ten-frame order). The app name stays **Itinerary App -
Travary** everywhere.

## 1. Owner sign-off (tick before starting)

The session works only on groups whose box is ticked. Anything unticked is
skipped and reported.

- [ ] **Copy:** the study's copy in `aso-study/copy/` for en-US, en-GB and en-AU, both stores.
- [ ] **iPhone screenshots:** `docs/mockups/app-store-screenshots-v1/final/`, Apple order 01, 07, 03, 06, 04, 09, 02, 11, 08, 10 (both the 1320 × 2868 and 1206 × 2622 buckets).
- [ ] **Header and search stills:** header v4 and search v5 PNGs from `docs/mockups/app-store-creative-v1/exports/` (stills only; the loops stay on hold).
- [ ] **In-app purchase wording:** display names "Annual Pass" and "Holiday Pass" and the study's descriptions (replacing "Travary Annual Holiday Pass").
- [ ] **Section 5 answers**, with any changes written into the "Owner" column.

## 2. What the session may and may not do

**May:** open pages, read them, type into fields, choose options, upload the
approved files, add localizations, create Google's default store listing, and
press **Save** on draft pages. Read every saved value back.

**Never, without the owner saying so in the chat at that moment:**

- Add for Review, Submit for Review, Submit to App Review, Send for review,
  Publish, Publish changes, Start rollout, or anything that releases.
- Change any price, availability, product ID, or tax, banking or agreement
  page. Never create or delete a product.
- Turn on Apple **Family Sharing** for the Annual Pass (it can't be turned off).
- Declare EU trader status, or change the selected build or version number.
- Type passwords, codes or card numbers. The owner signs in; if a page asks to
  sign in again, stop.
- Delete anything, or clear a field this file doesn't name.
- Upload stretched or cropped iPhone art as iPad or Android art.

If a console's label, limit or layout differs from the route map, stop that
field, note the difference and carry on with the next.

## 3. Before starting

- The owner opens Chrome, signs in to App Store Connect and Play Console, and
  turns on Claude in Chrome.
- Check identity first (route map §1): Apple ID **6818495253**, bundle
  **com.travary.app**; Play app ID **4974523505827658180**, package
  **com.travary.app**, developer Dream Prayer Developer. Abort on any mismatch.
- Keep a before/after ledger locally (shape:
  `aso-study/execution-log.template.json`), with no secrets in it or in
  screenshots.
- File uploads: if the browser tool can't attach a local file, name the file
  and its upload position, and let the owner drag it in from Finder.

## 4. Order of work

**Apple** (route map §2–5):

1. App Information: subtitle per locale, category Travel (no secondary),
   Privacy Policy URL, then age rating and content rights (§5).
2. App Privacy (§5).
3. Version 1.0: per locale, promotional text, description, keywords, support
   and marketing URLs, copyright (§5).
4. iPhone screenshots in both buckets, in the approved order. Skip iPad (§6).
5. Header and Search Results stills, if ticked. Preview them; never press a
   button that publishes.
6. App Review Information (§5), version release set to **Manually release**.
7. In-app purchases: localizations for both passes, subscription group
   display name; make sure both are attached to version 1.0.
8. Stop. Don't press Add for Review.

**Google** (route map §7):

1. Store settings: category Travel & Local, the one tag "Travel & local",
   email and website.
2. Create the default store listing (en-US), then en-GB and en-AU: app name,
   short and full descriptions, the 512 × 512 icon
   (`assets/branding/google_play_icon.png`). Leave phone screenshots and the
   feature graphic empty (§6) and save if the console lets you; if it won't
   save without them, record that and move on.
3. App content declarations (§5).
4. Stop. Don't press Send for review.

## 5. Answers for the blocked fields

Proposed from the app's code, `docs/ANALYTICS.md` and the published
[privacy policy](https://travary.app/privacy). The owner confirms each row;
rows marked **ASK** need the owner's answer in the chat at that point.

### Apple

| Field | Proposed answer | Why | Owner |
|---|---|---|---|
| Age rating | None or No to every question (violence, sexual content, profanity, drugs, gambling, contests, horror, medical, web access, messaging or chat, advertising, parental controls). User-generated content: **No**, because trips are shared only with people the organiser invites by code and nothing is public. Expect 4+. | No such content; links open travary.app in the browser | |
| Content rights | Yes, shows third-party content (flight schedules from AeroDataBox via API.Market; text read by Google's Gemini; Google Places IDs); yes, Travary has the rights (paid licences and API terms). | Flight lookup and Smart Import | |
| App Privacy: collected | **Contact info:** name, email (only on sign-in with Apple, Google or email), linked, App Functionality. **User content:** photos or videos (ticket photos backed up on shared or pass trips), other user content (trips, bookings, notes, checklists, packing lists, PDFs), linked, App Functionality. **Identifiers:** user ID (account and RevenueCat ID), linked, App Functionality; device ID (Firebase installation ID), not linked, Analytics and App Functionality. **Purchases:** purchase history, linked, App Functionality. **Usage data:** product interaction, not linked, Analytics. **Diagnostics:** crash data, not linked, App Functionality. **Location:** coarse location (country from IP, Firebase), not linked, Analytics. | Privacy policy §1, ANALYTICS.md | |
| App Privacy: not collected | Health, financial info, precise location, sensitive info, contacts, browsing or search history. Travel documents stay on the phone, so they're not collected. **Tracking: No.** | No ad ID on either platform | |
| Accessibility labels | Leave blank. No claims until VoiceOver, larger text and the rest are tested on the release build. | Voluntary; claims must be true | |
| Export compliance | Nothing to do: `ITSAppUsesNonExemptEncryption` is NO (HTTPS only). If asked, exempt encryption only. | Info.plist | |
| Regulated medical device | No. | | |
| Digital goods questionnaire | **ASK.** | Business or regional question | |
| Trader status (EU) | **ASK.** As a trader, your address, phone and email show on EU product pages; not declaring keeps the app out of the EU. | Owner's legal decision | |
| Copyright | `2026 Dream Prayer Developer` | The maker named in the legal pages | |
| Review contact | **ASK:** the owner types their own name, phone and email. | Private | |
| Sign-in required | Untick, once the owner confirms the selected build opens as a guest. | Guest accounts | |
| Review notes | The text below. | | |
| Pricing and availability | Free. Countries: **ASK** (the study suggests Australia first, then the UK and the US, for learning; availability can still be everywhere). | | |
| Version release | Manually release this version. | Launch control | |
| Build | **ASK:** confirm the newest processed build that passed TestFlight (main's log mentions Build 8). Don't swap it otherwise. | | |
| Purchases on the version | Attach `travary_annual_pass` and `holiday_pass` to version 1.0. | First purchases are reviewed with the version | |
| Subscription group display name | `Travary` | | |
| Annual Pass Family Sharing | Leave **off**. | Irreversible; sharing works per trip in the app | |
| Tax, banking, agreements | Don't touch. | Owner only | |

**App Review notes** (paste as written):

```text
Travary needs no sign-in: it opens as a guest. To try it, tap + and add a booking
(only a title and a date are needed), or use Smart Import with a screenshot of a
booking confirmation.

In-app purchases: the Holiday Pass (one payment for one holiday, holiday_pass) and the
Annual Pass (auto-renewing yearly subscription, travary_annual_pass) can be bought in the
sandbox. The pass desk opens from any paid action, for example inviting someone from a
trip's "Who's coming", or from Profile. Restore, Terms of Use and Privacy Policy sit under
the purchase button; Profile > Help and legal has both links too.

Account deletion: Profile > Delete account.

AI (guideline 5.1.2(i)): before anything is sent to Google's Gemini (Smart Import, or a
trip's automatic look), the app asks on a consent sheet, and nothing is sent until the
traveller taps Allow. The answer can be changed in Profile.

Passports and other travel documents are stored only on the device, behind Face ID or the
passcode, and are never uploaded.

The countdown widget (free) is added from the home screen's widget gallery. Flight alerts
are optional push notifications about flight changes on trips with a pass; permission is
asked when such a flight is first opened, never at launch.

Questions: dreamprayer.dev@gmail.com
```

### Google

| Field | Proposed answer | Why | Owner |
|---|---|---|---|
| Data safety: overview | Collects data: Yes. Encrypted in transit: Yes. Deletion: Yes, in the app (Profile > Delete account) and at https://travary.app/delete-account. Shared with third parties: No (Google, RevenueCat and AeroDataBox act as service providers). | Privacy policy | |
| Data safety: types | **Personal info:** name, email (optional; account management). **Financial info:** purchase history (app functionality). **Photos and videos:** photos (optional; app functionality). **Files and docs** (optional; ticket PDFs; app functionality). **App activity:** app interactions (analytics), other user-generated content (trips, bookings, notes; app functionality). **App info and performance:** crash logs, diagnostics (app functionality, analytics). **Device or other IDs:** installation ID and notification token (app functionality, analytics). Approximate location: check Firebase's [Play data disclosure](https://firebase.google.com/docs/android/play-data-disclosure) and match it. | ANALYTICS.md | |
| App access | All functionality available without special access (guest). Paid features need a purchase, not credentials. | | |
| Ads | No ads. Advertising ID: not used. | AD_ID removed | |
| Content rating (IARC) | Category: utility, productivity, communication or other. No violence, sexuality, language, drugs or gambling. Users interact or share content: **Yes** (trip members see each other's bookings and tickets). Shares location: No. Digital purchases: Yes. | | |
| Target audience | 18 and over. | Keeps the app out of the Families policy | |
| Financial features, health, government, news | None, None, No, No. | | |
| Permissions declarations | None needed. The app doesn't request photos, videos, storage or exact alarms (removed); it has notifications and boot completed only. | AndroidManifest | |
| Countries and regions | **ASK.** | | |
| Pricing and products | Free. Don't create or price products; check that the existing ones are named "Annual Pass" and "Holiday Pass" and report. | | |
| Managed publishing | Recommend **on**, so nothing goes live until the owner publishes: **ASK** before switching it. | | |
| Production access | Not this session: a closed test with 12 testers for 14 days comes first. | Launch checklist | |

## 6. Still missing: skip and report

- **iPad screenshots.** The iOS target is still iPhone and iPad
  (`TARGETED_DEVICE_FAMILY = "1,2"`), so App Store Connect needs 13-inch iPad
  screenshots before it accepts the version. Either make real iPad captures
  and frames, or make the app iPhone-only before the first release (a code
  change and a new build; iPad can't be dropped once the app is out). Owner's
  decision; a separate task.
- **Android phone screenshots and the 1024 × 500 feature graphic.** The
  frames are drawn around an iPhone and show iOS screens, so they can't be
  used on Google Play. They need Android emulator captures in frames without
  an iPhone, plus a feature graphic. A separate task.
- **Header and search loops:** on hold until the owner approves playback.
- **Custom product pages** (Apple "Family & packing", Google "Family trip
  planner"): only after the app is live (route map §6 and §8).

## 7. Finish with a report

List, for each console: fields saved (with read-back), fields left as they
were, fields skipped (unticked or ASK) and why, assets uploaded (file, bucket,
order), and anything that differed from the route map. Then stop. Submitting
for review is the owner's next, separate decision.

## Starting the session

Open Claude Desktop with Claude in Chrome on, sign in to both consoles, tick
section 1, and send:

```text
Work in /Users/khairofamily/AndroidStudioProjects/Travary. Read
docs/app-store/STORE_POPULATION_HANDOVER.md and follow it exactly, using the files it
lists. I've ticked the sign-off in section 1 and I'm signed in to App Store Connect and
Play Console in Chrome. Start with Apple, then Google. Fill and save drafts only. Ask me
at every ASK, never press a submit or publish button, and finish with the report in
section 7.
```
