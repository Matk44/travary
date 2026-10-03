import 'country_codes.dart';
import 'local_date.dart';

/// The kinds of personal travel document a traveller keeps.
enum TravelDocumentType {
  passport('Passport', 'Passport number'),
  visa('Visa or ESTA', 'Visa or application number'),
  insurance('Travel insurance', 'Policy number'),
  drivingLicence('Driving licence', 'Licence number'),
  idCard('ID card', 'Card number'),
  health('Health card', 'Card number'),
  other('Other document', 'Number');

  const TravelDocumentType(this.label, this.numberLabel);

  final String label;
  final String numberLabel;

  static TravelDocumentType fromName(Object? name) =>
      values.where((type) => type.name == name).firstOrNull ?? TravelDocumentType.other;
}

/// A file kept with a document: a photo of the page, or a PDF.
class DocumentFile {
  const DocumentFile({required this.id, required this.name, required this.fileName, required this.sizeBytes});

  final String id;

  /// Name shown to the traveller, e.g. "Passport photo page.jpg".
  final String name;

  /// File name inside the documents folder on this phone.
  final String fileName;
  final int sizeBytes;

  String get extension {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  bool get isImage => const {'jpg', 'jpeg', 'png', 'heic', 'webp', 'gif'}.contains(extension);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'fileName': fileName, 'sizeBytes': sizeBytes};

  static DocumentFile? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final fileName = json['fileName'];
    if (id is! String || fileName is! String || fileName.contains('/') || fileName.contains(r'\')) return null;
    final name = json['name'];
    final size = json['sizeBytes'];
    return DocumentFile(
      id: id,
      name: name is String ? name : fileName,
      fileName: fileName,
      sizeBytes: size is num ? size.toInt() : 0,
    );
  }
}

/// A passport, visa, insurance policy or other personal travel document.
///
/// Personal and sensitive: it belongs to a person, not a trip, and lives
/// only on this phone. It is never written to the cloud, sent to Smart
/// Import, shared with a trip's family or logged.
class TravelDocument {
  const TravelDocument({
    required this.id,
    required this.type,
    this.holder = '',
    this.title,
    this.number,
    this.issuedBy,
    this.expiresOn,
    this.notes,
    this.files = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final TravelDocumentType type;

  /// Whose it is ("Sam"). Empty for the phone's owner.
  final String holder;

  /// A name of the traveller's own ("ESTA (USA)"); else the type's label.
  final String? title;
  final String? number;

  /// The issuing country, ISO 3166-1 alpha-2.
  final String? issuedBy;
  final LocalDate? expiresOn;

  /// Anything else: an insurer's emergency number, what's covered.
  final String? notes;
  final List<DocumentFile> files;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get name => (title?.trim().isNotEmpty ?? false) ? title!.trim() : type.label;

  TravelDocument copyWith({
    TravelDocumentType? type,
    String? holder,
    String? title,
    String? number,
    String? issuedBy,
    LocalDate? expiresOn,
    String? notes,
    List<DocumentFile>? files,
    bool clearExpiry = false,
    bool clearIssuedBy = false,
    DateTime? updatedAt,
  }) => TravelDocument(
    id: id,
    type: type ?? this.type,
    holder: holder ?? this.holder,
    title: title ?? this.title,
    number: number ?? this.number,
    issuedBy: clearIssuedBy ? null : issuedBy ?? this.issuedBy,
    expiresOn: clearExpiry ? null : expiresOn ?? this.expiresOn,
    notes: notes ?? this.notes,
    files: files ?? this.files,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'holder': holder,
    'title': ?_blankToNull(title),
    'number': ?_blankToNull(number),
    'issuedBy': ?issuedBy,
    'expiresOn': ?expiresOn?.toIso(),
    'notes': ?_blankToNull(notes),
    'files': [for (final file in files) file.toJson()],
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  static TravelDocument? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    String? text(String key) => json[key] is String ? _blankToNull(json[key] as String) : null;
    final country = text('issuedBy')?.toUpperCase();
    return TravelDocument(
      id: id,
      type: TravelDocumentType.fromName(json['type']),
      holder: text('holder') ?? '',
      title: text('title'),
      number: text('number'),
      issuedBy: country != null && isoCountryCodes.contains(country) ? country : null,
      expiresOn: LocalDate.tryParse(json['expiresOn']),
      notes: text('notes'),
      files: [
        for (final file in json['files'] as List? ?? const [])
          if (DocumentFile.tryParse(file) case final parsed?) parsed,
      ],
      createdAt: _millis(json['createdAt']),
      updatedAt: _millis(json['updatedAt']),
    );
  }
}

String? _blankToNull(String? value) => value == null || value.trim().isEmpty ? null : value.trim();

DateTime _millis(Object? value) => value is num ? DateTime.fromMillisecondsSinceEpoch(value.toInt()) : DateTime(2026);
