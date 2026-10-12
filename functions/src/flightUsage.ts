import { FieldValue, Firestore } from 'firebase-admin/firestore';

import { BillingPeriod } from './flightAlertsLogic';

/**
 * Units used of the flight provider's monthly allowance, counted per
 * billing period in `flightUsage/{period}` (server-only). Every lookup
 * counts, from the flight page and from alerts alike: they share the plan.
 */
export async function recordFlightUnits(db: Firestore, period: BillingPeriod, units: number, source: 'page' | 'alerts'): Promise<void> {
  await db.collection('flightUsage').doc(period.id).set({
    units: FieldValue.increment(units),
    [source]: FieldValue.increment(units),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

export async function flightUnitsUsed(db: Firestore, period: BillingPeriod): Promise<number> {
  const units = (await db.collection('flightUsage').doc(period.id).get()).get('units');
  return typeof units === 'number' ? units : 0;
}
