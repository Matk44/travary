import { canonicalTheme, ExperienceTheme } from './visualVocabulary';

/**
 * Who decides a trip's look.
 *
 * - auto: the classifier. Each new profile updates `theme`.
 * - manual: the traveller picked a look. Profiles are still stored, but
 *   `theme` is never touched.
 *
 * Trips saved before `themeSource` existed: a classic theme (or none) is
 * automatic; anything else was picked by hand.
 */
export type ThemeSource = 'auto' | 'manual';

export interface TripThemeFields {
  theme?: unknown;
  themeSource?: unknown;
}

export function effectiveThemeSource(trip: TripThemeFields): ThemeSource {
  if (trip.themeSource === 'auto' || trip.themeSource === 'manual') return trip.themeSource;
  if (trip.theme === undefined || trip.theme === null) return 'auto';
  return canonicalTheme(trip.theme) === 'classic_travel' ? 'auto' : 'manual';
}

/**
 * The trip fields to write alongside a new profile: the effective theme for
 * an automatic trip (with `themeSource` made explicit, so a later read
 * doesn't mistake the new theme for a manual pick), nothing for a manual one.
 */
export function themeFieldsFor(
  trip: TripThemeFields,
  primaryTheme: ExperienceTheme,
): { theme: ExperienceTheme; themeSource: 'auto' } | Record<string, never> {
  if (effectiveThemeSource(trip) === 'manual') return {};
  if (trip.theme === primaryTheme && trip.themeSource === 'auto') return {};
  return { theme: primaryTheme, themeSource: 'auto' };
}
