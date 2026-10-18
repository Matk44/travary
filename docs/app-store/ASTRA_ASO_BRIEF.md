# Astra research prompt: Travary ASO and conversion

Act as a senior app-store growth researcher, ASO strategist and conversion copywriter. Conduct an evidence-led, in-depth study of Travary on both Apple's App Store and Google Play. Deliver the research, complete proposed listings, validated field values and an executable browser handover for Codex. Recommendations alone are not a complete deliverable.

## Objective and fixed decisions

- The primary target query is **“Itinerary App”**. Assess intent, competition and realistic opportunities around it, then support it with relevant secondary terms.
- The app title is **`Itinerary App - Travary`** on both stores. It is fixed: preserve its spelling, spaces and ASCII hyphen. It is 23 characters. Do not spend the study proposing a different title.
- Optimise for relevant organic discovery, store conversion and valuable activation: a traveller adding a genuine booking, using their holiday plan, sharing where appropriate, and ultimately purchasing a suitable pass. Distinguish ranking, impressions, listing visits, installs, activation and revenue.
- Assess Apple's newer dedicated search-results artwork, product-page headers and keyword-linked custom product pages in depth. Assess Google's relevant custom-listing features independently.
- Start with US, UK and Australian English audiences, reflecting the existing drafts. Verify the supported locale codes and country/language fallback behaviour for each store; do not assume the stores share locale or indexing rules. Recommend an initial market priority.
- This run is research and preparation. Write new deliverables locally; do not alter live listings, upload assets, submit reviews, publish, purchase tools or launch campaigns. Authenticated console inspection, if already available, should be read-only. Complete the study even if console access or paid keyword data is unavailable, recording the limitation precisely.

## Product truth and existing work

Repository: `/Users/khairofamily/AndroidStudioProjects/Travary`.

Read project instructions first:

- `/Users/khairofamily/AndroidStudioProjects/Travary/AGENTS.md`
- `/Users/khairofamily/AndroidStudioProjects/Travary/CLAUDE.md`

Then inspect the actual current listing and assets:

- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/APP_STORE_LISTING.md`
- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/metadata.json`
- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/mockups/app-store-screenshots-v1/SOURCE_LISTING_PLAN.md`
- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/mockups/app-store-screenshots-v1/GENERATION_LOG.md`
- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/mockups/app-store-screenshots-v1/manifest.json`
- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/mockups/app-store-screenshots-v1/final/`
- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/PROPOSED_SCREENSHOT_SELECTION.json`
- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/mockups/app-store-creative-v1/README.md`
- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/mockups/app-store-creative-v1/exports/delivery-manifest.json`
- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/COUNTDOWN_WIDGET.md`
- `/Users/khairofamily/AndroidStudioProjects/Travary/docs/LAUNCH_CHECKLIST.md`

Use current implementation and dated owner decisions to resolve conflicts. Some documents contain historical preparation notes: the original product plan includes superseded names, allowances and roadmap ideas; the source listing brief calls widgets unreleased, while current project memory records implemented widgets. An old manifest approval flag does not necessarily describe the latest final composite. Record material conflicts and their resolution; do not silently repeat stale claims. Inspect relevant code only where a claim needs verification. Preserve unrelated work and existing listing files.

Working product facts to verify:

- Travary is a bookings-first holiday organiser and day-of travel companion, rather than an itinerary generator or booking marketplace. Add bookings; trips form around their dates; Today orders the day's plans with tickets close at hand.
- Differentiators include family coordination, missing-booking gaps, offline saved bookings/tickets, destination postcards, countdowns, packing, reminders, and Travi, a coral suitcase mascot in a tactile travel-ephemera visual world.
- Smart Import reads a screenshot, photo or PDF into a draft the traveller checks. It is not an unverified promise of perfect automatic importing. Current draft allowance: 2 lifetime free Smart Imports and 2 ticket attachments per free holiday.
- Paid plans are **Holiday Pass** and **Annual Pass**. One holiday pass covers a holiday of up to 30 days; pass features extend to 7 days after it ends. Annual Pass is a yearly auto-renewing subscription. Sharing covers up to 6 people including the organiser. Verify exact entitlements and current purchase configuration; do not invent prices or trials.
- Saved bookings/tickets remain accessible when a pass ends. Personal travel documents stay on the device behind its lock; they are not shared with the holiday or sent to Smart Import. Do not invent encryption or compliance certifications.
- Current project memory records iOS and Android countdown widgets. Confirm platform implementation and remaining device/release checks before making store-specific claims.
- Verify flight lookup/alert limitations. Do not claim live gates, baggage belts, Live Activities, email forwarding, route optimisation or AI-generated holiday plans unless the current implementation substantiates them.
- The eleven completed screenshot subjects are: Today; countdown; booking gaps; Smart Import; flight-number entry; family sharing; offline tickets; personal travel documents; shared packing; destination postcards; home-screen widget.
- The current proposed Apple ten-frame selection omits flight-entry frame 05 and includes widget frame 11; this remains a proposal, not an upload decision. Frame 04's cream lower half accurately represents the loading UI. Evaluate conversion weaknesses honestly without inventing app content.
- Current Apple artwork: header v4 and search v5, with corrected 7-second/30-fps Travi loops in loop revision 2 and opaque still fallbacks. Use the current delivery manifest, not the superseded first motion pass. Final store placement preview remains necessary.

Visually inspect the final creatives; do not evaluate screenshot filenames alone. Respect the distinctive brand while being candid about legibility, message clarity, hierarchy, proof and purchase disclosure. Propose improvements separately from the existing approved direction. Artwork/keyframe approval is required before new animation; no new paid generation is authorised. Default to reusing existing work.

## Research requirements

### 1. Search intent, competitors and opportunity

Research current country-specific results for the primary query and useful adjacent queries. Record store, market, date, device/context and whether an observation is organic or paid. Audit roughly 5–8 relevant direct/adjacent competitors using their live listings, first screenshots, positioning, offers and review themes. Verify identities and current pricing rather than repeating repository comparisons.

Build a prioritised keyword map with intent, product fit, store/market, competition evidence, proposed placement and confidence. Consider itinerary/planner/organiser variants, family/shared trips, offline plans/tickets, countdowns and packing where relevant. Identify queries that imply trip generation, maps, route optimisation or booking services Travary does not provide. Do not pursue installs with a misleading promise.

Use available first-party data or owner-supplied exports where possible. The old Astro popularity/difficulty numbers are historical, unverified inputs. Never manufacture search volume, difficulty, rankings, conversion uplift or a proprietary score. Distinguish verified observations, third-party estimates and hypotheses. If quantitative data is unavailable, finish a useful qualitative recommendation and specify the smallest additional export needed to validate it.

### 2. Current platform mechanics and targeting

Verify current official documentation as of the research date. For each mechanism explain eligibility, supported devices/OS/markets, editable fields, targeting/matching rules, fallback behaviour, localisation, approval/publishing dependencies and measurement.

Explicitly distinguish:

- Apple's default listing and indexed metadata.
- Dedicated product-page header and search-results creative placements, Asset Library and supported testing options.
- Organic keyword-linked Custom Product Pages (CPPs), their URLs and optional deep links.
- Product Page Optimization versus CPPs and other supported experiments.
- Apple Ads, which is separate from organic search. Paid work is an optional, separately costed recommendation, not required execution.
- Google's main listing, search-keyword-targeted Custom Store Listings, country/audience/URL/campaign targeting and Store Listing Experiments. Do not invent an Apple-style keyword metadata field on Google Play.

Resolve a particular issue: **can “Itinerary App”, already in our fixed title, be assigned to an organic Apple CPP?** Verify the exact eligible keyword sources and restrictions, including title/subtitle terms, rather than assuming generic keyword deduplication advice answers this. Explain the supported strategy if that exact query cannot target a CPP. Do the equivalent eligibility/matching analysis for Google.

Recommend a practical first set of 1–3 intent pages per store unless evidence justifies more. For every recommended launch page supply its purpose, eligible queries/targeting configuration, complete editable copy, screenshot order, existing asset mapping, fallback and measurement plan. Put additional concepts in the later roadmap rather than producing dozens of speculative listings. Identify any deep link that needs engineering rather than inventing a working route.

### 3. Conversion and creative strategy

Audit whether an “Itinerary App” searcher understands the benefit immediately. Evaluate the title plus subtitle/short description, first-screenful, first three screenshots, icon, trust signals, free/paid clarity, and Travi's contribution to comprehension and attention.

Recommend concrete screenshot sequences and captions for each store and proposed intent page, with an explanation of the first three. Choose an Apple ten-frame set and a Google set within its verified limits; label the choice as a recommendation requiring owner review. Preserve accurate purchase disclosures. Address legacy Apple screenshot-based search presentation and newer creative placements separately.

Provide an asset matrix by store, placement, device size, locale and page. Include actual absolute file paths for reusable assets, dimensions/duration, status, exact upload order and remaining gaps. Existing iPhone captures and Apple header loops are not automatically Android screenshots, a Google feature graphic or a Google promotional video. Specify the required Android/iPad captures, formats and adaptations where missing. Evaluate a Google feature graphic and preview-video strategy under Google's current rules without assuming direct upload of an Apple MP4 is supported. Missing assets must remain clearly marked as missing.

## Required complete listings and validation

Deliver **one final recommended, complete listing per store and supported initial locale**, with optional test variants kept separately. Do not give only headline examples, partial descriptions, vague advice or a menu of unresolved choices. The fixed title remains identical across both stores. Provide an Apple subtitle and a distinct Google short description.

Audit every applicable listing field. At minimum cover:

- **Apple:** name, subtitle, keyword string, promotional text, full description, categories, available app tags and their selection rules, support/marketing/privacy/terms URLs as applicable, copyright, screenshots, app previews where appropriate, header/search placements, and every editable field for recommended CPPs. Include What's New only if applicable to the actual version status; do not invent a first-version release-notes requirement. Assess promoted in-app purchase/subscription metadata if useful and actually supported, clearly separating it from the main listing.
- **Google:** app name, short description, full description, app type/category/tags, support/contact details, website/privacy URL, icon, feature graphic, screenshots, promotional-video field and all editable fields/target settings for recommended custom listings. Distinguish track release notes from listing copy.
- Inventory any remaining administrative/declaration fields needed for setup, showing which are outside copywriting scope or require owner/product evidence. Do not fabricate legal identity, contact information, account data, privacy/Data Safety answers, accessibility claims or review credentials. These should have null values and explicit blockers in the handover, not plausible invented text.

Starting expected text limits, to reverify against official sources and actual console behaviour:

| Store | Field | Expected limit |
|---|---|---:|
| Apple | Name | 30 characters |
| Apple | Subtitle | 30 characters |
| Apple | Keywords | 100 UTF-8 bytes |
| Apple | Promotional text | 170 characters |
| Apple | Description | 4,000 characters |
| Google | App name | 30 characters |
| Google | Short description | 80 characters |
| Google | Full description | 4,000 characters |

Verify limits for any additional text fields you recommend. For **every copy field**, show exact text, measured count, applicable limit/unit, remaining capacity, locale and pass/fail. Count spaces, punctuation and line breaks. Compute counts from the actual saved strings with code; do not estimate manually or confuse characters with bytes. Explain any console-counting discrepancy. Maximum length is a ceiling, not a goal to fill with padding.

Keep citations and rationale outside the paste-ready copy. Use separate plain-text files with literal newlines for each long field. The report, text files and JSON must contain identical values. Follow each store's formatting and metadata policies; no keyword stuffing, fabricated endorsements, rankings or competitor brand names in our keyword field.

## Browser handover for Codex

Create an easy, sequential handover that lets Codex later use the owner's browser to populate the approved values without reinterpreting the research.

For each action provide:

1. Store, app identity, locale, default/custom page and reference name.
2. Console navigation path, section and exact visible field label; distinguish documented paths from paths actually observed in the current console.
3. Exact final value or absolute source-file path, its count/limit, and an action: fill, retain, select, upload, not applicable or owner input required.
4. For uploads: absolute asset path, placement, device bucket, locale, page, upload order and required final preview checks.
5. Dependencies: app/version state, platform availability, approval of assets, eligibility of keywords and existing values that must be preserved.
6. Verification: inspect the pasted/saved value and count, preserve paragraph breaks, confirm locale and page, preview the placement and capture the result. Record before/after values so an accidental overwrite can be reversed.
7. Clearly separate draft saves from actions that submit for review, publish or release. Identify buttons that may publish immediately and the later owner decision required. This research run must not perform those actions.

Do not use brittle invented element IDs or pretend an unobserved console path was tested. Unknown values must be visibly blocked and excluded from automatic filling. Put the minimal unresolved owner decisions in one short list; complete everything else.

Also provide a UTF-8 JSON handover with one record per field/action. Include: `store`, `app_id`, `locale`, `page_type`, `page_reference_name`, `console_section`, `field_label`, `action`, `value`, `source_file`, `character_count`, `utf8_byte_count`, `limit`, `limit_unit`, `asset_path`, `device_bucket`, `upload_order`, `dependencies`, `status`, `source_references`, and `navigation_verified`. Use null where a property is inapplicable or unknown. Validate JSON and counts programmatically. Its status is proposed/unapproved until the owner approves the report; do not label your own recommendation owner-approved.

## Experiments, evidence and output

Prioritise a realistic launch and 30/60/90-day learning plan. For each experiment state hypothesis, platform-supported method, control/variant, primary metric and denominator, traffic/locale, activation or revenue guardrails, required sample/baseline inputs and decision rule. Do not guarantee uplift or promise statistical significance on a calendar deadline without traffic data. Separate paid and organic results and explain how to avoid changing every variable at once.

Save new deliverables under `/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/`:

- `REPORT.md`: executive recommendation, evidence, keyword/competitor analysis, platform mechanics, full listings and complete copy/count tables, creative/page strategy and experiments.
- `BROWSER_HANDOVER.md`: the simple execution document described above.
- `listing-fields.json`: exact machine-readable proposed field values/actions.
- `copy/`: paste-ready text by store, locale and page.
- `asset-map.json`: exact asset assignments, paths, dimensions, order and missing-work status.
- `VALIDATION.md`: measured counts and consistency checks, uncertainties and minimal owner decisions.

Use primary Apple/Google sources for rules and feature mechanics; live listings and observed reviews for competitor evidence. Cite claims close to the relevant recommendation and include research dates. Explain where industry guidance is an inference rather than a documented ranking rule. Include evidence sufficient to assess each important recommendation without producing a generic ASO essay.

Official starting references for this brief, prepared on 18 October 2026; verify the relevant rules directly at research time:

- [Apple product-page marketing guidance](https://developer.apple.com/app-store/product-page/)
- [Apple version metadata](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Apple creative assets and placement management](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets)
- [Apple creative specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications)
- [Apple CPP configuration and keyword assignment](https://developer.apple.com/help/app-store-connect/create-custom-product-pages/configure-multiple-product-page-versions)
- [Google listing setup and text limits](https://support.google.com/googleplay/android-developer/answer/9859152)
- [Google custom listings and search-keyword targeting](https://support.google.com/googleplay/android-developer/answer/9867158)

Finish with a clear recommended launch configuration and links to every deliverable. The result should let the owner approve concrete listings and then let Codex populate the right fields with very little additional research. If local project access is unavailable, use the product facts in this brief and available attachments, label unverified implementation/asset details, and request only the specific missing inputs needed for a final executable handover.
