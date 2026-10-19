import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/domain.dart';
import '../logic/photo_shrink.dart';
import 'photo_shrinker.dart';

/// Keeps ticket and document files inside the app, so they open offline.
///
/// Files are copied into `<app documents>/attachments/`, camera photos
/// shrunk on the way in. That one file is what opens on the phone, what
/// shared and paid trips back up (`TravelStore.syncTickets`) and what the
/// family's phones download.
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

  File fileFor(Attachment attachment) => File(p.join(_directory.path, attachment.fileName));

  /// Copies the file at [sourcePath] into the store. A camera photo is
  /// shrunk once, here (`logic/photo_shrink.dart`): a HEIC becomes a JPEG,
  /// name and all. Anything else, and a photo that can't be shrunk, comes
  /// in byte for byte.
  Future<Attachment> import(String sourcePath, {String? name}) async {
    final source = File(sourcePath);
    final shrunk = await _shrunk(source);
    final extension = p.extension(sourcePath).toLowerCase();
    final id = '${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(1 << 20)}';
    final shown = name ?? p.basename(sourcePath);
    if (shrunk == null) {
      final fileName = '$id$extension';
      final copy = await source.copy(p.join(_directory.path, fileName));
      return Attachment(id: id, name: shown, fileName: fileName, sizeBytes: await copy.length());
    }
    final fileName = '$id${shrunkExtension(shrunk.photo, extension)}';
    final copy = await File(p.join(_directory.path, fileName)).writeAsBytes(shrunk.bytes, flush: true);
    return Attachment(id: id, name: shrunkPhotoName(shown), fileName: fileName, sizeBytes: await copy.length());
  }

  /// The last photo shrunk, by the file it came from: Smart Import keeps
  /// one file on each booking it reads, and each takes this copy rather
  /// than shrinking it again (the same bytes, so it still counts once).
  ({String from, CameraPhoto photo, Uint8List bytes})? _lastShrunk;

  /// [source] shrunk, if it's a camera photo that's shrunk; null keeps the
  /// original, as when shrinking fails: a file is never lost to it.
  Future<({CameraPhoto photo, Uint8List bytes})?> _shrunk(File source) async {
    if (!mayBeCameraPhoto(source.path)) return null;
    try {
      final stat = await source.stat();
      final from = '${source.path} ${stat.size} ${stat.modified.microsecondsSinceEpoch}';
      if (_lastShrunk case final last? when last.from == from) return (photo: last.photo, bytes: last.bytes);
      final bytes = await source.readAsBytes();
      final photo = cameraPhotoOf(source.path, bytes);
      if (photo == null) return null;
      final size = photo == CameraPhoto.jpeg ? jpegSizeOf(bytes) : null;
      if (!shrinksPhoto(photo, sizeBytes: bytes.length, size: size)) return null;
      final jpeg = await shrinkPhoto(bytes, photo);
      if (jpeg == null) return null;
      _lastShrunk = (from: from, photo: photo, bytes: jpeg);
      return (photo: photo, bytes: jpeg);
    } catch (error) {
      if (kDebugMode) debugPrint('Photo kept as it came: $error');
      return null;
    }
  }

  Future<void> delete(Attachment attachment) async {
    final file = fileFor(attachment);
    if (await file.exists()) await file.delete();
  }
}
