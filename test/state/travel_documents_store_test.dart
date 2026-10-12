import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/document_lock.dart';
import 'package:travary/data/memory_travel_document_repository.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/trip_plan.dart';
import 'package:travary/state/travel_documents_store.dart';

import '../helpers.dart';

void main() {
  const photo = DocumentFile(id: 'f1', name: 'Photo.jpg', fileName: 'f1.jpg', sizeBytes: 1);
  const scan = DocumentFile(id: 'f2', name: 'Scan.pdf', fileName: 'f2.pdf', sizeBytes: 1);
  final passport = TravelDocument(
    id: 'p',
    type: TravelDocumentType.passport,
    holder: 'Sam',
    expiresOn: LocalDate(2027, 2, 1),
    files: const [photo, scan],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  late MemoryTravelDocumentRepository repository;
  late FixedDocumentLock lock;
  late TravelDocumentsStore store;

  setUp(() async {
    repository = MemoryTravelDocumentRepository([passport]);
    lock = FixedDocumentLock();
    store = TravelDocumentsStore(repository: repository, lock: lock);
    await pumpEventQueue();
  });

  tearDown(() => store.dispose());

  test('locked: only how many there are', () {
    expect(store.isLoaded, isTrue);
    expect(store.isUnlocked, isFalse);
    expect(store.count, 1);
    expect(store.documents, isEmpty);
    expect(store.document('p'), isNull);
  });

  test('the phone\'s lock opens them; refusing keeps them shut', () async {
    lock.result = UnlockResult.refused;
    expect(await store.unlock(), isFalse);
    expect(store.documents, isEmpty);

    lock.result = UnlockResult.unlocked;
    expect(await store.unlock(), isTrue);
    expect(store.documents.single.id, 'p');
    expect(store.phoneHasNoLock, isFalse);

    // Already open: not asked again until it locks.
    await store.unlock();
    expect(lock.asked, 2);
    store.lock();
    expect(store.documents, isEmpty);
  });

  test('asking again while the phone\'s prompt is up waits for it, never a second prompt', () async {
    final pending = _PendingLock();
    final waiting = TravelDocumentsStore(repository: repository, lock: pending);
    addTearDown(waiting.dispose);
    final first = waiting.unlock();
    final second = waiting.unlock();
    expect(pending.asked, 1);
    pending.answer(UnlockResult.refused);
    expect(await first, isFalse);
    expect(await second, isFalse);

    // Once it's answered, the next ask is a new prompt.
    final third = waiting.unlock();
    expect(pending.asked, 2);
    pending.answer(UnlockResult.unlocked);
    expect(await third, isTrue);
  });

  test('a phone without a passcode opens them, and says so', () async {
    lock.result = UnlockResult.noLock;
    expect(await store.unlock(), isTrue);
    expect(store.phoneHasNoLock, isTrue);
  });

  test('nothing can be saved or deleted while locked', () async {
    expect(() => store.save(passport), throwsStateError);
    expect(() => store.delete(passport), throwsStateError);
  });

  test('saving replaces a document and deletes the files it dropped; deleting deletes its files', () async {
    await store.unlock();
    await store.save(passport.copyWith(files: const [photo], number: '533120784'));
    expect(repository.saved.single.number, '533120784');
    expect(repository.deletedFiles, ['f2']);

    final visa = TravelDocument(
      id: store.newId(),
      type: TravelDocumentType.visa,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await store.save(visa);
    expect(store.count, 2);

    await store.delete(store.document('p')!);
    expect(repository.saved.single.type, TravelDocumentType.visa);
    expect(repository.deletedFiles, ['f2', 'f1']);
  });

  test('how many need checking for the next trip, even while locked', () {
    final japan = TripPlan(
      trip('jp', title: 'Japan', plannedStart: LocalDate(2026, 11, 8), plannedEnd: LocalDate(2026, 11, 14)),
      const [],
    );
    expect(store.needingAttention(today: LocalDate(2026, 10, 3), nextTrip: japan), 1);
    expect(store.needingAttention(today: LocalDate(2026, 10, 3)), 0);
  });
}

/// A lock whose prompt stays up until [answer].
class _PendingLock implements DocumentLock {
  var asked = 0;
  Completer<UnlockResult>? _prompt;

  @override
  Future<UnlockResult> unlock() {
    asked++;
    return (_prompt = Completer()).future;
  }

  void answer(UnlockResult result) => _prompt!.complete(result);
}
