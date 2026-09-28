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
    required this.ownerId,
    required this.memberIds,
    this.memberNames = const {},
    this.premium,
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

  /// Who created the trip. Only they can delete it.
  final String ownerId;

  /// Everyone who can see the trip (the owner plus invited family).
  final List<String> memberIds;

  /// What each member is called ("Alex"), set when they invite or join.
  /// Server-written only.
  final Map<String, String> memberNames;

  /// Plus unlocked for everyone on the trip. Set by the server only.
  final TripPremium? premium;

  bool get isShared => memberIds.length > 1;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAutomaticLook => themeSource == ThemeSource.auto;

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
      ownerId: ownerId,
      memberIds: memberIds,
      memberNames: memberNames,
      premium: premium,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// The theme as stored: its wire name, or an unknown newer name kept as is.
  String get _themeWireName => unknownTheme ?? theme.wireName;

  /// Fields the traveller can edit: the only ones sent when updating a trip.
  /// Never the visual profile, which only the server writes, and the theme
  /// only when the traveller picked it: an automatic trip's theme belongs
  /// to the classifier, and this phone's copy may be seconds old.
  Map<String, Object?> toEditableJson() => {
    'title': title,
    if (themeSource == ThemeSource.manual) 'theme': _themeWireName,
    'themeSource': themeSource.wireName,
    'plannedStart': plannedStart?.toIso(),
    'plannedEnd': plannedEnd?.toIso(),
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
      ownerId: json['ownerId'] as String? ?? '',
      memberIds: [for (final m in json['memberIds'] as List? ?? const []) '$m'],
      memberNames: {
        for (final entry in (json['memberNames'] as Map? ?? const {}).entries) '${entry.key}': '${entry.value}',
      },
      premium: TripPremium.fromJson(json['premium']),
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
