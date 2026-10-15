import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  cacheLifetimeMs,
  cleanAirport,
  cleanFlightDate,
  cleanFlightNumber,
  FLIGHT_LOOKUP_DAYS_AHEAD,
  localTime,
  normaliseFlightLegs,
  pickLeg,
} from './flightStatusLogic';

/** AeroDataBox's answer for BA 283 on 4 October 2026 (trimmed). */
const ba283 = [
  {
    greatCircleDistance: { km: 8780.65 },
    departure: {
      airport: {
        icao: 'EGLL', iata: 'LHR', name: 'London Heathrow', shortName: 'Heathrow', municipalityName: 'London',
        timeZone: 'Europe/London',
      },
      scheduledTime: { utc: '2026-10-04 09:30Z', local: '2026-10-04 10:30+01:00' },
      revisedTime: { utc: '2026-10-04 10:05Z', local: '2026-10-04 11:05+01:00' },
      terminal: '5',
      checkInDesk: 'D',
      gate: 'B32',
      quality: ['Basic', 'Live'],
    },
    arrival: {
      airport: { icao: 'KLAX', iata: 'LAX', name: 'Los Angeles', shortName: 'Los Angeles', municipalityName: 'Los Angeles' },
      scheduledTime: { utc: '2026-10-04 20:45Z', local: '2026-10-04 13:45-07:00' },
      predictedTime: { utc: '2026-10-04 20:46Z', local: '2026-10-04 13:46-07:00' },
      terminal: 'B',
      quality: ['Basic'],
    },
    lastUpdatedUtc: '2026-10-04 09:19Z',
    number: 'BA 283',
    status: 'GateClosed',
    codeshareStatus: 'IsOperator',
    isCargo: false,
    aircraft: { model: 'Boeing 777-300ER' },
    airline: { name: 'British Airways', iata: 'BA', icao: 'BAW' },
  },
];

test('flight numbers are forgiving to type', () => {
  assert.equal(cleanFlightNumber('ba 283'), 'BA283');
  assert.equal(cleanFlightNumber('BA-2037'), 'BA2037');
  assert.equal(cleanFlightNumber('ezy8123'), 'EZY8123');
  assert.equal(cleanFlightNumber('U2 8123'), 'U28123');
  assert.equal(cleanFlightNumber('Lisbon'), null);
  assert.equal(cleanFlightNumber('BA'), null);
  assert.equal(cleanFlightNumber(283), null);
});

test('flights can be looked up from a week ago to the plan\'s 180 days ahead', () => {
  const now = Date.parse('2026-10-04T12:00:00Z');
  assert.equal(cleanFlightDate('2026-10-04', now), '2026-10-04');
  assert.equal(cleanFlightDate('2026-09-27', now), '2026-09-27');
  assert.equal(FLIGHT_LOOKUP_DAYS_AHEAD, 180, 'AeroDataBox Pro refuses a date later than 180 days ahead');
  assert.equal(cleanFlightDate('2027-04-02', now), '2027-04-02', 'schedules go 180 days ahead');
  assert.equal(cleanFlightDate('2027-04-03', now), null);
  assert.equal(cleanFlightDate('2026-09-26', now), null);
  assert.equal(cleanFlightDate('4 Oct', now), null);
  assert.equal(cleanAirport(' lhr '), 'LHR');
  assert.equal(cleanAirport('Heathrow'), null);
});

test('times stay on the airport\'s clock, like the ticket', () => {
  assert.equal(localTime({ local: '2026-10-04 13:45-07:00' }), '2026-10-04T13:45');
  assert.equal(localTime({ utc: '2026-10-04 20:45Z' }), null);
  assert.equal(localTime(undefined), null);
});

test('a real answer becomes gate, terminal, desk and delay', () => {
  const [leg] = normaliseFlightLegs(ba283);
  assert.equal(leg.number, 'BA 283');
  assert.equal(leg.airline, 'British Airways');
  assert.equal(leg.status, 'GateClosed');
  assert.deepEqual(leg.departure, {
    airport: 'LHR',
    airportName: 'Heathrow',
    airportFullName: 'London Heathrow',
    city: 'London',
    scheduled: '2026-10-04T10:30',
    revised: '2026-10-04T11:05',
    scheduledUtc: '2026-10-04T09:30:00.000Z',
    revisedUtc: '2026-10-04T10:05:00.000Z',
    delayMinutes: 35,
    terminal: '5',
    gate: 'B32',
    checkInDesk: 'D',
    baggageBelt: null,
  });
  // Predicted times are AeroDataBox's guess, not the airline's: not shown.
  assert.equal(leg.arrival.revised, null);
  assert.equal(leg.arrival.delayMinutes, null);
  assert.equal(leg.arrival.terminal, 'B');
  assert.equal(leg.updatedAt, '2026-10-04T09:19:00.000Z');
});

test('the traveller\'s leg is the one leaving their airport', () => {
  const second = { ...ba283[0], departure: { ...ba283[0].departure, airport: { iata: 'LAX', name: 'Los Angeles' } } };
  const legs = normaliseFlightLegs([second, ba283[0], { ...ba283[0], isCargo: true }, 'junk']);
  assert.equal(legs.length, 2, 'cargo and junk are dropped');
  assert.equal(pickLeg(legs, 'LHR')?.departure.airport, 'LHR');
  assert.equal(pickLeg(legs, null)?.departure.airport, 'LAX');
  assert.equal(pickLeg([], 'LHR'), null);
  assert.deepEqual(normaliseFlightLegs({ message: 'no' }), []);
});

test('unknown statuses read as Unknown', () => {
  const [leg] = normaliseFlightLegs([{ ...ba283[0], status: 'Teleported' }]);
  assert.equal(leg.status, 'Unknown');
});

test('answers are reused longer the further away the flight is', () => {
  const [leg] = normaliseFlightLegs(ba283);
  const minutes = (ms: number) => ms / 60_000;
  const at = (iso: string) => Date.parse(iso);
  assert.equal(minutes(cacheLifetimeMs(leg, at('2026-10-04T09:00:00Z'))), 10, 'about to leave');
  assert.equal(minutes(cacheLifetimeMs(leg, at('2026-10-03T22:00:00Z'))), 60, 'tomorrow morning');
  assert.equal(minutes(cacheLifetimeMs(leg, at('2026-10-03T02:00:00Z'))), 180, 'the day before');
  assert.equal(minutes(cacheLifetimeMs(leg, at('2026-09-20T09:00:00Z'))), 24 * 60, 'weeks away: the schedule');
  assert.equal(minutes(cacheLifetimeMs({ ...leg, status: 'EnRoute' }, at('2026-10-04T12:00:00Z'))), 15);
  assert.equal(minutes(cacheLifetimeMs({ ...leg, status: 'Arrived' }, at('2026-10-04T22:00:00Z'))), 360);
  assert.equal(minutes(cacheLifetimeMs(null, at('2026-10-04T12:00:00Z'))), 60, 'not found yet');
});
