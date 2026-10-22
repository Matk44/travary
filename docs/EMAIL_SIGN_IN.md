# Email sign-in (email and password)

22 October 2026. "Continue with email" is an email and password, alongside
Apple and Google, in every build (the passwordless links it replaces never
went live). Firebase Authentication checks the passwords and makes the
one-time codes; Travary sends the account emails itself through
**Cloudflare Email Sending** from `send.travary.app`, and travary.app
(Cloudflare Pages) finishes their links, so the emails reach the inbox.

## How it works

- **Create an account** (onboarding and Profile start here): the guest gets
  the email and password, so the uid and every trip stay as they are
  (`FirebaseAuthService.createWithPassword`), and is emailed a link to
  confirm the address. **Until it's opened the account is still a guest**
  (`Account.unconfirmedEmail`): not marked as onboarded, nothing more
  unlocked than a guest has. The form waits on "Check your inbox", asking
  Firebase every 5 s for 10 minutes, whenever the app comes back to the
  front, and on "I've tapped the link" (`EmailConfirmationWatch`,
  `AppSession.checkEmailConfirmed`); the app also asks once at launch.
  Profile says it's waiting. The link can be opened on any device.
- **Sign in** (the "Welcome back" sheet starts here): switches to that
  account, bringing the guest's trips (`adoptGuestTrips`), as Apple and
  Google do. An account never confirmed is sent a new link and waits the
  same way. Creating an account for an address that already has one signs
  in to it if the password is right.
- **Forgot your password?** A link to travary.app's page, which asks for
  the new one. The app never says whether an address has an account.
- **Use a different email** (a typo while waiting): the next "Create
  account" unlinks the unconfirmed address and links the new one. Choosing
  Apple or Google instead drops the unconfirmed one too.
- Passwords: at least 8 characters (`minPasswordLength`, and Firebase's
  password policy enforces the same), shown on request, and the phone's
  password manager fills, suggests and saves them under travary.app (iOS
  `webcredentials:travary.app` in `Runner.entitlements` and the site's
  `apple-app-site-association`; Android `get_login_creds` in
  `assetlinks.json`).

### Sending: `sendAccountEmail` and Cloudflare

Firebase won't let this project change its own email templates (their
links or words: the console and the Admin API both answer 400
`EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED`, checked 22 Oct 2026), and its own
sender, `noreply@travary-444.firebaseapp.com`, lands in spam. So the app
asks the callable **`sendAccountEmail`** (`functions/src/accountEmails.ts`,
pure parts in `accountEmailsLogic.ts`, tested) instead:

- `{kind: 'confirm'}`: the caller's own unconfirmed address.
  `{kind: 'reset', email}`: a password link, the same answer whether or not
  the address has an account (and nothing sent if it hasn't, or has only
  Apple or Google).
- Firebase's Admin SDK makes the link (`generateEmailVerificationLink`,
  `generatePasswordResetLink`); the function rebuilds it on
  `https://travary.app/auth/action` with the same code (`actionPageLink`).
- It sends through Cloudflare Email Sending's REST API
  (`POST /accounts/{id}/email/sending/send`, the request `wrangler email
  sending send` makes) from **Travary `<account@send.travary.app>`**,
  reply-to `dreamprayer.dev@gmail.com`, with a plain-text and an HTML part,
  one link, no images or tracking.
- **Limits** (server-only `accountEmails/` in Firestore, kept by a
  transaction): one account's confirmation a minute apart and 5 a day; one
  address's password links a minute apart and 5 a day whoever asks; 10
  password links a day from one phone. Addresses are stored only as a hash.
  Too soon says "We've just sent one. Wait a minute".
- **Secret**: `CLOUDFLARE_EMAIL_TOKEN` (a Cloudflare API token with Account
  → Email Sending → Edit). The account ID is `CLOUDFLARE_ACCOUNT_ID`
  (`params.ts`, defaults to Travary's). Logs never hold an address or a
  message.
- If the function can't be reached (not deployed, Cloudflare down), the app
  has Firebase send its own email instead, so nobody is ever stuck
  (`FirebaseAuthService._accountEmail`); a limit is never worked round.

**The sending domain** (enabled 22 Oct 2026 with `wrangler email sending
enable send.travary.app`, as hairaisalon.com uses `send.hairaisalon.com`):
Cloudflare publishes DKIM (`cf-bounce._domainkey.send.travary.app`), the
bounce domain `cf-bounce.send.travary.app` (its MX and SPF) and DMARC
`_dmarc.send.travary.app` = `v=DMARC1; p=reject;`. travary.app's own mail
records (Namecheap forwarding) are untouched. Check them with
`wrangler email sending dns get send.travary.app` (from `website/`, with
`CLOUDFLARE_ACCOUNT_ID` set).

### The links: travary.app/auth/action

A page on Cloudflare Pages (`website/build.py`, script
`website/static/js/auth.js`) finishes the link with Firebase's Identity
Toolkit API: it confirms an address at once, or asks for a new password and
saves it. It:

- only ever uses the project's own Web API key (`FIREBASE_WEB_API_KEY` in
  `build.py`); a link carrying another key is refused, so a forged "reset
  your Travary password" link can't collect a password for someone else's
  project;
- removes the code from the address bar as it loads, and is served
  `no-store`, `no-referrer` and `noindex` (`_headers`);
- needs JavaScript (it says so without).

Live since 22 Oct 2026: a made-up code comes back from Firebase as
"expired or already used", a link with another key is refused, and (in a
local copy with Firebase stubbed) a short password is refused and a new one
saved.

## Why this reaches the inbox

Inboxes trust mail whose From address, signature and links belong to one
domain with a published policy. These come from `send.travary.app`, signed
by it (DKIM), bounced through it (SPF on `cf-bounce.send.travary.app`),
with a strict DMARC policy, and link only to travary.app. They're short,
have a text part, a real reply-to, and the limits keep volume and
complaints low, which is what keeps a new domain's reputation. Firebase's
own (fallback) emails come from firebaseapp.com and may still land in spam.

## Setup

All done 22 Oct 2026: travary.app deployed with `/auth/action`; every
function deployed (`adoptGuestTrips` treats an unconfirmed email as a
guest); travary.app an authorised domain; the password policy (8
characters, enforced; existing passwords not forced to change); Email
Sending enabled on `send.travary.app`; the token stored
(`CLOUDFLARE_EMAIL_TOKEN`, an API token with Account · Email Sending ·
Edit; paste only the token, not "Bearer") and `sendAccountEmail` deployed
(`CLOUDFLARE_ACCOUNT_ID` is in `functions/.env`, which non-interactive
deploys need). **Verified:** both emails, sent through the live code to
Gmail, landed in the inbox with SPF, DKIM and DMARC `PASS`.

Still worth doing:

- **travary.app's own DMARC** (optional): Cloudflare → travary.app → Email
  → DMARC Management → enable (free; adds `_dmarc.travary.app` and
  collects reports). The sending subdomain already has its own.
- An Outlook or iCloud address too, and the whole flow in the app on a
  device (below).

Leave **Email enumeration protection** on (it is) and Firebase's **sign-up
quota** at its default: guests count towards it, and phones on a mobile
network share an IP.

## What stops sign-up floods

- An email counts only once confirmed: an unconfirmed one is a guest, and
  guests can already be made freely. Firebase also lets a Google sign-in
  with the same address take over an unconfirmed password account, so
  nobody can hold someone else's address.
- Firebase limits new accounts per IP an hour, throttles password guessing
  (`too-many-requests`), and with enumeration protection never says whether
  an address has an account.
- `sendAccountEmail`'s limits mean nobody can use Travary to flood an
  inbox, or spend the sending domain's reputation.
- The limit to be honest about: Firebase's sign-up endpoint is public (it
  has to be), so a bot can call it directly; it gets an unconfirmed account
  and nothing else, and can make Firebase (not Cloudflare) send its own
  email. If floods ever show up, upgrade the project to Identity Platform
  (free under 50,000 monthly users) for reCAPTCHA on sign-up and blocking
  functions.
- Not built: removing unconfirmed accounts left behind after a while.

## Checks on a device

- Create an account: the email comes from Travary
  `<account@send.travary.app>`, in the inbox; its button opens travary.app
  ("You're confirmed"); back in the app it's signed in within a few
  seconds.
- "Send it again" twice within a minute: "We've just sent one."
- The same address on a second phone: "Sign in" switches to it and the
  second phone's trips move across.
- Forgot your password: the link opens the page, the new password works in
  the app, the old one doesn't.
- An old link: "This link has expired or was already used."
- iOS (fresh install): "Create account" suggests a strong password and
  saves it to Passwords under travary.app.
- Not yet verified live: that "Use a different email" (unlink, then link the
  new address) frees the mistyped one for someone else.
