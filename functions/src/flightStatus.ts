import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/https';

import { billingPeriod } from './flightAlertsLogic';
import { aeroDataBox, FlightProviderError } from './flightProvider';
import {
  cacheLifetimeMs,
  cleanAirport,
  cleanFlightDate,
  cleanFlightNumber,
  FlightStatusResult,
  pickLeg,
} from './flightStatusLogic';
import { recordFlightUnits } from './flightUsage';
import { aeroDataBoxKey, flightBillingDay } from './params';

/**
 * Lookups per traveller per day that miss the shared cache. Protects the
 * AeroDataBox allowance; a family checking its flights stays far below it.
 */
const DAILY_LIMIT = 40;

/**
 * One flight number on one day: its schedule (filling in a new flight) and,
 * close to the day, its live status (gate, terminal, check-in desk, baggage
 * belt and delays). Returns the traveller's leg and every leg. Answers are cached in `flightStatus/{number_date}`
 * (server-only) and shared by everyone on that flight; flight alerts keep
 * the cache fresh for the flights they watch.
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
    if (!date) throw new HttpsError('invalid-argument', 'Airlines publish their schedules about six months ahead. Fill in the ticket yourself; we\'ll check it nearer the day.');
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
    const provider = aeroDataBox(aeroDataBoxKey.value());
    let legs: FlightStatusResult[];
    try {
      legs = await provider.flightLegs(number, date);
    } catch (e) {
      if (!(e instanceof FlightProviderError)) throw e;
      if (e.reason === 'not-a-flight') throw new HttpsError('invalid-argument', 'That flight couldn\'t be found on that day.');
      throw new HttpsError('unavailable', 'Live flight status isn\'t available right now. Try again soon.');
    } finally {
      await recordFlightUnits(db, billingPeriod(nowMs, flightBillingDay.value()), provider.unitsPerLookup, 'page');
    }
    await ref.set({ legs, checkedAt: Timestamp.fromMillis(nowMs) });
    return { flight: pickLeg(legs, from), legs, checkedAt: new Date(nowMs).toISOString() };
  },
);

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
