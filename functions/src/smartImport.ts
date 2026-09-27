import { ApiError, GoogleGenAI, ThinkingLevel } from '@google/genai';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/https';
import { defineSecret, defineString } from 'firebase-functions/params';

import { normaliseBookings, responseSchema } from './bookingSchema';
import { SYSTEM_PROMPT, userPrompt } from './prompt';

const geminiApiKey = defineSecret('GEMINI_API_KEY');

/** Change without a code edit: `SMART_IMPORT_MODEL=...` in functions/.env. */
const model = defineString('SMART_IMPORT_MODEL', { default: 'gemini-3.8-flash' });

/** Used when the main model is overloaded. */
const fallbackModel = defineString('SMART_IMPORT_FALLBACK_MODEL', { default: 'gemini-3.6-flash' });

/** Errors worth another go: overloaded (503), rate limited (429), server (500). */
const RETRYABLE = new Set([429, 500, 503]);

const MIME_TYPES = new Set([
  'image/png', 'image/jpeg', 'image/webp', 'image/heic', 'image/heif', 'application/pdf',
]);
const MAX_FILES = 3;
const MAX_TOTAL_BYTES = 15 * 1024 * 1024;

/**
 * Per-traveller daily cap. Protects the Gemini bill from abuse; far above
 * what anyone needs. (Free vs Plus allowances are enforced in the app for
 * now and move server-side with RevenueCat.)
 */
const DAILY_LIMIT = 25;

interface ImportFile {
  mimeType: string;
  data: string;
}

interface ImportRequest {
  files: ImportFile[];
  today: string;
}

/**
 * Smart Import: turns a screenshot, photo or PDF of a booking into draft
 * bookings. The app shows them for the traveller to check before saving.
 */
export const smartImport = onCall(
  { secrets: [geminiApiKey], memory: '512MiB', timeoutSeconds: 120, maxInstances: 20 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to use Smart Import.');

    const input = parseRequest(request.data);
    await reserveDailyUse(uid);

    const ai = new GoogleGenAI({ apiKey: geminiApiKey.value() });
    const started = Date.now();
    try {
      const { response, usedModel, attempts } = await generateWithRetry(ai, input);
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
 * Asks Gemini, riding out short spikes: two tries on the main model with a
 * pause, then one on the fallback model. Other errors fail straight away.
 */
async function generateWithRetry(ai: GoogleGenAI, input: ImportRequest) {
  const plan = [
    { model: model.value(), delayMs: 0 },
    { model: model.value(), delayMs: 1500 },
    { model: fallbackModel.value(), delayMs: 500 },
  ];
  let lastError: unknown;
  for (const [index, step] of plan.entries()) {
    if (step.delayMs) await new Promise((resolve) => setTimeout(resolve, step.delayMs));
    try {
      const response = await ai.models.generateContent({
        model: step.model,
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
      });
      return { response, usedModel: step.model, attempts: index + 1 };
    } catch (error) {
      lastError = error;
      if (!(error instanceof ApiError) || !RETRYABLE.has(error.status)) throw error;
      logger.warn('smart_import_retry', { model: step.model, status: error.status, attempt: index + 1 });
    }
  }
  throw lastError;
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
  return { files: parsed, today };
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
    if (RETRYABLE.has(error.status)) {
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
