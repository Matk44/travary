import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/document_lock.dart';
import '../data/travel_document_repository.dart';
import '../domain/domain.dart';
import '../logic/travel_documents.dart';
import '../logic/trip_plan.dart';
import 'analytics.dart';

/// The traveller's passports, visas, insurance and other documents: on
/// this phone only, behind the phone's own lock (Face ID, fingerprint or
/// passcode). Screens read them only once [isUnlocked]; they lock again
/// whenever the app goes to the background.
///
/// Never gated by a plan: these are the traveller's own documents.
class TravelDocumentsStore extends ChangeNotifier {
  TravelDocumentsStore({required this.repository, required DocumentLock lock}) : _lock = lock {
    unawaited(_load());
  }

  final TravelDocumentRepository repository;
  final DocumentLock _lock;
  final _random = Random();

  List<TravelDocument> _documents = const [];
  bool _loaded = false;
  bool _unlocked = false;
  bool _noLock = false;
  bool _disposed = false;

  bool get isLoaded => _loaded;

  /// Every document, but only while unlocked.
  List<TravelDocument> get documents => _unlocked ? List.unmodifiable(_documents) : const [];

  /// How many there are, which is safe to show while locked.
  int get count => _documents.length;
  bool get isUnlocked => _unlocked;

  /// The phone has no passcode, so the documents can't be locked.
  bool get phoneHasNoLock => _noLock;

  TravelDocument? document(String id) => documents.where((d) => d.id == id).firstOrNull;

  /// How many have expired or won't do for [nextTrip]: a count only, so
  /// it's safe to show while locked.
  int needingAttention({required LocalDate today, TripPlan? nextTrip}) => _documents.where((document) {
    final alert = documentStatus(document, today: today, nextTrip: nextTrip)?.alert;
    return alert == DocumentAlert.trip || alert == DocumentAlert.expired;
  }).length;

  Future<void> _load() async {
    _documents = await repository.load();
    _loaded = true;
    _notify();
  }

  /// Asks the phone's lock. True once the documents can be shown.
  Future<bool> unlock() async {
    if (_unlocked) return true;
    final result = await _lock.unlock();
    _unlocked = result != UnlockResult.refused;
    _noLock = result == UnlockResult.noLock;
    _notify();
    return _unlocked;
  }

  /// Hides them again (the app went to the background).
  void lock() {
    if (!_unlocked) return;
    _unlocked = false;
    _notify();
  }

  String newId() => '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(1 << 16)}';

  /// Copies a photo or PDF in for a document being edited.
  Future<DocumentFile> importFile(String path, {String? name}) => repository.importFile(path, name: name);

  /// Removes a file that was added and then not saved.
  Future<void> discardFile(DocumentFile file) => repository.deleteFile(file);

  File fileFor(DocumentFile file) => repository.fileFor(file);

  /// Adds [document], or replaces the one with its ID; files it no longer
  /// has are deleted from the phone.
  Future<void> save(TravelDocument document) async {
    _ensureUnlocked();
    final previous = _documents.where((d) => d.id == document.id).firstOrNull;
    _documents = [
      for (final d in _documents)
        if (d.id != document.id) d,
      document,
    ];
    await repository.saveAll(_documents);
    if (previous != null) {
      final kept = {for (final f in document.files) f.id};
      for (final file in previous.files.where((f) => !kept.contains(f.id))) {
        await repository.deleteFile(file);
      }
    }
    // The type only: never names, numbers or dates.
    track('travel_document_saved', {'type': document.type.name, 'new': previous == null});
    _notify();
  }

  /// Deletes [document] and its files from the phone.
  Future<void> delete(TravelDocument document) async {
    _ensureUnlocked();
    _documents = [
      for (final d in _documents)
        if (d.id != document.id) d,
    ];
    await repository.saveAll(_documents);
    for (final file in document.files) {
      await repository.deleteFile(file);
    }
    _notify();
  }

  void _ensureUnlocked() {
    if (!_unlocked) throw StateError('Travel documents are locked.');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
