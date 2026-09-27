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
