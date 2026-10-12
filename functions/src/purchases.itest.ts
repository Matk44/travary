/**
 * Purchases against the Firestore emulator, with RevenueCat faked. Run with
 * `npm --prefix functions run test:emulator`.
 */
import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';

import { deleteApp, initializeApp } from 'firebase-admin/app';
import { Firestore, getFirestore } from 'firebase-admin/firestore';

import { AccountAuth, adoptGuestTrips, deleteAccountData } from './account';
import { claimTripPassFor, hasPremium, refundTripPass, restampTrip, RevenueCatApi, syncPlusFor } from './purchases';
import { afterDay, Subscriber } from './purchasesLogic';

const PROJECT = 'demo-travary';
let app: ReturnType<typeof initializeApp>;
let db: Firestore;

class FakeRevenueCat implements RevenueCatApi {
  customers: Record<string, Subscriber> = {};
  async subscriber(uid: string) {
    return this.customers[uid] ?? {};
  }
}

const noAuth: AccountAuth = {
  verifyIdToken: async (token) => ({ uid: token.split(':')[1], firebase: { sign_in_provider: token.split(':')[0] } }),
  deleteUser: async () => {},
};

function passes(...ids: string[]): Subscriber {
  return {
    non_subscriptions: {
      holiday_pass: ids.map((id, i) => ({
        id,
        store_transaction_id: `store-${id}`,
        purchase_date: `2026-10-0${i + 1}T00:00:00Z`,
        store: 'app_store',
        is_sandbox: true,
      })),
    },
  };
}

let revenueCat: FakeRevenueCat;

/** Before every trip here, so a claimed pass still covers its trip. */
const OCT_11 = Date.parse('2026-10-11T00:00:00Z');

before(() => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Run through `npm run test:emulator`.');
  app = initializeApp({ projectId: PROJECT }, 'purchases-itest');
  db = getFirestore(app);
});

after(() => deleteApp(app));

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  revenueCat = new FakeRevenueCat();
  // Sam organises Japan (planned 2–10 Nov, a hotel to the 12th) with Mum.
  await db.doc('trips/japan').set({
    title: 'Japan', ownerId: 'sam', memberIds: ['sam', 'mum'], plannedStart: '2026-11-02', plannedEnd: '2026-11-10',
  });
  await db.doc('trips/japan/bookings/hotel').set({
    title: 'Hotel', startDate: '2026-11-05', endDate: '2026-11-12', memberIds: ['sam', 'mum'],
  });
  await db.doc('trips/lisbon').set({ title: 'Lisbon', ownerId: 'sam', memberIds: ['sam'] });
});

test('a Holiday Pass is claimed for the trip\'s own dates and unlocks it for everyone on it', async () => {
  revenueCat.customers.sam = passes('rc1');
  // The app only names the trip: the dates come from Firestore.
  assert.deepEqual(await claimTripPassFor(db, revenueCat, 'sam', 'japan', 'store-rc1'), {
    start: '2026-11-02', end: '2026-11-12',
  });

  const claim = (await db.doc('tripPasses/rc1').get()).data()!;
  assert.equal(claim.uid, 'sam');
  assert.equal(claim.tripId, 'japan');
  assert.deepEqual((await db.doc('users/sam').get()).get('tripPasses'), {
    japan: { start: '2026-11-02', end: '2026-11-12' },
  });
  assert.deepEqual((await db.doc('trips/japan').get()).get('premium'), {
    grantedBy: 'sam', until: afterDay('2026-11-19'),
  });

  // Retrying is harmless and doesn't use up another pass.
  revenueCat.customers.sam = passes('rc1', 'rc2');
  await claimTripPassFor(db, revenueCat, 'sam', 'japan', 'store-rc2', OCT_11);
  assert.equal((await db.doc('tripPasses/rc2').get()).exists, false);
});

test('a pass that no longer covers its trip doesn\'t swallow a new one', async () => {
  revenueCat.customers.sam = passes('rc1');
  await claimTripPassFor(db, revenueCat, 'sam', 'japan', 'store-rc1', OCT_11);
  // Brought forward to October: before the dates the pass was bought for,
  // so it doesn't cover it, and a new pass can be bought for the new dates.
  await db.doc('trips/japan/bookings/hotel').delete();
  await db.doc('trips/japan').update({ plannedStart: '2026-10-20', plannedEnd: '2026-10-25' });
  await restampTrip(db, 'japan');
  assert.equal((await db.doc('trips/japan').get()).get('premium'), undefined);

  revenueCat.customers.sam = passes('rc1', 'rc2');
  assert.deepEqual(await claimTripPassFor(db, revenueCat, 'sam', 'japan', 'store-rc2', OCT_11), {
    start: '2026-10-20', end: '2026-10-25',
  });
  assert.equal((await db.doc('tripPasses/rc2').get()).get('tripId'), 'japan');
  assert.deepEqual((await db.doc('trips/japan').get()).get('premium'), {
    grantedBy: 'sam', until: afterDay('2026-11-01'),
  });
});

test('one pass covers one trip, and only someone on it can claim', async () => {
  revenueCat.customers.sam = passes('rc1');
  await claimTripPassFor(db, revenueCat, 'sam', 'japan', 'store-rc1');
  await db.doc('trips/lisbon').update({ plannedStart: '2026-12-01' });
  await assert.rejects(
    claimTripPassFor(db, revenueCat, 'sam', 'lisbon', 'store-rc1'),
    /couldn't find an unused Holiday Pass/,
  );

  revenueCat.customers.stranger = passes('rc9');
  await assert.rejects(claimTripPassFor(db, revenueCat, 'stranger', 'japan', 'store-rc9'), /not on this trip/);
  await assert.rejects(claimTripPassFor(db, revenueCat, 'sam', 'nowhere', 'x'), /not on this trip/);
});

test('a trip with no dates can\'t take a pass yet, and the pass stays unclaimed', async () => {
  revenueCat.customers.sam = passes('rc1');
  await assert.rejects(claimTripPassFor(db, revenueCat, 'sam', 'lisbon', 'store-rc1'), /dates first/);
  assert.equal((await db.doc('tripPasses/rc1').get()).exists, false);
});

test('restamping follows the trip: a pass grows with its holiday, and the organiser\'s Plus covers it', async () => {
  revenueCat.customers.sam = passes('rc1');
  await claimTripPassFor(db, revenueCat, 'sam', 'japan', 'store-rc1');

  await db.doc('trips/japan/bookings/flight-home').set({ title: 'Flight home', startDate: '2026-11-14', memberIds: [] });
  await restampTrip(db, 'japan');
  assert.equal((await db.doc('trips/japan').get()).get('premium.until'), afterDay('2026-11-21'));

  const expires = Date.parse('2027-10-07T00:00:00Z');
  revenueCat.customers.sam = {
    ...passes('rc1'),
    entitlements: { plus: { expires_date: new Date(expires).toISOString(), product_identifier: 'travary_annual_pass' } },
  };
  assert.deepEqual(await syncPlusFor(db, revenueCat, 'sam', Date.parse('2026-10-07T00:00:00Z')), { plus: true });
  assert.equal((await db.doc('users/sam').get()).get('plus.expiresAt'), expires);
  assert.deepEqual((await db.doc('trips/lisbon').get()).get('premium'), { grantedBy: 'sam', until: expires });
  assert.equal((await db.doc('trips/japan').get()).get('premium.until'), expires);

  // Lapsed: the mirror goes, and the pass alone covers Japan again.
  revenueCat.customers.sam = passes('rc1');
  assert.deepEqual(await syncPlusFor(db, revenueCat, 'sam'), { plus: false });
  assert.equal((await db.doc('users/sam').get()).get('plus'), undefined);
  assert.equal((await db.doc('trips/lisbon').get()).get('premium'), undefined);
  assert.equal((await db.doc('trips/japan').get()).get('premium.until'), afterDay('2026-11-21'));
});

test('a guest\'s passes move with them; a deleted account\'s passes go', async () => {
  await db.doc('trips/japan').update({ ownerId: 'guest', memberIds: ['guest', 'mum'] });
  revenueCat.customers.guest = passes('rc1');
  await claimTripPassFor(db, revenueCat, 'guest', 'japan', 'store-rc1');

  await adoptGuestTrips(db, noAuth, 'me', 'anonymous:guest');
  assert.equal((await db.doc('tripPasses/rc1').get()).get('uid'), 'me');
  assert.deepEqual((await db.doc('users/me').get()).get('tripPasses.japan'), { start: '2026-11-02', end: '2026-11-12' });
  assert.equal((await db.doc('trips/japan').get()).get('premium.grantedBy'), 'me');

  await deleteAccountData(db, noAuth, async () => {}, 'me');
  assert.equal((await db.doc('tripPasses/rc1').get()).exists, false);
  const japan = await db.doc('trips/japan').get();
  assert.deepEqual(japan.get('memberIds'), ['mum']);
  assert.equal(japan.get('premium'), undefined);
});

test('a refunded Holiday Pass stops counting; a refund taken back restores it', async () => {
  revenueCat.customers.sam = passes('rc1');
  await claimTripPassFor(db, revenueCat, 'sam', 'japan', 'store-rc1', OCT_11);
  assert.deepEqual(await refundTripPass(db, 'store-rc1', false), ['japan']);
  assert.equal((await db.doc('trips/japan').get()).get('premium'), undefined);
  assert.equal((await db.doc('users/sam').get()).get('tripPasses.japan'), undefined);
  assert.ok((await db.doc('tripPasses/rc1').get()).get('refundedAt'));
  // It can't be claimed again for another trip.
  await db.doc('trips/lisbon').update({ plannedStart: '2026-12-01' });
  await assert.rejects(claimTripPassFor(db, revenueCat, 'sam', 'lisbon', 'store-rc1', OCT_11), /unused Holiday Pass/);

  await refundTripPass(db, 'store-rc1', true);
  assert.deepEqual((await db.doc('trips/japan').get()).get('premium'), { grantedBy: 'sam', until: afterDay('2026-11-19') });
  assert.deepEqual((await db.doc('users/sam').get()).get('tripPasses.japan'), { start: '2026-11-02', end: '2026-11-12' });

  // Nobody's pass matches: nothing changes.
  assert.deepEqual(await refundTripPass(db, 'store-unknown', false), []);
});

test('premium on the server: the mirror, the trip\'s stamp for its members, else the store itself', async () => {
  assert.equal(await hasPremium(db, revenueCat, 'mum', 'japan', OCT_11), false);

  revenueCat.customers.sam = passes('rc1');
  await claimTripPassFor(db, revenueCat, 'sam', 'japan', 'store-rc1', OCT_11);
  assert.equal(await hasPremium(db, null, 'mum', 'japan', OCT_11), true, 'Plus travels with the trip');
  assert.equal(await hasPremium(db, null, 'mum', 'lisbon', OCT_11), false);
  assert.equal(await hasPremium(db, null, 'mum', undefined, OCT_11), false);

  // An Annual Pass bought moments ago, before its mirror: the store says so, and it's mirrored.
  const expires = Date.parse('2027-10-07T00:00:00Z');
  revenueCat.customers.mum = {
    entitlements: { plus: { expires_date: new Date(expires).toISOString(), product_identifier: 'travary_annual_pass' } },
  };
  assert.equal(await hasPremium(db, revenueCat, 'mum', 'lisbon', OCT_11), true);
  assert.equal((await db.doc('users/mum').get()).get('plus.expiresAt'), expires);

  await db.doc('users/tester').set({ tester: true });
  assert.equal(await hasPremium(db, null, 'tester', undefined, OCT_11), true);
});
