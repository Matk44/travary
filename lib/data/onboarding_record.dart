import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Whether an account has been through onboarding, on any phone, so a
/// traveller signing in on a new phone (or after reinstalling) goes straight
/// to their plans. Kept on `users/{uid}`: `onboardingCompleted` and
/// `onboardingCompletedAt`, the only fields the app may write there.
abstract interface class OnboardingRecord {
  /// True once [uid] has finished onboarding or signed in; null when it
  /// can't be told right now (offline on a fresh phone).
  Future<bool?> isCompleted(String uid);

  /// Records it. Not awaited by callers: Firestore's offline cache applies
  /// it at once and sends it when it can.
  Future<void> markCompleted(String uid);
}

class FirestoreOnboardingRecord implements OnboardingRecord {
  FirestoreOnboardingRecord({required this.ensureSignedIn, FirebaseFirestore? firestore, this.timeout = _timeout})
    : _firestore = firestore;

  static const _timeout = Duration(seconds: 4);

  final Future<void> Function() ensureSignedIn;
  final FirebaseFirestore? _firestore;

  /// Startup waits at most this long before deciding without it.
  final Duration timeout;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      (_firestore ?? FirebaseFirestore.instance).doc('users/$uid');

  @override
  Future<bool?> isCompleted(String uid) async {
    try {
      await ensureSignedIn();
      final snapshot = await _doc(uid).get().timeout(timeout);
      return snapshot.data()?['onboardingCompleted'] == true;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> markCompleted(String uid) async {
    try {
      await ensureSignedIn();
      // Merge: the server owns everything else on this document.
      await _doc(uid).set({
        'onboardingCompleted': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // The local setup still records completion on this phone.
    }
  }
}

/// Demo mode and tests.
class MemoryOnboardingRecord implements OnboardingRecord {
  MemoryOnboardingRecord([Iterable<String> completed = const []]) : completed = {...completed};
  final Set<String> completed;

  @override
  Future<bool?> isCompleted(String uid) async => completed.contains(uid);

  @override
  Future<void> markCompleted(String uid) async => completed.add(uid);
}
