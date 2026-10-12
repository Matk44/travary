import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  afterDay, holidayPassRefund, holidayPassTransactions, isFirebaseUid, passSpanFor, pickTransaction,
  plusFromSubscriber, premiumFromRecords, samePremium, tripPremium, tripSpan, webhookUserIds,
} from './purchasesLogic';

const UID = 'Xq3bR9mZt2LkP0aVwY7cN4dE8fG1';

test('a trip\'s dates are its planned dates widened by its bookings, as in the app', () => {
  assert.deepEqual(tripSpan({ plannedStart: '2026-11-02', plannedEnd: '2026-11-10' }, []), {
    start: '2026-11-02', end: '2026-11-10',
  });
  assert.deepEqual(
    tripSpan({ plannedStart: '2026-11-02' }, [
      { startDate: '2026-11-01' },
      { startDate: '2026-11-05', endDate: '2026-11-12' },
      { startDate: 'soon' },
    ]),
    { start: '2026-11-01', end: '2026-11-12' },
  );
  assert.equal(tripSpan({}, []), null);
  assert.equal(tripSpan({ plannedStart: 12 }, [{ startDate: null }]), null);
});

test('a pass is claimed for at most 30 days', () => {
  assert.deepEqual(passSpanFor({ start: '2026-11-02', end: '2026-11-12' }), { start: '2026-11-02', end: '2026-11-12' });
  assert.deepEqual(passSpanFor({ start: '2026-11-01', end: '2027-01-10' }), { start: '2026-11-01', end: '2026-11-30' });
});

test('premium lasts until the last day has ended everywhere', () => {
  assert.equal(new Date(afterDay('2026-11-19')).toISOString(), '2026-11-20T12:00:00.000Z');
});

test('the Annual Pass is the plus entitlement while it lasts, grace period included', () => {
  const now = Date.parse('2026-10-07T00:00:00Z');
  const subscriber = {
    entitlements: { plus: { expires_date: '2027-10-07T09:00:00Z', product_identifier: 'travary_annual_pass' } },
    subscriptions: { travary_annual_pass: { unsubscribe_detected_at: null } },
  };
  assert.deepEqual(plusFromSubscriber(subscriber, now), {
    expiresAt: Date.parse('2027-10-07T09:00:00Z'), willRenew: true,
  });

  // Google keys the subscription by "subscription:base plan".
  const cancelled = {
    entitlements: { plus: { expires_date: '2027-10-07T09:00:00Z', product_identifier: 'travary_annual_pass' } },
    subscriptions: { 'travary_annual_pass:travary-annual-pass': { unsubscribe_detected_at: '2026-12-01T00:00:00Z' } },
  };
  assert.equal(plusFromSubscriber(cancelled, now)?.willRenew, false);

  const lapsed = { entitlements: { plus: { expires_date: '2026-10-01T00:00:00Z' } } };
  assert.equal(plusFromSubscriber(lapsed, now), null);
  const inGrace = {
    entitlements: { plus: { expires_date: '2026-10-01T00:00:00Z', grace_period_expires_date: '2026-10-20T00:00:00Z' } },
  };
  assert.equal(plusFromSubscriber(inGrace, now)?.expiresAt, Date.parse('2026-10-20T00:00:00Z'));
  assert.equal(plusFromSubscriber({}, now), null);
});

test('a pass is claimed from the purchase the app names, else the newest unclaimed one', () => {
  const bought = holidayPassTransactions({
    non_subscriptions: {
      holiday_pass: [
        { id: 'rc1', store_transaction_id: 'GPA.1', purchase_date: '2026-10-01T00:00:00Z', store: 'play_store' },
        { id: 'rc2', store_transaction_id: 'GPA.2', purchase_date: '2026-10-05T00:00:00Z', store: 'play_store' },
        { id: 'bad/id', purchase_date: '2026-10-06T00:00:00Z' },
      ],
      other: [{ id: 'x' }],
    },
  });
  assert.deepEqual(bought.map((t) => t.id), ['rc2', 'rc1']);
  assert.equal(pickTransaction(bought, 'GPA.1', new Set())?.id, 'rc1');
  assert.equal(pickTransaction(bought, 'rc1', new Set())?.id, 'rc1');
  assert.equal(pickTransaction(bought, 'GPA.1', new Set(['rc1']))?.id, 'rc2');
  assert.equal(pickTransaction(bought, 'unknown', new Set())?.id, 'rc2');
  assert.equal(pickTransaction(bought, 'GPA.1', new Set(['rc1', 'rc2'])), null);
});

test('a trip\'s premium is the longest of its organiser\'s Plus and its passes', () => {
  const span = { start: '2026-11-02', end: '2026-11-12' };
  const pass = { uid: 'sam', start: '2026-11-02', end: '2026-11-12' };
  assert.deepEqual(tripPremium(span, null, [pass]), { grantedBy: 'sam', until: afterDay('2026-11-19') });

  // The flight home added later: the pass grows with its holiday.
  assert.deepEqual(tripPremium({ start: '2026-11-02', end: '2026-11-14' }, null, [pass]), {
    grantedBy: 'sam', until: afterDay('2026-11-21'),
  });

  const plus = { uid: 'mum', expiresAt: Date.parse('2027-06-01T00:00:00Z') };
  assert.deepEqual(tripPremium(span, plus, [pass]), { grantedBy: 'mum', until: plus.expiresAt });
  assert.equal(tripPremium(span, null, []), null);
});

test('a stamp is only rewritten when it changes', () => {
  assert.ok(samePremium({ grantedBy: 'sam', until: 5 }, { grantedBy: 'sam', until: 5 }));
  assert.ok(!samePremium({ grantedBy: 'sam', until: 5 }, { grantedBy: 'sam', until: 6 }));
  assert.ok(samePremium(undefined, null));
  assert.ok(!samePremium({ grantedBy: 'sam', until: 5 }, null));
});

test('webhooks name Firebase accounts, never RevenueCat\'s anonymous ids', () => {
  assert.ok(isFirebaseUid(UID));
  assert.ok(!isFirebaseUid('$RCAnonymousID:abc123'));
  assert.deepEqual(
    webhookUserIds({
      app_user_id: UID,
      original_app_user_id: '$RCAnonymousID:1f2e',
      aliases: [UID, 'Yq3bR9mZt2LkP0aVwY7cN4dE8fG2'],
      transferred_to: ['../etc'],
    }),
    [UID, 'Yq3bR9mZt2LkP0aVwY7cN4dE8fG2'],
  );
});

test('premium without asking the store: the Annual Pass mirror, the trip\'s stamp for its members, a tester', () => {
  const now = Date.parse('2026-10-11T12:00:00Z');
  const later = now + 1000;
  assert.equal(premiumFromRecords('sam', {}, now), false);
  assert.equal(premiumFromRecords('sam', { user: { plus: { expiresAt: later } } }, now), true);
  assert.equal(premiumFromRecords('sam', { user: { plus: { expiresAt: now } } }, now), false, 'lapsed');
  assert.equal(premiumFromRecords('sam', { user: { tester: true } }, now), true);
  assert.equal(premiumFromRecords('sam', { user: { tester: 'yes' } }, now), false);
  const trip = { memberIds: ['sam', 'mum'], premium: { until: later } };
  assert.equal(premiumFromRecords('mum', { trip }, now), true);
  assert.equal(premiumFromRecords('stranger', { trip }, now), false, 'only for people on it');
  assert.equal(premiumFromRecords('mum', { trip: { ...trip, premium: { until: now } } }, now), false);
});

test('a refunded Holiday Pass is a CANCELLATION of its product; a reversal brings it back', () => {
  assert.deepEqual(
    holidayPassRefund({ type: 'CANCELLATION', product_id: 'holiday_pass', transaction_id: 'GPA.1' }),
    { transactionId: 'GPA.1', reversed: false },
  );
  assert.deepEqual(
    holidayPassRefund({ type: 'REFUND_REVERSED', product_id: 'holiday_pass', original_transaction_id: '2000' }),
    { transactionId: '2000', reversed: true },
  );
  assert.equal(holidayPassRefund({ type: 'CANCELLATION', product_id: 'travary_annual_pass', transaction_id: 'x' }), null);
  assert.equal(holidayPassRefund({ type: 'NON_RENEWING_PURCHASE', product_id: 'holiday_pass', transaction_id: 'x' }), null);
  assert.equal(holidayPassRefund({ type: 'CANCELLATION', product_id: 'holiday_pass' }), null);
  assert.equal(holidayPassRefund({ type: 'CANCELLATION', product_id: 'holiday_pass', transaction_id: 'a/b' }), null);
});
