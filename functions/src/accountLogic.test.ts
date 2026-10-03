import assert from 'node:assert/strict';
import { test } from 'node:test';

import { replaceMember, tripFateOnAccountDeletion } from './sharingLogic';

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
