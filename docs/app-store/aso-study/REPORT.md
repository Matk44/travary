# Travary ASO and conversion study

**Research date: 18 October 2026, Australia/Sydney. Status: proposed, unapproved. Local preparation only.**

## Recommended launch configuration

Keep **Itinerary App - Travary** exactly as it is, on both stores and in all three English localizations. Lead with bookings in time order, offline saved tickets and visible gaps. Use Apple subtitle **Trip planner & offline tickets** and Google short description **Keep bookings in order, save tickets offline and spot gaps in your trip.** Complete, measured listings for en-US, en-GB and en-AU follow in this report and in `copy/`.

Prioritize Australia for operational launch checks and learning, then the UK, then the US. This is a product/language/support recommendation, not a claim of greater Australian search volume or lower competition. Prepare all three English listings now. Existing holiday-oriented artwork fits AU/UK best; US descriptions use vacation and American spelling, while the reused artwork remains visibly the existing English artwork. Do not delay launch solely to manufacture three nearly identical art sets.

Start with the default listing on each store. Prepare **one additional family intent page per store**: Apple **Family & packing**, Google **Family trip planner**. These are the first eligible post-approval/publication pages, not prerequisites for the initial version. Exact copy and orders are supplied. Keep the primary “Itinerary App” journey on the default Apple listing. Do not assume its occurrence in the title makes it selectable for an organic CPP.

Use the existing approved header v4 and search v5 **stills** for the first Apple creative assignment after final placement preview. Hold loop revision2 until owner playback approval. Recommend ten Apple screenshot subjects in this order: **01 Today, 07 tickets, 03 gaps, 06 family, 04 Smart Import, 09 packing, 02 countdown, 11 widget, 08 documents, 10 postcards**. Use eight corresponding subjects on Google, omitting documents and postcards. Actual Android captures and a Google feature graphic are missing; the iPhone assets cannot be submitted as their replacements. iPad captures are also missing while the iOS target remains universal.

No new generation, motion, purchases, campaigns, uploads, saves, review submissions or live listing changes were performed. Existing source listing files and unrelated working-tree changes were preserved. The machine handover includes all proposed assignments and explicit null blockers.

## Evidence and product truth

The required project instructions, listing drafts, screenshot source plan/log/manifest/final files, proposed selection, creative README/delivery manifest, widget documentation and launch checklist were read. Relevant implementation checks covered pricing/access, Smart Import enforcement, purchase IDs, native widgets, flight lookup limits, analytics and support links. Local files are product evidence; they do not certify every behavior in the selected release build.

| Material conflict / claim | Resolution used in proposed copy |
|---|---|
| Old product plans, “Plus”, former names and old allowances | Current user-facing names are Holiday Pass and Annual Pass. Free allowance:2 lifetime Smart Imports and2 ticket files per trip. Unlimited manual bookings/trips. Source import file uses a ticket slot. [Pricing](/Users/khairofamily/AndroidStudioProjects/Travary/lib/domain/pricing.dart), [access](/Users/khairofamily/AndroidStudioProjects/Travary/lib/logic/access.dart). |
| “Unlimited Smart Import” in older drafts | Server has `DAILY_LIMIT = 25`. New copy says more Smart Imports, subject to a daily usage limit; no unconditional unlimited claim. Local code does not prove deployed backend parity: include in release verification. [Enforcement](/Users/khairofamily/AndroidStudioProjects/Travary/functions/src/smartImport.ts). |
| Widget described as unreleased in old source brief | Both native platforms implemented; simulator/emulator checked. iOS widget requires17+, main app supports earlier iOS. Real-device release checks remain. [Widget record](/Users/khairofamily/AndroidStudioProjects/Travary/docs/COUNTDOWN_WIDGET.md). |
| Old manifest describes green-screen plates | Final PNGs contain actual app captures. Visually inspected all11 completed subjects. No blanket owner approval inferred from export completion; proposed order still needs review. |
| Flight provider purchase stale in memory | Launch checklist records purchase15October. Lookup approximately7days past to180days ahead; live window3days before to1day after. Coverage/timing varies; no guaranteed live gates/belts. Paid alerts and device behavior need checks. Omitted from acquisition promises to avoid overstating flight reliability. [Launch checks](/Users/khairofamily/AndroidStudioProjects/Travary/docs/LAUNCH_CHECKLIST.md). |
| Holiday Pass versus subscription | One-time pass covers one trip up to30days, paid features through7days after end; Annual auto-renews yearly. Sharing covers6 including organiser and covered trip members. Saved bookings/tickets remain accessible after expiry. App sharing differs from Apple's separate Family Sharing switch. |
| Personal documents | Stored on device behind its lock; no automatic trip sharing or Smart Import transmission. Manual send-copy behavior means “never shareable” would be false. No encryption certification or compliance claims. |
| Purchase configuration | Annual yearly product observed in ASC, Prepare for Submission. Current purchase display name/description “Travary Annual Holiday Pass” conflicts with app wording. Proposed shorter Annual Pass purchase metadata supplied, separate from store promotion. Holiday product configuration and Google products still need verification. |
| iPhone-only launch suggestion versus current build | Current target includes iPhone and iPad. Required iPad artwork cannot silently be dropped. Recommendation: capture actual iPad UI; changing target is separately approved engineering work. |

Travary's strongest defensible proposition is a calm place to use bookings already made. Smart Import produces a checked draft. It is not email forwarding, a booking marketplace, route optimization, generated itineraries, live gates/belts, or Live Activities. Searches dominated by those expectations should not drive the listing promise.

Public support, privacy, terms, website and deletion pages were checked: [support](https://travary.app/support), [privacy](https://travary.app/privacy), [terms](https://travary.app/terms), [website](https://travary.app/), [deletion](https://travary.app/delete-account). Public support email is dreamprayer.dev@gmail.com. Reachability is not a completed privacy/deletion audit. Exact Analytics retention and release store declarations remain owner/product checks.

## Search observations and market opportunity

Country-specific discovery was observed on18October2026 in desktop Chrome. Apple results came from the public iTunes software Search API with country US/GB/AU, limit15, unauthenticated. They are **API result positions, not measured native iPhone organic ranks**; the API does not identify ads. Google observations used public desktop Play search with explicit `gl` country and `hl` language, with country/language footers checked. The browser was signed in: personalization and desktop rendering can affect results. No sponsored label was seen in the sampled Play results; that does not prove native Android ad absence.

| Store / query | US first results | UK first results | AU first results |
|---|---|---|---|
| Apple API / itinerary app | Wanderlog, TripIt, Itineraries(TravelJoy), Tripsy, Structured, Towngas Metering, Funliday, Tripadvisor | Wanderlog, TripIt, Structured, CheckMyTrip, Stippl, Tripsy, Tripadvisor, Rhyme | Wanderlog, TripIt, Tripsy, Stippl, CheckMyTrip, Tripadvisor, Funliday, Travee |
| Google desktop / itinerary app | Wanderlog, TripIt, Stippl, Tripadvisor, Rome2Rio, Polarsteps, GetYourGuide, Itinerate | TripIt, Wanderlog, Tripadvisor, Stippl, Polarsteps, GetYourGuide, Rome2Rio, Holicay | Wanderlog, TripIt, Stippl, Tripadvisor, Rome2Rio, Polarsteps, GetYourGuide, Itinerate |
| Apple API / family trip planner | Roadtrippers, Wanderlog, TripIt, Wanderjoy | Roadtrippers, TravelPlannerTripWay, Layla, Wanderjoy | Roadtrippers, BaliFamilyFinds, Roameo, NSW Sydney Trip Planner |
| Apple API / offline itinerary | Tripsy, CityMaps2GoPro, Tripomatic, YouLiTrip | Stippl, MAPS.ME, CityMaps2GoPro, YouLiTrip | MAPS.ME, Stippl, Tripadvisor, CityMaps2Go |

[Raw Apple observations](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/evidence/apple-search-api.json) preserve identities, URLs and positions, including noisy irrelevant matches. They demonstrate why API order must not be presented as native rank.

Additional Play samples: US **family trip planner** began Wanderlog, Tripadvisor, EasyRoad Family Trip Planner, Roadtrippers, Roadie, TripIt. UK **offline itinerary** began Offline Map Navigation(VirtualMaze), Organic Maps, Wanderlog, Offline Maps & AI Trip Planner(Aykonu), OsmAnd and MAPS.ME. AU **holiday countdown** began Vacation Countdown App(Kulana), Holiday Countdown(Webtoweb), Days To(miniminiapps), Countdown by Holiday Extras and Vacation Countdown(Copur). [US family search](https://play.google.com/store/search?q=family%20trip%20planner&c=apps&hl=en_US&gl=US), [UK offline search](https://play.google.com/store/search?q=offline%20itinerary&c=apps&hl=en_GB&gl=GB), [AU countdown search](https://play.google.com/store/search?q=holiday%20countdown&c=apps&hl=en_AU&gl=AU).

The primary query is contested by mature planners with reviews and strong visible proof. It also spans several intents: creating a trip, keeping reservations, planning sightseeing routes, and buying activities. Travary can address the reservations/day-of branch credibly. “Offline” alone often signals maps; pair it with saved bookings or tickets. Countdown traffic is adjacent and may activate a widget without adding a booking. It belongs below core itinerary proof until data supports a distinct page.

No Travary first-party search/conversion baseline was available: both stores are prelaunch. No proprietary volume, difficulty, rank, predicted uplift or old Astro scores are reused. Review counts are storefront snapshots, not query volume or proof of ranking causality.

### Prioritized keyword map

Priority is qualitative sequencing, not a fabricated numerical score. Confidence describes fit/evidence, not predicted ranking.

| Priority / query cluster | Intent and fit | Store / market | Evidence and competition | Proposed placement / confidence |
|---|---|---|---|---|
| P1 itinerary app | Keep or construct trip itinerary; high fit for booked-trip branch | Both; US/UK/AU | Wanderlog/TripIt repeatedly visible; native ranks unknown | Fixed title; default screenshots and opening description. High fit; opportunity size unknown. |
| P1 trip planner / trip organiser / trip organizer | Broad planning, sometimes generation or maps | Both; local spelling | Tripsy/TripIt/Wanderlog occupy overlapping positioning | Apple subtitle “Trip planner”; local organizer/organiser keyword; natural Google text. High fit with bookings qualifier. |
| P1 offline tickets / offline bookings | Retrieve saved material while travelling | Both; all | UK offline query maps-heavy; competitor offline often premium | Apple subtitle tickets/offline; Google short and first paragraphs; frame07 second. High fit, demand unmeasured. |
| P1 family trip planner / shared trip | Coordinate people and bookings | Both; all | Play US includes family-specific apps and established planners; Lambus group proof | Apple family/shared tokens, family CPP when eligible; Google family CSL. High fit; paid sharing disclosed. |
| P2 packing / packing checklist | Prepare luggage; may expect weather-generated packing | Both; all | PackPoint specializes; review reveals multistop needs | Apple packing/checklist tokens; middle copy/frame09, family page. Medium discovery confidence; no weather automation promise. |
| P2 holiday planner / vacation organizer | Leisure planning using bookings | UK/AU holiday; US vacation | Same planner competition; terminology inference, no volume proof | Local keyword strings/description. High product fit, medium search evidence. |
| P2 travel documents / booking organizer | Storage/organization; may expect secure cloud vault | Both; all | TripIt/Lambus documents prominent | Local keyword document/booking, accurate local-device explanation; later screenshot. Medium: avoid secure-vault absolute claim. |
| P3 holiday/vacation countdown / widget | Anticipation, quick glance | Both; all | Play AU standalone countdown apps visible | Lower description/frame02/11; no separate launch page. High feature fit, uncertain valuable activation. |
| Exclude from acquisition targeting: AI itinerary generator, route optimizer, navigation/offline maps, hotel/flight booking, email forwarding, live gate/baggage tracker | Feature mismatch | Both; all | Broad results include maps, transport and marketplaces | Do not insert these terms, adopt competitor promises or buy mismatched traffic. |

The smallest useful additional input is one dated export for the exact primary query and these six clusters, separately by store/country, containing query, country, observed native position, measurement date and any tool-provided popularity/difficulty with tool/version identified. No tool purchase is needed to finish this proposal. After launch, add28days of store acquisition by country/language/source with impressions or visitors, first-time downloads/acquisitions and conversion denominator. A native-phone audit should capture the first20 visible entries and each paid badge for the exact query plus family trip planner and offline tickets; record OS, storefront/account and date. Do not silently combine that with API positions.

## Competitor audit

Six live identities were verified, with first screenshot sequences visually inspected in the public Apple web listings on18October. Prices below are displayed IAP catalog entries, not a promised current personalized paywall. Old reviews are identified as historical and never treated as current unresolved bugs. This is a purposive, small sample; theme frequency and representativeness are unknown.

| Competitor / market / identity | Visible positioning and first screenshots | Offer snapshot and observed review theme | Implication for Travary |
|---|---|---|---|
| [TripIt: Travel Planner](https://apps.apple.com/us/app/tripit-travel-planner/id311035142), US, TripItInc | First sequence spans itinerary phone across two frames, anniversary ribbon, then press/rating proof; blue, direct chronology. Email reservations and alerts are core. | Free + Pro1year USD48.99;4.8/312K. 2022 public reviews praise organization, question email access and ask for clearer family/passenger overview. Historical sample. | Show chronology first; prove family clarity and checked import. Do not borrow press/rating badges or email promise. |
| [Wanderlog – Travel Planner](https://apps.apple.com/gb/app/wanderlog-travel-planner/id1476732439), UK, Vacation and Travel Planner App LLC | Bright first-frame itinerary/map, long travel document, reservation import; later route optimization. |4.9/3.8K UK. Catalog multiple annual entries £24.99–£59.99, not one verified checkout price. [Play listing](https://play.google.com/store/apps/details?id=com.wanderlog.android) sampled August2026 praise for routes/transport and complaints about upsells/performance with developer response. | “Simplified” alone is weak differentiation. Use specific missing-booking and offline-ticket proof; avoid map-led expectation. |
| [Tripsy: Travel Planner](https://apps.apple.com/us/app/tripsy-travel-planner/id1429967544), US, TripsyLLC | First frame awards/rating claims over city photo; next companion phone then dense trip organizer. Maps, activities and flight detail follow. |4.7/5.7K. Annual catalog entries USD39.99 and59.99; monthly4.99/7.99 among offers. August2025 review praises collaborative work/family sports travel. | Brand polish helps, but Travary must establish practical benefit without unearned awards. |
| [Lambus / Travel Planner](https://apps.apple.com/us/app/lambus-travel-planner/id1446178879), US, LambusGmbH | Muted beige sequence: trip map, stops/activities, accommodation/documents, expenses, companions. Group utility plainly shown. |4.7/81. Monthly3.99, yearly24.49, lifetime89.99, per-trip8.99 USD catalog. Older2019–2021 reviews discuss chronology, place search and files; chronology request got a2020 feature response. | Group travel is crowded; pair six-person sharing with packing and day-of tickets. Old requests are not current Lambus deficiencies. |
| [Tripomatic Trip Planner & Maps](https://apps.apple.com/us/app/tripomatic-trip-planner-maps/id519058033), US, Tripomatic s.r.o. | Current identity formerly Sygic Travel. First frames emphasize planning/map, discovering places, exploring maps; terse labels and illustrated sights. |4.6/3.3K. Yearly23.99/monthly3.99; other Premium29.99 catalog entry has no verified period. 2023 review praises consolidated planning, requests calendar/Pencil tools. | Do not compete on sightseeing/navigation promises. Show already-booked travel and gaps. |
| [PackPoint Travel Packing List](https://apps.apple.com/us/app/packpoint-travel-packing-list/id896337401), US, Wawwo | First three real screens: destination/dates, activities, packing checklist. Almost no marketing overlay. |4.7/2.5K. Premium2.99, custom activities0.99 and TripIt integration0.99 USD catalog. April2025 multistop complaint acknowledged by developer inMay. | Packing is a specialist acquisition expectation. Travary's shared list belongs with the family journey; don't imply weather/activity-generated lists. |

Competitors' platform coverage differs. These six are not claimed to all have Android equivalents. Google search evidence independently establishes Android competition. Their large ratings, editorial marks and pricing cannot be copied into Travary's trust claims. Build trust through real UI, clear allowances, live support/privacy links and successful release tests. Ask for reviews at a suitable successful-use moment under store rules; no incentives or selective positive-review gating proposed.

## Platform mechanics and targeting

### Apple default listing, locales and creative placements

Name/subtitle allow30characters; promotional text170, description4,000. The technical version reference specifies keywords100UTF-8bytes while marketing guidance calls them100characters. Use ASCII keyword strings and validate both. Promotional text is conversion copy, with no search-ranking benefit claimed. First version has no What's New requirement. [Metadata reference](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information), [product page](https://developer.apple.com/app-store/product-page/).

Apple names title, subtitle, keywords and category among text-relevance inputs, alongside behavioral signals. No fixed weighting or guaranteed combination rank is documented. Its deduplication guidance says not to repeat title/subtitle/category words in the keyword field. This is not itself proof of CPP eligibility. App Store Search analytics also includes Apple Ads; keep paid reports separate. [Search guidance](https://developer.apple.com/app-store/search/).

The initial locale codes are **en-US**, **en-GB**, **en-AU**. Supported storefront defaults are EnglishUS for US, EnglishUK for UK and EnglishAustralia for AU; AU also lists UK as a secondary supported language. User language/storefront and available localization determine display fallback; primary EnglishUS remains the app's primary localization. Upload explicit strings for all three. Supported-display localization does not prove cross-indexing or that US keyword changes rank the UK. [Localization matrix](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations).

Dedicated **Header** and **Search Results** placements serve iOS/iPadOS27+; earlier presentations still depend on icon/title/subtitle and screenshots/previews. Each new placement holds one asset. Existing header3840×1646 and search3840×2560 are valid shape/resolution choices. Approved Asset Library assets can be reused and later placement changes published; inspect the explicit publishing step rather than assuming Save is always private. [Asset management](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets), [WWDC2026](https://developer.apple.com/videos/play/wwdc2026/205/).

Header accepts21:9 image3840×1646 and universal16:9 image5244×2950; search3:2 ranges1920×1280 to3840×2560, with universal support. Images opaque; video5–30seconds,30/60fps, supported MP4/MOV/M4V. Search audio is muted; silent existing loops fit the purpose. The two7second/30fps revision2 files are recorded with actual probe data in asset-map. [Creative specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications).

Use Preview for device/language/orientation safe areas. The wide header is brand atmosphere; subtitle and first screenshots must carry practical meaning. Search v5 shows a real Today phone with a readable promise, but phone UI is small. Native placement preview remains essential; do not assume desktop thumbnails prove final legibility. [Asset best practices](https://developer.apple.com/app-store/asset-best-practices/).

Apple screenshots allow1–10 per size, opaque PNG/JPEG. Current English specifications and console require a Dynamic Island **medium** screenshot:1206×2622 copies exist. Add1320×2868 large set for explicit control. iPad13-inch requires2064×2752 or2048×2732 if supported. Older translated documentation still names6.9-inch as the main bucket; current English documentation and Travary's actual console agree on medium, so the handover follows those. No Watch app, App Clip or routing coverage is proposed. [Current screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).

### Apple organic CPP issue: the fixed title does not establish eligibility

**Do not plan an organic CPP for “Itinerary App” from title membership.** Apple's current CPP instructions specify selection from the **latest approved app-version keywords**, per localization; they do not offer free entry of arbitrary queries. The working source is the version's Keywords metadata, distinct from the broader text indexed for default search. Our proposed Keywords values deliberately omit “itinerary” and “app”. Consequently there is no verified supported eligible entry for that exact phrase in this configuration.

A remaining evidence boundary must be explicit: the official public instructions examined do **not expressly enumerate the exclusion of title/subtitle terms**, and this app has no approved version exposing its selector. Therefore a blanket claim that a duplicated title term could never appear in the selector was **not independently verified**. Generic deduplication advice and third-party reports do not establish that restriction. The executable decision is complete: keep the exact query on the default listing, do not duplicate title terms solely to force a CPP, and block any exact-query CPP assignment unless the real approved selector or Apple Support confirms eligibility. Record this narrow limitation instead of fabricating a verified rule.

The family page's candidate source tokens **family, packing, shared** are present in each saved locale's Keywords string. Select only actual offered entries, then capture the precise combination and overlap rules. Do not invent broad/exact-match controls or guarantee every longer query containing a token will route there. [CPP configuration](https://developer.apple.com/help/app-store-connect/create-custom-product-pages/configure-multiple-product-page-versions).

CPPs support70pages, iOS/iPadOS15+, localized screenshots/previews/promotional text, and unique generated URLs. Approval and visible status are required. Documentation says creation requires Ready for Distribution in at least one territory, although Travary's prelaunch console exposes a creation dialog; no created page or eligibility was inferred. Default handles unmatched users; disabled/deleted page URLs fall back there. Metrics appear after5first-time downloads. Optional approved universal/custom deep links work when users on18+ tap Open; no family route or deferred-install behavior is invented. Keyword **Publish** and approved-page edits can change live routing; gate them separately. [CPP overview](https://developer.apple.com/app-store/custom-product-pages/), [configuration workflow](https://developer.apple.com/help/app-store-connect/create-custom-product-pages/configure-multiple-product-page-versions).

**PPO** is a randomized experiment on the default page, with up to3treatments and localization controls after distribution eligibility. CPPs are not PPO experiment targets. Legacy help emphasizes icon/screenshots/previews; the newer2026 creative documentation supports header/search experimentation. Verify available controls in the actual test form. Tests measure store conversion, not downstream genuine-booking activation. [PPO overview](https://developer.apple.com/help/app-store-connect/create-product-page-optimization-tests/overview-of-product-page-optimization/), [new creative testing](https://developer.apple.com/videos/play/wwdc2026/205/).

**Apple Ads** separately buys placements and can use CPP creatives. It is optional future research, with its own budget, attribution and paid-match settings. No advertising work or spend is needed for this launch proposal. Do not confuse an ad selecting a CPP for an exact query with eligibility to route that organic query.

Apple's tags are generated with model/human review, currently available in the US, and developers manage offered assignments rather than type arbitrary tags. No assigned tags were observed for Travary; JSON blocks selection until actual tags appear. Keep accurate offered trip/itinerary tags and remove misleading ones. [Tag rules](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-tags).

### Google main listing and custom listings

Main listing fields are App name30, Short description80, Full description4,000characters. There is no Apple-style hidden keyword metadata field. Main listing appears across release tracks; release notes belong to each track/build. The console currently has no default listing. App typeApp and categoryTravel & Local are recommended; tag **Travel & local** was actually observed. Up to5relevant tags are allowed, but one appropriate tag suffices. [Listing setup](https://support.google.com/googleplay/android-developer/answer/9859152), [category/tag guidance](https://support.google.com/googleplay/android-developer/answer/9859673).

en-US/en-GB/en-AU are supported. Main language selection follows the user's preferred language and available translation, with default-language fallback and sometimes machine translation offered. Custom listings do not automatically translate: give all three explicit versions and EnglishUS default. Country targeting and language localization are separate decisions. [Translations](https://support.google.com/googleplay/android-developer/answer/9844778).

Google CSLs independently support up to50pages and can change app name, icon, short/full descriptions and graphics. Contact/privacy/category are shared. Target modes include country(one country-specific CSL per country), user state/audience, unique URL and Google Ads campaigns, alongside search keywords. URL parameters use a chosen unique lowercase identifier; campaign support does not imply targeting Play search ads. Do not combine all modes in the first family page. [Custom listing rules](https://support.google.com/googleplay/android-developer/answer/9867158).

For search targeting Google exposes traffic-derived terms and search for other terms, with **View variations** for spelling/translation bundles. There is no documented title/subtitle exclusion comparable to the Apple source issue. “Itinerary App” may be a candidate even though in the fixed app name, but eligibility and matching variants must be checked in the actual published-listing selector. A title match alone does not guarantee selectable targeting. Keep it on the main listing at launch. Recommend family trip planner/shared trip planner for the single CSL, selecting only appropriate verified variants. Main listing handles unmatched traffic; unavailable CSL locales use its configured default. A published main listing and available targeting controls are dependencies, not facts already satisfied. [CSL targeting](https://support.google.com/googleplay/android-developer/answer/9867158).

Phone screenshot minimum2; maximum8per device bucket. Basic dimensions320–3840 and long side at most twice short side. Recommendation eligibility expects at least4high-resolution9:16portrait(1080×1920) or16:9landscape frames; favor real UI in the first3 and keep taglines under20% of image. Existing1320×2868 and1206×2622 iPhone artwork exceeds2:1 and depicts iOS. Capture Android. Required feature graphic1024×500, icon512×512. Alt text≤140characters is supplied for every proposed phone frame and feature graphic. [Graphics rules](https://support.google.com/googleplay/android-developer/answer/9866151).

Google promotional video takes a **YouTube URL**, public/unlisted, without ads, age restrictions, playlist/time parameters. It precedes screenshots; feature graphic becomes poster, and muted autoplay can show part of the video. Launch without it. Later, prepare a short actual Android booking-to-Today walkthrough; approve static storyboard/keyframes first, then motion, then YouTube setup. Apple brand MP4 loops are neither Android screenshots nor a supported direct Google video upload.

Store Listing Experiments currently support a published fully rolled-out main/custom listing, graphics or localized text, up to2variants, configurable confidence/MDE and primary metric choices including unique-user install clicks, opens or preregistration. Current guidance allows automatic stopping after6months; don't reuse older3variant/90day assumptions. Inspect actual metric labels at setup. Use localized UK English first if it has sufficient traffic. [Current experiment documentation](https://support.google.com/googleplay/android-developer/answer/12053285).

## Creative audit and recommended page configurations

The icon has a recognizable coral suitcase face on turquoise, readable at small size, with a passport travel cue. Fine tag/eye details reduce at small sizes; the overall silhouette survives. It communicates travel and personality more than itinerary utility, so retain it and let adjacent copy/UI explain the task. No icon test is needed before first launch.

All completed screenshots were visually inspected together and at useful scale. [Contact sheet](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/evidence/screenshot-contact-sheet.jpg), [header still](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/evidence/header-v4.jpg), [search still](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/evidence/search-v5.jpg). Tactile paper, postcards and Travi form a coherent identity. Big headlines read well; small phone UI, supporting captions and paid labels need native preview. Travi should direct attention to real booking content rather than crowd it.

| Existing subject | Audit / decision |
|---|---|
|01Today | Strong primary proof: actual time-ordered bookings. Existing holiday headline preserved; opens the default sequence. |
|07offline tickets | Direct practical reassurance; current file-list view is less concrete than an opened ticket. Keep now; future actual offline-ticket view test needs owner still approval. |
|03gaps | Distinctive “what's missing” promise; actual UI labels small. Third frame makes a specific reason to choose Travary. |
|06family | Group membership is visible; shared daily plan less visible. Preserve “With a pass” and six-person cap. First frame only on family intent page. |
|04SmartImport | Cream lower half accurately depicts loading. Weak conversion proof because it stops before reviewed draft. Keep in middle, never invent a populated UI. Later replace/test with real checked draft after approval. “2 free, then a pass” remains. |
|09packing | Clear list utility; retain shared packing purchase disclosure. Second on family page. |
|02countdown | Attractive postcard/anticipation; weak answer to primary query. Move after utility proof. |
|11widget | Real native home-screen concept; magnified composition can obscure widget boundaries. Preview as actual screen and validate released widget. |
|08documents | Useful privacy reassurance but not core acquisition; iOS FaceID artwork belongs only on appropriate Apple UI. Copy uses general device lock, avoiding universal biometrics promise. |
|10postcards | Brand reward and trip collection; final frame. |
|05flight entry | Accurate subject but lookup timing/coverage adds qualification. Omit from selected10; record as existing unused alternative. |

New caption adaptations are **later proposals**, not altered approved assets: default first headline could become “Your bookings, in order.”; offline “Saved tickets. No signal needed.”; gaps “Spot the missing stay.”; family “One trip. Up to six people.” with “With a pass”; import “Check the draft. Keep the booking.” with “2 free, then a pass”. These would need real UI and static approval. Launch assignment reuses existing captions exactly, recorded in asset-map; no image edits were made.

| Page | Purpose / first3 and complete screenshot subject order | Copy / creative / targeting / fallback |
|---|---|---|
| Apple default, all3locales | Today → offline tickets → gaps proves chronology, access and missing-booking value. Complete:01,07,03,06,04,09,02,11,08,10. | Full localized default fields below. Existing header v4/search v5 stills. Primary query/default search; unmatched/older devices fall back to normal listing presentation. |
| Apple Family & packing, all3locales, first eligible postlaunch | Family → packing → Today explains paid coordination and underlying itinerary. Complete:06,09,01,07,03,04,02,11,08,10. | Localized promotional text below; inherited default name/subtitle/description; same approved still creatives initially. Eligible family/packing/shared selector entries only. No deep link. Generated CPP URL recorded after creation. |
| Google default, all3locales | Today → offline tickets → gaps; complete01,07,03,06,04,09,02,11. | Full localized listing below. Existing icon; missing Android shots and default feature graphic. Main search/default fallback. No video. |
| Google Family trip planner, all3locales, first eligible postlaunch | Family → packing → Today; complete06,09,01,07,03,04,02,11. | Complete distinct short/full descriptions below; same fixed name/icon and shared contact details. Missing family feature graphic and actual Android captures. Search keyword variants verified before use; no country/audience/campaign target. No video or deep link. |

Exact **absolute paths, device buckets, dimensions, file hashes, locale/page assignments, upload orders and missing work** are in [asset-map.json](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/asset-map.json). English artwork is intentionally reused across locales, not mislabeled as separately localized. iPhone medium+large assets exist; iPad and Android remain null, never filenames pointing at imaginary exports. Google tablet frames are optional future promotion work, not minimum phone-release blockers; actual device support/layout determines which buckets apply. Current inventory includes all11iPhone subjects and both loop revision2 alternatives, even where not assigned.

Purchase promotion is unnecessary at launch. Annual store metadata should align to Annual Pass; Holiday Pass needs trip context. App Store promotion needs approved dedicated1024×1024 imagery and handling for purchase initiated from the store; that flow was not verified. Existing review screenshots are not promotional graphics. Proposed product copy below stays within conservative current IAP reference limits30/45; confirm subscription form counters before its later save. Keep commercial IDs/durations/prices/Family Sharing/multiseat settings unchanged until separately reviewed. [IAP metadata](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information/).

## Measurement and 30/60/90-day learning plan

A store rank observation, search impression, listing visit, install, genuine booking, useful trip session and paid pass are different outcomes. Users can install from search without opening a product page, so listing visits are not a universal funnel stage. Compare each metric only with its defined eligible denominator.

| Measure | Definition / source / practical limitation |
|---|---|
| Query visibility | Dated native-store query position and paid badge, by country/OS/context. Current API/desktop observations are proxies, no Travary rank baseline. |
| Discovery | Store search impressions or relevant visitors by country/source; track paid separately. Apple Search source can contain ads. |
| Conversion | Store's displayed download/acquisition/install-click conversion and exact denominator. Log definition and redownload treatment, never divide unlike stores' metrics blindly. |
| Valuable activation | Unique eligible new users adding at least1real, non-demo booking within7days / eligible new users with full7day observation. `onboarding_booking_added` is available but genuine/non-demo classification and later-booking coverage need verification/instrumentation. |
| Useful usage | Activated users using Today/saved-ticket/packing on relevant travel dates; explicit plan/ticket-use measurement may need instrumentation. Widget tap alone does not prove a useful booking. |
| Sharing | Eligible activated trip organisers who successfully add another member / activated organisers eligible to share. Invite created or shared is not successful join. |
| Revenue | Net proceeds/refunds and appropriate pass purchases per eligible acquired/activated cohort; inspect renewals separately. RevenueCat integration/attribution needs verification. |

[Analytics documentation](/Users/khairofamily/AndroidStudioProjects/Travary/docs/ANALYTICS.md) records release Firebase events and RevenueCat purchase data, with advertising ID disabled. There is no proven deterministic CPP/CSL-to-Firebase user attribution in the current implementation. Use store-reported randomized conversion for experiment decisions, and aggregate release/country activation as a guardrail with an attribution caveat. Do not claim a particular page caused an individual purchase without validated linkage. Avoid sending booking/document details as analytics.

| Timing / experiment | Hypothesis and supported method | Control / variant; traffic | Primary metric / denominator | Guardrails, inputs and decision rule |
|---|---|---|---|---|
| Before launch | Bookings-first promise is understood and all promised features work. Task-based release QA, not an ASO statistical experiment. | Proposed default on both stores, AU/UK/US copy and native previews. | Comprehension and successful booking/offline retrieval checks. | Resolve real-device widget/import/offline/pass/reviewer checks and missing art. No ranking/uptick claim. Google production timing depends on12testers/14continuous days plus application, not study calendar. |
| Days1–30 after actual launch | Default attracts relevant travellers. Establish baseline without simultaneous changes. | Keep approved copy/assets stable; segment country, locale, source and OS. | Store conversion using its own defined denominator;7day booking activation separately. | Need exposure/acquisition counts and cohort age. Exclude internal/test data and track paid separately. Investigate errors/irrelevant reviews; do not declare success from a few installs. |
| Days31–60, only sufficient traffic | Offline-ticket proof second improves default conversion over countdown second. Apple PPO, one treatment. | Current proposed default order versus same set with countdown second; other fields fixed. One locale first, selected traffic allocation recorded. | PPO first-time download/conversion result over eligible randomized exposure as defined by console. | Baseline conversion, weekly exposures, practical MDE, confidence and test duration/power inputs required. Use calculator. Choose variant only if supported evidence and no credible activation/refund deterioration; otherwise inconclusive/control. Calendar does not guarantee significance. |
| Days31–60 or later, sequential | Clear offline/gap short description improves Google conversion. Localized Store Listing Experiment. | Saved main short description versus “Your bookings, tickets and daily plans together. Saved tickets work offline.” Name/full copy/screens fixed; UKEnglish if adequate. | Console unique-user install clicks / exposed eligible users, if offered; log exact definition. | Baseline, MDE and confidence set before start. Adopt only positive meaningful supported result; no early peeking or other concurrent variable changes. Aggregate7day activation guardrail lacks page-level causal attribution. |
| Days61–90 or later | Family-intent pages better match family searches and produce appropriate pass use. CPP/CSL cohort analysis, not randomized causal comparison. | Family pages with verified routing versus their historical main-listing query cohort. Country/source held comparable where possible. | Page first-time downloads or acquisitions / page exposures/visitors, exactly as reported. | Apple minimum5downloads is privacy threshold, not adequate power. Need page volume, query availability, country mix, dates. Account for selection/seasonality; do not infer uplift from unlike query cohorts. No matched traffic means keep default, don't force more pages. |
| Later, after actual UI/still approval | Reviewed-draft SmartImport proof beats loading screen. Apple PPO or Google graphics experiment, one variable. | Existing04 versus genuine reviewed draft; disclosures identical. | Platform randomized conversion with exact denominator. | Requires final capture and owner still approval. Motion optional later. Baseline/power and import failure/activation guardrails. |

Test copy variants above are optional experiments, not alternatives to the final recommended listing. Their exact strings and computed counts are separately stored under `copy/google/en-GB/test_variant/` and listed in validation. Never let an experiment replace the fixed title.

Days90+ roadmap: evaluate a countdown-specific page only if countdown traffic adds real bookings/pass value; consider document intent only if privacy expectations fit; refine localization from actual queries; test search v5 still versus approved revision2 motion through available creative controls. Do not launch dozens of pages without traffic.

Optional paid work would require a separately approved market, campaign/query plan and spend cap; an initial small AU diagnostic budget could be proposed after baseline collection. No numerical budget is assumed authorized, no campaigns launched, and paid results must never be relabeled organic uplift.

## Approval boundaries and execution readiness

All proposed text is complete; platform/account declarations remain null where evidence is insufficient. The minimal owner decisions are: approve the concrete copy and screenshot/page order; identify copyright/reviewer contact and confirm declarations/commercial setup; approve actual missing device captures/Google feature graphics; confirm release candidate and manual/managed publishing choice. These are grouped in VALIDATION, not repeated per field as new permission requests. The study is complete even though account/creative/release dependencies prevent automated live population today.

Apple exact title/subtitle CPP eligibility remains the narrow unresolved platform question described above. It does not block the supported default-listing strategy or supplied family page. Later Codex must verify the approved selector before selecting any candidates and stop only that routing action if unsupported.

[Browser handover](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/BROWSER_HANDOVER.md) gives the sequential execution and publishing boundaries. [Machine fields](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/listing-fields.json) carry exact values, counts, source paths, actions and null blockers. [Validation](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/VALIDATION.md) records reproducible checks. No status in this proposal asserts owner approval.


## Complete field values and computed counts

All strings below are exact. Each text file has UTF-8 encoding, LF paragraph breaks and no trailing newline. Long descriptions are complete. CPP title, subtitle and description inherit the same locale's default Apple listing and are not separately editable. Values in administrative rows remain blocked. A count marked N/A means no verified cap, not an invented unlimited allowance.

### Apple / en-US

#### default — Name

Record `apple-en-US-default-name`. Action: **retain**. 23 characters; 23 UTF-8 bytes; limit 30 characters; remaining 7; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/name.txt).

<!-- COPY:apple-en-US-default-name -->
```text
Itinerary App - Travary
```
<!-- END_COPY:apple-en-US-default-name -->

#### default — Subtitle

Record `apple-en-US-default-subtitle`. Action: **fill**. 30 characters; 30 UTF-8 bytes; limit 30 characters; remaining 0; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/subtitle.txt).

<!-- COPY:apple-en-US-default-subtitle -->
```text
Trip planner & offline tickets
```
<!-- END_COPY:apple-en-US-default-subtitle -->

#### default — Keywords

Record `apple-en-US-default-keywords`. Action: **fill**. 87 characters; 87 UTF-8 bytes; limit 100 UTF-8 bytes; remaining 13; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/keywords.txt).

<!-- COPY:apple-en-US-default-keywords -->
```text
family,shared,packing,checklist,vacation,countdown,booking,organizer,documents,reminder
```
<!-- END_COPY:apple-en-US-default-keywords -->

#### default — Promotional Text

Record `apple-en-US-default-promotional-text`. Action: **fill**. 152 characters; 152 UTF-8 bytes; limit 170 characters; remaining 18; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/promotional-text.txt).

<!-- COPY:apple-en-US-default-promotional-text -->
```text
Start with a booking. See each day in order, keep saved tickets offline and spot missing stays. Share trips and packing with up to 6 people with a pass.
```
<!-- END_COPY:apple-en-US-default-promotional-text -->

#### default — Description

Record `apple-en-US-default-description`. Action: **fill**. 2524 characters; 2524 UTF-8 bytes; limit 4000 characters; remaining 1476; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/description.txt).

<!-- COPY:apple-en-US-default-description -->
```text
Your bookings, in order. Your tickets, close at hand. Travary is an itinerary app for the trips you have booked, from the first confirmation to the journey home.

ADD A BOOKING. SEE YOUR TRIP TAKE SHAPE.
Add flights, stays, activities and restaurant bookings. Travary builds trips around their dates, so you can start with what you have already booked. Organize a weekend away or a family vacation without building a plan from scratch.

KNOW WHAT IS NEXT
Today puts the day's bookings in time order. Keep confirmation details and tickets beside the plans they belong to, and spot gaps such as a night without a stay or a missing flight home.

KEEP SAVED TICKETS OFFLINE
Save your bookings and ticket files before you leave. Open them without a connection when you need them. Saved bookings and tickets stay accessible on every plan, including after a pass ends. Importing and syncing shared changes need an internet connection.

CHECK THE DRAFT, THEN KEEP IT
Give Smart Import a booking screenshot, photo or PDF. Travi reads it into a draft for you to check and correct before saving. You get 2 free Smart Imports in total. Your imported source file counts towards your ticket-file allowance.

TRAVEL TOGETHER
With a pass, share a trip with up to 6 people, including the organizer. Keep the group's bookings and packing list together, with each person's tickets easy to find. One pass covers the people sharing that trip.

ENJOY THE COUNTDOWN
Give each trip a destination postcard, tick off packing and to-do lists, and set reminders. Keep your next vacation in sight with a home-screen countdown widget. Widgets require iOS 17 or later.

KEEP PERSONAL DOCUMENTS PERSONAL
Personal travel documents stay on your device behind its lock. They are not automatically shared with your trip or sent to Smart Import.

START FREE. CHOOSE A PASS WHEN YOU NEED MORE.
Create trips and add bookings free. Each free trip can keep 2 ticket files. A pass adds sharing, shared packing, more ticket files and more Smart Imports, subject to a daily usage limit.

Holiday Pass is a one-time purchase for one trip of up to 30 days, with pass features available until 7 days after it ends. Annual Pass is a yearly subscription that renews automatically unless cancelled. Prices are shown in the app before purchase. Manage or cancel Annual Pass in your App Store account settings.

Start with your next booking. Travi will meet you there.

Support: https://travary.app/support
Privacy: https://travary.app/privacy
Terms: https://travary.app/terms
```
<!-- END_COPY:apple-en-US-default-description -->

#### default — Support URL

Record `apple-en-US-default-support-url`. Action: **fill**. 27 characters; 27 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/support-url.txt).

<!-- COPY:apple-en-US-default-support-url -->
```text
https://travary.app/support
```
<!-- END_COPY:apple-en-US-default-support-url -->

#### default — Marketing URL

Record `apple-en-US-default-marketing-url`. Action: **fill**. 20 characters; 20 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/marketing-url.txt).

<!-- COPY:apple-en-US-default-marketing-url -->
```text
https://travary.app/
```
<!-- END_COPY:apple-en-US-default-marketing-url -->

#### custom_product_page — Promotional Text

Record `apple-en-US-family-promotional-text`. Action: **fill**. 158 characters; 158 UTF-8 bytes; limit 170 characters; remaining 12; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/family/promotional-text.txt).

<!-- COPY:apple-en-US-family-promotional-text -->
```text
Keep the family on the same page. Share bookings and packing with up to 6 people, including the organizer, with a pass. Saved tickets stay accessible offline.
```
<!-- END_COPY:apple-en-US-family-promotional-text -->

#### holiday_pass — Display Name

Record `apple-en-US-holiday_pass-display-name`. Action: **fill**. 12 characters; 12 UTF-8 bytes; limit 30 characters; remaining 18; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/holiday_pass/display-name.txt).

<!-- COPY:apple-en-US-holiday_pass-display-name -->
```text
Holiday Pass
```
<!-- END_COPY:apple-en-US-holiday_pass-display-name -->

#### holiday_pass — Description

Record `apple-en-US-holiday_pass-description`. Action: **fill**. 43 characters; 43 UTF-8 bytes; limit 45 characters; remaining 2; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/holiday_pass/description.txt).

<!-- COPY:apple-en-US-holiday_pass-description -->
```text
Sharing and extras for a trip up to 30 days
```
<!-- END_COPY:apple-en-US-holiday_pass-description -->

#### travary_annual_pass — Display Name

Record `apple-en-US-travary_annual_pass-display-name`. Action: **fill**. 11 characters; 11 UTF-8 bytes; limit 30 characters; remaining 19; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/travary_annual_pass/display-name.txt).

<!-- COPY:apple-en-US-travary_annual_pass-display-name -->
```text
Annual Pass
```
<!-- END_COPY:apple-en-US-travary_annual_pass-display-name -->

#### travary_annual_pass — Description

Record `apple-en-US-travary_annual_pass-description`. Action: **fill**. 41 characters; 41 UTF-8 bytes; limit 45 characters; remaining 4; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/travary_annual_pass/description.txt).

<!-- COPY:apple-en-US-travary_annual_pass-description -->
```text
Sharing and extras for your trips, yearly
```
<!-- END_COPY:apple-en-US-travary_annual_pass-description -->

### Apple / en-GB

#### default — Name

Record `apple-en-GB-default-name`. Action: **retain**. 23 characters; 23 UTF-8 bytes; limit 30 characters; remaining 7; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/name.txt).

<!-- COPY:apple-en-GB-default-name -->
```text
Itinerary App - Travary
```
<!-- END_COPY:apple-en-GB-default-name -->

#### default — Subtitle

Record `apple-en-GB-default-subtitle`. Action: **fill**. 30 characters; 30 UTF-8 bytes; limit 30 characters; remaining 0; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/subtitle.txt).

<!-- COPY:apple-en-GB-default-subtitle -->
```text
Trip planner & offline tickets
```
<!-- END_COPY:apple-en-GB-default-subtitle -->

#### default — Keywords

Record `apple-en-GB-default-keywords`. Action: **fill**. 86 characters; 86 UTF-8 bytes; limit 100 UTF-8 bytes; remaining 14; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/keywords.txt).

<!-- COPY:apple-en-GB-default-keywords -->
```text
family,shared,packing,checklist,holiday,countdown,booking,organiser,documents,reminder
```
<!-- END_COPY:apple-en-GB-default-keywords -->

#### default — Promotional Text

Record `apple-en-GB-default-promotional-text`. Action: **fill**. 152 characters; 152 UTF-8 bytes; limit 170 characters; remaining 18; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/promotional-text.txt).

<!-- COPY:apple-en-GB-default-promotional-text -->
```text
Start with a booking. See each day in order, keep saved tickets offline and spot missing stays. Share trips and packing with up to 6 people with a pass.
```
<!-- END_COPY:apple-en-GB-default-promotional-text -->

#### default — Description

Record `apple-en-GB-default-description`. Action: **fill**. 2522 characters; 2522 UTF-8 bytes; limit 4000 characters; remaining 1478; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/description.txt).

<!-- COPY:apple-en-GB-default-description -->
```text
Your bookings, in order. Your tickets, close at hand. Travary is an itinerary app for the trips you have booked, from the first confirmation to the journey home.

ADD A BOOKING. SEE YOUR TRIP TAKE SHAPE.
Add flights, stays, activities and restaurant bookings. Travary builds trips around their dates, so you can start with what you have already booked. Organise a weekend away or a family holiday without building a plan from scratch.

KNOW WHAT IS NEXT
Today puts the day's bookings in time order. Keep confirmation details and tickets beside the plans they belong to, and spot gaps such as a night without a stay or a missing flight home.

KEEP SAVED TICKETS OFFLINE
Save your bookings and ticket files before you leave. Open them without a connection when you need them. Saved bookings and tickets stay accessible on every plan, including after a pass ends. Importing and syncing shared changes need an internet connection.

CHECK THE DRAFT, THEN KEEP IT
Give Smart Import a booking screenshot, photo or PDF. Travi reads it into a draft for you to check and correct before saving. You get 2 free Smart Imports in total. Your imported source file counts towards your ticket-file allowance.

TRAVEL TOGETHER
With a pass, share a trip with up to 6 people, including the organiser. Keep the group's bookings and packing list together, with each person's tickets easy to find. One pass covers the people sharing that trip.

ENJOY THE COUNTDOWN
Give each trip a destination postcard, tick off packing and to-do lists, and set reminders. Keep your next holiday in sight with a home-screen countdown widget. Widgets require iOS 17 or later.

KEEP PERSONAL DOCUMENTS PERSONAL
Personal travel documents stay on your device behind its lock. They are not automatically shared with your trip or sent to Smart Import.

START FREE. CHOOSE A PASS WHEN YOU NEED MORE.
Create trips and add bookings free. Each free trip can keep 2 ticket files. A pass adds sharing, shared packing, more ticket files and more Smart Imports, subject to a daily usage limit.

Holiday Pass is a one-time purchase for one trip of up to 30 days, with pass features available until 7 days after it ends. Annual Pass is a yearly subscription that renews automatically unless cancelled. Prices are shown in the app before purchase. Manage or cancel Annual Pass in your App Store account settings.

Start with your next booking. Travi will meet you there.

Support: https://travary.app/support
Privacy: https://travary.app/privacy
Terms: https://travary.app/terms
```
<!-- END_COPY:apple-en-GB-default-description -->

#### default — Support URL

Record `apple-en-GB-default-support-url`. Action: **fill**. 27 characters; 27 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/support-url.txt).

<!-- COPY:apple-en-GB-default-support-url -->
```text
https://travary.app/support
```
<!-- END_COPY:apple-en-GB-default-support-url -->

#### default — Marketing URL

Record `apple-en-GB-default-marketing-url`. Action: **fill**. 20 characters; 20 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/marketing-url.txt).

<!-- COPY:apple-en-GB-default-marketing-url -->
```text
https://travary.app/
```
<!-- END_COPY:apple-en-GB-default-marketing-url -->

#### custom_product_page — Promotional Text

Record `apple-en-GB-family-promotional-text`. Action: **fill**. 158 characters; 158 UTF-8 bytes; limit 170 characters; remaining 12; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/family/promotional-text.txt).

<!-- COPY:apple-en-GB-family-promotional-text -->
```text
Keep the family on the same page. Share bookings and packing with up to 6 people, including the organiser, with a pass. Saved tickets stay accessible offline.
```
<!-- END_COPY:apple-en-GB-family-promotional-text -->

#### holiday_pass — Display Name

Record `apple-en-GB-holiday_pass-display-name`. Action: **fill**. 12 characters; 12 UTF-8 bytes; limit 30 characters; remaining 18; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/holiday_pass/display-name.txt).

<!-- COPY:apple-en-GB-holiday_pass-display-name -->
```text
Holiday Pass
```
<!-- END_COPY:apple-en-GB-holiday_pass-display-name -->

#### holiday_pass — Description

Record `apple-en-GB-holiday_pass-description`. Action: **fill**. 43 characters; 43 UTF-8 bytes; limit 45 characters; remaining 2; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/holiday_pass/description.txt).

<!-- COPY:apple-en-GB-holiday_pass-description -->
```text
Sharing and extras for a trip up to 30 days
```
<!-- END_COPY:apple-en-GB-holiday_pass-description -->

#### travary_annual_pass — Display Name

Record `apple-en-GB-travary_annual_pass-display-name`. Action: **fill**. 11 characters; 11 UTF-8 bytes; limit 30 characters; remaining 19; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/travary_annual_pass/display-name.txt).

<!-- COPY:apple-en-GB-travary_annual_pass-display-name -->
```text
Annual Pass
```
<!-- END_COPY:apple-en-GB-travary_annual_pass-display-name -->

#### travary_annual_pass — Description

Record `apple-en-GB-travary_annual_pass-description`. Action: **fill**. 41 characters; 41 UTF-8 bytes; limit 45 characters; remaining 4; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/travary_annual_pass/description.txt).

<!-- COPY:apple-en-GB-travary_annual_pass-description -->
```text
Sharing and extras for your trips, yearly
```
<!-- END_COPY:apple-en-GB-travary_annual_pass-description -->

### Apple / en-AU

#### default — Name

Record `apple-en-AU-default-name`. Action: **retain**. 23 characters; 23 UTF-8 bytes; limit 30 characters; remaining 7; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/name.txt).

<!-- COPY:apple-en-AU-default-name -->
```text
Itinerary App - Travary
```
<!-- END_COPY:apple-en-AU-default-name -->

#### default — Subtitle

Record `apple-en-AU-default-subtitle`. Action: **fill**. 30 characters; 30 UTF-8 bytes; limit 30 characters; remaining 0; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/subtitle.txt).

<!-- COPY:apple-en-AU-default-subtitle -->
```text
Trip planner & offline tickets
```
<!-- END_COPY:apple-en-AU-default-subtitle -->

#### default — Keywords

Record `apple-en-AU-default-keywords`. Action: **fill**. 86 characters; 86 UTF-8 bytes; limit 100 UTF-8 bytes; remaining 14; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/keywords.txt).

<!-- COPY:apple-en-AU-default-keywords -->
```text
family,shared,packing,checklist,holiday,countdown,booking,organiser,documents,reminder
```
<!-- END_COPY:apple-en-AU-default-keywords -->

#### default — Promotional Text

Record `apple-en-AU-default-promotional-text`. Action: **fill**. 152 characters; 152 UTF-8 bytes; limit 170 characters; remaining 18; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/promotional-text.txt).

<!-- COPY:apple-en-AU-default-promotional-text -->
```text
Start with a booking. See each day in order, keep saved tickets offline and spot missing stays. Share trips and packing with up to 6 people with a pass.
```
<!-- END_COPY:apple-en-AU-default-promotional-text -->

#### default — Description

Record `apple-en-AU-default-description`. Action: **fill**. 2522 characters; 2522 UTF-8 bytes; limit 4000 characters; remaining 1478; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/description.txt).

<!-- COPY:apple-en-AU-default-description -->
```text
Your bookings, in order. Your tickets, close at hand. Travary is an itinerary app for the trips you have booked, from the first confirmation to the journey home.

ADD A BOOKING. SEE YOUR TRIP TAKE SHAPE.
Add flights, stays, activities and restaurant bookings. Travary builds trips around their dates, so you can start with what you have already booked. Organise a weekend away or a family holiday without building a plan from scratch.

KNOW WHAT IS NEXT
Today puts the day's bookings in time order. Keep confirmation details and tickets beside the plans they belong to, and spot gaps such as a night without a stay or a missing flight home.

KEEP SAVED TICKETS OFFLINE
Save your bookings and ticket files before you leave. Open them without a connection when you need them. Saved bookings and tickets stay accessible on every plan, including after a pass ends. Importing and syncing shared changes need an internet connection.

CHECK THE DRAFT, THEN KEEP IT
Give Smart Import a booking screenshot, photo or PDF. Travi reads it into a draft for you to check and correct before saving. You get 2 free Smart Imports in total. Your imported source file counts towards your ticket-file allowance.

TRAVEL TOGETHER
With a pass, share a trip with up to 6 people, including the organiser. Keep the group's bookings and packing list together, with each person's tickets easy to find. One pass covers the people sharing that trip.

ENJOY THE COUNTDOWN
Give each trip a destination postcard, tick off packing and to-do lists, and set reminders. Keep your next holiday in sight with a home-screen countdown widget. Widgets require iOS 17 or later.

KEEP PERSONAL DOCUMENTS PERSONAL
Personal travel documents stay on your device behind its lock. They are not automatically shared with your trip or sent to Smart Import.

START FREE. CHOOSE A PASS WHEN YOU NEED MORE.
Create trips and add bookings free. Each free trip can keep 2 ticket files. A pass adds sharing, shared packing, more ticket files and more Smart Imports, subject to a daily usage limit.

Holiday Pass is a one-time purchase for one trip of up to 30 days, with pass features available until 7 days after it ends. Annual Pass is a yearly subscription that renews automatically unless cancelled. Prices are shown in the app before purchase. Manage or cancel Annual Pass in your App Store account settings.

Start with your next booking. Travi will meet you there.

Support: https://travary.app/support
Privacy: https://travary.app/privacy
Terms: https://travary.app/terms
```
<!-- END_COPY:apple-en-AU-default-description -->

#### default — Support URL

Record `apple-en-AU-default-support-url`. Action: **fill**. 27 characters; 27 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/support-url.txt).

<!-- COPY:apple-en-AU-default-support-url -->
```text
https://travary.app/support
```
<!-- END_COPY:apple-en-AU-default-support-url -->

#### default — Marketing URL

Record `apple-en-AU-default-marketing-url`. Action: **fill**. 20 characters; 20 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/marketing-url.txt).

<!-- COPY:apple-en-AU-default-marketing-url -->
```text
https://travary.app/
```
<!-- END_COPY:apple-en-AU-default-marketing-url -->

#### custom_product_page — Promotional Text

Record `apple-en-AU-family-promotional-text`. Action: **fill**. 158 characters; 158 UTF-8 bytes; limit 170 characters; remaining 12; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/family/promotional-text.txt).

<!-- COPY:apple-en-AU-family-promotional-text -->
```text
Keep the family on the same page. Share bookings and packing with up to 6 people, including the organiser, with a pass. Saved tickets stay accessible offline.
```
<!-- END_COPY:apple-en-AU-family-promotional-text -->

#### holiday_pass — Display Name

Record `apple-en-AU-holiday_pass-display-name`. Action: **fill**. 12 characters; 12 UTF-8 bytes; limit 30 characters; remaining 18; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/holiday_pass/display-name.txt).

<!-- COPY:apple-en-AU-holiday_pass-display-name -->
```text
Holiday Pass
```
<!-- END_COPY:apple-en-AU-holiday_pass-display-name -->

#### holiday_pass — Description

Record `apple-en-AU-holiday_pass-description`. Action: **fill**. 43 characters; 43 UTF-8 bytes; limit 45 characters; remaining 2; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/holiday_pass/description.txt).

<!-- COPY:apple-en-AU-holiday_pass-description -->
```text
Sharing and extras for a trip up to 30 days
```
<!-- END_COPY:apple-en-AU-holiday_pass-description -->

#### travary_annual_pass — Display Name

Record `apple-en-AU-travary_annual_pass-display-name`. Action: **fill**. 11 characters; 11 UTF-8 bytes; limit 30 characters; remaining 19; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/travary_annual_pass/display-name.txt).

<!-- COPY:apple-en-AU-travary_annual_pass-display-name -->
```text
Annual Pass
```
<!-- END_COPY:apple-en-AU-travary_annual_pass-display-name -->

#### travary_annual_pass — Description

Record `apple-en-AU-travary_annual_pass-description`. Action: **fill**. 41 characters; 41 UTF-8 bytes; limit 45 characters; remaining 4; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/travary_annual_pass/description.txt).

<!-- COPY:apple-en-AU-travary_annual_pass-description -->
```text
Sharing and extras for your trips, yearly
```
<!-- END_COPY:apple-en-AU-travary_annual_pass-description -->

### Apple / shared settings

#### custom_product_page — Reference Name

Record `apple-all-family-reference-name`. Action: **fill**. 16 characters; 16 UTF-8 bytes; limit 100 characters; remaining 84; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/shared/family/reference-name.txt).

<!-- COPY:apple-all-family-reference-name -->
```text
Family & packing
```
<!-- END_COPY:apple-all-family-reference-name -->

#### default — Primary Category

Record `apple-all-default-primary-category`. Action: **select**. 6 characters; 6 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/shared/default/primary-category.txt).

<!-- COPY:apple-all-default-primary-category -->
```text
Travel
```
<!-- END_COPY:apple-all-default-primary-category -->

#### default — License Agreement

Record `apple-all-default-license-agreement`. Action: **retain**. 32 characters; 32 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/shared/default/license-agreement.txt).

<!-- COPY:apple-all-default-license-agreement -->
```text
Standard Apple License Agreement
```
<!-- END_COPY:apple-all-default-license-agreement -->

#### default — Privacy Policy URL

Record `apple-all-default-privacy-policy-url`. Action: **fill**. 27 characters; 27 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/shared/default/privacy-policy-url.txt).

<!-- COPY:apple-all-default-privacy-policy-url -->
```text
https://travary.app/privacy
```
<!-- END_COPY:apple-all-default-privacy-policy-url -->

#### default — Terms URL (description link)

Record `apple-all-default-terms-url-description-link`. Action: **retain**. 25 characters; 25 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/shared/default/terms-url-description-link.txt).

<!-- COPY:apple-all-default-terms-url-description-link -->
```text
https://travary.app/terms
```
<!-- END_COPY:apple-all-default-terms-url-description-link -->

### Google / en-US

#### default — App name

Record `google-en-US-default-app-name`. Action: **retain**. 23 characters; 23 UTF-8 bytes; limit 30 characters; remaining 7; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/app-name.txt).

<!-- COPY:google-en-US-default-app-name -->
```text
Itinerary App - Travary
```
<!-- END_COPY:google-en-US-default-app-name -->

#### default — Short description

Record `google-en-US-default-short-description`. Action: **fill**. 72 characters; 72 UTF-8 bytes; limit 80 characters; remaining 8; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/short-description.txt).

<!-- COPY:google-en-US-default-short-description -->
```text
Keep bookings in order, save tickets offline and spot gaps in your trip.
```
<!-- END_COPY:google-en-US-default-short-description -->

#### default — Full description

Record `google-en-US-default-full-description`. Action: **fill**. 2471 characters; 2471 UTF-8 bytes; limit 4000 characters; remaining 1529; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/full-description.txt).

<!-- COPY:google-en-US-default-full-description -->
```text
Your bookings, in order. Your tickets, close at hand. Travary is an itinerary app for the trips you have booked, from the first confirmation to the journey home.

ADD A BOOKING. SEE YOUR TRIP TAKE SHAPE.
Add flights, stays, activities and restaurant bookings. Travary builds trips around their dates, so you can start with what you have already booked. Organize a weekend away or a family vacation without building a plan from scratch.

KNOW WHAT IS NEXT
Today puts the day's bookings in time order. Keep confirmation details and tickets beside the plans they belong to, and spot gaps such as a night without a stay or a missing flight home.

KEEP SAVED TICKETS OFFLINE
Save your bookings and ticket files before you leave. Open them without a connection when you need them. Saved bookings and tickets stay accessible on every plan, including after a pass ends. Importing and syncing shared changes need an internet connection.

CHECK THE DRAFT, THEN KEEP IT
Give Smart Import a booking screenshot, photo or PDF. Travi reads it into a draft for you to check and correct before saving. You get 2 free Smart Imports in total. Your imported source file counts towards your ticket-file allowance.

TRAVEL TOGETHER
With a pass, share a trip with up to 6 people, including the organizer. Keep the group's bookings and packing list together, with each person's tickets easy to find. One pass covers the people sharing that trip.

ENJOY THE COUNTDOWN
Give each trip a destination postcard, tick off packing and to-do lists, and set reminders. Keep your next vacation in sight with a home-screen countdown widget.

KEEP PERSONAL DOCUMENTS PERSONAL
Personal travel documents stay on your device behind its lock. They are not automatically shared with your trip or sent to Smart Import.

START FREE. CHOOSE A PASS WHEN YOU NEED MORE.
Create trips and add bookings free. Each free trip can keep 2 ticket files. A pass adds sharing, shared packing, more ticket files and more Smart Imports, subject to a daily usage limit.

Holiday Pass is a one-time purchase for one trip of up to 30 days, with pass features available until 7 days after it ends. Annual Pass is a yearly subscription that renews automatically unless cancelled. Prices are shown in the app before purchase. Manage or cancel Annual Pass in Google Play.

Start with your next booking. Travi will meet you there.

Support: https://travary.app/support
Privacy: https://travary.app/privacy
Terms: https://travary.app/terms
```
<!-- END_COPY:google-en-US-default-full-description -->

#### custom_store_listing — App name

Record `google-en-US-family-app-name`. Action: **retain**. 23 characters; 23 UTF-8 bytes; limit 30 characters; remaining 7; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/app-name.txt).

<!-- COPY:google-en-US-family-app-name -->
```text
Itinerary App - Travary
```
<!-- END_COPY:google-en-US-family-app-name -->

#### custom_store_listing — Short description

Record `google-en-US-family-short-description`. Action: **fill**. 79 characters; 79 UTF-8 bytes; limit 80 characters; remaining 1; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/short-description.txt).

<!-- COPY:google-en-US-family-short-description -->
```text
Shared trips and packing for up to 6 people with a pass. Saved tickets offline.
```
<!-- END_COPY:google-en-US-family-short-description -->

#### custom_store_listing — Full description

Record `google-en-US-family-full-description`. Action: **fill**. 2504 characters; 2504 UTF-8 bytes; limit 4000 characters; remaining 1496; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/full-description.txt).

<!-- COPY:google-en-US-family-full-description -->
```text
Bring your family trip together. Travary keeps bookings, daily plans and saved tickets in one place, with shared trips and packing lists for up to 6 people, including the organizer, with a pass.

ADD A BOOKING. SEE YOUR TRIP TAKE SHAPE.
Add flights, stays, activities and restaurant bookings. Travary builds trips around their dates, so you can start with what you have already booked. Organize a weekend away or a family vacation without building a plan from scratch.

KNOW WHAT IS NEXT
Today puts the day's bookings in time order. Keep confirmation details and tickets beside the plans they belong to, and spot gaps such as a night without a stay or a missing flight home.

KEEP SAVED TICKETS OFFLINE
Save your bookings and ticket files before you leave. Open them without a connection when you need them. Saved bookings and tickets stay accessible on every plan, including after a pass ends. Importing and syncing shared changes need an internet connection.

CHECK THE DRAFT, THEN KEEP IT
Give Smart Import a booking screenshot, photo or PDF. Travi reads it into a draft for you to check and correct before saving. You get 2 free Smart Imports in total. Your imported source file counts towards your ticket-file allowance.

TRAVEL TOGETHER
With a pass, share a trip with up to 6 people, including the organizer. Keep the group's bookings and packing list together, with each person's tickets easy to find. One pass covers the people sharing that trip.

ENJOY THE COUNTDOWN
Give each trip a destination postcard, tick off packing and to-do lists, and set reminders. Keep your next vacation in sight with a home-screen countdown widget.

KEEP PERSONAL DOCUMENTS PERSONAL
Personal travel documents stay on your device behind its lock. They are not automatically shared with your trip or sent to Smart Import.

START FREE. CHOOSE A PASS WHEN YOU NEED MORE.
Create trips and add bookings free. Each free trip can keep 2 ticket files. A pass adds sharing, shared packing, more ticket files and more Smart Imports, subject to a daily usage limit.

Holiday Pass is a one-time purchase for one trip of up to 30 days, with pass features available until 7 days after it ends. Annual Pass is a yearly subscription that renews automatically unless cancelled. Prices are shown in the app before purchase. Manage or cancel Annual Pass in Google Play.

Start with your next booking. Travi will meet you there.

Support: https://travary.app/support
Privacy: https://travary.app/privacy
Terms: https://travary.app/terms
```
<!-- END_COPY:google-en-US-family-full-description -->

#### default — Screenshot alt text — 1

Record `google-en-US-default-screenshot-alt-text-android-phone-1080x1920-01`. Action: **fill**. 45 characters; 45 UTF-8 bytes; limit 140 characters; remaining 95; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-01.txt).

<!-- COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-01 -->
```text
Today shows the day's bookings in time order.
```
<!-- END_COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-01 -->

#### default — Screenshot alt text — 2

Record `google-en-US-default-screenshot-alt-text-android-phone-1080x1920-02`. Action: **fill**. 67 characters; 67 UTF-8 bytes; limit 140 characters; remaining 73; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-02.txt).

<!-- COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-02 -->
```text
Saved bookings and tickets remain accessible offline on every plan.
```
<!-- END_COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-02 -->

#### default — Screenshot alt text — 3

Record `google-en-US-default-screenshot-alt-text-android-phone-1080x1920-03`. Action: **fill**. 56 characters; 56 UTF-8 bytes; limit 140 characters; remaining 84; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-03.txt).

<!-- COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-03 -->
```text
The trip plan highlights a missing stay and flight home.
```
<!-- END_COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-03 -->

#### default — Screenshot alt text — 4

Record `google-en-US-default-screenshot-alt-text-android-phone-1080x1920-04`. Action: **fill**. 73 characters; 73 UTF-8 bytes; limit 140 characters; remaining 67; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-04.txt).

<!-- COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-04 -->
```text
A shared trip for up to six people, including the organizer, with a pass.
```
<!-- END_COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-04 -->

#### default — Screenshot alt text — 5

Record `google-en-US-default-screenshot-alt-text-android-phone-1080x1920-05`. Action: **fill**. 87 characters; 87 UTF-8 bytes; limit 140 characters; remaining 53; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-05.txt).

<!-- COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-05 -->
```text
Smart Import reads a confirmation into a draft to check. Two free imports, then a pass.
```
<!-- END_COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-05 -->

#### default — Screenshot alt text — 6

Record `google-en-US-default-screenshot-alt-text-android-phone-1080x1920-06`. Action: **fill**. 68 characters; 68 UTF-8 bytes; limit 140 characters; remaining 72; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-06.txt).

<!-- COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-06 -->
```text
A trip packing checklist, with shared packing available with a pass.
```
<!-- END_COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-06 -->

#### default — Screenshot alt text — 7

Record `google-en-US-default-screenshot-alt-text-android-phone-1080x1920-07`. Action: **fill**. 54 characters; 54 UTF-8 bytes; limit 140 characters; remaining 86; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-07.txt).

<!-- COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-07 -->
```text
A destination postcard and countdown to the next trip.
```
<!-- END_COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-07 -->

#### default — Screenshot alt text — 8

Record `google-en-US-default-screenshot-alt-text-android-phone-1080x1920-08`. Action: **fill**. 49 characters; 49 UTF-8 bytes; limit 140 characters; remaining 91; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-08.txt).

<!-- COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-08 -->
```text
A home-screen countdown widget for the next trip.
```
<!-- END_COPY:google-en-US-default-screenshot-alt-text-android-phone-1080x1920-08 -->

#### default — Feature graphic alt text

Record `google-en-US-default-feature-graphic-alt-text`. Action: **fill**. 38 characters; 38 UTF-8 bytes; limit 140 characters; remaining 102; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/feature-graphic-alt-text.txt).

<!-- COPY:google-en-US-default-feature-graphic-alt-text -->
```text
Travi beside a day of travel bookings.
```
<!-- END_COPY:google-en-US-default-feature-graphic-alt-text -->

#### custom_store_listing — Screenshot alt text — 1

Record `google-en-US-family-screenshot-alt-text-android-phone-1080x1920-01`. Action: **fill**. 73 characters; 73 UTF-8 bytes; limit 140 characters; remaining 67; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-01.txt).

<!-- COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-01 -->
```text
A shared trip for up to six people, including the organizer, with a pass.
```
<!-- END_COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-01 -->

#### custom_store_listing — Screenshot alt text — 2

Record `google-en-US-family-screenshot-alt-text-android-phone-1080x1920-02`. Action: **fill**. 68 characters; 68 UTF-8 bytes; limit 140 characters; remaining 72; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-02.txt).

<!-- COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-02 -->
```text
A trip packing checklist, with shared packing available with a pass.
```
<!-- END_COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-02 -->

#### custom_store_listing — Screenshot alt text — 3

Record `google-en-US-family-screenshot-alt-text-android-phone-1080x1920-03`. Action: **fill**. 45 characters; 45 UTF-8 bytes; limit 140 characters; remaining 95; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-03.txt).

<!-- COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-03 -->
```text
Today shows the day's bookings in time order.
```
<!-- END_COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-03 -->

#### custom_store_listing — Screenshot alt text — 4

Record `google-en-US-family-screenshot-alt-text-android-phone-1080x1920-04`. Action: **fill**. 67 characters; 67 UTF-8 bytes; limit 140 characters; remaining 73; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-04.txt).

<!-- COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-04 -->
```text
Saved bookings and tickets remain accessible offline on every plan.
```
<!-- END_COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-04 -->

#### custom_store_listing — Screenshot alt text — 5

Record `google-en-US-family-screenshot-alt-text-android-phone-1080x1920-05`. Action: **fill**. 56 characters; 56 UTF-8 bytes; limit 140 characters; remaining 84; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-05.txt).

<!-- COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-05 -->
```text
The trip plan highlights a missing stay and flight home.
```
<!-- END_COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-05 -->

#### custom_store_listing — Screenshot alt text — 6

Record `google-en-US-family-screenshot-alt-text-android-phone-1080x1920-06`. Action: **fill**. 87 characters; 87 UTF-8 bytes; limit 140 characters; remaining 53; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-06.txt).

<!-- COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-06 -->
```text
Smart Import reads a confirmation into a draft to check. Two free imports, then a pass.
```
<!-- END_COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-06 -->

#### custom_store_listing — Screenshot alt text — 7

Record `google-en-US-family-screenshot-alt-text-android-phone-1080x1920-07`. Action: **fill**. 54 characters; 54 UTF-8 bytes; limit 140 characters; remaining 86; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-07.txt).

<!-- COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-07 -->
```text
A destination postcard and countdown to the next trip.
```
<!-- END_COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-07 -->

#### custom_store_listing — Screenshot alt text — 8

Record `google-en-US-family-screenshot-alt-text-android-phone-1080x1920-08`. Action: **fill**. 49 characters; 49 UTF-8 bytes; limit 140 characters; remaining 91; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-08.txt).

<!-- COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-08 -->
```text
A home-screen countdown widget for the next trip.
```
<!-- END_COPY:google-en-US-family-screenshot-alt-text-android-phone-1080x1920-08 -->

#### custom_store_listing — Feature graphic alt text

Record `google-en-US-family-feature-graphic-alt-text`. Action: **fill**. 49 characters; 49 UTF-8 bytes; limit 140 characters; remaining 91; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/feature-graphic-alt-text.txt).

<!-- COPY:google-en-US-family-feature-graphic-alt-text -->
```text
Travi beside a shared trip and packing checklist.
```
<!-- END_COPY:google-en-US-family-feature-graphic-alt-text -->

### Google / en-GB

#### default — App name

Record `google-en-GB-default-app-name`. Action: **retain**. 23 characters; 23 UTF-8 bytes; limit 30 characters; remaining 7; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/app-name.txt).

<!-- COPY:google-en-GB-default-app-name -->
```text
Itinerary App - Travary
```
<!-- END_COPY:google-en-GB-default-app-name -->

#### default — Short description

Record `google-en-GB-default-short-description`. Action: **fill**. 72 characters; 72 UTF-8 bytes; limit 80 characters; remaining 8; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/short-description.txt).

<!-- COPY:google-en-GB-default-short-description -->
```text
Keep bookings in order, save tickets offline and spot gaps in your trip.
```
<!-- END_COPY:google-en-GB-default-short-description -->

#### default — Full description

Record `google-en-GB-default-full-description`. Action: **fill**. 2469 characters; 2469 UTF-8 bytes; limit 4000 characters; remaining 1531; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/full-description.txt).

<!-- COPY:google-en-GB-default-full-description -->
```text
Your bookings, in order. Your tickets, close at hand. Travary is an itinerary app for the trips you have booked, from the first confirmation to the journey home.

ADD A BOOKING. SEE YOUR TRIP TAKE SHAPE.
Add flights, stays, activities and restaurant bookings. Travary builds trips around their dates, so you can start with what you have already booked. Organise a weekend away or a family holiday without building a plan from scratch.

KNOW WHAT IS NEXT
Today puts the day's bookings in time order. Keep confirmation details and tickets beside the plans they belong to, and spot gaps such as a night without a stay or a missing flight home.

KEEP SAVED TICKETS OFFLINE
Save your bookings and ticket files before you leave. Open them without a connection when you need them. Saved bookings and tickets stay accessible on every plan, including after a pass ends. Importing and syncing shared changes need an internet connection.

CHECK THE DRAFT, THEN KEEP IT
Give Smart Import a booking screenshot, photo or PDF. Travi reads it into a draft for you to check and correct before saving. You get 2 free Smart Imports in total. Your imported source file counts towards your ticket-file allowance.

TRAVEL TOGETHER
With a pass, share a trip with up to 6 people, including the organiser. Keep the group's bookings and packing list together, with each person's tickets easy to find. One pass covers the people sharing that trip.

ENJOY THE COUNTDOWN
Give each trip a destination postcard, tick off packing and to-do lists, and set reminders. Keep your next holiday in sight with a home-screen countdown widget.

KEEP PERSONAL DOCUMENTS PERSONAL
Personal travel documents stay on your device behind its lock. They are not automatically shared with your trip or sent to Smart Import.

START FREE. CHOOSE A PASS WHEN YOU NEED MORE.
Create trips and add bookings free. Each free trip can keep 2 ticket files. A pass adds sharing, shared packing, more ticket files and more Smart Imports, subject to a daily usage limit.

Holiday Pass is a one-time purchase for one trip of up to 30 days, with pass features available until 7 days after it ends. Annual Pass is a yearly subscription that renews automatically unless cancelled. Prices are shown in the app before purchase. Manage or cancel Annual Pass in Google Play.

Start with your next booking. Travi will meet you there.

Support: https://travary.app/support
Privacy: https://travary.app/privacy
Terms: https://travary.app/terms
```
<!-- END_COPY:google-en-GB-default-full-description -->

#### custom_store_listing — App name

Record `google-en-GB-family-app-name`. Action: **retain**. 23 characters; 23 UTF-8 bytes; limit 30 characters; remaining 7; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/app-name.txt).

<!-- COPY:google-en-GB-family-app-name -->
```text
Itinerary App - Travary
```
<!-- END_COPY:google-en-GB-family-app-name -->

#### custom_store_listing — Short description

Record `google-en-GB-family-short-description`. Action: **fill**. 79 characters; 79 UTF-8 bytes; limit 80 characters; remaining 1; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/short-description.txt).

<!-- COPY:google-en-GB-family-short-description -->
```text
Shared trips and packing for up to 6 people with a pass. Saved tickets offline.
```
<!-- END_COPY:google-en-GB-family-short-description -->

#### custom_store_listing — Full description

Record `google-en-GB-family-full-description`. Action: **fill**. 2502 characters; 2502 UTF-8 bytes; limit 4000 characters; remaining 1498; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/full-description.txt).

<!-- COPY:google-en-GB-family-full-description -->
```text
Bring your family trip together. Travary keeps bookings, daily plans and saved tickets in one place, with shared trips and packing lists for up to 6 people, including the organiser, with a pass.

ADD A BOOKING. SEE YOUR TRIP TAKE SHAPE.
Add flights, stays, activities and restaurant bookings. Travary builds trips around their dates, so you can start with what you have already booked. Organise a weekend away or a family holiday without building a plan from scratch.

KNOW WHAT IS NEXT
Today puts the day's bookings in time order. Keep confirmation details and tickets beside the plans they belong to, and spot gaps such as a night without a stay or a missing flight home.

KEEP SAVED TICKETS OFFLINE
Save your bookings and ticket files before you leave. Open them without a connection when you need them. Saved bookings and tickets stay accessible on every plan, including after a pass ends. Importing and syncing shared changes need an internet connection.

CHECK THE DRAFT, THEN KEEP IT
Give Smart Import a booking screenshot, photo or PDF. Travi reads it into a draft for you to check and correct before saving. You get 2 free Smart Imports in total. Your imported source file counts towards your ticket-file allowance.

TRAVEL TOGETHER
With a pass, share a trip with up to 6 people, including the organiser. Keep the group's bookings and packing list together, with each person's tickets easy to find. One pass covers the people sharing that trip.

ENJOY THE COUNTDOWN
Give each trip a destination postcard, tick off packing and to-do lists, and set reminders. Keep your next holiday in sight with a home-screen countdown widget.

KEEP PERSONAL DOCUMENTS PERSONAL
Personal travel documents stay on your device behind its lock. They are not automatically shared with your trip or sent to Smart Import.

START FREE. CHOOSE A PASS WHEN YOU NEED MORE.
Create trips and add bookings free. Each free trip can keep 2 ticket files. A pass adds sharing, shared packing, more ticket files and more Smart Imports, subject to a daily usage limit.

Holiday Pass is a one-time purchase for one trip of up to 30 days, with pass features available until 7 days after it ends. Annual Pass is a yearly subscription that renews automatically unless cancelled. Prices are shown in the app before purchase. Manage or cancel Annual Pass in Google Play.

Start with your next booking. Travi will meet you there.

Support: https://travary.app/support
Privacy: https://travary.app/privacy
Terms: https://travary.app/terms
```
<!-- END_COPY:google-en-GB-family-full-description -->

#### default — Screenshot alt text — 1

Record `google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-01`. Action: **fill**. 45 characters; 45 UTF-8 bytes; limit 140 characters; remaining 95; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-01.txt).

<!-- COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-01 -->
```text
Today shows the day's bookings in time order.
```
<!-- END_COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-01 -->

#### default — Screenshot alt text — 2

Record `google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-02`. Action: **fill**. 67 characters; 67 UTF-8 bytes; limit 140 characters; remaining 73; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-02.txt).

<!-- COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-02 -->
```text
Saved bookings and tickets remain accessible offline on every plan.
```
<!-- END_COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-02 -->

#### default — Screenshot alt text — 3

Record `google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-03`. Action: **fill**. 56 characters; 56 UTF-8 bytes; limit 140 characters; remaining 84; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-03.txt).

<!-- COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-03 -->
```text
The trip plan highlights a missing stay and flight home.
```
<!-- END_COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-03 -->

#### default — Screenshot alt text — 4

Record `google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-04`. Action: **fill**. 73 characters; 73 UTF-8 bytes; limit 140 characters; remaining 67; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-04.txt).

<!-- COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-04 -->
```text
A shared trip for up to six people, including the organiser, with a pass.
```
<!-- END_COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-04 -->

#### default — Screenshot alt text — 5

Record `google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-05`. Action: **fill**. 87 characters; 87 UTF-8 bytes; limit 140 characters; remaining 53; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-05.txt).

<!-- COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-05 -->
```text
Smart Import reads a confirmation into a draft to check. Two free imports, then a pass.
```
<!-- END_COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-05 -->

#### default — Screenshot alt text — 6

Record `google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-06`. Action: **fill**. 68 characters; 68 UTF-8 bytes; limit 140 characters; remaining 72; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-06.txt).

<!-- COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-06 -->
```text
A trip packing checklist, with shared packing available with a pass.
```
<!-- END_COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-06 -->

#### default — Screenshot alt text — 7

Record `google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-07`. Action: **fill**. 54 characters; 54 UTF-8 bytes; limit 140 characters; remaining 86; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-07.txt).

<!-- COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-07 -->
```text
A destination postcard and countdown to the next trip.
```
<!-- END_COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-07 -->

#### default — Screenshot alt text — 8

Record `google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-08`. Action: **fill**. 49 characters; 49 UTF-8 bytes; limit 140 characters; remaining 91; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-08.txt).

<!-- COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-08 -->
```text
A home-screen countdown widget for the next trip.
```
<!-- END_COPY:google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-08 -->

#### default — Feature graphic alt text

Record `google-en-GB-default-feature-graphic-alt-text`. Action: **fill**. 38 characters; 38 UTF-8 bytes; limit 140 characters; remaining 102; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/feature-graphic-alt-text.txt).

<!-- COPY:google-en-GB-default-feature-graphic-alt-text -->
```text
Travi beside a day of travel bookings.
```
<!-- END_COPY:google-en-GB-default-feature-graphic-alt-text -->

#### custom_store_listing — Screenshot alt text — 1

Record `google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-01`. Action: **fill**. 73 characters; 73 UTF-8 bytes; limit 140 characters; remaining 67; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-01.txt).

<!-- COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-01 -->
```text
A shared trip for up to six people, including the organiser, with a pass.
```
<!-- END_COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-01 -->

#### custom_store_listing — Screenshot alt text — 2

Record `google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-02`. Action: **fill**. 68 characters; 68 UTF-8 bytes; limit 140 characters; remaining 72; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-02.txt).

<!-- COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-02 -->
```text
A trip packing checklist, with shared packing available with a pass.
```
<!-- END_COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-02 -->

#### custom_store_listing — Screenshot alt text — 3

Record `google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-03`. Action: **fill**. 45 characters; 45 UTF-8 bytes; limit 140 characters; remaining 95; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-03.txt).

<!-- COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-03 -->
```text
Today shows the day's bookings in time order.
```
<!-- END_COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-03 -->

#### custom_store_listing — Screenshot alt text — 4

Record `google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-04`. Action: **fill**. 67 characters; 67 UTF-8 bytes; limit 140 characters; remaining 73; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-04.txt).

<!-- COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-04 -->
```text
Saved bookings and tickets remain accessible offline on every plan.
```
<!-- END_COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-04 -->

#### custom_store_listing — Screenshot alt text — 5

Record `google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-05`. Action: **fill**. 56 characters; 56 UTF-8 bytes; limit 140 characters; remaining 84; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-05.txt).

<!-- COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-05 -->
```text
The trip plan highlights a missing stay and flight home.
```
<!-- END_COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-05 -->

#### custom_store_listing — Screenshot alt text — 6

Record `google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-06`. Action: **fill**. 87 characters; 87 UTF-8 bytes; limit 140 characters; remaining 53; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-06.txt).

<!-- COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-06 -->
```text
Smart Import reads a confirmation into a draft to check. Two free imports, then a pass.
```
<!-- END_COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-06 -->

#### custom_store_listing — Screenshot alt text — 7

Record `google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-07`. Action: **fill**. 54 characters; 54 UTF-8 bytes; limit 140 characters; remaining 86; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-07.txt).

<!-- COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-07 -->
```text
A destination postcard and countdown to the next trip.
```
<!-- END_COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-07 -->

#### custom_store_listing — Screenshot alt text — 8

Record `google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-08`. Action: **fill**. 49 characters; 49 UTF-8 bytes; limit 140 characters; remaining 91; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-08.txt).

<!-- COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-08 -->
```text
A home-screen countdown widget for the next trip.
```
<!-- END_COPY:google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-08 -->

#### custom_store_listing — Feature graphic alt text

Record `google-en-GB-family-feature-graphic-alt-text`. Action: **fill**. 49 characters; 49 UTF-8 bytes; limit 140 characters; remaining 91; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/feature-graphic-alt-text.txt).

<!-- COPY:google-en-GB-family-feature-graphic-alt-text -->
```text
Travi beside a shared trip and packing checklist.
```
<!-- END_COPY:google-en-GB-family-feature-graphic-alt-text -->

#### test_variant — Short description

Record `google-en-GB-test_variant-short-description`. Action: **fill**. 76 characters; 76 UTF-8 bytes; limit 80 characters; remaining 4; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/test_variant/short-description.txt).

<!-- COPY:google-en-GB-test_variant-short-description -->
```text
Your bookings, tickets and daily plans together. Saved tickets work offline.
```
<!-- END_COPY:google-en-GB-test_variant-short-description -->

### Google / en-AU

#### default — App name

Record `google-en-AU-default-app-name`. Action: **retain**. 23 characters; 23 UTF-8 bytes; limit 30 characters; remaining 7; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/app-name.txt).

<!-- COPY:google-en-AU-default-app-name -->
```text
Itinerary App - Travary
```
<!-- END_COPY:google-en-AU-default-app-name -->

#### default — Short description

Record `google-en-AU-default-short-description`. Action: **fill**. 72 characters; 72 UTF-8 bytes; limit 80 characters; remaining 8; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/short-description.txt).

<!-- COPY:google-en-AU-default-short-description -->
```text
Keep bookings in order, save tickets offline and spot gaps in your trip.
```
<!-- END_COPY:google-en-AU-default-short-description -->

#### default — Full description

Record `google-en-AU-default-full-description`. Action: **fill**. 2469 characters; 2469 UTF-8 bytes; limit 4000 characters; remaining 1531; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/full-description.txt).

<!-- COPY:google-en-AU-default-full-description -->
```text
Your bookings, in order. Your tickets, close at hand. Travary is an itinerary app for the trips you have booked, from the first confirmation to the journey home.

ADD A BOOKING. SEE YOUR TRIP TAKE SHAPE.
Add flights, stays, activities and restaurant bookings. Travary builds trips around their dates, so you can start with what you have already booked. Organise a weekend away or a family holiday without building a plan from scratch.

KNOW WHAT IS NEXT
Today puts the day's bookings in time order. Keep confirmation details and tickets beside the plans they belong to, and spot gaps such as a night without a stay or a missing flight home.

KEEP SAVED TICKETS OFFLINE
Save your bookings and ticket files before you leave. Open them without a connection when you need them. Saved bookings and tickets stay accessible on every plan, including after a pass ends. Importing and syncing shared changes need an internet connection.

CHECK THE DRAFT, THEN KEEP IT
Give Smart Import a booking screenshot, photo or PDF. Travi reads it into a draft for you to check and correct before saving. You get 2 free Smart Imports in total. Your imported source file counts towards your ticket-file allowance.

TRAVEL TOGETHER
With a pass, share a trip with up to 6 people, including the organiser. Keep the group's bookings and packing list together, with each person's tickets easy to find. One pass covers the people sharing that trip.

ENJOY THE COUNTDOWN
Give each trip a destination postcard, tick off packing and to-do lists, and set reminders. Keep your next holiday in sight with a home-screen countdown widget.

KEEP PERSONAL DOCUMENTS PERSONAL
Personal travel documents stay on your device behind its lock. They are not automatically shared with your trip or sent to Smart Import.

START FREE. CHOOSE A PASS WHEN YOU NEED MORE.
Create trips and add bookings free. Each free trip can keep 2 ticket files. A pass adds sharing, shared packing, more ticket files and more Smart Imports, subject to a daily usage limit.

Holiday Pass is a one-time purchase for one trip of up to 30 days, with pass features available until 7 days after it ends. Annual Pass is a yearly subscription that renews automatically unless cancelled. Prices are shown in the app before purchase. Manage or cancel Annual Pass in Google Play.

Start with your next booking. Travi will meet you there.

Support: https://travary.app/support
Privacy: https://travary.app/privacy
Terms: https://travary.app/terms
```
<!-- END_COPY:google-en-AU-default-full-description -->

#### custom_store_listing — App name

Record `google-en-AU-family-app-name`. Action: **retain**. 23 characters; 23 UTF-8 bytes; limit 30 characters; remaining 7; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/app-name.txt).

<!-- COPY:google-en-AU-family-app-name -->
```text
Itinerary App - Travary
```
<!-- END_COPY:google-en-AU-family-app-name -->

#### custom_store_listing — Short description

Record `google-en-AU-family-short-description`. Action: **fill**. 79 characters; 79 UTF-8 bytes; limit 80 characters; remaining 1; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/short-description.txt).

<!-- COPY:google-en-AU-family-short-description -->
```text
Shared trips and packing for up to 6 people with a pass. Saved tickets offline.
```
<!-- END_COPY:google-en-AU-family-short-description -->

#### custom_store_listing — Full description

Record `google-en-AU-family-full-description`. Action: **fill**. 2502 characters; 2502 UTF-8 bytes; limit 4000 characters; remaining 1498; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/full-description.txt).

<!-- COPY:google-en-AU-family-full-description -->
```text
Bring your family trip together. Travary keeps bookings, daily plans and saved tickets in one place, with shared trips and packing lists for up to 6 people, including the organiser, with a pass.

ADD A BOOKING. SEE YOUR TRIP TAKE SHAPE.
Add flights, stays, activities and restaurant bookings. Travary builds trips around their dates, so you can start with what you have already booked. Organise a weekend away or a family holiday without building a plan from scratch.

KNOW WHAT IS NEXT
Today puts the day's bookings in time order. Keep confirmation details and tickets beside the plans they belong to, and spot gaps such as a night without a stay or a missing flight home.

KEEP SAVED TICKETS OFFLINE
Save your bookings and ticket files before you leave. Open them without a connection when you need them. Saved bookings and tickets stay accessible on every plan, including after a pass ends. Importing and syncing shared changes need an internet connection.

CHECK THE DRAFT, THEN KEEP IT
Give Smart Import a booking screenshot, photo or PDF. Travi reads it into a draft for you to check and correct before saving. You get 2 free Smart Imports in total. Your imported source file counts towards your ticket-file allowance.

TRAVEL TOGETHER
With a pass, share a trip with up to 6 people, including the organiser. Keep the group's bookings and packing list together, with each person's tickets easy to find. One pass covers the people sharing that trip.

ENJOY THE COUNTDOWN
Give each trip a destination postcard, tick off packing and to-do lists, and set reminders. Keep your next holiday in sight with a home-screen countdown widget.

KEEP PERSONAL DOCUMENTS PERSONAL
Personal travel documents stay on your device behind its lock. They are not automatically shared with your trip or sent to Smart Import.

START FREE. CHOOSE A PASS WHEN YOU NEED MORE.
Create trips and add bookings free. Each free trip can keep 2 ticket files. A pass adds sharing, shared packing, more ticket files and more Smart Imports, subject to a daily usage limit.

Holiday Pass is a one-time purchase for one trip of up to 30 days, with pass features available until 7 days after it ends. Annual Pass is a yearly subscription that renews automatically unless cancelled. Prices are shown in the app before purchase. Manage or cancel Annual Pass in Google Play.

Start with your next booking. Travi will meet you there.

Support: https://travary.app/support
Privacy: https://travary.app/privacy
Terms: https://travary.app/terms
```
<!-- END_COPY:google-en-AU-family-full-description -->

#### default — Screenshot alt text — 1

Record `google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-01`. Action: **fill**. 45 characters; 45 UTF-8 bytes; limit 140 characters; remaining 95; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-01.txt).

<!-- COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-01 -->
```text
Today shows the day's bookings in time order.
```
<!-- END_COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-01 -->

#### default — Screenshot alt text — 2

Record `google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-02`. Action: **fill**. 67 characters; 67 UTF-8 bytes; limit 140 characters; remaining 73; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-02.txt).

<!-- COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-02 -->
```text
Saved bookings and tickets remain accessible offline on every plan.
```
<!-- END_COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-02 -->

#### default — Screenshot alt text — 3

Record `google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-03`. Action: **fill**. 56 characters; 56 UTF-8 bytes; limit 140 characters; remaining 84; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-03.txt).

<!-- COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-03 -->
```text
The trip plan highlights a missing stay and flight home.
```
<!-- END_COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-03 -->

#### default — Screenshot alt text — 4

Record `google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-04`. Action: **fill**. 73 characters; 73 UTF-8 bytes; limit 140 characters; remaining 67; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-04.txt).

<!-- COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-04 -->
```text
A shared trip for up to six people, including the organiser, with a pass.
```
<!-- END_COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-04 -->

#### default — Screenshot alt text — 5

Record `google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-05`. Action: **fill**. 87 characters; 87 UTF-8 bytes; limit 140 characters; remaining 53; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-05.txt).

<!-- COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-05 -->
```text
Smart Import reads a confirmation into a draft to check. Two free imports, then a pass.
```
<!-- END_COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-05 -->

#### default — Screenshot alt text — 6

Record `google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-06`. Action: **fill**. 68 characters; 68 UTF-8 bytes; limit 140 characters; remaining 72; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-06.txt).

<!-- COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-06 -->
```text
A trip packing checklist, with shared packing available with a pass.
```
<!-- END_COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-06 -->

#### default — Screenshot alt text — 7

Record `google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-07`. Action: **fill**. 54 characters; 54 UTF-8 bytes; limit 140 characters; remaining 86; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-07.txt).

<!-- COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-07 -->
```text
A destination postcard and countdown to the next trip.
```
<!-- END_COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-07 -->

#### default — Screenshot alt text — 8

Record `google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-08`. Action: **fill**. 49 characters; 49 UTF-8 bytes; limit 140 characters; remaining 91; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-08.txt).

<!-- COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-08 -->
```text
A home-screen countdown widget for the next trip.
```
<!-- END_COPY:google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-08 -->

#### default — Feature graphic alt text

Record `google-en-AU-default-feature-graphic-alt-text`. Action: **fill**. 38 characters; 38 UTF-8 bytes; limit 140 characters; remaining 102; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/feature-graphic-alt-text.txt).

<!-- COPY:google-en-AU-default-feature-graphic-alt-text -->
```text
Travi beside a day of travel bookings.
```
<!-- END_COPY:google-en-AU-default-feature-graphic-alt-text -->

#### custom_store_listing — Screenshot alt text — 1

Record `google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-01`. Action: **fill**. 73 characters; 73 UTF-8 bytes; limit 140 characters; remaining 67; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-01.txt).

<!-- COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-01 -->
```text
A shared trip for up to six people, including the organiser, with a pass.
```
<!-- END_COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-01 -->

#### custom_store_listing — Screenshot alt text — 2

Record `google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-02`. Action: **fill**. 68 characters; 68 UTF-8 bytes; limit 140 characters; remaining 72; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-02.txt).

<!-- COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-02 -->
```text
A trip packing checklist, with shared packing available with a pass.
```
<!-- END_COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-02 -->

#### custom_store_listing — Screenshot alt text — 3

Record `google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-03`. Action: **fill**. 45 characters; 45 UTF-8 bytes; limit 140 characters; remaining 95; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-03.txt).

<!-- COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-03 -->
```text
Today shows the day's bookings in time order.
```
<!-- END_COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-03 -->

#### custom_store_listing — Screenshot alt text — 4

Record `google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-04`. Action: **fill**. 67 characters; 67 UTF-8 bytes; limit 140 characters; remaining 73; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-04.txt).

<!-- COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-04 -->
```text
Saved bookings and tickets remain accessible offline on every plan.
```
<!-- END_COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-04 -->

#### custom_store_listing — Screenshot alt text — 5

Record `google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-05`. Action: **fill**. 56 characters; 56 UTF-8 bytes; limit 140 characters; remaining 84; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-05.txt).

<!-- COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-05 -->
```text
The trip plan highlights a missing stay and flight home.
```
<!-- END_COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-05 -->

#### custom_store_listing — Screenshot alt text — 6

Record `google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-06`. Action: **fill**. 87 characters; 87 UTF-8 bytes; limit 140 characters; remaining 53; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-06.txt).

<!-- COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-06 -->
```text
Smart Import reads a confirmation into a draft to check. Two free imports, then a pass.
```
<!-- END_COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-06 -->

#### custom_store_listing — Screenshot alt text — 7

Record `google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-07`. Action: **fill**. 54 characters; 54 UTF-8 bytes; limit 140 characters; remaining 86; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-07.txt).

<!-- COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-07 -->
```text
A destination postcard and countdown to the next trip.
```
<!-- END_COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-07 -->

#### custom_store_listing — Screenshot alt text — 8

Record `google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-08`. Action: **fill**. 49 characters; 49 UTF-8 bytes; limit 140 characters; remaining 91; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-08.txt).

<!-- COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-08 -->
```text
A home-screen countdown widget for the next trip.
```
<!-- END_COPY:google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-08 -->

#### custom_store_listing — Feature graphic alt text

Record `google-en-AU-family-feature-graphic-alt-text`. Action: **fill**. 49 characters; 49 UTF-8 bytes; limit 140 characters; remaining 91; **PASS**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/feature-graphic-alt-text.txt).

<!-- COPY:google-en-AU-family-feature-graphic-alt-text -->
```text
Travi beside a shared trip and packing checklist.
```
<!-- END_COPY:google-en-AU-family-feature-graphic-alt-text -->

### Google / shared settings

#### default — Default language

Record `google-all-default-default-language`. Action: **select**. 31 characters; 33 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/default-language.txt).

<!-- COPY:google-all-default-default-language -->
```text
English (United States) – en-US
```
<!-- END_COPY:google-all-default-default-language -->

#### custom_store_listing — Listing name

Record `google-all-family-listing-name`. Action: **fill**. 19 characters; 19 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/family/listing-name.txt).

<!-- COPY:google-all-family-listing-name -->
```text
Family trip planner
```
<!-- END_COPY:google-all-family-listing-name -->

#### custom_store_listing — Targeting

Record `google-all-family-targeting`. Action: **select**. 15 characters; 15 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/family/targeting.txt).

<!-- COPY:google-all-family-targeting -->
```text
Search keywords
```
<!-- END_COPY:google-all-family-targeting -->

#### custom_store_listing — Default language

Record `google-all-family-default-language`. Action: **select**. 31 characters; 33 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/family/default-language.txt).

<!-- COPY:google-all-family-default-language -->
```text
English (United States) – en-US
```
<!-- END_COPY:google-all-family-default-language -->

#### default — Category

Record `google-all-default-category`. Action: **select**. 14 characters; 14 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/category.txt).

<!-- COPY:google-all-default-category -->
```text
Travel & Local
```
<!-- END_COPY:google-all-default-category -->

#### default — App or game

Record `google-all-default-app-or-game`. Action: **retain**. 3 characters; 3 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/app-or-game.txt).

<!-- COPY:google-all-default-app-or-game -->
```text
App
```
<!-- END_COPY:google-all-default-app-or-game -->

#### default — Email address

Record `google-all-default-email-address`. Action: **fill**. 25 characters; 25 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/email-address.txt).

<!-- COPY:google-all-default-email-address -->
```text
dreamprayer.dev@gmail.com
```
<!-- END_COPY:google-all-default-email-address -->

#### default — Website

Record `google-all-default-website`. Action: **fill**. 20 characters; 20 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/website.txt).

<!-- COPY:google-all-default-website -->
```text
https://travary.app/
```
<!-- END_COPY:google-all-default-website -->

#### default — Privacy policy

Record `google-all-default-privacy-policy`. Action: **fill**. 27 characters; 27 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/privacy-policy.txt).

<!-- COPY:google-all-default-privacy-policy -->
```text
https://travary.app/privacy
```
<!-- END_COPY:google-all-default-privacy-policy -->

#### default — Account deletion web link

Record `google-all-default-account-deletion-web-link`. Action: **fill**. 34 characters; 34 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/account-deletion-web-link.txt).

<!-- COPY:google-all-default-account-deletion-web-link -->
```text
https://travary.app/delete-account
```
<!-- END_COPY:google-all-default-account-deletion-web-link -->

#### creative_test — Default first headline

Record `google-all-creative_test-default-first-headline`. Action: **not applicable**. 24 characters; 24 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/default-first-headline.txt).

<!-- COPY:google-all-creative_test-default-first-headline -->
```text
Your bookings, in order.
```
<!-- END_COPY:google-all-creative_test-default-first-headline -->

#### creative_test — Offline headline

Record `google-all-creative_test-offline-headline`. Action: **not applicable**. 32 characters; 32 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/offline-headline.txt).

<!-- COPY:google-all-creative_test-offline-headline -->
```text
Saved tickets. No signal needed.
```
<!-- END_COPY:google-all-creative_test-offline-headline -->

#### creative_test — Gaps headline

Record `google-all-creative_test-gaps-headline`. Action: **not applicable**. 22 characters; 22 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/gaps-headline.txt).

<!-- COPY:google-all-creative_test-gaps-headline -->
```text
Spot the missing stay.
```
<!-- END_COPY:google-all-creative_test-gaps-headline -->

#### creative_test — Family headline

Record `google-all-creative_test-family-headline`. Action: **not applicable**. 27 characters; 27 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/family-headline.txt).

<!-- COPY:google-all-creative_test-family-headline -->
```text
One trip. Up to six people.
```
<!-- END_COPY:google-all-creative_test-family-headline -->

#### creative_test — Import headline

Record `google-all-creative_test-import-headline`. Action: **not applicable**. 34 characters; 34 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/import-headline.txt).

<!-- COPY:google-all-creative_test-import-headline -->
```text
Check the draft. Keep the booking.
```
<!-- END_COPY:google-all-creative_test-import-headline -->

#### creative_test — Family feature graphic headline

Record `google-all-creative_test-family-feature-graphic-headline`. Action: **not applicable**. 16 characters; 16 UTF-8 bytes; limit No verified cap / selection or URL; remaining N/A; **COUNTED; no verified text cap**. [Exact text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/family-feature-graphic-headline.txt).

<!-- COPY:google-all-creative_test-family-feature-graphic-headline -->
```text
Travel together.
```
<!-- END_COPY:google-all-creative_test-family-feature-graphic-headline -->

## Consolidated text count table

| Record / locale | Field | Exact text or full-value link above | Characters | UTF-8 bytes | Limit / unit | Remaining | Result |
|---|---|---|---:|---:|---|---:|---|
| apple-en-US-default-name | Name | Itinerary App - Travary | 23 | 23 | 30 characters | 7 | PASS |
| apple-en-US-default-subtitle | Subtitle | Trip planner & offline tickets | 30 | 30 | 30 characters | 0 | PASS |
| apple-en-US-default-keywords | Keywords | family,shared,packing,checklist,vacation,countdown,booking,organizer,documents,reminder | 87 | 87 | 100 UTF-8 bytes | 13 | PASS |
| apple-en-US-default-promotional-text | Promotional Text | Start with a booking. See each day in order, keep saved tickets offline and spot missing stays. Share trips and packing with up to 6 people with a pass. | 152 | 152 | 170 characters | 18 | PASS |
| apple-en-US-default-description | Description | [Full exact field](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/description.txt) | 2524 | 2524 | 4000 characters | 1476 | PASS |
| apple-en-US-default-support-url | Support URL | https://travary.app/support | 27 | 27 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| apple-en-US-default-marketing-url | Marketing URL | https://travary.app/ | 20 | 20 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| apple-en-US-family-promotional-text | Promotional Text | Keep the family on the same page. Share bookings and packing with up to 6 people, including the organizer, with a pass. Saved tickets stay accessible offline. | 158 | 158 | 170 characters | 12 | PASS |
| google-en-US-default-app-name | App name | Itinerary App - Travary | 23 | 23 | 30 characters | 7 | PASS |
| google-en-US-default-short-description | Short description | Keep bookings in order, save tickets offline and spot gaps in your trip. | 72 | 72 | 80 characters | 8 | PASS |
| google-en-US-default-full-description | Full description | [Full exact field](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/full-description.txt) | 2471 | 2471 | 4000 characters | 1529 | PASS |
| google-en-US-family-app-name | App name | Itinerary App - Travary | 23 | 23 | 30 characters | 7 | PASS |
| google-en-US-family-short-description | Short description | Shared trips and packing for up to 6 people with a pass. Saved tickets offline. | 79 | 79 | 80 characters | 1 | PASS |
| google-en-US-family-full-description | Full description | [Full exact field](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/full-description.txt) | 2504 | 2504 | 4000 characters | 1496 | PASS |
| apple-en-US-holiday_pass-display-name | Display Name | Holiday Pass | 12 | 12 | 30 characters | 18 | PASS |
| apple-en-US-holiday_pass-description | Description | Sharing and extras for a trip up to 30 days | 43 | 43 | 45 characters | 2 | PASS |
| apple-en-US-travary_annual_pass-display-name | Display Name | Annual Pass | 11 | 11 | 30 characters | 19 | PASS |
| apple-en-US-travary_annual_pass-description | Description | Sharing and extras for your trips, yearly | 41 | 41 | 45 characters | 4 | PASS |
| apple-en-GB-default-name | Name | Itinerary App - Travary | 23 | 23 | 30 characters | 7 | PASS |
| apple-en-GB-default-subtitle | Subtitle | Trip planner & offline tickets | 30 | 30 | 30 characters | 0 | PASS |
| apple-en-GB-default-keywords | Keywords | family,shared,packing,checklist,holiday,countdown,booking,organiser,documents,reminder | 86 | 86 | 100 UTF-8 bytes | 14 | PASS |
| apple-en-GB-default-promotional-text | Promotional Text | Start with a booking. See each day in order, keep saved tickets offline and spot missing stays. Share trips and packing with up to 6 people with a pass. | 152 | 152 | 170 characters | 18 | PASS |
| apple-en-GB-default-description | Description | [Full exact field](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/description.txt) | 2522 | 2522 | 4000 characters | 1478 | PASS |
| apple-en-GB-default-support-url | Support URL | https://travary.app/support | 27 | 27 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| apple-en-GB-default-marketing-url | Marketing URL | https://travary.app/ | 20 | 20 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| apple-en-GB-family-promotional-text | Promotional Text | Keep the family on the same page. Share bookings and packing with up to 6 people, including the organiser, with a pass. Saved tickets stay accessible offline. | 158 | 158 | 170 characters | 12 | PASS |
| google-en-GB-default-app-name | App name | Itinerary App - Travary | 23 | 23 | 30 characters | 7 | PASS |
| google-en-GB-default-short-description | Short description | Keep bookings in order, save tickets offline and spot gaps in your trip. | 72 | 72 | 80 characters | 8 | PASS |
| google-en-GB-default-full-description | Full description | [Full exact field](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/full-description.txt) | 2469 | 2469 | 4000 characters | 1531 | PASS |
| google-en-GB-family-app-name | App name | Itinerary App - Travary | 23 | 23 | 30 characters | 7 | PASS |
| google-en-GB-family-short-description | Short description | Shared trips and packing for up to 6 people with a pass. Saved tickets offline. | 79 | 79 | 80 characters | 1 | PASS |
| google-en-GB-family-full-description | Full description | [Full exact field](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/full-description.txt) | 2502 | 2502 | 4000 characters | 1498 | PASS |
| apple-en-GB-holiday_pass-display-name | Display Name | Holiday Pass | 12 | 12 | 30 characters | 18 | PASS |
| apple-en-GB-holiday_pass-description | Description | Sharing and extras for a trip up to 30 days | 43 | 43 | 45 characters | 2 | PASS |
| apple-en-GB-travary_annual_pass-display-name | Display Name | Annual Pass | 11 | 11 | 30 characters | 19 | PASS |
| apple-en-GB-travary_annual_pass-description | Description | Sharing and extras for your trips, yearly | 41 | 41 | 45 characters | 4 | PASS |
| apple-en-AU-default-name | Name | Itinerary App - Travary | 23 | 23 | 30 characters | 7 | PASS |
| apple-en-AU-default-subtitle | Subtitle | Trip planner & offline tickets | 30 | 30 | 30 characters | 0 | PASS |
| apple-en-AU-default-keywords | Keywords | family,shared,packing,checklist,holiday,countdown,booking,organiser,documents,reminder | 86 | 86 | 100 UTF-8 bytes | 14 | PASS |
| apple-en-AU-default-promotional-text | Promotional Text | Start with a booking. See each day in order, keep saved tickets offline and spot missing stays. Share trips and packing with up to 6 people with a pass. | 152 | 152 | 170 characters | 18 | PASS |
| apple-en-AU-default-description | Description | [Full exact field](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/description.txt) | 2522 | 2522 | 4000 characters | 1478 | PASS |
| apple-en-AU-default-support-url | Support URL | https://travary.app/support | 27 | 27 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| apple-en-AU-default-marketing-url | Marketing URL | https://travary.app/ | 20 | 20 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| apple-en-AU-family-promotional-text | Promotional Text | Keep the family on the same page. Share bookings and packing with up to 6 people, including the organiser, with a pass. Saved tickets stay accessible offline. | 158 | 158 | 170 characters | 12 | PASS |
| google-en-AU-default-app-name | App name | Itinerary App - Travary | 23 | 23 | 30 characters | 7 | PASS |
| google-en-AU-default-short-description | Short description | Keep bookings in order, save tickets offline and spot gaps in your trip. | 72 | 72 | 80 characters | 8 | PASS |
| google-en-AU-default-full-description | Full description | [Full exact field](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/full-description.txt) | 2469 | 2469 | 4000 characters | 1531 | PASS |
| google-en-AU-family-app-name | App name | Itinerary App - Travary | 23 | 23 | 30 characters | 7 | PASS |
| google-en-AU-family-short-description | Short description | Shared trips and packing for up to 6 people with a pass. Saved tickets offline. | 79 | 79 | 80 characters | 1 | PASS |
| google-en-AU-family-full-description | Full description | [Full exact field](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/full-description.txt) | 2502 | 2502 | 4000 characters | 1498 | PASS |
| apple-en-AU-holiday_pass-display-name | Display Name | Holiday Pass | 12 | 12 | 30 characters | 18 | PASS |
| apple-en-AU-holiday_pass-description | Description | Sharing and extras for a trip up to 30 days | 43 | 43 | 45 characters | 2 | PASS |
| apple-en-AU-travary_annual_pass-display-name | Display Name | Annual Pass | 11 | 11 | 30 characters | 19 | PASS |
| apple-en-AU-travary_annual_pass-description | Description | Sharing and extras for your trips, yearly | 41 | 41 | 45 characters | 4 | PASS |
| apple-all-family-reference-name | Reference Name | Family & packing | 16 | 16 | 100 characters | 84 | PASS |
| google-all-default-default-language | Default language | English (United States) – en-US | 31 | 33 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-family-listing-name | Listing name | Family trip planner | 19 | 19 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-family-targeting | Targeting | Search keywords | 15 | 15 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-family-default-language | Default language | English (United States) – en-US | 31 | 33 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| apple-all-default-primary-category | Primary Category | Travel | 6 | 6 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| apple-all-default-license-agreement | License Agreement | Standard Apple License Agreement | 32 | 32 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| apple-all-default-privacy-policy-url | Privacy Policy URL | https://travary.app/privacy | 27 | 27 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| apple-all-default-terms-url-description-link | Terms URL (description link) | https://travary.app/terms | 25 | 25 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-default-category | Category | Travel & Local | 14 | 14 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-default-app-or-game | App or game | App | 3 | 3 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-default-email-address | Email address | dreamprayer.dev@gmail.com | 25 | 25 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-default-website | Website | https://travary.app/ | 20 | 20 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-default-privacy-policy | Privacy policy | https://travary.app/privacy | 27 | 27 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-default-account-deletion-web-link | Account deletion web link | https://travary.app/delete-account | 34 | 34 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-en-US-default-screenshot-alt-text-android-phone-1080x1920-01 | Screenshot alt text | Today shows the day's bookings in time order. | 45 | 45 | 140 characters | 95 | PASS |
| google-en-US-default-screenshot-alt-text-android-phone-1080x1920-02 | Screenshot alt text | Saved bookings and tickets remain accessible offline on every plan. | 67 | 67 | 140 characters | 73 | PASS |
| google-en-US-default-screenshot-alt-text-android-phone-1080x1920-03 | Screenshot alt text | The trip plan highlights a missing stay and flight home. | 56 | 56 | 140 characters | 84 | PASS |
| google-en-US-default-screenshot-alt-text-android-phone-1080x1920-04 | Screenshot alt text | A shared trip for up to six people, including the organizer, with a pass. | 73 | 73 | 140 characters | 67 | PASS |
| google-en-US-default-screenshot-alt-text-android-phone-1080x1920-05 | Screenshot alt text | Smart Import reads a confirmation into a draft to check. Two free imports, then a pass. | 87 | 87 | 140 characters | 53 | PASS |
| google-en-US-default-screenshot-alt-text-android-phone-1080x1920-06 | Screenshot alt text | A trip packing checklist, with shared packing available with a pass. | 68 | 68 | 140 characters | 72 | PASS |
| google-en-US-default-screenshot-alt-text-android-phone-1080x1920-07 | Screenshot alt text | A destination postcard and countdown to the next trip. | 54 | 54 | 140 characters | 86 | PASS |
| google-en-US-default-screenshot-alt-text-android-phone-1080x1920-08 | Screenshot alt text | A home-screen countdown widget for the next trip. | 49 | 49 | 140 characters | 91 | PASS |
| google-en-US-default-feature-graphic-alt-text | Feature graphic alt text | Travi beside a day of travel bookings. | 38 | 38 | 140 characters | 102 | PASS |
| google-en-US-family-screenshot-alt-text-android-phone-1080x1920-01 | Screenshot alt text | A shared trip for up to six people, including the organizer, with a pass. | 73 | 73 | 140 characters | 67 | PASS |
| google-en-US-family-screenshot-alt-text-android-phone-1080x1920-02 | Screenshot alt text | A trip packing checklist, with shared packing available with a pass. | 68 | 68 | 140 characters | 72 | PASS |
| google-en-US-family-screenshot-alt-text-android-phone-1080x1920-03 | Screenshot alt text | Today shows the day's bookings in time order. | 45 | 45 | 140 characters | 95 | PASS |
| google-en-US-family-screenshot-alt-text-android-phone-1080x1920-04 | Screenshot alt text | Saved bookings and tickets remain accessible offline on every plan. | 67 | 67 | 140 characters | 73 | PASS |
| google-en-US-family-screenshot-alt-text-android-phone-1080x1920-05 | Screenshot alt text | The trip plan highlights a missing stay and flight home. | 56 | 56 | 140 characters | 84 | PASS |
| google-en-US-family-screenshot-alt-text-android-phone-1080x1920-06 | Screenshot alt text | Smart Import reads a confirmation into a draft to check. Two free imports, then a pass. | 87 | 87 | 140 characters | 53 | PASS |
| google-en-US-family-screenshot-alt-text-android-phone-1080x1920-07 | Screenshot alt text | A destination postcard and countdown to the next trip. | 54 | 54 | 140 characters | 86 | PASS |
| google-en-US-family-screenshot-alt-text-android-phone-1080x1920-08 | Screenshot alt text | A home-screen countdown widget for the next trip. | 49 | 49 | 140 characters | 91 | PASS |
| google-en-US-family-feature-graphic-alt-text | Feature graphic alt text | Travi beside a shared trip and packing checklist. | 49 | 49 | 140 characters | 91 | PASS |
| google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-01 | Screenshot alt text | Today shows the day's bookings in time order. | 45 | 45 | 140 characters | 95 | PASS |
| google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-02 | Screenshot alt text | Saved bookings and tickets remain accessible offline on every plan. | 67 | 67 | 140 characters | 73 | PASS |
| google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-03 | Screenshot alt text | The trip plan highlights a missing stay and flight home. | 56 | 56 | 140 characters | 84 | PASS |
| google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-04 | Screenshot alt text | A shared trip for up to six people, including the organiser, with a pass. | 73 | 73 | 140 characters | 67 | PASS |
| google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-05 | Screenshot alt text | Smart Import reads a confirmation into a draft to check. Two free imports, then a pass. | 87 | 87 | 140 characters | 53 | PASS |
| google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-06 | Screenshot alt text | A trip packing checklist, with shared packing available with a pass. | 68 | 68 | 140 characters | 72 | PASS |
| google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-07 | Screenshot alt text | A destination postcard and countdown to the next trip. | 54 | 54 | 140 characters | 86 | PASS |
| google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-08 | Screenshot alt text | A home-screen countdown widget for the next trip. | 49 | 49 | 140 characters | 91 | PASS |
| google-en-GB-default-feature-graphic-alt-text | Feature graphic alt text | Travi beside a day of travel bookings. | 38 | 38 | 140 characters | 102 | PASS |
| google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-01 | Screenshot alt text | A shared trip for up to six people, including the organiser, with a pass. | 73 | 73 | 140 characters | 67 | PASS |
| google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-02 | Screenshot alt text | A trip packing checklist, with shared packing available with a pass. | 68 | 68 | 140 characters | 72 | PASS |
| google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-03 | Screenshot alt text | Today shows the day's bookings in time order. | 45 | 45 | 140 characters | 95 | PASS |
| google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-04 | Screenshot alt text | Saved bookings and tickets remain accessible offline on every plan. | 67 | 67 | 140 characters | 73 | PASS |
| google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-05 | Screenshot alt text | The trip plan highlights a missing stay and flight home. | 56 | 56 | 140 characters | 84 | PASS |
| google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-06 | Screenshot alt text | Smart Import reads a confirmation into a draft to check. Two free imports, then a pass. | 87 | 87 | 140 characters | 53 | PASS |
| google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-07 | Screenshot alt text | A destination postcard and countdown to the next trip. | 54 | 54 | 140 characters | 86 | PASS |
| google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-08 | Screenshot alt text | A home-screen countdown widget for the next trip. | 49 | 49 | 140 characters | 91 | PASS |
| google-en-GB-family-feature-graphic-alt-text | Feature graphic alt text | Travi beside a shared trip and packing checklist. | 49 | 49 | 140 characters | 91 | PASS |
| google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-01 | Screenshot alt text | Today shows the day's bookings in time order. | 45 | 45 | 140 characters | 95 | PASS |
| google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-02 | Screenshot alt text | Saved bookings and tickets remain accessible offline on every plan. | 67 | 67 | 140 characters | 73 | PASS |
| google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-03 | Screenshot alt text | The trip plan highlights a missing stay and flight home. | 56 | 56 | 140 characters | 84 | PASS |
| google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-04 | Screenshot alt text | A shared trip for up to six people, including the organiser, with a pass. | 73 | 73 | 140 characters | 67 | PASS |
| google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-05 | Screenshot alt text | Smart Import reads a confirmation into a draft to check. Two free imports, then a pass. | 87 | 87 | 140 characters | 53 | PASS |
| google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-06 | Screenshot alt text | A trip packing checklist, with shared packing available with a pass. | 68 | 68 | 140 characters | 72 | PASS |
| google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-07 | Screenshot alt text | A destination postcard and countdown to the next trip. | 54 | 54 | 140 characters | 86 | PASS |
| google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-08 | Screenshot alt text | A home-screen countdown widget for the next trip. | 49 | 49 | 140 characters | 91 | PASS |
| google-en-AU-default-feature-graphic-alt-text | Feature graphic alt text | Travi beside a day of travel bookings. | 38 | 38 | 140 characters | 102 | PASS |
| google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-01 | Screenshot alt text | A shared trip for up to six people, including the organiser, with a pass. | 73 | 73 | 140 characters | 67 | PASS |
| google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-02 | Screenshot alt text | A trip packing checklist, with shared packing available with a pass. | 68 | 68 | 140 characters | 72 | PASS |
| google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-03 | Screenshot alt text | Today shows the day's bookings in time order. | 45 | 45 | 140 characters | 95 | PASS |
| google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-04 | Screenshot alt text | Saved bookings and tickets remain accessible offline on every plan. | 67 | 67 | 140 characters | 73 | PASS |
| google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-05 | Screenshot alt text | The trip plan highlights a missing stay and flight home. | 56 | 56 | 140 characters | 84 | PASS |
| google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-06 | Screenshot alt text | Smart Import reads a confirmation into a draft to check. Two free imports, then a pass. | 87 | 87 | 140 characters | 53 | PASS |
| google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-07 | Screenshot alt text | A destination postcard and countdown to the next trip. | 54 | 54 | 140 characters | 86 | PASS |
| google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-08 | Screenshot alt text | A home-screen countdown widget for the next trip. | 49 | 49 | 140 characters | 91 | PASS |
| google-en-AU-family-feature-graphic-alt-text | Feature graphic alt text | Travi beside a shared trip and packing checklist. | 49 | 49 | 140 characters | 91 | PASS |
| google-all-creative_test-default-first-headline | Default first headline | Your bookings, in order. | 24 | 24 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-creative_test-offline-headline | Offline headline | Saved tickets. No signal needed. | 32 | 32 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-creative_test-gaps-headline | Gaps headline | Spot the missing stay. | 22 | 22 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-creative_test-family-headline | Family headline | One trip. Up to six people. | 27 | 27 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-creative_test-import-headline | Import headline | Check the draft. Keep the booking. | 34 | 34 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-all-creative_test-family-feature-graphic-headline | Family feature graphic headline | Travel together. | 16 | 16 | Unverified / N/A | N/A | COUNTED; no verified text cap |
| google-en-GB-test_variant-short-description | Short description | Your bookings, tickets and daily plans together. Saved tickets work offline. | 76 | 76 | 80 characters | 4 | PASS |
## Existing screenshot captions — unchanged artwork

| Subject | Exact headline (⏎ means artwork line break) | Supporting caption | Purchase tag | Headline chars | Caption chars |
|---|---|---|---|---:|---:|
| 1 | Your holiday, ⏎ sorted into days. | Flights, stays, tickets and tables, in order. | None | 31 | 45 |
| 2 | Counting down ⏎ to the next one. | A postcard from where you're going. | None | 30 | 35 |
| 3 | It spots ⏎ what's missing. | The night without a stay. The flight home. | None | 24 | 42 |
| 4 | Hand Travi ⏎ the confirmation. | Smart Import reads screenshots and PDFs. | 2 free, then a pass | 28 | 40 |
| 5 | Just the ⏎ flight number. | The board flips in the times and airports. | None | 23 | 42 |
| 6 | Everyone on ⏎ the same page. | Up to 6 people, each with their own tickets. | With a pass | 26 | 44 |
| 7 | Tickets that work ⏎ with no signal. | Saved bookings and tickets, on every plan. | None | 33 | 42 |
| 8 | Your passport stays ⏎ on your phone. | Behind Face ID. Checked against your next trip. | None | 34 | 47 |
| 9 | Packed ⏎ together. | One packing list. Share it with a pass. | Share it with a pass (in supporting caption) | 16 | 39 |
| 10 | Every trip gets ⏎ its own postcard. | Drawn for where you're going. | None | 33 | 29 |
| 11 | Your next trip, ⏎ on your home screen. | A countdown widget, with Travi in it. | None | 36 | 37 |
Artwork captions have no separate console text-field cap. These are transcriptions for asset review, not instructions to regenerate images. Graphic caption counts include the transcribed line breaks; console copy counts above derive from exact text files.

## Non-text fields, omissions and blocked administrative values

| Record | Store / locale / page | Field | Action | Exact value | Dependency |
|---|---|---|---|---|---|
| apple-en-US-default-what-s-new-in-this-version | apple / en-US / default | What's New in This Version | not applicable | null | Owner approval of this proposal; First version 1.0: field not applicable; do not paste release notes |
| apple-en-US-family-keywords | apple / en-US / custom_product_page | Keywords | select | ["family", "packing", "shared"] | Owner approval of this proposal; These tokens must appear in eligible selector from latest approved locale Keywords; capture exact selected entries before approval to Publish; Do not add Itinerary App or subtitle terms as assumed eligible |
| apple-en-US-family-app-deep-link | apple / en-US / custom_product_page | App Deep Link | not applicable | null | Owner approval of this proposal; Omit. No tested family destination route has been established |
| apple-en-GB-default-what-s-new-in-this-version | apple / en-GB / default | What's New in This Version | not applicable | null | Owner approval of this proposal; First version 1.0: field not applicable; do not paste release notes |
| apple-en-GB-family-keywords | apple / en-GB / custom_product_page | Keywords | select | ["family", "packing", "shared"] | Owner approval of this proposal; These tokens must appear in eligible selector from latest approved locale Keywords; capture exact selected entries before approval to Publish; Do not add Itinerary App or subtitle terms as assumed eligible |
| apple-en-GB-family-app-deep-link | apple / en-GB / custom_product_page | App Deep Link | not applicable | null | Owner approval of this proposal; Omit. No tested family destination route has been established |
| apple-en-AU-default-what-s-new-in-this-version | apple / en-AU / default | What's New in This Version | not applicable | null | Owner approval of this proposal; First version 1.0: field not applicable; do not paste release notes |
| apple-en-AU-family-keywords | apple / en-AU / custom_product_page | Keywords | select | ["family", "packing", "shared"] | Owner approval of this proposal; These tokens must appear in eligible selector from latest approved locale Keywords; capture exact selected entries before approval to Publish; Do not add Itinerary App or subtitle terms as assumed eligible |
| apple-en-AU-family-app-deep-link | apple / en-AU / custom_product_page | App Deep Link | not applicable | null | Owner approval of this proposal; Omit. No tested family destination route has been established |
| apple-all-family-product-page-url | apple / shared / custom_product_page | Product Page URL | owner input required | null | Owner approval of this proposal; Generated only after page creation; never guess a ppId |
| google-all-family-search-keywords | google / shared / custom_store_listing | Search keywords | select | ["family trip planner", "shared trip planner"] | Owner approval of this proposal; Check availability and each spelling/translation variation; exclude navigation/generation/booking-service intent; If no suitable keywords available keep page as local proposal, no country-target workaround |
| google-all-family-countries | google / shared / custom_store_listing | Countries | not applicable | null | Owner approval of this proposal; Do not combine extra targeting in first keyword-page launch; system URL recorded after creation if supplied |
| google-all-family-user-state | google / shared / custom_store_listing | User state | not applicable | null | Owner approval of this proposal; Do not combine extra targeting in first keyword-page launch; system URL recorded after creation if supplied |
| google-all-family-google-ads-campaign | google / shared / custom_store_listing | Google Ads campaign | not applicable | null | Owner approval of this proposal; Do not combine extra targeting in first keyword-page launch; system URL recorded after creation if supplied |
| google-all-family-unique-url-parameter | google / shared / custom_store_listing | Unique URL parameter | not applicable | null | Owner approval of this proposal; Do not combine extra targeting in first keyword-page launch; system URL recorded after creation if supplied |
| apple-all-default-secondary-category | apple / shared / default | Secondary Category | not applicable | null | Owner approval of this proposal; Leave unset; no second category needed |
| apple-all-default-app-tags | apple / shared / default | App Tags | owner input required | null | Owner approval of this proposal; No assigned tags observed. Apple generates/reviews tags; retain accurate offered itinerary/trip tags, reject misleading maps/AI generator tags; no arbitrary tag entry |
| apple-all-default-copyright | apple / shared / default | Copyright | owner input required | null | Owner approval of this proposal; Owner must identify actual rights holder and year; developer display name is not proof of legal ownership |
| google-all-default-tags | google / shared / default | Tags | select | ["Travel & local"] | Owner approval of this proposal; Exact tag observed; select only this relevant tag, do not fill five for its own sake |
| google-all-default-phone-number | google / shared / default | Phone number | not applicable | null | Owner approval of this proposal; Optional; no owner-approved public phone. Leave blank |
| google-all-default-advertise-my-app-outside-of-google-play | google / shared / default | Advertise my app outside of Google Play | retain | true | Owner approval of this proposal; Observed checked; preserve, this study authorizes no paid campaign |
| apple-all-administration-age-ratings | apple / shared / administration | Age Ratings | owner input required | null | Owner approval of this proposal; Complete questionnaire from release content; not inferred from competitors |
| apple-all-administration-content-rights | apple / shared / administration | Content Rights | owner input required | null | Owner approval of this proposal; Owner confirms rights to artwork and data |
| apple-all-administration-app-privacy-declarations | apple / shared / administration | App Privacy declarations | owner input required | null | Owner approval of this proposal; Audit Firebase, RevenueCat, Smart Import backend, storage and retention; repository checklist is not signed declaration |
| apple-all-administration-accessibility-declarations | apple / shared / administration | Accessibility declarations | owner input required | null | Owner approval of this proposal; Device testing evidence required; no untested accessibility claims |
| apple-all-administration-export-compliance | apple / shared / administration | Export compliance | owner input required | null | Owner approval of this proposal; Use actual encryption implementation and legal review as needed |
| apple-all-administration-regulated-medical-device-status | apple / shared / administration | Regulated Medical Device Status | owner input required | null | Owner approval of this proposal; Owner completes applicable questionnaire; no invented declaration |
| apple-all-administration-digital-goods-and-services-questionnaire | apple / shared / administration | Digital Goods and Services questionnaire | owner input required | null | Owner approval of this proposal; Owner completes questionnaire if surfaced |
| apple-all-administration-trader-status-and-contact | apple / shared / administration | Trader status and contact | owner input required | null | Owner approval of this proposal; Retain existing verified status; owner resolves required trader/legal details |
| apple-all-administration-app-review-contact | apple / shared / administration | App Review Contact | owner input required | null | Owner approval of this proposal; Name, phone, email require owner input |
| apple-all-administration-sign-in-required | apple / shared / administration | Sign-in required | owner input required | null | Owner approval of this proposal; Observed checked with blank credentials. Verify guest review path on selected build; do not simply uncheck |
| apple-all-administration-username-and-password | apple / shared / administration | Username and Password | owner input required | null | Owner approval of this proposal; Only provide dedicated review credentials if necessary; do not invent or save secrets in this public handover |
| apple-all-administration-notes | apple / shared / administration | Notes | owner input required | null | Owner approval of this proposal; Provide tested review steps and pass purchase access after build validation |
| apple-all-administration-attachment | apple / shared / administration | Attachment | owner input required | null | Owner approval of this proposal; Only if reviewer needs specific supporting evidence |
| apple-all-administration-pricing-and-availability | apple / shared / administration | Pricing and Availability | owner input required | null | Owner approval of this proposal; Confirm free app distribution territories and device availability; do not infer selected app countries from subscription countries |
| apple-all-administration-app-store-version-release | apple / shared / administration | App Store Version Release | owner input required | null | Owner approval of this proposal; Observed automatic release. Recommend manual release only in later approved setup to retain launch control |
| apple-all-administration-build | apple / shared / administration | Build | owner input required | null | Owner approval of this proposal; Observed build 4 version 1.0.0; owner identifies release candidate after checks |
| apple-all-administration-in-app-purchases-and-subscriptions | apple / shared / administration | In-App Purchases and Subscriptions | owner input required | null | Owner approval of this proposal; Confirm both first products attached to first app review; Annual is Prepare for Submission |
| apple-all-administration-purchase-pricing-and-availability | apple / shared / administration | Purchase pricing and availability | owner input required | null | Owner approval of this proposal; Annual AU AUD59.99 observed, not full US/UK/Google/Holiday validation. No price/trial copy. Keep prices unchanged |
| apple-all-administration-subscription-group-display-name | apple / shared / administration | Subscription group display name | owner input required | null | Owner approval of this proposal; Group localization not configured. Confirm intended customer name and current limit before filling |
| apple-all-administration-purchase-options-and-family-sharing | apple / shared / administration | Purchase options and Family Sharing | owner input required | null | Owner approval of this proposal; Apple Family Sharing off; distinct from in-app six-person sharing. Multiseat allowed by default; owner decides policy, no silent change |
| apple-all-administration-tax-banking-and-agreements | apple / shared / administration | Tax, banking and agreements | owner input required | null | Owner approval of this proposal; Owner-only legal/account setup outside copywriting |
| google-all-administration-data-safety | google / shared / administration | Data safety | owner input required | null | Owner approval of this proposal; Owner signs after SDK/network/storage audit, including account deletion |
| google-all-administration-app-access | google / shared / administration | App access | owner input required | null | Owner approval of this proposal; Test reviewer guest and paid paths; supply credentials only if required |
| google-all-administration-ads-declaration | google / shared / administration | Ads declaration | owner input required | null | Owner approval of this proposal; Verify shipped SDKs; do not infer from no ads in copy |
| google-all-administration-content-rating | google / shared / administration | Content rating | owner input required | null | Owner approval of this proposal; Complete IARC questionnaire from actual content |
| google-all-administration-target-audience-and-content | google / shared / administration | Target audience and content | owner input required | null | Owner approval of this proposal; Family travel does not automatically mean child-directed app; owner declares audience |
| google-all-administration-financial-features | google / shared / administration | Financial features | owner input required | null | Owner approval of this proposal; Complete applicable declaration from actual app |
| google-all-administration-health-apps | google / shared / administration | Health apps | owner input required | null | Owner approval of this proposal; Complete applicable declaration from actual app |
| google-all-administration-permissions-declarations | google / shared / administration | Permissions declarations | owner input required | null | Owner approval of this proposal; Review any sensitive permissions surfaced for actual release manifest |
| google-all-administration-government-apps-news-declarations | google / shared / administration | Government apps / news declarations | owner input required | null | Owner approval of this proposal; Complete any applicable mandatory questionnaires |
| google-all-administration-developer-contact-and-verification | google / shared / administration | Developer contact and verification | owner input required | null | Owner approval of this proposal; Account dashboard says verification tasks pending; owner completes privately |
| google-all-administration-countries-and-regions | google / shared / administration | Countries and regions | owner input required | null | Owner approval of this proposal; Owner chooses initial distribution; study recommends AU first, then UK and US |
| google-all-administration-pricing | google / shared / administration | Pricing | owner input required | null | Owner approval of this proposal; Confirm free base app; paid product IDs, regional prices, no trial assumed |
| google-all-administration-subscriptions-and-one-time-products | google / shared / administration | Subscriptions and one-time products | owner input required | null | Owner approval of this proposal; Verify holiday_pass, travary_annual_pass and base plan travary-annual-pass in live account; do not create duplicates |
| google-all-administration-production-access | google / shared / administration | Production access | owner input required | null | Owner approval of this proposal; 0 closed testers observed; at least12 opted in continuously14 days plus production application required |
| google-all-administration-app-bundle-and-signing | google / shared / administration | App bundle and signing | owner input required | null | Owner approval of this proposal; Confirm signed release, target API, device support, widget/flight tests |
| google-all-administration-release-notes | google / shared / administration | Release notes | owner input required | null | Owner approval of this proposal; Separate release-specific text, not listing description; derive from exact build |
| google-all-administration-managed-publishing | google / shared / administration | Managed publishing | owner input required | null | Owner approval of this proposal; Record actual current state and owner-approved publishing mode; do not assume Save prevents automatic rollout |
| apple-en-US-default-app-previews | apple / en-US / default | App Previews | not applicable | null | Owner approval of this proposal; Launch without preview; 7-second brand loops belong in Header/Search Results, not app-preview slot |
| apple-en-US-family-app-previews | apple / en-US / custom_product_page | App Previews | not applicable | null | Owner approval of this proposal; Launch without preview; 7-second brand loops belong in Header/Search Results, not app-preview slot |
| apple-en-GB-default-app-previews | apple / en-GB / default | App Previews | not applicable | null | Owner approval of this proposal; Launch without preview; 7-second brand loops belong in Header/Search Results, not app-preview slot |
| apple-en-GB-family-app-previews | apple / en-GB / custom_product_page | App Previews | not applicable | null | Owner approval of this proposal; Launch without preview; 7-second brand loops belong in Header/Search Results, not app-preview slot |
| apple-en-AU-default-app-previews | apple / en-AU / default | App Previews | not applicable | null | Owner approval of this proposal; Launch without preview; 7-second brand loops belong in Header/Search Results, not app-preview slot |
| apple-en-AU-family-app-previews | apple / en-AU / custom_product_page | App Previews | not applicable | null | Owner approval of this proposal; Launch without preview; 7-second brand loops belong in Header/Search Results, not app-preview slot |
| google-en-US-default-video | google / en-US / default | Video | not applicable | null | Owner approval of this proposal; No launch video; this field takes YouTube URL, not Apple MP4 |
| google-en-US-family-video | google / en-US / custom_store_listing | Video | not applicable | null | Owner approval of this proposal; No launch video; this field takes YouTube URL, not Apple MP4 |
| google-en-GB-default-video | google / en-GB / default | Video | not applicable | null | Owner approval of this proposal; No launch video; this field takes YouTube URL, not Apple MP4 |
| google-en-GB-family-video | google / en-GB / custom_store_listing | Video | not applicable | null | Owner approval of this proposal; No launch video; this field takes YouTube URL, not Apple MP4 |
| google-en-AU-default-video | google / en-AU / default | Video | not applicable | null | Owner approval of this proposal; No launch video; this field takes YouTube URL, not Apple MP4 |
| google-en-AU-family-video | google / en-AU / custom_store_listing | Video | not applicable | null | Owner approval of this proposal; No launch video; this field takes YouTube URL, not Apple MP4 |
| apple-all-administration-promoted-purchases-offers | apple / shared / administration | Promoted purchases / offers | not applicable | null | Owner approval of this proposal; No promotion at launch; Holiday Pass requires trip context; purchase-from-store handling and approved promotional1024x1024 image not verified |
| google-all-administration-promoted-purchases-offers | google / shared / administration | Promoted purchases / offers | not applicable | null | Owner approval of this proposal; No promotion at launch; Holiday Pass requires trip context; purchase-from-store handling and approved promotional1024x1024 image not verified |