import 'dart:async';

import 'package:provider/provider.dart';
import 'package:travary/data/auth_service.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/app_session.dart';

/// A sign-in service with no Firebase: signing in links the guest unless
/// [existing] says that account is already someone's, in which case it
/// switches to that account's id and "moves" [guestTrips] trips.
class FakeAuthService implements AuthService {
  FakeAuthService({String uid = 'me', Set<SignInMethod> methods = const {}, this.name, this.email})
    : _current = Account(uid: uid, methods: methods, name: name, email: email);

  final String? name;
  final String? email;

  /// Sign-in methods whose accounts already exist, and their ids.
  final existing = <SignInMethod, String>{};
  var guestTrips = 0;

  /// Throw this from the next sign-in (e.g. cancelled).
  AuthFailure? failNext;
  final calls = <String>[];
  var _guests = 0;

  final _changes = StreamController<Account?>.broadcast();
  Account _current;

  @override
  Account? get current => _current;

  @override
  Stream<Account?> get changes => _changes.stream;

  @override
  bool supports(SignInMethod method) => true;

  void _set(Account account) {
    _current = account;
    _changes.add(account);
  }

  @override
  Future<SignInResult> signIn(SignInMethod method) async {
    calls.add('signIn:${method.name}');
    final failure = failNext;
    failNext = null;
    if (failure != null) throw failure;
    final other = existing[method];
    if (other != null) {
      _set(Account(uid: other, methods: {method}, email: email));
      return SignInResult(account: _current, switched: true, movedTrips: guestTrips);
    }
    _set(Account(uid: _current.uid, methods: {..._current.methods, method}, name: name, email: email));
    return SignInResult(account: _current);
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _set(Account(uid: 'guest${++_guests}'));
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('deleteAccount');
    _set(Account(uid: 'guest${++_guests}'));
  }
}

/// The session for a test app: demo mode (no sign-in) unless [auth] is given.
ChangeNotifierProvider<AppSession> appSessionProvider({AuthService? auth, String uid = 'me'}) => ChangeNotifierProvider(
  create: (_) => AppSession(auth: auth, uid: auth?.current?.uid ?? uid),
);
