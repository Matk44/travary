import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/shared_files.dart';
import 'analytics.dart';

/// A file shared into Travary, waiting for the home screen to read it
/// (after onboarding, if that's still going). The newest share wins.
class ShareInbox extends ChangeNotifier {
  ShareInbox(this._files);

  final SharedFiles? _files;
  SharedFile? _waiting;
  StreamSubscription<SharedFile>? _incoming;
  bool _disposed = false;

  bool get hasWaiting => _waiting != null;

  Future<void> start() async {
    final files = _files;
    if (files == null) return;
    _incoming = files.incoming.listen(_received);
    if (await files.takeInitial() case final file?) _received(file);
  }

  void _received(SharedFile file) {
    if (_disposed) return;
    track('file_shared_in', {'pdf': file.name.toLowerCase().endsWith('.pdf')});
    _waiting = file;
    notifyListeners();
  }

  /// The waiting file, once.
  SharedFile? take() {
    final file = _waiting;
    _waiting = null;
    return file;
  }

  /// [file] has been read or kept: its shared copy can go.
  Future<void> done(SharedFile file) async => _files?.done(file);

  @override
  void dispose() {
    _disposed = true;
    unawaited(_incoming?.cancel());
    super.dispose();
  }
}
