/**
 * Flight alerts against the Firestore emulator, with the flight provider
 * and push sending faked. Run with `npm --prefix functions run test:emulator`.
 */
import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';

import { deleteApp, initializeApp } from 'firebase-admin/app';
import { FieldValue, Firestore, getFirestore, Timestamp } from 'firebase-admin/firestore';

import {
  deletePushTokens, FlightCheckDeps, Messenger, registerPushTokenFor, runFlightChecks, syncTripFlights,
} from './flightAlerts';
import { AlertText, billingPeriod, firstCheckAt } from './flightAlertsLogic';
import { FlightProvider, FlightProviderError } from './flightProvider';
import { FlightMovement, FlightStatusName, FlightStatusResult } from './flightStatusLogic';

const PROJECT = 'demo-travary';
const MIN = 60_000;
const HOUR = 60 * MIN;
let app: ReturnType<typeof initializeApp>;
let db: Firestore;

/** 2.5 hours before BA 2037 leaves Gatwick. */
const NOW = Date.parse('2026-10-14T06:00:00Z');
const KEY = 'BA2037_2026-10-14';

function end(over: Partial<FlightMovement>): FlightMovement {
  return {
    airport: null, airportName: null, airportFullName: null, city: null,
    scheduled: null, revised: null, scheduledUtc: null, revisedUtc: null, delayMinutes: null,
    terminal: null, gate: null, checkInDesk: null, baggageBelt: null,
    ...over,
  };
}

function leg(status: FlightStatusName, lateMinutes = 0): FlightStatusResult {
  const revised = new Date(Date.parse('2026-10-14T08:30:00Z') + lateMinutes * MIN);
  return {
    number: 'BA 2037',
    airline: 'British Airways',
    status,
    departure: end({
      airport: 'LGW', airportName: 'Gatwick', city: 'London',
      scheduled: '2026-10-14T09:30', scheduledUtc: '2026-10-14T08:30:00.000Z',
      revised: new Date(revised.getTime() + HOUR).toISOString().slice(0, 16), revisedUtc: revised.toISOString(),
    }),
    arrival: end({
      airport: 'MCO', airportName: 'Orlando', city: 'Orlando',
      scheduled: '2026-10-14T14:30', scheduledUtc: '2026-10-14T18:30:00.000Z',
    }),
    updatedAt: null,
  };
}

class FakeProvider implements FlightProvider {
  readonly unitsPerLookup = 2;
  answer: FlightStatusResult[] | Error = [leg('Expected')];
  calls = 0;
  async flightLegs() {
    this.calls++;
    if (this.answer instanceof Error) throw this.answer;
    return this.answer;
  }
}

class FakeMessenger implements Messenger {
  sent: { tokens: string[]; alert: AlertText; data: Record<string, string> }[] = [];
  gone: string[] = [];
  async send(tokens: string[], alert: AlertText, data: Record<string, string>) {
    this.sent.push({ tokens: [...tokens].sort(), alert, data });
    return tokens.filter((t) => this.gone.includes(t));
  }
}

let provider: FakeProvider;
let messenger: FakeMessenger;
let clock: number;

const deps = (): FlightCheckDeps => ({
  db, provider, messenger, now: () => clock, monthlyUnits: 5000, billingDay: 1, ratePerSecond: 1000, deadlineMs: HOUR,
  sleep: async () => {},
});

const flightBooking = (members: string[], extra: Record<string, unknown> = {}) => ({
  kind: 'flight', title: 'London to Orlando', startDate: '2026-10-14', startTime: '09:30',
  location: 'London Gatwick (LGW)', details: { flightNumber: 'BA 2037' }, memberIds: members, ...extra,
});

const watch = () => db.doc(`watchedFlights/${KEY}`).get();

/** Makes the watched flight due now. */
const due = () => db.doc(`watchedFlights/${KEY}`).update({ nextCheckAt: Timestamp.fromMillis(clock) });

before(() => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Run through `npm run test:emulator`.');
  app = initializeApp({ projectId: PROJECT }, 'flight-alerts-itest');
  db = getFirestore(app);
});

after(() => deleteApp(app));

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  provider = new FakeProvider();
  messenger = new FakeMessenger();
  clock = NOW;
  // Alice and Bob's Orlando trip has a Holiday Pass; Carol's Florida trip,
  // on the same flight, is free.
  await db.doc('trips/orlando').set({
    title: 'Orlando', ownerId: 'alice', memberIds: ['alice', 'bob'], premium: { grantedBy: 'alice', until: NOW + 30 * 24 * HOUR },
  });
  await db.doc('trips/orlando/bookings/out').set(flightBooking(['alice', 'bob']));
  await db.doc('trips/orlando/bookings/hotel').set({ kind: 'stay', title: 'Hotel', startDate: '2026-10-14', memberIds: ['alice', 'bob'] });
  await db.doc('trips/florida').set({ title: 'Florida', ownerId: 'carol', memberIds: ['carol'] });
  await db.doc('trips/florida/bookings/flight').set(flightBooking(['carol']));
  for (const [uid, token] of [['alice', 'alice-phone-token-0000000'], ['bob', 'bob-phone-token-000000000'], ['carol', 'carol-phone-token-0000000']]) {
    await registerPushTokenFor(db, uid, { token, platform: 'ios' });
  }
});

test('paid trips\' flights are watched, one watch per flight however many trips are on it', async () => {
  await syncTripFlights(db, 'orlando', NOW);
  await syncTripFlights(db, 'florida', NOW);
  const w = await watch();
  assert.equal(w.get('number'), 'BA2037');
  assert.deepEqual(w.get('trips'), { orlando: { out: { from: 'LGW' } } }, 'the free trip isn\'t watched');
  assert.deepEqual(w.get('tripIds'), ['orlando']);
  assert.equal(w.get('nextCheckAt').toMillis(), firstCheckAt(Date.parse('2026-10-14T09:30:00Z'), NOW));

  // Carol gets Plus: her trip joins the same watch.
  await db.doc('users/carol').set({ plus: { expiresAt: NOW + 365 * 24 * HOUR } });
  await syncTripFlights(db, 'florida', NOW);
  assert.deepEqual((await watch()).get('tripIds').sort(), ['florida', 'orlando']);

  // The Orlando flight is deleted: Florida's watch carries on.
  await db.doc('trips/orlando/bookings/out').delete();
  await syncTripFlights(db, 'orlando', NOW);
  assert.deepEqual((await watch()).get('tripIds'), ['florida']);

  // And once nobody's on it, the watch goes.
  await db.doc('users/carol').set({ plus: FieldValue.delete() }, { merge: true });
  await syncTripFlights(db, 'florida', NOW);
  assert.equal((await watch()).exists, false);
});

test('the first answer goes on Today quietly; a delay is pushed to everyone on the trip', async () => {
  await syncTripFlights(db, 'orlando', NOW);
  await due();
  let run = await runFlightChecks(deps());
  assert.deepEqual({ checked: run.checked, alerts: run.alerts, units: run.units }, { checked: 1, alerts: 0, units: 2 });
  assert.equal(messenger.sent.length, 0, 'nothing has changed yet');
  const live = (await db.doc('trips/orlando').get()).get('liveFlights.out');
  assert.equal(live.status, 'Expected');
  assert.equal(live.checkedAt, NOW);
  assert.equal((await db.doc(`flightStatus/${KEY}`).get()).get('legs').length, 1, 'the flight page reads the same answer');
  assert.equal((await db.doc(`flightUsage/${billingPeriod(NOW, 1).id}`).get()).get('units'), 2);
  const next = (await watch()).get('nextCheckAt').toMillis();
  assert.ok(next > NOW && next <= NOW + 40 * MIN, 'checked again within 40 minutes');

  clock = next;
  provider.answer = [leg('Delayed', 45)];
  messenger.gone = ['bob-phone-token-000000000'];
  run = await runFlightChecks(deps());
  assert.equal(run.alerts, 1, 'one phone still there');
  assert.deepEqual(messenger.sent, [{
    tokens: ['alice-phone-token-0000000', 'bob-phone-token-000000000'],
    alert: { title: 'BA 2037 is delayed', body: 'Now leaves at 10:15am instead of 9:30am.', kind: 'departureTime' },
    data: { type: 'flight', tripId: 'orlando', bookingId: 'out', change: 'departureTime' },
  }]);
  assert.equal((await db.collection('pushTokens').where('uid', '==', 'bob').get()).size, 0, 'a phone that\'s gone is forgotten');
  assert.equal((await db.doc('trips/orlando').get()).get('liveFlights.out.departure.revised'), '2026-10-14T10:15');

  // The same answer again isn't news.
  clock += 30 * MIN;
  await due();
  await runFlightChecks(deps());
  assert.equal(messenger.sent.length, 1);
});

test('a trip whose pass has run out is taken off the watch and not told', async () => {
  await syncTripFlights(db, 'orlando', NOW);
  await due();
  await runFlightChecks(deps());
  await db.doc('trips/orlando').update({ premium: { grantedBy: 'alice', until: NOW + MIN } });
  clock = NOW + 10 * MIN;
  await due();
  provider.answer = [leg('Canceled')];
  await runFlightChecks(deps());
  assert.equal(messenger.sent.length, 0);
  assert.equal((await watch()).exists, false);
  assert.equal((await db.doc('trips/orlando').get()).get('liveFlights.out'), undefined, 'its live line goes too');
});

test('when the month\'s units are out, nothing is looked up and the app carries on', async () => {
  await syncTripFlights(db, 'orlando', NOW);
  await due();
  await db.doc(`flightUsage/${billingPeriod(NOW, 1).id}`).set({ units: 4960 });
  const run = await runFlightChecks(deps());
  assert.equal(run.level, 'out');
  assert.equal(provider.calls, 0);
  assert.equal((await watch()).get('nextCheckAt').toMillis(), NOW + HOUR, 'looked at again in an hour');
});

test('a failed lookup is retried soon', async () => {
  await syncTripFlights(db, 'orlando', NOW);
  await due();
  provider.answer = new FlightProviderError('unavailable', 503);
  await runFlightChecks(deps());
  const w = await watch();
  assert.equal(w.get('failures'), 1);
  assert.equal(w.get('nextCheckAt').toMillis(), NOW + 5 * MIN);
});

test('a phone belongs to whoever registered it last, and goes with their account', async () => {
  await registerPushTokenFor(db, 'dave', { token: 'alice-phone-token-0000000', platform: 'android' });
  assert.equal((await db.collection('pushTokens').where('uid', '==', 'alice').get()).size, 0);
  await deletePushTokens(db, 'dave');
  assert.equal((await db.collection('pushTokens').where('uid', '==', 'dave').get()).size, 0);
  await assert.rejects(registerPushTokenFor(db, 'dave', { token: 'short', platform: 'ios' }));
  await assert.rejects(registerPushTokenFor(db, 'dave', { token: 'a-long-enough-token-000000', platform: 'web' }));
});
