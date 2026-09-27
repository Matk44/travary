import { FieldValue, getFirestore, Timestamp, Transaction } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/https';

import {
  cleanName, INVITE_DAYS, MAX_MEMBERS, newInviteCode, normaliseCode, withMember, withoutMember,
} from './sharingLogic';

/**
 * Family sharing. Joining and leaving go through here because the security
 * rules (rightly) don't let anyone add themselves to a trip. Every change to
 * a trip's members also updates the copy on each of its bookings, which is
 * what the app's reads rely on.
 *
 *   invites/{code}   { tripId, createdBy, expiresAt }   server-only
 *   trips/{id}       memberIds[], memberNames{uid: name}, invite{code, expiresAt}
 */

const db = () => getFirestore();

function requireUid(auth: { uid: string } | undefined): string {
  if (!auth?.uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  return auth.uid;
}

function body(data: unknown): Record<string, unknown> {
  return data && typeof data === 'object' ? (data as Record<string, unknown>) : {};
}

/** Creates (or reuses) the trip's invite code. Any member can invite. */
export const createTripInvite = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const { tripId, name } = body(request.data);
  if (typeof tripId !== 'string' || !tripId) throw new HttpsError('invalid-argument', 'Which trip?');

  const tripRef = db().collection('trips').doc(tripId);
  return db().runTransaction(async (tx) => {
    const trip = await tx.get(tripRef);
    const memberIds = (trip.get('memberIds') ?? []) as string[];
    if (!trip.exists || !memberIds.includes(uid)) {
      throw new HttpsError('permission-denied', 'You\'re not on this trip.');
    }
    if (memberIds.length >= MAX_MEMBERS) {
      throw new HttpsError('resource-exhausted', `This trip already has ${MAX_MEMBERS} people.`);
    }

    const updates: Record<string, unknown> = {};
    const displayName = cleanName(name);
    if (displayName) updates[`memberNames.${uid}`] = displayName;

    const current = trip.get('invite') as { code?: string; expiresAt?: Timestamp } | undefined;
    let code = current?.code;
    let expiresAt = current?.expiresAt;
    if (!code || !expiresAt || expiresAt.toMillis() < Date.now() + 24 * 3600 * 1000) {
      code = await unusedCode(tx);
      expiresAt = Timestamp.fromMillis(Date.now() + INVITE_DAYS * 24 * 3600 * 1000);
      tx.set(db().collection('invites').doc(code), {
        tripId,
        createdBy: uid,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt,
      });
      updates.invite = { code, expiresAt };
    }
    if (Object.keys(updates).length > 0) tx.update(tripRef, updates);
    logger.info('trip_invite', { tripId, uid, members: memberIds.length });
    return { code, expiresAt: expiresAt.toMillis() };
  });
});

/** Joins the trip an invite code belongs to. Safe to call twice. */
export const joinTrip = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const { code: rawCode, name } = body(request.data);
  const code = normaliseCode(rawCode);
  if (!code) throw new HttpsError('invalid-argument', 'Codes are 6 letters and numbers.');

  const invite = await db().collection('invites').doc(code).get();
  const expiresAt = invite.get('expiresAt') as Timestamp | undefined;
  if (!invite.exists || !expiresAt || expiresAt.toMillis() < Date.now()) {
    throw new HttpsError('not-found', 'That code isn\'t valid or has expired. Ask for a new one.');
  }
  const tripId = invite.get('tripId') as string;

  return db().runTransaction(async (tx) => {
    const tripRef = db().collection('trips').doc(tripId);
    const trip = await tx.get(tripRef);
    if (!trip.exists) throw new HttpsError('not-found', 'That trip no longer exists.');
    const memberIds = (trip.get('memberIds') ?? []) as string[];
    const title = (trip.get('title') as string) ?? 'the trip';
    if (memberIds.includes(uid)) return { tripId, title };
    if (memberIds.length >= MAX_MEMBERS) {
      throw new HttpsError('resource-exhausted', `This trip already has ${MAX_MEMBERS} people.`);
    }

    const next = withMember(memberIds, uid);
    await setMembers(tx, tripId, next, {
      [`memberNames.${uid}`]: cleanName(name) ?? 'Traveller',
    });
    logger.info('trip_joined', { tripId, uid, members: next.length });
    return { tripId, title };
  });
});

/** The organiser removes someone, or a member leaves. */
export const removeTripMember = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const { tripId, memberId } = body(request.data);
  if (typeof tripId !== 'string' || typeof memberId !== 'string') {
    throw new HttpsError('invalid-argument', 'Which trip and who?');
  }

  return db().runTransaction(async (tx) => {
    const trip = await tx.get(db().collection('trips').doc(tripId));
    const ownerId = trip.get('ownerId') as string | undefined;
    const memberIds = (trip.get('memberIds') ?? []) as string[];
    if (!trip.exists || !memberIds.includes(uid)) {
      throw new HttpsError('permission-denied', 'You\'re not on this trip.');
    }
    if (memberId !== uid && uid !== ownerId) {
      throw new HttpsError('permission-denied', 'Only the organiser can remove people.');
    }
    if (memberId === ownerId) {
      throw new HttpsError('failed-precondition', 'The organiser can\'t leave. Delete the trip instead.');
    }
    if (!memberIds.includes(memberId)) return { removed: false };

    await setMembers(tx, tripId, withoutMember(memberIds, memberId), {
      [`memberNames.${memberId}`]: FieldValue.delete(),
    });
    logger.info('trip_member_removed', { tripId, by: uid, removed: memberId });
    return { removed: true };
  });
});

/** Writes the new member list to the trip and every booking in it. */
async function setMembers(
  tx: Transaction,
  tripId: string,
  memberIds: string[],
  extraTripFields: Record<string, unknown>,
): Promise<void> {
  const tripRef = db().collection('trips').doc(tripId);
  const bookings = await tx.get(tripRef.collection('bookings'));
  tx.update(tripRef, { memberIds, ...extraTripFields });
  for (const booking of bookings.docs) tx.update(booking.ref, { memberIds });
}

async function unusedCode(tx: Transaction): Promise<string> {
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = newInviteCode();
    const existing = await tx.get(db().collection('invites').doc(code));
    if (!existing.exists) return code;
  }
  throw new HttpsError('internal', 'Couldn\'t make an invite code. Try again.');
}
