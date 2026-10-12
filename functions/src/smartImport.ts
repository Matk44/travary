import { ApiError, GoogleGenAI, ThinkingLevel } from '@google/genai';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/https';
import { defineString } from 'firebase-functions/params';

import { normaliseBookings, responseSchema } from './bookingSchema';
import { geminiRetryPlan, generateWithRetry, RETRYABLE_STATUSES } from './geminiRetry';
import { geminiApiKey, revenueCatApiKey } from './params';
import { SYSTEM_PROMPT, userPrompt } from './prompt';
import { hasPremium, revenueCatApi } from './purchases';
import { FREE_SMART_IMPORTS } from './purchasesLogic';

/** Change without a code edit: `SMART_IMPORT_MODEL=...` in functions/.env. */
const model = defineString('SMART_IMPORT_MODEL', { default: 'gemini-3.8-flash' });

/** Used when the main model is overloaded. */
const fallbackModel = defineString('SMART_IMPORT_FALLBACK_MODEL', { default: 'gemini-3.6-flash' });

const MIME_TYPES = new Set([
  'image/png', 'image/jpeg', 'image/webp', 'image/heic', 'image/heif', 'application/pdf',
]);
const MAX_FILES = 3;
const MAX_TOTAL_BYTES = 15 * 1024 * 1024;

/**
 * Per-traveller daily cap. Protects the Gemini bill from abuse; far above
 * what anyone needs. Past the free ones (FREE_SMART_IMPORTS, counted in
 * `smartImport.total`) it takes premium: Plus, or a pass on the trip the
 * app names (`tripId`), checked here as well as in the app.
 */
const DAILY_LIMIT = 25;

interface ImportFile {
  mimeType: string;
  data: string;
}

interface ImportRequest {
  files: ImportFile[];
  today: string;
  /** The trip whose pass allows this one, when it's a pass that does. */
  tripId?: string;
}

/**
 * Smart Import: turns a screenshot, photo or PDF of a booking into draft
 * bookings. The app shows them for the traveller to check before saving.
 */
export const smartImport = onCall(
  { secrets: [geminiApiKey, revenueCatApiKey], memory: '512MiB', timeoutSeconds: 120, maxInstances: 20 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to use Smart Import.');

    const input = parseRequest(request.data);
    await requireAllowance(uid, input.tripId);
    await reserveDailyUse(uid);

    const ai = new GoogleGenAI({ apiKey: geminiApiKey.value() });
    const started = Date.now();
    try {
      const { response, usedModel, attempts } = await generate(ai, input);
      const result = normaliseBookings(JSON.parse(response.text ?? '{}'));
      // Log sizes and timings only, never the traveller's documents.
      logger.info('smart_import', {
        uid,
        files: input.files.length,
        bookings: result.bookings.length,
        ms: Date.now() - started,
        model: usedModel,
        attempts,
        tokens: response.usageMetadata?.totalTokenCount,
      });
      return result;
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

/**
 * Asks Gemini, riding out short spikes with the shared retry policy
 * (geminiRetry.ts). Other errors fail straight away.
 */
function generate(ai: GoogleGenAI, input: ImportRequest) {
  return generateWithRetry(
    geminiRetryPlan(model.value(), fallbackModel.value()),
    (stepModel) =>
      ai.models.generateContent({
        model: stepModel,
        contents: [
          {
            role: 'user',
            parts: [
              ...input.files.map((file) => ({ inlineData: { mimeType: file.mimeType, data: file.data } })),
              { text: userPrompt(input.today) },
            ],
          },
        ],
        config: {
          systemInstruction: SYSTEM_PROMPT,
          responseMimeType: 'application/json',
          responseJsonSchema: responseSchema,
          thinkingConfig: { thinkingLevel: ThinkingLevel.LOW },
        },
      }),
    { onRetry: (details) => logger.warn('smart_import_retry', details) },
  );
}

function parseRequest(data: unknown): ImportRequest {
  const body = (data && typeof data === 'object' ? data : {}) as Record<string, unknown>;
  const today = typeof body.today === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(body.today)
    ? body.today
    : new Date().toISOString().slice(0, 10);

  const files = Array.isArray(body.files) ? body.files : [];
  if (files.length === 0 || files.length > MAX_FILES) {
    throw new HttpsError('invalid-argument', 'Attach a screenshot, photo or PDF.');
  }
  let totalBytes = 0;
  const parsed = files.map((file): ImportFile => {
    const f = (file && typeof file === 'object' ? file : {}) as Record<string, unknown>;
    if (typeof f.mimeType !== 'string' || !MIME_TYPES.has(f.mimeType)) {
      throw new HttpsError('invalid-argument', 'Use a photo, screenshot or PDF.');
    }
    if (typeof f.data !== 'string' || f.data.length === 0) {
      throw new HttpsError('invalid-argument', 'The file was empty.');
    }
    totalBytes += Math.floor((f.data.length * 3) / 4);
    return { mimeType: f.mimeType, data: f.data };
  });
  if (totalBytes > MAX_TOTAL_BYTES) {
    throw new HttpsError('invalid-argument', 'That file is too big. Try a screenshot instead.');
  }
  const tripId = typeof body.tripId === 'string' && body.tripId && !body.tripId.includes('/') ? body.tripId : undefined;
  return { files: parsed, today, tripId };
}

/** A free one, or premium (see DAILY_LIMIT). */
async function requireAllowance(uid: string, tripId: string | undefined): Promise<void> {
  const db = getFirestore();
  const used = (await db.doc(`users/${uid}`).get()).get('smartImport.total');
  if (typeof used !== 'number' || used < FREE_SMART_IMPORTS) return;
  if (await hasPremium(db, revenueCatApi(revenueCatApiKey.value()), uid, tripId)) return;
  throw new HttpsError(
    'permission-denied',
    'You\'ve used your free Smart Imports. Travary Plus, or a Holiday Pass for this trip, brings in as many as you like.',
  );
}

async function reserveDailyUse(uid: string): Promise<void> {
  const db = getFirestore();
  const ref = db.collection('users').doc(uid);
  const day = new Date().toISOString().slice(0, 10);
  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const usage = (snapshot.get('smartImport') ?? {}) as { day?: string; today?: number; total?: number };
    const today = usage.day === day ? usage.today ?? 0 : 0;
    if (today >= DAILY_LIMIT) {
      throw new HttpsError('resource-exhausted', 'That\'s a lot of imports for one day. Try again tomorrow.');
    }
    tx.set(ref, { smartImport: { day, today: today + 1, total: (usage.total ?? 0) + 1 } }, { merge: true });
  });
}

function toHttpsError(error: unknown): HttpsError {
  if (error instanceof HttpsError) return error;
  if (error instanceof SyntaxError) {
    logger.warn('smart_import_bad_json');
    return new HttpsError('internal', 'Couldn\'t read that booking. Try a clearer screenshot.');
  }
  if (error instanceof ApiError) {
    logger.error('smart_import_gemini_error', { status: error.status, detail: error.message.slice(0, 1000) });
    if (RETRYABLE_STATUSES.has(error.status)) {
      return new HttpsError('unavailable', 'Smart Import is busy right now. Try again in a minute.');
    }
    if (error.status === 400) {
      return new HttpsError('invalid-argument', 'Couldn\'t read that file. Try a screenshot or PDF.');
    }
  } else {
    logger.error('smart_import_failed', { error: String(error) });
  }
  return new HttpsError('internal', 'Smart Import had a problem. Try again shortly.');
}
