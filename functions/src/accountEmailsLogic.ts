/**
 * The account emails Travary sends itself (confirm your email, choose a new
 * password), through Cloudflare Email Sending from send.travary.app, so
 * they reach the inbox. Pure, so it's unit-tested. Firebase still makes the
 * one-time codes; these build travary.app's links from them, the messages
 * and the limits that keep the sending domain's reputation clean.
 */

/** Who the emails come from: a subdomain of travary.app with Cloudflare's DKIM, SPF and DMARC. */
export const ACCOUNT_EMAIL_FROM = { address: 'account@send.travary.app', name: 'Travary' } as const;

/** Where replies go: support, so a reply is never lost. */
export const ACCOUNT_EMAIL_REPLY_TO = 'dreamprayer.dev@gmail.com';

/** travary.app's page that finishes the links (website/static/js/auth.js). */
export const ACTION_PAGE = 'https://travary.app/auth/action';

/** Firebase's link modes the page knows. */
const MODES = new Set(['verifyEmail', 'resetPassword', 'verifyAndChangeEmail', 'recoverEmail']);

/**
 * [firebaseLink] (what the Admin SDK's generate…Link returns, on
 * travary-444.firebaseapp.com) as the same link on travary.app's page;
 * null if it has no code or a mode the page doesn't know.
 */
export function actionPageLink(firebaseLink: string, page: string = ACTION_PAGE): string | null {
  let url: URL;
  try {
    url = new URL(firebaseLink);
  } catch {
    return null;
  }
  const mode = url.searchParams.get('mode');
  const code = url.searchParams.get('oobCode');
  if (!mode || !MODES.has(mode) || !code) return null;
  const link = new URL(page);
  link.searchParams.set('mode', mode);
  link.searchParams.set('oobCode', code);
  const apiKey = url.searchParams.get('apiKey');
  if (apiKey) link.searchParams.set('apiKey', apiKey);
  link.searchParams.set('lang', url.searchParams.get('lang') || 'en');
  return link.toString();
}

const ADDRESS = /^[^\s@<>()[\]\\,;:"]{1,64}@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$/;

/** An address as typed, trimmed and lowercased; null if it can't be one. */
export function normaliseEmail(input: unknown): string | null {
  if (typeof input !== 'string') return null;
  const email = input.trim().toLowerCase();
  return email.length <= 254 && ADDRESS.test(email) ? email : null;
}

/** How often one thing may be emailed: a gap between sends, and a day's most. */
export interface RateLimit {
  minGapMs: number;
  perDay: number;
}

/** One account's confirmation link: a minute apart, five a day. */
export const CONFIRM_LIMIT: RateLimit = { minGapMs: 60_000, perDay: 5 };

/** One address's password links, whoever asks: a minute apart, five a day. */
export const RESET_LIMIT: RateLimit = { minGapMs: 60_000, perDay: 5 };

/** Password links one phone may ask for, to any addresses, in a day. */
export const RESET_CALLER_LIMIT: RateLimit = { minGapMs: 0, perDay: 10 };

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Whether another send fits [limit] after the sends at [sent] (epoch ms),
 * and the history to keep: the last day's, with this one if it fits.
 */
export function rateCheck(sent: readonly number[], now: number, limit: RateLimit): { allowed: boolean; sent: number[] } {
  const recent = sent.filter((at) => Number.isFinite(at) && at > now - DAY_MS && at <= now).sort((a, b) => a - b);
  const last = recent[recent.length - 1];
  const allowed = recent.length < limit.perDay && (last === undefined || now - last >= limit.minGapMs);
  return { allowed, sent: allowed ? [...recent, now] : recent };
}

/** An email ready to send: both an HTML and a plain-text part, as inboxes prefer. */
export interface AccountEmail {
  subject: string;
  text: string;
  html: string;
}

function escapeHtml(text: string): string {
  return text.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
}

/** One short message with one button; no images, no tracking. */
function page(heading: string, lines: string[], button: string, link: string, after: string): string {
  const url = escapeHtml(link);
  const paragraphs = lines.map((line) => `<p style="margin:0 0 16px">${line}</p>`).join('');
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escapeHtml(heading)}</title></head>
<body style="margin:0;padding:0;background:#f3ecdf">
<div style="max-width:480px;margin:0 auto;padding:32px 20px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;font-size:16px;line-height:1.5;color:#102b46">
<p style="margin:0 0 24px;font-size:20px;font-weight:700;letter-spacing:-.01em">Travary</p>
<div style="background:#fffaf2;border-radius:16px;padding:28px 24px">
<h1 style="margin:0 0 16px;font-size:22px;line-height:1.25">${escapeHtml(heading)}</h1>
${paragraphs}
<p style="margin:24px 0"><a href="${url}" style="display:inline-block;background:#d9573f;color:#ffffff;text-decoration:none;font-weight:600;padding:12px 22px;border-radius:999px">${escapeHtml(button)}</a></p>
<p style="margin:0 0 16px;font-size:14px;color:#4a5d70">Or copy this link into your browser:<br><a href="${url}" style="color:#4a5d70;word-break:break-all">${url}</a></p>
<p style="margin:0;font-size:14px;color:#4a5d70">${after}</p>
</div>
<p style="margin:20px 0 0;font-size:12px;color:#6b7b8a">Travary, the holiday organiser. You're getting this because someone used this address in the Travary app.</p>
</div></body></html>`;
}

/** "Confirm your email": the link a new email account needs before it counts. */
export function confirmEmailMessage(link: string): AccountEmail {
  return {
    subject: 'Confirm your email for Travary',
    text: [
      'Hello,',
      '',
      'Tap the link to confirm this is your email, then go back to Travary: it signs you in by itself.',
      '',
      link,
      '',
      "If you didn't make a Travary account, you can ignore this email. Nothing happens without the link.",
      '',
      'Travary',
    ].join('\n'),
    html: page(
      'Confirm your email',
      ['Tap the button to confirm this is your email, then go back to Travary: it signs you in by itself.'],
      'Confirm my email',
      link,
      "If you didn't make a Travary account, you can ignore this email. Nothing happens without the link.",
    ),
  };
}

/** "Choose a new password": the link for a forgotten password. */
export function resetPasswordMessage(link: string, email: string): AccountEmail {
  return {
    subject: 'Choose a new Travary password',
    text: [
      'Hello,',
      '',
      `Tap the link to choose a new password for ${email}, then sign in to Travary with it.`,
      '',
      link,
      '',
      "If you didn't ask, ignore this email: your password stays as it is.",
      '',
      'Travary',
    ].join('\n'),
    html: page(
      'Choose a new password',
      [`Tap the button to choose a new password for <strong>${escapeHtml(email)}</strong>, then sign in to Travary with it.`],
      'Choose a new password',
      link,
      "If you didn't ask, ignore this email: your password stays as it is.",
    ),
  };
}
