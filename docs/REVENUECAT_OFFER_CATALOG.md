# RevenueCat pass catalog

6 October 2026. The onboarding pass desk supports RevenueCat packages and
localized store prices through `RevenueCatOfferCatalog`.

7 October 2026. Real purchases go through `RevenueCatPurchaseService` (cloud
builds with the keys below), with verified Holiday Pass claims and the
Annual Pass mirrored by the server (`functions/src/purchases.ts`; see
Premium in `CLAUDE.md`). Without keys, and in demo mode, the app keeps
`TestPurchaseService` (“Test store: nothing is charged”).

## What's set up

- App Store Connect and Google Play: `travary_annual_pass` (yearly; Google
  base plan `travary-annual-pass`) and the consumable `holiday_pass`.
- RevenueCat project **Travary**: apps “Travary (App Store)” (bundle
  `com.travary.app`, the team's existing in-app purchase and App Store
  Connect API keys) and “Travary (Play Store)” (package `com.travary.app`).
  Entitlement `plus` on both Annual Pass products. Offering `default`
  (current): package `$rc_annual` (Annual Pass) and custom package
  `holiday_pass`, with the `pass_desk` metadata below.
- Done 8 October 2026: the Play service account
  (`revenuecat-service-account@travary-444`) is uploaded to RevenueCat, the
  server's `REVENUECAT_API_KEY` and `REVENUECAT_WEBHOOK_AUTH` secrets are
  set, and the webhook
  (`https://us-central1-travary-444.cloudfunctions.net/revenueCatWebhook`)
  answered RevenueCat's test event. Left: the Apple Annual Pass price and
  sandbox purchases on both stores.

## Configuration

Set the public SDK key for each platform using a local, git-ignored
`--dart-define-from-file` configuration (`config/revenuecat.local.json`,
already filled in on the development Mac) or build defines:

```json
{
  "TRAVARY_REVENUECAT_IOS_KEY": "appl_YOUR_PUBLIC_KEY",
  "TRAVARY_REVENUECAT_ANDROID_KEY": "goog_YOUR_PUBLIC_KEY",
  "TRAVARY_REVENUECAT_OFFERING": "onboarding"
}
```

These are RevenueCat's platform-specific **public SDK** keys, never a secret
REST API key. Omitting the offering ID selects RevenueCat's current offering.
The app configures the SDK lazily, using the active Travary account's user ID
(`RevenueCatIdentity`); identity changes and offering reads are serialized.

With no platform key, the offline preview uses $14.99 Holiday Pass and
$34.99 Annual Pass. With a key, only products actually returned in that
offering are displayed. An empty or failed response never fabricates USD
prices; retry and free continuation remain available. The catalog is fetched
when opening the desk; SDK cache behavior still applies.

## Offering metadata

Create the actual products in App Store Connect/Google Play, attach them to
packages in the RevenueCat offering, and set this **example** metadata on it:

```json
{
  "pass_desk": {
    "holiday": {
      "package": "holiday_pass",
      "title": "Holiday Pass",
      "scope": "This holiday"
    },
    "annual": {
      "package": "$rc_annual",
      "title": "Annual Pass",
      "scope": "Holidays through the year"
    }
  }
}
```

This is the metadata on the `default` offering now.

`package` is the package identifier within the selected offering. Change it
remotely to use a different product without changing the app's product IDs.
`title` and `scope` are optional strings. Titles fall back to the store product
title; scope falls back to the semantic role's copy. Set `enabled: false` or
remove the package from the offering to hide that ticket. With no annual
metadata, the offering's annual package is used. Holiday requires an explicit
package mapping so a lifetime product is never guessed to be a trip purchase.

The two roles have fixed billing semantics: Holiday is a non-subscription
product, Annual is a one-year subscription. Monthly/lifetime or new billing
models need corresponding application and entitlement rules before they can
be sold here. Product category and subscription period are validated. The
consumable type must also be configured correctly in the store; the category
alone does not distinguish consumables from non-consumables.

## Prices and artwork

The ticket and CTA use the returned offer. The price is the SDK's
`StoreProduct.priceString`, including the store's correct localized formatting.
Travary adds no “US” prefix. It does not strip qualifiers from the store's own
localized string. Numeric prices and currency codes are retained for the
existing per-day comparison. Offering metadata cannot override the price or
mislabel the billing period. Change the real product price in the store's
product configuration; RevenueCat supplies that price through the offering.

The approved paywall artwork has no lettering, digits, prices or selection
marks. Native text and selection controls sit over its measured regions.
Remote text and larger accessibility type can expand the ticket and scroll.
Removing a selected Holiday Pass does not automatically choose Annual.

## References and verification

Official documentation: [displaying products](https://www.revenuecat.com/docs/getting-started/displaying-products),
[SDK configuration](https://www.revenuecat.com/docs/getting-started/configuring-sdk),
[offering metadata](https://www.revenuecat.com/docs/tools/offering-metadata/offering-metadata-examples).

Parser and widget tests cover remote package changes, localized prices,
metadata titles/scope, ignored price overrides, invalid billing periods,
disabled/removed products and deliberate selection. State tests cover loading,
failure without fake prices, overlapping refreshes and disposed accounts.
Live dashboard/product availability and store purchase QA require the owner's
actual RevenueCat project and the separate production billing implementation.
