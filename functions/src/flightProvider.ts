import { logger } from 'firebase-functions';

import { FlightStatusResult, normaliseFlightLegs } from './flightStatusLogic';

/**
 * Where flight data comes from. Everything that looks a flight up (the
 * flight page's status, the departures board, flight alerts) goes through
 * this, so the provider can change, or a second one can fill in what the
 * first lacks (gates and belts), without touching the rules.
 */
export interface FlightProvider {
  /** Units of the plan's monthly allowance one lookup costs. */
  readonly unitsPerLookup: number;

  /**
   * Every passenger leg flown as [number] ("BA283") leaving on [date], the
   * local departure date ("2026-10-04"). Empty when the airline has none.
   * Throws [FlightProviderError] when the provider can't answer.
   */
  flightLegs(number: string, date: string): Promise<FlightStatusResult[]>;
}

/** Why a provider couldn't answer. */
export class FlightProviderError extends Error {
  constructor(
    readonly reason: 'not-a-flight' | 'busy' | 'unavailable',
    readonly http: number,
  ) {
    super(`flight provider: ${reason} (${http})`);
  }
}

/** AeroDataBox through API.Market (where the key was issued). */
const AERODATABOX = 'https://prod.api.market/api/v1/aedbx/aerodatabox';

/**
 * AeroDataBox's flight status by number (Tier 2: 2 units a call on the Pro
 * plan, 5,000 a month, 1 request a second). Live status (revised times,
 * statuses, terminals) close to the day, the airline's schedule up to 180
 * days ahead (`FLIGHT_LOOKUP_DAYS_AHEAD`: the Pro plan refuses later
 * dates). Gates, check-in desks and belts only where the airport shares
 * them.
 */
export function aeroDataBox(key: string): FlightProvider {
  return {
    unitsPerLookup: 2,
    async flightLegs(number, date) {
      // The date is the day it leaves (the ticket's date), not one it might land on.
      const url = `${AERODATABOX}/flights/number/${number}/${date}`
        + '?withAircraftImage=false&withLocation=false&dateLocalRole=Departure';
      for (let attempt = 1; ; attempt++) {
        const started = Date.now();
        const response = await fetch(url, { headers: { 'x-api-market-key': key, Accept: 'application/json' } });
        // Status and timing only: which flight someone takes stays out of the logs.
        logger.info('flight_status', { http: response.status, ms: Date.now() - started, attempt });
        if (response.status === 204 || response.status === 404) return [];
        if (response.ok) return normaliseFlightLegs(await response.json());
        // One request a second: a lookup from the flight page and a check
        // from alerts can meet.
        if (response.status === 429 && attempt < 3) {
          await new Promise((resolve) => setTimeout(resolve, 1100 * attempt));
          continue;
        }
        if (response.status === 400) throw new FlightProviderError('not-a-flight', 400);
        logger.error('flight_status_failed', { http: response.status, detail: (await response.text()).slice(0, 300) });
        throw new FlightProviderError(response.status === 429 ? 'busy' : 'unavailable', response.status);
      }
    },
  };
}
