import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { test } from 'node:test';

import { tripPassLastDay } from './tripPass';

interface Case {
  why: string;
  pass: [string, string];
  trip: [string, string] | null;
  lastDay: string | null;
}

const { cases } = JSON.parse(readFileSync(join(__dirname, '..', 'src', 'tripPassCases.json'), 'utf8')) as {
  cases: Case[];
};

test('a Trip Pass lasts as the app says (shared cases)', () => {
  assert.ok(cases.length >= 10);
  for (const c of cases) {
    const trip = c.trip === null ? null : { start: c.trip[0], end: c.trip[1] };
    assert.equal(tripPassLastDay({ start: c.pass[0], end: c.pass[1] }, trip), c.lastDay, c.why);
  }
});

test('junk dates are refused, not guessed', () => {
  assert.throws(() => tripPassLastDay({ start: '12/10/2026', end: '2026-10-18' }, null));
});
