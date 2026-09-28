import { defineSecret } from 'firebase-functions/params';

/**
 * Server-only secrets (Secret Manager). Never in functions/.env, source
 * control or the app. Set with `firebase functions:secrets:set <NAME>`.
 */

/** Google AI Studio (Gemini API) key: Smart Import and trip classification. */
export const geminiApiKey = defineSecret('GEMINI_API_KEY');

/** Google Maps Platform key restricted to Places API (New): trip location verification. */
export const mapsApiKey = defineSecret('GOOGLE_MAPS_PLATFORM_KEY');
