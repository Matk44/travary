# travary.app: SEO / AEO strategy

Written 10 October 2026, when the site was first built. Private: this file is
never deployed (only `website/public/` is).

## 1. What we're marketing

Travary is a holiday organiser, not a trip-research tool. Its marketing angle
comes straight from the product plan: **"You planned it. Travary keeps
everyone on it."** The things a search visitor can't get elsewhere:

| Travary has | Why it matters in search |
|---|---|
| Bookings first: trips form themselves from dates | Answers "how do I organise my bookings" without "create a trip" friction |
| **Today**: opens on what you need right now, time rail, ticket one tap away | Nobody else is built around the day itself (TripIt organises, Wanderlog plans) |
| Countdown postcard + luggage tag between trips | A free web tool can show this off (`/holiday-countdown`) |
| Floating local time (times as printed) | Expert authority on "are flight times local", "+1 on a flight" |
| Trip gaps (nights without a stay, the flight home) + "Before you go" checklist | Matches checklist / "things to do before going on holiday" intent |
| Travel documents on the phone only, Face ID, 6-month expiry check | Matches "passport 6 month rule", "copy of passport on phone" |
| Family sharing on iPhone **and** Android | Tripsy is Apple-only; "share itinerary with family" |
| 30 destination postcards + 57 onboarding stages + Travi films | Unique, beautiful art nobody else can use: every page looks unlike the SERP |

Not shipped at launch, so the site never claims them: live flight status in
release builds, widgets / Live Activities, email forwarding, share-sheet
import. (Flight alerts now ship at launch, 13 Oct 2026: delays and changes,
never gates or belts.)

## 2. What the DreamPrayer site taught us

From the memory notes of the four sibling sites (all on the same
`build_guides.py` architecture):

- **The format works.** Answer-first paragraph + FAQ schema + Article schema +
  breadcrumbs got biblicaldreaminterpretations.com cited in Google's AI
  Overviews within six weeks. 28-day numbers went 104 → 433 → 1,200 clicks
  (Jul–Sep 2026), position ~5.
- **Programmatic long-tail carries the site.** The per-symbol pages earned the
  traffic; the "foundations" pages got ~1 click each. Travary's equivalent:
  destination itineraries (30 postcards ready) and question pages.
- **Blue ocean beats big ocean.** HairAI stalled at position ~57 because
  Byrdie/Allure/Vogue own editorial beauty SERPs; DreamPrayer won because its
  SERPs were weak. **Travel's head terms are owned by TripAdvisor, Lonely
  Planet, Condé Nast and big blogs**, so we start with tool-intent and
  question-intent queries where the competition is app vendors' blogs,
  aggregator spam and thin listicles.
- **Honesty is the differentiator** (DreamPrayer's cats/dogs/demons pages). In
  travel that means: disclose we make Travary on comparison pages, cite
  official sources (UK FCDO data on the passport page), don't invent prices.
- **New domains are slow.** DreamPrayer's domain was already indexed;
  tinypsalms.app, bythewaterbible.com and hairaisalon.com (new domains) took
  months to reach page 1–2. Judge travary.app by impressions and query count
  for the first 3 months, not clicks.
- **Technical gotchas, all handled here:** extensionless URLs on Cloudflare
  Pages (`.html` 308-redirects split rankings), a real `404.html` (Pages
  otherwise serves the home page for every unknown URL), deploy a public-only
  folder (three sites leaked `app.md` and build scripts), `--branch main` on
  `wrangler pages deploy`, never list a noindex page in the sitemap,
  per-page `updated` dates, Cloudflare's managed robots.txt blocks AI crawlers
  until switched off.
- **Cross-site links work when they're genuinely on-topic** (DreamPrayer →
  Tiny Psalms via a real child-nightmares article).

## 3. Keyword research

Method: Google Autocomplete mined for 54 seed phrases (US, UK and AU), about
2,800 suggestions; SERPs checked for the main clusters; Astro ASO numbers
from the earlier App Store work (itinerary app 37/49, itinerary planner
31/55, holiday planner 20/42, trip organizer 5/23). Autocomplete shows what
people type, not volumes, so priorities below come from breadth of
long-tail variants × weakness of the current SERP × fit with the app.

| Cluster | Example long-tails people type | SERP today | Fit | Page |
|---|---|---|---|---|
| **Itinerary templates** | travel itinerary template free printable, holiday itinerary template google docs/excel/word, family vacation itinerary template, disney world daily itinerary template | Template spam on hijacked .ac.uk/.gov domains, Canva, Gumroad | Tool | `/itinerary-template` |
| **Countdowns** | holiday countdown, vacation countdown app, best holiday countdown app free, disney countdown, how many days until my holiday, holiday countdown with own picture | Weak: educationalappstore, spam | Tool + feature | `/holiday-countdown` |
| **How to plan / make an itinerary** | how to make a travel itinerary, how to plan a holiday itinerary, how to make a good travel itinerary, holiday itinerary example | Mid: blogs, Wanderlog | Core | `how-to-make-a-travel-itinerary` |
| **Before you go** | things to do before going on holiday / vacation, at home before going on holiday, holiday checklist abroad, checklist before travelling abroad | Mid: TravelSupermarket, NatWest, Post Office, small blogs | "Before you go" | `things-to-do-before-going-on-holiday` |
| **Family** | family holiday checklist, holiday checklist abroad with kids, family holiday planner app, how to plan a family holiday, family trip planner | Weak-mid | Core audience | `family-holiday-checklist`, `how-to-plan-a-family-holiday` |
| **Flight times** | are flight times local, are arrival times local, all flight times are local meaning, what does +1 mean on a flight, overnight flight what day | Very weak: forums, spam | Floating time = expert | `are-flight-times-local`, `what-does-plus-one-mean-on-a-flight` |
| **Airport / boarding pass** | how early should i get to the airport (+ airline/airport/kids variants), do i need to print my boarding pass (+ airline variants), boarding pass on phone | Mid: airlines, airports | Today / tickets offline | `how-early-to-get-to-the-airport`, `do-i-need-to-print-my-boarding-pass` |
| **Passports** | passport 6 month rule (+ 30 country variants), countries with 6 month passport rule, does the 6 month rule apply to children/cruises | Mid: TPG, Chase, Wego; lists disagree | Expiry check | `passport-six-month-rule` |
| **Documents** | travel documents checklist, copy of passport on phone, digital copy of passport, what documents do I need to travel abroad | Mid | Travel documents | `travel-documents-checklist`, `copy-of-passport-on-phone` |
| **Organising / sharing** | best app to organise travel plans, keep all travel documents in one place, best way to share itinerary with family | Weak: app blogs | Core | `how-to-organise-travel-bookings`, `how-to-share-travel-itinerary-with-family` |
| **App comparisons** | best itinerary app, best travel organizer app (reddit), tripit alternatives, apps like tripit, is tripit worth it, wanderlog vs tripit | App vendors' own blogs, sponsored roundups | Bottom of funnel | `best-itinerary-apps`, `tripit-alternatives` |
| **Destination itineraries** | orlando itinerary with kids / 7 days, disney world itinerary 4/5/7 days, lake district itinerary 3 days without car, paris itinerary with kids, japan itinerary 2 weeks | Competitive (big blogs) but huge long tail | Postcard art per place | 4 itineraries at launch |

Deliberately not targeted yet: "travel app", "trip planner" (Astro difficulty
67–88, owned by Expedia/Google/TripAdvisor), "things to do in X"
(destination authorities), visa requirements by nationality (legal risk,
changes constantly).

UK/AU say "holiday", US says "vacation": titles lead with "holiday" (the
app's own word and the user's market), body copy and FAQs carry "vacation"
where it reads naturally.

## 3b. The blue-ocean map (evidence checked 10 October 2026)

Demand: Google Trends, past 12 months (relative interest, so ratios not
volumes). Competition: who actually ranks today.

| Trends (US, past 12 months) | Average interest |
|---|---|
| packing list | ~52 |
| trip planner (head term, for scale) | ~37 |
| itinerary template | ~13 (≈3× the brand search "tripit") |
| disney itinerary | ~4 |
| disney countdown / vacation countdown | ~3 / ~1 |
| 6 month passport | ~1 |

UK (holiday wording): "holiday packing list", "holiday checklist",
"itinerary template" and "holiday countdown" each run at roughly the same
interest as "trip planner".

| Niche | Demand | Who ranks now | Verdict |
|---|---|---|---|
| **Itinerary templates by trip type** (cruise, road trip, Disney, family, Europe, Japan, business, honeymoon…) | High: a third of "trip planner" in the US, equal in the UK | Template spam on hijacked university/government domains, Jotform, Canva, Visme, Craft | **Best opportunity.** One tool page built; spin out 8–10 pre-filled variants |
| **Packing lists** (beach, cruise, Disney, baby/toddler, family of 4, all-inclusive, carry-on, 10/14 days) | Highest of all: bigger than "trip planner" | The same spam, a hotel blog, a $2 Gumroad file | **Biggest gap at launch.** Build a tickable, printable packing-list tool + variants |
| **"Holiday checklist for [country]"** (Spain, Türkiye, Greece, Dubai, Cyprus…), UK package-holiday market | Medium, long tail | Mumsnet threads, travel agents, blogs | **Blue ocean.** Programmatic pages from data: passport rule, plugs, currency, driving side, emergency number |
| **Passport validity by country** | Small each, 30+ variants | A news farm, scraped pages, NerdWallet | Fold into the country checklists (FCDO content API keeps them current) rather than thin pages |
| **Flight-time questions** (local time, +1, overnight) | Small | Forums and spam | Built. Cheap AEO wins |
| **App comparisons** (TripIt alternatives, Wanderlog vs TripIt) | Small, high intent | Vendors' own blogs, AlternativeTo, spam | Built 2; add Wanderlog vs TripIt, best Disney countdown app |
| Countdowns | Smaller than assumed in the US | App Store listings | Keep the tool; add Disney and cruise variants only |
| Avoid: "trip planner", "travel app", "things to do in X", big Disney planning | Huge | TripAdvisor, Lonely Planet, Disney Tourist Blog, Undercover Tourist | Not until the domain has authority |

## 3c. Conversion first: people looking for an app (decided 10 October 2026)

The owner's call: aim at searchers who want an app, because they convert,
ahead of broad informational traffic. Evidence:

| Trends, past 12 months | US | UK |
|---|---|---|
| itinerary app | **~50** | ~2 |
| trip planner app | ~9 | ~0 |
| travel planner app | ~6 | — |
| vacation / holiday planner app | ~0 | ~0 |
| travel app | — | ~50 (too broad; difficulty 88 in Astro) |
| holiday app | — | ~25 (mostly people after TUI/Jet2's apps) |

"Itinerary app" is the way people search for this kind of app in the US, by
a wide margin, and it matches the store name (Itinerary App - Travary) and
Astro (37 popularity / 49 difficulty). Its SERP is surprisingly open: small
apps' App Store listings, travel-agent tools, and pages about *building* an
itinerary app. The long tails are open too: "best itinerary app for
families" (parenting blogs), "itinerary app that works offline" (a 2013
forum), "holiday planner app uk" (one 2024 phone-network post), Disney
planning apps (small listings plus AlternativeTo).

What's built for it:

- **Home page** retargeted: title "Travary: Itinerary App & Holiday
  Planner", "Itinerary app · iPhone & Android", first sentence "Travary is
  the itinerary app for…", a real-screens rail, and a "Made for your kind
  of trip" grid.
- **Use-case landing pages** (top-level URLs, `content/apps/`), each with a
  distinct angle, real screens, FAQs and an inline waiting-list form:
  `/itinerary-app-for-families`, `/shared-itinerary-app`,
  `/offline-itinerary-app`, `/holiday-planner-app` (UK/AU wording),
  `/disney-world-planning-app`, `/travel-document-organizer-app`.
- **Comparisons:** `/travary-vs-tripit`, `/travary-vs-wanderlog`.
- **`/about`**, a fact sheet and press kit that AI assistants and
  journalists can quote.

Measure it: the waiting list stores the page each person joined from, so
`python3 website/tool/waitlist.py` shows which pages convert.

Next app-intent pages, if the data supports them: itinerary app for
Android (Tripsy is iPhone-only), Japan itinerary app, cruise itinerary
app, Travary vs Tripsy, holiday countdown app.

### Ideas taken from the By The Water playbook

Used: every home FAQ answer ends with a "Learn more" link (hub and
spoke); a tile grid of in-app art that links somewhere (the postcard wall
now opens the countdown on that postcard); a screenshot rail; honest stats
only (no ratings until there are real ones); lighter images (countdown
postcards cut from ~200 KB to ~130 KB); a how-to-use page. Still to do: a
short screen recording of the app ("see it in action", under 1 MB, muted
loop); the Smart App Banner at launch.

### Off-site matters most for app searches

Google's results and AI answers for "best itinerary app", "TripIt
alternatives" and "Disney planning app" lean on third-party pages:
AlternativeTo, app directories (mwm.ai, PeerPush), Reddit threads and
listicles. Our own pages can't fully replace that. At launch:

- [ ] List Travary on AlternativeTo as an alternative to TripIt, Wanderlog
      and Tripsy (it ranks for "TripIt alternatives").
- [ ] Product Hunt launch.
- [ ] Ask the authors of the small "best itinerary apps 2026" roundups to
      include Travary (several are other apps' blogs or independent sites).
- [ ] Reddit: answer real questions in r/travel, r/TravelHacks,
      r/disneyworld and r/solotravel only where Travary genuinely fits, and
      say you made it.
- [ ] Short videos of Travi and the countdown for TikTok, Reels and Shorts.

## 4. Built for launch (25 pages)

Home · 2 free tools · 16 guides · 4 itineraries · 2 hubs · 404. Every guide:
answer-first box, time-rail contents, FAQ (schema), Article + Breadcrumb
schema, per-page share image with its postcard, an in-article Travary box,
related links, tickable checklists where relevant.

## 5. What to write next (in this order)

Revised after the evidence in 3b: the tools and checklists come first,
because that's where demand is high and the results pages are weakest.

1. **Itinerary template variants** (8–10 pages, weeks 1–2): cruise, road
   trip, Disney World, family vacation, Europe, Japan, business trip,
   honeymoon, school trip, weekend away. Each is the existing tool,
   pre-filled for that trip type, with its own postcard.
2. **Packing-list tool + variants** (weeks 2–4): tickable, printable,
   shareable; beach, cruise, Disney, baby and toddler, family of 4,
   all-inclusive, carry-on only, city break, ski.
3. **"Holiday checklist for [country]"** (weeks 4–8): the top 20 holiday
   countries, generated from data (FCDO entry rules, plug type, currency,
   driving side, emergency number), refreshed by the build script.
4. **Destination itineraries, one a week** (the DreamPrayer symbol-page
   engine): every place with a postcard. Start with high-intent family and
   first-timer queries: Kyoto 3 days, Tokyo with kids, Bali 10 days, Lisbon 4
   days, Rome with kids, London with kids, New York 4 days, Barcelona 3 days,
   Sydney 5 days, Edinburgh 2 days, Disneyland Paris 2 days, Singapore 3
   days. Each gets its stage art and countdown postcard.
5. **Disney-specific long tail** (huge, family, fits the launch audience):
   Disney World itinerary 4 / 5 days, first time at Disney World, Disney
   World with a toddler, best Disney countdown app.
6. **Day-of questions** (AEO gold, weak SERPs): what to do if your flight is
   cancelled, how to survive an overnight flight with kids, jet lag with
   children, what time is hotel check-in, can you check in to a hotel early,
   what is the EU's EES / ETIAS, the UK ETA explained.
7. **Comparisons**: Wanderlog vs TripIt, best holiday countdown apps, best
   family trip planner apps (once Travary is live, with real screenshots).
8. **Seasonal**: summer holiday checklist (publish in April), Christmas
   travel checklist (September), half-term ideas (UK).

Re-read Search Console monthly and follow the data: write spin-off pages for
queries that get impressions inside a broader page (DreamPrayer's floods /
ocean / childhood home pages came from exactly that).

## 6. Launch checklist

Done 10 October 2026:

- [x] Cloudflare Pages project `travary` (classic Pages, direct upload),
      `website/public` deployed.
- [x] Custom domains `travary.app` and `www.travary.app` connected (the
      Namecheap parking A and CNAME records were replaced; the MX and SPF
      email-forwarding records are untouched).
- [x] robots.txt checked: Cloudflare serves our own allow-all file, so
      nothing needed changing in AI Crawl Control.
- [x] Google Search Console: URL-prefix property `https://travary.app/`,
      verified by HTML tag (in `build.py`, keep it). `sitemap.xml` submitted
      (25 URLs). Indexing requested for the home page, both tools, the
      flight-times, +1, passport and before-you-go guides, and the Orlando
      itinerary.

Still to do:

- [ ] Request indexing for the remaining pages over the next few days (about
      10 a day), or let the sitemap bring them in.
- [ ] Bing Webmaster Tools: import from Search Console (feeds ChatGPT and
      Copilot search).
- [ ] App Store Connect and Play Console: set the Marketing URL to
      `https://travary.app` (keep Support/Privacy on the GitHub Pages site,
      which both stores already reference).
- [ ] At launch: set `STORE_LIVE = True` and `IOS_APP_ID` in `build.py`,
      rebuild, redeploy. Every badge becomes a real link and the iOS Smart App
      Banner appears.
- [ ] One genuinely on-topic link from a sister site (e.g. a Tiny Psalms
      guide on bedtime routines while travelling → the family holiday
      checklist).

## 7. How to judge it

New domain, so: months 1–3 watch indexed pages, impressions and query count;
months 3–6 average position on the question pages; clicks after that. The
first pages likely to move are the weak-SERP ones: flight times, +1, the
countdown and the template.
