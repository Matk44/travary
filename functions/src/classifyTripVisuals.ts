import { ApiError, GoogleGenAI, ThinkingLevel } from '@google/genai';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/https';
import { defineString } from 'firebase-functions/params';
import { onSchedule } from 'firebase-functions/scheduler';

import { geminiRetryPlan, generateWithRetry, RETRYABLE_STATUSES } from './geminiRetry';
import { LocationResolver, PlacesLocationResolver, verifyLocation } from './locationResolver';
import { geminiApiKey, mapsApiKey } from './params';
import {
  geminiPayload, InvalidRequestError, parseClassifyRequest, SanitizedTrip, sourceHashFor,
} from './visualProfileRequest';
import {
  normaliseVisualProfile, readStoredProfile, VISUAL_PROFILE_SCHEMA_VERSION, visualProfileResponseSchema, VisualProfile,
  withoutExpiredCoordinates,
} from './visualProfileSchema';
import { VISUAL_PROFILE_SYSTEM_PROMPT, visualProfileUserPrompt } from './visualProfilePrompt';
import {
  AccessError, FirestoreVisualProfileStore, purgeExpiredCoordinates, RateLimitError, VisualProfileStore,
} from './visualProfileStore';
import { themeFieldsFor } from './visualThemeRules';

/** Tunable without touching Smart Import: `VISUAL_PROFILE_MODEL=...` in functions/.env. */
const visualModel = defineString('VISUAL_PROFILE_MODEL', { default: 'gemini-3.8-flash' });

/** Used when the main model is overloaded. */
const visualFallbackModel = defineString('VISUAL_PROFILE_FALLBACK_MODEL', { default: 'gemini-3.6-flash' });

export interface GeminiClassification {
  /** Gemini's parsed JSON, not yet trusted. */
  raw: unknown;
  model: string;
  attempts: number;
  tokens?: number;
}

export interface ClassifyDependencies {
  store: VisualProfileStore;
  classify(payload: ReturnType<typeof geminiPayload>): Promise<GeminiClassification>;
  resolver: LocationResolver;
  now(): number;
  log: Pick<typeof logger, 'info' | 'warn' | 'error'>;
}

export interface ClassifyResponse {
  profile: VisualProfile;
  cached: boolean;
}

/**
 * Classifies one trip's itinerary into a visual profile: experience theme,
 * setting, moods and a verified destination. The app picks artwork packs
 * from it; Gemini never picks files.
 *
 * Logs timings, model, tokens, confidence and statuses only: never titles,
 * places, evidence or the request.
 */
export const classifyTripVisuals = onCall(
  { secrets: [geminiApiKey, mapsApiKey], memory: '512MiB', timeoutSeconds: 120, maxInstances: 20 },
  async (request) => {
    const ai = new GoogleGenAI({ apiKey: geminiApiKey.value() });
    return classifyTripVisualsHandler(request.auth?.uid, request.data, {
      store: new FirestoreVisualProfileStore(getFirestore()),
      classify: (payload) => classifyWithGemini(ai, payload),
      resolver: new PlacesLocationResolver({ apiKey: mapsApiKey.value() }),
      now: Date.now,
      log: logger,
    });
  },
);

/** Deletes Places coordinates older than Google allows them to be kept. */
export const purgeExpiredPlaceCoordinates = onSchedule(
  { schedule: 'every 24 hours', timeoutSeconds: 300, maxInstances: 1 },
  async () => {
    const purged = await purgeExpiredCoordinates(getFirestore(), Date.now());
    logger.info('purge_place_coordinates', { purged });
  },
);

export async function classifyTripVisualsHandler(
  uid: string | undefined,
  data: unknown,
  deps: ClassifyDependencies,
): Promise<ClassifyResponse> {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');

  let trip: SanitizedTrip;
  try {
    trip = parseClassifyRequest(data);
  } catch (error) {
    if (error instanceof InvalidRequestError) throw new HttpsError('invalid-argument', error.message);
    throw error;
  }
  const { tripId } = trip;
  const started = deps.now();

  const stored = await deps.store.readTrip(tripId);
  // A brand-new trip may not have reached the server yet: the app retries.
  if (!stored) throw new HttpsError('not-found', 'That trip isn\'t saved yet.', { reason: 'trip_not_synced' });
  if (!stored.memberIds.includes(uid)) throw new HttpsError('permission-denied', 'You\'re not on this trip.');

  const sourceHash = sourceHashFor(trip);
  const cached = readStoredProfile(stored.visualProfile);
  if (cached && cached.sourceHash === sourceHash) {
    const profile = withoutExpiredCoordinates(cached, deps.now());
    if (Object.keys(themeFieldsFor(stored, profile.primaryTheme)).length > 0) {
      // e.g. the traveller just switched back to the automatic look.
      await guarded(() => deps.store.syncAutomaticTheme({ uid, tripId, primaryTheme: profile.primaryTheme }));
    }
    deps.log.info('classify_trip_visuals', {
      uid, tripId, cached: true, ms: deps.now() - started, confidence: profile.confidence,
    });
    return { profile, cached: true };
  }

  await guarded(() => deps.store.reserve({ uid, tripId, sourceHash, nowMs: deps.now() }));

  let generated: GeminiClassification;
  try {
    generated = await deps.classify(geminiPayload(trip));
  } catch (error) {
    throw toHttpsError(error, deps.log);
  }

  const classification = normaliseVisualProfile(generated.raw);
  const location = await verifyLocation(classification.location, deps.resolver, deps.now());
  const profile: VisualProfile = {
    schemaVersion: VISUAL_PROFILE_SCHEMA_VERSION,
    primaryTheme: classification.primaryTheme,
    secondaryThemes: classification.secondaryThemes,
    setting: classification.setting,
    moods: classification.moods,
    location,
    confidence: classification.confidence,
    evidence: classification.evidence,
    sourceHash,
  };

  const outcome = await guarded(() => deps.store.save({ uid, tripId, profile }));
  const details = {
    uid,
    tripId,
    cached: false,
    ms: deps.now() - started,
    model: generated.model,
    attempts: generated.attempts,
    tokens: generated.tokens,
    confidence: profile.confidence,
    locationConfidence: profile.location.confidence,
    verificationStatus: profile.location.verificationStatus,
    primaryTheme: profile.primaryTheme,
  };
  if (outcome === 'superseded') {
    deps.log.info('classify_trip_visuals_superseded', details);
    throw new HttpsError('aborted', 'A newer update to this trip is being classified.', { reason: 'superseded' });
  }
  deps.log.info('classify_trip_visuals', details);
  return { profile, cached: false };
}

/** Runs a store call, turning its errors into ones for the app. */
async function guarded<T>(action: () => Promise<T>): Promise<T> {
  try {
    return await action();
  } catch (error) {
    if (error instanceof AccessError) {
      throw error.reason === 'missing'
        ? new HttpsError('not-found', 'That trip isn\'t saved yet.', { reason: 'trip_not_synced' })
        : new HttpsError('permission-denied', 'You\'re not on this trip.');
    }
    if (error instanceof RateLimitError) {
      if (error.reason === 'cooldown') {
        throw new HttpsError('resource-exhausted', 'This trip was classified a moment ago.', {
          reason: 'cooldown',
          retryAfterSeconds: Math.ceil((error.retryAfterMs ?? 0) / 1000),
        });
      }
      throw new HttpsError('resource-exhausted', 'Automatic looks are resting until tomorrow.', { reason: 'daily' });
    }
    throw error;
  }
}

/** One Gemini call (with the shared retry policy), parsed but not trusted. */
async function classifyWithGemini(
  ai: GoogleGenAI,
  payload: ReturnType<typeof geminiPayload>,
): Promise<GeminiClassification> {
  const { response, usedModel, attempts } = await generateWithRetry(
    geminiRetryPlan(visualModel.value(), visualFallbackModel.value()),
    (model) =>
      ai.models.generateContent({
        model,
        contents: visualProfileUserPrompt(payload),
        config: {
          systemInstruction: VISUAL_PROFILE_SYSTEM_PROMPT,
          responseMimeType: 'application/json',
          responseJsonSchema: visualProfileResponseSchema,
          thinkingConfig: { thinkingLevel: ThinkingLevel.LOW },
        },
      }),
    { onRetry: (details) => logger.warn('classify_trip_visuals_retry', details) },
  );
  return {
    raw: JSON.parse(response.text ?? '{}'),
    model: usedModel,
    attempts,
    tokens: response.usageMetadata?.totalTokenCount,
  };
}

function toHttpsError(error: unknown, log: ClassifyDependencies['log']): HttpsError {
  if (error instanceof HttpsError) return error;
  if (error instanceof SyntaxError) {
    log.warn('classify_trip_visuals_bad_json');
    return new HttpsError('internal', 'Couldn\'t choose a look for this trip right now.');
  }
  if (error instanceof ApiError) {
    // Status only: Gemini's messages can quote the request.
    log.error('classify_trip_visuals_gemini_error', { status: error.status });
    if (RETRYABLE_STATUSES.has(error.status)) {
      return new HttpsError('unavailable', 'Automatic looks are busy right now. Try again in a minute.');
    }
  } else {
    log.error('classify_trip_visuals_failed', { error: error instanceof Error ? error.name : typeof error });
  }
  return new HttpsError('internal', 'Couldn\'t choose a look for this trip right now.');
}
