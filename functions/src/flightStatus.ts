import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/https';

import {
  cacheLifetimeMs,
  cleanAirport,
  cleanFlightDate,
  cleanFlightNumber,
  FlightStatusResult,
  normaliseFlightLegs,
  pickLeg,
} from './flightStatusLogic';
import { aeroDataBoxKey } from './params';

/** AeroDataBox through API.Market (where the key was issued). */
const GATEWAY = 'https://prod.api.market/api/v1/aedbx/aerodatabox';

/**
 * Lookups per traveller per day that miss the shared cache. Protects the
 * AeroDataBox allowance; a family checking its flights stays far below it.
 */
const DAILY_LIMIT = 40;

/**
 * One flight number on one day: its schedule (filling in a new flight) and,
 * close to the day, its live status (gate, terminal, check-in desk, baggage
 * belt and delays). Returns the traveller's leg and every leg. Answers are cached in `flightStatus/{number_date}`
 * (server-only) and shared by everyone on that flight.
 */
export const flightStatus = onCall(
  { secrets: [aeroDataBoxKey], timeoutSeconds: 30, maxInstances: 10 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to check your flight.');
    const data = (request.data ?? {}) as Record<string, unknown>;
    const number = cleanFlightNumber(data.flightNumber);
    if (!number) throw new HttpsError('invalid-argument', 'That doesn\'t look like a flight number.');
    const nowMs = Date.now();
    const date = cleanFlightDate(data.date, nowMs);
    if (!date) throw new HttpsError('invalid-argument', 'Flights can be looked up up to a year ahead.');
    const from = cleanAirport(data.from);

    const db = getFirestore();
    const ref = db.collection('flightStatus').doc(`${number}_${date}`);
    const cached = await ref.get();
    if (cached.exists) {
      const legs = (cached.get('legs') ?? []) as FlightStatusResult[];
      const checkedAt = (cached.get('checkedAt') as Timestamp).toMillis();
      if (nowMs - checkedAt < cacheLifetimeMs(pickLeg(legs, from), nowMs)) {
        return { flight: pickLeg(legs, from), legs, checkedAt: new Date(checkedAt).toISOString() };
      }
    }

    await reserveDailyLookup(uid);
    const legs = normaliseFlightLegs(await fetchFlight(number, date));
    await ref.set({ legs, checkedAt: Timestamp.fromMillis(nowMs) });
    return { flight: pickLeg(legs, from), legs, checkedAt: new Date(nowMs).toISOString() };
  },
);

async function fetchFlight(number: string, date: string): Promise<unknown> {
  // The date is the day it leaves (the ticket's date, the form's "Flying
  // on"), not one it might land on.
  const url = `${GATEWAY}/flights/number/${number}/${date}?withAircraftImage=false&withLocation=false&dateLocalRole=Departure`;
  for (let attempt = 1; ; attempt++) {
    const started = Date.now();
    const response = await fetch(url, {
      headers: { 'x-api-market-key': aeroDataBoxKey.value(), Accept: 'application/json' },
    });
    // Status and timing only: which flight someone takes stays out of the logs.
    logger.info('flight_status', { http: response.status, ms: Date.now() - started, attempt });
    if (response.status === 204 || response.status === 404) return [];
    if (response.ok) return response.json();
    // The free plan allows one request a second.
    if (response.status === 429 && attempt < 3) {
      await new Promise((resolve) => setTimeout(resolve, 1100 * attempt));
      continue;
    }
    if (response.status === 400) {
      throw new HttpsError('invalid-argument', 'That flight couldn\'t be found on that day.');
    }
    logger.error('flight_status_failed', { http: response.status, detail: (await response.text()).slice(0, 300) });
    throw new HttpsError('unavailable', 'Live flight status isn\'t available right now. Try again soon.');
  }
}

async function reserveDailyLookup(uid: string): Promise<void> {
  const db = getFirestore();
  const ref = db.collection('users').doc(uid);
  const day = new Date().toISOString().slice(0, 10);
  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const usage = (snapshot.get('flightStatus') ?? {}) as { day?: string; today?: number };
    const today = usage.day === day ? usage.today ?? 0 : 0;
    if (today >= DAILY_LIMIT) {
      throw new HttpsError('resource-exhausted', 'That\'s a lot of flight checks for one day. Try again tomorrow.');
    }
    tx.set(ref, { flightStatus: { day, today: today + 1 } }, { merge: true });
  });
}
