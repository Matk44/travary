/**
 * Flight alerts: pure rules (no Firestore, no network), so they're easy to
 * test. The handlers are in flightAlerts.ts.
 *
 *   - Which bookings are watched: flights with a number, from the day
 *     before to a year ahead, on a trip where someone has premium.
 *   - Who hears: everyone on the trip with premium on it (a Holiday Pass or
 *     Plus travelling with the trip, their own Plus, a tester account).
 *   - When a flight is checked: rarely while it's days away, often close
 *     to take-off and landing, less as the month's units run low.
 *   - What's worth a push: a change from what was last announced (a new
 *     time, a status, a gate, a belt), never small drifts.
 *   - The words of each push.
 */

import { cleanFlightNumber, FlightMovement, FlightStatusName, FlightStatusResult } from './flightStatusLogic';
import { premiumFromRecords, PremiumRecords } from './purchasesLogic';

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

// What's watched.

/** A booking as stored in Firestore (only what alerts use). */
export interface BookingRecord {
  kind?: unknown;
  startDate?: unknown;
  startTime?: unknown;
  location?: unknown;
  details?: unknown;
}

/** One flight booking to watch: the flight it's on and how to find its leg. */
export interface WatchedBooking {
  /** `watchedFlights/{key}`, shared by everyone on the flight: "BA283_2026-10-04". */
  key: string;
  number: string;
  date: string;
  /** The departure airport's IATA code when the booking names one (one number can fly several legs a day). */
  from: string | null;
  /** The booking's local departure read as UTC: off by the airport's offset, good enough until the first answer. */
  estimateMs: number;
}

export function flightKey(number: string, date: string): string {
  return `${number}_${date}`;
}

/**
 * An IATA airport code written in [location] ("London Heathrow (LHR)",
 * "LHR T5"), else null. Only capitals count. Mirrors `airportCodeIn` in
 * lib/logic/flight_status_text.dart.
 */
export function airportCodeIn(location: unknown): string | null {
  if (typeof location !== 'string') return null;
  const codes = location.match(/(?<![A-Za-z])[A-Z]{3}(?![A-Za-z])/g) ?? [];
  return codes.length === 1 ? codes[0] : null;
}

/**
 * The flight [booking] is on, if it's worth watching at [nowMs]: a flight
 * with a flight number leaving from yesterday (still in the air, or just
 * landed) to a year ahead.
 */
export function watchedFlightFor(booking: BookingRecord, nowMs: number): WatchedBooking | null {
  if (booking.kind !== 'flight') return null;
  const details = typeof booking.details === 'object' && booking.details !== null
    ? (booking.details as Record<string, unknown>)
    : {};
  const number = cleanFlightNumber(details.flightNumber);
  const date = typeof booking.startDate === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(booking.startDate)
    ? booking.startDate
    : null;
  if (!number || !date) return null;
  const today = Date.parse(new Date(nowMs).toISOString().slice(0, 10) + 'T00:00:00Z');
  const days = Math.round((Date.parse(`${date}T00:00:00Z`) - today) / DAY);
  if (Number.isNaN(days) || days < -1 || days > 365) return null;
  const time = typeof booking.startTime === 'string' && /^\d{2}:\d{2}$/.test(booking.startTime)
    ? booking.startTime
    : '12:00';
  return {
    key: flightKey(number, date),
    number,
    date,
    from: airportCodeIn(booking.location),
    estimateMs: Date.parse(`${date}T${time}:00Z`),
  };
}

// Who hears.

export type UserRecord = PremiumRecords['user'];
export type TripRecord = NonNullable<PremiumRecords['trip']>;

/**
 * Everyone on [trip] who gets its flight alerts: whoever has premium on it
 * (`premiumFromRecords`). On a trip with a Holiday Pass or its organiser's
 * Plus, that's everyone.
 */
export function alertRecipients(trip: TripRecord, users: Record<string, UserRecord | undefined>, now: number): string[] {
  const members = Array.isArray(trip.memberIds) ? trip.memberIds.filter((m): m is string => typeof m === 'string') : [];
  return members.filter((uid) => premiumFromRecords(uid, { user: users[uid], trip }, now));
}

// The month's allowance.

/** One billing period of the provider's plan: `flightUsage/{id}` counts its units. */
export interface BillingPeriod {
  /** Its first day, "2026-10-01". */
  id: string;
  startMs: number;
  endMs: number;
}

/** The billing period [nowMs] falls in, for a plan renewing on day [billingDay] (1–28) of each month. */
export function billingPeriod(nowMs: number, billingDay: number): BillingPeriod {
  const day = Math.min(Math.max(Math.trunc(billingDay) || 1, 1), 28);
  const now = new Date(nowMs);
  const month = now.getUTCMonth() - (now.getUTCDate() < day ? 1 : 0);
  const startMs = Date.UTC(now.getUTCFullYear(), month, day);
  const endMs = Date.UTC(now.getUTCFullYear(), month + 1, day);
  return { id: new Date(startMs).toISOString().slice(0, 10), startMs, endMs };
}

/**
 * How freely flights can be checked:
 *   - normal: on schedule.
 *   - tight: spending faster than the month allows; checks further apart.
 *   - low: under a tenth left; only the last 3 hours before take-off and
 *     the flight itself.
 *   - out: nothing left beyond a reserve for the flight page; no checks
 *     until the allowance renews.
 */
export type BudgetLevel = 'normal' | 'tight' | 'low' | 'out';

export function budgetLevel(usedUnits: number, monthlyUnits: number, period: BillingPeriod, nowMs: number): BudgetLevel {
  const left = monthlyUnits - usedUnits;
  if (left <= Math.max(50, monthlyUnits * 0.02)) return 'out';
  if (left < monthlyUnits * 0.1) return 'low';
  const elapsed = Math.min(Math.max((nowMs - period.startMs) / (period.endMs - period.startMs), 0), 1);
  return usedUnits / monthlyUnits > elapsed + 0.1 ? 'tight' : 'normal';
}

// When to check.

export interface CheckTiming {
  /** Best known take-off (UTC ms): the airline's revised time, else its schedule, else the booking's [WatchedBooking.estimateMs]. */
  departs: number;
  /** Best known landing (UTC ms), once the airline has said. */
  arrives: number | null;
  /** The last answer's status; null before any answer. */
  status: FlightStatusName | null;
  /** Lookups in a row that found nothing (a wrong number, or not in the schedule yet). */
  empties: number;
}

const IN_THE_AIR: FlightStatusName[] = ['Departed', 'EnRoute', 'Approaching'];

/** Minutes between checks at each level, close to take-off and in the air. */
const STEPS = {
  lastHour: { normal: 20, tight: 30, low: 30 },
  lastThreeHours: { normal: 40, tight: 60, low: 60 },
  shouldHaveLeft: { normal: 15, tight: 20, low: 30 },
  landing: { normal: 10, tight: 15, low: 20 },
} as const;

/**
 * When to look the flight up next, or null when nothing more is worth
 * checking. With an ordinary 2-hour flight and units to spare, about 20
 * checks (40 units): 3 days before (schedule changes), the day before,
 * every 4 hours on the day, every 40 then 20 minutes in the last 3 hours,
 * once it should have left, 30 minutes before landing and every 10 until
 * it has, then the belt for 45 minutes.
 */
export function nextCheckAt(flight: CheckTiming, now: number, level: BudgetLevel): number | null {
  const { departs, arrives, status } = flight;
  if (now > departs + 36 * HOUR || flight.empties >= 3) return null;
  if (level === 'out') return now + HOUR;
  const later = (ms: number) => Math.max(ms, now + MINUTE);

  if (status === 'Canceled') {
    // Now and then until it should have left: cancellations are sometimes taken back.
    return level === 'low' || now > departs + HOUR ? null : later(Math.min(now + 2 * HOUR, departs + HOUR));
  }
  if (status === 'Arrived') {
    // The baggage belt, when the airport shares it.
    const landed = arrives ?? now;
    return level === 'normal' && now < landed + 45 * MINUTE ? later(now + 15 * MINUTE) : null;
  }
  if (status === 'Diverted') {
    const due = (arrives ?? departs + 12 * HOUR) + 2 * HOUR;
    return level === 'low' || now > due ? null : later(now + 30 * MINUTE);
  }
  if (status !== null && IN_THE_AIR.includes(status)) {
    if (arrives === null) return later(now + 30 * MINUTE);
    if (now < arrives - 30 * MINUTE) return later(arrives - 30 * MINUTE);
    return later(now + (now > arrives + 3 * HOUR ? 30 : STEPS.landing[level]) * MINUTE);
  }

  // Not gone yet (or not known to have).
  const ahead = departs - now;
  if (status === null && flight.empties > 0 && ahead <= DAY) return later(now + 3 * HOUR);
  if (ahead <= 0) {
    return later(now + (-ahead < 2 * HOUR ? STEPS.shouldHaveLeft[level] : 60) * MINUTE);
  }
  if (ahead <= HOUR) return later(Math.min(now + STEPS.lastHour[level] * MINUTE, departs));
  if (ahead <= 3 * HOUR) return later(Math.min(now + STEPS.lastThreeHours[level] * MINUTE, departs - HOUR));
  if (level === 'low') return later(departs - 3 * HOUR);
  if (ahead <= DAY) return later(Math.min(now + (level === 'tight' ? 8 : 4) * HOUR, departs - 3 * HOUR));
  // The first look (firstCheckAt) is up to a day early for the time zone:
  // it counts as the one 3 days before.
  if (ahead <= 4 * DAY || level === 'tight') return later(departs - DAY);
  return later(departs - 3 * DAY);
}

/**
 * Whether a check that's due is still worth its units at [level]: nothing
 * once the month's units are out, and only the hours that matter when
 * they're low (the check scheduled earlier assumed more).
 */
export function worthCheckingNow(flight: CheckTiming, now: number, level: BudgetLevel): boolean {
  if (level === 'out') return false;
  if (level !== 'low') return true;
  if (flight.status !== null && IN_THE_AIR.includes(flight.status)) return true;
  if (flight.status === 'Arrived' || flight.status === 'Canceled') return false;
  return flight.departs - now <= 3 * HOUR && now <= flight.departs + 2 * HOUR;
}

/** The first look at a newly watched flight: 3 days before it leaves (allowing for the estimate's time zone), or now. */
export function firstCheckAt(estimateMs: number, now: number): number {
  return Math.max(now, estimateMs - 3 * DAY - 14 * HOUR);
}

/** After a failed lookup: soon, then less often, never later than the check it replaces. */
export function retryAt(failures: number, now: number, scheduled: number | null): number {
  const wait = Math.min(5 * MINUTE * 2 ** Math.max(failures - 1, 0), HOUR);
  return scheduled === null ? now + wait : Math.min(now + wait, Math.max(scheduled, now + MINUTE));
}

/** [leg]'s timing for [nextCheckAt]: the airline's times when it has them, else the booking's. */
export function timingOf(leg: FlightStatusResult | null, estimateMs: number, empties: number): CheckTiming {
  return {
    departs: utcOf(leg?.departure) ?? estimateMs,
    arrives: utcOf(leg?.arrival) ?? null,
    status: leg?.status ?? null,
    empties,
  };
}

function utcOf(end: FlightMovement | undefined): number | null {
  const iso = end?.revisedUtc ?? end?.scheduledUtc;
  const ms = iso ? Date.parse(iso) : NaN;
  return Number.isNaN(ms) ? null : ms;
}

// What changed.

export type FlightChange =
  | { kind: 'cancelled' }
  | { kind: 'mayBeCancelled' }
  | { kind: 'notCancelled' }
  | { kind: 'diverted' }
  | { kind: 'landed' }
  | { kind: 'departed' }
  | { kind: 'departureTime'; from: string; to: string; later: boolean; schedule: boolean }
  | { kind: 'delayed' }
  | { kind: 'gateClosed' }
  | { kind: 'boarding' }
  | { kind: 'arrivalTime'; from: string; to: string; later: boolean }
  | { kind: 'gate'; from: string | null; to: string }
  | { kind: 'terminal'; from: string; to: string }
  | { kind: 'checkInOpen' }
  | { kind: 'belt'; to: string };

export type FlightChangeKind = FlightChange['kind'];

type Change<K extends FlightChangeKind> = Extract<FlightChange, { kind: K }>;

/** How far along a flight is, to tell news (boarding) from going back (a stale answer). */
const PROGRESS: Record<FlightStatusName, number> = {
  Unknown: 0, Expected: 0, Delayed: 0, CanceledUncertain: 0, Canceled: 0,
  CheckIn: 1, Boarding: 2, GateClosed: 3, Departed: 4, EnRoute: 4, Diverted: 4, Approaching: 5, Arrived: 6,
};

/** Times closer than this to the last one announced aren't news. */
const TIME_CHANGE = 5 * MINUTE;

/** In the air, landing estimates move about: only bigger changes are news. */
const LANDING_CHANGE = 15 * MINUTE;

const minutesApart = (a: string | null, b: string | null) =>
  a && b ? Math.abs(Date.parse(a) - Date.parse(b)) : 0;

/**
 * What changed between [announced] (what everyone was last told) and
 * [latest], and the new baseline: [latest], except times that only drifted
 * (kept as announced, so small drifts add up to news) and details the
 * latest answer dropped (a gate that vanishes and comes back isn't news).
 * The first answer is the baseline: it announces only a cancellation.
 */
export function flightChanges(
  announced: FlightStatusResult | null,
  latest: FlightStatusResult,
): { changes: FlightChange[]; baseline: FlightStatusResult } {
  const baseline: FlightStatusResult = { ...latest, departure: { ...latest.departure }, arrival: { ...latest.arrival } };
  if (!announced) {
    // Too important to keep for the next change.
    if (latest.status === 'Canceled') return { changes: [{ kind: 'cancelled' }], baseline };
    if (latest.status === 'CanceledUncertain') return { changes: [{ kind: 'mayBeCancelled' }], baseline };
    return { changes: [], baseline };
  }
  const was = announced.status;
  const now = latest.status;
  const moved = was !== now;
  if (moved && now === 'Canceled') return { changes: [{ kind: 'cancelled' }], baseline };

  const changes: FlightChange[] = [];
  if (moved && now === 'CanceledUncertain') changes.push({ kind: 'mayBeCancelled' });
  else if (moved && (was === 'Canceled' || was === 'CanceledUncertain') && now !== 'Unknown') {
    changes.push({ kind: 'notCancelled' });
  }
  if (moved && now === 'Diverted') changes.push({ kind: 'diverted' });
  else if (moved && now === 'Arrived') changes.push({ kind: 'landed' });
  else if (moved && IN_THE_AIR.includes(now) && PROGRESS[was] < 4) changes.push({ kind: 'departed' });
  else if (moved && now === 'GateClosed' && PROGRESS[was] < 3) changes.push({ kind: 'gateClosed' });
  else if (moved && now === 'Boarding' && PROGRESS[was] < 2) changes.push({ kind: 'boarding' });
  else if (moved && now === 'CheckIn' && PROGRESS[was] < 1) changes.push({ kind: 'checkInOpen' });

  const gone = PROGRESS[now] >= 4;
  const dep = announced.departure;
  const newDep = latest.departure;
  let newTime = false;
  if (!gone) {
    const from = dep.revisedUtc ?? dep.scheduledUtc;
    const to = newDep.revisedUtc ?? newDep.scheduledUtc;
    if (minutesApart(from, to) >= TIME_CHANGE) {
      newTime = true;
      changes.push({
        kind: 'departureTime',
        from: (dep.revised ?? dep.scheduled)!,
        to: (newDep.revised ?? newDep.scheduled)!,
        later: Date.parse(to!) > Date.parse(from!),
        schedule: minutesApart(dep.scheduledUtc, newDep.scheduledUtc) >= TIME_CHANGE,
      });
    } else {
      keepTimes(baseline.departure, dep);
    }
    if (!newTime && moved && now === 'Delayed') changes.push({ kind: 'delayed' });

    if (newDep.gate && newDep.gate !== dep.gate) changes.push({ kind: 'gate', from: dep.gate, to: newDep.gate });
    if (newDep.terminal && dep.terminal && newDep.terminal !== dep.terminal) {
      changes.push({ kind: 'terminal', from: dep.terminal, to: newDep.terminal });
    }
  }
  baseline.departure.gate ??= dep.gate;
  baseline.departure.terminal ??= dep.terminal;
  baseline.departure.checkInDesk ??= dep.checkInDesk;

  const arr = announced.arrival;
  const newArr = latest.arrival;
  if (now !== 'Arrived' && now !== 'Diverted') {
    const from = arr.revisedUtc ?? arr.scheduledUtc;
    const to = newArr.revisedUtc ?? newArr.scheduledUtc;
    const inAir = IN_THE_AIR.includes(now);
    // Before take-off a landing time moves with the take-off time; on its
    // own it's news only when the airline changes the schedule.
    const news = inAir
      ? minutesApart(from, to) >= LANDING_CHANGE
      : !newTime && minutesApart(arr.scheduledUtc, newArr.scheduledUtc) >= TIME_CHANGE;
    if (news) {
      changes.push({
        kind: 'arrivalTime',
        from: (arr.revised ?? arr.scheduled)!,
        to: (newArr.revised ?? newArr.scheduled)!,
        later: Date.parse(to!) > Date.parse(from!),
      });
    } else if (!newTime) {
      keepTimes(baseline.arrival, arr);
    }
  }
  if (newArr.baggageBelt && newArr.baggageBelt !== arr.baggageBelt) changes.push({ kind: 'belt', to: newArr.baggageBelt });
  baseline.arrival.baggageBelt ??= arr.baggageBelt;
  baseline.arrival.gate ??= arr.gate;
  baseline.arrival.terminal ??= arr.terminal;
  return { changes, baseline };
}

function keepTimes(into: FlightMovement, from: FlightMovement): void {
  into.scheduled = from.scheduled;
  into.revised = from.revised;
  into.scheduledUtc = from.scheduledUtc;
  into.revisedUtc = from.revisedUtc;
  into.delayMinutes = from.delayMinutes;
}

/** Which of a flight number's legs [leg] is: announcements are kept per leg. */
export function legKey(leg: FlightStatusResult, index: number): string {
  return leg.departure.airport ?? `leg${index}`;
}

// The words.

export interface AlertText {
  title: string;
  body: string;
  /** The main change, for the app (opening the flight) and counting. */
  kind: FlightChangeKind;
}

/** Most important first: one push says the biggest news, with the smaller news after it. */
const PRIORITY: FlightChangeKind[] = [
  'cancelled', 'mayBeCancelled', 'notCancelled', 'diverted', 'landed', 'departed', 'departureTime', 'delayed',
  'gateClosed', 'boarding', 'arrivalTime', 'gate', 'terminal', 'checkInOpen', 'belt',
];

/**
 * The push for [changes] to [leg] ([number] as the watch has it, when the
 * answer has none). Null when nothing changed. Times are the airport's
 * own, like the ticket: "Now leaves at 10:15am instead of 9:30am."
 */
export function alertText(changes: FlightChange[], leg: FlightStatusResult, number: string): AlertText | null {
  const ordered = [...changes].sort((a, b) => PRIORITY.indexOf(a.kind) - PRIORITY.indexOf(b.kind));
  const main = ordered[0];
  if (!main) return null;
  const n = leg.number || displayNumber(number);
  const dep = leg.departure;
  const arr = leg.arrival;
  const from = dep.city ?? dep.airportName ?? dep.airport;
  const to = arr.city ?? arr.airportName ?? arr.airport;
  const leaves = dep.revised ?? dep.scheduled;
  const lands = arr.revised ?? arr.scheduled;
  const leavesAt = leaves ? `Leaves at ${clock(leaves, dep.scheduled)}.` : null;
  const gate = ordered.find((c): c is Change<'gate'> => c.kind === 'gate');
  const terminal = ordered.find((c): c is Change<'terminal'> => c.kind === 'terminal');
  const belt = ordered.find((c): c is Change<'belt'> => c.kind === 'belt');
  const said = new Set<FlightChangeKind>([main.kind]);

  let title: string;
  let body: (string | null)[];
  switch (main.kind) {
    case 'cancelled':
      title = `${n} is cancelled`;
      body = [
        from && to && dep.scheduled ? `${from} to ${to}, ${dayShort(dep.scheduled)}.` : null,
        'Your airline will say what happens next.',
      ];
      break;
    case 'mayBeCancelled':
      title = `${n} may be cancelled`;
      body = ['The airline shows it as possibly cancelled. Check with them before you set off.'];
      break;
    case 'notCancelled':
      title = `${n} is no longer cancelled`;
      body = [leavesAt];
      break;
    case 'diverted':
      title = `${n} has been diverted`;
      body = [to ? `It won't land in ${to} as planned. Check with the airline.` : 'Check with the airline.'];
      break;
    case 'landed':
      title = `${n} has landed`;
      body = [lands ? `Landed${to ? ` in ${to}` : ''} at ${clock(lands, arr.scheduled)}.` : null];
      break;
    case 'departed':
      title = `${n} has taken off`;
      body = [lands ? `Lands${to ? ` in ${to}` : ''} at ${clock(lands, arr.scheduled)}.` : null];
      break;
    case 'departureTime':
      title = main.schedule ? `${n} has a new time` : main.later ? `${n} is delayed` : `${n} leaves earlier`;
      body = [
        `${main.schedule ? 'The airline has moved it: now' : 'Now'} leaves at ${clock(main.to, main.from)} instead of ${clock(main.from, main.from)}.`,
      ];
      said.add('delayed');
      break;
    case 'delayed':
      title = `${n} is delayed`;
      body = ['The airline hasn\'t given a new time yet.'];
      break;
    case 'gateClosed':
      title = `${n}: the gate has closed`;
      body = [leavesAt];
      break;
    case 'boarding':
      title = `${n} is boarding`;
      body = [dep.gate ? `Gate ${dep.gate}.` : leavesAt];
      if (dep.gate) said.add('gate');
      break;
    case 'arrivalTime':
      title = main.later ? `${n} will land later` : `${n} will land earlier`;
      body = [`Now lands at ${clock(main.to, main.from)} instead of ${clock(main.from, main.from)}.`];
      break;
    case 'gate':
      title = main.from ? `Gate change for ${n}` : `${n} leaves from gate ${main.to}`;
      body = [main.from ? `Now gate ${main.to}, not ${main.from}.` : leavesAt];
      break;
    case 'terminal':
      title = `Terminal change for ${n}`;
      body = [`Now leaves from Terminal ${main.to}, not ${main.from}.`];
      break;
    case 'checkInOpen':
      title = `Check-in is open for ${n}`;
      body = [
        leaves ? `Leaves at ${clock(leaves, dep.scheduled)}${dep.terminal ? ` from Terminal ${dep.terminal}` : ''}.` : null,
        dep.checkInDesk ? `Check-in ${dep.checkInDesk}.` : null,
      ];
      break;
    case 'belt':
      title = `Bags from ${n}`;
      body = [`Belt ${main.to}${arr.airportName ? ` at ${arr.airportName}` : ''}.`];
      said.add('belt');
      break;
  }
  // The smaller news that came with it.
  if (gate && !said.has('gate') && main.kind !== 'landed' && main.kind !== 'cancelled') {
    body.push(gate.from ? `Now gate ${gate.to}, not ${gate.from}.` : `Gate ${gate.to}.`);
  }
  if (terminal && !said.has('terminal') && main.kind !== 'cancelled') body.push(`Now from Terminal ${terminal.to}.`);
  if (belt && !said.has('belt')) body.push(`Bags on belt ${belt.to}.`);
  const text = body.filter((s): s is string => !!s).join(' ');
  return { title, body: text || `${from && to ? `${from} to ${to}` : 'Open Travary for the latest'}.`, kind: main.kind };
}

/** "BA283" → "BA 283", as tickets print it. */
export function displayNumber(number: string): string {
  const match = /^([A-Z]{3}|[A-Z0-9]{2})(\d{1,4}[A-Z]?)$/.exec(number);
  return match ? `${match[1]} ${match[2]}` : number;
}

const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/** "2026-10-14T…" → "Wed 14 Oct", like the app's `formatDayShort`. */
export function dayShort(local: string): string {
  const date = new Date(`${local.slice(0, 10)}T00:00:00Z`);
  return `${DAYS[date.getUTCDay()]} ${date.getUTCDate()} ${MONTHS[date.getUTCMonth()]}`;
}

/**
 * "2026-10-14T09:40" → "9:40am", like the app's `formatClock`, with the day
 * when it isn't [reference]'s ("1:10am Thu 15 Oct").
 */
export function clock(local: string, reference: string | null): string {
  const hour = Number(local.slice(11, 13));
  const minute = local.slice(14, 16);
  const time = `${hour % 12 === 0 ? 12 : hour % 12}:${minute}${hour < 12 ? 'am' : 'pm'}`;
  return reference && reference.slice(0, 10) !== local.slice(0, 10) ? `${time} ${dayShort(local)}` : time;
}

// The live line on the trip.

/** A booking's live state on its trip (`trips/{id}.liveFlights.{bookingId}`): its leg and when it was checked. */
export type LiveFlight = FlightStatusResult & { checkedAt: number };

/**
 * Whether a trip's copy of a flight's state needs writing: it has changed,
 * or its "checked" time is half an hour behind (so the app can tell a
 * paused check from a quiet flight without a write on every check).
 */
export function liveNeedsWrite(stored: unknown, leg: FlightStatusResult, now: number): boolean {
  if (!stored || typeof stored !== 'object') return true;
  const { checkedAt, ...rest } = stored as Record<string, unknown>;
  if (typeof checkedAt !== 'number' || now - checkedAt >= 30 * MINUTE) return true;
  return JSON.stringify(sortKeys(rest)) !== JSON.stringify(sortKeys(leg));
}

function sortKeys(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(sortKeys);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).sort().map((k) => [k, sortKeys((value as Record<string, unknown>)[k])]));
  }
  return value;
}
