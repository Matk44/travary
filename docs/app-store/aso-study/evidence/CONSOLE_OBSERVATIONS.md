# Read-only console observations — 18 October 2026

Observed in the owner's already authenticated Chrome profiles. No values entered, assets uploaded, records created, draft saves, reviews submitted or listings published. Creation dialogs were cancelled. This is a sanitized observation log, not an export of secrets or unrelated apps' metrics.

## Apple

App: **Itinerary App - Travary**. Apple ID **6818495253**, bundle ID and SKU **com.travary.app**. Primary language English (U.S.).

| Observed location | State / exact labels |
|---|---|
| Apps > Travary > Distribution > App Information (`/apps/6818495253/distribution/info`) | Name already fixed; 7 characters remaining. Subtitle blank, 30 remaining. Primary and secondary categories unset. Standard Apple License Agreement selected. Content rights / age rating incomplete. No App Tags section assigned to this app observed. |
| Distribution > iOS App > 1.0 Prepare for Submission (`/distribution/ios/version/inflight`) | Build 4, version 1.0.0 selected. English (U.S.). Promotional Text blank/170, Description blank/4,000, Keywords blank/100, Support URL blank, Marketing URL blank, Copyright blank/200. No What's New field for this first version. |
| Version > Header and Search Results > Header | 0 of 1 Header Asset; Preview, Browse Assets, Upload. Sizes displayed 5244×2950 and3840×1646. Search Results tab present; its content not separately inspected. |
| Version > App Previews and Screenshots | Required default tab exact label **iPhone with Dynamic Island (medium display)**; 0 of3 App Previews and0 of10 App Screenshots. Accepted portrait1179×2556 or1206×2622. Other tabs: iPhone Duo; iPad13-inch; Apple Watch. **View All Sizes in Media Manager** link observed. Large bucket supported by documentation; Media Manager not opened. |
| Version > App Review Information | Sign-in required checked, User name and Password blank; First name, Last name, Phone number, Email blank; Notes4,000; Attachment optional. Guest access needs release-build verification before changing sign-in requirement. |
| Version > App Store Version Release | **Automatically release this version** selected. Manual release is available. No setting changed. Submission could therefore lead to automatic release after approval. |
| Distribution > Custom Product Pages (`/distribution/productpages`) | 0 of70; Create Custom Product Page. Creation dialog reference-name limit100, choose blank or existing page. Dialog cancelled; no CPP created. Keyword selector unavailable for this unapproved app, so title/subtitle exclusion could not be directly tested. |
| Distribution > Asset Library; Product Page Optimization | Sidebar links observed, contents not inspected. |
| Subscriptions > Travary Subscriptions (`/distribution/subscription-groups/22439167`) | One Annual product. Group display localization not configured. Streamlined Purchasing on. |
| Travary Annual Pass (`/distribution/subscriptions/6818993167`) | Reference name Travary Annual Pass; product ID travary_annual_pass; duration1year; Prepare for Submission. English(U.S.) Display Name and Description both currently **Travary Annual Holiday Pass**. Optional image absent. Review screenshot already exists; preserve. Apple Family Sharing off (Turn On offered). Multiseat allowed and purchase from App Store, Apple Business, Apple School Manager; preserve pending owner decision. |
| Annual > Current Pricing for New Subscribers | Australia AUD59.99 observed. Current list reports175countries, no introductory offers or upcoming changes. Other target-country and Holiday Pass prices not audited; no hardcoded prices recommended. |

## Google

Developer: Dream Prayer Developer; personal account. App **Itinerary App - Travary**, package **com.travary.app**, console app ID **4974523505827658180**.

Dashboard: `https://play.google.com/console/u/0/developers/6149577155193334943/app/4974523505827658180/app-dashboard`

| Observed location | State / exact labels |
|---|---|
| Dashboard | Draft app, production inactive. Internal testers see temporary name com.travary.app(unreviewed). Account verification tasks pending. |
| Dashboard > Production | 0 closed testers opted in. Requires at least12 opted in continuously14days and production application. Apply for production disabled. Closed-test tasks locked until setup complete. |
| Grow users > Store presence > Store listings (`…/store-listings`) | No default listing exists. **Create default store listing** button. Not pressed because creation could mutate state. Editable listing labels and locale creation flow therefore documented, not observed. |
| Grow users > Store presence > Store settings (`…/store-settings`) | App or game: App. Category: Not selected. Store listing contact details: Email address, Phone number, Website blank. Advertise my app outside of Google Play checked; untouched. |
| Store settings > Manage tags | Up to5. Exact available tags observed include Travel & local, Air travel, Travel guide, Hotels & vacation rental, Public transport, Train and Calendar. None selected. Recommend Travel & local only: the narrower alternatives imply services outside the core proposition. Dialog cancelled without Apply. |

Do not treat navigation to a section as verification of every nested field. `navigation_verified` in JSON is true only for the field/section actually observed; other locale forms and uploads remain false.
