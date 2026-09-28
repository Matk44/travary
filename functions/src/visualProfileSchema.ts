import {
  EXPERIENCE_THEMES, ExperienceTheme, isOneOf, isoCountryCode, Mood, MOODS, Setting, SETTINGS, slugify,
  VERIFICATION_STATUSES, VerificationStatus,
} from './visualVocabulary';

/**
 * What classifyTripVisuals asks Gemini for, and the validation applied to
 * whatever comes back. Gemini returns semantic metadata only: never image
 * prompts, file names, asset paths or pack IDs.
 *
 * The schema is kept simpler than the stored profile (Gemini rejects
 * schemas past a complexity limit); every bound is enforced by
 * normaliseVisualProfile instead.
 */
export const visualProfileResponseSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    primaryTheme: { type: 'string', enum: [...EXPERIENCE_THEMES] },
    secondaryThemes: {
      type: 'array',
      maxItems: 2,
      items: { type: 'string', enum: [...EXPERIENCE_THEMES] },
    },
    setting: { type: 'string', enum: [...SETTINGS] },
    moods: {
      type: 'array',
      maxItems: 3,
      items: { type: 'string', enum: [...MOODS] },
    },
    location: {
      type: 'object',
      additionalProperties: false,
      properties: {
        countryCode: {
          type: 'string',
          description: 'ISO 3166-1 alpha-2 country code. Omit when uncertain.',
        },
        countryName: { type: 'string' },
        region: { type: 'string' },
        city: { type: 'string' },
        locationQuery: {
          type: 'string',
          description: 'Most specific confident destination query, such as Kyoto, Japan.',
        },
        confidence: { type: 'number', minimum: 0, maximum: 1 },
      },
      required: ['confidence'],
    },
    confidence: { type: 'number', minimum: 0, maximum: 1 },
    evidence: {
      type: 'array',
      maxItems: 6,
      items: { type: 'string' },
    },
  },
  required: [
    'primaryTheme',
    'secondaryThemes',
    'setting',
    'moods',
    'location',
    'confidence',
    'evidence',
  ],
} as const;

export const VISUAL_PROFILE_SCHEMA_VERSION = 1;

/** Below this, a classification (or a location) is too weak to use. */
export const MIN_CONFIDENCE = 0.55;

const MAX_SECONDARY_THEMES = 2;
const MAX_MOODS = 3;
const MAX_EVIDENCE = 6;
const MAX_EVIDENCE_LENGTH = 120;

/** Where the trip is, as Gemini read it from the itinerary. */
export interface LocationHint {
  countryCode?: string;
  countryName?: string;
  region?: string;
  /** `region` as an art-pack selector ("kansai"). */
  regionSlug?: string;
  city?: string;
  /** `city` as an art-pack selector ("kyoto"). */
  citySlug?: string;
  locationQuery?: string;
  confidence: number;
}

/**
 * The hint after Places verification. Places supplies only the place ID
 * and, for at most 30 days (Google Maps Platform terms), coordinates. The
 * names stay the ones read from the traveller's itinerary.
 */
export interface VisualLocation extends LocationHint {
  verificationStatus: VerificationStatus;
  placeId?: string;
  latitude?: number;
  longitude?: number;
  /** Milliseconds since the epoch; coordinates are deleted after this. */
  coordinatesExpireAt?: number;
}

/** A classification before location verification. */
export interface NormalisedClassification {
  primaryTheme: ExperienceTheme;
  secondaryThemes: ExperienceTheme[];
  setting: Setting;
  moods: Mood[];
  location: LocationHint;
  confidence: number;
  evidence: string[];
}

/** What is stored on `trips/{tripId}.visualProfile` and returned to the app. */
export interface VisualProfile extends Omit<NormalisedClassification, 'location'> {
  schemaVersion: number;
  location: VisualLocation;
  sourceHash: string;
}

/**
 * Turns Gemini's output into a classification the app can trust: known
 * values only, no duplicates, bounded text, weak signals dropped.
 */
export function normaliseVisualProfile(raw: unknown): NormalisedClassification {
  const root = asRecord(raw);
  const confidence = clampConfidence(root.confidence);

  let primaryTheme: ExperienceTheme = isOneOf(EXPERIENCE_THEMES, root.primaryTheme)
    ? root.primaryTheme
    : 'classic_travel';
  let secondaryThemes = uniqueKnown(EXPERIENCE_THEMES, root.secondaryThemes)
    .filter((theme) => theme !== primaryTheme)
    .slice(0, MAX_SECONDARY_THEMES);
  if (confidence < MIN_CONFIDENCE) {
    // Weak or conflicting signals: the classic look, nothing layered on it.
    primaryTheme = 'classic_travel';
    secondaryThemes = [];
  }

  return {
    primaryTheme,
    secondaryThemes,
    setting: isOneOf(SETTINGS, root.setting) ? root.setting : 'unknown',
    moods: uniqueKnown(MOODS, root.moods).slice(0, MAX_MOODS),
    location: normaliseLocation(root.location),
    confidence,
    evidence: normaliseEvidence(root.evidence),
  };
}

function normaliseLocation(raw: unknown): LocationHint {
  const location = asRecord(raw);
  const confidence = clampConfidence(location.confidence);
  // Unknown or low-confidence places stay absent rather than invented.
  if (confidence < MIN_CONFIDENCE) return { confidence };

  const region = cleanText(location.region, 80);
  const city = cleanText(location.city, 80);
  const regionSlug = region ? slugify(region) : undefined;
  const citySlug = city ? slugify(city) : undefined;
  return compact({
    countryCode: isoCountryCode(location.countryCode),
    countryName: cleanText(location.countryName, 60),
    region,
    regionSlug,
    city,
    citySlug,
    locationQuery: cleanText(location.locationQuery, 120),
    confidence,
  });
}

/**
 * Short statements only. Anything that looks like a booking reference,
 * contact detail or link is dropped: evidence must never carry copied
 * personal data.
 */
function normaliseEvidence(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  const kept: string[] = [];
  for (const item of raw) {
    const text = cleanText(item, MAX_EVIDENCE_LENGTH);
    if (!text || looksPersonal(text) || kept.includes(text)) continue;
    kept.push(text);
    if (kept.length === MAX_EVIDENCE) break;
  }
  return kept;
}

const PERSONAL_PATTERNS = [
  /@/, // email addresses and handles
  /https?:|www\./i, // links
  /\b(?=[A-Z0-9-]*\d)(?=[A-Z0-9-]*[A-Z])[A-Z0-9-]{5,}\b/, // booking references like X7K2PQ
  /(?=[A-Za-z0-9_]*\d)(?=[A-Za-z0-9_]*[A-Za-z])[A-Za-z0-9_]{8,}/, // keys, tokens, long mixed codes
];

function looksPersonal(text: string): boolean {
  if (PERSONAL_PATTERNS.some((pattern) => pattern.test(text))) return true;
  // Phone, card and account numbers: nine or more digits in one run
  // (a date such as 2027-04-08 has eight).
  for (const run of text.match(/\d[\d\s().-]*\d/g) ?? []) {
    if (run.replace(/\D/g, '').length >= 9) return true;
  }
  return false;
}

/**
 * Reads a profile stored on a trip document, or undefined if it isn't a
 * well-formed one (then it's simply reclassified).
 */
export function readStoredProfile(raw: unknown): VisualProfile | undefined {
  const root = asRecord(raw);
  if (typeof root.sourceHash !== 'string' || !/^[0-9a-f]{64}$/.test(root.sourceHash)) return undefined;
  if (!isOneOf(EXPERIENCE_THEMES, root.primaryTheme)) return undefined;
  const location = asRecord(root.location);
  if (!isOneOf(VERIFICATION_STATUSES, location.verificationStatus)) return undefined;
  const classification = normaliseVisualProfile(root);
  const hint = normaliseLocation(location);
  const stored: VisualLocation = { ...hint, verificationStatus: location.verificationStatus };
  if (typeof location.placeId === 'string' && location.placeId.length > 0 && location.placeId.length <= 1024) {
    stored.placeId = location.placeId;
  }
  if (isLatitude(location.latitude) && isLongitude(location.longitude) && isFiniteNumber(location.coordinatesExpireAt)) {
    stored.latitude = location.latitude;
    stored.longitude = location.longitude;
    stored.coordinatesExpireAt = location.coordinatesExpireAt;
  }
  return {
    schemaVersion: isFiniteNumber(root.schemaVersion) ? root.schemaVersion : VISUAL_PROFILE_SCHEMA_VERSION,
    primaryTheme: classification.primaryTheme,
    secondaryThemes: classification.secondaryThemes,
    setting: classification.setting,
    moods: classification.moods,
    location: stored,
    confidence: classification.confidence,
    evidence: classification.evidence,
    sourceHash: root.sourceHash,
  };
}

/** [profile] without coordinates that are past their allowed caching time. */
export function withoutExpiredCoordinates(profile: VisualProfile, nowMs: number): VisualProfile {
  const { location } = profile;
  if (location.coordinatesExpireAt === undefined || location.coordinatesExpireAt > nowMs) return profile;
  const { latitude: _lat, longitude: _lng, coordinatesExpireAt: _exp, ...rest } = location;
  return { ...profile, location: rest };
}

// ------------------------------------------------------------------ helpers

export function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value) ? (value as Record<string, unknown>) : {};
}

export function isFiniteNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

export function isLatitude(value: unknown): value is number {
  return isFiniteNumber(value) && value >= -90 && value <= 90;
}

export function isLongitude(value: unknown): value is number {
  return isFiniteNumber(value) && value >= -180 && value <= 180;
}

export function clampConfidence(value: unknown): number {
  if (!isFiniteNumber(value)) return 0;
  return Math.min(1, Math.max(0, value));
}

/**
 * Trimmed, single-line text without control or bidi-override characters,
 * cut to [max] characters. Undefined when empty.
 */
export function cleanText(value: unknown, max: number): string | undefined {
  if (typeof value !== 'string') return undefined;
  const text = value
    .replace(/[\p{Cc}\u202A-\u202E\u2066-\u2069]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  if (!text) return undefined;
  return cutAt(text, max);
}

/** [text] cut to [max] UTF-16 units without splitting a surrogate pair. */
export function cutAt(text: string, max: number): string {
  if (text.length <= max) return text;
  const code = text.charCodeAt(max - 1);
  const end = code >= 0xd800 && code <= 0xdbff ? max - 1 : max;
  return text.slice(0, end).trimEnd();
}

function uniqueKnown<T extends string>(list: readonly T[], raw: unknown): T[] {
  if (!Array.isArray(raw)) return [];
  const result: T[] = [];
  for (const value of raw) {
    if (isOneOf(list, value) && !result.includes(value)) result.push(value);
  }
  return result;
}

/** Drops undefined values (Firestore rejects them). */
export function compact<T extends object>(value: T): T {
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as T;
}
