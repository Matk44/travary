import { initializeApp } from 'firebase-admin/app';

initializeApp();

export { smartImport } from './smartImport';
export { createTripInvite, joinTrip, removeTripMember } from './sharing';
