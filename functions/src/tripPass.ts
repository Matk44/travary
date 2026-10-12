/**
 * How long a Trip Pass keeps Plus on its trip, for the purchase mirror that
 * stamps `premium.until` on trips (when a pass is bought, and again when the
 * trip's dates change). Mirrors `tripPassLastDay` in lib/logic/access.dart;
 * both run the cases in tripPassCases.json, so they can't drift apart.
 *
 * A pass is bought for the trip's dates at the time. It grows with the same
 * holiday (the flight home added later), up to 30 days, until a week after
 * it ends; moving the trip to another time never takes the pass along,
 * and a trip moved or stretched back before those dates isn't covered at
 * all (a far-off pass would otherwise cover every trip until then).
 */

export const TRIP_PASS_GRACE_DAYS = 7;
export const TRIP_PASS_MAX_DAYS = 30;

/** Calendar dates as ISO strings ("2026-10-12"), first and last day. */
export interface DateSpan {
  start: string;
  end: string;
}

const DAY_MS = 24 * 60 * 60 * 1000;

function toDay(iso: string): number {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso);
  if (!match) throw new Error(`Not a date: ${iso}`);
  return Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3])) / DAY_MS;
}

function fromDay(day: number): string {
  return new Date(day * DAY_MS).toISOString().slice(0, 10);
}

/**
 * The last day [pass] keeps Plus on its trip, which now runs [trip] (null
 * when it has no dates), or null when the trip now covers other holidays
 * while the pass is on: moved to before the dates bought for, or stretched
 * back more than 30 days before them.
 */
export function tripPassLastDay(pass: DateSpan, trip: DateSpan | null): string | null {
  const passStart = toDay(pass.start);
  const passEnd = toDay(pass.end);
  const bought = fromDay(passEnd + TRIP_PASS_GRACE_DAYS);
  if (trip === null) return bought;
  const start = toDay(trip.start);
  const end = toDay(trip.end);
  if (end < passStart || start < passStart - TRIP_PASS_MAX_DAYS) return null;
  if (end <= passEnd) return bought;
  const overlaps = start <= passEnd && end >= passStart;
  const sameHoliday = overlaps && end - start + 1 <= TRIP_PASS_MAX_DAYS;
  return sameHoliday ? fromDay(end + TRIP_PASS_GRACE_DAYS) : bought;
}
