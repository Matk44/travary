import 'booking_kind.dart';
import 'local_date.dart';

/// A single thing the traveller has booked (or wants reminding about).
///
/// Times are floating local times (see [LocalDate]). A booking without a
/// [startTime] is "all day". A booking whose [endDate] is after its
/// [startDate] (a hotel stay, a car hire) spans several days.
class Booking {
  const Booking({
    required this.id,
    required this.tripId,
    required this.kind,
    required this.title,
    required this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.location,
    this.reference,
    this.notes,
    this.details = const {},
    this.attachments = const [],
    this.artKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tripId;
  final BookingKind kind;
  final String title;
  final LocalDate startDate;
  final ClockTime? startTime;

  /// Null means "same day as [startDate]" (or no end at all).
  final LocalDate? endDate;
  final ClockTime? endTime;
  final String? location;

  /// Booking reference / confirmation code.
  final String? reference;
  final String? notes;

  /// Kind-specific extras keyed by [DetailKeys].
  final Map<String, String> details;
  final List<Attachment> attachments;

  /// Artwork the traveller picked for this card. Null lets the app choose.
  final String? artKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAllDay => startTime == null;
  bool get hasEnd => endDate != null || endTime != null;
  LocalDate get lastDate => endDate ?? startDate;
  bool get spansDays => lastDate.isAfter(startDate);
  bool get hasTickets => attachments.isNotEmpty;

  DateTime get startsAt => startDate.toDateTime(startTime);

  /// The end as a wall-clock moment, or null when there is no end.
  DateTime? get endsAt {
    if (!hasEnd) return null;
    if (endTime == null) return lastDate.addDays(1).toDateTime();
    return lastDate.toDateTime(endTime);
  }

  /// A trimmed, non-empty detail value, or null.
  String? detail(String key) {
    final value = details[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Booking copyWith({
    String? tripId,
    List<Attachment>? attachments,
    String? artKey,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id,
      tripId: tripId ?? this.tripId,
      kind: kind,
      title: title,
      startDate: startDate,
      startTime: startTime,
      endDate: endDate,
      endTime: endTime,
      location: location,
      reference: reference,
      notes: notes,
      details: details,
      attachments: attachments ?? this.attachments,
      artKey: artKey ?? this.artKey,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'tripId': tripId,
    'kind': kind.name,
    'title': title,
    'startDate': startDate.toIso(),
    'startTime': startTime?.toIso(),
    'endDate': endDate?.toIso(),
    'endTime': endTime?.toIso(),
    'location': location,
    'reference': reference,
    'notes': notes,
    'details': details,
    'attachments': [for (final a in attachments) a.toJson()],
    'artKey': artKey,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory Booking.fromJson(String id, Map<String, Object?> json) {
    final created = _dateFromMillis(json['createdAt']);
    return Booking(
      id: id,
      tripId: json['tripId'] as String? ?? '',
      kind: BookingKind.fromName(json['kind'] as String?),
      title: json['title'] as String? ?? '',
      startDate:
          LocalDate.tryParse(json['startDate']) ??
          LocalDate.fromDateTime(created),
      startTime: ClockTime.tryParse(json['startTime']),
      endDate: LocalDate.tryParse(json['endDate']),
      endTime: ClockTime.tryParse(json['endTime']),
      location: json['location'] as String?,
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      details: {
        for (final entry in (json['details'] as Map? ?? const {}).entries)
          '${entry.key}': '${entry.value}',
      },
      attachments: [
        for (final item in json['attachments'] as List? ?? const [])
          if (item is Map) Attachment.fromJson(Map<String, Object?>.from(item)),
      ],
      artKey: json['artKey'] as String?,
      createdAt: created,
      updatedAt: _dateFromMillis(json['updatedAt']),
    );
  }

  @override
  String toString() => 'Booking($id, ${kind.name}, $title, $startDate)';
}

/// A ticket, confirmation or document attached to a booking.
///
/// Files live in the app's own documents folder. Only the file name is
/// stored, never an absolute path: iOS moves the app container between
/// installs, which breaks absolute paths.
class Attachment {
  const Attachment({
    required this.id,
    required this.name,
    required this.fileName,
    required this.sizeBytes,
  });

  final String id;

  /// Name shown to the traveller, e.g. "Park tickets.pdf".
  final String name;

  /// File name inside the attachments folder.
  final String fileName;
  final int sizeBytes;

  String get extension {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  bool get isImage =>
      const {'jpg', 'jpeg', 'png', 'heic', 'webp', 'gif'}.contains(extension);
  bool get isPdf => extension == 'pdf';

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'fileName': fileName,
    'sizeBytes': sizeBytes,
  };

  factory Attachment.fromJson(Map<String, Object?> json) => Attachment(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Document',
    fileName: json['fileName'] as String? ?? '',
    sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
  );
}

DateTime _dateFromMillis(Object? value) => value is num
    ? DateTime.fromMillisecondsSinceEpoch(value.toInt())
    : DateTime.now();
