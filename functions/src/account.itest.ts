/**
 * Account moves and deletion against the Firestore emulator. Run with
 * `npm --prefix functions run test:emulator`.
 */
import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';

import { deleteApp, initializeApp } from 'firebase-admin/app';
import { Firestore, getFirestore } from 'firebase-admin/firestore';

import { AccountAuth, adoptGuestTrips, deleteAccountData } from './account';

const PROJECT = 'demo-travary';
let app: ReturnType<typeof initializeApp>;
let db: Firestore;

/** Tokens are "<provider>:<uid>"; deleted users are recorded. */
class FakeAuth implements AccountAuth {
  deleted: string[] = [];
  async verifyIdToken(token: string) {
    const [provider, uid] = token.split(':');
    if (!uid) throw new Error('bad token');
    return { uid, firebase: { sign_in_provider: provider } };
  }
  async deleteUser(uid: string) {
    this.deleted.push(uid);
  }
}

before(() => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Run through `npm run test:emulator`.');
  app = initializeApp({ projectId: PROJECT }, 'account-itest');
  db = getFirestore(app);
});

after(() => deleteApp(app));

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  // The guest organises Lisbon alone and is on Mum's Kyoto trip.
  await db.doc('trips/lisbon').set({ title: 'Lisbon', ownerId: 'guest', memberIds: ['guest'], memberNames: {} });
  await db.doc('trips/lisbon/bookings/b1').set({ title: 'Hotel', memberIds: ['guest'] });
  await db.doc('trips/kyoto').set({
    title: 'Kyoto',
    ownerId: 'mum',
    memberIds: ['mum', 'guest'],
    memberNames: { mum: 'Mum', guest: 'Sam' },
  });
  await db.doc('trips/kyoto/bookings/b2').set({ title: 'Ryokan', memberIds: ['mum', 'guest'] });
  await db.doc('invites/ABC234').set({ tripId: 'lisbon', createdBy: 'guest' });
});

test('a guest\'s trips move to the account they signed in to, with every booking\'s copy', async () => {
  const auth = new FakeAuth();
  assert.deepEqual(await adoptGuestTrips(db, auth, 'me', 'anonymous:guest'), { trips: 2 });

  const lisbon = (await db.doc('trips/lisbon').get()).data()!;
  assert.equal(lisbon.ownerId, 'me');
  assert.deepEqual(lisbon.memberIds, ['me']);
  assert.deepEqual((await db.doc('trips/lisbon/bookings/b1').get()).get('memberIds'), ['me']);

  const kyoto = (await db.doc('trips/kyoto').get()).data()!;
  assert.equal(kyoto.ownerId, 'mum');
  assert.deepEqual(kyoto.memberIds, ['mum', 'me']);
  assert.deepEqual(kyoto.memberNames, { mum: 'Mum', me: 'Sam' });
  assert.deepEqual((await db.doc('trips/kyoto/bookings/b2').get()).get('memberIds'), ['mum', 'me']);

  assert.equal((await db.doc('invites/ABC234').get()).get('createdBy'), 'me');
  assert.deepEqual(auth.deleted, ['guest'], 'the empty guest account is removed');
});

test('only a guest account\'s trips can be taken, and only with its token', async () => {
  const auth = new FakeAuth();
  await assert.rejects(adoptGuestTrips(db, auth, 'me', 'google.com:mum'), /permission-denied|guest/);
  await assert.rejects(adoptGuestTrips(db, auth, 'me', 'nonsense'), /couldn't be confirmed/);
  await assert.rejects(adoptGuestTrips(db, auth, 'me', undefined), /token/);
  assert.deepEqual((await db.doc('trips/kyoto').get()).get('memberIds'), ['mum', 'guest']);
  assert.deepEqual(await adoptGuestTrips(db, auth, 'guest', 'anonymous:guest'), { trips: 0 });
});

test('deleting an account: own trips go with their files, shared ones are left or handed on', async () => {
  await db.doc('trips/paris').set({ title: 'Paris', ownerId: 'guest', memberIds: ['guest', 'dad'], memberNames: { guest: 'Sam' } });
  await db.doc('trips/paris/bookings/b3').set({ title: 'Louvre', memberIds: ['guest', 'dad'] });
  await db.doc('users/guest').set({ smartImport: { total: 2 } });
  const auth = new FakeAuth();
  const filesDeleted: string[] = [];

  const counts = await deleteAccountData(db, auth, async (tripId) => {
    filesDeleted.push(tripId);
  }, 'guest');

  assert.deepEqual(counts, { deleted: 1, handedOver: 1, left: 1 });
  assert.equal((await db.doc('trips/lisbon').get()).exists, false);
  assert.equal((await db.doc('trips/lisbon/bookings/b1').get()).exists, false);
  assert.equal((await db.doc('invites/ABC234').get()).exists, false);
  assert.deepEqual(filesDeleted, ['lisbon']);

  const paris = (await db.doc('trips/paris').get()).data()!;
  assert.equal(paris.ownerId, 'dad');
  assert.deepEqual(paris.memberIds, ['dad']);
  assert.deepEqual(paris.memberNames, {});
  assert.deepEqual((await db.doc('trips/paris/bookings/b3').get()).get('memberIds'), ['dad']);

  assert.deepEqual((await db.doc('trips/kyoto').get()).get('memberIds'), ['mum']);
  assert.equal((await db.doc('users/guest').get()).exists, false);
  assert.deepEqual(auth.deleted, ['guest']);
});
