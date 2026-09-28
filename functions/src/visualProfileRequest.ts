import { createHash } from 'node:crypto';

import { isArtSubject } from './artSubjects';
import { Kind, KINDS } from './bookingSchema';
import { asRecord, cleanText } from './visualProfileSchema';

/**
 * The classifier's input: a sanitized snapshot of one trip, sent by the app
 * (the app is local-first, so the server's copy may be seconds behind).
 *
 * Only what classification needs is kept. Anything else a client sends
 * (references, notes, attachments, names, seats, rooms, prices) is dropped
 * here and never reaches Gemini, the hash or the logs.
 */

/**
 * Bump whenever prompt semantics or normalisation rules change enough that
 * stored profiles should be reclassified. Part of every source hash.
 */
export const VISUAL_CLASSIFIER_VERSION = 1;

export const REQUEST_LIMITS = {
  tripId: 128,
  tripTitle: 120,
  bookings: 80,
  bookingId: 128,
  title: 100,
  location: 180,
  /** UTF-8 bytes of the sanitized payload. */
  payloadBytes: 48 * 1024,
} as const;

export interface SanitizedBooking {
  id: string;
  kind: Kind;
  title: string;
  location?: string;
  artSubject?: string;
  startDate: string;
  endDate?: string;
}

export interface SanitizedTrip {
  tripId: string;
  tripTitle?: string;
  /** Sorted by start date, end date, then ID. */
  bookings: SanitizedBooking[];
}

/** A request the function refuses, with a message for the traveller. */
export class InvalidRequestError extends Error {}

/** Validates and sanitizes the callable's `data`. Throws InvalidRequestError. */
export function parseClassifyRequest(data: unknown): SanitizedTrip {
  const body = asRecord(data);

  const tripId = typeof body.tripId === 'string' ? body.tripId.trim() : '';
  if (!tripId || tripId.length > REQUEST_LIMITS.tripId || tripId.includes('/')) {
    throw new InvalidRequestError('Which trip?');
  }

  const tripTitle = boundedText(body.tripTitle, REQUEST_LIMITS.tripTitle, 'trip name');

  if (!Array.isArray(body.bookings)) throw new InvalidRequestError('No bookings were sent.');
  if (body.bookings.length > REQUEST_LIMITS.bookings) {
    throw new InvalidRequestError(`At most ${REQUEST_LIMITS.bookings} bookings can be classified.`);
  }

  const ids = new Set<string>();
  const bookings = body.bookings.map((item): SanitizedBooking => {
    const b = asRecord(item);
    const id = typeof b.id === 'string' ? b.id.trim() : '';
    if (!id || id.length > REQUEST_LIMITS.bookingId) throw new InvalidRequestError('A booking had no ID.');
    if (ids.has(id)) throw new InvalidRequestError('A booking was sent twice.');
    ids.add(id);

    if (typeof b.kind !== 'string' || !(KINDS as readonly string[]).includes(b.kind)) {
      throw new InvalidRequestError('A booking had an unknown kind.');
    }
    const kind = b.kind as Kind;

    const title = boundedText(b.title, REQUEST_LIMITS.title, 'booking name');
    if (!title) throw new InvalidRequestError('Every booking needs a name.');

    if (!isValidDate(b.startDate)) throw new InvalidRequestError('A booking had an invalid date.');
    let endDate: string | undefined;
    if (b.endDate !== undefined && b.endDate !== null) {
      if (!isValidDate(b.endDate) || b.endDate < b.startDate) {
        throw new InvalidRequestError('A booking had an invalid end date.');
      }
      if (b.endDate !== b.startDate) endDate = b.endDate;
    }

    const location = boundedText(b.location, REQUEST_LIMITS.location, 'place');
    // Only the existing per-kind vocabulary; "generic" says nothing.
    const artSubject = isArtSubject(kind, b.artSubject) && b.artSubject !== 'generic' ? b.artSubject : undefined;

    return {
      id,
      kind,
      title,
      ...(location && { location }),
      ...(artSubject && { artSubject }),
      startDate: b.startDate,
      ...(endDate && { endDate }),
    };
  });

  bookings.sort(compareBookings);
  const trip: SanitizedTrip = { tripId, ...(tripTitle && { tripTitle }), bookings };
  if (Buffer.byteLength(JSON.stringify(trip), 'utf8') > REQUEST_LIMITS.payloadBytes) {
    throw new InvalidRequestError('That trip is too big to classify.');
  }
  return trip;
}

/**
 * Exactly what Gemini sees: no IDs (they carry no meaning), bookings in
 * date order.
 */
export function geminiPayload(trip: SanitizedTrip) {
  return {
    ...(trip.tripTitle && { tripTitle: trip.tripTitle }),
    bookings: trip.bookings.map((b) => ({
      kind: b.kind,
      title: b.title,
      ...(b.location && { location: b.location }),
      ...(b.artSubject && { artSubject: b.artSubject }),
      startDate: b.startDate,
      ...(b.endDate && { endDate: b.endDate }),
    })),
  };
}

/**
 * SHA-256 (hex) of the canonical sanitized snapshot plus the classifier
 * version. Unchanged hash = unchanged classification input.
 */
export function sourceHashFor(trip: SanitizedTrip, classifierVersion = VISUAL_CLASSIFIER_VERSION): string {
  // Fixed key order: JSON.stringify keeps insertion order.
  const canonical = {
    classifierVersion,
    tripTitle: trip.tripTitle ?? '',
    bookings: [...trip.bookings].sort(compareBookings).map((b) => ({
      id: b.id,
      kind: b.kind,
      title: b.title,
      location: b.location ?? '',
      artSubject: b.artSubject ?? '',
      startDate: b.startDate,
      endDate: b.endDate ?? '',
    })),
  };
  return createHash('sha256').update(JSON.stringify(canonical), 'utf8').digest('hex');
}

/** Code-unit order, the same on every server (unlike localeCompare). */
function compareBookings(a: SanitizedBooking, b: SanitizedBooking): number {
  return order(a.startDate, b.startDate) || order(a.endDate ?? '', b.endDate ?? '') || order(a.id, b.id);
}

function order(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

/** Cleaned text within [max] characters; rejects anything longer. */
function boundedText(value: unknown, max: number, what: string): string | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== 'string') throw new InvalidRequestError(`The ${what} wasn't text.`);
  const text = cleanText(value, Number.MAX_SAFE_INTEGER);
  if (text && text.length > max) throw new InvalidRequestError(`The ${what} is too long.`);
  return text;
}

const DATE = /^\d{4}-\d{2}-\d{2}$/;

export function isValidDate(value: unknown): value is string {
  if (typeof value !== 'string' || !DATE.test(value)) return false;
  const [y, m, d] = value.split('-').map(Number);
  const date = new Date(Date.UTC(y, m - 1, d));
  return date.getUTCFullYear() === y && date.getUTCMonth() === m - 1 && date.getUTCDate() === d;
}
