import assert from 'node:assert/strict';
import { test } from 'node:test';

import { cleanName, newInviteCode, normaliseCode, withMember, withoutMember } from './sharingLogic';

test('invite codes are 6 unambiguous characters', () => {
  for (let i = 0; i < 200; i++) {
    const code = newInviteCode();
    assert.match(code, /^[A-HJ-NP-Z2-9]{6}$/);
  }
});

test('codes are forgiving to type', () => {
  assert.equal(normaliseCode('abc 234'), 'ABC234');
  assert.equal(normaliseCode(' xyz-789 '), 'XYZ789');
  assert.equal(normaliseCode('abc'), null);
  assert.equal(normaliseCode(42), null);
});

test('names are tidied and bounded', () => {
  assert.equal(cleanName('  Alex   Taylor '), 'Alex Taylor');
  assert.equal(cleanName('x'.repeat(50))?.length, 30);
  assert.equal(cleanName('   '), null);
  assert.equal(cleanName(undefined), null);
});

test('member lists never duplicate', () => {
  assert.deepEqual(withMember(['a'], 'b'), ['a', 'b']);
  assert.deepEqual(withMember(['a', 'b'], 'b'), ['a', 'b']);
  assert.deepEqual(withoutMember(['a', 'b'], 'b'), ['a']);
});
