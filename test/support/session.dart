import 'dart:async';

import 'package:provider/provider.dart';
import 'package:travary/data/auth_service.dart';
import 'package:travary/data/onboarding_record.dart';
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

  /// Methods this phone offers; all by default.
  Set<SignInMethod> supported = {...SignInMethod.values};

  @override
  bool supports(SignInMethod method) => supported.contains(method);

  /// Email accounts that already exist (another phone), by address.
  final emailAccounts = <String, ({String uid, String password, bool confirmed})>{};

  /// The address waiting to be confirmed has had its link opened (on any
  /// device): the next [refresh] finds it confirmed, as Firebase does.
  var linkOpened = false;

  AuthFailure? _failure() {
    final failure = failNext;
    failNext = null;
    return failure;
  }

  @override
  Future<SignInResult> signInWithPassword(String email, String password) async {
    calls.add('signInWithPassword:$email');
    if (_failure() case final failure?) throw failure;
    final existing = emailAccounts[email];
    if (existing == null || existing.password != password) {
      throw const AuthFailure('That email or password isn\'t right. Check them, or reset your password.');
    }
    final switched = existing.uid != _current.uid;
    _set(
      Account(
        uid: existing.uid,
        methods: existing.confirmed ? {SignInMethod.email} : const {},
        email: existing.confirmed ? email : null,
        unconfirmedEmail: existing.confirmed ? null : email,
      ),
    );
    return SignInResult(account: _current, switched: switched, movedTrips: switched ? guestTrips : 0);
  }

  @override
  Future<SignInResult> createWithPassword(String email, String password) async {
    calls.add('createWithPassword:$email');
    if (_failure() case final failure?) throw failure;
    if (emailAccounts.containsKey(email)) {
      try {
        return await signInWithPassword(email, password);
      } on AuthFailure {
        throw const AuthFailure('That email already has a Travary account. Sign in with its password, or reset it.');
      }
    }
    linkOpened = false;
    _set(Account(uid: _current.uid, methods: _current.methods, name: name, unconfirmedEmail: email));
    return SignInResult(account: _current);
  }

  @override
  Future<void> sendEmailConfirmation() async {
    calls.add('sendEmailConfirmation');
    if (_failure() case final failure?) throw failure;
  }

  @override
  Future<Account?> refresh() async {
    calls.add('refresh');
    final waiting = _current.unconfirmedEmail;
    if (waiting != null && linkOpened) {
      _set(Account(uid: _current.uid, methods: {..._current.methods, SignInMethod.email}, name: name, email: waiting));
    }
    return _current;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('sendPasswordReset:$email');
    if (_failure() case final failure?) throw failure;
  }

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
ChangeNotifierProvider<AppSession> appSessionProvider({
  AuthService? auth,
  String uid = 'me',
  OnboardingRecord? onboardingRecord,
  Stream<Uri>? links,
}) => ChangeNotifierProvider(
  create: (_) =>
      AppSession(auth: auth, uid: auth?.current?.uid ?? uid, onboardingRecord: onboardingRecord, links: links),
);
