import 'package:cloud_functions/cloud_functions.dart';

/// A problem worth showing the traveller as-is.
class SharingException implements Exception {
  const SharingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TripInvite {
  const TripInvite(this.code, this.expiresAt);

  /// Six characters, e.g. "K7MPQ2".
  final String code;
  final DateTime expiresAt;
}

/// Family sharing: invite codes, joining, leaving. Runs on the server
/// because only the server may change who's on a trip.
abstract interface class SharingService {
  /// A code others can use to join [tripId]. [name] is what the family
  /// will call the person inviting.
  Future<TripInvite> createInvite(String tripId, {String? name});

  /// Joins the trip for [code]. Returns its id and title.
  Future<({String tripId, String title})> join(String code, {required String name});

  /// Removes [memberId] from the trip (the organiser removing someone, or a
  /// member removing themselves to leave).
  Future<void> removeMember(String tripId, String memberId);
}

class CloudSharingService implements SharingService {
  CloudSharingService({required this.ensureSignedIn, FirebaseFunctions? functions})
    : _functions = functions;

  final Future<void> Function() ensureSignedIn;
  final FirebaseFunctions? _functions;

  Future<Map<String, dynamic>> _call(String name, Map<String, Object?> data) async {
    try {
      await ensureSignedIn();
      final result = await (_functions ?? FirebaseFunctions.instance).httpsCallable(name).call<dynamic>(data);
      return Map<String, dynamic>.from(result.data as Map? ?? const {});
    } on FirebaseFunctionsException catch (e) {
      throw SharingException(
        e.code == 'internal' || (e.message ?? '').isEmpty
            ? 'Something went wrong. Check your connection and try again.'
            : e.message!,
      );
    }
  }

  @override
  Future<TripInvite> createInvite(String tripId, {String? name}) async {
    final data = await _call('createTripInvite', {'tripId': tripId, 'name': name});
    return TripInvite(
      data['code'] as String,
      DateTime.fromMillisecondsSinceEpoch((data['expiresAt'] as num).toInt()),
    );
  }

  @override
  Future<({String tripId, String title})> join(String code, {required String name}) async {
    final data = await _call('joinTrip', {'code': code, 'name': name});
    return (tripId: data['tripId'] as String, title: data['title'] as String? ?? 'the trip');
  }

  @override
  Future<void> removeMember(String tripId, String memberId) =>
      _call('removeTripMember', {'tripId': tripId, 'memberId': memberId});
}
