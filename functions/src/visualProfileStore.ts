import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';

import { VisualProfile } from './visualProfileSchema';
import { themeFieldsFor, TripThemeFields } from './visualThemeRules';
import { ExperienceTheme } from './visualVocabulary';

/**
 * Where classifyTripVisuals keeps its state. Firestore in production; an
 * in-memory fake in tests.
 *
 *   trips/{tripId}   visualProfile, visualProfileUpdatedAt,
 *                    visualProfileRequest {hash, at, by}     server-only
 *                    theme, themeSource                       also the app's
 *   users/{uid}      visualClassification {day, today, total} server-only
 */

/** Classifications one traveller can run per UTC day. Far above normal use. */
export const DAILY_CLASSIFICATIONS = 30;

/** Minimum gap between two classifications of the same trip. */
export const TRIP_COOLDOWN_MS = 15_000;

export interface TripVisualState extends TripThemeFields {
  memberIds: string[];
  visualProfile?: unknown;
}

export class AccessError extends Error {
  constructor(readonly reason: 'missing' | 'not_member') {
    super(reason);
  }
}

export class RateLimitError extends Error {
  constructor(
    readonly reason: 'daily' | 'cooldown',
    readonly retryAfterMs?: number,
  ) {
    super(reason);
  }
}

export interface VisualProfileStore {
  readTrip(tripId: string): Promise<TripVisualState | undefined>;

  /**
   * Counts a classification against [uid]'s daily limit, enforces the trip's
   * cooldown and records [sourceHash] as the trip's latest request.
   * Throws RateLimitError or AccessError.
   */
  reserve(args: { uid: string; tripId: string; sourceHash: string; nowMs: number }): Promise<void>;

  /**
   * Stores [profile] (and the theme, for an automatic trip) unless a newer
   * request for the trip started meanwhile. Throws AccessError.
   */
  save(args: { uid: string; tripId: string; profile: VisualProfile }): Promise<'saved' | 'superseded'>;

  /** Points an automatic trip's theme at [primaryTheme]. Throws AccessError. */
  syncAutomaticTheme(args: { uid: string; tripId: string; primaryTheme: ExperienceTheme }): Promise<void>;
}

/** Milliseconds left in a trip's cooldown (0 when free). */
export function cooldownRemaining(lastRequestAtMs: number | undefined, nowMs: number): number {
  if (lastRequestAtMs === undefined) return 0;
  return Math.max(0, lastRequestAtMs + TRIP_COOLDOWN_MS - nowMs);
}

/** Today's count for a usage record, starting again each UTC day. */
export function usageToday(usage: unknown, day: string): { today: number; total: number } {
  const record = (usage && typeof usage === 'object' ? usage : {}) as { day?: unknown; today?: unknown; total?: unknown };
  const today = record.day === day && typeof record.today === 'number' ? record.today : 0;
  const total = typeof record.total === 'number' ? record.total : 0;
  return { today, total };
}

function memberIdsOf(data: Record<string, unknown> | undefined): string[] {
  const ids = data?.memberIds;
  return Array.isArray(ids) ? ids.filter((id): id is string => typeof id === 'string') : [];
}

export class FirestoreVisualProfileStore implements VisualProfileStore {
  constructor(private readonly db: Firestore) {}

  private trip(tripId: string) {
    return this.db.collection('trips').doc(tripId);
  }

  async readTrip(tripId: string): Promise<TripVisualState | undefined> {
    const snapshot = await this.trip(tripId).get();
    if (!snapshot.exists) return undefined;
    const data = snapshot.data();
    return {
      memberIds: memberIdsOf(data),
      theme: data?.theme,
      themeSource: data?.themeSource,
      visualProfile: data?.visualProfile,
    };
  }

  async reserve({ uid, tripId, sourceHash, nowMs }: { uid: string; tripId: string; sourceHash: string; nowMs: number }) {
    const tripRef = this.trip(tripId);
    const userRef = this.db.collection('users').doc(uid);
    const day = new Date(nowMs).toISOString().slice(0, 10);
    await this.db.runTransaction(async (tx) => {
      const [trip, user] = await tx.getAll(tripRef, userRef);
      if (!trip.exists) throw new AccessError('missing');
      if (!memberIdsOf(trip.data()).includes(uid)) throw new AccessError('not_member');

      const { today, total } = usageToday(user.get('visualClassification'), day);
      if (today >= DAILY_CLASSIFICATIONS) throw new RateLimitError('daily');

      const lastAt = trip.get('visualProfileRequest.at');
      const remaining = cooldownRemaining(lastAt instanceof Timestamp ? lastAt.toMillis() : undefined, nowMs);
      if (remaining > 0) throw new RateLimitError('cooldown', remaining);

      tx.set(userRef, { visualClassification: { day, today: today + 1, total: total + 1 } }, { merge: true });
      tx.update(tripRef, {
        visualProfileRequest: { hash: sourceHash, at: Timestamp.fromMillis(nowMs), by: uid },
      });
    });
  }

  async save({ uid, tripId, profile }: { uid: string; tripId: string; profile: VisualProfile }) {
    const tripRef = this.trip(tripId);
    return this.db.runTransaction(async (tx): Promise<'saved' | 'superseded'> => {
      const trip = await tx.get(tripRef);
      if (!trip.exists) throw new AccessError('missing');
      const data = trip.data() ?? {};
      if (!memberIdsOf(data).includes(uid)) throw new AccessError('not_member');
      if (trip.get('visualProfileRequest.hash') !== profile.sourceHash) return 'superseded';
      tx.update(tripRef, {
        visualProfile: profile,
        visualProfileUpdatedAt: FieldValue.serverTimestamp(),
        ...themeFieldsFor(data, profile.primaryTheme),
      });
      return 'saved';
    });
  }

  async syncAutomaticTheme({ uid, tripId, primaryTheme }: { uid: string; tripId: string; primaryTheme: ExperienceTheme }) {
    const tripRef = this.trip(tripId);
    await this.db.runTransaction(async (tx) => {
      const trip = await tx.get(tripRef);
      if (!trip.exists) throw new AccessError('missing');
      const data = trip.data() ?? {};
      if (!memberIdsOf(data).includes(uid)) throw new AccessError('not_member');
      const fields = themeFieldsFor(data, primaryTheme);
      if (Object.keys(fields).length > 0) tx.update(tripRef, fields);
    });
  }
}

/**
 * Deletes Places coordinates past their 30-day limit (Google Maps Platform
 * Service Specific Terms §14.3). Place IDs and the itinerary's own names
 * stay. Returns how many trips were cleaned.
 */
export async function purgeExpiredCoordinates(db: Firestore, nowMs: number, batchSize = 400): Promise<number> {
  let purged = 0;
  for (;;) {
    const expired = await db
      .collection('trips')
      .where('visualProfile.location.coordinatesExpireAt', '<=', nowMs)
      .limit(batchSize)
      .get();
    if (expired.empty) return purged;
    const batch = db.batch();
    for (const doc of expired.docs) {
      batch.update(doc.ref, {
        'visualProfile.location.latitude': FieldValue.delete(),
        'visualProfile.location.longitude': FieldValue.delete(),
        'visualProfile.location.coordinatesExpireAt': FieldValue.delete(),
      });
    }
    await batch.commit();
    purged += expired.size;
    if (expired.size < batchSize) return purged;
  }
}
