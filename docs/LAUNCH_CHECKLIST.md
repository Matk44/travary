# Launch checklist (14 October 2026)

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

- [ ] **You:** buy the AeroDataBox base plan on API.Market ($7.50, 5,000
  units). Until then every lookup fails. On 14 Oct the board answered
  "That flight couldn't be found on that day" for JL 5.
- [ ] Then set `FLIGHT_BILLING_DAY` in `functions/.env` to the day the
  plan renews and redeploy the functions.
- [ ] Store builds turn flight lookup on. To build before the plan is
  bought, run `FLIGHT_LOOKUP=false tool/build_release.sh`.
- [ ] Test a flight alert on a real iPhone.

## 4. Platform requirements

- [x] iOS: the share extension's privacy manifest
  (`ios/ShareExtension/PrivacyInfo.xcprivacy`, App Group defaults). App
  Store Connect rejects uploads without it (ITMS-91053).
- [x] iOS: `ITSAppUsesNonExemptEncryption` is false (HTTPS only), so
  uploads don't ask the export compliance question.
- [x] Android targets API 36 (Flutter's default), which Play requires of
  new apps.
- [ ] **Decide now: iPhone only, or iPad too?** The iOS target says both
  (`TARGETED_DEVICE_FAMILY = "1,2"`). That means 13-inch iPad screenshots
  and an App Review on iPad, and **iPad support can't be removed once the
  app is out**. Recommended: iPhone only for 1.0. iPads still run it in
  iPhone mode, and real iPad support can come later.
- [x] Android App Links: travary.app's `assetlinks.json` lists the upload
  and Play App Signing SHA-256s (deployed 15 Oct).

## 5. Store listings

- [ ] **Closed test first (confirmed 14 Oct).** "Dream Prayer Developer"
  is a personal account, and Travary's dashboard says it must finish
  setting up, **complete a closed test** (at least 12 testers for 14 days
  in a row) and apply for production access. Travary is a draft with an
  internal test track only. This is the longest wait on the list, so
  start it first.
- [ ] **You:** Play: Data safety, content rating, target audience (not
  children), ads (none), app access (no login needed), feature graphic
  1024×500, phone screenshots.
- [ ] **You:** App Store: App Privacy answers (analytics and push tokens,
  `docs/ANALYTICS.md`), age rating, category Travel, support URL
  `https://matk44.github.io/travary_support/`, privacy policy URL,
  6.9-inch iPhone screenshots, and review notes (no login needed; passes
  can be bought in the sandbox).
- [ ] `privacy.html`: write in the Analytics retention period.
- [ ] The GitHub copies (`matk44.github.io/travary_support`): `terms.html`,
  `index.html` and `delete-account.html` still say "Travary Plus" and "Trip
  Pass", and `index.html` says 3 free Smart Imports (it's 2). The
  travary.app privacy and terms are current: point the app's links
  (`TravaryLinks`) and the store listings at them, or bring the GitHub
  copies in step. travary.app itself said 3 free imports until 15 Oct.
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
- [ ] Publish art catalog v130 (73 packs) if the new city packs should be
  in 1.0. The bucket still serves v96.
- [ ] `tool/build_release.sh`, then TestFlight and Play internal or
  closed testing.
- [ ] This Mac had 213 MB free on 14 Oct (12 GB after clearing Travary's
  Xcode cache). An archive needs several GB.
