import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/onboarding.dart';

abstract interface class OnboardingRepository {
  Future<OnboardingDraft> load();
  Future<void> save(OnboardingDraft draft);
}

/// Account-scoped, local setup only. No source documents, flight results or
/// credentials are stored here. Atomic replacement preserves the last draft.
class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository({required this.userId, Directory? directory}) : _directory = directory;
  final String userId;
  Directory? _directory;

  Future<File> _file() async {
    final directory = _directory ??= Directory(p.join((await getApplicationSupportDirectory()).path, 'onboarding'));
    return File(p.join(directory.path, '${Uri.encodeComponent(userId)}.json'));
  }

  @override
  Future<OnboardingDraft> load() async {
    final file = await _file();
    if (!await file.exists()) return const OnboardingDraft();
    return OnboardingDraft.fromJson(jsonDecode(await file.readAsString()));
  }

  @override
  Future<void> save(OnboardingDraft draft) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final next = File('${file.path}.tmp');
    await next.writeAsString(jsonEncode(draft.toJson()), flush: true);
    await next.rename(file.path);
  }
}

class MemoryOnboardingRepository implements OnboardingRepository {
  MemoryOnboardingRepository([this.draft = const OnboardingDraft()]);
  OnboardingDraft draft;
  @override
  Future<OnboardingDraft> load() async => draft;
  @override
  Future<void> save(OnboardingDraft draft) async => this.draft = draft;
}
