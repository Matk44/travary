import assert from 'node:assert/strict';
import { test } from 'node:test';

import { normaliseBookings } from './bookingSchema';

test('keeps a well-formed booking', () => {
  const { bookings } = normaliseBookings({
    bookings: [{
      kind: 'flight', title: 'London to Orlando', startDate: '2026-10-12', startTime: '10:30',
      endTime: '14:55', reference: 'X7K2PQ',
      details: { flightNumber: 'BA 2037', seats: '22A, 22B' }, uncertain: [],
    }],
  });
  assert.equal(bookings.length, 1);
  assert.deepEqual(bookings[0], {
    kind: 'flight', title: 'London to Orlando', startDate: '2026-10-12', startTime: '10:30',
    endTime: '14:55', reference: 'X7K2PQ',
    details: { flightNumber: 'BA 2037', seats: '22A, 22B' }, uncertain: [],
  });
});

test('drops bookings without a real start date', () => {
  const { bookings } = normaliseBookings({
    bookings: [
      { kind: 'dining', title: 'A', startDate: '2026-02-30' },
      { kind: 'dining', title: 'B', startDate: 'next Tuesday' },
      { kind: 'dining', title: 'C' },
    ],
  });
  assert.equal(bookings.length, 0);
});

test('flags what it had to fix', () => {
  const { bookings } = normaliseBookings({
    bookings: [{
      kind: 'spaceship', title: '  Lagoon   Grill ', startDate: '2026-10-14', startTime: '7:15pm',
      endDate: '2026-10-01', details: { partySize: 'Table for 4', unknown: 'x' },
    }],
  });
  const b = bookings[0];
  assert.equal(b.kind, 'note');
  assert.equal(b.title, 'Lagoon Grill');
  assert.equal(b.startTime, undefined);
  assert.equal(b.endDate, undefined);
  assert.deepEqual(b.details, { partySize: '4' });
  assert.deepEqual(new Set(b.uncertain), new Set(['kind', 'startTime', 'endDate']));
});

test('a same-day end date is dropped', () => {
  const { bookings } = normaliseBookings({
    bookings: [{ kind: 'activity', title: 'Tour', startDate: '2026-10-14', endDate: '2026-10-14', endTime: '16:00' }],
  });
  assert.equal(bookings[0].endDate, undefined);
  assert.equal(bookings[0].endTime, '16:00');
});

test('only known uncertain fields pass through', () => {
  const { bookings } = normaliseBookings({
    bookings: [{ kind: 'stay', title: 'Hotel', startDate: '2026-10-14', uncertain: ['startTime', 'details.room', 'hack'] }],
  });
  assert.deepEqual(bookings[0].uncertain, ['startTime', 'details.room']);
});

test('survives garbage', () => {
  assert.deepEqual(normaliseBookings(null), { bookings: [] });
  assert.deepEqual(normaliseBookings({ bookings: 'nope', warning: '  blurry  ' }), { bookings: [], warning: 'blurry' });
});

test('keeps a valid picture subject and drops others', () => {
  const { bookings } = normaliseBookings({
    bookings: [
      { kind: 'dining', title: 'Ohana', startDate: '2026-10-14', artSubject: 'grill' },
      { kind: 'dining', title: 'X', startDate: '2026-10-14', artSubject: 'rollercoaster' },
      { kind: 'dining', title: 'Y', startDate: '2026-10-14', artSubject: 'generic' },
    ],
  });
  assert.equal(bookings[0].artSubject, 'grill');
  assert.equal(bookings[1].artSubject, undefined);
  assert.equal(bookings[2].artSubject, undefined);
});
