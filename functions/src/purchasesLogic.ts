/**
 * Pure rules for purchases (no Firestore, no network), so they're easy to
 * test. The handlers are in purchases.ts.
 *
 *   - The Annual Pass is RevenueCat's `plus` entitlement.
 *   - A Holiday Pass is the consumable `holiday_pass`, claimed for one trip
 *     with the dates the server reads (never sent by the app).
 *   - A trip's `premium` stamp is the best of its organiser's Annual Pass
 *     and the passes bought for it, so everyone on the trip gets Plus.
 */

import { DateSpan, TRIP_PASS_MAX_DAYS, tripPassLastDay } from './tripPass';

export const PLUS_ENTITLEMENT = 'plus';
export const HOLIDAY_PASS_PRODUCT = 'holiday_pass';

/**
 * Smart Imports anyone gets before premium is needed. Mirrors
 * `Pricing.freeSmartImports` in lib/domain/pricing.dart (a test keeps them
 * equal).
 */
export const FREE_SMART_IMPORTS = 3;

const DAY_MS = 24 * 60 * 60 * 1000;
const ISO_DAY = /^\d{4}-\d{2}-\d{2}$/;

function isDay(value: unknown): value is string {
  return typeof value === 'string' && ISO_DAY.test(value);
}

function addDays(day: string, days: number): string {
  return new Date(Date.parse(`${day}T00:00:00Z`) + days * DAY_MS).toISOString().slice(0, 10);
}

/**
 * A trip's first and last day, as the app works them out (TripPlan): its
 * planned dates widened by every booking. Null when it has no dates.
 */
export function tripSpan(
  trip: { plannedStart?: unknown; plannedEnd?: unknown },
  bookings: { startDate?: unknown; endDate?: unknown }[],
): DateSpan | null {
  let first = isDay(trip.plannedStart) ? trip.plannedStart : null;
  let last = isDay(trip.plannedEnd) ? trip.plannedEnd : first;
  for (const booking of bookings) {
    if (!isDay(booking.startDate)) continue;
    const end = isDay(booking.endDate) && booking.endDate > booking.startDate ? booking.endDate : booking.startDate;
    first = first === null || booking.startDate < first ? booking.startDate : first;
    last = last === null || end > last ? end : last;
  }
  return first === null || last === null ? null : { start: first, end: last < first ? first : last };
}

/** The dates a pass is claimed for: the trip's, at most 30 days. */
export function passSpanFor(span: DateSpan): DateSpan {
  const latest = addDays(span.start, TRIP_PASS_MAX_DAYS - 1);
  return { start: span.start, end: span.end > latest ? latest : span.end };
}

/**
 * The moment after [day] has ended everywhere on Earth (noon UTC the next
 * day), for `premium.until`: the app compares it with the phone's clock.
 */
export function afterDay(day: string): number {
  return Date.parse(`${addDays(day, 1)}T12:00:00Z`);
}

// RevenueCat's REST API (v1 GET /subscribers/{id}), only what's used.
export interface Subscriber {
  entitlements?: Record<string, {
    expires_date?: string | null;
    grace_period_expires_date?: string | null;
    product_identifier?: string;
  }>;
  subscriptions?: Record<string, {
    unsubscribe_detected_at?: string | null;
    refunded_at?: string | null;
  }>;
  non_subscriptions?: Record<string, {
    id?: string;
    store_transaction_id?: string;
    purchase_date?: string;
    store?: string;
    is_sandbox?: boolean;
  }[]>;
}

export interface PlusMirror {
  expiresAt: number;
  willRenew: boolean;
}

/** The Annual Pass from RevenueCat, or null when it isn't active at [now]. */
export function plusFromSubscriber(subscriber: Subscriber, now: number): PlusMirror | null {
  const plus = subscriber.entitlements?.[PLUS_ENTITLEMENT];
  if (!plus) return null;
  const expires = plus.expires_date == null ? Number.MAX_SAFE_INTEGER : Date.parse(plus.expires_date);
  const grace = plus.grace_period_expires_date ? Date.parse(plus.grace_period_expires_date) : NaN;
  const expiresAt = Math.max(expires, Number.isNaN(grace) ? -Infinity : grace);
  if (Number.isNaN(expiresAt) || expiresAt <= now) return null;
  const product = plus.product_identifier ?? '';
  const subscriptions = subscriber.subscriptions ?? {};
  const subscription = subscriptions[product]
    ?? Object.entries(subscriptions).find(([id]) => id.startsWith(`${product}:`))?.[1];
  return {
    expiresAt,
    willRenew: !subscription?.unsubscribe_detected_at && !subscription?.refunded_at,
  };
}

export interface PassTransaction {
  /** RevenueCat's id for the purchase: the key of its claim. */
  id: string;
  storeTransactionId: string;
  purchasedAt: number;
  store: string;
  sandbox: boolean;
}

/** Every Holiday Pass this customer has bought, newest first. */
export function holidayPassTransactions(subscriber: Subscriber): PassTransaction[] {
  const bought = subscriber.non_subscriptions?.[HOLIDAY_PASS_PRODUCT] ?? [];
  return bought
    .filter((t) => typeof t.id === 'string' && t.id.length > 0 && /^[^/]+$/.test(t.id))
    .map((t) => ({
      id: t.id!,
      storeTransactionId: t.store_transaction_id ?? '',
      purchasedAt: Date.parse(t.purchase_date ?? '') || 0,
      store: t.store ?? '',
      sandbox: t.is_sandbox === true,
    }))
    .sort((a, b) => b.purchasedAt - a.purchasedAt);
}

/**
 * The purchase to claim: the one the app just made ([transactionId], the
 * store's or RevenueCat's id) if it's free, else the newest unclaimed one
 * (the ids can differ between stores). Null when every pass is claimed.
 */
export function pickTransaction(
  transactions: PassTransaction[],
  transactionId: string,
  claimed: Set<string>,
): PassTransaction | null {
  const unclaimed = transactions.filter((t) => !claimed.has(t.id));
  return unclaimed.find((t) => t.storeTransactionId === transactionId || t.id === transactionId)
    ?? unclaimed[0]
    ?? null;
}

export interface PassRecord extends DateSpan {
  uid: string;
}

export interface PremiumStamp {
  grantedBy: string;
  until: number;
}

/**
 * When [pass] stops covering a trip running [span] (`premium.until`), or
 * null when it doesn't cover it at all (tripPassLastDay).
 */
export function passUntil(pass: DateSpan, span: DateSpan | null): number | null {
  const lastDay = tripPassLastDay(pass, span);
  return lastDay === null ? null : afterDay(lastDay);
}

/**
 * The `premium` stamp for a trip running [span]: the longest of its
 * organiser's Annual Pass and the Holiday Passes bought for it (each until
 * a week after the holiday, growing with it: tripPassLastDay).
 */
export function tripPremium(
  span: DateSpan | null,
  ownerPlus: { uid: string; expiresAt: number } | null,
  passes: PassRecord[],
): PremiumStamp | null {
  let best: PremiumStamp | null = ownerPlus ? { grantedBy: ownerPlus.uid, until: ownerPlus.expiresAt } : null;
  for (const pass of passes) {
    const until = passUntil(pass, span);
    if (until !== null && (best === null || until > best.until)) best = { grantedBy: pass.uid, until };
  }
  return best;
}

export function samePremium(a: unknown, b: PremiumStamp | null): boolean {
  if (b === null) return a == null;
  if (!a || typeof a !== 'object') return false;
  const stamp = a as Record<string, unknown>;
  return stamp.grantedBy === b.grantedBy && stamp.until === b.until;
}

/** Firebase uids (RevenueCat's app user ids here); not RevenueCat's anonymous ids. */
export function isFirebaseUid(id: unknown): id is string {
  return typeof id === 'string' && /^[A-Za-z0-9]{20,128}$/.test(id);
}

/** Everyone a RevenueCat webhook event is about (transfers name two). */
export function webhookUserIds(event: Record<string, unknown>): string[] {
  const ids = [
    event.app_user_id,
    event.original_app_user_id,
    ...(Array.isArray(event.aliases) ? event.aliases : []),
    ...(Array.isArray(event.transferred_from) ? event.transferred_from : []),
    ...(Array.isArray(event.transferred_to) ? event.transferred_to : []),
  ];
  return [...new Set(ids.filter(isFirebaseUid))].slice(0, 10);
}

/** What `users/{uid}` and a trip say about premium, as read from Firestore. */
export interface PremiumRecords {
  user?: { plus?: { expiresAt?: unknown }; tester?: unknown } | null;
  trip?: { memberIds?: unknown; premium?: { until?: unknown } } | null;
}

/**
 * Whether [uid] has premium features without asking the store: their
 * mirrored Annual Pass, the trip's own premium stamp (their pass, or Plus
 * travelling with it) for someone on it, or an account the operator marked
 * as a tester (`users/{uid}.tester`, set by hand in the console: store
 * reviewers, the team's own phones).
 */
export function premiumFromRecords(uid: string, records: PremiumRecords, now: number): boolean {
  const { user, trip } = records;
  if (user?.tester === true) return true;
  const plusUntil = user?.plus?.expiresAt;
  if (typeof plusUntil === 'number' && plusUntil > now) return true;
  const members = Array.isArray(trip?.memberIds) ? trip.memberIds : [];
  const tripUntil = trip?.premium?.until;
  return members.includes(uid) && typeof tripUntil === 'number' && tripUntil > now;
}

/**
 * The Holiday Pass a RevenueCat webhook event says was refunded (a
 * CANCELLATION of the `holiday_pass` product), or a refund taken back
 * (REFUND_REVERSED, App Store only): its store transaction. Null for every
 * other event.
 */
export function holidayPassRefund(event: Record<string, unknown>): { transactionId: string; reversed: boolean } | null {
  if (event.product_id !== HOLIDAY_PASS_PRODUCT) return null;
  const reversed = event.type === 'REFUND_REVERSED';
  if (event.type !== 'CANCELLATION' && !reversed) return null;
  const transactionId = event.transaction_id ?? event.original_transaction_id;
  if (typeof transactionId !== 'string' || !transactionId || transactionId.includes('/')) return null;
  return { transactionId, reversed };
}
