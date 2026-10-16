import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// The home-screen countdown widget's side of the phone
/// (`logic/countdown_widget.dart`): the folder it reads and asking the
/// phone to draw it again. Everything in the folder is written from Dart.
abstract interface class CountdownWidgetBridge {
  /// Where the widget reads its files: on iOS a folder in the App Group
  /// container shared with the widget extension, on Android one in the
  /// app's own files. Null if the phone has none (no App Group).
  Future<CountdownWidgetFolder?> folder();

  /// Asks the phone to draw every Travary widget again from the folder.
  Future<void> reload();
}

/// The native side: `ios/Runner/CountdownWidgetChannel.swift` and
/// `android/.../widget/CountdownWidgetChannel.kt`.
class PlatformCountdownWidgetBridge implements CountdownWidgetBridge {
  static const _channel = MethodChannel('travary/countdown_widget');

  @override
  Future<CountdownWidgetFolder?> folder() async {
    final path = await _channel.invokeMethod<String>('folder');
    if (path == null) return null;
    final directory = Directory(path);
    await directory.create(recursive: true);
    return CountdownWidgetFolder(directory);
  }

  @override
  Future<void> reload() => _channel.invokeMethod<void>('reload');
}

/// The widget's folder: `countdown.json` and the pictures and fonts it
/// names. Files are named by their contents, so a picture that changes
/// (a pack updated) gets a new name and the widget never draws a stale
/// one, and one that doesn't is written once.
class CountdownWidgetFolder {
  CountdownWidgetFolder(this.root);

  final Directory root;

  static const jsonName = 'countdown.json';

  /// The folders [put] writes into; [prune] tidies only these.
  static const managed = ['art', 'travi', 'fonts'];

  /// Copies [bytes] into [folder] (one of [managed]) as `<sha1>.<ext>`
  /// unless it's already there, and returns its name relative to [root].
  Future<String> put(String folder, List<int> bytes, {required String extension}) async {
    assert(managed.contains(folder));
    final name = '$folder/${sha1.convert(bytes)}$extension';
    final file = File(p.join(root.path, name));
    if (!file.existsSync()) {
      await file.parent.create(recursive: true);
      await _writeAtomically(file, bytes);
    }
    return name;
  }

  /// Writes the widget's file whole, so the widget never reads half of it.
  Future<void> writeJson(Map<String, Object?> json) =>
      _writeAtomically(File(p.join(root.path, jsonName)), utf8.encode(jsonEncode(json)));

  /// Deletes what the last [writeJson] no longer names ([keep]: names
  /// relative to [root]).
  Future<void> prune(Set<String> keep) async {
    for (final folder in managed) {
      final directory = Directory(p.join(root.path, folder));
      if (!directory.existsSync()) continue;
      await for (final entity in directory.list()) {
        final name = '$folder/${p.basename(entity.path)}';
        if (entity is File && !keep.contains(name)) {
          try {
            await entity.delete();
          } on FileSystemException catch (error) {
            if (kDebugMode) debugPrint('Countdown widget: $name not deleted: $error');
          }
        }
      }
    }
  }

  Future<void> _writeAtomically(File file, List<int> bytes) async {
    final temporary = File('${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(file.path);
  }
}
