/**
 * The words a trip's visual profile is made of. Gemini may only choose from
 * these lists, and the app matches art packs against them.
 *
 * Keep in step with lib/domain/visual_profile.dart (a Flutter test compares
 * the lists). Every experience theme is backed by Travary artwork; country
 * and city are location metadata, never themes.
 */

export const EXPERIENCE_THEMES = [
  'classic_travel',
  'coastal_resort',
  'urban_modern',
  'urban_heritage',
  'alpine',
  'countryside',
  'outdoor_adventure',
  'themepark',
  'cruise',
  'roadtrip',
  'wellness_retreat',
] as const;
export type ExperienceTheme = (typeof EXPERIENCE_THEMES)[number];

export const SETTINGS = [
  'coastal',
  'urban',
  'mountain',
  'countryside',
  'themepark',
  'cruise',
  'wilderness',
  'mixed',
  'unknown',
] as const;
export type Setting = (typeof SETTINGS)[number];

export const MOODS = [
  'relaxed',
  'cultural',
  'active',
  'family',
  'luxury',
  'nightlife',
  'romantic',
  'wellness',
] as const;
export type Mood = (typeof MOODS)[number];

export const VERIFICATION_STATUSES = ['verified', 'unverified', 'conflict', 'skipped'] as const;
export type VerificationStatus = (typeof VERIFICATION_STATUSES)[number];

/** Theme names written by earlier versions of the app. */
export const LEGACY_THEME_ALIASES: Readonly<Record<string, ExperienceTheme>> = {
  classic: 'classic_travel',
  tropical: 'coastal_resort',
  city: 'urban_modern',
  snow: 'alpine',
  countryside: 'countryside',
  themepark: 'themepark',
};

/** The current name for a stored theme (new or legacy), or undefined. */
export function canonicalTheme(value: unknown): ExperienceTheme | undefined {
  if (typeof value !== 'string') return undefined;
  if ((EXPERIENCE_THEMES as readonly string[]).includes(value)) return value as ExperienceTheme;
  return LEGACY_THEME_ALIASES[value];
}

export function isOneOf<T extends string>(list: readonly T[], value: unknown): value is T {
  return typeof value === 'string' && (list as readonly string[]).includes(value);
}

/** Officially assigned ISO 3166-1 alpha-2 codes (249). */
export const ISO_COUNTRY_CODES: ReadonlySet<string> = new Set(
  (
    'AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ ' +
    'BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ ' +
    'CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ ' +
    'DE DJ DK DM DO DZ ' +
    'EC EE EG EH ER ES ET ' +
    'FI FJ FK FM FO FR ' +
    'GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY ' +
    'HK HM HN HR HT HU ' +
    'ID IE IL IM IN IO IQ IR IS IT ' +
    'JE JM JO JP ' +
    'KE KG KH KI KM KN KP KR KW KY KZ ' +
    'LA LB LC LI LK LR LS LT LU LV LY ' +
    'MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ ' +
    'NA NC NE NF NG NI NL NO NP NR NU NZ ' +
    'OM ' +
    'PA PE PF PG PH PK PL PM PN PR PS PT PW PY ' +
    'QA ' +
    'RE RO RS RU RW ' +
    'SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SY SZ ' +
    'TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ ' +
    'UA UG UM US UY UZ ' +
    'VA VC VE VG VI VN VU ' +
    'WF WS ' +
    'YE YT ' +
    'ZA ZM ZW'
  ).split(' '),
);

/** An ISO alpha-2 code in upper case, or undefined when it isn't one. */
export function isoCountryCode(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const code = value.trim().toUpperCase();
  return ISO_COUNTRY_CODES.has(code) ? code : undefined;
}

/** Letters NFKD doesn't take apart. */
const FOLDED: Readonly<Record<string, string>> = {
  ß: 'ss', æ: 'ae', œ: 'oe', ø: 'o', đ: 'd', ð: 'd', ł: 'l', þ: 'th', ı: 'i',
};

/**
 * A place name as an art-pack selector: "Côte d'Azur" → "cote_d_azur".
 * Lowercase ASCII letters, digits and underscores, at most 64 characters.
 * Undefined when nothing is left (e.g. a name in a non-Latin script).
 */
export function slugify(value: string): string | undefined {
  const slug = value
    .toLowerCase()
    .replace(/[ßæœøđðłþı]/g, (letter) => FOLDED[letter] ?? letter)
    .normalize('NFKD')
    .replace(/\p{M}+/gu, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 64)
    .replace(/_+$/g, '');
  return slug.length > 0 ? slug : undefined;
}
