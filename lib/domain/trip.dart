import 'checklist.dart';
import 'country_codes.dart';
import 'local_date.dart';
import 'premium.dart';
import 'visual_profile.dart';

/// A holiday: a named group of bookings.
///
/// Trips are formed automatically as bookings are added, so dates are
/// normally derived from the bookings. [plannedStart]/[plannedEnd] only
/// matter for a trip created before anything was booked.
class Trip {
  const Trip({
    required this.id,
    required this.title,
    this.theme = ExperienceTheme.classicTravel,
    this.themeSource = ThemeSource.auto,
    this.visualProfile,
    this.unknownTheme,
    this.plannedStart,
    this.plannedEnd,
    this.destination,
    required this.ownerId,
    required this.memberIds,
    this.memberNames = const {},
    this.premium,
    this.hiddenGaps = const {},
    this.checklist = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;

  /// The stored theme: the traveller's pick for a manual trip; for an
  /// automatic one, the server's copy of the classifier's choice (kept for
  /// readers that don't read profiles). Cards use [effectiveTheme].
  final ExperienceTheme theme;
  final ThemeSource themeSource;

  /// What the server's classifier made of the itinerary. Server-written
  /// only; never sent by the app.
  final TripVisualProfile? visualProfile;

  /// A stored theme this version doesn't know (written by a newer app or
  /// server). [theme] shows classic meanwhile, and saving the trip writes
  /// the unknown name back unchanged unless the traveller picks a look.
  final String? unknownTheme;
  final LocalDate? plannedStart;
  final LocalDate? plannedEnd;

  /// Where the traveller said the trip goes ("Where to?"). Wins over the
  /// classifier's reading of the itinerary.
  final TripDestination? destination;

  /// Who created the trip. Only they can delete it.
  final String ownerId;

  /// Everyone who can see the trip (the owner plus invited family).
  final List<String> memberIds;

  /// What each member is called ("Alex"), set when they invite or join.
  /// Server-written only.
  final Map<String, String> memberNames;

  /// Plus unlocked for everyone on the trip. Set by the server only.
  final TripPremium? premium;

  /// Gaps in the plan the travellers said aren't needed ("we're staying
  /// with family"), by `PlanGap.id`. Shared, so nobody on the trip is
  /// asked again.
  final Set<String> hiddenGaps;

  /// "Before you go": things to sort out that aren't bookings, by item id.
  /// Shared, and changed one item at a time (`TravelRepository
  /// .saveChecklistItem`), so two people ticking at once don't collide.
  final Map<String, ChecklistItem> checklist;

  bool get isShared => memberIds.length > 1;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAutomaticLook => themeSource == ThemeSource.auto;

  /// The destination that chooses place art: the traveller's, else the
  /// classifier's.
  TripLocationHint? get effectiveLocation => destination?.location ?? visualProfile?.location;

  /// The look the cards use: the classifier's choice for an automatic trip
  /// (as soon as its profile arrives), the traveller's for a manual one.
  ExperienceTheme get effectiveTheme {
    final profile = visualProfile;
    return isAutomaticLook && profile != null ? profile.primaryTheme : theme;
  }

  Trip copyWith({
    String? title,
    ExperienceTheme? theme,
    ThemeSource? themeSource,
    LocalDate? plannedStart,
    LocalDate? plannedEnd,
    TripDestination? destination,
    bool clearDestination = false,
    Set<String>? hiddenGaps,
    Map<String, ChecklistItem>? checklist,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id,
      title: title ?? this.title,
      theme: theme ?? this.theme,
      themeSource: themeSource ?? this.themeSource,
      visualProfile: visualProfile,
      unknownTheme: theme == null ? unknownTheme : null,
      plannedStart: plannedStart ?? this.plannedStart,
      plannedEnd: plannedEnd ?? this.plannedEnd,
      destination: clearDestination ? null : destination ?? this.destination,
      ownerId: ownerId,
      memberIds: memberIds,
      memberNames: memberNames,
      premium: premium,
      hiddenGaps: hiddenGaps ?? this.hiddenGaps,
      checklist: checklist ?? this.checklist,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// The theme as stored: its wire name, or an unknown newer name kept as is.
  String get _themeWireName => unknownTheme ?? theme.wireName;

  /// Fields the traveller can edit: the only ones sent when updating a trip.
  /// Never the visual profile, which only the server writes, and the theme
  /// only when the traveller picked it: an automatic trip's theme belongs
  /// to the classifier, and this phone's copy may be seconds old. Nor the
  /// checklist, which changes an item at a time.
  Map<String, Object?> toEditableJson() => {
    'title': title,
    if (themeSource == ThemeSource.manual) 'theme': _themeWireName,
    'themeSource': themeSource.wireName,
    'plannedStart': plannedStart?.toIso(),
    'plannedEnd': plannedEnd?.toIso(),
    'destination': destination?.toJson(),
    'hiddenGaps': [...hiddenGaps]..sort(),
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  /// Everything the app writes when it creates a trip. Members, names,
  /// invites and premium are absent: only the server sets those.
  Map<String, Object?> toJson() => {
    'title': title,
    'theme': _themeWireName,
    'themeSource': themeSource.wireName,
    'plannedStart': plannedStart?.toIso(),
    'plannedEnd': plannedEnd?.toIso(),
    'destination': ?destination?.toJson(),
    if (hiddenGaps.isNotEmpty) 'hiddenGaps': [...hiddenGaps]..sort(),
    if (checklist.isNotEmpty) 'checklist': {for (final item in checklist.values) item.id: item.toJson()},
    'ownerId': ownerId,
    'memberIds': memberIds,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory Trip.fromJson(String id, Map<String, Object?> json) {
    final storedTheme = json['theme'];
    final known = ExperienceTheme.tryParse(storedTheme);
    return Trip(
      id: id,
      title: json['title'] as String? ?? 'Trip',
      theme: known ?? ExperienceTheme.classicTravel,
      themeSource: ThemeSource.tryParse(json['themeSource']) ?? ThemeSource.inferFor(storedTheme),
      visualProfile: TripVisualProfile.tryParse(json['visualProfile']),
      unknownTheme: known == null && storedTheme is String && _isThemeName(storedTheme) ? storedTheme : null,
      plannedStart: LocalDate.tryParse(json['plannedStart']),
      plannedEnd: LocalDate.tryParse(json['plannedEnd']),
      destination: TripDestination.tryParse(json['destination']),
      ownerId: json['ownerId'] as String? ?? '',
      memberIds: [for (final m in json['memberIds'] as List? ?? const []) '$m'],
      memberNames: {
        for (final entry in (json['memberNames'] as Map? ?? const {}).entries) '${entry.key}': '${entry.value}',
      },
      premium: TripPremium.fromJson(json['premium']),
      hiddenGaps: {
        for (final gap in json['hiddenGaps'] as List? ?? const [])
          if (gap is String && gap.length <= 40) gap,
      },
      checklist: {
        for (final entry in (json['checklist'] is Map ? json['checklist'] as Map : const {}).entries)
          if (ChecklistItem.tryParse('${entry.key}', entry.value) case final item?) item.id: item,
      },
      createdAt: _millis(json['createdAt']),
      updatedAt: _millis(json['updatedAt']),
    );
  }

  @override
  String toString() => 'Trip($id, $title)';
}

/// A plausible theme name worth keeping ("desert_oasis"), not junk.
bool _isThemeName(String value) => RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(value);

DateTime _millis(Object? value) => value is num ? DateTime.fromMillisecondsSinceEpoch(value.toInt()) : DateTime.now();

/// Where a trip goes, as the traveller chose it: a country, or a region or
/// city in one. Written by the app ("Where to?"); the art rules trust it
/// like a verified place, since the traveller confirmed it.
class TripDestination {
  const TripDestination({
    required this.countryCode,
    required this.countryName,
    this.region,
    this.regionSlug,
    this.city,
    this.citySlug,
  });

  /// ISO 3166-1 alpha-2, upper case.
  final String countryCode;
  final String countryName;
  final String? region;

  /// [region] as an art-pack selector ("lake_district").
  final String? regionSlug;
  final String? city;

  /// [city] as an art-pack selector ("kyoto").
  final String? citySlug;

  /// The place itself: "Kyoto", "Lake District", "Japan".
  String get name => city ?? region ?? countryName;

  /// With its country: "Kyoto, Japan", "Japan".
  String get label => city == null && region == null ? countryName : '$name, $countryName';

  /// As a location the art rules read.
  TripLocationHint get location => TripLocationHint(
    countryCode: countryCode,
    countryName: countryName,
    region: region,
    regionSlug: regionSlug,
    city: city,
    citySlug: citySlug,
    confidence: 1,
    verification: LocationVerification.verified,
  );

  Map<String, Object?> toJson() => {
    'countryCode': countryCode,
    'countryName': countryName,
    'region': ?region,
    'regionSlug': ?regionSlug,
    'city': ?city,
    'citySlug': ?citySlug,
  };

  /// Null unless [json] names a real country.
  static TripDestination? tryParse(Object? json) {
    if (json is! Map) return null;
    String? text(String key) {
      final value = json[key];
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty || trimmed.length > 120 ? null : trimmed;
    }

    String? slug(String key) => isSlug(json[key]) ? json[key] as String : null;
    final country = text('countryCode')?.toUpperCase();
    final countryName = text('countryName');
    if (country == null || !isoCountryCodes.contains(country) || countryName == null) return null;
    return TripDestination(
      countryCode: country,
      countryName: countryName,
      region: text('region'),
      regionSlug: slug('regionSlug'),
      city: text('city'),
      citySlug: slug('citySlug'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TripDestination &&
      other.countryCode == countryCode &&
      other.countryName == countryName &&
      other.region == region &&
      other.regionSlug == regionSlug &&
      other.city == city &&
      other.citySlug == citySlug;

  @override
  int get hashCode => Object.hash(countryCode, countryName, region, regionSlug, city, citySlug);

  @override
  String toString() => 'TripDestination($label)';
}
