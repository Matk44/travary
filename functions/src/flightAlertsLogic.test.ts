import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  airportCodeIn, alertRecipients, alertText, billingPeriod, budgetLevel, BudgetLevel, CheckTiming, clock,
  displayNumber, FlightChange, flightChanges, firstCheckAt, liveNeedsWrite, nextCheckAt, retryAt, timingOf,
  watchedFlightFor, worthCheckingNow,
} from './flightAlertsLogic';
import { FlightMovement, FlightStatusName, FlightStatusResult } from './flightStatusLogic';

const MIN = 60_000;
const HOUR = 60 * MIN;
const DAY = 24 * HOUR;
const at = (iso: string) => Date.parse(iso);

function end(over: Partial<FlightMovement> = {}): FlightMovement {
  return {
    airport: null, airportName: null, airportFullName: null, city: null,
    scheduled: null, revised: null, scheduledUtc: null, revisedUtc: null, delayMinutes: null,
    terminal: null, gate: null, checkInDesk: null, baggageBelt: null,
    ...over,
  };
}

/** BA 2037, Gatwick 9:30am (BST) to Orlando 2:30pm (EDT), 14 October 2026. */
function leg(status: FlightStatusName = 'Expected', over: { departure?: Partial<FlightMovement>; arrival?: Partial<FlightMovement> } = {}): FlightStatusResult {
  return {
    number: 'BA 2037',
    airline: 'British Airways',
    status,
    departure: end({
      airport: 'LGW', airportName: 'Gatwick', city: 'London',
      scheduled: '2026-10-14T09:30', scheduledUtc: '2026-10-14T08:30:00.000Z', terminal: 'S',
      ...over.departure,
    }),
    arrival: end({
      airport: 'MCO', airportName: 'Orlando', city: 'Orlando',
      scheduled: '2026-10-14T14:30', scheduledUtc: '2026-10-14T18:30:00.000Z', terminal: 'B',
      ...over.arrival,
    }),
    updatedAt: null,
  };
}

/** [base] leaving [minutes] late (negative: early), the airline's revised time. */
function late(minutes: number, status: FlightStatusName = 'Delayed'): FlightStatusResult {
  const utc = new Date(at('2026-10-14T08:30:00Z') + minutes * MIN);
  const local = new Date(utc.getTime() + HOUR).toISOString().slice(0, 16);
  return leg(status, { departure: { revised: local, revisedUtc: utc.toISOString() } });
}

const kinds = (changes: FlightChange[]) => changes.map((c) => c.kind);

// What's watched.

test('a flight booking with a number is watched from the day before to a year ahead', () => {
  const now = at('2026-10-12T10:00:00Z');
  const booking = {
    kind: 'flight', startDate: '2026-10-14', startTime: '09:30', location: 'London Gatwick (LGW)',
    details: { flightNumber: 'ba 2037' },
  };
  assert.deepEqual(watchedFlightFor(booking, now), {
    key: 'BA2037_2026-10-14',
    number: 'BA2037',
    date: '2026-10-14',
    from: 'LGW',
    estimateMs: at('2026-10-14T09:30:00Z'),
  });
  assert.equal(watchedFlightFor({ ...booking, startTime: null }, now)?.estimateMs, at('2026-10-14T12:00:00Z'), 'no time: midday');
  assert.equal(watchedFlightFor({ ...booking, startDate: '2026-10-11' }, now)?.date, '2026-10-11', 'yesterday: may still be flying');
  assert.equal(watchedFlightFor({ ...booking, startDate: '2026-10-10' }, now), null, 'long gone');
  assert.equal(watchedFlightFor({ ...booking, startDate: '2027-10-14' }, now), null, 'past the schedules');
  assert.equal(watchedFlightFor({ ...booking, kind: 'stay' }, now), null);
  assert.equal(watchedFlightFor({ ...booking, details: {} }, now), null, 'no flight number');
  assert.equal(watchedFlightFor({ ...booking, details: { flightNumber: 'the 9am one' } }, now), null);
});

test('airport codes are read like the app reads them', () => {
  assert.equal(airportCodeIn('London Heathrow (LHR)'), 'LHR');
  assert.equal(airportCodeIn('LHR T5'), 'LHR');
  assert.equal(airportCodeIn('London Heathrow'), null);
  assert.equal(airportCodeIn('LHR to JFK'), null, 'two codes: no telling');
  assert.equal(airportCodeIn(null), null);
});

// Who hears.

test('everyone on a trip with a pass hears; otherwise only those with their own premium', () => {
  const now = at('2026-10-12T10:00:00Z');
  const members = ['alice', 'bob', 'cara'];
  const stamped = { memberIds: members, premium: { until: now + DAY } };
  assert.deepEqual(alertRecipients(stamped, {}, now), members);
  assert.deepEqual(alertRecipients({ memberIds: members, premium: { until: now - 1 } }, {}, now), [], 'the pass has run out');
  assert.deepEqual(
    alertRecipients({ memberIds: members }, { bob: { plus: { expiresAt: now + DAY } }, cara: { tester: true } }, now),
    ['bob', 'cara'],
  );
  assert.deepEqual(alertRecipients({ memberIds: members }, { bob: { plus: { expiresAt: now - 1 } } }, now), []);
});

// The month's units.

test('billing periods start on the plan\'s day', () => {
  assert.deepEqual(billingPeriod(at('2026-10-12T10:00:00Z'), 1), {
    id: '2026-10-01', startMs: at('2026-10-01T00:00:00Z'), endMs: at('2026-11-01T00:00:00Z'),
  });
  assert.equal(billingPeriod(at('2026-10-12T10:00:00Z'), 11).id, '2026-10-11');
  assert.equal(billingPeriod(at('2026-10-10T10:00:00Z'), 11).id, '2026-09-11');
  assert.equal(billingPeriod(at('2027-01-05T10:00:00Z'), 11).id, '2026-12-11', 'across the new year');
  assert.equal(billingPeriod(at('2026-10-12T10:00:00Z'), 31).id, '2026-09-28', 'at most the 28th');
});

test('checks slow down as the month\'s units run low', () => {
  const period = billingPeriod(at('2026-10-16T00:00:00Z'), 1);
  const mid = at('2026-10-16T12:00:00Z'); // about half way
  assert.equal(budgetLevel(2000, 5000, period, mid), 'normal');
  assert.equal(budgetLevel(3200, 5000, period, mid), 'tight', 'spending faster than the month allows');
  assert.equal(budgetLevel(4600, 5000, period, mid), 'low');
  assert.equal(budgetLevel(4900, 5000, period, mid), 'out', 'a reserve stays for the flight page');
  assert.equal(budgetLevel(5000, 5000, period, mid), 'out');
});

// When to check.

const departs = at('2026-10-14T08:30:00Z');
const arrives = at('2026-10-14T18:30:00Z');

/** The status a flight shows at [now]: on time, boarding 40 minutes before, landed on time. */
function statusAt(now: number): FlightStatusName | null {
  if (now >= arrives) return 'Arrived';
  if (now >= departs + 5 * MIN) return 'EnRoute';
  if (now >= departs - 15 * MIN) return 'GateClosed';
  if (now >= departs - 40 * MIN) return 'Boarding';
  if (now >= departs - 3 * HOUR) return 'CheckIn';
  return 'Expected';
}

/** Every check of a flight watched from [from], at [level]. */
function simulate(from: number, level: BudgetLevel): number[] {
  const checks: number[] = [];
  let next: number | null = firstCheckAt(departs - HOUR, from);
  while (next !== null && checks.length < 200) {
    checks.push(next);
    const timing: CheckTiming = { departs, arrives, status: statusAt(next), empties: 0 };
    next = nextCheckAt(timing, next, level);
  }
  return checks;
}

test('a flight is checked about 20 times, mostly close to take-off and landing', () => {
  const checks = simulate(at('2026-10-01T09:00:00Z'), 'normal');
  assert.ok(checks.length >= 15 && checks.length <= 25, `${checks.length} checks`);
  assert.ok(checks[0] <= departs - 3 * DAY && checks[0] > departs - 4 * DAY, 'first: three days before');
  assert.equal(checks[1], departs - DAY, 'then the day before');
  const lastThreeHours = checks.filter((t) => t >= departs - 3 * HOUR && t <= departs);
  assert.ok(lastThreeHours.length >= 6, 'often in the last three hours');
  assert.ok(checks.includes(departs), 'at take-off');
  assert.ok(checks.includes(arrives - 30 * MIN), 'half an hour before landing');
  assert.ok(checks.every((t, i) => i === 0 || t > checks[i - 1]), 'always forwards');
  assert.ok(checks.at(-1)! <= arrives + 45 * MIN, 'the belt for 45 minutes, then done');
});

test('fewer checks when units run short, and none once they\'re out', () => {
  const from = at('2026-10-01T09:00:00Z');
  const normal = simulate(from, 'normal').length;
  const tight = simulate(from, 'tight').length;
  const low = simulate(from, 'low');
  assert.ok(tight < normal, `tight ${tight} < normal ${normal}`);
  assert.ok(low.length < tight, `low ${low.length} < tight ${tight}`);
  assert.ok(low.filter((t) => t < departs - 3 * HOUR).length <= 1, 'low: only the last 3 hours (after a first look)');
  const now = departs - 2 * HOUR;
  assert.equal(nextCheckAt({ departs, arrives, status: 'Expected', empties: 0 }, now, 'out'), now + HOUR);
});

test('a flight nobody can find is given up on', () => {
  const now = departs - 10 * HOUR;
  assert.equal(nextCheckAt({ departs, arrives: null, status: null, empties: 1 }, now, 'normal'), now + 3 * HOUR);
  assert.equal(nextCheckAt({ departs, arrives: null, status: null, empties: 3 }, now, 'normal'), null);
});

test('cancelled flights are looked at now and then until they should have left', () => {
  const now = departs - 5 * HOUR;
  assert.equal(nextCheckAt({ departs, arrives, status: 'Canceled', empties: 0 }, now, 'normal'), now + 2 * HOUR);
  assert.equal(nextCheckAt({ departs, arrives, status: 'Canceled', empties: 0 }, departs + 2 * HOUR, 'normal'), null);
  assert.equal(nextCheckAt({ departs, arrives, status: 'Canceled', empties: 0 }, now, 'low'), null);
});

test('with few units left, only the hours that matter are checked', () => {
  const far: CheckTiming = { departs, arrives, status: 'Expected', empties: 0 };
  assert.equal(worthCheckingNow(far, departs - 10 * HOUR, 'low'), false);
  assert.equal(worthCheckingNow(far, departs - 2 * HOUR, 'low'), true);
  assert.equal(worthCheckingNow({ ...far, status: 'EnRoute' }, departs + 5 * HOUR, 'low'), true);
  assert.equal(worthCheckingNow({ ...far, status: 'Arrived' }, arrives + 10 * MIN, 'low'), false, 'no belt');
  assert.equal(worthCheckingNow(far, departs - 10 * HOUR, 'normal'), true);
  assert.equal(worthCheckingNow(far, departs - HOUR, 'out'), false);
});

test('failed lookups are retried soon, then less often', () => {
  const now = departs - 10 * HOUR;
  assert.equal(retryAt(1, now, now + 4 * HOUR), now + 5 * MIN);
  assert.equal(retryAt(3, now, now + 4 * HOUR), now + 20 * MIN);
  assert.equal(retryAt(9, now, now + 4 * HOUR), now + HOUR);
  assert.equal(retryAt(3, now, now + 10 * MIN), now + 10 * MIN, 'never later than planned');
});

test('the airline\'s times beat the booking\'s guess', () => {
  const timing = timingOf(late(45), departs + 3 * HOUR, 0);
  assert.equal(timing.departs, departs + 45 * MIN);
  assert.equal(timing.arrives, arrives);
  assert.equal(timing.status, 'Delayed');
  assert.equal(timingOf(null, departs + 3 * HOUR, 2).departs, departs + 3 * HOUR);
});

// What changed.

test('the first answer is the starting point, unless it\'s a cancellation', () => {
  assert.deepEqual(flightChanges(null, late(45)).changes, []);
  assert.deepEqual(kinds(flightChanges(null, leg('Canceled')).changes), ['cancelled']);
  assert.deepEqual(kinds(flightChanges(null, leg('CanceledUncertain')).changes), ['mayBeCancelled']);
});

test('a new time of 5 minutes or more is news; small drifts add up', () => {
  const delay = flightChanges(leg(), late(45)).changes;
  assert.deepEqual(delay, [{ kind: 'departureTime', from: '2026-10-14T09:30', to: '2026-10-14T10:15', later: true, schedule: false }]);

  const drift = flightChanges(leg('Expected'), late(3, 'Expected'));
  assert.deepEqual(drift.changes, []);
  assert.equal(drift.baseline.departure.revisedUtc, null, 'the drift isn\'t taken as told');
  assert.deepEqual(kinds(flightChanges(drift.baseline, late(6, 'Expected')).changes), ['departureTime']);

  const earlier = flightChanges(leg(), late(-20, 'Expected')).changes[0];
  assert.equal(earlier.kind === 'departureTime' && earlier.later, false);
});

test('a moved schedule is told apart from a delay', () => {
  const moved = leg('Expected', { departure: { scheduled: '2026-10-14T10:40', scheduledUtc: '2026-10-14T09:40:00.000Z' } });
  const [change] = flightChanges(leg(), moved).changes;
  assert.equal(change.kind === 'departureTime' && change.schedule, true);
});

test('"Delayed" without a new time is news once', () => {
  assert.deepEqual(kinds(flightChanges(leg('Expected'), leg('Delayed')).changes), ['delayed']);
  assert.deepEqual(kinds(flightChanges(leg('Delayed'), leg('Delayed')).changes), []);
});

test('each step towards take-off is news once, and a step back isn\'t', () => {
  assert.deepEqual(kinds(flightChanges(leg('Expected'), leg('CheckIn')).changes), ['checkInOpen']);
  assert.deepEqual(kinds(flightChanges(leg('CheckIn'), leg('Boarding')).changes), ['boarding']);
  assert.deepEqual(kinds(flightChanges(leg('Boarding'), leg('GateClosed')).changes), ['gateClosed']);
  assert.deepEqual(kinds(flightChanges(leg('GateClosed'), leg('Departed')).changes), ['departed']);
  assert.deepEqual(kinds(flightChanges(leg('Departed'), leg('EnRoute')).changes), []);
  assert.deepEqual(kinds(flightChanges(leg('EnRoute'), leg('Approaching')).changes), []);
  assert.deepEqual(kinds(flightChanges(leg('Approaching'), leg('Arrived')).changes), ['landed']);
  assert.deepEqual(kinds(flightChanges(leg('Boarding'), leg('CheckIn')).changes), [], 'a stale answer');
  assert.deepEqual(kinds(flightChanges(leg('Expected'), leg('Departed')).changes), ['departed'], 'missed the boarding');
});

test('cancellations, diversions and reinstatements', () => {
  assert.deepEqual(kinds(flightChanges(late(45), leg('Canceled')).changes), ['cancelled'], 'nothing else matters');
  assert.deepEqual(kinds(flightChanges(leg('Expected'), leg('CanceledUncertain')).changes), ['mayBeCancelled']);
  assert.deepEqual(kinds(flightChanges(leg('CanceledUncertain'), leg('Expected')).changes), ['notCancelled']);
  assert.deepEqual(kinds(flightChanges(leg('EnRoute'), leg('Diverted')).changes), ['diverted']);
});

test('gates and belts are news when they appear or change, never when they vanish', () => {
  const gated = leg('Expected', { departure: { gate: '12' } });
  assert.deepEqual(flightChanges(leg(), gated).changes, [{ kind: 'gate', from: null, to: '12' }]);
  assert.deepEqual(flightChanges(gated, leg('Expected', { departure: { gate: '31' } })).changes, [{ kind: 'gate', from: '12', to: '31' }]);
  const vanished = flightChanges(gated, leg());
  assert.deepEqual(vanished.changes, []);
  assert.equal(vanished.baseline.departure.gate, '12', 'kept, so its return isn\'t news');

  assert.deepEqual(flightChanges(leg(), leg('Expected', { departure: { terminal: 'N' } })).changes, [{ kind: 'terminal', from: 'S', to: 'N' }]);
  assert.deepEqual(flightChanges(leg('Arrived'), leg('Arrived', { arrival: { baggageBelt: '7' } })).changes, [{ kind: 'belt', to: '7' }]);
});

test('in the air, only a bigger change to the landing time is news', () => {
  const landing = (minutes: number) => {
    const utc = new Date(arrives + minutes * MIN);
    const local = new Date(utc.getTime() - 4 * HOUR).toISOString().slice(0, 16);
    return leg('EnRoute', { arrival: { revised: local, revisedUtc: utc.toISOString() } });
  };
  assert.deepEqual(flightChanges(leg('EnRoute'), landing(10)).changes, []);
  assert.deepEqual(flightChanges(leg('EnRoute'), landing(-25)).changes, [
    { kind: 'arrivalTime', from: '2026-10-14T14:30', to: '2026-10-14T14:05', later: false },
  ]);
  // Before take-off, a landing time that moves with the take-off time isn't news of its own.
  assert.deepEqual(kinds(flightChanges(leg(), late(45)).changes), ['departureTime']);
});

// The words.

test('pushes say what changed, in the airport\'s own time', () => {
  const text = (changes: FlightChange[], now = leg()) => alertText(changes, now, 'BA2037');
  assert.deepEqual(text(flightChanges(leg(), late(45)).changes, late(45)), {
    title: 'BA 2037 is delayed',
    body: 'Now leaves at 10:15am instead of 9:30am.',
    kind: 'departureTime',
  });
  assert.equal(text(flightChanges(leg(), late(-20, 'Expected')).changes)?.title, 'BA 2037 leaves earlier');
  const moved = leg('Expected', { departure: { scheduled: '2026-10-14T10:40', scheduledUtc: '2026-10-14T09:40:00.000Z' } });
  assert.deepEqual(text(flightChanges(leg(), moved).changes, moved), {
    title: 'BA 2037 has a new time',
    body: 'The airline has moved it: now leaves at 10:40am instead of 9:30am.',
    kind: 'departureTime',
  });
  assert.deepEqual(text([{ kind: 'cancelled' }]), {
    title: 'BA 2037 is cancelled',
    body: 'London to Orlando, Wed 14 Oct. Your airline will say what happens next.',
    kind: 'cancelled',
  });
  const boarding = leg('Boarding', { departure: { gate: '12' } });
  assert.deepEqual(text(flightChanges(leg('CheckIn'), boarding).changes, boarding), {
    title: 'BA 2037 is boarding', body: 'Gate 12.', kind: 'boarding',
  });
  assert.equal(text([{ kind: 'departed' }], leg('EnRoute'))?.body, 'Lands in Orlando at 2:30pm.');
  const landed = leg('Arrived', { arrival: { revised: '2026-10-14T14:21', baggageBelt: '7' } });
  assert.deepEqual(text(flightChanges(leg('Approaching'), landed).changes, landed), {
    title: 'BA 2037 has landed', body: 'Landed in Orlando at 2:21pm. Bags on belt 7.', kind: 'landed',
  });
  assert.deepEqual(text([{ kind: 'gate', from: '12', to: '31' }]), {
    title: 'Gate change for BA 2037', body: 'Now gate 31, not 12.', kind: 'gate',
  });
  assert.equal(text([{ kind: 'gate', from: null, to: '12' }])?.title, 'BA 2037 leaves from gate 12');
  assert.equal(
    text([{ kind: 'departureTime', from: '2026-10-14T23:30', to: '2026-10-15T01:10', later: true, schedule: false }])?.body,
    'Now leaves at 1:10am Thu 15 Oct instead of 11:30pm.',
  );
  // The main news first, the smaller news after it.
  const both: FlightChange[] = [{ kind: 'gate', from: null, to: '12' }, flightChanges(leg(), late(45)).changes[0]];
  assert.equal(text(both, late(45))?.body, 'Now leaves at 10:15am instead of 9:30am. Gate 12.');
  assert.equal(text([]), null);
});

test('flight numbers and times read like the app writes them', () => {
  assert.equal(displayNumber('BA2037'), 'BA 2037');
  assert.equal(displayNumber('EZY8123'), 'EZY 8123');
  assert.equal(displayNumber('U28123'), 'U2 8123');
  assert.equal(clock('2026-10-14T00:05', null), '12:05am');
  assert.equal(clock('2026-10-14T12:00', null), '12:00pm');
  assert.equal(clock('2026-10-15T09:40', '2026-10-14T23:00'), '9:40am Thu 15 Oct');
});

test('a trip\'s live line is rewritten when it changes or gets old', () => {
  const now = at('2026-10-14T07:00:00Z');
  const stored = { ...leg(), checkedAt: now - 10 * MIN };
  assert.equal(liveNeedsWrite(stored, leg(), now), false);
  assert.equal(liveNeedsWrite(stored, late(45), now), true);
  assert.equal(liveNeedsWrite({ ...stored, checkedAt: now - 31 * MIN }, leg(), now), true);
  assert.equal(liveNeedsWrite(undefined, leg(), now), true);
});
