import 'dart:math' as math;

import '../domain/domain.dart';

/// Where a trip can go: a country, or a region or city in one. The
/// built-in list behind "Where to?": every country, plus well-known
/// regions and cities (every place with an art pack among them).
///
/// Works offline and costs nothing: a trip named "Japan holiday" knows it's
/// in Japan the moment it's typed. Anything the list doesn't know ("Grandma's",
/// a village) is left to the server's classifier and the trip's bookings.
class Place {
  Place._(
    this.countryCode, {
    required this.names,
    List<String> adjectives = const [],
    this.region,
    this.city,
    this.within,
    this.askFirst = false,
    required this.rank,
  }) : _folded = [for (final name in names) foldPlaceText(name)],
       _adjectives = [for (final word in adjectives) foldPlaceText(word)];

  /// ISO 3166-1 alpha-2.
  final String countryCode;
  final String? region;
  final String? city;

  /// Its own name first, then others it goes by ("Disney World").
  final List<String> names;

  /// For a region: the wider region it lies in ("England" for the Lake
  /// District).
  final String? within;

  /// The own name is also an everyday word or a first name ("Nice",
  /// "Jordan"), or names two places ("Georgia"): offered as a suggestion,
  /// never detected on its own.
  final bool askFirst;

  /// Lower comes first among suggestions.
  final int rank;
  final List<String> _folded;

  /// Words for its people or things ("Japanese", "Scottish"): they name it
  /// in a trip's name ("Italian lakes") but are never offered as names.
  final List<String> _adjectives;

  String get name => names.first;
  String get countryName => _countryNames[countryCode]!;
  bool get isCountry => city == null && region == null;

  /// "Kyoto, Japan", "Japan".
  String get label => isCountry ? name : '$name, $countryName';

  TripDestination get destination => TripDestination(
    countryCode: countryCode,
    countryName: countryName,
    region: region,
    regionSlug: region == null ? null : asciiSlug(foldPlaceText(region!)),
    city: city,
    citySlug: city == null ? null : asciiSlug(foldPlaceText(city!)),
  );

  @override
  String toString() => 'Place($label)';
}

/// A suggestion while typing "Where to?": [place] by the [name] that
/// matched ("Disney World"), and the trip's name with the partly typed
/// place completed ("Summer in Kyo" → "Summer in Kyoto").
class PlaceSuggestion {
  const PlaceSuggestion(this.place, this.name, this.completed);

  final Place place;
  final String name;
  final String completed;

  /// Where [name] is, when it doesn't say: "Orlando, United States" for
  /// Disney World, "Japan" for Kyoto; null for a country.
  String? get where => name != place.name ? place.label : (place.isCountry ? null : place.countryName);
}

/// Every place, countries included.
final List<Place> places = List.unmodifiable(_buildPlaces());

/// The country's own entry.
Place countryPlace(String countryCode) => _countries[countryCode]!;

/// Lower case, no accents or punctuation, single spaces: how names are
/// compared ("Côte d’Ivoire" → "cote d ivoire").
String foldPlaceText(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_plainLetters[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();
}

/// The place [text] (a trip's name) is about, or null if it names none
/// clearly. The most specific place wins ("Kyoto, Japan" is Kyoto); several
/// places in one country give the country ("Kyoto and Tokyo" is Japan);
/// several countries give nothing, for the traveller to choose.
Place? detectPlace(String text) {
  final folded = ' ${foldPlaceText(text)} ';
  if (folded.trim().isEmpty) return null;

  final hits = <_Hit>[];
  void find(String name, Place? place) {
    for (var at = folded.indexOf(' $name '); at >= 0; at = folded.indexOf(' $name ', at + 1)) {
      // "Jordan's wedding" is about a person.
      if (place != null && folded.startsWith(' s ', at + name.length + 1)) continue;
      hits.add(_Hit(place, at, name.length));
    }
  }

  for (final place in places) {
    for (final (i, name) in place._folded.indexed) {
      if (i > 0 || !place.askFirst) find(name, place);
    }
    for (final word in place._adjectives) {
      find(word, place);
    }
  }
  // Wider than any country: these win their words and name nothing.
  for (final phrase in _notCountries) {
    find(phrase, null);
  }

  // Words naming two places decide nothing.
  final bySpan = <(int, int), Set<Place?>>{};
  for (final hit in hits) {
    bySpan.putIfAbsent((hit.at, hit.length), () => {}).add(hit.place);
  }
  hits.removeWhere((hit) => bySpan[(hit.at, hit.length)]!.length > 1);

  // The longest name covering some words wins them: "New York" over "York".
  hits.sort((a, b) => b.length != a.length ? b.length - a.length : a.at - b.at);
  final kept = <_Hit>[];
  for (final hit in hits) {
    if (kept.every((other) => !other.overlaps(hit))) kept.add(hit);
  }
  final found = {for (final hit in kept) ?hit.place};
  if (found.isEmpty) return null;

  final countries = {for (final place in found) place.countryCode};
  if (countries.length > 1) return null;

  // Drop places that only contain another one found ("Orlando, Florida").
  final specific = [
    for (final place in found)
      if (!found.any((other) => other != place && _contains(place, other))) place,
  ];
  return specific.length == 1 ? specific.single : countryPlace(countries.single);
}

/// Places that complete what's being typed at the end of [text], best
/// first: the longest typed tail that starts a place's name, then a
/// place's own name over its other names, then the better-known place.
List<PlaceSuggestion> suggestPlaces(String text, {int limit = 3}) {
  final words = RegExp(r'\S+').allMatches(text).toList();
  final found = <Place, ({int tail, bool own, PlaceSuggestion suggestion})>{};
  for (var k = math.max(0, words.length - 3); k < words.length; k++) {
    final start = words[k].start;
    final query = foldPlaceText(text.substring(start));
    final tail = words.length - k;
    if (query.length < 3 || (tail == 1 && _notPlaces.contains(query))) continue;
    for (final place in places) {
      if (found.containsKey(place)) continue;
      for (final (i, name) in place._folded.indexed) {
        if (!name.startsWith(query)) continue;
        final suggestion = PlaceSuggestion(place, place.names[i], '${text.substring(0, start)}${place.names[i]}');
        found[place] = (tail: tail, own: i == 0, suggestion: suggestion);
        break;
      }
    }
  }
  final ranked = found.values.toList()
    ..sort((a, b) {
      if (a.tail != b.tail) return b.tail - a.tail;
      if (a.own != b.own) return a.own ? -1 : 1;
      return a.suggestion.place.rank - b.suggestion.place.rank;
    });
  return [for (final match in ranked.take(limit)) match.suggestion];
}

/// Places for the destination picker: any name, or any word of one, that
/// starts with [query]. Everyone's favourites first when [query] is empty.
List<Place> searchPlaces(String query, {int limit = 60}) {
  final q = foldPlaceText(query);
  if (q.isEmpty) {
    return [...places.where((p) => p.isCountry)]..sort((a, b) => a.rank - b.rank);
  }
  final starts = <Place>[];
  final words = <Place>[];
  for (final place in places) {
    if (place._folded.any((name) => name.startsWith(q))) {
      starts.add(place);
    } else if (place._folded.any((name) => name.split(' ').any((word) => word.startsWith(q)))) {
      words.add(place);
    }
  }
  int byRank(Place a, Place b) => a.rank - b.rank;
  return [...(starts..sort(byRank)), ...(words..sort(byRank))].take(limit).toList();
}

class _Hit {
  const _Hit(this.place, this.at, this.length);

  /// Null for words that name no place.
  final Place? place;
  final int at;
  final int length;

  bool overlaps(_Hit other) => at < other.at + other.length && other.at < at + length;
}

/// Whether [outer] is a wider place that [inner] lies in.
bool _contains(Place outer, Place inner) {
  if (outer.countryCode != inner.countryCode) return false;
  if (outer.isCountry) return !inner.isCountry;
  if (outer.city != null) return false;
  return inner.city != null
      ? inner.region == outer.region || inner.within == outer.region
      : inner.within == outer.region;
}

/// Single words that start place names but are only filler in a trip's
/// name ("Week in" isn't India).
const _notPlaces = {'and', 'the', 'for', 'our', 'with', 'trip', 'tour', 'holiday', 'holidays', 'vacation', 'week'};

/// Phrases with a country's word in them that name somewhere wider.
const _notCountries = [
  'south america', 'south american', 'central america', 'central american', 'latin america', //
  'latin american', 'north america', 'north american', 'indian ocean',
];

final Map<String, Place> _countries = {
  for (final place in places)
    if (place.isCountry) place.countryCode: place,
};

List<Place> _buildPlaces() {
  final popular = {for (final (i, code) in _popularCountries.indexed) code: i};
  final byName = [...isoCountryCodes]..sort((a, b) => _countryNames[a]!.compareTo(_countryNames[b]!));
  final countries = [
    for (final (i, code) in byName.indexed)
      Place._(
        code,
        names: [_countryNames[code]!, ...?_countryAlso[code]],
        adjectives: _countryAdjectives[code] ?? const [],
        askFirst: _askFirstCountries.contains(code),
        rank: popular[code] ?? 1000 + i,
      ),
  ];
  final spots = [
    for (final (i, spot) in _spots.indexed)
      Place._(
        spot.country,
        names: [spot.city ?? spot.region!, ...spot.also],
        adjectives: spot.adjectives,
        region: spot.region,
        city: spot.city,
        within: spot.within,
        askFirst: spot.ask,
        rank: 100 + i,
      ),
  ];
  return [...countries, ...spots];
}

/// A region or city in [country]. A city's [region] is the area it's in
/// ("Kansai"); a region alone is the place itself ("Lake District"), and
/// may lie [within] a wider one.
class _Spot {
  const _Spot(
    this.country, {
    this.city,
    this.region,
    this.within,
    this.also = const [],
    this.adjectives = const [],
    this.ask = false,
  });

  final String country;
  final String? city;
  final String? region;
  final String? within;
  final List<String> also;
  final List<String> adjectives;
  final bool ask;
}

/// The most visited countries, in suggestion order.
const _popularCountries = [
  'FR', 'ES', 'US', 'IT', 'GB', 'TR', 'MX', 'TH', 'DE', 'GR', 'JP', 'PT', 'AT', 'NL', 'CA', 'AU', 'AE', //
  'HR', 'CH', 'IE', 'ID', 'MY', 'SG', 'VN', 'IN', 'MA', 'EG', 'ZA', 'NZ', 'KR', 'CN', 'BR', 'CZ', 'HU', //
  'IS', 'MT', 'CY', 'MV', 'JM', 'DO', 'BS', 'BB', 'LK', 'PL', 'BE', 'DK', 'SE', 'NO', 'FI', 'KE', 'TZ', //
  'MU', 'AR', 'PE', 'CR',
];

/// Country names that are also first names or other places.
const _askFirstCountries = {'GE', 'JO', 'TD', 'JE'};

/// Other names countries go by.
const _countryAlso = {
  'AE': ['UAE'],
  'AG': ['Antigua and Barbuda', 'Antigua'],
  'BA': ['Bosnia and Herzegovina', 'Bosnia'],
  'BL': ['St Barts', 'St Barths', 'Saint Barthelemy'],
  'CD': ['Democratic Republic of the Congo'],
  'CG': ['Republic of the Congo'],
  'CI': ['Ivory Coast', 'Cote d Ivoire'],
  'CV': ['Cabo Verde'],
  'CZ': ['Czech Republic'],
  'GB': ['UK', 'Britain', 'Great Britain'],
  'IE': ['Republic of Ireland'],
  'KN': ['St Kitts and Nevis', 'Saint Kitts', 'St Kitts'],
  'KR': ['Korea'],
  'LC': ['Saint Lucia'],
  'MF': ['Saint Martin'],
  'MK': ['Macedonia'],
  'MM': ['Burma'],
  'MO': ['Macao'],
  'NL': ['Holland', 'The Netherlands'],
  'SZ': ['Swaziland'],
  'TC': ['Turks and Caicos'],
  'TR': ['Turkiye'],
  'TT': ['Trinidad and Tobago', 'Trinidad', 'Tobago'],
  'US': ['USA', 'United States of America'],
  'VA': ['Vatican'],
  'VC': ['Saint Vincent', 'St Vincent'],
  'VN': ['Viet Nam'],
};

/// Words for a country's people or things, which name it in a trip's name
/// ("Italian lakes").
const _countryAdjectives = {
  'AR': ['Argentinian', 'Argentine'],
  'AT': ['Austrian'],
  'AU': ['Australian'],
  'BE': ['Belgian'],
  'BR': ['Brazilian'],
  'CA': ['Canadian'],
  'CH': ['Swiss'],
  'CN': ['Chinese'],
  'CU': ['Cuban'],
  'CY': ['Cypriot'],
  'CZ': ['Czech'],
  'DE': ['German'],
  'DK': ['Danish'],
  'EG': ['Egyptian'],
  'ES': ['Spanish'],
  'FI': ['Finnish'],
  'FR': ['French'],
  'GB': ['British'],
  'GR': ['Greek'],
  'HR': ['Croatian'],
  'HU': ['Hungarian'],
  'ID': ['Indonesian'],
  'IE': ['Irish'],
  'IS': ['Icelandic'],
  'IT': ['Italian'],
  'JM': ['Jamaican'],
  'JP': ['Japanese'],
  'KR': ['Korean'],
  'LK': ['Sri Lankan'],
  'MA': ['Moroccan'],
  'MT': ['Maltese'],
  'MX': ['Mexican'],
  'MY': ['Malaysian'],
  'NL': ['Dutch'],
  'NO': ['Norwegian'],
  'PE': ['Peruvian'],
  'PH': ['Filipino'],
  'PT': ['Portuguese'],
  'SE': ['Swedish'],
  'SG': ['Singaporean'],
  'TH': ['Thai'],
  'TR': ['Turkish'],
  'US': ['American'],
  'VN': ['Vietnamese'],
  'ZA': ['South African'],
};

/// Well-known regions and cities. Every place with an art pack is here
/// (a test checks), and its city and region names give the pack's slugs.
const _spots = [
  // With art packs.
  _Spot('JP', city: 'Kyoto', region: 'Kansai'),
  _Spot('US', city: 'Orlando', region: 'Florida', also: ['Disney World', 'Walt Disney World', 'Universal Orlando']),
  _Spot('FR', city: 'Paris', region: 'Île-de-France', also: ['Disneyland Paris']),
  _Spot('GB', region: 'Lake District', within: 'England', also: ['The Lake District', 'The Lakes']),
  _Spot('ID', region: 'Bali', also: ['Ubud', 'Seminyak']),
  // Japan and East Asia.
  _Spot('JP', city: 'Tokyo', region: 'Kanto', also: ['Tokyo Disneyland', 'Tokyo DisneySea']),
  _Spot('JP', city: 'Osaka', region: 'Kansai'),
  _Spot('JP', city: 'Nara', region: 'Kansai'),
  _Spot('JP', city: 'Hiroshima'),
  _Spot('JP', region: 'Hokkaido', also: ['Sapporo', 'Niseko']),
  _Spot('JP', region: 'Okinawa'),
  _Spot('KR', city: 'Seoul'),
  _Spot('KR', city: 'Busan'),
  _Spot('KR', region: 'Jeju'),
  _Spot('CN', city: 'Beijing'),
  _Spot('CN', city: 'Shanghai'),
  _Spot('TW', city: 'Taipei'),
  // South-East Asia.
  _Spot('TH', city: 'Bangkok'),
  _Spot('TH', region: 'Phuket'),
  _Spot('TH', city: 'Chiang Mai'),
  _Spot('TH', region: 'Koh Samui', also: ['Samui']),
  _Spot('TH', region: 'Krabi'),
  _Spot('ID', region: 'Lombok'),
  _Spot('ID', city: 'Jakarta'),
  _Spot('MY', city: 'Kuala Lumpur'),
  _Spot('MY', region: 'Langkawi'),
  _Spot('MY', region: 'Penang'),
  _Spot('VN', city: 'Hanoi'),
  _Spot('VN', city: 'Ho Chi Minh City', also: ['Saigon']),
  _Spot('VN', region: 'Ha Long Bay', also: ['Halong Bay']),
  _Spot('VN', city: 'Hoi An'),
  _Spot('KH', city: 'Siem Reap', also: ['Angkor Wat']),
  _Spot('PH', region: 'Palawan'),
  _Spot('PH', region: 'Boracay'),
  // South Asia.
  _Spot('IN', city: 'Delhi', also: ['New Delhi']),
  _Spot('IN', city: 'Mumbai'),
  _Spot('IN', region: 'Goa'),
  _Spot('IN', region: 'Kerala'),
  _Spot('IN', region: 'Rajasthan', also: ['Jaipur']),
  _Spot('IN', city: 'Agra', also: ['Taj Mahal']),
  _Spot('NP', city: 'Kathmandu'),
  // The United Kingdom and Ireland.
  _Spot('GB', region: 'England', adjectives: ['English']),
  _Spot('GB', region: 'Scotland', adjectives: ['Scottish']),
  _Spot('GB', region: 'Wales', adjectives: ['Welsh']),
  _Spot('GB', region: 'Northern Ireland'),
  _Spot('GB', city: 'London', region: 'England'),
  _Spot('GB', city: 'Edinburgh', region: 'Scotland'),
  _Spot('GB', city: 'Glasgow', region: 'Scotland'),
  _Spot('GB', region: 'Scottish Highlands', within: 'Scotland', also: ['The Highlands', 'Isle of Skye', 'Skye']),
  _Spot('GB', city: 'Manchester', region: 'England'),
  _Spot('GB', city: 'Liverpool', region: 'England'),
  _Spot('GB', city: 'York', region: 'England'),
  _Spot('GB', city: 'Bath', region: 'England', ask: true),
  _Spot('GB', city: 'Oxford', region: 'England'),
  _Spot('GB', city: 'Cambridge', region: 'England'),
  _Spot('GB', city: 'Brighton', region: 'England'),
  _Spot('GB', city: 'Bristol', region: 'England'),
  _Spot('GB', city: 'Cardiff', region: 'Wales'),
  _Spot('GB', city: 'Belfast', region: 'Northern Ireland'),
  _Spot('GB', region: 'Cornwall', within: 'England'),
  _Spot('GB', region: 'Devon', within: 'England'),
  _Spot('GB', region: 'Cotswolds', within: 'England', also: ['The Cotswolds']),
  _Spot('GB', region: 'Yorkshire', within: 'England', also: ['Yorkshire Dales']),
  _Spot('GB', region: 'Peak District', within: 'England'),
  _Spot('GB', region: 'Snowdonia', within: 'Wales', also: ['Eryri']),
  _Spot('GB', region: 'Norfolk', within: 'England', also: ['Norfolk Broads']),
  _Spot('GB', region: 'Isle of Wight', within: 'England'),
  _Spot('IE', city: 'Dublin'),
  _Spot('IE', city: 'Galway'),
  // France.
  _Spot('FR', region: 'Côte d’Azur', also: ['French Riviera', 'Cote d Azur']),
  _Spot('FR', city: 'Nice', region: 'Côte d’Azur', ask: true),
  _Spot('FR', region: 'Provence'),
  _Spot('FR', region: 'Normandy'),
  _Spot('FR', region: 'Brittany'),
  _Spot('FR', region: 'Dordogne'),
  _Spot('FR', region: 'Loire Valley'),
  _Spot('FR', region: 'French Alps', also: ['Chamonix']),
  _Spot('FR', region: 'Corsica'),
  _Spot('FR', city: 'Bordeaux'),
  _Spot('FR', city: 'Lyon'),
  _Spot('FR', city: 'Marseille'),
  // Italy.
  _Spot('IT', city: 'Rome', region: 'Lazio', also: ['Roma']),
  _Spot('IT', city: 'Florence', region: 'Tuscany', also: ['Firenze']),
  _Spot('IT', region: 'Tuscany'),
  _Spot('IT', city: 'Venice', region: 'Veneto', also: ['Venezia']),
  _Spot('IT', city: 'Verona', region: 'Veneto'),
  _Spot('IT', city: 'Milan', region: 'Lombardy', also: ['Milano']),
  _Spot('IT', region: 'Lake Como'),
  _Spot('IT', region: 'Lake Garda'),
  _Spot('IT', city: 'Naples', region: 'Campania', also: ['Napoli']),
  _Spot('IT', region: 'Amalfi Coast', within: 'Campania', also: ['Positano', 'Sorrento', 'Capri']),
  _Spot('IT', region: 'Sicily'),
  _Spot('IT', region: 'Sardinia'),
  _Spot('IT', region: 'Puglia', also: ['Apulia']),
  _Spot('IT', region: 'Dolomites', also: ['The Dolomites']),
  _Spot('IT', region: 'Cinque Terre'),
  // Spain and Portugal.
  _Spot('ES', city: 'Barcelona', region: 'Catalonia'),
  _Spot('ES', city: 'Madrid'),
  _Spot('ES', city: 'Seville', region: 'Andalusia', also: ['Sevilla']),
  _Spot('ES', city: 'Málaga', region: 'Andalusia', also: ['Malaga']),
  _Spot('ES', city: 'Granada', region: 'Andalusia'),
  _Spot('ES', city: 'Valencia'),
  _Spot('ES', region: 'Costa del Sol', also: ['Marbella']),
  _Spot('ES', region: 'Costa Brava'),
  _Spot('ES', city: 'Benidorm'),
  _Spot('ES', region: 'Mallorca', also: ['Majorca']),
  _Spot('ES', region: 'Menorca', also: ['Minorca']),
  _Spot('ES', region: 'Ibiza'),
  _Spot('ES', region: 'Canary Islands', also: ['The Canaries', 'Canaries']),
  _Spot('ES', region: 'Tenerife', within: 'Canary Islands'),
  _Spot('ES', region: 'Lanzarote', within: 'Canary Islands'),
  _Spot('ES', region: 'Gran Canaria', within: 'Canary Islands'),
  _Spot('ES', region: 'Fuerteventura', within: 'Canary Islands'),
  _Spot('PT', city: 'Lisbon', also: ['Lisboa']),
  _Spot('PT', city: 'Porto', also: ['Oporto']),
  _Spot('PT', region: 'Algarve', also: ['The Algarve']),
  _Spot('PT', region: 'Madeira'),
  _Spot('PT', region: 'Azores', also: ['The Azores']),
  // Greece, Croatia, Türkiye, Cyprus.
  _Spot('GR', city: 'Athens'),
  _Spot('GR', region: 'Santorini'),
  _Spot('GR', region: 'Mykonos'),
  _Spot('GR', region: 'Crete'),
  _Spot('GR', region: 'Corfu'),
  _Spot('GR', region: 'Rhodes'),
  _Spot('GR', region: 'Zakynthos', also: ['Zante']),
  _Spot('GR', region: 'Kefalonia'),
  _Spot('HR', city: 'Dubrovnik'),
  _Spot('HR', city: 'Split', ask: true),
  _Spot('HR', region: 'Hvar'),
  _Spot('TR', city: 'Istanbul'),
  _Spot('TR', city: 'Antalya'),
  _Spot('TR', city: 'Bodrum'),
  _Spot('TR', city: 'Dalaman'),
  _Spot('TR', city: 'Marmaris'),
  _Spot('TR', region: 'Cappadocia'),
  _Spot('CY', city: 'Paphos'),
  _Spot('CY', city: 'Ayia Napa'),
  // The rest of Europe.
  _Spot('NL', city: 'Amsterdam'),
  _Spot('BE', city: 'Brussels'),
  _Spot('BE', city: 'Bruges'),
  _Spot('DE', city: 'Berlin'),
  _Spot('DE', city: 'Munich', region: 'Bavaria', also: ['München']),
  _Spot('DE', region: 'Bavaria'),
  _Spot('DE', city: 'Hamburg'),
  _Spot('DE', region: 'Black Forest'),
  _Spot('AT', city: 'Vienna', also: ['Wien']),
  _Spot('AT', city: 'Salzburg'),
  _Spot('AT', region: 'Tyrol', also: ['Tirol', 'Innsbruck']),
  _Spot('CH', city: 'Zurich'),
  _Spot('CH', city: 'Geneva'),
  _Spot('CH', city: 'Lucerne'),
  _Spot('CH', city: 'Zermatt'),
  _Spot('CH', city: 'Interlaken'),
  _Spot('CZ', city: 'Prague'),
  _Spot('HU', city: 'Budapest'),
  _Spot('PL', city: 'Kraków', also: ['Krakow']),
  _Spot('PL', city: 'Warsaw'),
  _Spot('DK', city: 'Copenhagen'),
  _Spot('SE', city: 'Stockholm'),
  _Spot('NO', city: 'Oslo'),
  _Spot('NO', region: 'Norwegian Fjords', also: ['The Fjords', 'Fjords']),
  _Spot('FI', city: 'Helsinki'),
  _Spot('FI', region: 'Lapland', also: ['Rovaniemi']),
  _Spot('IS', city: 'Reykjavik', also: ['Reykjavík']),
  // The United States.
  _Spot('US', region: 'Florida'),
  _Spot('US', city: 'Miami', region: 'Florida'),
  _Spot('US', region: 'Florida Keys', within: 'Florida', also: ['Key West']),
  _Spot('US', city: 'New York', also: ['New York City', 'NYC', 'Manhattan']),
  _Spot('US', city: 'Las Vegas', also: ['Vegas']),
  _Spot('US', region: 'California'),
  _Spot('US', city: 'Los Angeles', region: 'California', also: ['Hollywood']),
  _Spot('US', city: 'San Francisco', region: 'California'),
  _Spot('US', city: 'San Diego', region: 'California'),
  _Spot('US', city: 'Anaheim', region: 'California', also: ['Disneyland California', 'Disneyland Resort']),
  _Spot('US', region: 'Hawaii', also: ['Hawai i', 'Oahu', 'Honolulu', 'Waikiki']),
  _Spot('US', region: 'Maui', within: 'Hawaii'),
  _Spot('US', city: 'Chicago'),
  _Spot('US', city: 'Boston'),
  _Spot('US', city: 'Washington DC', also: ['Washington D C']),
  _Spot('US', city: 'New Orleans'),
  _Spot('US', city: 'Nashville'),
  _Spot('US', city: 'Seattle'),
  _Spot('US', region: 'Alaska'),
  _Spot('US', region: 'Texas'),
  _Spot('US', region: 'Arizona', also: ['Grand Canyon']),
  _Spot('US', region: 'Utah'),
  _Spot('US', region: 'Colorado'),
  _Spot('US', region: 'Yellowstone'),
  _Spot('US', region: 'New Mexico'),
  _Spot('US', region: 'New Jersey'),
  _Spot('US', region: 'New England'),
  _Spot('US', region: 'Georgia', ask: true),
  // Canada, Mexico, the Caribbean, South America.
  _Spot('CA', city: 'Toronto'),
  _Spot('CA', city: 'Vancouver'),
  _Spot('CA', city: 'Montreal', also: ['Montréal']),
  _Spot('CA', city: 'Quebec City'),
  _Spot('CA', region: 'Banff', also: ['Lake Louise']),
  _Spot('CA', city: 'Whistler'),
  _Spot('CA', city: 'Niagara Falls'),
  _Spot('MX', city: 'Cancún', also: ['Cancun']),
  _Spot('MX', region: 'Riviera Maya', also: ['Tulum', 'Playa del Carmen']),
  _Spot('MX', city: 'Mexico City'),
  _Spot('MX', region: 'Los Cabos', also: ['Cabo']),
  _Spot('DO', city: 'Punta Cana'),
  _Spot('CU', city: 'Havana'),
  _Spot('BR', city: 'Rio de Janeiro', also: ['Rio']),
  _Spot('BR', city: 'São Paulo', also: ['Sao Paulo']),
  _Spot('AR', city: 'Buenos Aires'),
  _Spot('PE', city: 'Cusco', also: ['Cuzco', 'Machu Picchu']),
  // Australia and New Zealand.
  _Spot('AU', city: 'Sydney', region: 'New South Wales'),
  _Spot('AU', region: 'New South Wales'),
  _Spot('AU', city: 'Melbourne'),
  _Spot('AU', city: 'Brisbane'),
  _Spot('AU', region: 'Gold Coast'),
  _Spot('AU', city: 'Cairns', also: ['Great Barrier Reef']),
  _Spot('AU', city: 'Perth', ask: true),
  _Spot('AU', region: 'Uluru'),
  _Spot('NZ', city: 'Auckland'),
  _Spot('NZ', city: 'Queenstown'),
  _Spot('NZ', city: 'Wellington'),
  _Spot('NZ', city: 'Rotorua'),
  // The Middle East and Africa.
  _Spot('AE', city: 'Dubai'),
  _Spot('AE', city: 'Abu Dhabi'),
  _Spot('QA', city: 'Doha'),
  _Spot('JO', region: 'Petra', ask: true),
  _Spot('IL', city: 'Tel Aviv'),
  _Spot('IL', city: 'Jerusalem'),
  _Spot('EG', city: 'Cairo'),
  _Spot('EG', city: 'Sharm El Sheikh', also: ['Sharm']),
  _Spot('EG', city: 'Hurghada'),
  _Spot('EG', city: 'Luxor'),
  _Spot('MA', city: 'Marrakech', also: ['Marrakesh']),
  _Spot('ZA', city: 'Cape Town'),
  _Spot('ZA', city: 'Johannesburg'),
  _Spot('ZA', region: 'Kruger', also: ['Kruger National Park']),
  _Spot('KE', region: 'Masai Mara', also: ['Maasai Mara']),
  _Spot('TZ', region: 'Zanzibar'),
  _Spot('TZ', region: 'Serengeti'),
];

/// Every country's English name. Plain forms where the standard one is
/// awkward for a traveller ("Hong Kong", "Turkey").
const _countryNames = {
  'AD': 'Andorra', 'AE': 'United Arab Emirates', 'AF': 'Afghanistan', 'AG': 'Antigua & Barbuda', //
  'AI': 'Anguilla', 'AL': 'Albania', 'AM': 'Armenia', 'AO': 'Angola', 'AQ': 'Antarctica', //
  'AR': 'Argentina', 'AS': 'American Samoa', 'AT': 'Austria', 'AU': 'Australia', 'AW': 'Aruba', //
  'AX': 'Åland Islands', 'AZ': 'Azerbaijan', 'BA': 'Bosnia & Herzegovina', 'BB': 'Barbados', //
  'BD': 'Bangladesh', 'BE': 'Belgium', 'BF': 'Burkina Faso', 'BG': 'Bulgaria', 'BH': 'Bahrain', //
  'BI': 'Burundi', 'BJ': 'Benin', 'BL': 'St Barthélemy', 'BM': 'Bermuda', 'BN': 'Brunei', //
  'BO': 'Bolivia', 'BQ': 'Caribbean Netherlands', 'BR': 'Brazil', 'BS': 'Bahamas', 'BT': 'Bhutan', //
  'BV': 'Bouvet Island', 'BW': 'Botswana', 'BY': 'Belarus', 'BZ': 'Belize', 'CA': 'Canada', //
  'CC': 'Cocos (Keeling) Islands', 'CD': 'DR Congo', 'CF': 'Central African Republic', //
  'CG': 'Congo', 'CH': 'Switzerland', 'CI': 'Côte d’Ivoire', 'CK': 'Cook Islands', 'CL': 'Chile', //
  'CM': 'Cameroon', 'CN': 'China', 'CO': 'Colombia', 'CR': 'Costa Rica', 'CU': 'Cuba', //
  'CV': 'Cape Verde', 'CW': 'Curaçao', 'CX': 'Christmas Island', 'CY': 'Cyprus', 'CZ': 'Czechia', //
  'DE': 'Germany', 'DJ': 'Djibouti', 'DK': 'Denmark', 'DM': 'Dominica', 'DO': 'Dominican Republic', //
  'DZ': 'Algeria', 'EC': 'Ecuador', 'EE': 'Estonia', 'EG': 'Egypt', 'EH': 'Western Sahara', //
  'ER': 'Eritrea', 'ES': 'Spain', 'ET': 'Ethiopia', 'FI': 'Finland', 'FJ': 'Fiji', //
  'FK': 'Falkland Islands', 'FM': 'Micronesia', 'FO': 'Faroe Islands', 'FR': 'France', 'GA': 'Gabon', //
  'GB': 'United Kingdom', 'GD': 'Grenada', 'GE': 'Georgia', 'GF': 'French Guiana', 'GG': 'Guernsey', //
  'GH': 'Ghana', 'GI': 'Gibraltar', 'GL': 'Greenland', 'GM': 'Gambia', 'GN': 'Guinea', //
  'GP': 'Guadeloupe', 'GQ': 'Equatorial Guinea', 'GR': 'Greece', //
  'GS': 'South Georgia & South Sandwich Islands', 'GT': 'Guatemala', 'GU': 'Guam', //
  'GW': 'Guinea-Bissau', 'GY': 'Guyana', 'HK': 'Hong Kong', 'HM': 'Heard & McDonald Islands', //
  'HN': 'Honduras', 'HR': 'Croatia', 'HT': 'Haiti', 'HU': 'Hungary', 'ID': 'Indonesia', //
  'IE': 'Ireland', 'IL': 'Israel', 'IM': 'Isle of Man', 'IN': 'India', //
  'IO': 'British Indian Ocean Territory', 'IQ': 'Iraq', 'IR': 'Iran', 'IS': 'Iceland', 'IT': 'Italy', //
  'JE': 'Jersey', 'JM': 'Jamaica', 'JO': 'Jordan', 'JP': 'Japan', 'KE': 'Kenya', 'KG': 'Kyrgyzstan', //
  'KH': 'Cambodia', 'KI': 'Kiribati', 'KM': 'Comoros', 'KN': 'St Kitts & Nevis', 'KP': 'North Korea', //
  'KR': 'South Korea', 'KW': 'Kuwait', 'KY': 'Cayman Islands', 'KZ': 'Kazakhstan', 'LA': 'Laos', //
  'LB': 'Lebanon', 'LC': 'St Lucia', 'LI': 'Liechtenstein', 'LK': 'Sri Lanka', 'LR': 'Liberia', //
  'LS': 'Lesotho', 'LT': 'Lithuania', 'LU': 'Luxembourg', 'LV': 'Latvia', 'LY': 'Libya', //
  'MA': 'Morocco', 'MC': 'Monaco', 'MD': 'Moldova', 'ME': 'Montenegro', 'MF': 'St Martin', //
  'MG': 'Madagascar', 'MH': 'Marshall Islands', 'MK': 'North Macedonia', 'ML': 'Mali', //
  'MM': 'Myanmar', 'MN': 'Mongolia', 'MO': 'Macau', 'MP': 'Northern Mariana Islands', //
  'MQ': 'Martinique', 'MR': 'Mauritania', 'MS': 'Montserrat', 'MT': 'Malta', 'MU': 'Mauritius', //
  'MV': 'Maldives', 'MW': 'Malawi', 'MX': 'Mexico', 'MY': 'Malaysia', 'MZ': 'Mozambique', //
  'NA': 'Namibia', 'NC': 'New Caledonia', 'NE': 'Niger', 'NF': 'Norfolk Island', 'NG': 'Nigeria', //
  'NI': 'Nicaragua', 'NL': 'Netherlands', 'NO': 'Norway', 'NP': 'Nepal', 'NR': 'Nauru', 'NU': 'Niue', //
  'NZ': 'New Zealand', 'OM': 'Oman', 'PA': 'Panama', 'PE': 'Peru', 'PF': 'French Polynesia', //
  'PG': 'Papua New Guinea', 'PH': 'Philippines', 'PK': 'Pakistan', 'PL': 'Poland', //
  'PM': 'St Pierre & Miquelon', 'PN': 'Pitcairn Islands', 'PR': 'Puerto Rico', 'PS': 'Palestine', //
  'PT': 'Portugal', 'PW': 'Palau', 'PY': 'Paraguay', 'QA': 'Qatar', 'RE': 'Réunion', 'RO': 'Romania', //
  'RS': 'Serbia', 'RU': 'Russia', 'RW': 'Rwanda', 'SA': 'Saudi Arabia', 'SB': 'Solomon Islands', //
  'SC': 'Seychelles', 'SD': 'Sudan', 'SE': 'Sweden', 'SG': 'Singapore', 'SH': 'St Helena', //
  'SI': 'Slovenia', 'SJ': 'Svalbard & Jan Mayen', 'SK': 'Slovakia', 'SL': 'Sierra Leone', //
  'SM': 'San Marino', 'SN': 'Senegal', 'SO': 'Somalia', 'SR': 'Suriname', 'SS': 'South Sudan', //
  'ST': 'São Tomé & Príncipe', 'SV': 'El Salvador', 'SX': 'Sint Maarten', 'SY': 'Syria', //
  'SZ': 'Eswatini', 'TC': 'Turks & Caicos Islands', 'TD': 'Chad', 'TF': 'French Southern Territories', //
  'TG': 'Togo', 'TH': 'Thailand', 'TJ': 'Tajikistan', 'TK': 'Tokelau', 'TL': 'Timor-Leste', //
  'TM': 'Turkmenistan', 'TN': 'Tunisia', 'TO': 'Tonga', 'TR': 'Turkey', 'TT': 'Trinidad & Tobago', //
  'TV': 'Tuvalu', 'TW': 'Taiwan', 'TZ': 'Tanzania', 'UA': 'Ukraine', 'UG': 'Uganda', //
  'UM': 'US Outlying Islands', 'US': 'United States', 'UY': 'Uruguay', 'UZ': 'Uzbekistan', //
  'VA': 'Vatican City', 'VC': 'St Vincent & the Grenadines', 'VE': 'Venezuela', //
  'VG': 'British Virgin Islands', 'VI': 'US Virgin Islands', 'VN': 'Vietnam', 'VU': 'Vanuatu', //
  'WF': 'Wallis & Futuna', 'WS': 'Samoa', 'YE': 'Yemen', 'YT': 'Mayotte', 'ZA': 'South Africa', //
  'ZM': 'Zambia', 'ZW': 'Zimbabwe',
};

/// Accented letters as plain ones, for comparing names.
const _plainLetters = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', 'æ': 'ae', 'ç': 'c', 'č': 'c', //
  'ć': 'c', 'đ': 'd', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ğ': 'g', 'ì': 'i', 'í': 'i', //
  'î': 'i', 'ï': 'i', 'ī': 'i', 'ı': 'i', 'ł': 'l', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', //
  'ö': 'o', 'ø': 'o', 'ō': 'o', 'œ': 'oe', 'ř': 'r', 'ś': 's', 'š': 's', 'ş': 's', 'ș': 's', 'ß': 'ss', //
  'ț': 't', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ý': 'y', 'ÿ': 'y', 'ź': 'z', 'ż': 'z', //
  'ž': 'z',
};
