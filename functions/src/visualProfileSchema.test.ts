import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  cleanText, normaliseVisualProfile, readStoredProfile, visualProfileResponseSchema, withoutExpiredCoordinates,
} from './visualProfileSchema';
import { canonicalTheme, EXPERIENCE_THEMES, ISO_COUNTRY_CODES, isoCountryCode, slugify } from './visualVocabulary';

const kyoto = {
  primaryTheme: 'urban_heritage',
  secondaryThemes: ['urban_modern'],
  setting: 'urban',
  moods: ['cultural', 'active'],
  location: {
    countryCode: 'JP',
    countryName: 'Japan',
    region: 'Kansai',
    city: 'Kyoto',
    locationQuery: 'Kyoto, Japan',
    confidence: 0.91,
  },
  confidence: 0.88,
  evidence: ['Kyoto and Osaka itinerary', 'Rail booking between major cities', 'Several cultural attractions'],
};

test('parses a fully valid profile', () => {
  assert.deepEqual(normaliseVisualProfile(kyoto), {
    primaryTheme: 'urban_heritage',
    secondaryThemes: ['urban_modern'],
    setting: 'urban',
    moods: ['cultural', 'active'],
    location: {
      countryCode: 'JP',
      countryName: 'Japan',
      region: 'Kansai',
      regionSlug: 'kansai',
      city: 'Kyoto',
      citySlug: 'kyoto',
      locationQuery: 'Kyoto, Japan',
      confidence: 0.91,
    },
    confidence: 0.88,
    evidence: ['Kyoto and Osaka itinerary', 'Rail booking between major cities', 'Several cultural attractions'],
  });
});

test('unknown enum values fall back safely', () => {
  const profile = normaliseVisualProfile({
    ...kyoto,
    primaryTheme: 'cyberpunk',
    secondaryThemes: ['space_opera', 'alpine'],
    setting: 'moon',
    moods: ['grumpy', 'relaxed'],
  });
  assert.equal(profile.primaryTheme, 'classic_travel');
  assert.deepEqual(profile.secondaryThemes, ['alpine']);
  assert.equal(profile.setting, 'unknown');
  assert.deepEqual(profile.moods, ['relaxed']);
});

test('low overall confidence becomes classic_travel with nothing layered on it', () => {
  const profile = normaliseVisualProfile({ ...kyoto, confidence: 0.54 });
  assert.equal(profile.primaryTheme, 'classic_travel');
  assert.deepEqual(profile.secondaryThemes, []);
  assert.equal(normaliseVisualProfile({ ...kyoto, confidence: 0.55 }).primaryTheme, 'urban_heritage');
});

test('invalid ISO country codes are dropped, valid ones upper-cased', () => {
  for (const code of ['UK', 'EU', 'XK', 'ZZ', 'JPN', 'J', 42]) {
    const profile = normaliseVisualProfile({ ...kyoto, location: { ...kyoto.location, countryCode: code } });
    assert.equal(profile.location.countryCode, undefined, String(code));
    assert.equal(profile.location.city, 'Kyoto', 'the rest of the location stays');
  }
  const lower = normaliseVisualProfile({ ...kyoto, location: { ...kyoto.location, countryCode: ' gb ' } });
  assert.equal(lower.location.countryCode, 'GB');
});

test('location fields are dropped below the confidence threshold', () => {
  const profile = normaliseVisualProfile({ ...kyoto, location: { ...kyoto.location, confidence: 0.5 } });
  assert.deepEqual(profile.location, { confidence: 0.5 });
  assert.equal(profile.primaryTheme, 'urban_heritage', 'the theme is unaffected');
});

test('duplicate moods and themes are removed, and the primary never repeats', () => {
  const profile = normaliseVisualProfile({
    ...kyoto,
    secondaryThemes: ['urban_heritage', 'urban_modern', 'urban_modern', 'alpine', 'cruise'],
    moods: ['cultural', 'cultural', 'active', 'family', 'luxury'],
  });
  assert.deepEqual(profile.secondaryThemes, ['urban_modern', 'alpine']);
  assert.deepEqual(profile.moods, ['cultural', 'active', 'family']);
});

test('confidences are clamped', () => {
  const high = normaliseVisualProfile({ ...kyoto, confidence: 7, location: { ...kyoto.location, confidence: -2 } });
  assert.equal(high.confidence, 1);
  assert.deepEqual(high.location, { confidence: 0 });
  assert.equal(normaliseVisualProfile({ ...kyoto, confidence: 'high' }).confidence, 0);
  assert.equal(normaliseVisualProfile({ ...kyoto, confidence: Number.NaN }).confidence, 0);
});

test('every string is trimmed and bounded', () => {
  const profile = normaliseVisualProfile({
    ...kyoto,
    location: {
      ...kyoto.location,
      city: `  Kyo\u0000to\n${'x'.repeat(200)}`,
      countryName: 'J'.repeat(100),
      locationQuery: 'q'.repeat(300),
    },
  });
  assert.equal(profile.location.city!.length, 80);
  assert.ok(profile.location.city!.startsWith('Kyo to x'));
  assert.equal(profile.location.countryName!.length, 60);
  assert.equal(profile.location.locationQuery!.length, 120);
});

test('evidence is short and never carries references or contact details', () => {
  const profile = normaliseVisualProfile({
    ...kyoto,
    evidence: [
      '  Beach resort   stay ',
      'Booking reference X7K2PQ',
      'Flight BA2037 to Orlando',
      'Email me at a@b.com',
      'See https://example.com',
      'Call +44 20 7946 0958',
      'Arrives 2027-04-08',
      'Beach resort stay',
      'w'.repeat(300),
      42,
      'Theme park tickets',
      'Water park day',
      'Character dining',
      'Seventh statement',
    ],
  });
  assert.deepEqual(profile.evidence.slice(0, 3), ['Beach resort stay', 'Arrives 2027-04-08', 'w'.repeat(120)]);
  assert.equal(profile.evidence.length, 6);
  assert.ok(!profile.evidence.some((e) => /X7K2PQ|BA2037|@|https|7946/.test(e)));
});

test('survives garbage', () => {
  const profile = normaliseVisualProfile(null);
  assert.equal(profile.primaryTheme, 'classic_travel');
  assert.equal(profile.setting, 'unknown');
  assert.deepEqual(profile.location, { confidence: 0 });
  assert.deepEqual(normaliseVisualProfile(['nope']).moods, []);
});

test('model output can never add image prompts, files or paths', () => {
  const profile = normaliseVisualProfile({
    ...kyoto,
    imagePrompt: 'draw a castle',
    assetPath: '../../secrets',
    packId: 'city_jp_kyoto',
    location: { ...kyoto.location, file: 'x.png' },
  }) as unknown as Record<string, unknown>;
  for (const key of ['imagePrompt', 'assetPath', 'packId']) assert.equal(profile[key], undefined);
  assert.equal((profile.location as Record<string, unknown>).file, undefined);
});

test('Gemini can never choose colours: palettes come only from validated art packs', () => {
  const schemaText = JSON.stringify(visualProfileResponseSchema).toLowerCase();
  for (const word of ['palette', 'colour', 'color', 'hex', 'rgb', 'file', 'pack']) {
    assert.ok(!schemaText.includes(word), `schema mentions ${word}`);
  }
  const profile = normaliseVisualProfile({
    ...kyoto,
    palette: { ui: { primary: '#FF0000' } },
    colors: ['#FF0000'],
  }) as unknown as Record<string, unknown>;
  assert.equal(profile.palette, undefined);
  assert.equal(profile.colors, undefined);
  assert.ok(!JSON.stringify(profile).includes('#FF0000'));
});

test('the Gemini schema only offers the vocabulary', () => {
  assert.deepEqual(visualProfileResponseSchema.properties.primaryTheme.enum, [...EXPERIENCE_THEMES]);
  assert.equal(visualProfileResponseSchema.properties.secondaryThemes.maxItems, 2);
  assert.equal(visualProfileResponseSchema.properties.moods.maxItems, 3);
  assert.equal(visualProfileResponseSchema.additionalProperties, false);
});

test('stored profiles are re-validated when read', () => {
  const stored = {
    schemaVersion: 1,
    ...normaliseVisualProfile(kyoto),
    location: { ...normaliseVisualProfile(kyoto).location, verificationStatus: 'verified', placeId: 'p1', latitude: 35, longitude: 135, coordinatesExpireAt: 5000 },
    sourceHash: 'a'.repeat(64),
  };
  const read = readStoredProfile(stored)!;
  assert.equal(read.location.placeId, 'p1');
  assert.equal(read.location.latitude, 35);
  assert.equal(readStoredProfile({ ...stored, sourceHash: 'nope' }), undefined);
  assert.equal(readStoredProfile({ ...stored, primaryTheme: 'future_theme' }), undefined);
  assert.equal(readStoredProfile({ ...stored, location: { confidence: 1 } }), undefined);

  const expired = withoutExpiredCoordinates(read, 5000);
  assert.equal(expired.location.latitude, undefined);
  assert.equal(expired.location.coordinatesExpireAt, undefined);
  assert.equal(expired.location.placeId, 'p1', 'place IDs may be kept');
  assert.equal(withoutExpiredCoordinates(read, 4999).location.latitude, 35);
});

test('vocabulary helpers', () => {
  assert.equal(ISO_COUNTRY_CODES.size, 249);
  assert.equal(isoCountryCode('fr'), 'FR');
  assert.equal(isoCountryCode('UK'), undefined);
  assert.equal(canonicalTheme('tropical'), 'coastal_resort');
  assert.equal(canonicalTheme('snow'), 'alpine');
  assert.equal(canonicalTheme('urban_heritage'), 'urban_heritage');
  assert.equal(canonicalTheme('lunar'), undefined);
  assert.equal(slugify("Côte d'Azur"), 'cote_d_azur');
  assert.equal(slugify('Kyōto'), 'kyoto');
  assert.equal(slugify('Straße'), 'strasse');
  assert.equal(slugify('  São Paulo '), 'sao_paulo');
  assert.equal(slugify('京都'), undefined);
  assert.equal(slugify(`${'a'.repeat(63)} b`), 'a'.repeat(63));
  assert.equal(cleanText('a\u202Eb', 10), 'a b');
  assert.equal(cleanText('😀😀', 3), '😀', 'never splits a surrogate pair');
});
