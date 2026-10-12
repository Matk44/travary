import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Holiday Passes the store has charged for but the server hasn't recorded
/// yet (`claimTripPass`), for one account on this phone: store transaction
/// → trip. Kept on disk so a pass bought offline, or while the server was
/// busy, is claimed when the app next opens instead of being forgotten when
/// it closes. Only IDs are kept.
abstract interface class PendingPassClaims {
  Future<Map<String, String>> load();
  Future<void> save(Map<String, String> claims);
}

class LocalPendingPassClaims implements PendingPassClaims {
  LocalPendingPassClaims({required this.userId, Directory? directory}) : _directory = directory;

  final String userId;
  Directory? _directory;

  Future<File> _file() async {
    final directory = _directory ??= Directory(p.join((await getApplicationSupportDirectory()).path, 'purchases'));
    final safe = userId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File(p.join(directory.path, 'unclaimed_$safe.json'));
  }

  @override
  Future<Map<String, String>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return {};
      final json = jsonDecode(await file.readAsString());
      if (json is! Map) return {};
      return {
        for (final MapEntry(:key, :value) in json.entries)
          if (value is String && value.isNotEmpty) '$key': value,
      };
    } catch (_) {
      // Unreadable: Restore purchases still finds the pass on the server.
      return {};
    }
  }

  @override
  Future<void> save(Map<String, String> claims) async {
    try {
      final file = await _file();
      if (claims.isEmpty) {
        if (await file.exists()) await file.delete();
        return;
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(claims), flush: true);
    } catch (_) {
      // Not saved: it's still claimed while the app stays open.
    }
  }
}

class MemoryPendingPassClaims implements PendingPassClaims {
  MemoryPendingPassClaims([Map<String, String>? claims]) : claims = {...?claims};

  Map<String, String> claims;

  @override
  Future<Map<String, String>> load() async => {...claims};

  @override
  Future<void> save(Map<String, String> claims) async => this.claims = {...claims};
}
