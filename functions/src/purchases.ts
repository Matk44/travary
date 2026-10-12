import { timingSafeEqual } from 'node:crypto';

import {
  DocumentReference, DocumentSnapshot, FieldValue, Firestore, getFirestore, Transaction,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/firestore';
import { HttpsError, onCall, onRequest } from 'firebase-functions/https';

import { revenueCatApiKey, revenueCatWebhookAuth } from './params';
import {
  holidayPassRefund, holidayPassTransactions, PassRecord, passSpanFor, passUntil, pickTransaction,
  plusFromSubscriber, premiumFromRecords, samePremium, Subscriber, tripPremium, tripSpan, webhookUserIds,
} from './purchasesLogic';

/**
 * Purchases, checked with RevenueCat and mirrored for the app (which never
 * records a purchase itself; the rules don't let it):
 *
 *   users/{uid}          plus {expiresAt, willRenew}, tripPasses {tripId: {start, end}}
 *   tripPasses/{id}      one claimed Holiday Pass, keyed by RevenueCat's
 *                        purchase id so it can only be claimed once:
 *                        {uid, tripId, start, end, store, sandbox, ...}   server-only
 *   trips/{id}.premium   {grantedBy, until}: Plus travelling with the trip,
 *                        for everyone on it
 *
 * - claimTripPass: after the store charges for a Holiday Pass, the app
 *   names the trip; the dates come from Firestore.
 * - syncPurchases / revenueCatWebhook: mirror the Annual Pass (bought,
 *   renewed, expired) and restamp the trips its owner organises.
 * - Triggers restamp a trip when its dates or organiser change, so a pass
 *   grows with its holiday (tripPassLastDay) and Plus covers new trips.
 * - A refunded Holiday Pass (RevenueCat's CANCELLATION webhook) is marked
 *   `refundedAt` and stops counting; a refund taken back restores it.
 * - hasPremium: what Smart Import (after the free ones) and inviting family
 *   check on the server, so the app isn't the only gate.
 */

/** What the handlers need from RevenueCat (faked in tests). */
export interface RevenueCatApi {
  subscriber(uid: string): Promise<Subscriber>;
}

export function revenueCatApi(secretKey: string): RevenueCatApi {
  return {
    async subscriber(uid) {
      const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`, {
        headers: { Authorization: `Bearer ${secretKey}` },
      });
      if (!response.ok) {
        logger.error('revenuecat_lookup_failed', { status: response.status });
        throw new HttpsError('unavailable', 'The store couldn\'t be reached. Try again in a moment.');
      }
      const json = (await response.json()) as { subscriber?: Subscriber };
      return json.subscriber ?? {};
    },
  };
}

interface PremiumInputs {
  trip: DocumentSnapshot;
  span: ReturnType<typeof tripSpan>;
  ownerPlus: { uid: string; expiresAt: number } | null;
  passes: PassRecord[];
}

/** Everything a trip's `premium` stamp depends on, read in [tx]. */
async function readPremiumInputs(db: Firestore, tx: Transaction, tripRef: DocumentReference): Promise<PremiumInputs> {
  const trip = await tx.get(tripRef);
  const bookings = await tx.get(tripRef.collection('bookings'));
  const passes = await tx.get(db.collection('tripPasses').where('tripId', '==', tripRef.id));
  const ownerId = trip.get('ownerId');
  const owner = typeof ownerId === 'string' && ownerId ? await tx.get(db.doc(`users/${ownerId}`)) : null;
  const expiresAt = owner?.get('plus.expiresAt');
  return {
    trip,
    span: tripSpan(trip.data() ?? {}, bookings.docs.map((d) => d.data())),
    ownerPlus: typeof expiresAt === 'number' ? { uid: ownerId as string, expiresAt } : null,
    passes: passes.docs
      .filter((d) => d.get('refundedAt') == null)
      .map((d) => ({ uid: d.get('uid'), start: d.get('start'), end: d.get('end') })),
  };
}

function writePremium(tx: Transaction, inputs: PremiumInputs, extraPass?: PassRecord): void {
  const premium = tripPremium(inputs.span, inputs.ownerPlus, [...inputs.passes, ...(extraPass ? [extraPass] : [])]);
  if (samePremium(inputs.trip.get('premium'), premium)) return;
  tx.update(inputs.trip.ref, { premium: premium ?? FieldValue.delete() });
}

/** Works out a trip's `premium` stamp again. Nothing happens to a deleted trip. */
export async function restampTrip(db: Firestore, tripId: string): Promise<void> {
  await db.runTransaction(async (tx) => {
    const inputs = await readPremiumInputs(db, tx, db.collection('trips').doc(tripId));
    if (!inputs.trip.exists) return;
    writePremium(tx, inputs);
  });
}

/**
 * Records a Holiday Pass the caller has paid for (checked with RevenueCat)
 * for [tripId], with the trip's dates as Firestore has them, and stamps
 * the trip. Claiming the same trip again is a no-op, so retries are safe.
 */
export async function claimTripPassFor(
  db: Firestore,
  revenueCat: RevenueCatApi,
  uid: string,
  tripId: unknown,
  transactionId: unknown,
  now = Date.now(),
): Promise<{ start: string; end: string }> {
  if (typeof tripId !== 'string' || !tripId || tripId.includes('/')) {
    throw new HttpsError('invalid-argument', 'Which trip?');
  }
  const bought = holidayPassTransactions(await revenueCat.subscriber(uid));
  const tripRef = db.collection('trips').doc(tripId);
  return db.runTransaction(async (tx) => {
    const inputs = await readPremiumInputs(db, tx, tripRef);
    const memberIds = (inputs.trip.get('memberIds') ?? []) as string[];
    if (!inputs.trip.exists || !memberIds.includes(uid)) {
      throw new HttpsError('permission-denied', 'You\'re not on this trip.');
    }
    // A retry, or a pass bought again before the first one ran out: the
    // pass already on it. One that no longer covers the trip (it's moved
    // to before the dates it was bought for, or they've passed) doesn't
    // swallow a new purchase.
    const mine = inputs.passes.find((p) => p.uid === uid && (passUntil(p, inputs.span) ?? 0) > now);
    if (mine) return { start: mine.start, end: mine.end };

    const claims = bought.length ? await tx.getAll(...bought.map((t) => db.collection('tripPasses').doc(t.id))) : [];
    const claimed = new Set(claims.filter((c) => c.exists).map((c) => c.id));
    const pass = pickTransaction(bought, typeof transactionId === 'string' ? transactionId : '', claimed);
    if (!pass) {
      throw new HttpsError('failed-precondition', 'We couldn\'t find an unused Holiday Pass. Try Restore purchases in a moment.');
    }
    if (!inputs.span) throw new HttpsError('failed-precondition', 'Add the trip\'s dates first.');
    const dates = passSpanFor(inputs.span);

    tx.create(db.collection('tripPasses').doc(pass.id), {
      uid,
      tripId,
      ...dates,
      store: pass.store,
      sandbox: pass.sandbox,
      storeTransactionId: pass.storeTransactionId,
      purchasedAt: new Date(pass.purchasedAt),
      claimedAt: FieldValue.serverTimestamp(),
    });
    tx.set(db.doc(`users/${uid}`), { tripPasses: { [tripId]: dates } }, { merge: true });
    writePremium(tx, inputs, { uid, ...dates });
    logger.info('trip_pass_claimed', { uid, tripId, store: pass.store, sandbox: pass.sandbox });
    return dates;
  });
}

/**
 * Mirrors the caller's Annual Pass from RevenueCat to `users/{uid}`, then
 * restamps every trip they organise.
 */
export async function syncPlusFor(
  db: Firestore,
  revenueCat: RevenueCatApi,
  uid: string,
  now = Date.now(),
): Promise<{ plus: boolean }> {
  const plus = plusFromSubscriber(await revenueCat.subscriber(uid), now);
  await db.doc(`users/${uid}`).set({ plus: plus ?? FieldValue.delete() }, { merge: true });
  const trips = await db.collection('trips').where('ownerId', '==', uid).get();
  for (const trip of trips.docs) await restampTrip(db, trip.id);
  return { plus: plus !== null };
}

/**
 * Whether [uid] may use premium features (on [tripId], when given): their
 * mirrored Annual Pass, the trip's premium stamp, or a tester account; else
 * RevenueCat's own answer, so an Annual Pass bought moments ago (before its
 * mirror lands) is never refused. That answer is mirrored on the way.
 * Throws `unavailable` when the store can't be reached.
 */
export async function hasPremium(
  db: Firestore,
  revenueCat: RevenueCatApi | null,
  uid: string,
  tripId?: unknown,
  now = Date.now(),
): Promise<boolean> {
  const user = await db.doc(`users/${uid}`).get();
  const trip = typeof tripId === 'string' && tripId && !tripId.includes('/')
    ? await db.collection('trips').doc(tripId).get()
    : null;
  if (premiumFromRecords(uid, { user: user.data(), trip: trip?.data() }, now)) return true;
  if (!revenueCat) return false;
  const plus = plusFromSubscriber(await revenueCat.subscriber(uid), now);
  if (!plus) return false;
  await db.doc(`users/${uid}`).set({ plus }, { merge: true });
  return true;
}

/**
 * A Holiday Pass refunded ([reversed]: the refund taken back): marks its
 * claim, puts the traveller's mirror right and restamps the trip. Returns
 * the trips it touched.
 */
export async function refundTripPass(db: Firestore, transactionId: string, reversed: boolean): Promise<string[]> {
  const claims = await db.collection('tripPasses').where('storeTransactionId', '==', transactionId).get();
  const trips: string[] = [];
  for (const claim of claims.docs) {
    const uid = claim.get('uid') as string;
    const tripId = claim.get('tripId') as string;
    await claim.ref.update({ refundedAt: reversed ? FieldValue.delete() : FieldValue.serverTimestamp() });
    // The traveller's mirror shows the pass they still have for the trip.
    const kept = (await db.collection('tripPasses').where('uid', '==', uid).where('tripId', '==', tripId).get())
      .docs.filter((d) => d.get('refundedAt') == null)
      .sort((a, b) => (b.get('claimedAt')?.toMillis?.() ?? 0) - (a.get('claimedAt')?.toMillis?.() ?? 0));
    await db.doc(`users/${uid}`).set({
      tripPasses: {
        [tripId]: kept.length ? { start: kept[0].get('start'), end: kept[0].get('end') } : FieldValue.delete(),
      },
    }, { merge: true });
    await restampTrip(db, tripId);
    logger.info(reversed ? 'trip_pass_refund_reversed' : 'trip_pass_refunded', { uid, tripId });
    trips.push(tripId);
  }
  return trips;
}

function requireUid(auth: { uid: string } | undefined): string {
  if (!auth?.uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  return auth.uid;
}

function body(data: unknown): Record<string, unknown> {
  return data && typeof data === 'object' ? (data as Record<string, unknown>) : {};
}

export const claimTripPass = onCall({ secrets: [revenueCatApiKey] }, async (request) => {
  const uid = requireUid(request.auth);
  const { tripId, transactionId } = body(request.data);
  return claimTripPassFor(getFirestore(), revenueCatApi(revenueCatApiKey.value()), uid, tripId, transactionId);
});

export const syncPurchases = onCall({ secrets: [revenueCatApiKey] }, async (request) => {
  const uid = requireUid(request.auth);
  return syncPlusFor(getFirestore(), revenueCatApi(revenueCatApiKey.value()), uid);
});

function sameSecret(given: string | undefined, expected: string): boolean {
  const a = Buffer.from(given ?? '');
  const b = Buffer.from(expected);
  return a.length === b.length && b.length > 0 && timingSafeEqual(a, b);
}

/**
 * RevenueCat's webhook (Integrations → Webhooks, with the Authorization
 * header set to the REVENUECAT_WEBHOOK_AUTH secret). The event only says
 * whom to look at: the Annual Pass is always read back from RevenueCat.
 */
export const revenueCatWebhook = onRequest({ secrets: [revenueCatApiKey, revenueCatWebhookAuth] }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).end();
    return;
  }
  if (!sameSecret(req.get('authorization'), revenueCatWebhookAuth.value())) {
    res.status(401).end();
    return;
  }
  const event = body(body(req.body).event);
  const uids = webhookUserIds(event);
  const revenueCat = revenueCatApi(revenueCatApiKey.value());
  const refund = holidayPassRefund(event);
  if (refund) await refundTripPass(getFirestore(), refund.transactionId, refund.reversed);
  for (const uid of uids) await syncPlusFor(getFirestore(), revenueCat, uid);
  logger.info('revenuecat_webhook', { type: event.type, users: uids.length });
  res.status(200).json({ ok: true });
});

function changed(before: Record<string, unknown> | undefined, after: Record<string, unknown> | undefined, fields: string[]) {
  return !before || !after || fields.some((f) => before[f] !== after[f]);
}

/** A trip's planned dates or organiser changed (or it's new). */
export const restampTripOnTripChange = onDocumentWritten('trips/{tripId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!after || !changed(before, after, ['plannedStart', 'plannedEnd', 'ownerId'])) return;
  await restampTrip(getFirestore(), event.params.tripId);
});

/** A booking was added, removed or moved, so the trip's dates may have changed. */
export const restampTripOnBookingChange = onDocumentWritten('trips/{tripId}/bookings/{bookingId}', async (event) => {
  if (!changed(event.data?.before.data(), event.data?.after.data(), ['startDate', 'endDate'])) return;
  await restampTrip(getFirestore(), event.params.tripId);
});

/** Moves a guest's claimed passes to the account they signed in to. */
export async function moveTripPasses(db: Firestore, from: string, to: string): Promise<string[]> {
  if (from === to) return [];
  const passes = await db.collection('tripPasses').where('uid', '==', from).get();
  if (passes.empty) return [];
  const batch = db.batch();
  const tripPasses: Record<string, { start: string; end: string }> = {};
  for (const pass of passes.docs) {
    batch.update(pass.ref, { uid: to });
    if (pass.get('refundedAt') == null) tripPasses[pass.get('tripId')] = { start: pass.get('start'), end: pass.get('end') };
  }
  batch.set(db.doc(`users/${to}`), { tripPasses }, { merge: true });
  await batch.commit();
  return passes.docs.map((p) => p.get('tripId') as string);
}

/** Deletes a traveller's claimed passes (deleting their account). Returns the trips they covered. */
export async function deleteTripPasses(db: Firestore, uid: string): Promise<string[]> {
  const passes = await db.collection('tripPasses').where('uid', '==', uid).get();
  const batch = db.batch();
  for (const pass of passes.docs) batch.delete(pass.ref);
  if (!passes.empty) await batch.commit();
  return passes.docs.map((p) => p.get('tripId') as string);
}
