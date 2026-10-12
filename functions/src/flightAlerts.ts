import { createHash } from 'node:crypto';

import {
  DocumentData, DocumentReference, DocumentSnapshot, FieldPath, FieldValue, Firestore, getFirestore,
  QueryDocumentSnapshot, Timestamp,
} from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/firestore';
import { HttpsError, onCall } from 'firebase-functions/https';
import { onSchedule } from 'firebase-functions/scheduler';

import {
  alertRecipients, alertText, AlertText, billingPeriod, budgetLevel, BudgetLevel, firstCheckAt, flightChanges,
  legKey, liveNeedsWrite, nextCheckAt, retryAt, timingOf, TripRecord, UserRecord, watchedFlightFor, WatchedBooking,
  worthCheckingNow,
} from './flightAlertsLogic';
import { aeroDataBox, FlightProvider } from './flightProvider';
import { FlightStatusResult, pickLeg } from './flightStatusLogic';
import { flightUnitsUsed, recordFlightUnits } from './flightUsage';
import {
  aeroDataBoxKey, flightAlertsEnabled, flightBillingDay, flightRatePerSecond, flightUnitsPerMonth,
} from './params';

/**
 * Flight alerts (paid trips): everyone on the trip hears the moment their
 * flight changes, and the flight's card on Today shows the latest.
 *
 *   watchedFlights/{NUMBER_date}   one flight on one day, shared by everyone
 *                                  on it: number, date, trips {tripId:
 *                                  {bookingId: {from}}}, tripIds[], legs
 *                                  (latest answer), announced {leg: what
 *                                  everyone was last told}, nextCheckAt
 *                                  (null once there's nothing left to
 *                                  check)                          server-only
 *   trips/{id}.liveFlights         {bookingId: the flight's leg + checkedAt}:
 *                                  the live line on Today          server-only
 *   pushTokens/{sha256(token)}     {uid, token, platform}: where pushes go;
 *                                  a phone belongs to whoever registered
 *                                  it last                         server-only
 *   flightUsage/{period}           units used of the provider's month
 *   config/flightAlerts            {paused: true} stops checking at once,
 *                                  without a deploy
 *
 * - Triggers keep the watch list: a flight booking saved or removed, a
 *   trip's premium or members changing, someone's Plus starting or ending.
 *   Only trips where someone has premium are watched (alertRecipients), so
 *   it can't be faked from the app.
 * - checkWatchedFlights runs every 5 minutes and looks up the flights that
 *   are due (nextCheckAt), one request a second, within the month's units
 *   (budgetLevel). Each answer is compared with what was last announced
 *   (flightChanges); news goes as one push per trip to everyone on it with
 *   premium, and onto the trip for Today. The answer also fills the flight
 *   page's cache, so opening the flight costs nothing more.
 */

const MINUTE = 60_000;

// Watching.

/** Whether anyone on [trip] gets flight alerts. */
async function tripRecipients(db: Firestore, trip: DocumentData, now: number): Promise<string[]> {
  const members = Array.isArray(trip.memberIds) ? trip.memberIds.filter((m): m is string => typeof m === 'string') : [];
  if (!members.length) return [];
  const users = await db.getAll(...members.map((uid) => db.doc(`users/${uid}`)));
  return alertRecipients(
    trip as TripRecord,
    Object.fromEntries(users.map((u) => [u.id, u.data() as UserRecord])),
    now,
  );
}

interface WatchEntry {
  watched: WatchedBooking;
  bookings: Record<string, { from: string | null }>;
}

/**
 * Brings the watch list in line with [tripId]: its flights are watched
 * while someone on it has premium, and nothing of it is watched otherwise
 * (or once it's deleted). Safe to run any number of times.
 */
export async function syncTripFlights(db: Firestore, tripId: string, now = Date.now()): Promise<void> {
  const tripRef = db.collection('trips').doc(tripId);
  const trip = await tripRef.get();
  const desired = new Map<string, WatchEntry>();
  if (trip.exists && (await tripRecipients(db, trip.data()!, now)).length) {
    const flights = await tripRef.collection('bookings').where('kind', '==', 'flight').get();
    for (const booking of flights.docs) {
      const watched = watchedFlightFor(booking.data(), now);
      if (!watched) continue;
      const entry = desired.get(watched.key) ?? { watched, bookings: {} };
      entry.bookings[booking.id] = { from: watched.from };
      if (watched.estimateMs < entry.watched.estimateMs) entry.watched = watched;
      desired.set(watched.key, entry);
    }
  }
  const current = await db.collection('watchedFlights').where('tripIds', 'array-contains', tripId).get();
  const keys = new Set([...current.docs.map((d) => d.id), ...desired.keys()]);
  const live: Record<string, FlightStatusResult & { checkedAt: number }> = {};
  for (const key of keys) {
    const entry = desired.get(key) ?? null;
    const watch = await updateWatch(db, key, tripId, entry, now);
    // Joining a flight already being checked: its latest straight away.
    if (entry && watch?.legs?.length && watch.checkedAt) {
      for (const [bookingId, { from }] of Object.entries(entry.bookings)) {
        const leg = pickLeg(watch.legs, from);
        if (leg) live[bookingId] = { ...leg, checkedAt: watch.checkedAt };
      }
    }
  }
  if (!trip.exists) return;
  const stored = (trip.get('liveFlights') ?? {}) as Record<string, unknown>;
  const watchedIds = new Set([...desired.values()].flatMap((e) => Object.keys(e.bookings)));
  const writes: [FieldPath, unknown][] = [
    ...Object.keys(stored).filter((id) => !watchedIds.has(id)).map((id) => [liveField(id), FieldValue.delete()] as [FieldPath, unknown]),
    ...Object.entries(live).filter(([id]) => !stored[id]).map(([id, value]) => [liveField(id), value] as [FieldPath, unknown]),
  ];
  await updateFields(tripRef, writes);
}

const liveField = (bookingId: string) => new FieldPath('liveFlights', bookingId);

async function updateFields(ref: DocumentReference, writes: [FieldPath, unknown][]): Promise<void> {
  if (!writes.length) return;
  const [[field, value], ...rest] = writes;
  try {
    await ref.update(field, value, ...rest.flat());
  } catch (e) {
    // The trip was deleted meanwhile: nothing to show it on.
    if ((e as { code?: number }).code !== 5) throw e;
  }
}

/** Puts [tripId]'s bookings on [key]'s watch (or takes them off). Returns the watch as it was. */
async function updateWatch(
  db: Firestore,
  key: string,
  tripId: string,
  entry: WatchEntry | null,
  now: number,
): Promise<{ legs: FlightStatusResult[] | null; checkedAt: number | null } | null> {
  const ref = db.collection('watchedFlights').doc(key);
  return db.runTransaction(async (tx) => {
    const watch = await tx.get(ref);
    if (!watch.exists) {
      if (!entry) return null;
      const { number, date, estimateMs } = entry.watched;
      tx.create(ref, {
        number,
        date,
        trips: { [tripId]: entry.bookings },
        tripIds: [tripId],
        estimateMs,
        legs: null,
        announced: {},
        checkedAt: null,
        nextCheckAt: Timestamp.fromMillis(firstCheckAt(estimateMs, now)),
        failures: 0,
        empties: 0,
        createdAt: FieldValue.serverTimestamp(),
      });
      return null;
    }
    const trips = { ...((watch.get('trips') ?? {}) as Record<string, unknown>) };
    if (entry) trips[tripId] = entry.bookings;
    else delete trips[tripId];
    const tripIds = Object.keys(trips);
    if (!tripIds.length) {
      tx.delete(ref);
    } else {
      const updates: Record<string, unknown> = { trips, tripIds };
      // Not answered yet: the earliest booking's time decides the first look.
      const estimate = watch.get('estimateMs') as number;
      if (entry && !watch.get('legs') && entry.watched.estimateMs < estimate) {
        updates.estimateMs = entry.watched.estimateMs;
        const next = (watch.get('nextCheckAt') as Timestamp | null)?.toMillis();
        if (next != null) updates.nextCheckAt = Timestamp.fromMillis(Math.min(next, firstCheckAt(entry.watched.estimateMs, now)));
      }
      tx.update(ref, updates);
    }
    return {
      legs: (watch.get('legs') as FlightStatusResult[] | null) ?? null,
      checkedAt: (watch.get('checkedAt') as Timestamp | null)?.toMillis() ?? null,
    };
  });
}

/** Whether a booking write could change what's watched. */
export function flightBookingChanged(before: DocumentData | undefined, after: DocumentData | undefined): boolean {
  if (before?.kind !== 'flight' && after?.kind !== 'flight') return false;
  if (!before || !after) return true;
  return ['kind', 'startDate', 'startTime', 'location'].some((f) => before[f] !== after[f])
    || before.details?.flightNumber !== after.details?.flightNumber;
}

/** Whether a trip write could change who hears about its flights. */
export function tripAudienceChanged(before: DocumentData | undefined, after: DocumentData | undefined): boolean {
  if (!before) return false; // A new trip has no bookings yet; they bring themselves.
  if (!after) return true;
  return JSON.stringify(before.premium ?? null) !== JSON.stringify(after.premium ?? null)
    || JSON.stringify(before.memberIds ?? []) !== JSON.stringify(after.memberIds ?? []);
}

/** Whether a user write changed their own premium (Plus, or the tester flag). */
export function userPremiumChanged(before: DocumentData | undefined, after: DocumentData | undefined): boolean {
  return (before?.plus?.expiresAt ?? null) !== (after?.plus?.expiresAt ?? null)
    || (before?.tester === true) !== (after?.tester === true);
}

// Checking.

/** Sends pushes (faked in tests). */
export interface Messenger {
  /** Sends [alert] to [tokens]; returns the tokens that no longer reach a phone. */
  send(tokens: string[], alert: AlertText, data: Record<string, string>, thread: string): Promise<string[]>;
}

/** Firebase Cloud Messaging. */
export function fcmMessenger(): Messenger {
  return {
    async send(tokens, alert, data, thread) {
      const result = await getMessaging().sendEachForMulticast({
        tokens,
        notification: { title: alert.title, body: alert.body },
        data,
        apns: { payload: { aps: { sound: 'default', threadId: thread } } },
        android: { priority: 'high', notification: { channelId: 'flight_changes', tag: `${thread}_${alert.kind}` } },
      });
      return result.responses.flatMap((r, i) => {
        const code = r.error?.code;
        return code === 'messaging/registration-token-not-registered' || code === 'messaging/invalid-registration-token'
          ? [tokens[i]]
          : [];
      });
    },
  };
}

export interface FlightCheckDeps {
  db: Firestore;
  provider: FlightProvider;
  messenger: Messenger;
  now: () => number;
  monthlyUnits: number;
  billingDay: number;
  ratePerSecond: number;
  /** Stop starting checks this long into a run (the rest stay due). */
  deadlineMs: number;
  sleep?: (ms: number) => Promise<void>;
}

export interface FlightRun {
  due: number;
  checked: number;
  alerts: number;
  units: number;
  level: BudgetLevel;
}

/** One run of the checker: every watched flight that's due, as far as the units allow. */
export async function runFlightChecks(deps: FlightCheckDeps): Promise<FlightRun> {
  const { db } = deps;
  const started = deps.now();
  const sleep = deps.sleep ?? ((ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms)));
  await purgeFinishedWatches(db, started);
  const period = billingPeriod(started, deps.billingDay);
  let used = await flightUnitsUsed(db, period);
  const due = await db.collection('watchedFlights')
    .where('nextCheckAt', '<=', Timestamp.fromMillis(started))
    .orderBy('nextCheckAt')
    .limit(100)
    .get();
  const run: FlightRun = { due: due.size, checked: 0, alerts: 0, units: 0, level: budgetLevel(used, deps.monthlyUnits, period, started) };
  let lastCall = 0;
  for (const doc of due.docs) {
    if (deps.now() - started > deps.deadlineMs) break;
    const now = deps.now();
    const level = budgetLevel(used, deps.monthlyUnits, period, now);
    run.level = level;
    const timing = earliestTiming(doc);
    if (!worthCheckingNow(timing, now, level)) {
      await doc.ref.update({ nextCheckAt: stamp(nextCheckAt(timing, now, level)) });
      continue;
    }
    const wait = lastCall + 1000 / Math.max(deps.ratePerSecond, 0.1) - deps.now();
    if (wait > 0) await sleep(wait);
    lastCall = deps.now();
    const result = await checkFlight(deps, doc, level);
    used += result.units;
    run.units += result.units;
    run.checked++;
    run.alerts += result.alerts;
    if (result.units) await recordFlightUnits(db, period, result.units, 'alerts');
  }
  return run;
}

const stamp = (ms: number | null) => (ms === null ? null : Timestamp.fromMillis(ms));

type Subscribers = Record<string, Record<string, { from: string | null }>>;

/** Each subscribed booking's leg of [legs]. */
function pickedLegs(trips: Subscribers, legs: FlightStatusResult[]) {
  const picked: { tripId: string; bookingId: string; leg: FlightStatusResult; key: string }[] = [];
  for (const [tripId, bookings] of Object.entries(trips)) {
    for (const [bookingId, { from }] of Object.entries(bookings)) {
      const leg = pickLeg(legs, from);
      if (leg) picked.push({ tripId, bookingId, leg, key: legKey(leg, legs.indexOf(leg)) });
    }
  }
  return picked;
}

/** The watch's soonest leg's timing (the latest answer's, else the booking's). */
function earliestTiming(watch: DocumentSnapshot) {
  const legs = (watch.get('legs') as FlightStatusResult[] | null) ?? [];
  const estimate = watch.get('estimateMs') as number;
  const empties = (watch.get('empties') as number) ?? 0;
  const timings = pickedLegs(watch.get('trips') ?? {}, legs).map((p) => timingOf(p.leg, estimate, empties));
  if (!timings.length) return timingOf(null, estimate, empties);
  return timings.reduce((a, b) => (b.departs < a.departs ? b : a));
}

/** When to check next: the soonest any subscribed leg needs it. */
function nextForLegs(trips: Subscribers, legs: FlightStatusResult[], estimate: number, empties: number, now: number, level: BudgetLevel) {
  const picked = pickedLegs(trips, legs);
  const times = (picked.length ? picked.map((p) => timingOf(p.leg, estimate, empties)) : [timingOf(null, estimate, empties)])
    .map((t) => nextCheckAt(t, now, level))
    .filter((t): t is number => t !== null);
  return times.length ? Math.min(...times) : null;
}

/** Looks one watched flight up, tells everyone what changed, and schedules the next look. */
export async function checkFlight(
  deps: FlightCheckDeps,
  watch: QueryDocumentSnapshot,
  level: BudgetLevel,
): Promise<{ units: number; alerts: number }> {
  const { db } = deps;
  const now = deps.now();
  const number = watch.get('number') as string;
  const date = watch.get('date') as string;
  const trips = (watch.get('trips') ?? {}) as Subscribers;
  const estimate = watch.get('estimateMs') as number;
  const previousLegs = (watch.get('legs') as FlightStatusResult[] | null) ?? [];
  const empties = (watch.get('empties') as number) ?? 0;

  let legs: FlightStatusResult[];
  try {
    legs = await deps.provider.flightLegs(number, date);
  } catch (e) {
    const failures = ((watch.get('failures') as number) ?? 0) + 1;
    logger.warn('flight_alert_check_failed', { failures, error: (e as Error).message });
    const scheduled = nextForLegs(trips, previousLegs, estimate, empties, now, level);
    await watch.ref.update({ failures, nextCheckAt: stamp(scheduled === null ? null : retryAt(failures, now, scheduled)) });
    return { units: deps.provider.unitsPerLookup, alerts: 0 };
  }
  const units = deps.provider.unitsPerLookup;
  const nowEmpties = legs.length ? 0 : empties + 1;

  // What each leg's news is, once, however many trips are on it.
  const announced = (watch.get('announced') ?? {}) as Record<string, FlightStatusResult>;
  const picked = pickedLegs(trips, legs);
  const news = new Map<string, AlertText | null>();
  const baselines: Record<string, FlightStatusResult> = { ...announced };
  for (const { leg, key } of picked) {
    if (news.has(key)) continue;
    const { changes, baseline } = flightChanges(announced[key] ?? null, leg);
    baselines[key] = baseline;
    news.set(key, alertText(changes, leg, number));
  }

  // Each trip: who's on it with premium, its live lines, and the push.
  let alerts = 0;
  const told = new Set<string>();
  const dropped: string[] = [];
  for (const tripId of Object.keys(trips)) {
    const tripRef = db.collection('trips').doc(tripId);
    const trip = await tripRef.get();
    const recipients = trip.exists ? await tripRecipients(db, trip.data()!, now) : [];
    if (!recipients.length) {
      dropped.push(tripId);
      continue;
    }
    const mine = picked.filter((p) => p.tripId === tripId);
    const stored = (trip.get('liveFlights') ?? {}) as Record<string, unknown>;
    const writes = mine
      .filter((p) => liveNeedsWrite(stored[p.bookingId], p.leg, now))
      .map((p) => [liveField(p.bookingId), { ...p.leg, checkedAt: now }] as [FieldPath, unknown]);
    await updateFields(tripRef, writes);

    const first = mine.find((p) => news.get(p.key));
    if (!first) continue;
    const alert = news.get(first.key)!;
    const uids = recipients.filter((uid) => !told.has(`${first.key}/${uid}`));
    uids.forEach((uid) => told.add(`${first.key}/${uid}`));
    alerts += await sendAlert(deps, uids, alert, { type: 'flight', tripId, bookingId: first.bookingId, change: alert.kind }, watch.id);
  }

  // The flight page reads the same answer instead of asking again.
  await db.collection('flightStatus').doc(watch.id).set({ legs, checkedAt: Timestamp.fromMillis(now) });
  const remaining = Object.fromEntries(Object.entries(trips).filter(([id]) => !dropped.includes(id)));
  await watch.ref.update({
    legs,
    announced: baselines,
    checkedAt: Timestamp.fromMillis(now),
    failures: 0,
    empties: nowEmpties,
    nextCheckAt: stamp(nextForLegs(remaining, legs, estimate, nowEmpties, now, level)),
  });
  // Trips nobody on has premium for any more come off the watch.
  for (const tripId of dropped) await syncTripFlights(db, tripId, now);
  return { units, alerts };
}

/** Sends [alert] to every phone of [uids], forgetting phones that are gone. Returns how many pushes went. */
async function sendAlert(
  deps: FlightCheckDeps,
  uids: string[],
  alert: AlertText,
  data: Record<string, string>,
  thread: string,
): Promise<number> {
  const tokens: { id: string; token: string }[] = [];
  for (let i = 0; i < uids.length; i += 30) {
    const found = await deps.db.collection('pushTokens').where('uid', 'in', uids.slice(i, i + 30)).get();
    tokens.push(...found.docs.map((d) => ({ id: d.id, token: d.get('token') as string })));
  }
  if (!tokens.length) return 0;
  let gone: string[] = [];
  try {
    gone = await deps.messenger.send(tokens.map((t) => t.token), alert, data, thread);
  } catch (e) {
    logger.error('flight_alert_push_failed', { error: (e as Error).message });
    return 0;
  }
  for (const t of tokens.filter((t) => gone.includes(t.token))) await deps.db.collection('pushTokens').doc(t.id).delete();
  // The kind of change only: never the flight or who's on it.
  logger.info('flight_alert_sent', { change: alert.kind, phones: tokens.length - gone.length });
  return tokens.length - gone.length;
}

/** Watches for flights that left days ago: gone, with their live lines. */
async function purgeFinishedWatches(db: Firestore, now: number): Promise<void> {
  const cutoff = new Date(now - 3 * 24 * 60 * MINUTE).toISOString().slice(0, 10);
  const old = await db.collection('watchedFlights').where('date', '<', cutoff).limit(50).get();
  for (const watch of old.docs) {
    for (const [tripId, bookings] of Object.entries((watch.get('trips') ?? {}) as Subscribers)) {
      await updateFields(
        db.collection('trips').doc(tripId),
        Object.keys(bookings).map((id) => [liveField(id), FieldValue.delete()]),
      );
    }
    await watch.ref.delete();
  }
}

// Phones.

/** Where [uid]'s pushes go: this phone, taken from whoever had it before. */
export async function registerPushTokenFor(db: Firestore, uid: string, data: unknown): Promise<void> {
  const { token, platform } = (data && typeof data === 'object' ? data : {}) as Record<string, unknown>;
  if (typeof token !== 'string' || token.length < 20 || token.length > 4096 || /\s/.test(token)) {
    throw new HttpsError('invalid-argument', 'That isn\'t a push token.');
  }
  if (platform !== 'ios' && platform !== 'android') throw new HttpsError('invalid-argument', 'Which phone?');
  const id = createHash('sha256').update(token).digest('hex');
  await db.collection('pushTokens').doc(id).set({ uid, token, platform, updatedAt: FieldValue.serverTimestamp() });
}

/** Forgets [uid]'s phones (deleting their account). */
export async function deletePushTokens(db: Firestore, uid: string): Promise<void> {
  const tokens = await db.collection('pushTokens').where('uid', '==', uid).get();
  for (const t of tokens.docs) await t.ref.delete();
}

// Cloud Functions.

export const registerPushToken = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  await registerPushTokenFor(getFirestore(), uid, request.data);
  return { ok: true };
});

export const watchFlightsOnBookingChange = onDocumentWritten('trips/{tripId}/bookings/{bookingId}', async (event) => {
  if (!flightBookingChanged(event.data?.before.data(), event.data?.after.data())) return;
  await syncTripFlights(getFirestore(), event.params.tripId);
});

export const watchFlightsOnTripChange = onDocumentWritten('trips/{tripId}', async (event) => {
  if (!tripAudienceChanged(event.data?.before.data(), event.data?.after.data())) return;
  await syncTripFlights(getFirestore(), event.params.tripId);
});

export const watchFlightsOnUserChange = onDocumentWritten('users/{uid}', async (event) => {
  if (!userPremiumChanged(event.data?.before.data(), event.data?.after.data())) return;
  const db = getFirestore();
  const trips = await db.collection('trips').where('memberIds', 'array-contains', event.params.uid).get();
  for (const trip of trips.docs) await syncTripFlights(db, trip.id);
});

export const checkWatchedFlights = onSchedule(
  { schedule: 'every 5 minutes', secrets: [aeroDataBoxKey], timeoutSeconds: 300, maxInstances: 1, retryCount: 0 },
  async () => {
    if (!flightAlertsEnabled.value()) return;
    const db = getFirestore();
    if ((await db.doc('config/flightAlerts').get()).get('paused') === true) {
      logger.info('flight_alerts_paused');
      return;
    }
    const run = await runFlightChecks({
      db,
      provider: aeroDataBox(aeroDataBoxKey.value()),
      messenger: fcmMessenger(),
      now: Date.now,
      monthlyUnits: flightUnitsPerMonth.value(),
      billingDay: flightBillingDay.value(),
      ratePerSecond: flightRatePerSecond.value(),
      deadlineMs: 4 * MINUTE,
    });
    if (run.due) logger.info('flight_alerts_run', { ...run });
  },
);
