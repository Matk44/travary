import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/domain.dart';

/// Keeps ticket and document files inside the app, so they open offline.
///
/// Files are copied into `<app documents>/attachments/`. Cloud backup of
/// these files is a Travary Plus feature (not built yet).
class AttachmentStore {
  AttachmentStore._(this._directory);

  static Future<AttachmentStore> open() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'attachments'));
    await directory.create(recursive: true);
    return AttachmentStore._(directory);
  }

  /// A store in a custom folder (tests).
  AttachmentStore.at(Directory directory) : _directory = directory;

  final Directory _directory;
  final _random = Random();

  File fileFor(Attachment attachment) =>
      File(p.join(_directory.path, attachment.fileName));

  /// Copies the file at [sourcePath] into the store.
  Future<Attachment> import(String sourcePath, {String? name}) async {
    final source = File(sourcePath);
    final extension = p.extension(sourcePath).toLowerCase();
    final id = '${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(1 << 20)}';
    final fileName = '$id$extension';
    final copy = await source.copy(p.join(_directory.path, fileName));
    return Attachment(
      id: id,
      name: name ?? p.basename(sourcePath),
      fileName: fileName,
      sizeBytes: await copy.length(),
    );
  }

  Future<void> delete(Attachment attachment) async {
    final file = fileFor(attachment);
    if (await file.exists()) await file.delete();
  }
}
