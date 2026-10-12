import { getAuth } from 'firebase-admin/auth';
import { FieldValue, Firestore, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/https';

import { deletePushTokens } from './flightAlerts';
import { deleteTripPasses, moveTripPasses, restampTrip } from './purchases';
import { replaceMember, tripFateOnAccountDeletion } from './sharingLogic';

/**
 * Accounts. Travellers start as anonymous guests; signing in with Apple or
 * Google normally links that same account, so nothing moves. Two cases need
 * the server, because the rules (rightly) never let the app change who is
 * on a trip:
 *
 * - adoptGuestTrips: the Apple or Google account already existed (signed in
 *   on another phone), so the app switched to it. The guest's trips move
 *   to it: memberIds, ownerId, memberNames and every booking's copy.
 * - deleteAccount: a traveller deletes their account. Trips they share are
 *   handed to the next person (or left); trips only they are on are
 *   deleted with their bookings, invites and ticket files.
 */

/** What the handlers need from Firebase Auth (faked in tests). */
export interface AccountAuth {
  verifyIdToken(token: string): Promise<{ uid: string; firebase: { sign_in_provider: string } }>;
  deleteUser(uid: string): Promise<void>;
}

/** Deletes a trip's ticket files from Cloud Storage (faked in tests). */
export type DeleteTripFiles = (tripId: string) => Promise<void>;

/** Firestore's limit is 500 writes per batch. */
const BATCH = 400;

/**
 * Moves the guest's trips (proved by the guest's ID token) to [uid], then
 * deletes the guest account. Returns how many trips moved.
 */
export async function adoptGuestTrips(
  db: Firestore,
  auth: AccountAuth,
  uid: string,
  guestToken: unknown,
): Promise<{ trips: number }> {
  if (typeof guestToken !== 'string' || guestToken.length === 0) {
    throw new HttpsError('invalid-argument', 'Missing the guest account\'s token.');
  }
  let guest: string;
  try {
    const decoded = await auth.verifyIdToken(guestToken);
    if (decoded.firebase.sign_in_provider !== 'anonymous') {
      throw new HttpsError('permission-denied', 'Only a guest account\'s trips can be moved.');
    }
    guest = decoded.uid;
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError('invalid-argument', 'The guest account couldn\'t be confirmed.');
  }
  if (guest === uid) return { trips: 0 };

  const trips = await db.collection('trips').where('memberIds', 'array-contains', guest).get();
  for (const doc of trips.docs) {
    await db.runTransaction(async (tx) => {
      const trip = await tx.get(doc.ref);
      if (!trip.exists) return;
      const bookings = await tx.get(doc.ref.collection('bookings'));
      const memberIds = replaceMember((trip.get('memberIds') ?? []) as string[], guest, uid);
      const updates: Record<string, unknown> = { memberIds, [`memberNames.${guest}`]: FieldValue.delete() };
      if (trip.get('ownerId') === guest) updates.ownerId = uid;
      const names = (trip.get('memberNames') ?? {}) as Record<string, string>;
      if (names[guest] && !names[uid]) updates[`memberNames.${uid}`] = names[guest];
      tx.update(doc.ref, updates);
      for (const booking of bookings.docs) tx.update(booking.ref, { memberIds });
    });
  }
  const invites = await db.collection('invites').where('createdBy', '==', guest).get();
  for (const invite of invites.docs) await invite.ref.update({ createdBy: uid });
  // Holiday Passes the guest bought go with them (their trips are restamped).
  for (const tripId of await moveTripPasses(db, guest, uid)) await restampTrip(db, tripId);
  // The phone registers again as the account it switched to.
  await deletePushTokens(db, guest);

  try {
    await auth.deleteUser(guest);
  } catch (e) {
    logger.warn('guest_delete_failed', { uid, error: (e as Error).name });
  }
  logger.info('guest_trips_adopted', { uid, trips: trips.size });
  return { trips: trips.size };
}

/**
 * Removes [uid] from every trip (handing shared trips on, deleting their
 * own), deletes their purchases (claimed Holiday Passes too), usage record
 * and push tokens, then the account itself.
 */
export async function deleteAccountData(
  db: Firestore,
  auth: AccountAuth,
  deleteTripFiles: DeleteTripFiles,
  uid: string,
): Promise<{ deleted: number; handedOver: number; left: number }> {
  const counts = { deleted: 0, handedOver: 0, left: 0 };
  // Their Holiday Passes go too; the trips they covered are restamped below.
  const passTrips = await deleteTripPasses(db, uid);
  const trips = await db.collection('trips').where('memberIds', 'array-contains', uid).get();
  for (const doc of trips.docs) {
    const fate = tripFateOnAccountDeletion(
      (doc.get('ownerId') as string) ?? '',
      (doc.get('memberIds') ?? []) as string[],
      uid,
    );
    if (fate.action === 'delete') {
      await deleteTrip(db, doc.ref.id);
      await deleteTripFiles(doc.ref.id);
      counts.deleted++;
      continue;
    }
    await db.runTransaction(async (tx) => {
      const bookings = await tx.get(doc.ref.collection('bookings'));
      const updates: Record<string, unknown> = {
        memberIds: fate.memberIds,
        [`memberNames.${uid}`]: FieldValue.delete(),
      };
      if (fate.action === 'hand-over') updates.ownerId = fate.ownerId;
      tx.update(doc.ref, updates);
      for (const booking of bookings.docs) tx.update(booking.ref, { memberIds: fate.memberIds });
    });
    if (fate.action === 'hand-over') counts.handedOver++;
    else counts.left++;
  }
  for (const tripId of new Set(passTrips)) await restampTrip(db, tripId);
  await deletePushTokens(db, uid);
  await db.doc(`users/${uid}`).delete();
  await auth.deleteUser(uid);
  logger.info('account_deleted', { uid, ...counts });
  return counts;
}

async function deleteTrip(db: Firestore, tripId: string): Promise<void> {
  const tripRef = db.collection('trips').doc(tripId);
  const refs = [
    ...(await tripRef.collection('bookings').get()).docs.map((d) => d.ref),
    ...(await db.collection('invites').where('tripId', '==', tripId).get()).docs.map((d) => d.ref),
  ];
  for (let i = 0; i < refs.length; i += BATCH) {
    const batch = db.batch();
    for (const ref of refs.slice(i, i + BATCH)) batch.delete(ref);
    await batch.commit();
  }
  await tripRef.delete();
}

function requireUid(auth: { uid: string } | undefined): string {
  if (!auth?.uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  return auth.uid;
}

function body(data: unknown): Record<string, unknown> {
  return data && typeof data === 'object' ? (data as Record<string, unknown>) : {};
}

const adminAuth = (): AccountAuth => ({
  verifyIdToken: (token) => getAuth().verifyIdToken(token),
  deleteUser: (uid) => getAuth().deleteUser(uid),
});

/** Called by the app right after it switches from a guest to an existing account. */
export const adoptGuestTripsCall = onCall(async (request) => {
  const uid = requireUid(request.auth);
  if (request.auth?.token.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('failed-precondition', 'Sign in with Apple or Google first.');
  }
  return adoptGuestTrips(getFirestore(), adminAuth(), uid, body(request.data).guestToken);
});

/** Deletes the caller's account and data. Apple tokens are revoked by the app first. */
export const deleteAccountCall = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const bucket = getStorage().bucket();
  return deleteAccountData(getFirestore(), adminAuth(), (tripId) => bucket.deleteFiles({ prefix: `trips/${tripId}/` }), uid);
});
