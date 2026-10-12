import 'package:cloud_functions/cloud_functions.dart';

/// The server side of purchases (`functions/src/purchases.ts`). The app
/// never records what it bought: the server checks with RevenueCat and
/// mirrors it to `users/{uid}` and the trips it covers.
abstract interface class PurchaseServer {
  /// Records the Holiday Pass bought in [transactionId] for [tripId]. The
  /// server reads the trip's dates itself and stamps `premium` on the trip.
  Future<void> claimTripPass({required String tripId, required String transactionId});

  /// Mirrors the Annual Pass from RevenueCat now (the webhook also does,
  /// for renewals and expiry) and stamps the trips this traveller organises.
  Future<void> syncPurchases();
}

class PurchaseServerException implements Exception {
  const PurchaseServerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudPurchaseServer implements PurchaseServer {
  CloudPurchaseServer({required this.ensureSignedIn, FirebaseFunctions? functions}) : _functions = functions;

  final Future<void> Function() ensureSignedIn;
  final FirebaseFunctions? _functions;

  Future<void> _call(String name, Map<String, Object?> data) async {
    try {
      await ensureSignedIn();
      await (_functions ?? FirebaseFunctions.instance).httpsCallable(name).call<dynamic>(data);
    } on FirebaseFunctionsException catch (e) {
      throw PurchaseServerException(
        e.code == 'internal' || (e.message ?? '').isEmpty
            ? 'Something went wrong. Check your connection and try again.'
            : e.message!,
      );
    }
  }

  @override
  Future<void> claimTripPass({required String tripId, required String transactionId}) =>
      _call('claimTripPass', {'tripId': tripId, 'transactionId': transactionId});

  @override
  Future<void> syncPurchases() => _call('syncPurchases', const {});
}
