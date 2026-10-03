import '../domain/domain.dart';

/// How well a source of artwork suits a trip, best first. The card resolver
/// tries a booking's subject at each rank in turn (see `ArtResolver`).
enum ArtRank {
  /// A pack for the trip's verified city.
  city,

  /// A pack for its verified region.
  region,

  /// A pack for its country.
  country,

  /// A pack (or bundled art) for the trip's look.
  primary,

  /// A pack (or bundled art) for a secondary theme of an automatic trip.
  secondary,

  /// Theme-free and classic art: the bundled core that is always there.
  core,
}

/// A location is trusted for country art without verification only when
/// Gemini was at least this sure of it.
const highConfidenceLocation = 0.8;

/// The parts of a trip's destination that may choose artwork.
class TrustedDestination {
  const TrustedDestination({this.countryCode, this.regionSlug, this.citySlug, this.experienceFirst = false});

  static const none = TrustedDestination();

  final String? countryCode;
  final String? regionSlug;
  final String? citySlug;

  /// Unverified places rank below the trip's experience art.
  final bool experienceFirst;

  bool get isEmpty => countryCode == null;
}

/// What of [trip]'s destination may pick art packs:
///
/// - the traveller's own destination, or a verified one: city, region and
///   country;
/// - unverified: a confident country only, ranked after experience art;
/// - conflict or skipped (or no profile): nothing.
///
/// City and region always need a country too (place names repeat).
TrustedDestination trustedDestinationOf(Trip trip) {
  final location = trip.effectiveLocation;
  final country = location?.countryCode;
  if (location == null || country == null) return TrustedDestination.none;
  return switch (location.verification) {
    LocationVerification.verified => TrustedDestination(
      countryCode: country,
      regionSlug: location.regionSlug,
      citySlug: location.citySlug,
    ),
    LocationVerification.unverified when location.confidence >= highConfidenceLocation => TrustedDestination(
      countryCode: country,
      experienceFirst: true,
    ),
    _ => TrustedDestination.none,
  };
}

/// The secondary themes that shape [trip]'s art: only an automatic trip's,
/// since a manual pick replaces the classifier's view.
List<ExperienceTheme> secondaryThemesOf(Trip trip) {
  final profile = trip.visualProfile;
  if (!trip.isAutomaticLook || profile == null) return const [];
  return [
    for (final theme in profile.secondaryThemes)
      if (theme != trip.effectiveTheme) theme,
  ];
}

/// Everything the card resolver needs to know about one trip's art.
class TripArtContext {
  const TripArtContext({
    required this.theme,
    this.secondaryThemes = const [],
    this.packRanks = const {},
    this.rankOrder = standardRankOrder,
  });

  /// Just a look, no packs (design tools, drafts outside a trip).
  factory TripArtContext.forTheme(ExperienceTheme theme) => TripArtContext(theme: theme);

  static const standardRankOrder = [
    ArtRank.city,
    ArtRank.region,
    ArtRank.country,
    ArtRank.primary,
    ArtRank.secondary,
    ArtRank.core,
  ];

  /// For an unverified destination: experience art before country art.
  static const experienceFirstRankOrder = [
    ArtRank.city,
    ArtRank.region,
    ArtRank.primary,
    ArtRank.country,
    ArtRank.secondary,
    ArtRank.core,
  ];

  final ExperienceTheme theme;
  final List<ExperienceTheme> secondaryThemes;

  /// Installed packs that suit the trip, by pack ID.
  final Map<String, ArtRank> packRanks;

  /// Ranks from best to worst for this trip.
  final List<ArtRank> rankOrder;

  /// The rank of bundled art drawn for [artTheme] (null = any theme).
  ArtRank? rankOfBundledTheme(ExperienceTheme? artTheme) {
    if (artTheme == theme) return ArtRank.primary;
    if (artTheme != null && secondaryThemes.contains(artTheme)) return ArtRank.secondary;
    if (artTheme == null || artTheme == ExperienceTheme.classicTravel) return ArtRank.core;
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is TripArtContext &&
      other.theme == theme &&
      _sameList(other.secondaryThemes, secondaryThemes) &&
      _sameList(other.rankOrder, rankOrder) &&
      other.packRanks.length == packRanks.length &&
      packRanks.entries.every((e) => other.packRanks[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    theme,
    Object.hashAll(secondaryThemes),
    Object.hashAll(rankOrder),
    Object.hashAllUnordered([for (final e in packRanks.entries) Object.hash(e.key, e.value)]),
  );
}

/// How [pack] suits a trip with [theme], [secondaryThemes] and
/// [destination], or null if it doesn't.
///
/// A pack matches at its own scope only: a Kyoto city pack never stands in
/// for the rest of Japan.
ArtRank? packRankFor(
  ArtPackRef pack, {
  required ExperienceTheme theme,
  List<ExperienceTheme> secondaryThemes = const [],
  TrustedDestination destination = TrustedDestination.none,
}) {
  final selectors = pack.selectors;
  final country = destination.countryCode;
  final inCountry = country != null && selectors.countryCodes.contains(country);
  switch (selectors.scope) {
    case ArtPackScope.city:
      final city = destination.citySlug;
      return inCountry && city != null && selectors.cities.contains(city) ? ArtRank.city : null;
    case ArtPackScope.region:
      final region = destination.regionSlug;
      return inCountry && region != null && selectors.regions.contains(region) ? ArtRank.region : null;
    case ArtPackScope.country:
      return inCountry ? ArtRank.country : null;
    case ArtPackScope.experience:
      if (selectors.themes.contains(theme)) return ArtRank.primary;
      if (secondaryThemes.any(selectors.themes.contains)) return ArtRank.secondary;
      if (selectors.themes.contains(ExperienceTheme.classicTravel)) return ArtRank.core;
      return null;
  }
}

/// The ranks of a trip's own destination packs, best first.
const destinationRanks = [ArtRank.city, ArtRank.region, ArtRank.country];

/// The place a destination pack of [rank] shows for a trip at [location]:
/// its city, region or country. Null if that name isn't known, or [rank]
/// isn't a destination's.
String? destinationName(TripLocationHint location, ArtRank rank) => switch (rank) {
  ArtRank.city => location.city,
  ArtRank.region => location.region,
  ArtRank.country => location.countryName,
  ArtRank.primary || ArtRank.secondary || ArtRank.core => null,
};

/// The art context for [trip], given the packs installed on this phone.
TripArtContext artContextFor(Trip trip, Iterable<ArtPackRef> installed) {
  final theme = trip.effectiveTheme;
  final secondary = secondaryThemesOf(trip);
  final destination = trustedDestinationOf(trip);
  return TripArtContext(
    theme: theme,
    secondaryThemes: secondary,
    packRanks: {
      for (final pack in installed)
        if (packRankFor(pack, theme: theme, secondaryThemes: secondary, destination: destination) case final rank?)
          pack.id: rank,
    },
    rankOrder: destination.experienceFirst ? TripArtContext.experienceFirstRankOrder : TripArtContext.standardRankOrder,
  );
}

/// The packs to download for [trip] from [available] (the remote catalog):
/// the smallest set that covers it, which is one destination pack (city,
/// else region, else country) and one pack for its look, in the order
/// they should arrive. Conflicting or unconfirmed places get no
/// destination pack; bundled classic art needs no download.
///
/// [subjects] are the trip's picture subjects, used to prefer the pack that
/// covers more of them when several fit equally.
List<ArtPackRef> packsToDownload(Trip trip, Iterable<ArtPackRef> available, {Set<String> subjects = const {}}) {
  final theme = trip.effectiveTheme;
  final destination = trustedDestinationOf(trip);
  ArtPackRef? bestDestination;
  ArtRank? bestDestinationRank;
  ArtPackRef? bestExperience;

  for (final pack in available) {
    final rank = packRankFor(pack, theme: theme, destination: destination);
    if (rank == null) continue;
    if (rank.index <= ArtRank.country.index) {
      if (bestDestination == null ||
          rank.index < bestDestinationRank!.index ||
          (rank == bestDestinationRank && _better(pack, bestDestination, theme, subjects))) {
        bestDestination = pack;
        bestDestinationRank = rank;
      }
    } else if (rank == ArtRank.primary) {
      if (bestExperience == null || _better(pack, bestExperience, theme, subjects)) bestExperience = pack;
    }
  }

  return [
    if (destination.experienceFirst) ?bestExperience,
    ?bestDestination,
    if (!destination.experienceFirst) ?bestExperience,
  ];
}

/// Among equally placed packs: drawn for the trip's look, then the
/// catalog's priority, then more of the trip's subjects, then ID.
bool _better(ArtPackRef a, ArtPackRef b, ExperienceTheme theme, Set<String> subjects) {
  final themeA = a.selectors.themes.contains(theme);
  final themeB = b.selectors.themes.contains(theme);
  if (themeA != themeB) return themeA;
  if (a.priority != b.priority) return a.priority > b.priority;
  final coverA = a.selectors.subjects.where(subjects.contains).length;
  final coverB = b.selectors.subjects.where(subjects.contains).length;
  if (coverA != coverB) return coverA > coverB;
  return a.id.compareTo(b.id) < 0;
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
