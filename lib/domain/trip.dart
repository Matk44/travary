import 'local_date.dart';
import 'premium.dart';

/// The visual mood of a trip. Picks which artwork set the cards use, so the
/// same "dinner" card looks tropical in Orlando and snowy in Zermatt.
enum TripTheme {
  classic('Classic'),
  tropical('Tropical'),
  city('City'),
  snow('Snow'),
  countryside('Countryside'),
  themepark('Theme park');

  const TripTheme(this.label);

  final String label;

  static TripTheme fromName(String? name) =>
      values.firstWhere((t) => t.name == name, orElse: () => classic);
}

/// A holiday: a named group of bookings.
///
/// Trips are formed automatically as bookings are added, so dates are
/// normally derived from the bookings. [plannedStart]/[plannedEnd] only
/// matter for a trip created before anything was booked.
class Trip {
  const Trip({
    required this.id,
    required this.title,
    this.theme = TripTheme.classic,
    this.plannedStart,
    this.plannedEnd,
    required this.ownerId,
    required this.memberIds,
    this.premium,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final TripTheme theme;
  final LocalDate? plannedStart;
  final LocalDate? plannedEnd;

  /// Who created the trip. Only they can delete it.
  final String ownerId;

  /// Everyone who can see the trip (the owner plus invited family).
  final List<String> memberIds;

  /// Plus unlocked for everyone on the trip. Set by the server only.
  final TripPremium? premium;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip copyWith({
    String? title,
    TripTheme? theme,
    LocalDate? plannedStart,
    LocalDate? plannedEnd,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id,
      title: title ?? this.title,
      theme: theme ?? this.theme,
      plannedStart: plannedStart ?? this.plannedStart,
      plannedEnd: plannedEnd ?? this.plannedEnd,
      ownerId: ownerId,
      memberIds: memberIds,
      premium: premium,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Fields the app writes. `premium` is deliberately absent: only the
  /// server sets it, and writes are merged so it survives app updates.
  Map<String, Object?> toJson() => {
    'title': title,
    'theme': theme.name,
    'plannedStart': plannedStart?.toIso(),
    'plannedEnd': plannedEnd?.toIso(),
    'ownerId': ownerId,
    'memberIds': memberIds,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory Trip.fromJson(String id, Map<String, Object?> json) => Trip(
    id: id,
    title: json['title'] as String? ?? 'Trip',
    theme: TripTheme.fromName(json['theme'] as String?),
    plannedStart: LocalDate.tryParse(json['plannedStart']),
    plannedEnd: LocalDate.tryParse(json['plannedEnd']),
    ownerId: json['ownerId'] as String? ?? '',
    memberIds: [for (final m in json['memberIds'] as List? ?? const []) '$m'],
    premium: TripPremium.fromJson(json['premium']),
    createdAt: _millis(json['createdAt']),
    updatedAt: _millis(json['updatedAt']),
  );

  @override
  String toString() => 'Trip($id, $title)';
}

DateTime _millis(Object? value) => value is num
    ? DateTime.fromMillisecondsSinceEpoch(value.toInt())
    : DateTime.now();
