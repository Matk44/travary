import { defineBoolean, defineInt, defineSecret, defineString } from 'firebase-functions/params';

/**
 * Server-only secrets (Secret Manager). Never in functions/.env, source
 * control or the app. Set with `firebase functions:secrets:set <NAME>`.
 */

/** Google AI Studio (Gemini API) key: Smart Import and trip classification. */
export const geminiApiKey = defineSecret('GEMINI_API_KEY');

/** Google Maps Platform key restricted to Places API (New): trip location verification. */
export const mapsApiKey = defineSecret('GOOGLE_MAPS_PLATFORM_KEY');

/** AeroDataBox via API.Market: live flight status (gate, terminal, delays). */
export const aeroDataBoxKey = defineSecret('AERODATABOX_API_KEY');

/** RevenueCat secret API key (v1, read-only is enough): checks purchases. */
export const revenueCatApiKey = defineSecret('REVENUECAT_API_KEY');

/** The Authorization header RevenueCat's webhook sends (set in both places). */
export const revenueCatWebhookAuth = defineSecret('REVENUECAT_WEBHOOK_AUTH');

/**
 * Cloudflare API token with Account → Email Sending: Edit, for the account
 * emails sent from send.travary.app (accountEmails.ts).
 */
export const cloudflareEmailToken = defineSecret('CLOUDFLARE_EMAIL_TOKEN');

/** The Cloudflare account that sends them (not a secret). */
export const cloudflareAccountId = defineString('CLOUDFLARE_ACCOUNT_ID', { default: '1b63e91f9618e2482f550906703a747f' });

/*
 * Flight alerts (functions/.env). The provider's plan: AeroDataBox Pro on
 * API.Market, 5,000 units a month (a hard limit), 1 request a second,
 * renewing on the day it was bought. To stop checking at once without a
 * deploy, set `config/flightAlerts` {paused: true} in Firestore.
 */

/** Whether the checker runs at all. */
export const flightAlertsEnabled = defineBoolean('FLIGHT_ALERTS_ENABLED', { default: false });

/** Units in the plan's month: the flight page's lookups and alerts share them. */
export const flightUnitsPerMonth = defineInt('FLIGHT_UNITS_PER_MONTH', { default: 5000 });

export const flightRatePerSecond = defineInt('FLIGHT_RATE_PER_SECOND', { default: 1 });

/** The day of the month (1 to 28) the plan's units renew. */
export const flightBillingDay = defineInt('FLIGHT_BILLING_DAY', { default: 1 });
