import 'country_codes.dart';

/// The character of a trip, which picks its artwork: the same "dinner" card
/// looks like a beach grill on a coastal holiday and a mountain hut on an
/// alpine one. Country and city are location metadata, never themes.
///
/// [wireName] is what Firestore and the server store; it matches
/// `EXPERIENCE_THEMES` in `functions/src/visualVocabulary.ts` (a test
/// compares them). Never persist [name]: Dart identifiers can be renamed.
enum ExperienceTheme {
  classicTravel('classic_travel', 'Classic'),
  coastalResort('coastal_resort', 'Coastal resort'),
  urbanModern('urban_modern', 'Modern city'),
  urbanHeritage('urban_heritage', 'Historic city'),
  alpine('alpine', 'Alpine'),
  countryside('countryside', 'Countryside'),
  outdoorAdventure('outdoor_adventure', 'Outdoors'),
  themepark('themepark', 'Theme park'),
  cruise('cruise', 'Cruise'),
  roadtrip('roadtrip', 'Road trip'),
  wellnessRetreat('wellness_retreat', 'Wellness');

  const ExperienceTheme(this.wireName, this.label);

  final String wireName;
  final String label;

  /// Theme names written by earlier versions of the app (and used in older
  /// artwork file names).
  static const legacyAliases = <String, ExperienceTheme>{
    'classic': classicTravel,
    'tropical': coastalResort,
    'city': urbanModern,
    'snow': alpine,
    'countryside': countryside,
    'themepark': themepark,
  };

  /// The theme for a stored name (current or legacy), or null if unknown.
  static ExperienceTheme? tryParse(Object? value) {
    if (value is! String) return null;
    for (final theme in values) {
      if (theme.wireName == value) return theme;
    }
    return legacyAliases[value];
  }

  /// Like [tryParse], falling back to classic for anything unknown, so trips
  /// written by a newer app still load.
  static ExperienceTheme parse(Object? value) => tryParse(value) ?? classicTravel;
}

/// Who chooses a trip's look.
enum ThemeSource {
  /// Travary, from the trip's visual profile.
  auto('auto'),

  /// The traveller picked a look; classification never changes it.
  manual('manual');

  const ThemeSource(this.wireName);

  final String wireName;

  static ThemeSource? tryParse(Object? value) {
    for (final source in values) {
      if (source.wireName == value) return source;
    }
    return null;
  }

  /// For trips saved before `themeSource` existed: a classic theme (or none)
  /// counts as automatic, anything else as picked by hand. Mirrors
  /// `effectiveThemeSource` in `functions/src/visualThemeRules.ts`.
  static ThemeSource inferFor(Object? storedTheme) {
    if (storedTheme == null) return auto;
    return ExperienceTheme.tryParse(storedTheme) == ExperienceTheme.classicTravel ? auto : manual;
  }
}

/// Where the trip mostly happens.
enum TripSetting {
  coastal('coastal'),
  urban('urban'),
  mountain('mountain'),
  countryside('countryside'),
  themepark('themepark'),
  cruise('cruise'),
  wilderness('wilderness'),
  mixed('mixed'),
  unknown('unknown');

  const TripSetting(this.wireName);

  final String wireName;

  static TripSetting parse(Object? value) {
    for (final setting in values) {
      if (setting.wireName == value) return setting;
    }
    return unknown;
  }
}

/// How the trip feels.
enum TripMood {
  relaxed('relaxed'),
  cultural('cultural'),
  active('active'),
  family('family'),
  luxury('luxury'),
  nightlife('nightlife'),
  romantic('romantic'),
  wellness('wellness');

  const TripMood(this.wireName);

  final String wireName;

  static TripMood? tryParse(Object? value) {
    for (final mood in values) {
      if (mood.wireName == value) return mood;
    }
    return null;
  }
}

/// How far the destination was checked (Places Text Search on the server).
enum LocationVerification {
  /// A geocoder found the place and its country agrees.
  verified('verified'),

  /// Not checked successfully; the itinerary's reading is kept.
  unverified('unverified'),

  /// The geocoder's country disagrees. Destination art isn't used.
  conflict('conflict'),

  /// Too uncertain to look up.
  skipped('skipped');

  const LocationVerification(this.wireName);

  final String wireName;

  /// Unknown statuses from a newer server are treated as unverified: usable
  /// only when confident, never for city or region art.
  static LocationVerification parse(Object? value) {
    for (final status in values) {
      if (status.wireName == value) return status;
    }
    return unverified;
  }
}

/// The trip's main destination, as far as it's known.
class TripLocationHint {
  const TripLocationHint({
    this.countryCode,
    this.countryName,
    this.region,
    this.regionSlug,
    this.city,
    this.citySlug,
    this.locationQuery,
    required this.confidence,
    this.verification = LocationVerification.skipped,
    this.placeId,
  });

  /// ISO 3166-1 alpha-2, upper case.
  final String? countryCode;
  final String? countryName;
  final String? region;

  /// [region] as an art-pack selector ("kansai").
  final String? regionSlug;
  final String? city;

  /// [city] as an art-pack selector ("kyoto").
  final String? citySlug;
  final String? locationQuery;

  /// 0...1.
  final double confidence;
  final LocationVerification verification;
  final String? placeId;

  static TripLocationHint? tryParse(Object? json) {
    if (json is! Map) return null;
    String? text(String key, int max) {
      final value = json[key];
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty || trimmed.length > max ? null : trimmed;
    }

    final country = text('countryCode', 2)?.toUpperCase();
    return TripLocationHint(
      countryCode: country != null && isoCountryCodes.contains(country) ? country : null,
      countryName: text('countryName', 120),
      region: text('region', 160),
      regionSlug: _slugOrNull(json['regionSlug']) ?? asciiSlug(text('region', 160)),
      city: text('city', 160),
      citySlug: _slugOrNull(json['citySlug']) ?? asciiSlug(text('city', 160)),
      locationQuery: text('locationQuery', 240),
      confidence: _confidence(json['confidence']),
      verification: LocationVerification.parse(json['verificationStatus']),
      placeId: text('placeId', 1024),
    );
  }

  Map<String, Object?> toJson() => {
    'countryCode': ?countryCode,
    'countryName': ?countryName,
    'region': ?region,
    'regionSlug': ?regionSlug,
    'city': ?city,
    'citySlug': ?citySlug,
    'locationQuery': ?locationQuery,
    'confidence': confidence,
    'verificationStatus': verification.wireName,
    'placeId': ?placeId,
  };

  @override
  bool operator ==(Object other) =>
      other is TripLocationHint &&
      other.countryCode == countryCode &&
      other.countryName == countryName &&
      other.region == region &&
      other.regionSlug == regionSlug &&
      other.city == city &&
      other.citySlug == citySlug &&
      other.locationQuery == locationQuery &&
      other.confidence == confidence &&
      other.verification == verification &&
      other.placeId == placeId;

  @override
  int get hashCode => Object.hash(
    countryCode,
    countryName,
    region,
    regionSlug,
    city,
    citySlug,
    locationQuery,
    confidence,
    verification,
    placeId,
  );
}

/// What the server's classifier made of a trip (`trips/{id}.visualProfile`,
/// written by the `classifyTripVisuals` function only).
///
/// Parsing is tolerant: values a newer server adds fall back safely, so an
/// older app can always read the trip. The classifier's `evidence` is kept
/// on the server for diagnostics and isn't read here.
class TripVisualProfile {
  const TripVisualProfile({
    this.schemaVersion = 1,
    required this.primaryTheme,
    this.secondaryThemes = const [],
    this.setting = TripSetting.unknown,
    this.moods = const [],
    this.location,
    required this.confidence,
    required this.sourceHash,
  });

  final int schemaVersion;
  final ExperienceTheme primaryTheme;
  final List<ExperienceTheme> secondaryThemes;
  final TripSetting setting;
  final List<TripMood> moods;
  final TripLocationHint? location;

  /// 0...1.
  final double confidence;

  /// The server's hash of the itinerary it classified.
  final String sourceHash;

  /// Null when [json] isn't a profile at all.
  static TripVisualProfile? tryParse(Object? json) {
    if (json is! Map) return null;
    final hash = json['sourceHash'];
    if (hash is! String || hash.isEmpty) return null;
    final primary = ExperienceTheme.parse(json['primaryTheme']);
    return TripVisualProfile(
      schemaVersion: json['schemaVersion'] is num ? (json['schemaVersion'] as num).toInt() : 1,
      primaryTheme: primary,
      secondaryThemes: [
        for (final value in json['secondaryThemes'] as List? ?? const []) ?ExperienceTheme.tryParse(value),
      ].where((theme) => theme != primary).toSet().toList(),
      setting: TripSetting.parse(json['setting']),
      moods: {for (final value in json['moods'] as List? ?? const []) ?TripMood.tryParse(value)}.toList(),
      location: TripLocationHint.tryParse(json['location']),
      confidence: _confidence(json['confidence']),
      sourceHash: hash,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'primaryTheme': primaryTheme.wireName,
    'secondaryThemes': [for (final theme in secondaryThemes) theme.wireName],
    'setting': setting.wireName,
    'moods': [for (final mood in moods) mood.wireName],
    'location': ?location?.toJson(),
    'confidence': confidence,
    'sourceHash': sourceHash,
  };

  @override
  bool operator ==(Object other) =>
      other is TripVisualProfile &&
      other.schemaVersion == schemaVersion &&
      other.primaryTheme == primaryTheme &&
      _sameList(other.secondaryThemes, secondaryThemes) &&
      other.setting == setting &&
      _sameList(other.moods, moods) &&
      other.location == location &&
      other.confidence == confidence &&
      other.sourceHash == sourceHash;

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    primaryTheme,
    Object.hashAll(secondaryThemes),
    setting,
    Object.hashAll(moods),
    location,
    confidence,
    sourceHash,
  );
}

/// A lowercase ASCII selector for a place name ("New York" → "new_york").
/// The server sends proper slugs (with accents folded); this is only the
/// fallback, and only for plain-ASCII names: "Kyōto" gets none rather than
/// a wrong "ky_to".
String? asciiSlug(String? name) {
  if (name == null || name.codeUnits.any((unit) => unit > 0x7E)) return null;
  final slug = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  if (slug.isEmpty) return null;
  return slug.length <= 64 ? slug : slug.substring(0, 64).replaceAll(RegExp(r'_+$'), '');
}

final _slugPattern = RegExp(r'^[a-z0-9_]{1,64}$');

/// True for an art-pack selector: lowercase ASCII letters, digits, `_`.
bool isSlug(Object? value) => value is String && _slugPattern.hasMatch(value);

String? _slugOrNull(Object? value) => isSlug(value) ? value as String : null;

double _confidence(Object? value) {
  if (value is! num || value.isNaN) return 0;
  return value.toDouble().clamp(0, 1).toDouble();
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
