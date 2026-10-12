import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// A booking's screenshot, photo or PDF shared into Travary.
typedef SharedFile = ({String path, String name});

/// Files shared into Travary from other apps: the share sheet on iPhone
/// (`ios/ShareExtension`) and Android. Only what a booking can be read
/// from: PDFs and images.
abstract interface class SharedFiles {
  /// One shared before the app opened (it opened the app), once.
  Future<SharedFile?> takeInitial();

  /// Ones shared while the app was running.
  Stream<SharedFile> get incoming;

  /// [file] has been read or kept: its copy can go.
  Future<void> done(SharedFile file);
}

/// The file types a booking can be read from.
const sharedFileExtensions = {'.pdf', '.png', '.jpg', '.jpeg', '.heic', '.heif', '.webp', '.gif'};

/// The first file in [paths] a booking can be read from, if any.
SharedFile? firstBookingFile(Iterable<String> paths) {
  for (final path in paths) {
    final clean = path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
    if (sharedFileExtensions.contains(p.extension(clean).toLowerCase())) {
      return (path: clean, name: p.basename(clean));
    }
  }
  return null;
}

/// receive_sharing_intent.
class PluginSharedFiles implements SharedFiles {
  ReceiveSharingIntent get _plugin => ReceiveSharingIntent.instance;

  static SharedFile? _pick(List<SharedMediaFile> media) => firstBookingFile([
    for (final file in media)
      if (file.type == SharedMediaType.file || file.type == SharedMediaType.image) file.path,
  ]);

  @override
  Future<SharedFile?> takeInitial() async {
    try {
      final file = _pick(await _plugin.getInitialMedia());
      await _plugin.reset();
      return file;
    } catch (error) {
      if (kDebugMode) debugPrint('No shared file at launch: $error');
      return null;
    }
  }

  @override
  Stream<SharedFile> get incoming =>
      _plugin.getMediaStream().map(_pick).where((file) => file != null).cast<SharedFile>().handleError((Object error) {
        if (kDebugMode) debugPrint('Shared file not received: $error');
      });

  @override
  Future<void> done(SharedFile file) async {
    try {
      await _plugin.reset();
      // Only the copy the share left for us (iOS: its own folder under the
      // app group's Shared; Android: the cache); never a file elsewhere.
      final copy = File(file.path);
      if (p.basename(p.dirname(p.dirname(copy.path))) == 'Shared') {
        await copy.parent.delete(recursive: true);
      } else if (copy.path.contains('/cache/') && await copy.exists()) {
        await copy.delete();
      }
    } catch (_) {
      // A leftover copy is harmless.
    }
  }
}

/// Tests: hands out what it's given.
class MemorySharedFiles implements SharedFiles {
  SharedFile? initial;
  final finished = <SharedFile>[];
  final _incoming = StreamController<SharedFile>.broadcast();

  void share(SharedFile file) => _incoming.add(file);

  @override
  Future<SharedFile?> takeInitial() async {
    final file = initial;
    initial = null;
    return file;
  }

  @override
  Stream<SharedFile> get incoming => _incoming.stream;

  @override
  Future<void> done(SharedFile file) async => finished.add(file);
}
