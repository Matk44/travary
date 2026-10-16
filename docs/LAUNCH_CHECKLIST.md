# Launch checklist (14 October 2026, checked again 16 October)

What's left before Travary goes to Google Play and the App Store. Ticked
items were checked or done on 14 Oct 2026. "You" means the owner (console
work, accounts, money); everything else can be done in this repo.

## 1. Sign-in

- [x] **Google sign-in on Android needs nothing in Play Console.** It needs
  every signing key's SHA-1 in Firebase, and all three are there: debug
  (`FE:87:B9…`), the upload key (`3D:5C:42…`) and Play App Signing
  (`B3:E1:4C:F6:74:8A:2A:9F:A5:7B:52:4B:24:11:E9:C4:DB:36:61:05`).
  `google-services.json` has an OAuth client for each. Checked in Play
  Console on 14 Oct: the app signing key in use and the upload key match
  Firebase exactly. A second, "quantum-ready (beta)" signing key is listed
  with no installs; it signs nothing yet.
- [x] Google Auth Platform (the OAuth consent screen) for `travary-444` is
  **In production**, External, with the app name Travary and
  dreamprayer.dev@gmail.com as support email (checked 14 Oct; it's under
  that account, not mathew.khairo@gmail.com).
- [x] Branding (15 Oct): logo (the app icon, 120 px), home page
  `https://travary.app`, privacy `https://travary.app/privacy`, terms
  `https://travary.app/terms` (new pages naming Dream Prayer Developer),
  `travary.app` authorised, developer contact dreamprayer.dev@gmail.com.
  travary.app is now verified in Search Console for dreamprayer.dev too.
  Verified and published: Google sign-in now shows Travary and its logo.
- [ ] **Decide:** launch with email sign-in or without it. It's off unless
  the build passes `TRAVARY_EMAIL_LINKS=true`, and it needs the setup in
  `docs/EMAIL_LINK_SIGN_IN.md`. Apple and Google cover most people.

## 2. Purchases

- [x] `tool/build_release.sh` builds the store uploads with RevenueCat's
  keys and refuses to build without them. A release build without keys
  now refuses to start, where before it would have simulated purchases
  (premium for free).
- [ ] **You:** App Store Connect: set the price of the Annual Pass
  (`travary_annual_pass`). Name the products "Annual Pass" and "Holiday
  Pass", and give each one a review screenshot (the pass desk). In-app
  purchases go to review together with the first app version.
- [ ] **You:** Play Console: name the products "Annual Pass" and "Holiday
  Pass".
- [ ] **You:** buy each pass in the sandbox on both stores, end to end:
  the pass desk, then the trip unlocked, then Restore.

## 3. Flight data

- [x] The AeroDataBox Pro plan ($7.50, 5,000 units, schedules 180 days
  ahead) was bought on API.Market (15 Oct) and the key works.
- [x] `FLIGHT_BILLING_DAY=15` in `functions/.env` (07:28, 16 Oct) and the
  functions redeployed an hour later (08:28), so it's live.
- [ ] Test a flight alert on a real iPhone (a test push reached the
  simulator on 15 Oct).

## 4. Platform requirements

- [x] iOS: the share extension's privacy manifest
  (`ios/ShareExtension/PrivacyInfo.xcprivacy`, App Group defaults). App
  Store Connect rejects uploads without it (ITMS-91053).
- [x] iOS: `ITSAppUsesNonExemptEncryption` is false (HTTPS only), so
  uploads don't ask the export compliance question.
- [ ] **You:** iOS: the countdown widget's App ID,
  `com.travary.app.CountdownWidget`, with the App Group
  `group.com.travary.app` (like the share extension's), so device and
  TestFlight builds sign. Then add the widget on a real iPhone and tap its
  tag (`docs/COUNTDOWN_WIDGET.md`). It has its own privacy manifest
  (`ios/CountdownWidget/PrivacyInfo.xcprivacy`, no reasons needed).
- [x] Android targets API 36 (Flutter's default), which Play requires of
  new apps.
- [ ] **Decide now: iPhone only, or iPad too?** The iOS target says both
  (`TARGETED_DEVICE_FAMILY = "1,2"`). That means 13-inch iPad screenshots
  and an App Review on iPad, and **iPad support can't be removed once the
  app is out**. Recommended: iPhone only for 1.0. iPads still run it in
  iPhone mode, and real iPad support can come later.
- [x] Android App Links: travary.app's `assetlinks.json` lists the upload
  and Play App Signing SHA-256s (deployed 15 Oct).
- [x] **Android download over Google Play's 200 MB limit (fixed 15 Oct).**
  The release bundle was 245 MB and a phone's download about 203 MB (bundletool
  `get-size total`, 202.5 MB for an arm64 phone), over Play's 200 MB base
  cap, almost all of it bundled PNG art. All 99 bundled PNGs (138.3 MB:
  `assets/art/` and three onboarding pictures) are now WebP like the art
  packs (cwebp q88, alpha exact, same pixel sizes: 20.3 MB). Now: bundle
  129 MB, a phone's download **86.4 MB** (arm64, API 34; 86.0 to 86.5 MB
  across every phone configuration); iOS `Runner.app` 271 MB to 153 MB
  (zipped, as an .ipa roughly is: 215 MB to 99 MB), so it's well under the
  200 MB that makes iOS ask before downloading over mobile data. The
  PNG masters are in `art_masters/bundled/`; new bundled art goes through
  `dart run tool/art_packs.dart bundled-webp` (`assets/art/README.md`), and
  a test fails if a PNG is ever bundled again. Looks checked: `tool/visual_qa.sh`
  before and after (110 renders, 32 identical, the rest within a few
  levels of colour, no halos on `documents_halo_{light,dark}`), the two
  Documents goldens regenerated for the same tiny differences, and the
  iOS Simulator (Today, Trips, a trip, Documents, Profile, onboarding).
- [x] Android permissions (15 Oct): the release build no longer asks for
  photos, videos, audio or shared storage (open_filex declared them;
  Travary only opens files in its own folders, which needs none) or the
  advertising ID (Firebase Analytics' AdServices ones). Play only allows
  photo and video access for apps built around a photo library. What's
  left: internet, notifications, restart (reminders), biometrics (travel
  documents), billing and push.
- [x] **Apple 5.1.2(i): ask before sending anything to AI** (built 15
  Oct). Apple requires apps to say clearly when personal data goes to a
  third-party AI and to get explicit permission first. Nothing goes to
  Google's Gemini (Smart Import's file, or trips' and bookings' names and
  places for automatic looks) until the traveller taps Allow on the
  consent sheet: at Smart Import before the file is chosen, from a trip
  page's "Dress up this trip?" offer, at Trip details' "Automatic", or
  from Profile's switch. The privacy policy says so too (live on
  travary.app since 16 Oct). In the App Review notes, mention the sheet.
- [ ] **Closed test first (confirmed 14 Oct).** "Dream Prayer Developer"
  is a personal account, and Travary's dashboard says it must finish
  setting up, **complete a closed test** (at least 12 testers for 14 days
  in a row) and apply for production access. Travary is a draft with an
  internal test track only. This is the longest wait on the list, so
  start it first.
- [ ] **You:** Play: Policy → App content shows 11 declarations needing
  attention (15 Oct), starting with privacy policy, ads (none), app access
  (no login needed) and content rating; also target audience (not
  children) and Data safety. If it asks about the advertising ID: Travary
  doesn't use it (removed from the manifest). Plus a feature graphic
  1024×500 and phone screenshots.
- [ ] **You:** App Store: App Privacy answers (analytics and push tokens,
  `docs/ANALYTICS.md`), age rating, category Travel, 6.9-inch iPhone
  screenshots, and review notes (no login needed; passes can be bought in
  the sandbox). URLs are in the next items.
- [ ] `privacy.html`: write in the Analytics retention period.
- [x] Support, privacy, terms and delete-your-data pages are on travary.app
  (`/support`, `/privacy`, `/terms`, `/delete-account`), and the app links
  there (15 Oct). The old GitHub Pages copies return 404: don't use them
  anywhere.
- [ ] **You, App Store Connect:** Privacy Policy URL
  `https://travary.app/privacy`; Support URL `https://travary.app/support`;
  and, because the Annual Pass auto-renews, add a line to the end of the
  App Description: "Terms of Use: https://travary.app/terms" (or paste the
  terms into the custom EULA field). In the review notes, say where the
  links are: the pass desk (any premium action, or Profile → Annual Pass)
  shows Terms of Use and Privacy Policy under the button; Profile → Help
  and legal has both too.
- [ ] **You, Play Console:** Privacy policy URL `https://travary.app/privacy`;
  Data safety → account deletion URL `https://travary.app/delete-account`.
- [x] Pass desk: each pass shows its title, price, period and whether it
  renews; Restore, Terms of Use and Privacy Policy (full names) sit on one
  line under the button on every phone size tested with the real fonts.
  Profile → Annual Pass has "Manage or cancel" for subscribers (Google asks
  for a way to cancel inside the app). Account deletion is in Profile
  (Apple 5.1.1(v)).
- [ ] **Decide:** the home-screen name. "Itinerary App - Travary" is cut
  off under the icon ("Itinerary A…"). Store search ranks the store
  listing's title, not the name under the icon. The listing can stay
  "Itinerary App - Travary" while the phone says "Travary".

## 6. Test data (just before launch)

What production (`travary-444`) holds on 14 Oct, all from testing: 11
trips, 12 bookings, 9 user records, 1 invite, 9 cached flight answers, 2
push tokens, and 19 accounts (17 guests, 1 Apple, 1 Google). No passes and
no tester flags.

- [ ] Wipe it **after closed testing ends and just before release**, or
  testers lose their trips mid-test. That means the Firestore documents
  above, the ticket files in Storage and every Auth account. Ask Claude;
  it needs your go-ahead.
- [ ] **You:** in Firebase, delete the leftover apps "travary (android)"
  (`com.travary.travary_temp`) and "travary (ios)"
  (`com.travary.travaryTemp`). Choose "Travary iOS" when Firebase asks
  which app.
- [ ] Repo: decide what happens to the untracked art staging (632 MB),
  `docs/reviews/` and `test/widget/failures/`.

## 7. Release

- [ ] Commit, merge `design/c2-art` into `main`, and bump the version
  (`pubspec.yaml` and `lib/app/build_info.dart`, which the script checks).
- [x] Art catalog v234 (83 packs) is published (15 Oct).
- [ ] `tool/build_release.sh`, then TestFlight and Play internal or
  closed testing. On 15 Oct both release builds compiled cleanly (Android
  bundle 129 MB and 86 MB per phone, iOS app 153 MB, after the WebP art:
  see the 200 MB limit above), all 1,218 app tests and 120 server tests
  pass, and analyze and format are clean.
- [x] **Crash reporting** (16 Oct): Firebase Crashlytics in release
  builds (Flutter, Dart and native crashes), never linked to an account.
  Checked in an Android release build on the emulator (Crashlytics starts
  and collects). The privacy policy says so and is live on travary.app.
  **You:** add crash data to the store forms (`docs/ANALYTICS.md`, "Store
  privacy forms"): Apple *Diagnostics → Crash Data*, Play *App info and
  performance → Crash logs*, both not linked to identity.
- [ ] **Run it on a real iPhone and a real Android phone** before inviting
  testers: a TestFlight build and the Play internal track. Nothing so far
  has been checked off a simulator or emulator: Apple and Google sign-in,
  a sandbox purchase, Face ID on travel documents, the share extension,
  reminders and a flight alert.
- [ ] Push to GitHub: 9 commits on `design/c2-art` (15 and 16 Oct, the
  WebP art and the AI consent included) exist only on this Mac.
- [ ] Keep disk space free: the Mac filled up twice (14 and 15 Oct)
  building Android and iOS releases one after the other. An archive needs
  several GB; `build/` alone holds about 4 GB after both.
