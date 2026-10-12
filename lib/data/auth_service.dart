import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  /// The Apple or Google account already existed (from another phone), so
  /// this phone switched to it and the guest's [movedTrips] moved across.
  /// Otherwise the guest account itself was linked: same trips, same id.
  final bool switched;
  final int movedTrips;
}

/// Accounts: everyone starts as a guest; signing in links the guest to
/// Apple, Google or an email address so their trips follow them to any phone.
abstract interface class AuthService {
  Account? get current;

  /// The account whenever it changes: linked, switched, signed out.
  Stream<Account?> get changes;

  bool supports(SignInMethod method);

  /// Links the guest to Apple or Google (or switches to that account if it
  /// already exists, bringing the guest's trips). Throws [AuthFailure].
  /// Email uses [sendSignInLink] and [signInWithLink] instead.
  Future<SignInResult> signIn(SignInMethod method);

  /// Emails [email] a link that signs in on this phone, and remembers the
  /// address for when the link comes back. Throws [AuthFailure].
  Future<void> sendSignInLink(String email);

  /// The address a link was last sent to, until it's used.
  Future<String?> pendingEmail();

  /// Whether [link] is one of those links.
  bool isSignInLink(String link);

  /// Signs in with a link sent to [email] (the pending address if omitted):
  /// links the guest, or switches to that account if it already exists.
  /// Throws [AuthFailure].
  Future<SignInResult> signInWithLink(String link, {String? email});

  /// Signs out; Travary carries on as a new guest on this phone.
  Future<void> signOut();

  /// Deletes the account and its data (revoking Apple's tokens first, as
  /// Apple requires), then carries on as a new guest. Throws [AuthFailure].
  Future<void> deleteAccount();
}

/// Firebase Auth with Apple (Firebase's own provider flow: native on iOS,
/// a web sheet on Android), Google (google_sign_in) and passwordless email
/// links.
///
/// Email links open the app from the project's Firebase Hosting domain
/// (`travary-444.firebaseapp.com`, or a custom one in
/// `TRAVARY_EMAIL_LINK_DOMAIN`) once that domain is an Associated Domain on
/// iOS and an App Link on Android. Until then email isn't offered: turn it
/// on with `--dart-define=TRAVARY_EMAIL_LINKS=true` (docs/EMAIL_LINK_SIGN_IN.md).
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required this.ensureSignedIn,
    FirebaseFunctions? functions,
    this.emailLinks = const bool.fromEnvironment('TRAVARY_EMAIL_LINKS'),
    this.emailLinkDomain = const String.fromEnvironment('TRAVARY_EMAIL_LINK_DOMAIN'),
  }) : _functions = functions {
    unawaited(_start());
  }

  final Future<String> Function() ensureSignedIn;
  final FirebaseFunctions? _functions;

  /// Email links are set up for this build.
  final bool emailLinks;

  /// A custom Hosting domain for the links; empty for the project's own.
  final String emailLinkDomain;
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
    TargetPlatform.iOS || TargetPlatform.android => method != SignInMethod.email || emailLinks,
    _ => false,
  };

  @override
  Future<SignInResult> signIn(SignInMethod method) async {
    if (method == SignInMethod.email) throw const AuthFailure('Enter your email to get a sign-in link.');
    await ensureSignedIn();
    final user = _auth.currentUser!;
    final guestToken = user.isAnonymous ? await user.getIdToken() : null;
    AuthCredential? googleCredential;
    try {
      if (method == SignInMethod.google) {
        googleCredential = await _googleCredential();
        await user.linkWithCredential(googleCredential);
      } else {
        await user.linkWithProvider(_appleProvider());
      }
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

  /// The project's own Hosting domain, already authorised for sign-in.
  static const _projectLinkDomain = 'travary-444.firebaseapp.com';

  ActionCodeSettings get _linkSettings => ActionCodeSettings(
    url: 'https://${emailLinkDomain.isEmpty ? _projectLinkDomain : emailLinkDomain}/sign-in',
    handleCodeInApp: true,
    iOSBundleId: 'com.travary.app',
    androidPackageName: 'com.travary.app',
    androidInstallApp: true,
    // Only a custom domain is named; the project's own is the default.
    linkDomain: emailLinkDomain.isEmpty ? null : emailLinkDomain,
  );

  @override
  Future<void> sendSignInLink(String email) async {
    if (!emailLinks) throw const AuthFailure('Email sign-in isn\'t available yet.');
    await ensureSignedIn();
    try {
      await _auth.sendSignInLinkToEmail(email: email.trim(), actionCodeSettings: _linkSettings);
    } on FirebaseAuthException catch (e) {
      throw _failure(e, SignInMethod.email);
    }
    await _pendingEmail.write(email.trim());
  }

  @override
  Future<String?> pendingEmail() => _pendingEmail.read();

  @override
  bool isSignInLink(String link) => emailLinks && _auth.isSignInWithEmailLink(link);

  @override
  Future<SignInResult> signInWithLink(String link, {String? email}) async {
    final address = email ?? await _pendingEmail.read();
    if (address == null) {
      throw const AuthFailure('Open the link on the phone you asked for it on, or send a new one.');
    }
    await ensureSignedIn();
    final user = _auth.currentUser!;
    final guestToken = user.isAnonymous ? await user.getIdToken() : null;
    try {
      await user.linkWithCredential(EmailAuthProvider.credentialWithLink(email: address, emailLink: link));
      await _pendingEmail.clear();
      await _auth.currentUser?.reload();
      return SignInResult(account: _refresh());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use' || e.code == 'credential-already-in-use') {
        // That address is already Travary's (another phone): switch to it and
        // bring this guest's trips, as for Apple and Google.
        try {
          await _auth.signInWithEmailLink(email: address, emailLink: link);
        } on FirebaseAuthException catch (e) {
          throw _failure(e, SignInMethod.email);
        }
        await _pendingEmail.clear();
        final moved = guestToken == null ? 0 : await _adopt(guestToken);
        return SignInResult(account: _refresh(), switched: true, movedTrips: moved);
      }
      throw _failure(e, SignInMethod.email);
    }
  }

  final _pendingEmail = _PendingEmailFile();

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
    'invalid-action-code' ||
    'expired-action-code' => const AuthFailure('That sign-in link has expired or was already used. Send a new one.'),
    'provider-already-linked' => const AuthFailure('You\'re already signed in with that.'),
    'requires-recent-login' => const AuthFailure('Please sign in again, then try once more.'),
    _ => AuthFailure('Sign-in didn\'t work (${e.code}). Try again.'),
  };

  /// [user] as an [Account].
  static Account accountOf(User user) {
    final methods = {for (final info in user.providerData) ?SignInMethod.fromProviderId(info.providerId)};
    String? first(String? Function(UserInfo) pick) =>
        user.providerData.map(pick).firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    return Account(
      uid: user.uid,
      methods: methods,
      name: (user.displayName?.isNotEmpty ?? false) ? user.displayName : first((i) => i.displayName),
      email: (user.email?.isNotEmpty ?? false) ? user.email : first((i) => i.email),
    );
  }
}

/// The address an email link was sent to, on this phone only, until the link
/// comes back (possibly after the app was closed). Never sent anywhere.
class _PendingEmailFile {
  Future<File> _file() async =>
      File(p.join((await getApplicationSupportDirectory()).path, 'auth', 'pending_email.txt'));

  Future<String?> read() async {
    try {
      final text = (await (await _file()).readAsString()).trim();
      return text.isEmpty ? null : text;
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> write(String email) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(email, flush: true);
  }

  Future<void> clear() async {
    try {
      await (await _file()).delete();
    } on Object catch (_) {}
  }
}
