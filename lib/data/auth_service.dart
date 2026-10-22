import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/domain.dart';

/// A sign-in problem worth showing as-is. [cancelled] when the traveller
/// simply backed out (nothing to show).
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.cancelled = false});

  const AuthFailure.cancelled() : message = '', cancelled = true;

  final String message;
  final bool cancelled;

  @override
  String toString() => message;
}

/// What signing in did.
class SignInResult {
  const SignInResult({required this.account, this.switched = false, this.movedTrips = 0});

  final Account account;

  /// The Apple, Google or email account already existed (from another
  /// phone), so this phone switched to it and the guest's [movedTrips] moved
  /// across.
  /// Otherwise the guest account itself was linked: same trips, same id.
  final bool switched;
  final int movedTrips;
}

/// Accounts: everyone starts as a guest; signing in links the guest to
/// Apple, Google or an email and password so their trips follow them to any
/// phone. An email counts once its address is confirmed.
abstract interface class AuthService {
  Account? get current;

  /// The account whenever it changes: linked, switched, signed out.
  Stream<Account?> get changes;

  bool supports(SignInMethod method);

  /// Links the guest to Apple or Google (or switches to that account if it
  /// already exists, bringing the guest's trips). Throws [AuthFailure].
  /// Email uses [signInWithPassword] and [createWithPassword] instead.
  Future<SignInResult> signIn(SignInMethod method);

  /// Signs in to an existing email account: switches to it, bringing the
  /// guest's trips. If its address was never confirmed, the link is emailed
  /// again and the account is still a guest ([Account.unconfirmedEmail]).
  /// Throws [AuthFailure].
  Future<SignInResult> signInWithPassword(String email, String password);

  /// Gives the guest an email and password (same account, same trips) and
  /// emails the link that confirms the address. Until it's opened the
  /// account is still a guest ([Account.unconfirmedEmail]). An address that
  /// already has an account signs in to it if the password is its own.
  /// Throws [AuthFailure].
  Future<SignInResult> createWithPassword(String email, String password);

  /// Emails the link that confirms [Account.unconfirmedEmail] again. Throws
  /// [AuthFailure].
  Future<void> sendEmailConfirmation();

  /// Asks Firebase for the account again (its address may have been
  /// confirmed, on any device) and publishes it.
  Future<Account?> refresh();

  /// Emails [email] a link to choose a new password. Never says whether the
  /// address has an account. Throws [AuthFailure].
  Future<void> sendPasswordReset(String email);

  /// Signs out; Travary carries on as a new guest on this phone.
  Future<void> signOut();

  /// Deletes the account and its data (revoking Apple's tokens first, as
  /// Apple requires), then carries on as a new guest. Throws [AuthFailure].
  Future<void> deleteAccount();
}

/// Firebase Auth with Apple (Firebase's own provider flow: native on iOS,
/// a web sheet on Android), Google (google_sign_in) and an email and
/// password.
///
/// Firebase keeps the passwords (hashed) and makes the one-time codes. The
/// emails (confirming an address, choosing a new password) are Travary's
/// own: the `sendAccountEmail` function sends them through Cloudflare from
/// send.travary.app, linking to travary.app's `/auth/action` page, so they
/// reach the inbox. Firebase's own email stands in while the function can't
/// be reached (docs/EMAIL_SIGN_IN.md).
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({required this.ensureSignedIn, FirebaseFunctions? functions}) : _functions = functions {
    unawaited(_start());
  }

  final Future<String> Function() ensureSignedIn;
  final FirebaseFunctions? _functions;
  final _changes = StreamController<Account?>.broadcast();
  Account? _current;
  bool _googleReady = false;

  /// Google's OAuth clients for travary-444 (public identifiers, not secrets).
  static const _googleWebClientId = '315160115482-uvt4v0mpqqg03c3gi3sr443dmu2ur0la.apps.googleusercontent.com';
  static const _googleIosClientId = '315160115482-liqv57p5mjrp94cfstl0ldbcgmvq44hp.apps.googleusercontent.com';

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFunctions get _fns => _functions ?? FirebaseFunctions.instance;

  Future<void> _start() async {
    await ensureSignedIn();
    _auth.userChanges().listen((user) => _publish(user == null ? null : accountOf(user)));
  }

  void _publish(Account? account) {
    if (account == _current) return;
    _current = account;
    _changes.add(account);
  }

  @override
  Account? get current => _current;

  @override
  Stream<Account?> get changes => _changes.stream;

  @override
  bool supports(SignInMethod method) => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.android => true,
    _ => false,
  };

  @override
  Future<SignInResult> signIn(SignInMethod method) async {
    if (method == SignInMethod.email) throw const AuthFailure('Enter your email and password.');
    await ensureSignedIn();
    final user = _auth.currentUser!;
    final guestToken = _isGuest(user) ? await user.getIdToken() : null;
    AuthCredential? googleCredential;
    try {
      if (method == SignInMethod.google) {
        googleCredential = await _googleCredential();
        await user.linkWithCredential(googleCredential);
      } else {
        await user.linkWithProvider(_appleProvider());
      }
      // An email never confirmed gives way to the sign-in chosen instead.
      await _dropUnconfirmed(_auth.currentUser);
      await _auth.currentUser?.reload();
      return SignInResult(account: _refresh());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // That Apple or Google account is already Travary's (another phone):
        // switch to it and bring this guest's trips.
        final credential = e.credential ?? googleCredential;
        if (credential == null) throw const AuthFailure('That account couldn\'t be used. Try again.');
        await _auth.signInWithCredential(credential);
        final moved = guestToken == null ? 0 : await _adopt(guestToken);
        return SignInResult(account: _refresh(), switched: true, movedTrips: moved);
      }
      throw _failure(e, method);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthFailure.cancelled();
      }
      throw AuthFailure('Google sign-in didn\'t work (${e.code.name}). Try again.');
    }
  }

  @override
  Future<SignInResult> signInWithPassword(String email, String password) async {
    await ensureSignedIn();
    final user = _auth.currentUser!;
    final guestToken = _isGuest(user) ? await user.getIdToken() : null;
    try {
      return await _switchTo(email.trim(), password, from: user.uid, guestToken: guestToken);
    } on FirebaseAuthException catch (e) {
      throw _failure(e, SignInMethod.email);
    }
  }

  @override
  Future<SignInResult> createWithPassword(String email, String password) async {
    final address = email.trim();
    await ensureSignedIn();
    final user = _auth.currentUser!;
    final guestToken = _isGuest(user) ? await user.getIdToken() : null;
    try {
      // A mistyped address still waiting to be confirmed makes way for this one.
      if (_unconfirmed(user)) await user.unlink(EmailAuthProvider.PROVIDER_ID);
      await user.linkWithCredential(EmailAuthProvider.credential(email: address, password: password));
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use' && e.code != 'credential-already-in-use') {
        throw _failure(e, SignInMethod.email);
      }
      // That address is already Travary's (another phone): its own password
      // signs in to it, as Apple and Google switch to theirs.
      try {
        return await _switchTo(address, password, from: user.uid, guestToken: guestToken);
      } on FirebaseAuthException catch (e) {
        throw switch (e.code) {
          'invalid-credential' || 'wrong-password' || 'user-not-found' => const AuthFailure(
            'That email already has a Travary account. Sign in with its password, or reset it.',
          ),
          _ => _failure(e, SignInMethod.email),
        };
      }
    }
    await _confirm(_auth.currentUser!);
    await _auth.currentUser?.reload();
    return SignInResult(account: _refresh());
  }

  /// Signs in to the email account [email], switching from the account
  /// [from] (bringing its trips if it was a guest's). An address never
  /// confirmed is sent its link again.
  Future<SignInResult> _switchTo(String email, String password, {required String from, String? guestToken}) async {
    final user = (await _auth.signInWithEmailAndPassword(email: email, password: password)).user!;
    if (!user.emailVerified) await _confirm(user);
    final switched = user.uid != from;
    final moved = switched && guestToken != null ? await _adopt(guestToken) : 0;
    return SignInResult(account: _refresh(), switched: switched, movedTrips: moved);
  }

  /// Asks `sendAccountEmail` for one of the account emails, sent from
  /// travary.app. While the server can't (not deployed yet, the sender
  /// down), [fallback] has Firebase send its own instead.
  Future<void> _accountEmail(Map<String, Object> data, Future<void> Function() fallback) async {
    try {
      await _fns.httpsCallable('sendAccountEmail').call<dynamic>(data);
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'resource-exhausted':
          throw const AuthFailure('We\'ve just sent one. Wait a minute, then try again.');
        case 'invalid-argument':
          throw const AuthFailure('That email address doesn\'t look right. Check it and try again.');
        default:
          await fallback();
      }
    }
  }

  /// Emails the link that confirms [user]'s address. Too many in a row are
  /// refused; the last one still works, and there's "Send it again".
  Future<void> _confirm(User user) async {
    try {
      await _accountEmail(const {'kind': 'confirm'}, user.sendEmailVerification);
    } on Object catch (_) {}
  }

  @override
  Future<void> sendEmailConfirmation() async {
    final user = _auth.currentUser;
    if (user == null || !_unconfirmed(user)) return;
    try {
      await _accountEmail(const {'kind': 'confirm'}, user.sendEmailVerification);
    } on FirebaseAuthException catch (e) {
      throw e.code == 'too-many-requests'
          ? const AuthFailure('We\'ve just sent a few. Wait a minute, then try again.')
          : _failure(e, SignInMethod.email);
    }
  }

  @override
  Future<Account?> refresh() async {
    final user = _auth.currentUser;
    if (user == null) return _current;
    final waiting = _unconfirmed(user);
    try {
      await user.reload();
      // A newly confirmed address goes into the next ID token too.
      final now = _auth.currentUser;
      if (waiting && now != null && now.emailVerified) await now.getIdToken(true);
    } on FirebaseAuthException catch (_) {
      // Offline, most likely: ask again later.
      return _current;
    }
    return _refresh();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final address = email.trim();
    await ensureSignedIn();
    try {
      await _accountEmail({'kind': 'reset', 'email': address}, () => _auth.sendPasswordResetEmail(email: address));
    } on FirebaseAuthException catch (e) {
      // Email enumeration protection hides this; never tell either way.
      if (e.code == 'user-not-found') return;
      throw _failure(e, SignInMethod.email);
    }
  }

  /// An email and password whose address hasn't been confirmed yet.
  static bool _unconfirmed(User user) =>
      !user.emailVerified && user.providerData.any((info) => info.providerId == EmailAuthProvider.PROVIDER_ID);

  /// No confirmed way in: anonymous, or only an unconfirmed email. Its trips
  /// may move to the account the phone switches to (`adoptGuestTrips`).
  static bool _isGuest(User user) => user.isAnonymous || accountOf(user).isGuest;

  /// Unlinks an unconfirmed email once another sign-in has been linked.
  Future<void> _dropUnconfirmed(User? user) async {
    if (user == null || !_unconfirmed(user)) return;
    try {
      await user.unlink(EmailAuthProvider.PROVIDER_ID);
    } on FirebaseAuthException catch (_) {}
  }

  @override
  Future<void> signOut() async {
    if (_current?.methods.contains(SignInMethod.google) ?? false) {
      try {
        await _initGoogle();
        await GoogleSignIn.instance.signOut();
      } on Object catch (_) {
        // Firebase is what matters; Google's own session is a nicety.
      }
    }
    await _auth.signOut();
    await ensureSignedIn();
    _refresh();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final methods = accountOf(user).methods;
    try {
      // Apple requires its tokens be revoked when an account is deleted.
      if (methods.contains(SignInMethod.apple) && defaultTargetPlatform == TargetPlatform.iOS) {
        final credential = await user.reauthenticateWithProvider(_appleProvider());
        final code = credential.additionalUserInfo?.authorizationCode;
        if (code != null) await _auth.revokeTokenWithAuthorizationCode(code);
      }
      await _fns.httpsCallable('deleteAccount').call<dynamic>();
    } on FirebaseAuthException catch (e) {
      throw _failure(e, SignInMethod.apple);
    } on FirebaseFunctionsException catch (e) {
      throw AuthFailure(e.message ?? 'Your account couldn\'t be deleted. Check your connection and try again.');
    }
    if (methods.contains(SignInMethod.google)) {
      try {
        await _initGoogle();
        await GoogleSignIn.instance.disconnect();
      } on Object catch (_) {}
    }
    await _auth.signOut();
    await ensureSignedIn();
    _refresh();
  }

  Future<int> _adopt(String guestToken) async {
    try {
      final result = await _fns.httpsCallable('adoptGuestTrips').call<dynamic>({'guestToken': guestToken});
      return ((result.data as Map?)?['trips'] as num?)?.toInt() ?? 0;
    } on FirebaseFunctionsException {
      // Signed in either way; the guest's trips stay with the guest.
      return 0;
    }
  }

  Account _refresh() {
    final user = _auth.currentUser;
    _publish(user == null ? null : accountOf(user));
    return _current!;
  }

  AppleAuthProvider _appleProvider() => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  Future<void> _initGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS ? _googleIosClientId : null,
      serverClientId: defaultTargetPlatform == TargetPlatform.android ? _googleWebClientId : null,
    );
    _googleReady = true;
  }

  Future<AuthCredential> _googleCredential() async {
    await _initGoogle();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthFailure('Google didn\'t confirm your account. Try again.');
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  AuthFailure _failure(FirebaseAuthException e, SignInMethod method) => switch (e.code) {
    'canceled' || 'cancelled' || 'web-context-canceled' || 'user-cancelled' => const AuthFailure.cancelled(),
    // Apple's "unknown" (ASAuthorizationError 1000): mostly a phone with no
    // Apple Account, after Apple's own prompt to sign in under Settings.
    'unknown' when method == SignInMethod.apple => const AuthFailure(
      'Apple sign-in didn\'t finish. Check this phone is signed in to an Apple Account in Settings, then try again.',
    ),
    'email-already-in-use' || 'account-exists-with-different-credential' => const AuthFailure(
      'That email already has a Travary account with another sign-in. Use that one instead.',
    ),
    'network-request-failed' => const AuthFailure('You\'re offline. Connect and try again.'),
    'invalid-email' => const AuthFailure('That email address doesn\'t look right. Check it and try again.'),
    // With email enumeration protection on, a wrong password and an address
    // with no account are the same answer.
    'invalid-credential' || 'wrong-password' || 'user-not-found' when method == SignInMethod.email => const AuthFailure(
      'That email or password isn\'t right. Check them, or reset your password.',
    ),
    'weak-password' ||
    'password-does-not-meet-requirements' => const AuthFailure('Choose a longer password: at least 8 characters.'),
    'too-many-requests' => const AuthFailure('Too many tries in a row. Wait a few minutes, or reset your password.'),
    'user-disabled' => const AuthFailure('That account has been switched off. Contact Travary support for help.'),
    'operation-not-allowed' => const AuthFailure('Email sign-in isn\'t switched on yet. Use Apple or Google for now.'),
    'provider-already-linked' => const AuthFailure('You\'re already signed in with that.'),
    'requires-recent-login' => const AuthFailure('Please sign in again, then try once more.'),
    _ => AuthFailure('Sign-in didn\'t work (${e.code}). Try again.'),
  };

  /// [user] as an [Account]. An email and password counts once its address
  /// is confirmed; until then a guest has it as [Account.unconfirmedEmail].
  static Account accountOf(User user) {
    bool counts(UserInfo info) => info.providerId != EmailAuthProvider.PROVIDER_ID || user.emailVerified;
    final infos = user.providerData.where(counts).toList();
    final methods = {for (final info in infos) ?SignInMethod.fromProviderId(info.providerId)};
    String? first(String? Function(UserInfo) pick) =>
        infos.map(pick).firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    final waiting = methods.isEmpty && infos.length < user.providerData.length;
    return Account(
      uid: user.uid,
      methods: methods,
      name: (user.displayName?.isNotEmpty ?? false) ? user.displayName : first((i) => i.displayName),
      email: methods.isEmpty
          ? null
          : (user.email?.isNotEmpty ?? false) && (user.emailVerified || !_unconfirmed(user))
          ? user.email
          : first((i) => i.email),
      unconfirmedEmail: waiting ? user.email : null,
    );
  }
}
