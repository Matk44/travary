import {
  asRecord, isLatitude, isLongitude, LocationHint, MIN_CONFIDENCE, VisualLocation,
} from './visualProfileSchema';
import { isoCountryCode, slugify } from './visualVocabulary';

/**
 * Checks the destination Gemini read from the itinerary against a geocoder
 * (Places Text Search (New) in production, a fake in tests).
 *
 * Google Maps Platform terms (reviewed Sept 2026, Service Specific Terms
 * §14.3 and the Places API policies): place IDs may be stored indefinitely,
 * latitude/longitude cached for at most 30 consecutive days, and no other
 * Places content cached. So verification keeps the itinerary's own place
 * names and stores only the place ID plus coordinates with an expiry; a
 * scheduled function deletes expired coordinates. Nothing from Places is
 * shown to the traveller, so no attribution is needed today; show "Google
 * Maps" attribution if that changes.
 */

/** What a geocoder found for a query. */
export type PlaceLookup =
  | { status: 'found'; place: ResolvedPlace }
  | { status: 'none' }
  /** A result came back, but not one we can rely on (e.g. no country). */
  | { status: 'ambiguous' }
  | { status: 'failed'; reason: 'timeout' | 'network' | 'http' | 'bad_response' | 'no_key'; httpStatus?: number };

export interface ResolvedPlace {
  placeId: string;
  /** ISO 3166-1 alpha-2, from the typed `country` address component. */
  countryCode: string;
  /** First-order administrative area, e.g. "Kyoto". Compared, never stored. */
  region?: string;
  /** Locality (or postal town), e.g. "Kyoto". Compared, never stored. */
  locality?: string;
  latitude: number;
  longitude: number;
}

export interface LocationResolver {
  resolve(query: string): Promise<PlaceLookup>;
}

/** Coordinates from Places may be kept this long (Service Specific Terms §14.3). */
export const PLACES_COORDINATE_TTL_MS = 30 * 24 * 3600 * 1000;

/**
 * Merges the Gemini hint with a Places lookup. Only location metadata
 * changes: the experience classification never depends on Places.
 *
 * - skipped: location confidence below 0.55, or no query. Places isn't asked.
 * - verified: Places found a coherent place whose country doesn't conflict
 *   with Gemini's. Adds the place ID and (expiring) coordinates.
 * - conflict: Places' country differs from Gemini's. The hint is kept, and
 *   the app won't use destination packs.
 * - unverified: no acceptable result (none, ambiguous, or a place that
 *   doesn't corroborate Gemini's city), or Places failed. The hint is kept.
 */
export async function verifyLocation(
  hint: LocationHint,
  resolver: LocationResolver,
  nowMs: number,
): Promise<VisualLocation> {
  if (hint.confidence < MIN_CONFIDENCE || !hint.locationQuery) {
    return { ...hint, verificationStatus: 'skipped' };
  }
  let lookup: PlaceLookup;
  try {
    lookup = await resolver.resolve(hint.locationQuery);
  } catch {
    lookup = { status: 'failed', reason: 'network' };
  }
  if (lookup.status !== 'found') return { ...hint, verificationStatus: 'unverified' };

  const { place } = lookup;
  if (hint.countryCode && hint.countryCode !== place.countryCode) {
    return { ...hint, verificationStatus: 'conflict' };
  }
  if (hint.citySlug && !corroboratesCity(place, hint.citySlug)) {
    return { ...hint, verificationStatus: 'unverified' };
  }
  return {
    ...hint,
    verificationStatus: 'verified',
    placeId: place.placeId,
    latitude: place.latitude,
    longitude: place.longitude,
    coordinatesExpireAt: nowMs + PLACES_COORDINATE_TTL_MS,
  };
}

/**
 * Whether Places' locality or first-order area names Gemini's city. City
 * states and prefecture capitals (Tokyo, Kyoto) often come back as an
 * administrative area without a locality. A result naming neither can't
 * contradict the city.
 */
function corroboratesCity(place: ResolvedPlace, citySlug: string): boolean {
  const names = [place.locality, place.region].filter((name): name is string => name !== undefined);
  return names.length === 0 || names.some((name) => slugify(name) === citySlug);
}

// --------------------------------------------------------------- Places

export const PLACES_TEXT_SEARCH_URL = 'https://places.googleapis.com/v1/places:searchText';

/** The only fields requested (Text Search Pro SKU). */
export const PLACES_FIELD_MASK =
  'places.id,places.displayName,places.formattedAddress,places.addressComponents,places.location,places.types';

const RETRYABLE_HTTP = new Set([429, 500, 502, 503, 504]);

export interface PlacesResolverOptions {
  apiKey: string;
  /** Replaces the global fetch (tests). */
  fetchImpl?: typeof fetch;
  timeoutMs?: number;
  sleep?: (ms: number) => Promise<void>;
}

/**
 * Places Text Search (New): one lookup, one result, a narrow field mask and
 * a 5-second timeout. A network error or busy response (429/5xx) gets one
 * more try; a timeout or any other 4xx doesn't.
 */
export class PlacesLocationResolver implements LocationResolver {
  constructor(private readonly options: PlacesResolverOptions) {}

  async resolve(query: string): Promise<PlaceLookup> {
    if (!this.options.apiKey) return { status: 'failed', reason: 'no_key' };
    const fetchImpl = this.options.fetchImpl ?? fetch;
    const sleep = this.options.sleep ?? ((ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms)));
    const timeoutMs = this.options.timeoutMs ?? 5000;

    for (let attempt = 1; attempt <= 2; attempt++) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);
      try {
        const response = await fetchImpl(PLACES_TEXT_SEARCH_URL, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': this.options.apiKey,
            'X-Goog-FieldMask': PLACES_FIELD_MASK,
          },
          body: JSON.stringify({ textQuery: query, pageSize: 1, languageCode: 'en' }),
          signal: controller.signal,
        });
        if (response.ok) return parsePlacesResponse(await response.json());
        if (RETRYABLE_HTTP.has(response.status) && attempt === 1) {
          await sleep(300);
          continue;
        }
        return { status: 'failed', reason: 'http', httpStatus: response.status };
      } catch (error) {
        if (controller.signal.aborted) return { status: 'failed', reason: 'timeout' };
        if (error instanceof SyntaxError) return { status: 'failed', reason: 'bad_response' };
        if (attempt === 1) {
          await sleep(300);
          continue;
        }
        return { status: 'failed', reason: 'network' };
      } finally {
        clearTimeout(timer);
      }
    }
    return { status: 'failed', reason: 'network' };
  }
}

/** Reads the first place of a Text Search response. */
export function parsePlacesResponse(body: unknown): PlaceLookup {
  const places = asRecord(body).places;
  if (!Array.isArray(places) || places.length === 0) return { status: 'none' };
  const place = asRecord(places[0]);

  const placeId = typeof place.id === 'string' && place.id.length > 0 && place.id.length <= 1024 ? place.id : undefined;
  const location = asRecord(place.location);
  const components = Array.isArray(place.addressComponents) ? place.addressComponents.map(asRecord) : [];
  const component = (type: string) =>
    components.find((c) => Array.isArray(c.types) && c.types.includes(type));
  const text = (value: unknown) => (typeof value === 'string' && value.trim() ? value.trim() : undefined);

  const countryCode = isoCountryCode(component('country')?.shortText);
  if (!placeId || !countryCode || !isLatitude(location.latitude) || !isLongitude(location.longitude)) {
    return { status: 'ambiguous' };
  }
  const region = text(component('administrative_area_level_1')?.longText);
  const locality = text(component('locality')?.longText) ?? text(component('postal_town')?.longText);
  return {
    status: 'found',
    place: {
      placeId,
      countryCode,
      ...(region && { region }),
      ...(locality && { locality }),
      latitude: location.latitude,
      longitude: location.longitude,
    },
  };
}
