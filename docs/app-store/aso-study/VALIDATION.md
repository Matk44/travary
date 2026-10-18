# Validation and unresolved dependencies

Prepared18October2026. Proposed/unapproved. **PASS** for local consistency; this does not certify store approval or release behavior.

## Reproducible checks

Run `python3 docs/app-store/aso-study/build_deliverables.py` then `python3 docs/app-store/aso-study/validate_deliverables.py` from the project root. The scripts write only this study directory and do not call live services. `report-research.md` and `handover-intro.md` are source documents; generated REPORT/BROWSER files should not be hand-edited.

| Check | Result |
|---|---:|
| limited copy fields | 104 |
| exact text files | 130 |
| fixed titles | 9 |
| apple keyword strings | 3 |
| explicit null rows | 229 |
| unique assets checked | 28 |
| field records | 504 |
| asset assignments and inventory | 335 |
| complete default listings | 6 |
| google complete family listings | 3 |
| apple family promotional localizations | 3 |

Counts use Python `len(saved_string)` for Unicode code points and `len(saved_string.encode("utf-8"))` for bytes, including spaces/punctuation/LF line breaks. No BOM, CRLF or trailing newline is inserted. All listing copy and ASCII keyword fields avoid grapheme/UTF-16 ambiguity. Some language-selection strings contain an en dash; byte and character counts correctly differ. They are selectors, not pasted description text.

Apple Keywords UI says Characters remaining while technical documentation says100UTF-8bytes. Proposed ASCII strings make those counts identical. No padding to maximum. Unknown URL/selection/internal-name caps are recorded null and counted, without claiming a verified pass against an invented limit. Product names/descriptions use conservative30/45IAP limits; subscription form counter remains a check.

Descriptions are plain UTF-8; report code blocks, JSON values and files were compared exactly. Full six default listings present. Google family full descriptions and Apple family promotional text supplied for all3locales; Apple CPP inherits default name/subtitle/description. Counts for every proposed text field are below and in REPORT. No app tests were run: app source was not changed.

## Limits and minimal owner decisions

1. Approve the proposed copy, default/family orders and still creative assignments. Existing still approval is preserved; this recommendation is not self-approved. Loops await playback approval.
2. Supply actual copyright holder/year and review contact/access, and confirm privacy/rating/rights/account/commercial declarations from release evidence. No secrets or guessed legal values are populated.
3. Complete and approve real Android/iPad captures plus Google feature graphics. The current universal iOS target makes iPad a blocker. Optional Google tablet promotion work is distinct.
4. Confirm release candidate, physical-device feature tests and intended manual/managed publication. Apple currently automatically releases on approval; Google requires closed test/production access.

These decisions do not authorize live changes in this run. Detailed null rows in listing-fields identify each dependent action.

## Evidence limitations

- Native store query ranks, volumes, difficulty and a first-party conversion baseline are unavailable. Apple API/Google desktop observations are clearly labeled proxies, not paid/organic rank measurements.
- Apple official instructions establish latest-approved-version Keywords as the CPP source; they do not expressly enumerate title/subtitle exclusion. The real selector is unavailable preapproval. Exact title-query routing is therefore unverified and blocked; supported recommendation keeps it on default. No deduplication rule is passed off as proof.
- Google custom keyword bundles and exact matching variations cannot be inspected until the main listing exists/published and controls are available. Candidate targeting is a proposal requiring selector verification.
- Public pricing catalogs can include multiple offers and old entries. No competitor paywall or Travary price/trial is invented. Annual AU59.99/year was observed; other product/region prices not fully audited.
- Real-device widget, offline saved-file, pass-sharing, purchase and flight checks remain release gates. Daily import limit25 is in local server code; deployed parity must be checked.
- Store declarations are not certified by public policy-page reachability. Analytics retention/integration/attribution and genuine-booking event coverage need checks. No deterministic page-to-revenue attribution is established.
- Counter/preview/publishing verification was not simulated through a live save. The handover distinguishes observed and documented paths; no live modification occurred.

## Every text-field count

Exact value appears at its record in REPORT and in linked source. RemainingN/A means no verified cap or a non-text selector; not a failed required field.

| Record | Characters | UTF-8 bytes | Limit / unit | Remaining | Result |
|---|---:|---:|---|---:|---|
| [apple-en-US-default-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/name.txt) | 23 | 23 | 30 characters | 7 | PASS |
| [apple-en-US-default-subtitle](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/subtitle.txt) | 30 | 30 | 30 characters | 0 | PASS |
| [apple-en-US-default-keywords](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/keywords.txt) | 87 | 87 | 100 UTF-8 bytes | 13 | PASS |
| [apple-en-US-default-promotional-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/promotional-text.txt) | 152 | 152 | 170 characters | 18 | PASS |
| [apple-en-US-default-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/description.txt) | 2524 | 2524 | 4000 characters | 1476 | PASS |
| [apple-en-US-default-support-url](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/support-url.txt) | 27 | 27 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [apple-en-US-default-marketing-url](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/default/marketing-url.txt) | 20 | 20 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [apple-en-US-family-promotional-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/family/promotional-text.txt) | 158 | 158 | 170 characters | 12 | PASS |
| [google-en-US-default-app-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/app-name.txt) | 23 | 23 | 30 characters | 7 | PASS |
| [google-en-US-default-short-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/short-description.txt) | 72 | 72 | 80 characters | 8 | PASS |
| [google-en-US-default-full-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/full-description.txt) | 2471 | 2471 | 4000 characters | 1529 | PASS |
| [google-en-US-family-app-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/app-name.txt) | 23 | 23 | 30 characters | 7 | PASS |
| [google-en-US-family-short-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/short-description.txt) | 79 | 79 | 80 characters | 1 | PASS |
| [google-en-US-family-full-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/full-description.txt) | 2504 | 2504 | 4000 characters | 1496 | PASS |
| [apple-en-US-holiday_pass-display-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/holiday_pass/display-name.txt) | 12 | 12 | 30 characters | 18 | PASS |
| [apple-en-US-holiday_pass-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/holiday_pass/description.txt) | 43 | 43 | 45 characters | 2 | PASS |
| [apple-en-US-travary_annual_pass-display-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/travary_annual_pass/display-name.txt) | 11 | 11 | 30 characters | 19 | PASS |
| [apple-en-US-travary_annual_pass-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-US/travary_annual_pass/description.txt) | 41 | 41 | 45 characters | 4 | PASS |
| [apple-en-GB-default-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/name.txt) | 23 | 23 | 30 characters | 7 | PASS |
| [apple-en-GB-default-subtitle](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/subtitle.txt) | 30 | 30 | 30 characters | 0 | PASS |
| [apple-en-GB-default-keywords](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/keywords.txt) | 86 | 86 | 100 UTF-8 bytes | 14 | PASS |
| [apple-en-GB-default-promotional-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/promotional-text.txt) | 152 | 152 | 170 characters | 18 | PASS |
| [apple-en-GB-default-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/description.txt) | 2522 | 2522 | 4000 characters | 1478 | PASS |
| [apple-en-GB-default-support-url](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/support-url.txt) | 27 | 27 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [apple-en-GB-default-marketing-url](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/default/marketing-url.txt) | 20 | 20 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [apple-en-GB-family-promotional-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/family/promotional-text.txt) | 158 | 158 | 170 characters | 12 | PASS |
| [google-en-GB-default-app-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/app-name.txt) | 23 | 23 | 30 characters | 7 | PASS |
| [google-en-GB-default-short-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/short-description.txt) | 72 | 72 | 80 characters | 8 | PASS |
| [google-en-GB-default-full-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/full-description.txt) | 2469 | 2469 | 4000 characters | 1531 | PASS |
| [google-en-GB-family-app-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/app-name.txt) | 23 | 23 | 30 characters | 7 | PASS |
| [google-en-GB-family-short-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/short-description.txt) | 79 | 79 | 80 characters | 1 | PASS |
| [google-en-GB-family-full-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/full-description.txt) | 2502 | 2502 | 4000 characters | 1498 | PASS |
| [apple-en-GB-holiday_pass-display-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/holiday_pass/display-name.txt) | 12 | 12 | 30 characters | 18 | PASS |
| [apple-en-GB-holiday_pass-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/holiday_pass/description.txt) | 43 | 43 | 45 characters | 2 | PASS |
| [apple-en-GB-travary_annual_pass-display-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/travary_annual_pass/display-name.txt) | 11 | 11 | 30 characters | 19 | PASS |
| [apple-en-GB-travary_annual_pass-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-GB/travary_annual_pass/description.txt) | 41 | 41 | 45 characters | 4 | PASS |
| [apple-en-AU-default-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/name.txt) | 23 | 23 | 30 characters | 7 | PASS |
| [apple-en-AU-default-subtitle](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/subtitle.txt) | 30 | 30 | 30 characters | 0 | PASS |
| [apple-en-AU-default-keywords](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/keywords.txt) | 86 | 86 | 100 UTF-8 bytes | 14 | PASS |
| [apple-en-AU-default-promotional-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/promotional-text.txt) | 152 | 152 | 170 characters | 18 | PASS |
| [apple-en-AU-default-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/description.txt) | 2522 | 2522 | 4000 characters | 1478 | PASS |
| [apple-en-AU-default-support-url](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/support-url.txt) | 27 | 27 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [apple-en-AU-default-marketing-url](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/default/marketing-url.txt) | 20 | 20 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [apple-en-AU-family-promotional-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/family/promotional-text.txt) | 158 | 158 | 170 characters | 12 | PASS |
| [google-en-AU-default-app-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/app-name.txt) | 23 | 23 | 30 characters | 7 | PASS |
| [google-en-AU-default-short-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/short-description.txt) | 72 | 72 | 80 characters | 8 | PASS |
| [google-en-AU-default-full-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/full-description.txt) | 2469 | 2469 | 4000 characters | 1531 | PASS |
| [google-en-AU-family-app-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/app-name.txt) | 23 | 23 | 30 characters | 7 | PASS |
| [google-en-AU-family-short-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/short-description.txt) | 79 | 79 | 80 characters | 1 | PASS |
| [google-en-AU-family-full-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/full-description.txt) | 2502 | 2502 | 4000 characters | 1498 | PASS |
| [apple-en-AU-holiday_pass-display-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/holiday_pass/display-name.txt) | 12 | 12 | 30 characters | 18 | PASS |
| [apple-en-AU-holiday_pass-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/holiday_pass/description.txt) | 43 | 43 | 45 characters | 2 | PASS |
| [apple-en-AU-travary_annual_pass-display-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/travary_annual_pass/display-name.txt) | 11 | 11 | 30 characters | 19 | PASS |
| [apple-en-AU-travary_annual_pass-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/en-AU/travary_annual_pass/description.txt) | 41 | 41 | 45 characters | 4 | PASS |
| [apple-all-family-reference-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/shared/family/reference-name.txt) | 16 | 16 | 100 characters | 84 | PASS |
| [google-all-default-default-language](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/default-language.txt) | 31 | 33 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-family-listing-name](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/family/listing-name.txt) | 19 | 19 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-family-targeting](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/family/targeting.txt) | 15 | 15 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-family-default-language](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/family/default-language.txt) | 31 | 33 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [apple-all-default-primary-category](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/shared/default/primary-category.txt) | 6 | 6 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [apple-all-default-license-agreement](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/shared/default/license-agreement.txt) | 32 | 32 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [apple-all-default-privacy-policy-url](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/shared/default/privacy-policy-url.txt) | 27 | 27 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [apple-all-default-terms-url-description-link](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/apple/shared/default/terms-url-description-link.txt) | 25 | 25 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-default-category](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/category.txt) | 14 | 14 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-default-app-or-game](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/app-or-game.txt) | 3 | 3 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-default-email-address](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/email-address.txt) | 25 | 25 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-default-website](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/website.txt) | 20 | 20 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-default-privacy-policy](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/privacy-policy.txt) | 27 | 27 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-default-account-deletion-web-link](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/default/account-deletion-web-link.txt) | 34 | 34 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-en-US-default-screenshot-alt-text-android-phone-1080x1920-01](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-01.txt) | 45 | 45 | 140 characters | 95 | PASS |
| [google-en-US-default-screenshot-alt-text-android-phone-1080x1920-02](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-02.txt) | 67 | 67 | 140 characters | 73 | PASS |
| [google-en-US-default-screenshot-alt-text-android-phone-1080x1920-03](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-03.txt) | 56 | 56 | 140 characters | 84 | PASS |
| [google-en-US-default-screenshot-alt-text-android-phone-1080x1920-04](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-04.txt) | 73 | 73 | 140 characters | 67 | PASS |
| [google-en-US-default-screenshot-alt-text-android-phone-1080x1920-05](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-05.txt) | 87 | 87 | 140 characters | 53 | PASS |
| [google-en-US-default-screenshot-alt-text-android-phone-1080x1920-06](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-06.txt) | 68 | 68 | 140 characters | 72 | PASS |
| [google-en-US-default-screenshot-alt-text-android-phone-1080x1920-07](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-07.txt) | 54 | 54 | 140 characters | 86 | PASS |
| [google-en-US-default-screenshot-alt-text-android-phone-1080x1920-08](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/screenshot-alt-text-android-phone-1080x1920-08.txt) | 49 | 49 | 140 characters | 91 | PASS |
| [google-en-US-default-feature-graphic-alt-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/default/feature-graphic-alt-text.txt) | 38 | 38 | 140 characters | 102 | PASS |
| [google-en-US-family-screenshot-alt-text-android-phone-1080x1920-01](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-01.txt) | 73 | 73 | 140 characters | 67 | PASS |
| [google-en-US-family-screenshot-alt-text-android-phone-1080x1920-02](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-02.txt) | 68 | 68 | 140 characters | 72 | PASS |
| [google-en-US-family-screenshot-alt-text-android-phone-1080x1920-03](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-03.txt) | 45 | 45 | 140 characters | 95 | PASS |
| [google-en-US-family-screenshot-alt-text-android-phone-1080x1920-04](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-04.txt) | 67 | 67 | 140 characters | 73 | PASS |
| [google-en-US-family-screenshot-alt-text-android-phone-1080x1920-05](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-05.txt) | 56 | 56 | 140 characters | 84 | PASS |
| [google-en-US-family-screenshot-alt-text-android-phone-1080x1920-06](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-06.txt) | 87 | 87 | 140 characters | 53 | PASS |
| [google-en-US-family-screenshot-alt-text-android-phone-1080x1920-07](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-07.txt) | 54 | 54 | 140 characters | 86 | PASS |
| [google-en-US-family-screenshot-alt-text-android-phone-1080x1920-08](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/screenshot-alt-text-android-phone-1080x1920-08.txt) | 49 | 49 | 140 characters | 91 | PASS |
| [google-en-US-family-feature-graphic-alt-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-US/family/feature-graphic-alt-text.txt) | 49 | 49 | 140 characters | 91 | PASS |
| [google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-01](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-01.txt) | 45 | 45 | 140 characters | 95 | PASS |
| [google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-02](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-02.txt) | 67 | 67 | 140 characters | 73 | PASS |
| [google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-03](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-03.txt) | 56 | 56 | 140 characters | 84 | PASS |
| [google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-04](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-04.txt) | 73 | 73 | 140 characters | 67 | PASS |
| [google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-05](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-05.txt) | 87 | 87 | 140 characters | 53 | PASS |
| [google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-06](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-06.txt) | 68 | 68 | 140 characters | 72 | PASS |
| [google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-07](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-07.txt) | 54 | 54 | 140 characters | 86 | PASS |
| [google-en-GB-default-screenshot-alt-text-android-phone-1080x1920-08](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/screenshot-alt-text-android-phone-1080x1920-08.txt) | 49 | 49 | 140 characters | 91 | PASS |
| [google-en-GB-default-feature-graphic-alt-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/default/feature-graphic-alt-text.txt) | 38 | 38 | 140 characters | 102 | PASS |
| [google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-01](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-01.txt) | 73 | 73 | 140 characters | 67 | PASS |
| [google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-02](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-02.txt) | 68 | 68 | 140 characters | 72 | PASS |
| [google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-03](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-03.txt) | 45 | 45 | 140 characters | 95 | PASS |
| [google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-04](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-04.txt) | 67 | 67 | 140 characters | 73 | PASS |
| [google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-05](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-05.txt) | 56 | 56 | 140 characters | 84 | PASS |
| [google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-06](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-06.txt) | 87 | 87 | 140 characters | 53 | PASS |
| [google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-07](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-07.txt) | 54 | 54 | 140 characters | 86 | PASS |
| [google-en-GB-family-screenshot-alt-text-android-phone-1080x1920-08](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/screenshot-alt-text-android-phone-1080x1920-08.txt) | 49 | 49 | 140 characters | 91 | PASS |
| [google-en-GB-family-feature-graphic-alt-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/family/feature-graphic-alt-text.txt) | 49 | 49 | 140 characters | 91 | PASS |
| [google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-01](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-01.txt) | 45 | 45 | 140 characters | 95 | PASS |
| [google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-02](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-02.txt) | 67 | 67 | 140 characters | 73 | PASS |
| [google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-03](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-03.txt) | 56 | 56 | 140 characters | 84 | PASS |
| [google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-04](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-04.txt) | 73 | 73 | 140 characters | 67 | PASS |
| [google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-05](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-05.txt) | 87 | 87 | 140 characters | 53 | PASS |
| [google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-06](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-06.txt) | 68 | 68 | 140 characters | 72 | PASS |
| [google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-07](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-07.txt) | 54 | 54 | 140 characters | 86 | PASS |
| [google-en-AU-default-screenshot-alt-text-android-phone-1080x1920-08](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/screenshot-alt-text-android-phone-1080x1920-08.txt) | 49 | 49 | 140 characters | 91 | PASS |
| [google-en-AU-default-feature-graphic-alt-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/default/feature-graphic-alt-text.txt) | 38 | 38 | 140 characters | 102 | PASS |
| [google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-01](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-01.txt) | 73 | 73 | 140 characters | 67 | PASS |
| [google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-02](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-02.txt) | 68 | 68 | 140 characters | 72 | PASS |
| [google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-03](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-03.txt) | 45 | 45 | 140 characters | 95 | PASS |
| [google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-04](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-04.txt) | 67 | 67 | 140 characters | 73 | PASS |
| [google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-05](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-05.txt) | 56 | 56 | 140 characters | 84 | PASS |
| [google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-06](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-06.txt) | 87 | 87 | 140 characters | 53 | PASS |
| [google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-07](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-07.txt) | 54 | 54 | 140 characters | 86 | PASS |
| [google-en-AU-family-screenshot-alt-text-android-phone-1080x1920-08](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/screenshot-alt-text-android-phone-1080x1920-08.txt) | 49 | 49 | 140 characters | 91 | PASS |
| [google-en-AU-family-feature-graphic-alt-text](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-AU/family/feature-graphic-alt-text.txt) | 49 | 49 | 140 characters | 91 | PASS |
| [google-all-creative_test-default-first-headline](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/default-first-headline.txt) | 24 | 24 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-creative_test-offline-headline](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/offline-headline.txt) | 32 | 32 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-creative_test-gaps-headline](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/gaps-headline.txt) | 22 | 22 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-creative_test-family-headline](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/family-headline.txt) | 27 | 27 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-creative_test-import-headline](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/import-headline.txt) | 34 | 34 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-all-creative_test-family-feature-graphic-headline](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/shared/creative_test/family-feature-graphic-headline.txt) | 16 | 16 | Unverified/N/A | N/A | COUNTED; no verified text cap |
| [google-en-GB-test_variant-short-description](/Users/khairofamily/AndroidStudioProjects/Travary/docs/app-store/aso-study/copy/google/en-GB/test_variant/short-description.txt) | 76 | 76 | 80 characters | 4 | PASS |
