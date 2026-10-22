/** Pure helpers for family sharing (tested without Firebase). */

/** Most people on one trip: the organiser plus five. */
export const MAX_MEMBERS = 6;

/** How long an invite code works. */
export const INVITE_DAYS = 14;

/** No 0/O, 1/I/L: codes are read aloud and typed. */
const ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

export function newInviteCode(random: () => number = Math.random): string {
  let code = '';
  for (let i = 0; i < 6; i++) code += ALPHABET[Math.floor(random() * ALPHABET.length)];
  return code;
}

/** "abc 123" or "abc-123" → "ABC123"; null if it can't be a code. */
export function normaliseCode(input: unknown): string | null {
  if (typeof input !== 'string') return null;
  const code = input.toUpperCase().replace(/[^A-Z0-9]/g, '');
  return /^[A-Z0-9]{6}$/.test(code) ? code : null;
}

/** A display name: trimmed, one line, at most 30 characters. */
export function cleanName(input: unknown): string | null {
  if (typeof input !== 'string') return null;
  const name = input.replace(/\s+/g, ' ').trim().slice(0, 30);
  return name.length > 0 ? name : null;
}

export function withMember(memberIds: readonly string[], uid: string): string[] {
  return memberIds.includes(uid) ? [...memberIds] : [...memberIds, uid];
}

export function withoutMember(memberIds: readonly string[], uid: string): string[] {
  return memberIds.filter((id) => id !== uid);
}

/** [from] swapped for [to] in a member list, keeping its place and never
 * listing [to] twice (they may already be on the trip). */
export function replaceMember(memberIds: readonly string[], from: string, to: string): string[] {
  const out: string[] = [];
  for (const id of memberIds) {
    const next = id === from ? to : id;
    if (!out.includes(next)) out.push(next);
  }
  return out;
}

/** What deleting [uid]'s account does to one trip they're on: an organiser
 * with others on the trip hands it to the next person; an organiser on
 * their own deletes it; anyone else just leaves. */
export type TripFate =
  | { action: 'delete' }
  | { action: 'leave'; memberIds: string[] }
  | { action: 'hand-over'; memberIds: string[]; ownerId: string };

export function tripFateOnAccountDeletion(ownerId: string, memberIds: readonly string[], uid: string): TripFate {
  const others = withoutMember(memberIds, uid);
  if (ownerId !== uid) return { action: 'leave', memberIds: others };
  if (others.length === 0) return { action: 'delete' };
  return { action: 'hand-over', memberIds: others, ownerId: others[0] };
}

/**
 * Whether an ID token is a guest's, whose trips may move to the account the
 * phone switched to: anonymous, or an email and password whose address was
 * never confirmed (the app still counts that as a guest). Apple, Google and
 * confirmed email accounts are someone's, and never taken.
 */
export function isGuestToken(token: { email_verified?: boolean; firebase: { sign_in_provider: string } }): boolean {
  const provider = token.firebase.sign_in_provider;
  return provider === 'anonymous' || (provider === 'password' && token.email_verified !== true);
}
