import assert from 'node:assert/strict';
import { test } from 'node:test';

import { isGuestToken, replaceMember, tripFateOnAccountDeletion } from './sharingLogic';

test('a guest is swapped for their account in place, never twice', () => {
  assert.deepEqual(replaceMember(['guest', 'mum'], 'guest', 'me'), ['me', 'mum']);
  assert.deepEqual(replaceMember(['mum', 'guest'], 'guest', 'me'), ['mum', 'me']);
  assert.deepEqual(replaceMember(['me', 'guest'], 'guest', 'me'), ['me']);
  assert.deepEqual(replaceMember(['mum'], 'guest', 'me'), ['mum']);
});

test('deleting an account: trips you share are handed on or left, your own are deleted', () => {
  assert.deepEqual(tripFateOnAccountDeletion('me', ['me'], 'me'), { action: 'delete' });
  assert.deepEqual(tripFateOnAccountDeletion('me', ['me', 'mum', 'sam'], 'me'), {
    action: 'hand-over',
    memberIds: ['mum', 'sam'],
    ownerId: 'mum',
  });
  assert.deepEqual(tripFateOnAccountDeletion('mum', ['mum', 'me'], 'me'), { action: 'leave', memberIds: ['mum'] });
});

test('a guest is anonymous, or an email it never confirmed; anyone signed in is not', () => {
  const token = (sign_in_provider: string, email_verified?: boolean) => ({ email_verified, firebase: { sign_in_provider } });
  assert.equal(isGuestToken(token('anonymous')), true);
  assert.equal(isGuestToken(token('password', false)), true);
  assert.equal(isGuestToken(token('password')), true);
  assert.equal(isGuestToken(token('password', true)), false);
  assert.equal(isGuestToken(token('google.com', true)), false);
  assert.equal(isGuestToken(token('apple.com')), false);
  assert.equal(isGuestToken(token('custom')), false);
});
