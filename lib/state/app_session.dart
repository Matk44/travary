import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_service.dart';
import '../domain/domain.dart';
import 'analytics.dart';

/// Who is using Travary on this phone, and the way to sign in, out or
/// delete the account.
///
/// [uid] keys everything that holds a traveller's data (`TravaryApp`
/// rebuilds the stores when it changes): signing in normally links the
/// guest and keeps the same id, but switching to an existing account,
/// signing out and deleting the account each start on a different one.
class AppSession extends ChangeNotifier {
  AppSession({required this.auth, required String uid}) : _uid = uid {
    _account = auth?.current;
    _subscription = auth?.changes.listen(_changed);
  }

  /// Null in demo mode: accounts need trips saved to the cloud.
  final AuthService? auth;
  StreamSubscription<Account?>? _subscription;
  String _uid;
  Account? _account;
  String? _notice;
  bool _busy = false;
  bool _disposed = false;

  String get uid => _uid;

  /// The current account, once known (null in demo mode).
  Account? get account => _account;
  bool get canSignIn => auth != null;
  bool get isBusy => _busy;

  /// A message for after the app rebuilt for a new account ("Signed in…"),
  /// shown once by the home screen.
  String? takeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  bool supports(SignInMethod method) => auth?.supports(method) ?? false;

  void _changed(Account? account) {
    // Between signing out and the new guest there's briefly no one.
    if (account == null) return;
    _account = account;
    // During an action the switch waits for its end, so the message for
    // after the rebuild is ready first.
    if (!_busy) _uid = account.uid;
    _notify();
  }

  /// Signs in with [method]. Returns what to tell the traveller, or null
  /// when they backed out. Throws [AuthFailure] with a message to show.
  Future<String?> signIn(SignInMethod method) => _run(() async {
    try {
      final result = await auth!.signIn(method);
      track('sign_in', {'method': method.name, 'switched': result.switched, 'moved': result.movedTrips});
      _account = result.account;
      final moved = result.movedTrips;
      final message = result.switched
          ? 'Signed in with ${method.label}.${moved > 0 ? ' $moved ${moved == 1 ? 'trip' : 'trips'} from this phone moved to your account.' : ''}'
          : 'Signed in with ${method.label}. Your trips are saved to your account.';
      if (result.account.uid != _uid) {
        _notice = message;
        _uid = result.account.uid;
      }
      return message;
    } on AuthFailure catch (e) {
      if (e.cancelled) return null;
      rethrow;
    }
  });

  Future<void> signOut() => _run(() async {
    track('sign_out');
    _notice = 'Signed out. Sign in again to see your trips.';
    await auth!.signOut();
    _syncUid();
  });

  Future<void> deleteAccount() => _run(() async {
    await auth!.deleteAccount();
    track('account_deleted');
    _notice = 'Your account has been deleted.';
    _syncUid();
  });

  void _syncUid() {
    final account = auth!.current;
    if (account != null) {
      _account = account;
      _uid = account.uid;
    }
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    _busy = true;
    _notify();
    try {
      return await action();
    } finally {
      _busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
