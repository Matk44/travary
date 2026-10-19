import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/domain.dart';

/// The free plan's numbers, from Firestore's `config/freePlan`
/// (`{bookingsPerHoliday: 12}`), so they can change without a release.
/// Set by hand in the console; every signed-in phone may read it, none may
/// write it (`firestore.rules`).
///
/// Offline, the last answer Firestore cached; never read (or unreadable),
/// [FreePlanLimits.defaults].
class FirestoreFreePlanLimits {
  FirestoreFreePlanLimits({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  Stream<FreePlanLimits> watch() => (_firestore ?? FirebaseFirestore.instance)
      .doc('config/freePlan')
      .snapshots()
      .map((snapshot) => FreePlanLimits.fromJson(snapshot.data()))
      // Refused or failed: the store keeps what it has (the defaults).
      .handleError((Object _) {});
}
