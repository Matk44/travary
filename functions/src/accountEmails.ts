import { createHash } from 'node:crypto';

import { getAuth } from 'firebase-admin/auth';
import { Firestore, getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/https';

import {
  ACCOUNT_EMAIL_FROM,
  ACCOUNT_EMAIL_REPLY_TO,
  AccountEmail,
  actionPageLink,
  CONFIRM_LIMIT,
  confirmEmailMessage,
  normaliseEmail,
  RateLimit,
  rateCheck,
  RESET_CALLER_LIMIT,
  RESET_LIMIT,
  resetPasswordMessage,
} from './accountEmailsLogic';
import { cloudflareAccountId, cloudflareEmailToken } from './params';

/**
 * sendAccountEmail: the emails Firebase would send for an email and
 * password account, sent by Travary instead so they come from travary.app
 * and link to travary.app (Firebase won't let this project change its own
 * templates' links, and its own sender lands in spam). Firebase still
 * makes and checks the one-time codes (the Admin SDK's generate…Link);
 * Cloudflare Email Sending delivers from send.travary.app.
 *
 * - `{kind: 'confirm'}`: the caller's own unconfirmed address.
 * - `{kind: 'reset', email}`: a link to choose a new password. The answer
 *   is the same whether or not the address has an account.
 *
 * Limits (per account, per address and per phone, in `accountEmails/`,
 * server-only) keep anyone from using it to send floods.
 */

/** What the handler needs from Firebase Auth (faked in tests). */
export interface AccountEmailAuth {
  getUser(uid: string): Promise<AccountUser>;
  /** Null when no account has the address. */
  findUserByEmail(email: string): Promise<AccountUser | null>;
  generateEmailVerificationLink(email: string): Promise<string>;
  generatePasswordResetLink(email: string): Promise<string>;
}

export interface AccountUser {
  email?: string;
  emailVerified: boolean;
  providerData: { providerId: string }[];
}

/** Sends one email (faked in tests). Throws if it wasn't accepted. */
export type SendEmail = (to: string, message: AccountEmail) => Promise<void>;

const hasPassword = (user: AccountUser) => user.providerData.some((p) => p.providerId === 'password');

/** A key for an address that doesn't keep the address. */
const addressKey = (email: string) => createHash('sha256').update(email).digest('hex').slice(0, 40);

const tooSoon = () => new HttpsError('resource-exhausted', "We've just sent one. Wait a minute, then try again.");

/**
 * Records a send against every key in [limits] if each still has room;
 * false (nothing recorded) if any is full.
 */
async function takeSends(db: Firestore, limits: [string, RateLimit][], now: number): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const refs = limits.map(([key]) => db.collection('accountEmails').doc(key));
    const docs = await Promise.all(refs.map((ref) => tx.get(ref)));
    const checks = docs.map((doc, i) => rateCheck((doc.get('sent') as number[] | undefined) ?? [], now, limits[i][1]));
    if (checks.some((check) => !check.allowed)) return false;
    refs.forEach((ref, i) => tx.set(ref, { sent: checks[i].sent }));
    return true;
  });
}

export async function sendAccountEmailFor(
  db: Firestore,
  auth: AccountEmailAuth,
  send: SendEmail,
  uid: string,
  data: Record<string, unknown>,
  now: number = Date.now(),
): Promise<{ sent: boolean }> {
  if (data.kind === 'confirm') {
    const user = await auth.getUser(uid);
    if (!user.email || user.emailVerified || !hasPassword(user)) return { sent: false };
    if (!(await takeSends(db, [[`confirm_${uid}`, CONFIRM_LIMIT]], now))) throw tooSoon();
    const link = actionPageLink(await auth.generateEmailVerificationLink(user.email));
    if (!link) throw new HttpsError('internal', "The link couldn't be made. Try again.");
    await send(user.email, confirmEmailMessage(link));
    logger.info('account_email_sent', { kind: 'confirm' });
    return { sent: true };
  }
  if (data.kind === 'reset') {
    const email = normaliseEmail(data.email);
    if (!email) throw new HttpsError('invalid-argument', "That email address doesn't look right.");
    // Counted before looking the address up, so the answer never says
    // whether it has an account.
    const limits: [string, RateLimit][] = [
      [`reset_${addressKey(email)}`, RESET_LIMIT],
      [`caller_${uid}`, RESET_CALLER_LIMIT],
    ];
    if (!(await takeSends(db, limits, now))) throw tooSoon();
    const user = await auth.findUserByEmail(email);
    if (!user || !hasPassword(user)) {
      logger.info('account_email_skipped', { kind: 'reset' });
      return { sent: true };
    }
    const link = actionPageLink(await auth.generatePasswordResetLink(email));
    if (!link) throw new HttpsError('internal', "The link couldn't be made. Try again.");
    await send(email, resetPasswordMessage(link, email));
    logger.info('account_email_sent', { kind: 'reset' });
    return { sent: true };
  }
  throw new HttpsError('invalid-argument', 'Unknown email.');
}

/** Cloudflare Email Sending's REST API (the same request `wrangler email sending send` makes). */
export function cloudflareSender(accountId: string, token: string): SendEmail {
  return async (to, message) => {
    const response = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/email/sending/send`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: ACCOUNT_EMAIL_FROM,
        to,
        reply_to: ACCOUNT_EMAIL_REPLY_TO,
        subject: message.subject,
        text: message.text,
        html: message.html,
      }),
    });
    const result = (await response.json().catch(() => ({}))) as {
      success?: boolean;
      errors?: { code?: number; message?: string }[];
      result?: { permanent_bounces?: string[]; suppressed_recipients?: string[] };
    };
    if (!response.ok || result.success === false) {
      // Never log the address or the message.
      logger.error('account_email_failed', { status: response.status, codes: result.errors?.map((e) => e.code) });
      throw new HttpsError('unavailable', "The email couldn't be sent. Try again in a moment.");
    }
    const bounced = (result.result?.permanent_bounces?.length ?? 0) + (result.result?.suppressed_recipients?.length ?? 0);
    if (bounced > 0) logger.warn('account_email_bounced', { bounced });
  };
}

const adminAuth = (): AccountEmailAuth => ({
  getUser: (uid) => getAuth().getUser(uid),
  findUserByEmail: async (email) => {
    try {
      return await getAuth().getUserByEmail(email);
    } catch (e) {
      if ((e as { code?: string }).code === 'auth/user-not-found') return null;
      throw e;
    }
  },
  generateEmailVerificationLink: (email) => getAuth().generateEmailVerificationLink(email),
  generatePasswordResetLink: (email) => getAuth().generatePasswordResetLink(email),
});

export const sendAccountEmail = onCall(
  { secrets: [cloudflareEmailToken], timeoutSeconds: 30, maxInstances: 10 },
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in first.');
    const data = request.data && typeof request.data === 'object' ? (request.data as Record<string, unknown>) : {};
    const send = cloudflareSender(cloudflareAccountId.value(), cloudflareEmailToken.value());
    return sendAccountEmailFor(getFirestore(), adminAuth(), send, request.auth.uid, data);
  },
);
