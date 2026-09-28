import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { test } from 'node:test';

import { ApiError } from '@google/genai';

import { geminiRetryPlan, generateWithRetry, RETRYABLE_STATUSES } from './geminiRetry';

const busy = (status: number) => new ApiError({ message: 'busy', status });

function scripted(outcomes: Array<number | 'ok'>) {
  const calls: string[] = [];
  const call = async (model: string) => {
    calls.push(model);
    const next = outcomes.shift();
    if (next === 'ok' || next === undefined) return `answer from ${model}`;
    throw busy(next);
  };
  return { calls, call };
}

const noSleep = { sleep: async () => {} };

test('the plan: the main model twice, then the fallback', () => {
  assert.deepEqual(geminiRetryPlan('main', 'spare'), [
    { model: 'main', delayMs: 0 },
    { model: 'main', delayMs: 1500 },
    { model: 'spare', delayMs: 500 },
  ]);
  assert.deepEqual([...RETRYABLE_STATUSES].sort(), [429, 500, 503]);
});

test('busy errors retry, then fall back', async () => {
  const { calls, call } = scripted([503, 429, 'ok']);
  const retries: unknown[] = [];
  const outcome = await generateWithRetry(geminiRetryPlan('main', 'spare'), call, {
    ...noSleep,
    onRetry: (details) => retries.push(details),
  });
  assert.deepEqual(calls, ['main', 'main', 'spare']);
  assert.deepEqual(outcome, { response: 'answer from spare', usedModel: 'spare', attempts: 3 });
  assert.deepEqual(retries, [
    { model: 'main', status: 503, attempt: 1 },
    { model: 'main', status: 429, attempt: 2 },
  ]);
});

test('a second try on the main model can succeed', async () => {
  const { calls, call } = scripted([500, 'ok']);
  const outcome = await generateWithRetry(geminiRetryPlan('main', 'spare'), call, noSleep);
  assert.deepEqual(calls, ['main', 'main']);
  assert.equal(outcome.attempts, 2);
});

test('other errors fail straight away', async () => {
  for (const status of [400, 403, 404]) {
    const { calls, call } = scripted([status]);
    await assert.rejects(generateWithRetry(geminiRetryPlan('main', 'spare'), call, noSleep), (e) => e instanceof ApiError && e.status === status);
    assert.deepEqual(calls, ['main']);
  }
  const { calls, call } = { calls: [] as string[], call: async (m: string) => { calls.push(m); throw new SyntaxError('x'); } };
  await assert.rejects(generateWithRetry(geminiRetryPlan('main', 'spare'), call, noSleep), SyntaxError);
  assert.equal(calls.length, 1);
});

test('gives up after the fallback with the last error', async () => {
  const { calls, call } = scripted([503, 503, 429]);
  await assert.rejects(generateWithRetry(geminiRetryPlan('main', 'spare'), call, noSleep), (e) => e instanceof ApiError && e.status === 429);
  assert.equal(calls.length, 3);
});

test('waits between tries as planned', async () => {
  const waits: number[] = [];
  const { call } = scripted([503, 503, 'ok']);
  await generateWithRetry(geminiRetryPlan('main', 'spare'), call, { sleep: async (ms) => { waits.push(ms); } });
  assert.deepEqual(waits, [1500, 500]);
});

test('Smart Import and trip classification share this one policy', () => {
  for (const file of ['smartImport.ts', 'classifyTripVisuals.ts']) {
    const source = readFileSync(join(__dirname, '..', 'src', file), 'utf8');
    assert.match(source, /generateWithRetry\(\s*geminiRetryPlan\(/, file);
    assert.doesNotMatch(source, /new Set\(\[429/, `${file} has no retry list of its own`);
  }
});
