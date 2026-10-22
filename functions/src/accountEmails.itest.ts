/**
 * Account emails against the Firestore emulator (the limits are kept
 * there). Run with `npm --prefix functions run test:emulator`.
 */
import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';

import { deleteApp, initializeApp } from 'firebase-admin/app';
import { Firestore, getFirestore } from 'firebase-admin/firestore';

import { AccountEmailAuth, AccountUser, sendAccountEmailFor } from './accountEmails';
import { AccountEmail } from './accountEmailsLogic';

const PROJECT = 'demo-travary';
let app: ReturnType<typeof initializeApp>;
let db: Firestore;

const link = (mode: string) => `https://travary-444.firebaseapp.com/__/auth/action?mode=${mode}&oobCode=code&apiKey=key`;

/** Accounts by uid; "sam" has an unconfirmed email and password, "kim" only Google. */
class FakeAuth implements AccountEmailAuth {
  users: Record<string, AccountUser> = {
    sam: { email: 'sam@example.com', emailVerified: false, providerData: [{ providerId: 'password' }] },
    kim: { email: 'kim@example.com', emailVerified: true, providerData: [{ providerId: 'google.com' }] },
    guest: { emailVerified: false, providerData: [] },
  };
  async getUser(uid: string) {
    return this.users[uid];
  }
  async findUserByEmail(email: string) {
    return Object.values(this.users).find((u) => u.email === email) ?? null;
  }
  async generateEmailVerificationLink() {
    return link('verifyEmail');
  }
  async generatePasswordResetLink() {
    return link('resetPassword');
  }
}

let sent: { to: string; message: AccountEmail }[];
const send = async (to: string, message: AccountEmail) => {
  sent.push({ to, message });
};

before(() => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Run through `npm run test:emulator`.');
  app = initializeApp({ projectId: PROJECT }, 'account-emails-itest');
  db = getFirestore(app);
});

after(() => deleteApp(app));

beforeEach(async () => {
  sent = [];
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, {
    method: 'DELETE',
  });
});

const T = 1_000_000_000_000;

test('an unconfirmed address gets its link on travary.app, then has to wait a minute', async () => {
  const auth = new FakeAuth();
  assert.deepEqual(await sendAccountEmailFor(db, auth, send, 'sam', { kind: 'confirm' }, T), { sent: true });
  assert.equal(sent.length, 1);
  assert.equal(sent[0].to, 'sam@example.com');
  assert.ok(sent[0].message.text.includes('https://travary.app/auth/action?mode=verifyEmail&oobCode=code'));
  await assert.rejects(sendAccountEmailFor(db, auth, send, 'sam', { kind: 'confirm' }, T + 10_000), /resource-exhausted|Wait a minute/);
  assert.deepEqual(await sendAccountEmailFor(db, auth, send, 'sam', { kind: 'confirm' }, T + 61_000), { sent: true });
  assert.equal(sent.length, 2);
});

test('nothing to confirm for a guest, a confirmed address or Google alone', async () => {
  const auth = new FakeAuth();
  assert.deepEqual(await sendAccountEmailFor(db, auth, send, 'guest', { kind: 'confirm' }, T), { sent: false });
  assert.deepEqual(await sendAccountEmailFor(db, auth, send, 'kim', { kind: 'confirm' }, T), { sent: false });
  auth.users.sam.emailVerified = true;
  assert.deepEqual(await sendAccountEmailFor(db, auth, send, 'sam', { kind: 'confirm' }, T), { sent: false });
  assert.equal(sent.length, 0);
});

test('a password link goes only to an email account, and the answer never says which', async () => {
  const auth = new FakeAuth();
  assert.deepEqual(await sendAccountEmailFor(db, auth, send, 'guest', { kind: 'reset', email: ' Sam@Example.com ' }, T), {
    sent: true,
  });
  assert.equal(sent.length, 1);
  assert.equal(sent[0].to, 'sam@example.com');
  assert.ok(sent[0].message.text.includes('mode=resetPassword'));
  // No account, or Google only: the same answer, and no email.
  assert.deepEqual(await sendAccountEmailFor(db, auth, send, 'guest', { kind: 'reset', email: 'nobody@example.com' }, T + 1), {
    sent: true,
  });
  assert.deepEqual(await sendAccountEmailFor(db, auth, send, 'guest', { kind: 'reset', email: 'kim@example.com' }, T + 2), {
    sent: true,
  });
  assert.equal(sent.length, 1);
});

test('one address can\'t be flooded, and one phone can\'t flood many', async () => {
  const auth = new FakeAuth();
  await sendAccountEmailFor(db, auth, send, 'guest', { kind: 'reset', email: 'sam@example.com' }, T);
  await assert.rejects(
    sendAccountEmailFor(db, auth, send, 'other-phone', { kind: 'reset', email: 'sam@example.com' }, T + 5_000),
    /Wait a minute/,
    'the address is limited whoever asks',
  );
  for (let i = 0; i < 9; i++) {
    await sendAccountEmailFor(db, auth, send, 'guest', { kind: 'reset', email: `person${i}@example.com` }, T + 100 + i);
  }
  await assert.rejects(
    sendAccountEmailFor(db, auth, send, 'guest', { kind: 'reset', email: 'one-more@example.com' }, T + 200),
    /Wait a minute/,
    'ten a day from one phone',
  );
  const stored = await db.collection('accountEmails').get();
  assert.ok(stored.docs.every((doc) => !doc.id.includes('@')), 'addresses are never stored as they are');
});

test('a malformed request or address is refused', async () => {
  const auth = new FakeAuth();
  await assert.rejects(sendAccountEmailFor(db, auth, send, 'sam', { kind: 'spam' }, T), /Unknown email/);
  await assert.rejects(sendAccountEmailFor(db, auth, send, 'sam', { kind: 'reset', email: 'nope' }, T), /doesn't look right/);
  assert.equal(sent.length, 0);
});
