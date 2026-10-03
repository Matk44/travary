import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travary/data/travel_document_repository.dart';
import 'package:travary/domain/domain.dart';

void main() {
  late Directory temp;
  late LocalTravelDocumentRepository repository;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('travel_documents_');
    repository = LocalTravelDocumentRepository.at(Directory(p.join(temp.path, 'travel_documents')));
  });

  tearDown(() => temp.deleteSync(recursive: true));

  TravelDocument passport(List<DocumentFile> files) => TravelDocument(
    id: 'p1',
    type: TravelDocumentType.passport,
    holder: 'Sam',
    number: '533120784',
    expiresOn: LocalDate(2031, 3, 12),
    files: files,
    createdAt: DateTime(2026, 10, 3),
    updatedAt: DateTime(2026, 10, 3),
  );

  test('nothing saved yet: no documents', () async {
    expect(await repository.load(), isEmpty);
  });

  test('documents and their files are kept on the phone and come back the same', () async {
    final source = File(p.join(temp.path, 'photo page.JPG'))..writeAsBytesSync([1, 2, 3]);
    final file = await repository.importFile(source.path, name: 'Photo page.jpg');
    expect(file.fileName, endsWith('.jpg'));
    expect(file.sizeBytes, 3);
    expect(repository.fileFor(file).readAsBytesSync(), [1, 2, 3]);
    expect(p.isWithin(temp.path, repository.fileFor(file).path), isTrue);

    await repository.saveAll([
      passport([file]),
    ]);
    final loaded = await repository.load();
    expect(loaded.single.toJson(), passport([file]).toJson());
    // Written whole, then swapped in: no temporary file is left behind.
    expect(File(p.join(temp.path, 'travel_documents', 'documents.json.tmp')).existsSync(), isFalse);

    await repository.deleteFile(file);
    expect(repository.fileFor(file).existsSync(), isFalse);
  });

  test('a damaged list reads as empty rather than crashing', () async {
    await repository.saveAll([passport(const [])]);
    File(p.join(temp.path, 'travel_documents', 'documents.json')).writeAsStringSync('{not json');
    expect(await repository.load(), isEmpty);
  });
}
