import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/ai_consent.dart';

/// The answer to "May I ask Google's AI?" on this phone, whoever is signed
/// in.
abstract interface class AiConsentRecord {
  Future<AiConsent> load();
  Future<void> save(AiConsent consent);
}

class LocalAiConsentRecord implements AiConsentRecord {
  LocalAiConsentRecord({Directory? directory}) : _directory = directory;
  Directory? _directory;

  Future<File> _file() async {
    final directory = _directory ??= Directory(p.join((await getApplicationSupportDirectory()).path, 'ai'));
    return File(p.join(directory.path, 'consent.json'));
  }

  @override
  Future<AiConsent> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return AiConsent.undecided;
      final json = jsonDecode(await file.readAsString());
      return AiConsent.parse(json is Map ? json['consent'] : null);
    } catch (_) {
      // Unreadable: asked again, and nothing is sent until then.
      return AiConsent.undecided;
    }
  }

  @override
  Future<void> save(AiConsent consent) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'consent': consent.name}), flush: true);
    } catch (_) {
      // Not saved: at worst it's asked again.
    }
  }
}

class MemoryAiConsentRecord implements AiConsentRecord {
  MemoryAiConsentRecord([this.consent = AiConsent.undecided]);
  AiConsent consent;

  @override
  Future<AiConsent> load() async => consent;

  @override
  Future<void> save(AiConsent consent) async => this.consent = consent;
}
