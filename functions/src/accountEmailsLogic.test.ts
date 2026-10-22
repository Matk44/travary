import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  ACCOUNT_EMAIL_FROM,
  actionPageLink,
  CONFIRM_LIMIT,
  confirmEmailMessage,
  normaliseEmail,
  rateCheck,
  RESET_CALLER_LIMIT,
  resetPasswordMessage,
} from './accountEmailsLogic';

const firebaseLink = (mode: string) =>
  `https://travary-444.firebaseapp.com/__/auth/action?mode=${mode}&oobCode=ABC-123_x&apiKey=AIzaKey&lang=en`;

test('Firebase\'s links become travary.app\'s, keeping the code and key', () => {
  const link = new URL(actionPageLink(firebaseLink('verifyEmail'))!);
  assert.equal(link.origin + link.pathname, 'https://travary.app/auth/action');
  assert.equal(link.searchParams.get('mode'), 'verifyEmail');
  assert.equal(link.searchParams.get('oobCode'), 'ABC-123_x');
  assert.equal(link.searchParams.get('apiKey'), 'AIzaKey');
  assert.equal(link.searchParams.get('lang'), 'en');
  assert.equal(new URL(actionPageLink(firebaseLink('resetPassword'))!).searchParams.get('mode'), 'resetPassword');
});

test('a link without a code, with an unknown mode, or not a link at all makes none', () => {
  assert.equal(actionPageLink('https://travary-444.firebaseapp.com/__/auth/action?mode=verifyEmail'), null);
  assert.equal(actionPageLink(firebaseLink('signIn')), null);
  assert.equal(actionPageLink('not a link'), null);
});

test('addresses are trimmed and lowercased; anything else is refused', () => {
  assert.equal(normaliseEmail('  Sam@Example.COM '), 'sam@example.com');
  assert.equal(normaliseEmail('sam@example'), null);
  assert.equal(normaliseEmail('two words@example.com'), null);
  assert.equal(normaliseEmail(42), null);
  assert.equal(normaliseEmail(`${'a'.repeat(250)}@example.com`), null);
});

test('a minute between sends and five a day, counting only the last day', () => {
  const now = 10 * 24 * 60 * 60 * 1000;
  assert.deepEqual(rateCheck([], now, CONFIRM_LIMIT), { allowed: true, sent: [now] });
  assert.equal(rateCheck([now - 30_000], now, CONFIRM_LIMIT).allowed, false, 'too soon');
  assert.equal(rateCheck([now - 61_000], now, CONFIRM_LIMIT).allowed, true);
  const fiveToday = [1, 2, 3, 4, 5].map((h) => now - h * 60 * 60 * 1000);
  assert.equal(rateCheck(fiveToday, now, CONFIRM_LIMIT).allowed, false, 'five already today');
  const yesterday = fiveToday.map((at) => at - 24 * 60 * 60 * 1000);
  assert.deepEqual(rateCheck(yesterday, now, CONFIRM_LIMIT), { allowed: true, sent: [now] }, 'yesterday is forgotten');
  assert.equal(rateCheck(Array.from({ length: 9 }, (_, i) => now - i), now, RESET_CALLER_LIMIT).allowed, true);
  assert.equal(rateCheck(Array.from({ length: 10 }, (_, i) => now - i), now, RESET_CALLER_LIMIT).allowed, false);
});

test('each email has a subject, a plain-text part and an HTML part with the one link', () => {
  const link = actionPageLink(firebaseLink('verifyEmail'))!;
  const confirm = confirmEmailMessage(link);
  assert.equal(confirm.subject, 'Confirm your email for Travary');
  assert.ok(confirm.text.includes(link));
  assert.ok(confirm.html.includes(link.replace(/&/g, '&amp;')));
  assert.ok(!/<img|<script/i.test(confirm.html), 'no images or scripts');

  const reset = resetPasswordMessage(link, 'sam<x>@example.com');
  assert.equal(reset.subject, 'Choose a new Travary password');
  assert.ok(reset.html.includes('sam&lt;x&gt;@example.com'), 'the address is escaped');
  assert.ok(!reset.html.includes('sam<x>'));
});

test('they come from Travary on send.travary.app', () => {
  assert.deepEqual(ACCOUNT_EMAIL_FROM, { address: 'account@send.travary.app', name: 'Travary' });
});
