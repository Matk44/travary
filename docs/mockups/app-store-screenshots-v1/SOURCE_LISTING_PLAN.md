# App Store listing (16 October 2026)

The plan for Travary's App Store page: the story, the words, the ten
screenshots, and Apple's new header and search assets (iOS 27). Screenshot
layouts and the ChatGPT prompts that finish them:
[mockups/app-store-screenshots-v1/](mockups/app-store-screenshots-v1/README.md).

## The story

The listing tells one holiday in the order it's lived: sorted, looked forward
to, checked, quick, shared, safe, yours. Three lines carry it:

- **Promise:** "Your holiday, sorted into days." (the website's headline)
- **Travi's line:** "Where are we off to?" (his first question in onboarding)
- **For the organiser:** "You planned it. Travary keeps everyone on it."

## Words

**Target keyword: "itinerary app"** (owner, 16 Oct 2026). Astro, US: itinerary
app popularity 30, difficulty 44; itinerary planner 32 and 60. Similar demand,
far less competition, so the name keeps "Itinerary App" and "planner" moves to
the keyword field, where it still combines with the name and subtitle
("itinerary planner", "trip planner", "vacation planner").

| Field | US English | UK English (also Australia) |
|---|---|---|
| Name (30) | Itinerary App - Travary | Itinerary App - Travary |
| Subtitle (30) | Vacation & trip organizer | Holiday planner & organiser |
| Keywords (100) | `holiday,countdown,packing,list,family,kids,offline,tickets,flight,passport,checklist,travel,planner` (99) | `vacation,countdown,packing,list,family,kids,offline,tickets,flight,passport,checklist,travel,trip` (97) |

Keywords never repeat a word from the name or subtitle, and keep the words the
custom product pages link to (a linked keyword can't be in the name or
subtitle). Never "disney" or any other trademark (guideline 2.3.7).

**Promotional text** (170, changes without review): "Add your bookings and
Travary sorts them into days, then opens each morning on what you need right
now, with tickets one tap away, even with no signal."

**Description:** the full UK text is on the listing page. It follows the
website's sections (no trip to set up, Today, the countdown, gaps, less
typing, sharing, passports, reminders, destinations), lists the three plans
plainly, says the Annual Pass renews yearly, and ends with the Terms of Use
and Privacy Policy links. The US copy swaps holiday → vacation, organise →
organize, colours → colors.

## Screenshots

Ten frames, linen and navy in turn, one phone centred at the same size in
every frame, Travi in front of its lower corner where he appears. The first
three show in search on iOS 26 and earlier, so they stand alone.

| # | Caption | Screen | Travi |
|---|---|---|---|
| 01 | Your holiday, / sorted into days. | Today, Orlando day 3, 8:20am (demo) | hello, overlapping |
| 02 | Counting down / to the next one. | The Lake District countdown (demo) | his own peek, in the screen |
| 03 | It spots / what's missing. | "Kyoto in spring" with its gaps (cloud) | none |
| 04 | Hand Travi / the confirmation. | Smart Import reading (tag: 2 free, then a pass) | reading, in the screen |
| 05 | Just the / flight number. | The departures board (cloud) | none |
| 06 | Everyone on / the same page. | "Who's coming", four people (cloud; tag: with a pass) | envelope, overlapping |
| 07 | Tickets that work / with no signal. | The Documents tab (demo) | none |
| 08 | Your passport stays / on your phone. | Travel documents, unlocked (demo) | none |
| 09 | Packed / together. | The Kyoto packing list (cloud) | proud, overlapping |
| 10 | Every trip gets / its own postcard. | The Trips tab, three coming trips (cloud) | wave, overlapping |

Capture in the iPhone 17 Pro Max simulator (1320 × 2868) and upload a
1206 × 2622 copy too: Apple's page names the 6.3-inch size as the required
one. Demo mode is `--dart-define=TRAVARY_BACKEND=demo` with Design tools →
Preview a different time; cloud is a debug build on a fresh guest account
(flight lookup and sharing need it; inviting from a debug build needs
`tester: true` on the organiser's `users/{uid}`). Before capturing: clear the
demo hire car's company ("Alamo"), set the status bar clock to the previewed
time (`xcrun simctl status_bar booted override --time "8:20" …`), use made-up
names and documents only. Travi's peeks last under a second: record the
simulator (`xcrun simctl io booted recordVideo`) and take the frame.

## Apple's new assets (iOS 27, live in App Store Connect since 5 Oct 2026)

- **Product page header** (21:9, 3840 × 1646, or 16:9 5244 × 2950 PNG; video
  5–30 s, loops): Travi's workshop wall with arches onto Kyoto, Bali and the
  Lake District, Travi in front, "Where are we off to?". The film chains the
  onboarding films (one locked camera, so it loops without a cut). Needs a
  wide workshop plate: new art, owner approval of the still first.
- **Search result** (3:2, 1920 × 1280 to 3840 × 2560): the promise, the Today
  and countdown screens, Travi presenting them. It replaces the three
  screenshot thumbnails for iOS 27 users.
- **Custom product pages linked to keywords** (up to 70): packing (packing,
  list, checklist), countdown, family (family, kids), documents (passport),
  flights (flight). Seasonal headers wait, pre-approved, in the Asset Library.
- No prices, discounts, URLs or awards in header and search assets.

## Never in the listing

Real brands (the old `docs/reference/travary_today_reference.png` has Disney
names), Android or Google Play (guideline 2.3.10), unreleased features
(widgets, Live Activities, email forwarding, gates and belts), "Snap a
booking", "Trip Pass", "Travary Plus", real people's names or documents.
