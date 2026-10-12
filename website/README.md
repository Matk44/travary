# travary.app

The marketing site for Travary: home page, free tools, guides and
itineraries, built from the app's own art. Static HTML, no framework, built
by one Python script. Strategy and keyword research: `STRATEGY.md`.

## Build, check, preview

```bash
python3 website/build.py        # → website/public/ (the only folder deployed)
python3 website/validate.py     # titles, metas, links, images, schema, sitemap
python3 website/serve.py        # http://localhost:8787, served like Cloudflare Pages
```

The first build encodes about 300 images (10+ minutes); they're cached in
`website/.cache/`, so later builds take under a second.

The app screens come from the app itself, rendered from the generic demo
data with real fonts:

```bash
tool/visual_qa.sh                                                  # once: collects the fonts
TRAVARY_VISUAL_QA=1 flutter test website/tool/marketing_screens_test.dart
```

That writes `build/marketing_screens/*.png`, which `build.py` picks up.

## Deploy (Cloudflare Pages)

```bash
python3 website/build.py && python3 website/validate.py && cd website && \
  CLOUDFLARE_ACCOUNT_ID=1b63e91f9618e2482f550906703a747f \
  npx --yes wrangler@latest pages deploy --branch main --commit-dirty=true
```

Run it **from `website/`**: it reads `wrangler.toml` there (the output folder
`public`, the waiting list's D1 binding) and bundles `website/functions/`. From
the repo root, wrangler would find the Firebase `functions/` folder instead. Always deploy
`public`, never the whole `website/` folder, and always pass `--branch main`
(any other branch makes a preview that never reaches the domain). The
project is a classic Pages project (created with `--force` on 2026-10-10,
like the sibling sites); don't pass `--force` again. After a deploy, check
with a cache-busting query (`?cb=1`).

## The waiting list

Until launch, every "Get the app" and coming-soon badge opens a waiting-list
card (`waitlist_dialog` in `build.py`, behaviour in `static/js/site.js`).
Without JavaScript the links go to `/early-access`, a plain form, which
redirects to `/early-access/joined`.

- **Where sign-ups go:** `POST /api/waitlist` (`functions/api/waitlist.js`, a
  Cloudflare Pages Function) writes to the private D1 database
  `travary-waitlist` (binding `DB` in `wrangler.toml`, tables in
  `schema.sql`). Nothing on the web can read it. Firestore isn't involved.
- **What's kept:** email (lowercased, one row each), phone (iphone / android
  / blank), the page they joined from, the time, and `notified_at` once
  you've emailed them. Plus a salted hash of the IP for a day, for the
  five-an-hour limit (secret `RATE_SALT` on the Pages project).
- **Spam:** a hidden honeypot field, a too-fast check, an Origin check and
  the per-visitor limit. If bots ever get through, add Cloudflare Turnstile.

```bash
python3 website/tool/waitlist.py                 # counts: total, by phone, by week, top pages
python3 website/tool/waitlist.py export          # CSV for the launch email (keep it private)
python3 website/tool/waitlist.py remove a@b.com  # someone asked to be removed
python3 website/tool/waitlist.py notified        # after the launch email has gone out
```

Or browse it in the Cloudflare dashboard: Storage & databases → D1 →
travary-waitlist. Test locally with `wrangler pages dev` from `website/`
(launch config "travary-website-functions", port 8788); it uses a local copy
of the database (`--local` on the script).

The privacy promise on the form and on `/early-access`: used only for the
launch email, never shared, deleted after it's sent or whenever someone
asks. Change the copy in `waitlist_form` if that changes, and update
`privacy.html` in the travary_support repo to match.

At launch, `STORE_LIVE = True` swaps every waiting-list button for real
store badges and drops the card and `/early-access` from the build.

## Writing a guide or itinerary

One file per page: `content/guides/<slug>.html` or
`content/itineraries/<slug>.html`. The slug is the URL. Format:

```
title: Under 60 characters
h1: The page's heading
meta: 70–160 characters
crumb: Short name for breadcrumbs
section: Planning | Flights | Documents | Apps   (guides only)
art: postcard:country_jp        # the hero and share image
travi: reading                  # a Travi still (assets/onboarding/travi/stills)
order: 3                        # position in its section
updated: 2026-10-10             # only change when the page really changes
keywords: the queries it targets (not published)
related: slug-one, slug-two, slug-three
answer: The 40–80 word direct answer, shown first (what AI answers quote).
---
<h2>Body HTML</h2>
...
---faq---
Q: A question people ask?
A: A plain answer, one or two sentences.
```

Body building blocks: `<ul class="checklist">` (tickable, remembered per
device, `<span class="when">` for a timing chip), `<ol class="steps">`,
`<div class="note"><strong>Label</strong><p>…</p></div>`,
`<div class="table-wrap"><table>…`, and itinerary days:

```html
<div class="day">
  <div class="day-head"><span class="day-num">Day<b>1</b></span><div><h3>Title</h3><p>Subtitle</p></div></div>
  <ol class="rail">
    <li class="kind-flight"><span class="time">9:00<small>am</small></span><span class="pin"></span>
      <div class="card"><strong>What</strong><p>Detail</p><span class="tip">Optional tip</span></div></li>
  </ol>
  <p class="day-foot"><b>Staying:</b> …</p>
</div>
```

Shortcodes (pipe-separated): `[[postcard|country_jp|alt]]`,
`[[countdown|city_jp_kyoto|alt]]`, `[[stage|city_fr_paris|alt]]`,
`[[screen|today_orlando|alt]]` (a phone with an app screen),
`[[travi|wave|alt]]`, `[[film|hello-idle|hello|alt]]` (still first, film
swapped in on screen), `[[icon|flight|alt]]`, `[[ephemera|boarding_pass|alt]]`,
`[[appbox|text|pose|heading]]`, `[[badges]]`, `[[price_pass]]`,
`[[price_annual]]`, `[[imports]]`.

Internal links use clean URLs: `/guides/slug`, never `.html`.

Places with art are listed in `PLACES` in `build.py` (30 postcards). Prices
and the free-import count are settings there too, mirroring
`lib/domain/pricing.dart`.

## At launch

In `build.py`: `STORE_LIVE = True`, `IOS_APP_ID = "…"`, then rebuild and
deploy. Add `GOOGLE_SITE_VERIFICATION` when Search Console gives you the tag,
and never remove it afterwards.

## Rules for the content

- Never claim a feature the release build doesn't have (no flight alerts,
  widgets or email forwarding yet).
- Facts about other apps: checked against their own listings, dated, with the
  disclosure that we make Travary.
- Passport and entry rules: cite the official source and the date checked.
- No real brand names in app screenshots (the screens use the demo data's
  generic names).
