import 'visual_profile.dart';

/// Which trips a downloadable art pack is for. Every value is validated
/// against Travary's vocabulary before a pack is used (see
/// `lib/data/art_pack_catalog.dart`).
///
/// A pack's scope is its most specific location selector: [cities], then
/// [regions], then [countryCodes]. A pack with none of those is an
/// experience pack for its [themes]. City and region packs always name
/// their country too, since place names repeat around the world.
class ArtPackSelectors {
  const ArtPackSelectors({
    this.countryCodes = const [],
    this.regions = const [],
    this.cities = const [],
    this.themes = const [],
    this.subjects = const [],
  });

  /// ISO 3166-1 alpha-2, upper case.
  final List<String> countryCodes;

  /// Region slugs ("kansai").
  final List<String> regions;

  /// City slugs ("kyoto").
  final List<String> cities;

  /// The looks the pack is drawn for.
  final List<ExperienceTheme> themes;

  /// The picture subjects it covers ("train", "gardens").
  final List<String> subjects;

  ArtPackScope get scope {
    if (cities.isNotEmpty) return ArtPackScope.city;
    if (regions.isNotEmpty) return ArtPackScope.region;
    if (countryCodes.isNotEmpty) return ArtPackScope.country;
    return ArtPackScope.experience;
  }

  Map<String, Object?> toJson() => {
    'countryCodes': countryCodes,
    'regions': regions,
    'cities': cities,
    'themes': [for (final theme in themes) theme.wireName],
    'subjects': subjects,
  };
}

enum ArtPackScope { city, region, country, experience }

/// The identity of an art pack: what the catalog says about it, and what
/// every picture from it remembers.
class ArtPackRef {
  const ArtPackRef({required this.id, required this.version, required this.priority, required this.selectors});

  /// Lowercase ASCII letters, digits and `_`, e.g. `city_jp_kyoto`.
  final String id;
  final int version;

  /// Higher wins among packs that match a trip equally well.
  final int priority;
  final ArtPackSelectors selectors;

  @override
  String toString() => 'ArtPack($id v$version)';
}
