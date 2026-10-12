# Analytics

9 October 2026. Funnel events go to **Firebase Analytics** from release
builds; purchases and revenue come from **RevenueCat**, which can also send
them into Firebase. Nothing is sent from debug runs unless built with
`--dart-define=TRAVARY_ANALYTICS=true` (for Firebase DebugView).

## What's sent

`track()` in `lib/state/analytics.dart` is the only way in. Events carry
action types and counts: never names, destinations, booking details,
document contents, email addresses or anything typed. Travel documents
carry their type only. Parameter text is cut at 100 characters.

| Area | Events |
|---|---|
| Onboarding | `onboarding_destination_chosen`, `onboarding_holiday_started` (dates set?), `onboarding_booking_started` / `_added` (kind, manual or import), `onboarding_offer_requested`, `onboarding_account_shown` / `_started` / `_linked` / `_cancelled` / `_failed` / `_skipped` (method), `onboarding_pass_desk_shown` / `_continued` (free or upgraded), `onboarding_completed` |
| Accounts | `sign_in` (method, switched, trips moved), `sign_out`, `account_deleted`, `email_link_sent`, `email_link_failed` |
| Paywall and purchases | `paywall_shown` / `_dismissed` (where, feature), `purchase_started` / `_purchased` / `_cancelled` / `_failed` (product ID, where) |
| Using the app | `trip_created`, `trip_joined`, `invite_created` / `_shared`, `smart_import_read` / `_failed`, `flight_filled`, `checklist_item_added` / `_done`, `packing_item_added` / `_done`, `packing_list_copied` (count), `travel_document_saved` (type), `notifications_asked` (allowed, denied), `flight_alert_opened`, and a few others |

Firebase also records its automatic events (first open, sessions, app
updates) and device basics (model, OS, country from IP). Travary turns off
the advertising ID on both platforms (`$FirebaseAnalyticsWithoutAdIdSupport`
in the Podfile; `AD_ID` removed and ad-ID collection off in the Android
manifest) and ad personalisation signals. No user ID is set.

## To switch it on (once)

1. Done: Google Analytics is linked to `travary-444` (property 519144259,
   streams for the iOS and Android apps). The config files' old
   `IS_ANALYTICS_ENABLED false` key doesn't matter.
2. **RevenueCat** → Project → Integrations → **Firebase** → connect, so
   purchases, renewals, cancellations and refunds appear in Firebase next to
   the funnel. The app already gives RevenueCat its analytics ID.
3. Update the public pages and store forms below **before** the release
   that sends anything.

## Privacy page wording (for `privacy.html`, to review)

> **Usage analytics.** Travary uses Google Firebase Analytics to understand
> how the app is used, for example how many people finish setting up a
> holiday or open the pass options. It records which actions happen (such as
> "booking added" or "pass desk shown"), counts, and basic device information
> (device model, operating system, app version, approximate country). It never
> records your destinations, bookings, documents, email address or anything
> you type, and Travary doesn't use advertising identifiers or share this
> with advertisers. Google processes this data on Travary's behalf.
>
> **Purchases.** Purchases are handled by Apple or Google and managed through
> RevenueCat, which tells Travary which passes your account holds.
>
> **Flight alerts.** On a trip with a Holiday Pass or Plus, Travary checks
> the trip's flights (flight number and date only) with its flight data
> provider, AeroDataBox, and sends a notification to everyone on the trip
> when one changes. To do that it keeps this phone's notification token
> (from Apple or Google) with your account; it's deleted when you delete
> your account. Notifications are optional and can be turned off in your
> phone's settings.

## Store privacy forms

- **App Store Connect → App Privacy:** add *Usage Data → Product
  Interaction* and *Diagnostics* if not already listed, *not linked to
  identity* and *not used for tracking*. Purchases (*Purchase History*)
  through RevenueCat, linked to the account.
- **Google Play → Data safety:** *App activity → App interactions* and
  *App info and performance*, collected, not shared, for analytics. No
  advertising ID.
- **Flight alerts (push):** Play's form likely needs *Device or other IDs*
  (the notification token), collected for app functionality, not shared.
  Apple doesn't ask about push tokens on their own; check both forms when
  flight alerts ship.

## Reading it

Firebase → Analytics → Events, or build a funnel (Explore → Funnel
exploration) from `onboarding_destination_chosen` →
`onboarding_booking_added` → `onboarding_pass_desk_shown` →
`purchase_purchased`. Compare purchases and revenue per new user, not just
paywall conversion (`docs/ONBOARDING_CONVERSION.md`).
