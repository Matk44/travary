import { ApiError } from '@google/genai';

/**
 * The one retry policy for every Gemini call (Smart Import and trip
 * classification): two tries on the main model with a pause, then one on
 * the fallback model. Only "busy" errors are retried; anything else fails
 * straight away.
 */

/** Errors worth another go: overloaded (503), rate limited (429), server (500). */
export const RETRYABLE_STATUSES: ReadonlySet<number> = new Set([429, 500, 503]);

export interface RetryStep {
  model: string;
  delayMs: number;
}

export function geminiRetryPlan(model: string, fallbackModel: string): RetryStep[] {
  return [
    { model, delayMs: 0 },
    { model, delayMs: 1500 },
    { model: fallbackModel, delayMs: 500 },
  ];
}

export function isRetryableGeminiError(error: unknown): error is ApiError {
  return error instanceof ApiError && RETRYABLE_STATUSES.has(error.status);
}

export interface RetryOutcome<T> {
  response: T;
  usedModel: string;
  attempts: number;
}

export interface RetryHooks {
  /** Called before each retry, e.g. to log it. */
  onRetry?: (details: { model: string; status: number; attempt: number }) => void;
  /** Replaces the real pause (tests). */
  sleep?: (ms: number) => Promise<void>;
}

/** Runs [call] with each model in [plan] until one succeeds. */
export async function generateWithRetry<T>(
  plan: readonly RetryStep[],
  call: (model: string) => Promise<T>,
  hooks: RetryHooks = {},
): Promise<RetryOutcome<T>> {
  const sleep = hooks.sleep ?? ((ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms)));
  let lastError: unknown = new Error('No Gemini models configured.');
  for (const [index, step] of plan.entries()) {
    if (step.delayMs) await sleep(step.delayMs);
    try {
      const response = await call(step.model);
      return { response, usedModel: step.model, attempts: index + 1 };
    } catch (error) {
      lastError = error;
      if (!isRetryableGeminiError(error)) throw error;
      hooks.onRetry?.({ model: step.model, status: error.status, attempt: index + 1 });
    }
  }
  throw lastError;
}
