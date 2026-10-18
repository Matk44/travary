# Travary browser handover

Prepared18October2026. **Proposed/unapproved. Research only; no live changes made.** This document prepares a later approved population session. It does not authorize saves, uploads, submissions, publication or release in this research run.

## 1. Load the approved local package and confirm identity

Read REPORT.md and VALIDATION.md, then use listing-fields.json as the source of truth. Do not retype long copy from the narrative. Each string has an absolute UTF-8 text-file path; read its entire contents, including literal paragraph breaks and excluding any additional trailing newline. Asset paths and dimensions are in asset-map.json.

Apple: Apps > **Itinerary App - Travary**, Apple ID **6818495253**, bundle/SKU **com.travary.app**. Google: Dream Prayer Developer > **Itinerary App - Travary**, package **com.travary.app**, console app ID **4974523505827658180**. Abort the population action if identity differs. Preserve the exact23character title with ASCII hyphen in every locale and custom page.

Before every group: capture the current page, locale, status and exact values into a local execution ledger. Use execution-log.template.json as a schema example. Keep review passwords out of this study directory and screenshots. Preserve unrelated fields/assets. Empty current values below describe18October only; re-read them during execution. Never clear a newer value just because this proposal says it was blank.

The action appendix is exhaustive: each record gives store/locale/page/section, action, exact text or file, count/cap, upload bucket/order, dependencies and verification flag. `navigation_verified=true` means the field/section was actually observed, not that a save or upload was tested. False means documentation or proposed workflow only. Unknown values remain null and must be excluded from automated filling.

## 2. Apple app-level draft fields

Observed route: [App Information](https://appstoreconnect.apple.com/apps/6818495253/distribution/info).

1. Record current primary language, name, subtitle and categories. Primary English(U.S.) was observed. Name is already correct; retain it. For each English(U.S.)/English(U.K.)/English(Australia) localization, enter that locale's Subtitle file. Other locale forms were not opened in this run: verify available language creation/control labels rather than using invented selectors.
2. Select primary categoryTravel. Leave optional secondary unset unless a later approved decision changes it. No arbitrary Apple tags: only inspect/manage actual offered tags once present. Currently no tags were observed; this action remains blocked.
3. Retain Standard Apple License Agreement. Copyright remains blocked until actual rights holder/year are supplied. Privacy URL has an exact proposed value but privacy declarations remain owner/product evidence, not automatically inferred copy.
4. Only in a later approved session, use **Save** for draft fields, re-read values, locale and counters, and log before/after. Do not click Add for Review or Submit to App Review as part of draft population.

## 3. Apple version copy and screenshot assets

Observed route: Distribution > iOS App > **1.0 Prepare for Submission**: [version](https://appstoreconnect.apple.com/apps/6818495253/distribution/ios/version/inflight).

1. Confirm actual release version/build. On18October, build4/version1.0.0 was selected. Do not swap builds or change version merely to match this document.
2. In **Product Page Information**, choose each locale explicitly. Fill Promotional Text, Description, Keywords, Support URL and Marketing URL from the matching default files. Description is plain text: retain blank lines, no Markdown or citations. Keywords are comma-separated ASCII; verify bytes as well as UI counter. First version has no What's New field; do not paste invented release notes.
3. Open **App Previews and Screenshots**. The observed default bucket is **iPhone with Dynamic Island (medium display)**. Upload the ten1206×2622 files in asset-map upload order01–10, which intentionally differs from filename numbers. The first three must be subjects01,07,03. Do not sort filenames automatically.
4. **View All Sizes in Media Manager** was observed; its contents were not opened. There select the documented Dynamic Island large bucket and upload the corresponding1320×2868 set in the same order. Reconfirm bucket names and accepted dimensions before the first upload. Do not place large files into the medium bucket.
5. iPad13-inch tab was observed. Required iPad captures are missing; stop only this upload group. Capture actual supported iPad release UI at2064×2752 or2048×2732, obtain asset approval, update map/hashes and rerun validation. Do not stretch iPhone imagery or silently change app device families. iPhone Duo is currently future conditional SDK work; no nonexistent artwork is supplied. Apple Watch bucket visibility is not proof the app has a Watch build; no Watch upload proposed.
6. Launch has no App Previews. Seven-second brand loops are Header/Search assets, not app previews.
7. For each uploaded bucket, inspect Preview at native/small presentation: time/order/UI fidelity, labels, free/paid qualifiers, six-person count, crop/safe areas, status bars, screenshots not exposing personal data. Capture the completed placement and log ordered asset names/hashes. Save draft only after locale/order is confirmed.

## 4. Apple Header and Search Results

Observed on the version page: **Header and Search Results** tab > **Header**, **Search Results**, **Preview**, **Browse Assets**, **Upload**. Header showed0of1 and valid wide dimensions. Search tab content was not opened. Asset Library sidebar exists; nested workflow is documented, not browser-tested here.

1. After approval, use the existing opaque header v4 and search v5 still files, one per placement/locale as mapped. Approved underlying art does not approve every new crop/assignment. Confirm English art reuse for US/UK/AU; no separate US graphic exists.
2. If an approved compatible asset already exists in Asset Library, prefer Browse Assets and retain its approved identity. Otherwise upload to the intended draft placement or Asset Library according to current UI. Keep library review separate from version review. Do not duplicate into the same single slot.
3. Preview phone/tablet, orientations and language presentation. Check header central safe area and search promise/Today phone legibility. Record fallback presentation on earlier OS where possible. Reordering screenshots still matters for legacy search.
4. Revision2 loops are held; source art/scene reuse is approved, final playback is not. Only substitute after owner playback approval and final native placement preview. No new animation authorized.
5. **Publish**, **Publish Changes**, or a confirmation that applies already-approved assets may change a live page immediately. Read the current confirmation and stop for the later publication decision. Library **Add for Review/Submit to App Review** is also outside draft population. Do not assume an asset's prior approval permits silent live assignment.

## 5. Apple purchase metadata and administrative blockers

Observed Annual product: [Travary Annual Pass](https://appstoreconnect.apple.com/apps/6818495253/distribution/subscriptions/6818993167), product travary_annual_pass, yearly, Prepare for Submission. EnglishUS display name and description currently Travary Annual Holiday Pass. Proposed purchase-localization copy is supplied separately under product folders, using conservative30/45character IAP limits; inspect subscription form counters before its later save. Holiday product console details were not inspected; identify existing holiday_pass and never create a duplicate. Preserve review screenshot, product IDs, prices, availability, Family Sharing, multiseat and purchase options.

No promoted purchase image or store promotion is proposed. First subscription must be reviewed with a new app version; confirm both first purchase products are appropriately attached. RevenueCat entitlement and purchase-from-store behavior require release tests.

Administrative null records identify copyright, ratings/rights, privacy/accessibility/compliance questionnaires, reviewer contact/access, release build, pricing/account setup and purchase declarations. Do not fill with plausible guesses. **Sign-in required** is currently checked with blank credentials. Test the guest review flow on the selected build before deciding whether to uncheck; otherwise owner supplies dedicated review credentials privately and verified instructions.

**Automatically release this version is currently selected.** A later approved setup should choose Manually release this version if the owner adopts the recommended launch control. Merely submitting the current automatic configuration can release after approval. Draft preparation ends before Add for Review/Submit to App Review; final release is a distinct owner decision.

## 6. Apple family CPP at first eligible stage

Observed list: [Custom Product Pages](https://appstoreconnect.apple.com/apps/6818495253/distribution/productpages).0of70. Create dialog/reference name100 observed and cancelled; no page exists. Official creation eligibility requires distributed app; the prelaunch button alone does not prove full eligibility.

1. Once eligible and approved for population, Create Custom Product Page > reference name **Family & packing** > copy existing default page. Confirm source version. Record the generated Product Page URL; never invent ppId.
2. Add each locale. Use its exact CPP Promotional Text file and reorder screenshots **06,09,01,07,03,04,02,11,08,10** in both available iPhone buckets and actual iPad bucket once supplied. Name/subtitle/description are inherited from locale default; there are no separate CPP fields to fill. Retain same approved header/search stills initially, with current availability checked. No deep link or preview is proposed.
3. In **Keywords**, inspect latest approved locale's eligible selector. Proposed candidate entries are family, packing, shared; select only offered relevant entries and capture exact variants/combinations. All are present in the prepared default keyword strings. Do not type an invented query or assume title/subtitle terms are eligible. Exact Itinerary App routing remains on default unless source eligibility is directly verified. Unsupported candidates block only routing; retain the page proposal.
4. Save draft/reviewable content separately from **Add for Review**, **Submit to App Review** and keyword **Publish**. CPP approval/visible state required for organic search. Approved-page edits can publish automatically on approval. Record this behavior in the approval request.
5. After separately authorized publication, verify URL/country/language/OS, unmatched default fallback and selected-query behavior. Five first-time downloads unlock analytics, not statistical confidence. Capture default and family comparison without claiming randomized uplift.

## 7. Google main listing and store settings

Observed app dashboard: [Travary dashboard](https://play.google.com/console/u/0/developers/6149577155193334943/app/4974523505827658180/app-dashboard).

Observed path: **Grow users > Store presence > Store listings**. [Store listings](https://play.google.com/console/u/0/developers/6149577155193334943/app/4974523505827658180/store-listings) currently offers **Create default store listing**; no listing exists. The button was not pressed. Below field labels are documented; verify them on the newly opened approved form.

1. After approval, Create default store listing. Choose English(UnitedStates), en-US as default. Enter fixed App name, exact Short description and complete Full description from files. Add en-GB and en-AU translations explicitly using available controls. Do not confuse app creation name, console temporary internal-test name, locale and country.
2. Upload existing512×512 icon. Actual Android phone screenshots and1024×500feature graphic are missing. Capture/create approved static assets according to asset-map requirements, update exact paths/hashes and validate before upload. First three phone screenshots01,07,03; full eight01,07,03,06,04,09,02,11. Use final matching screenshot/feature alt text≤140characters. Preview clipping, real Android UI and paid labels. No iOS UI/FaceID label or AppleMP4 upload.
3. Leave Video empty; future field takes YouTubeURL. Optional tablet assets remain missing and require actual large-screen UI. Do not claim optimized tablet support merely by uploading phone crops.
4. Observed **Grow users > Store presence > Store settings**: App or gameApp; CategoryNotselected; contact fields blank. Set categoryTravel&Local and exact tagTravel&local through Manage tags. One relevant tag is recommended; avoid navigation/booking-service alternatives. Set Email address and Website from shared exact files; optional Phone number stays blank. Preserve checked external marketing setting.
5. Documented **Policy and programs > App content** privacy/deletion fields use supplied URLs after audit. Nested navigation was not tested; follow current visible UI from dashboard tasks if menu labels differ. All declarations stay blocked until actual product/owner evidence.
6. Save approved drafts and inspect Publishing overview to see the actual staged changes. **Send for review**, **Publish changes**, **Start rollout**, managed-publishing controls and release creation are separate decisions. Do not assume Save equals public or private without current status/confirmation.

Google is Draft, production inactive,0closed testers. Finish setup, then approved closed test with at least12opted-in testers continuously14days and production-access application. No publication date is guaranteed. Internal-test temporary name is expected pre-review, not evidence the fixed listing name should change.

## 8. Google family CSL after main publication

Documented path: Grow users > Store presence > Store listings > create custom store listing. Custom form/keyword controls were not observed because main listing is absent. Current Google rules and specific labels must be checked at that stage.

1. Create internal **Family trip planner** page after eligibility. Default en-US plus en-GB/en-AU translations. Retain fixed App name and icon; use exact distinct family Short/Full description files. Shared contacts/privacy/category remain main settings.
2. Choose **Search keywords** targeting; inspect family trip planner and shared trip planner availability, then **View variations**. Capture selected spellings/translations and exclude route-generator/map/booking-service mismatch. No Apple-style keyword metadata field exists. Do not assume matching is exact just because the seed phrase is exact.
3. No country, audience, ad campaign or URL target is proposed. If eligible matching terms are unavailable, keep proposal locally; do not silently convert it into a country-targeted replacement. Itinerary App remains main at launch; app-name occurrence neither proves nor excludes Google selector eligibility.
4. Complete family screenshot order06,09,01,07,03,04,02,11, missing family feature graphic and alt text. No video. Preview explicit locales; CSL does not autotranslate. Record generated page/reference details from UI and unmatched fallback.
5. Save draft separate from review/publication. Only after separate approval publish and verify targeting and listing analytics. These cohorts are not randomized experiments.

## 9. Verify, log and stop at the approved boundary

For every filled record: read saved value back, compare Unicode text/UTF-8 bytes to source, count line breaks, verify locale/page/title and remaining capacity, and capture a screenshot without secrets. For selections: record exact current options and choices. For uploads: record absolute path/hash, native bucket, order, final preview and current state. If current console limit differs, stop that field, record discrepancy and update the proposal; do not truncate automatically.

Store the before/after ledger locally. If a mistaken draft overwrite occurs, restore the exact before value and confirm; don't restore an old live version through a publishing action without separate authorization. Existing values/assets outside the approved record set must be retained.

The appendix below contains one row per machine record. Null values with owner-input/missing status are blocked. Records for test_variant are optional later experiment material and excluded from default population. The final draft completion report must identify filled/saved, retained, missing and blocked rows separately and link screenshots. Only then present a concrete publication/review request if that later task authorizes seeking one.
