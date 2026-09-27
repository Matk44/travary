import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../domain/domain.dart';

/// Copies ticket files to cloud storage and back, so they survive a lost
/// phone and reach every family member on a shared trip.
abstract interface class AttachmentBackup {
  /// Uploads [file] for [attachment] on [tripId]; returns its cloud path.
  Future<String> upload(String tripId, Attachment attachment, File file);

  /// Downloads the cloud copy of [attachment] into [target].
  Future<void> download(Attachment attachment, File target);

  /// Removes the cloud copy of [attachment].
  Future<void> delete(Attachment attachment);
}

/// Firebase Storage: `trips/{tripId}/attachments/{fileName}`, readable by the
/// trip's members only (see storage.rules).
class FirebaseAttachmentBackup implements AttachmentBackup {
  FirebaseAttachmentBackup({required this.ensureSignedIn, FirebaseStorage? storage}) : _storage = storage;

  final Future<void> Function() ensureSignedIn;
  final FirebaseStorage? _storage;

  FirebaseStorage get _bucket => _storage ?? FirebaseStorage.instance;

  @override
  Future<String> upload(String tripId, Attachment attachment, File file) async {
    await ensureSignedIn();
    final path = 'trips/$tripId/attachments/${attachment.fileName}';
    await _bucket.ref(path).putFile(file, SettableMetadata(contentType: _contentType(attachment)));
    return path;
  }

  @override
  Future<void> download(Attachment attachment, File target) async {
    final path = attachment.remotePath;
    if (path == null) throw StateError('Nothing to download for ${attachment.id}');
    await ensureSignedIn();
    await target.parent.create(recursive: true);
    await _bucket.ref(path).writeToFile(target);
  }

  @override
  Future<void> delete(Attachment attachment) async {
    final path = attachment.remotePath;
    if (path == null) return;
    await ensureSignedIn();
    await _bucket.ref(path).delete();
  }

  String _contentType(Attachment attachment) => switch (attachment.extension) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'gif' => 'image/gif',
    _ => 'image/jpeg',
  };
}
