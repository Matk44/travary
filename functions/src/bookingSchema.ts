/**
 * The shape Smart Import asks Gemini for, and the validation applied to
 * whatever comes back. Mirrors the app's Booking model
 * (lib/domain/booking.dart, lib/domain/booking_kind.dart).
 */

export const KINDS = ['flight', 'stay', 'attraction', 'dining', 'transport', 'activity', 'event', 'note'] as const;
export type Kind = (typeof KINDS)[number];

export const DETAIL_KEYS = ['flightNumber', 'seats', 'room', 'guests', 'partySize', 'company'] as const;
type DetailKey = (typeof DETAIL_KEYS)[number];

/** Fields Gemini may flag as uncertain. The app highlights them. */
export const FIELDS = [
  'kind', 'title', 'startDate', 'startTime', 'endDate', 'endTime', 'location', 'reference', 'notes',
  ...DETAIL_KEYS.map((key) => `details.${key}`),
] as const;

export interface DraftBooking {
  kind: Kind;
  title: string;
  startDate: string;
  startTime?: string;
  endDate?: string;
  endTime?: string;
  location?: string;
  reference?: string;
  notes?: string;
  details: Partial<Record<DetailKey, string>>;
  uncertain: string[];
}

const text = (description: string) => ({ type: 'string', description });

/** JSON Schema for Gemini's structured output. */
export const responseSchema = {
  type: 'object',
  properties: {
    // Kept deliberately simple: Gemini rejects schemas past a complexity
    // limit. List size and allowed "uncertain" values are enforced by
    // normaliseBookings instead.
    bookings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          kind: { type: 'string', enum: [...KINDS] },
          title: text('Short name a traveller would use: "London to Orlando", "Lagoon Resort", "Sunshine Park".'),
          startDate: text('YYYY-MM-DD'),
          startTime: text('24-hour HH:mm, local time exactly as printed. Omit if there is no time.'),
          endDate: text('YYYY-MM-DD. Omit if the booking ends the same day.'),
          endTime: text('24-hour HH:mm, local time exactly as printed. Omit if not shown.'),
          location: text('The most useful place: hotel address, departure airport, venue, meeting point.'),
          reference: text('Booking or confirmation reference exactly as printed.'),
          notes: text('Only genuinely useful extras, under 200 characters.'),
          details: {
            type: 'object',
            properties: {
              flightNumber: text('e.g. "BA 2037"'),
              seats: text('Comma-separated, e.g. "22A, 22B"'),
              room: text('Room number'),
              guests: text('Number of guests or tickets, digits only'),
              partySize: text('Table size, digits only'),
              company: text('Transport company, e.g. "Alamo", "Eurostar"'),
            },
          },
          uncertain: {
            type: 'array',
            items: { type: 'string' },
            description: `Fields you could not read with confidence, from: ${FIELDS.join(', ')}.`,
          },
        },
        required: ['kind', 'title', 'startDate'],
      },
    },
    warning: text('A short note if something important could not be read. Omit otherwise.'),
  },
  required: ['bookings'],
} as const;

const DATE = /^\d{4}-\d{2}-\d{2}$/;
const TIME = /^\d{2}:\d{2}$/;

function isValidDate(value: unknown): value is string {
  if (typeof value !== 'string' || !DATE.test(value)) return false;
  const [y, m, d] = value.split('-').map(Number);
  const date = new Date(Date.UTC(y, m - 1, d));
  return date.getUTCFullYear() === y && date.getUTCMonth() === m - 1 && date.getUTCDate() === d;
}

function isValidTime(value: unknown): value is string {
  if (typeof value !== 'string' || !TIME.test(value)) return false;
  const [h, m] = value.split(':').map(Number);
  return h < 24 && m < 60;
}

function clean(value: unknown, max: number): string | undefined {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.replace(/\s+/g, ' ').trim();
  return trimmed ? trimmed.slice(0, max) : undefined;
}

/**
 * Turns Gemini's output into bookings the app can trust structurally:
 * known kinds only, real dates and times, bounded text, known detail keys.
 * Anything it had to fix is added to `uncertain`.
 */
export function normaliseBookings(raw: unknown): { bookings: DraftBooking[]; warning?: string } {
  const root = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
  const list = Array.isArray(root.bookings) ? root.bookings.slice(0, 12) : [];
  const bookings: DraftBooking[] = [];

  for (const item of list) {
    if (!item || typeof item !== 'object') continue;
    const b = item as Record<string, unknown>;
    if (!isValidDate(b.startDate)) continue;

    const uncertain = new Set<string>(
      Array.isArray(b.uncertain) ? b.uncertain.filter((f): f is string => (FIELDS as readonly string[]).includes(f as string)) : [],
    );
    const kind: Kind = (KINDS as readonly string[]).includes(b.kind as string) ? (b.kind as Kind) : 'note';
    if (kind !== b.kind) uncertain.add('kind');

    const title = clean(b.title, 80);
    if (!title) uncertain.add('title');

    const startTime = isValidTime(b.startTime) ? b.startTime : undefined;
    if (b.startTime !== undefined && !startTime) uncertain.add('startTime');

    let endDate = isValidDate(b.endDate) ? b.endDate : undefined;
    if (endDate && endDate < b.startDate) {
      endDate = undefined;
      uncertain.add('endDate');
    }
    if (endDate === b.startDate) endDate = undefined;
    const endTime = isValidTime(b.endTime) ? b.endTime : undefined;
    if (b.endTime !== undefined && !endTime) uncertain.add('endTime');

    const details: Partial<Record<DetailKey, string>> = {};
    const rawDetails = (b.details && typeof b.details === 'object' ? b.details : {}) as Record<string, unknown>;
    for (const key of DETAIL_KEYS) {
      let value = clean(rawDetails[key], 60);
      if (value && (key === 'guests' || key === 'partySize')) {
        const digits = value.match(/\d+/)?.[0];
        if (!digits) uncertain.add(`details.${key}`);
        value = digits;
      }
      if (value) details[key] = value;
    }

    bookings.push({
      kind,
      title: title ?? 'Booking',
      startDate: b.startDate,
      ...(startTime && { startTime }),
      ...(endDate && { endDate }),
      ...(endTime && { endTime }),
      ...optional('location', clean(b.location, 160)),
      ...optional('reference', clean(b.reference, 40)),
      ...optional('notes', clean(b.notes, 200)),
      details,
      uncertain: [...uncertain],
    });
  }

  const warning = clean(root.warning, 200);
  return warning ? { bookings, warning } : { bookings };
}

function optional<K extends string>(key: K, value: string | undefined): Partial<Record<K, string>> {
  return value ? ({ [key]: value } as Record<K, string>) : {};
}
