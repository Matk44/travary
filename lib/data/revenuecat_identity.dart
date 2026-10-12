import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart' as rc;

/// RevenueCat's SDK is one per app: configured once, then switched to
/// whoever is signed in (the Firebase uid, so the server can look up the
/// same customer). Runs one at a time, so a quick account switch can't
/// interleave a configure with a log-in.
abstract final class RevenueCatIdentity {
  static Future<void> _queue = Future.value();

  /// This phone's Firebase Analytics ID, given to RevenueCat so it can send
  /// purchases, renewals and refunds to Firebase Analytics (its Firebase
  /// integration). Unset without analytics.
  static Future<String?> Function()? analyticsInstanceId;

  /// Runs [body] as [userId], holding the queue until it finishes.
  static Future<T> run<T>(String publicSdkKey, String userId, Future<T> Function() body) async {
    final previous = _queue;
    final release = Completer<void>();
    _queue = release.future;
    await previous;
    try {
      if (!await rc.Purchases.isConfigured) {
        await rc.Purchases.configure(rc.PurchasesConfiguration(publicSdkKey)..appUserID = userId);
        final instanceId = await analyticsInstanceId?.call().catchError((Object _) => null);
        if (instanceId != null) await rc.Purchases.setFirebaseAppInstanceId(instanceId);
      } else if (await rc.Purchases.appUserID != userId) {
        await rc.Purchases.logIn(userId);
      }
      return await body();
    } finally {
      release.complete();
    }
  }

  /// Makes [userId] RevenueCat's current customer.
  static Future<void> ensure(String publicSdkKey, String userId) => run(publicSdkKey, userId, () async {});
}
