/**
 * The Firestore store against the Firestore emulator (transactions, field
 * paths, server timestamps). Run with `npm --prefix functions run
 * test:emulator`, which starts the emulator for a demo project.
 */
import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';

import { deleteApp, initializeApp } from 'firebase-admin/app';
import { Firestore, getFirestore, Timestamp } from 'firebase-admin/firestore';

import { classifyTripVisualsHandler } from './classifyTripVisuals';
import { PLACES_COORDINATE_TTL_MS } from './locationResolver';
import { VisualProfile } from './visualProfileSchema';
import {
  AccessError, DAILY_CLASSIFICATIONS, FirestoreVisualProfileStore, purgeExpiredCoordinates, RateLimitError,
  TRIP_COOLDOWN_MS,
} from './visualProfileStore';

const PROJECT = 'demo-travary';
const NOW = 1_800_000_000_000;

let app: ReturnType<typeof initializeApp>;
let db: Firestore;
let store: FirestoreVisualProfileStore;

before(() => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Run through `npm run test:emulator`.');
  app = initializeApp({ projectId: PROJECT }, 'store-itest');
  db = getFirestore(app);
  store = new FirestoreVisualProfileStore(db);
});

after(() => deleteApp(app));

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  await db.doc('trips/t1').set({ title: 'Kyoto', theme: 'classic_travel', themeSource: 'auto', memberIds: ['me', 'mum'], ownerId: 'me' });
});

const profile = (hash: string, overrides: Partial<VisualProfile> = {}): VisualProfile => ({
  schemaVersion: 1,
  primaryTheme: 'urban_heritage',
  secondaryThemes: [],
  setting: 'urban',
  moods: ['cultural'],
  location: { countryCode: 'JP', city: 'Kyoto', citySlug: 'kyoto', locationQuery: 'Kyoto, Japan', confidence: 0.9, verificationStatus: 'verified', placeId: 'p1', latitude: 35, longitude: 135, coordinatesExpireAt: NOW + PLACES_COORDINATE_TTL_MS },
  confidence: 0.9,
  evidence: ['City break'],
  sourceHash: hash,
  ...overrides,
});

const HASH_A = 'a'.repeat(64);
const HASH_B = 'b'.repeat(64);

test('reserve counts the day, records the request and enforces the cooldown', async () => {
  await store.reserve({ uid: 'me', tripId: 't1', sourceHash: HASH_A, nowMs: NOW });
  const trip = await db.doc('trips/t1').get();
  assert.equal(trip.get('visualProfileRequest.hash'), HASH_A);
  assert.equal((trip.get('visualProfileRequest.at') as Timestamp).toMillis(), NOW);
  assert.equal(trip.get('visualProfileRequest.by'), 'me');
  const user = await db.doc('users/me').get();
  assert.deepEqual(user.get('visualClassification'), { day: new Date(NOW).toISOString().slice(0, 10), today: 1, total: 1 });

  await assert.rejects(
    store.reserve({ uid: 'mum', tripId: 't1', sourceHash: HASH_B, nowMs: NOW + 1000 }),
    (e: unknown) => e instanceof RateLimitError && e.reason === 'cooldown' && e.retryAfterMs === TRIP_COOLDOWN_MS - 1000,
  );
  await store.reserve({ uid: 'mum', tripId: 't1', sourceHash: HASH_B, nowMs: NOW + TRIP_COOLDOWN_MS });
  assert.equal((await db.doc('trips/t1').get()).get('visualProfileRequest.hash'), HASH_B);
});

test('reserve enforces the daily limit per traveller and resets each day', async () => {
  const day = new Date(NOW).toISOString().slice(0, 10);
  await db.doc('users/me').set({ visualClassification: { day, today: DAILY_CLASSIFICATIONS, total: 50 }, smartImport: { total: 3 } });
  await assert.rejects(store.reserve({ uid: 'me', tripId: 't1', sourceHash: HASH_A, nowMs: NOW }),
    (e: unknown) => e instanceof RateLimitError && e.reason === 'daily');
  await store.reserve({ uid: 'me', tripId: 't1', sourceHash: HASH_A, nowMs: NOW + 24 * 3600 * 1000 });
  const user = await db.doc('users/me').get();
  assert.equal(user.get('visualClassification.today'), 1);
  assert.equal(user.get('visualClassification.total'), 51);
  assert.equal(user.get('smartImport.total'), 3, 'other usage is untouched');
});

test('reserve and save refuse non-members and missing trips', async () => {
  await assert.rejects(store.reserve({ uid: 'x', tripId: 't1', sourceHash: HASH_A, nowMs: NOW }),
    (e: unknown) => e instanceof AccessError && e.reason === 'not_member');
  await assert.rejects(store.reserve({ uid: 'me', tripId: 'nope', sourceHash: HASH_A, nowMs: NOW }),
    (e: unknown) => e instanceof AccessError && e.reason === 'missing');
  await assert.rejects(store.save({ uid: 'x', tripId: 't1', profile: profile(HASH_A) }), AccessError);
});

test('save stores the profile and updates an automatic trip\'s theme', async () => {
  await store.reserve({ uid: 'me', tripId: 't1', sourceHash: HASH_A, nowMs: NOW });
  assert.equal(await store.save({ uid: 'me', tripId: 't1', profile: profile(HASH_A) }), 'saved');
  const trip = await db.doc('trips/t1').get();
  assert.deepEqual(trip.get('visualProfile'), profile(HASH_A));
  assert.ok(trip.get('visualProfileUpdatedAt') instanceof Timestamp);
  assert.equal(trip.get('theme'), 'urban_heritage');
  assert.equal(trip.get('themeSource'), 'auto');
  assert.equal(trip.get('title'), 'Kyoto');
});

test('save never touches a manual theme', async () => {
  await db.doc('trips/t1').update({ theme: 'alpine', themeSource: 'manual' });
  await store.reserve({ uid: 'me', tripId: 't1', sourceHash: HASH_A, nowMs: NOW });
  await store.save({ uid: 'me', tripId: 't1', profile: profile(HASH_A) });
  const trip = await db.doc('trips/t1').get();
  assert.equal(trip.get('theme'), 'alpine');
  assert.equal(trip.get('themeSource'), 'manual');
  assert.equal(trip.get('visualProfile.primaryTheme'), 'urban_heritage');
});

test('a result overtaken by a newer request is not saved', async () => {
  await store.reserve({ uid: 'me', tripId: 't1', sourceHash: HASH_A, nowMs: NOW });
  await store.reserve({ uid: 'mum', tripId: 't1', sourceHash: HASH_B, nowMs: NOW + TRIP_COOLDOWN_MS });
  assert.equal(await store.save({ uid: 'me', tripId: 't1', profile: profile(HASH_A) }), 'superseded');
  const trip = await db.doc('trips/t1').get();
  assert.equal(trip.get('visualProfile'), undefined);
  assert.equal(trip.get('theme'), 'classic_travel');
});

test('syncAutomaticTheme applies only to automatic trips', async () => {
  await store.syncAutomaticTheme({ uid: 'me', tripId: 't1', primaryTheme: 'alpine' });
  assert.equal((await db.doc('trips/t1').get()).get('theme'), 'alpine');
  await db.doc('trips/t1').update({ theme: 'cruise', themeSource: 'manual' });
  await store.syncAutomaticTheme({ uid: 'me', tripId: 't1', primaryTheme: 'alpine' });
  assert.equal((await db.doc('trips/t1').get()).get('theme'), 'cruise');
});

test('expired Places coordinates are purged, place IDs kept', async () => {
  await db.doc('trips/old').set({ memberIds: ['me'], visualProfile: profile(HASH_A, {
    location: { ...profile(HASH_A).location, coordinatesExpireAt: NOW - 1 },
  }) });
  await db.doc('trips/new').set({ memberIds: ['me'], visualProfile: profile(HASH_B) });
  assert.equal(await purgeExpiredCoordinates(db, NOW, 1), 1);
  const old = await db.doc('trips/old').get();
  assert.equal(old.get('visualProfile.location.latitude'), undefined);
  assert.equal(old.get('visualProfile.location.longitude'), undefined);
  assert.equal(old.get('visualProfile.location.coordinatesExpireAt'), undefined);
  assert.equal(old.get('visualProfile.location.placeId'), 'p1');
  assert.equal(old.get('visualProfile.location.city'), 'Kyoto');
  assert.equal((await db.doc('trips/new').get()).get('visualProfile.location.latitude'), 35);
  assert.equal(await purgeExpiredCoordinates(db, NOW), 0);
});

test('the handler works end to end on Firestore', async () => {
  let calls = 0;
  const deps = {
    store,
    classify: async () => {
      calls++;
      return {
        raw: {
          primaryTheme: 'urban_heritage', secondaryThemes: [], setting: 'urban', moods: ['cultural'],
          location: { countryCode: 'JP', city: 'Kyoto', locationQuery: 'Kyoto, Japan', confidence: 0.9 },
          confidence: 0.9, evidence: ['City break'],
        },
        model: 'gemini-test',
        attempts: 1,
      };
    },
    resolver: { resolve: async () => ({ status: 'none' as const }) },
    now: () => NOW,
    log: { info: () => {}, warn: () => {}, error: () => {} },
  };
  const data = { tripId: 't1', tripTitle: 'Kyoto', bookings: [{ id: 'b1', kind: 'stay', title: 'Ryokan', startDate: '2027-04-05', endDate: '2027-04-08' }] };
  const first = await classifyTripVisualsHandler('me', data, deps);
  assert.equal(first.cached, false);
  assert.equal(first.profile.location.verificationStatus, 'unverified');
  const second = await classifyTripVisualsHandler('mum', data, deps);
  assert.equal(second.cached, true);
  assert.deepEqual(second.profile, first.profile);
  assert.equal(calls, 1);
  assert.equal((await db.doc('trips/t1').get()).get('theme'), 'urban_heritage');
});
