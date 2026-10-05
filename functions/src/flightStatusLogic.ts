/**
 * Live flight status (gate, terminal, delays) from AeroDataBox, reduced to
 * what a traveller's flight card needs. Pure, so it's unit-tested.
 */

/** AeroDataBox's flight statuses. Anything else reads as Unknown. */
export const FLIGHT_STATUSES = [
  'Unknown', 'Expected', 'EnRoute', 'CheckIn', 'Boarding', 'GateClosed', 'Departed', 'Delayed',
  'Approaching', 'Arrived', 'Canceled', 'Diverted', 'CanceledUncertain',
] as const;
export type FlightStatusName = (typeof FLIGHT_STATUSES)[number];

/** One end of the flight. Times are the airport's local time ("2026-10-04T10:30"), like tickets. */
export interface FlightMovement {
  airport: string | null;
  /** Short name for the status ("Heathrow"). */
  airportName: string | null;
  /** Full name for a booking's location ("London Heathrow"). */
  airportFullName: string | null;
  /** The city it serves, for a booking's title ("London to Los Angeles"). */
  city: string | null;
  scheduled: string | null;
  /** Actual or estimated time, when the airline has given one. */
  revised: string | null;
  /** Minutes late (negative when early), from the revised time. */
  delayMinutes: number | null;
  terminal: string | null;
  gate: string | null;
  checkInDesk: string | null;
  baggageBelt: string | null;
}

export interface FlightStatusResult {
  number: string;
  airline: string | null;
  status: FlightStatusName;
  departure: FlightMovement;
  arrival: FlightMovement;
  /** When AeroDataBox last heard about the flight (ISO, UTC). */
  updatedAt: string | null;
}

/** "ba 283", "BA-283", "ezy8123" → "BA283", "EZY8123"; null if it isn't a flight number. */
export function cleanFlightNumber(input: unknown): string | null {
  if (typeof input !== 'string') return null;
  const clean = input.toUpperCase().replace(/[\s-]/g, '');
  return /^(?:[A-Z]{3}|[A-Z0-9]{2})\d{1,4}[A-Z]?$/.test(clean) ? clean : null;
}

/**
 * The flight's local date, "YYYY-MM-DD", if it can be looked up: from a
 * week ago (a flight just taken) to a year ahead (AeroDataBox's schedules).
 * Live status only exists close to the day; further ahead the answer is
 * the airline's schedule, which is what fills in a new flight.
 */
export function cleanFlightDate(input: unknown, nowMs: number): string | null {
  if (typeof input !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(input)) return null;
  const day = Date.parse(`${input}T00:00:00Z`);
  if (Number.isNaN(day)) return null;
  const today = Date.parse(new Date(nowMs).toISOString().slice(0, 10) + 'T00:00:00Z');
  const days = Math.round((day - today) / 86_400_000);
  return days >= -7 && days <= 365 ? input : null;
}

/** IATA airport code from the app ("LHR"), else null. */
export function cleanAirport(input: unknown): string | null {
  if (typeof input !== 'string') return null;
  const code = input.trim().toUpperCase();
  return /^[A-Z]{3}$/.test(code) ? code : null;
}

type Json = Record<string, unknown>;

const isObject = (value: unknown): value is Json => typeof value === 'object' && value !== null && !Array.isArray(value);
const text = (value: unknown): string | null =>
  typeof value === 'string' && value.trim() !== '' ? value.trim().slice(0, 40) : null;

/** "2026-10-04 10:30+01:00" → "2026-10-04T10:30" (the airport's wall clock). */
export function localTime(value: unknown): string | null {
  const raw = isObject(value) ? value.local : undefined;
  if (typeof raw !== 'string') return null;
  const match = /^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2})/.exec(raw);
  return match ? `${match[1]}T${match[2]}` : null;
}

/** "2026-10-04 09:30Z" → epoch ms. */
function utcMs(value: unknown): number | null {
  const raw = isObject(value) ? value.utc : undefined;
  if (typeof raw !== 'string') return null;
  const ms = Date.parse(raw.replace(' ', 'T'));
  return Number.isNaN(ms) ? null : ms;
}

function movement(value: unknown): FlightMovement {
  const m = isObject(value) ? value : {};
  const airport = isObject(m.airport) ? m.airport : {};
  const scheduledMs = utcMs(m.scheduledTime);
  const revisedMs = utcMs(m.revisedTime);
  return {
    airport: cleanAirport(airport.iata),
    airportName: text(airport.shortName) ?? text(airport.name),
    airportFullName: text(airport.name),
    city: text(airport.municipalityName),
    scheduled: localTime(m.scheduledTime),
    revised: localTime(m.revisedTime),
    delayMinutes: scheduledMs != null && revisedMs != null ? Math.round((revisedMs - scheduledMs) / 60_000) : null,
    terminal: text(m.terminal),
    gate: text(m.gate),
    checkInDesk: text(m.checkInDesk),
    baggageBelt: text(m.baggageBelt),
  };
}

/**
 * Every passenger leg in AeroDataBox's answer (one flight number can fly
 * several legs a day), reduced to what the app shows.
 */
export function normaliseFlightLegs(raw: unknown): FlightStatusResult[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((f): f is Json => isObject(f) && f.isCargo !== true)
    .map((flight) => {
      const updated = typeof flight.lastUpdatedUtc === 'string' ? Date.parse(flight.lastUpdatedUtc.replace(' ', 'T')) : NaN;
      return {
        number: text(flight.number) ?? '',
        airline: isObject(flight.airline) ? text(flight.airline.name) : null,
        status: FLIGHT_STATUSES.find((s) => s === flight.status) ?? 'Unknown',
        departure: movement(flight.departure),
        arrival: movement(flight.arrival),
        updatedAt: Number.isNaN(updated) ? null : new Date(updated).toISOString(),
      };
    });
}

/** The traveller's leg: the one leaving [from] when the app knows it, else the first. */
export function pickLeg(legs: FlightStatusResult[], from: string | null = null): FlightStatusResult | null {
  return (from && legs.find((leg) => leg.departure.airport === from)) || legs[0] || null;
}

const MINUTE = 60_000;

/**
 * How long a looked-up status may be reused before asking again: often
 * near departure, rarely when the flight is days away or over. Keeps the
 * AeroDataBox bill (and its free plan) small however often the card opens.
 */
export function cacheLifetimeMs(result: FlightStatusResult | null, nowMs: number): number {
  if (result == null) return 60 * MINUTE;
  if (['Arrived', 'Canceled', 'Diverted'].includes(result.status)) return 6 * 60 * MINUTE;
  if (['EnRoute', 'Departed', 'Approaching'].includes(result.status)) return 15 * MINUTE;
  // The local departure time read as UTC is off by the airport's offset at
  // most, which is fine for choosing a refresh interval.
  const departs = result.departure.revised ?? result.departure.scheduled;
  const departsMs = departs ? Date.parse(`${departs}:00Z`) : NaN;
  if (Number.isNaN(departsMs)) return 30 * MINUTE;
  const hoursAway = (departsMs - nowMs) / (60 * MINUTE);
  // Days away it's the schedule, which rarely changes.
  if (hoursAway > 72) return 24 * 60 * MINUTE;
  if (hoursAway > 24) return 3 * 60 * MINUTE;
  if (hoursAway > 6) return 60 * MINUTE;
  return 10 * MINUTE;
}
