import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/domain.dart';
import 'document_lock.dart';
import 'travel_document_repository.dart';

/// Documents kept in memory (tests and design tools). Files stay where
/// they were picked from.
class MemoryTravelDocumentRepository implements TravelDocumentRepository {
  MemoryTravelDocumentRepository([List<TravelDocument> documents = const []]) : _documents = [...documents];

  List<TravelDocument> _documents;
  final _paths = <String, String>{};
  var _next = 0;

  /// What was last saved.
  List<TravelDocument> get saved => List.unmodifiable(_documents);

  /// Files deleted so far, by ID.
  final deletedFiles = <String>[];

  @override
  Future<List<TravelDocument>> load() async => [..._documents];

  @override
  Future<void> saveAll(List<TravelDocument> documents) async => _documents = [...documents];

  @override
  Future<DocumentFile> importFile(String sourcePath, {String? name}) async {
    final id = 'file${_next++}';
    final fileName = '$id${p.extension(sourcePath).toLowerCase()}';
    _paths[fileName] = sourcePath;
    final source = File(sourcePath);
    return DocumentFile(
      id: id,
      name: name ?? p.basename(sourcePath),
      fileName: fileName,
      sizeBytes: source.existsSync() ? source.lengthSync() : 0,
    );
  }

  @override
  File fileFor(DocumentFile file) => File(_paths[file.fileName] ?? file.fileName);

  @override
  Future<void> deleteFile(DocumentFile file) async => deletedFiles.add(file.id);
}

/// A lock that always opens with [result] (tests and design tools).
class FixedDocumentLock implements DocumentLock {
  FixedDocumentLock([this.result = UnlockResult.unlocked]);

  UnlockResult result;
  var asked = 0;

  @override
  Future<UnlockResult> unlock() async {
    asked++;
    return result;
  }
}
