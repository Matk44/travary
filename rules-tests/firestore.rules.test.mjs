// Firestore rules: the visual profile is server-only; theme and themeSource
// stay the traveller's. Run with `npm --prefix rules-tests test`.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';

import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { deleteField, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-travary',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(() => env.cleanup());

const profile = {
  schemaVersion: 1,
  primaryTheme: 'urban_heritage',
  secondaryThemes: [],
  setting: 'urban',
  moods: ['cultural'],
  location: { countryCode: 'JP', city: 'Kyoto', confidence: 0.9, verificationStatus: 'verified', placeId: 'p1' },
  confidence: 0.9,
  evidence: ['City break'],
  sourceHash: 'a'.repeat(64),
};

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (admin) => {
    await setDoc(doc(admin.firestore(), 'trips/t1'), {
      title: 'Kyoto',
      theme: 'urban_heritage',
      themeSource: 'auto',
      ownerId: 'alice',
      memberIds: ['alice', 'bob'],
      visualProfile: profile,
      visualProfileUpdatedAt: serverTimestamp(),
      visualProfileRequest: { hash: 'a'.repeat(64), by: 'alice' },
    });
  });
});

const db = (uid) => env.authenticatedContext(uid).firestore();
const newTrip = (uid, extra = {}) => ({
  title: 'Lisbon',
  theme: 'classic_travel',
  themeSource: 'auto',
  ownerId: uid,
  memberIds: [uid],
  createdAt: 1,
  updatedAt: 1,
  ...extra,
});

test('members read the stored profile', async () => {
  await assertSucceeds(getDoc(doc(db('bob'), 'trips/t1')));
  await assertFails(getDoc(doc(db('mallory'), 'trips/t1')));
});

test('members can pick a manual look or go back to automatic', async () => {
  await assertSucceeds(updateDoc(doc(db('bob'), 'trips/t1'), { theme: 'alpine', themeSource: 'manual', updatedAt: 2 }));
  await assertSucceeds(updateDoc(doc(db('alice'), 'trips/t1'), { themeSource: 'auto', updatedAt: 3 }));
  // An old app's edit without themeSource still works.
  await assertSucceeds(updateDoc(doc(db('alice'), 'trips/t1'), { title: 'Kyoto & Osaka', theme: 'city', updatedAt: 4 }));
});

test('a trip can be created with a look but never with a profile', async () => {
  await assertSucceeds(setDoc(doc(db('carol'), 'trips/t2'), newTrip('carol')));
  await assertSucceeds(setDoc(doc(db('carol'), 'trips/t3'), newTrip('carol', { theme: 'cruise', themeSource: 'manual' })));
  for (const field of ['visualProfile', 'visualProfileUpdatedAt', 'visualProfileRequest']) {
    const value = field === 'visualProfile' ? profile : field === 'visualProfileUpdatedAt' ? serverTimestamp() : { hash: 'x' };
    await assertFails(setDoc(doc(db('carol'), `trips/bad_${field}`), newTrip('carol', { [field]: value })));
  }
});

test('the app can\'t write, change or delete the visual profile', async () => {
  const trip = doc(db('alice'), 'trips/t1');
  await assertFails(updateDoc(trip, { visualProfile: { ...profile, primaryTheme: 'cruise' } }));
  await assertFails(updateDoc(trip, { 'visualProfile.primaryTheme': 'cruise' }));
  await assertFails(updateDoc(trip, { 'visualProfile.location.city': 'Tokyo' }));
  await assertFails(updateDoc(trip, { visualProfile: deleteField() }));
  await assertFails(updateDoc(trip, { visualProfileUpdatedAt: serverTimestamp() }));
  await assertFails(updateDoc(trip, { visualProfileRequest: { hash: 'b'.repeat(64) } }));
  await assertFails(updateDoc(trip, { visualProfileRequest: deleteField() }));
});

test('only valid looks are accepted', async () => {
  const trip = doc(db('alice'), 'trips/t1');
  await assertFails(updateDoc(trip, { themeSource: 'server' }));
  await assertFails(updateDoc(trip, { themeSource: 1 }));
  await assertFails(updateDoc(trip, { theme: 42 }));
  await assertFails(updateDoc(trip, { theme: 'x'.repeat(41) }));
  await assertFails(setDoc(doc(db('carol'), 'trips/t4'), newTrip('carol', { themeSource: 'robot' })));
});

test('non-members can\'t change a trip\'s look', async () => {
  await assertFails(updateDoc(doc(db('mallory'), 'trips/t1'), { theme: 'alpine', themeSource: 'manual' }));
});

test('existing protections are unchanged', async () => {
  const trip = doc(db('bob'), 'trips/t1');
  await assertFails(updateDoc(trip, { premium: { plan: 'plus' } }));
  await assertFails(updateDoc(trip, { memberIds: ['bob'] }));
  await assertFails(updateDoc(trip, { ownerId: 'bob' }));
  await assertFails(updateDoc(trip, { memberNames: { bob: 'Bob' } }));
});

test('members can set, change or remove where the trip goes', async () => {
  const trip = doc(db('bob'), 'trips/t1');
  const kyoto = { countryCode: 'JP', countryName: 'Japan', region: 'Kansai', regionSlug: 'kansai', city: 'Kyoto', citySlug: 'kyoto' };
  await assertSucceeds(updateDoc(trip, { destination: kyoto, updatedAt: 2 }));
  await assertSucceeds(updateDoc(trip, { destination: { countryCode: 'JP', countryName: 'Japan' }, updatedAt: 3 }));
  await assertSucceeds(updateDoc(trip, { destination: null, updatedAt: 4 }));
  await assertSucceeds(setDoc(doc(db('carol'), 'trips/t5'), newTrip('carol', { destination: kyoto })));
});

test('only a well-formed destination is accepted', async () => {
  const trip = doc(db('bob'), 'trips/t1');
  await assertFails(updateDoc(trip, { destination: 'Japan' }));
  await assertFails(updateDoc(trip, { destination: { countryName: 'Japan' } }));
  await assertFails(updateDoc(trip, { destination: { countryCode: 'jp', countryName: 'Japan' } }));
  await assertFails(updateDoc(trip, { destination: { countryCode: 'JP', countryName: 'x'.repeat(121) } }));
  await assertFails(updateDoc(trip, { destination: { countryCode: 'JP', countryName: 'Japan', notes: 'secret' } }));
  await assertFails(updateDoc(trip, { destination: { countryCode: 'JP', countryName: 'Japan', city: 7 } }));
  await assertFails(updateDoc(doc(db('mallory'), 'trips/t1'), { destination: { countryCode: 'JP', countryName: 'Japan' } }));
});

test('members tick, add and remove checklist items one at a time', async () => {
  const item = { text: 'Apply for the visa', done: false, due: '2026-10-01', createdAt: 1 };
  await assertSucceeds(updateDoc(doc(db('bob'), 'trips/t1'), { 'checklist.c1': item }));
  await assertSucceeds(updateDoc(doc(db('alice'), 'trips/t1'), { 'checklist.c2': { ...item, text: 'Dog sitter' } }));
  await assertSucceeds(updateDoc(doc(db('bob'), 'trips/t1'), { 'checklist.c1.done': true }));
  const stored = (await getDoc(doc(db('alice'), 'trips/t1'))).data().checklist;
  if (!stored.c1.done || stored.c2.text !== 'Dog sitter') throw new Error('an item was lost');
  await assertSucceeds(updateDoc(doc(db('alice'), 'trips/t1'), { 'checklist.c1': deleteField() }));
  await assertSucceeds(setDoc(doc(db('carol'), 'trips/t6'), newTrip('carol', { checklist: { c1: item } })));
});

test('a checklist is a map, of at most 100 items, for members only', async () => {
  const trip = doc(db('bob'), 'trips/t1');
  await assertFails(updateDoc(trip, { checklist: ['Apply for the visa'] }));
  const many = Object.fromEntries(Array.from({ length: 101 }, (_, i) => [`c${i}`, { text: 'x', done: false, createdAt: 1 }]));
  await assertFails(updateDoc(trip, { checklist: many }));
  await assertFails(updateDoc(doc(db('mallory'), 'trips/t1'), { 'checklist.c1': { text: 'x', done: false, createdAt: 1 } }));
});

test('the packing list: members tick and add items one at a time; a map of at most 100', async () => {
  const item = { text: 'Sun cream', done: false, createdAt: 1 };
  await assertSucceeds(updateDoc(doc(db('bob'), 'trips/t1'), { 'packing.p1': item }));
  await assertSucceeds(updateDoc(doc(db('alice'), 'trips/t1'), { 'packing.p1.done': true }));
  await assertSucceeds(updateDoc(doc(db('alice'), 'trips/t1'), { 'packing.p1': deleteField() }));
  const trip = doc(db('bob'), 'trips/t1');
  await assertFails(updateDoc(trip, { packing: ['Sun cream'] }));
  const many = Object.fromEntries(Array.from({ length: 101 }, (_, i) => [`p${i}`, item]));
  await assertFails(updateDoc(trip, { packing: many }));
  await assertFails(updateDoc(doc(db('mallory'), 'trips/t1'), { 'packing.p1': item }));
});

test('purchases are the server\'s: travellers read their own mirror and nothing else', async () => {
  await env.withSecurityRulesDisabled(async (admin) => {
    await setDoc(doc(admin.firestore(), 'users/bob'), { tripPasses: { t1: { start: '2026-11-02', end: '2026-11-12' } } });
    await setDoc(doc(admin.firestore(), 'tripPasses/rc1'), { uid: 'bob', tripId: 't1' });
  });
  await assertSucceeds(getDoc(doc(db('bob'), 'users/bob')));
  await assertFails(getDoc(doc(db('alice'), 'users/bob')));
  await assertFails(setDoc(doc(db('bob'), 'users/bob'), { plus: { expiresAt: 4102444800000 } }));
  await assertFails(updateDoc(doc(db('bob'), 'users/bob'), { 'tripPasses.t2': { start: '2026-01-01', end: '2026-12-31' } }));
  await assertFails(getDoc(doc(db('bob'), 'tripPasses/rc1')));
  await assertFails(setDoc(doc(db('bob'), 'tripPasses/rc2'), { uid: 'bob', tripId: 't1' }));
  await assertFails(updateDoc(doc(db('bob'), 'trips/t1'), { premium: { grantedBy: 'bob', until: 4102444800000 } }));
});

test('onboarding: travellers record their own completion, and nothing else on users/{uid}', async () => {
  const done = () => ({ onboardingCompleted: true, onboardingCompletedAt: serverTimestamp() });
  // A new account has no document yet; a merge creates it.
  await assertSucceeds(setDoc(doc(db('carol'), 'users/carol'), done(), { merge: true }));
  await assertSucceeds(getDoc(doc(db('carol'), 'users/carol')));
  // Next to the server's purchases, and again (another sign-in).
  await env.withSecurityRulesDisabled(async (admin) => {
    await setDoc(doc(admin.firestore(), 'users/dave'), { plus: { expiresAt: 4102444800000, willRenew: true } });
  });
  await assertSucceeds(setDoc(doc(db('dave'), 'users/dave'), done(), { merge: true }));
  await assertSucceeds(setDoc(doc(db('dave'), 'users/dave'), done(), { merge: true }));
  // Only true, only the server's clock, only these fields, only their own.
  await assertFails(setDoc(doc(db('erin'), 'users/erin'), { onboardingCompleted: false, onboardingCompletedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('erin'), 'users/erin'), { onboardingCompleted: true, onboardingCompletedAt: new Date(0) }));
  await assertFails(setDoc(doc(db('erin'), 'users/erin'), { ...done(), plus: { expiresAt: 4102444800000 } }));
  await assertFails(setDoc(doc(db('dave'), 'users/dave'), { ...done(), smartImport: { total: 0 } }, { merge: true }));
  await assertFails(updateDoc(doc(db('dave'), 'users/dave'), { 'plus.expiresAt': 1 }));
  await assertFails(setDoc(doc(db('mallory'), 'users/carol'), done(), { merge: true }));
});

test('flight alerts are the server\'s: members read their flights\' live state, nobody writes it', async () => {
  const live = { status: 'Delayed', number: 'BA 2037', checkedAt: 1 };
  await env.withSecurityRulesDisabled(async (admin) => {
    await updateDoc(doc(admin.firestore(), 'trips/t1'), { 'liveFlights.b1': live });
    await setDoc(doc(admin.firestore(), 'watchedFlights/BA2037_2026-10-14'), { number: 'BA2037', tripIds: ['t1'] });
    await setDoc(doc(admin.firestore(), 'pushTokens/abc'), { uid: 'bob', token: 'secret' });
  });
  const trip = (await getDoc(doc(db('bob'), 'trips/t1'))).data();
  if (trip.liveFlights.b1.status !== 'Delayed') throw new Error('members read the live state');
  await assertFails(updateDoc(doc(db('bob'), 'trips/t1'), { 'liveFlights.b1.status': 'Landed' }));
  await assertFails(updateDoc(doc(db('bob'), 'trips/t1'), { liveFlights: deleteField() }));
  await assertFails(setDoc(doc(db('carol'), 'trips/t9'), newTrip('carol', { liveFlights: { b1: live } })));
  for (const path of ['watchedFlights/BA2037_2026-10-14', 'pushTokens/abc', 'flightUsage/2026-10-01', 'config/flightAlerts']) {
    await assertFails(getDoc(doc(db('bob'), path)));
    await assertFails(setDoc(doc(db('bob'), path), { uid: 'bob' }));
  }
});

test('the free plan\'s numbers: every signed-in phone reads them, nobody writes them', async () => {
  await env.withSecurityRulesDisabled(async (admin) => {
    await setDoc(doc(admin.firestore(), 'config/freePlan'), { bookingsPerHoliday: 12 });
  });
  const limits = (await getDoc(doc(db('mallory'), 'config/freePlan'))).data();
  if (limits.bookingsPerHoliday !== 12) throw new Error('signed-in phones read the free plan');
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'config/freePlan')));
  await assertFails(setDoc(doc(db('bob'), 'config/freePlan'), { bookingsPerHoliday: 1000 }));
  await assertFails(updateDoc(doc(db('bob'), 'config/freePlan'), { bookingsPerHoliday: 1000 }));
  await assertFails(getDoc(doc(db('bob'), 'config/flightAlerts')));
});
