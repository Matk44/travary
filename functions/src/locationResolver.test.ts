import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  LocationResolver, parsePlacesResponse, PLACES_COORDINATE_TTL_MS, PLACES_FIELD_MASK, PLACES_TEXT_SEARCH_URL,
  PlaceLookup, PlacesLocationResolver, verifyLocation,
} from './locationResolver';
import { LocationHint } from './visualProfileSchema';

const NOW = 1_800_000_000_000;

const kyotoHint: LocationHint = {
  countryCode: 'JP',
  countryName: 'Japan',
  region: 'Kansai',
  regionSlug: 'kansai',
  city: 'Kyoto',
  citySlug: 'kyoto',
  locationQuery: 'Kyoto, Japan',
  confidence: 0.91,
};

class FakeResolver implements LocationResolver {
  queries: string[] = [];
  constructor(private readonly answer: PlaceLookup | (() => Promise<PlaceLookup>)) {}
  async resolve(query: string): Promise<PlaceLookup> {
    this.queries.push(query);
    return typeof this.answer === 'function' ? this.answer() : this.answer;
  }
}

const found = (countryCode: string, extra: { region?: string; locality?: string } = {}): PlaceLookup => ({
  status: 'found',
  place: { placeId: 'ChIJ-kyoto', countryCode, latitude: 35.0116, longitude: 135.7681, ...extra },
});

test('a verified place adds its ID and expiring coordinates, keeping the itinerary\'s names', async () => {
  const resolver = new FakeResolver(found('JP', { region: 'Kyoto Prefecture', locality: 'Kyoto' }));
  const location = await verifyLocation(kyotoHint, resolver, NOW);
  assert.deepEqual(resolver.queries, ['Kyoto, Japan']);
  assert.deepEqual(location, {
    ...kyotoHint,
    verificationStatus: 'verified',
    placeId: 'ChIJ-kyoto',
    latitude: 35.0116,
    longitude: 135.7681,
    coordinatesExpireAt: NOW + PLACES_COORDINATE_TTL_MS,
  });
  assert.equal(PLACES_COORDINATE_TTL_MS, 30 * 24 * 3600 * 1000);
});

test('a city named by the first-order area (Tokyo) still verifies', async () => {
  const hint = { ...kyotoHint, city: 'Tokyo', citySlug: 'tokyo', locationQuery: 'Tokyo, Japan' };
  const location = await verifyLocation(hint, new FakeResolver(found('JP', { region: 'Tokyo' })), NOW);
  assert.equal(location.verificationStatus, 'verified');
});

test('a place that names a different city is unverified', async () => {
  const location = await verifyLocation(kyotoHint, new FakeResolver(found('JP', { region: 'Osaka', locality: 'Osaka' })), NOW);
  assert.equal(location.verificationStatus, 'unverified');
  assert.equal(location.placeId, undefined);
  assert.equal(location.city, 'Kyoto', 'the hint is kept');
});

test('a conflicting country is recorded as a conflict and the hint is kept', async () => {
  const location = await verifyLocation(kyotoHint, new FakeResolver(found('FR', { locality: 'Kyoto' })), NOW);
  assert.deepEqual(location, { ...kyotoHint, verificationStatus: 'conflict' });
});

test('without a Gemini country, a coherent place verifies', async () => {
  const { countryCode: _c, ...hint } = kyotoHint;
  const location = await verifyLocation(hint, new FakeResolver(found('JP', { locality: 'Kyoto' })), NOW);
  assert.equal(location.verificationStatus, 'verified');
  assert.equal(location.countryCode, undefined, 'Places content other than IDs and coordinates is never stored');
});

test('no result, an ambiguous one, a timeout or an error keep the hint as unverified', async () => {
  const answers: Array<PlaceLookup | (() => Promise<PlaceLookup>)> = [
    { status: 'none' },
    { status: 'ambiguous' },
    { status: 'failed', reason: 'timeout' },
    { status: 'failed', reason: 'http', httpStatus: 403 },
    () => Promise.reject(new Error('socket hang up')),
  ];
  for (const answer of answers) {
    const location = await verifyLocation(kyotoHint, new FakeResolver(answer), NOW);
    assert.deepEqual(location, { ...kyotoHint, verificationStatus: 'unverified' });
  }
});

test('low-confidence or query-less locations skip Places entirely', async () => {
  const resolver = new FakeResolver(found('JP'));
  const low = await verifyLocation({ confidence: 0.4 }, resolver, NOW);
  assert.deepEqual(low, { confidence: 0.4, verificationStatus: 'skipped' });
  const { locationQuery: _q, ...noQuery } = kyotoHint;
  const skipped = await verifyLocation(noQuery, resolver, NOW);
  assert.equal(skipped.verificationStatus, 'skipped');
  assert.equal(skipped.city, 'Kyoto');
  assert.deepEqual(resolver.queries, []);
});

// ---------------------------------------------------------------- Places HTTP

interface Captured {
  url: string;
  init: RequestInit;
}

function fakeFetch(responses: Array<Response | Error | 'hang'>) {
  const captured: Captured[] = [];
  const impl = (async (url: string, init: RequestInit) => {
    captured.push({ url, init });
    const next = responses.shift();
    if (next === 'hang' || next === undefined) {
      return new Promise<Response>((_, reject) => {
        init.signal?.addEventListener('abort', () => reject(new DOMException('aborted', 'AbortError')));
      });
    }
    if (next instanceof Error) throw next;
    return next;
  }) as unknown as typeof fetch;
  return { captured, impl };
}

const placesBody = {
  places: [{
    id: 'ChIJ-kyoto',
    displayName: { text: 'Kyoto', languageCode: 'en' },
    formattedAddress: 'Kyoto, Japan',
    addressComponents: [
      { longText: 'Kyoto', shortText: 'Kyoto', types: ['locality', 'political'], languageCode: 'en' },
      { longText: 'Kyoto', shortText: 'Kyoto', types: ['administrative_area_level_1', 'political'], languageCode: 'en' },
      { longText: 'Japan', shortText: 'JP', types: ['country', 'political'], languageCode: 'en' },
    ],
    location: { latitude: 35.0116, longitude: 135.7681 },
    types: ['locality', 'political'],
  }],
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

const noSleep = async () => {};

test('Places requests use the exact field mask and a one-result limit', async () => {
  const { captured, impl } = fakeFetch([json(placesBody)]);
  const lookup = await new PlacesLocationResolver({ apiKey: 'server-key', fetchImpl: impl }).resolve('Kyoto, Japan');
  assert.equal(captured.length, 1);
  const [{ url, init }] = captured;
  assert.equal(url, PLACES_TEXT_SEARCH_URL);
  assert.equal(url, 'https://places.googleapis.com/v1/places:searchText');
  assert.equal(init.method, 'POST');
  const headers = init.headers as Record<string, string>;
  assert.equal(headers['X-Goog-FieldMask'],
    'places.id,places.displayName,places.formattedAddress,places.addressComponents,places.location,places.types');
  assert.equal(headers['X-Goog-FieldMask'], PLACES_FIELD_MASK);
  assert.equal(headers['X-Goog-Api-Key'], 'server-key');
  assert.equal(headers['Content-Type'], 'application/json');
  assert.deepEqual(JSON.parse(init.body as string), { textQuery: 'Kyoto, Japan', pageSize: 1, languageCode: 'en' });
  assert.ok(init.signal instanceof AbortSignal);
  assert.deepEqual(lookup, {
    status: 'found',
    place: { placeId: 'ChIJ-kyoto', countryCode: 'JP', region: 'Kyoto', locality: 'Kyoto', latitude: 35.0116, longitude: 135.7681 },
  });
});

test('a non-retryable 4xx is not retried', async () => {
  for (const status of [400, 403, 404]) {
    const { captured, impl } = fakeFetch([json({ error: {} }, status), json(placesBody)]);
    const lookup = await new PlacesLocationResolver({ apiKey: 'k', fetchImpl: impl, sleep: noSleep }).resolve('Kyoto');
    assert.deepEqual(lookup, { status: 'failed', reason: 'http', httpStatus: status });
    assert.equal(captured.length, 1);
  }
});

test('busy responses and network errors get exactly one more try', async () => {
  const busy = fakeFetch([json({}, 503), json(placesBody)]);
  assert.equal((await new PlacesLocationResolver({ apiKey: 'k', fetchImpl: busy.impl, sleep: noSleep }).resolve('Kyoto')).status, 'found');
  assert.equal(busy.captured.length, 2);

  const down = fakeFetch([new TypeError('fetch failed'), new TypeError('fetch failed'), json(placesBody)]);
  assert.deepEqual(
    await new PlacesLocationResolver({ apiKey: 'k', fetchImpl: down.impl, sleep: noSleep }).resolve('Kyoto'),
    { status: 'failed', reason: 'network' },
  );
  assert.equal(down.captured.length, 2);

  const stillBusy = fakeFetch([json({}, 429), json({}, 500), json(placesBody)]);
  assert.deepEqual(
    await new PlacesLocationResolver({ apiKey: 'k', fetchImpl: stillBusy.impl, sleep: noSleep }).resolve('Kyoto'),
    { status: 'failed', reason: 'http', httpStatus: 500 },
  );
  assert.equal(stillBusy.captured.length, 2);
});

test('times out after the limit without retrying', async () => {
  const { captured, impl } = fakeFetch(['hang', json(placesBody)]);
  const started = Date.now();
  const lookup = await new PlacesLocationResolver({ apiKey: 'k', fetchImpl: impl, timeoutMs: 50, sleep: noSleep }).resolve('Kyoto');
  assert.deepEqual(lookup, { status: 'failed', reason: 'timeout' });
  assert.equal(captured.length, 1);
  assert.ok(Date.now() - started < 2000);
});

test('the default timeout is 5 seconds', async () => {
  let delay = 0;
  const realSetTimeout = globalThis.setTimeout;
  const { impl } = fakeFetch([json(placesBody)]);
  globalThis.setTimeout = ((fn: () => void, ms: number) => {
    delay = ms;
    return realSetTimeout(fn, ms);
  }) as typeof setTimeout;
  try {
    const lookup = new PlacesLocationResolver({ apiKey: 'k', fetchImpl: impl }).resolve('Kyoto');
    globalThis.setTimeout = realSetTimeout;
    await lookup;
  } finally {
    globalThis.setTimeout = realSetTimeout;
  }
  assert.equal(delay, 5000);
});

test('no key means no request', async () => {
  const { captured, impl } = fakeFetch([json(placesBody)]);
  assert.deepEqual(await new PlacesLocationResolver({ apiKey: '', fetchImpl: impl }).resolve('Kyoto'), { status: 'failed', reason: 'no_key' });
  assert.equal(captured.length, 0);
});

test('a garbled response is a failure, not a crash', async () => {
  const { impl } = fakeFetch([new Response('<html>', { status: 200 })]);
  assert.deepEqual(await new PlacesLocationResolver({ apiKey: 'k', fetchImpl: impl, sleep: noSleep }).resolve('Kyoto'), { status: 'failed', reason: 'bad_response' });
});

test('reads typed address components and rejects incoherent places', () => {
  assert.deepEqual(parsePlacesResponse({}), { status: 'none' });
  assert.deepEqual(parsePlacesResponse({ places: [] }), { status: 'none' });
  const place = placesBody.places[0];
  const without = (key: string) => ({ places: [{ ...place, [key]: undefined }] });
  assert.deepEqual(parsePlacesResponse(without('id')), { status: 'ambiguous' });
  assert.deepEqual(parsePlacesResponse(without('location')), { status: 'ambiguous' });
  assert.deepEqual(parsePlacesResponse({ places: [{ ...place, addressComponents: place.addressComponents.slice(0, 2) }] }), { status: 'ambiguous' });
  assert.deepEqual(parsePlacesResponse({ places: [{ ...place, location: { latitude: 135, longitude: 35 } }] }), { status: 'ambiguous' });
  const postalTown = parsePlacesResponse({
    places: [{
      ...place,
      addressComponents: [
        { longText: 'Windermere', shortText: 'Windermere', types: ['postal_town'] },
        { longText: 'England', shortText: 'England', types: ['administrative_area_level_1'] },
        { longText: 'United Kingdom', shortText: 'GB', types: ['country'] },
      ],
    }],
  });
  assert.equal(postalTown.status === 'found' && postalTown.place.locality, 'Windermere');
});
