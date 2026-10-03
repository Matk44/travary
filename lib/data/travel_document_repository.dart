import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/domain.dart';

/// Where travel documents live: on this phone only.
///
/// Deliberately separate from bookings and their tickets: nothing here is
/// ever written to Firestore or Cloud Storage, sent to Smart Import,
/// shared with a trip's family or logged. The phone's own encrypted backup
/// (iCloud, Google) is the only copy elsewhere.
abstract class TravelDocumentRepository {
  Future<List<TravelDocument>> load();
  Future<void> saveAll(List<TravelDocument> documents);

  /// Copies the file at [sourcePath] in, returning how it's kept.
  Future<DocumentFile> importFile(String sourcePath, {String? name});
  File fileFor(DocumentFile file);
  Future<void> deleteFile(DocumentFile file);
}

/// The documents and their files in the app's private support folder
/// (`travel_documents/`): not the Documents folder, which iOS can show in
/// the Files app. iOS and Android encrypt it while the phone is locked.
class LocalTravelDocumentRepository implements TravelDocumentRepository {
  LocalTravelDocumentRepository.at(this._directory) : _files = Directory(p.join(_directory.path, 'files'));

  static Future<LocalTravelDocumentRepository> open() async {
    final support = await getApplicationSupportDirectory();
    final repository = LocalTravelDocumentRepository.at(Directory(p.join(support.path, 'travel_documents')));
    await repository._files.create(recursive: true);
    return repository;
  }

  final Directory _directory;
  final Directory _files;
  final _random = Random.secure();

  File get _index => File(p.join(_directory.path, 'documents.json'));

  @override
  Future<List<TravelDocument>> load() async {
    if (!await _index.exists()) return const [];
    try {
      final json = jsonDecode(await _index.readAsString());
      return [
        for (final item in (json as Map)['documents'] as List? ?? const [])
          if (TravelDocument.tryParse(item) case final document?) document,
      ];
    } on FormatException {
      return const [];
    }
  }

  /// Writes a new copy, then swaps it in: a crash mid-write never loses
  /// the documents already saved.
  @override
  Future<void> saveAll(List<TravelDocument> documents) async {
    await _directory.create(recursive: true);
    final temp = File('${_index.path}.tmp');
    await temp.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'documents': [for (final document in documents) document.toJson()],
      }),
      flush: true,
    );
    await temp.rename(_index.path);
  }

  @override
  Future<DocumentFile> importFile(String sourcePath, {String? name}) async {
    await _files.create(recursive: true);
    final id = List.generate(16, (_) => _random.nextInt(16).toRadixString(16)).join();
    final fileName = '$id${p.extension(sourcePath).toLowerCase()}';
    final copy = await File(sourcePath).copy(p.join(_files.path, fileName));
    return DocumentFile(
      id: id,
      name: name ?? p.basename(sourcePath),
      fileName: fileName,
      sizeBytes: await copy.length(),
    );
  }

  @override
  File fileFor(DocumentFile file) => File(p.join(_files.path, file.fileName));

  @override
  Future<void> deleteFile(DocumentFile file) async {
    final stored = fileFor(file);
    if (await stored.exists()) await stored.delete();
  }
}
