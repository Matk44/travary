import { initializeApp } from 'firebase-admin/app';

initializeApp();

export { smartImport } from './smartImport';
export { classifyTripVisuals, purgeExpiredPlaceCoordinates } from './classifyTripVisuals';
export { createTripInvite, joinTrip, removeTripMember } from './sharing';
export { adoptGuestTripsCall as adoptGuestTrips, deleteAccountCall as deleteAccount } from './account';
export { flightStatus } from './flightStatus';
export {
  checkWatchedFlights, registerPushToken, watchFlightsOnBookingChange, watchFlightsOnTripChange, watchFlightsOnUserChange,
} from './flightAlerts';
export {
  claimTripPass, syncPurchases, revenueCatWebhook, restampTripOnTripChange, restampTripOnBookingChange,
} from './purchases';
