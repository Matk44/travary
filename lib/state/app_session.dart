import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_service.dart';
import '../data/onboarding_record.dart';
import '../domain/domain.dart';
import '../logic/invite_link.dart';
import 'analytics.dart';

/// Who is using Travary on this phone, and the way to sign in, out or
/// delete the account.
///
/// [uid] keys everything that holds a traveller's data (`TravaryApp`
/// rebuilds the stores when it changes): signing in normally links the
/// guest and keeps the same id, but switching to an existing account,
/// signing out and deleting the account each start on a different one.
class AppSession extends ChangeNotifier {
  AppSession({required this.auth, required String uid, this.onboardingRecord, Stream<Uri>? links}) : _uid = uid {
    _account = auth?.current;
    _subscription = auth?.changes.listen(_changed);
    if (auth != null) {
      _links = links?.listen((link) => unawaited(_openLink(link)));
      unawaited(auth!.pendingEmail().then((email) => _emailLinkSentTo ??= email).then((_) => _notify()));
    }
  }

  /// Null in demo mode: accounts need trips saved to the cloud.
  final AuthService? auth;

  /// Signing in counts as having been through onboarding, on every phone.
  final OnboardingRecord? onboardingRecord;
  StreamSubscription<Account?>? _subscription;
  StreamSubscription<Uri>? _links;
  String _uid;
  Account? _account;
  String? _notice;
  String? _tripToOpenAfterSignIn;
  bool _offerAfterSignIn = false;
  String? _emailLinkSentTo;
  String? _emailLinkError;
  ({String? tripId, bool offer})? _linkHandoff;
  bool _busy = false;
  bool _disposed = false;

  String get uid => _uid;

  /// The current account, once known (null in demo mode).
  Account? get account => _account;
  bool get canSignIn => auth != null;
  bool get isBusy => _busy;

  /// An onboarding holiday whose guest data was adopted by an existing
  /// account. The new navigator opens it after its repository has loaded.
  String? get tripToOpenAfterSignIn => _tripToOpenAfterSignIn;
  String? takeTripToOpenAfterSignIn() {
    final tripId = _tripToOpenAfterSignIn;
    _tripToOpenAfterSignIn = null;
    return tripId;
  }

  /// That holiday's pass desk comes first: the sign-in was onboarding's,
  /// just before its offer.
  bool get offerAfterSignIn => _offerAfterSignIn;
  bool takeOfferAfterSignIn() {
    final offer = _offerAfterSignIn;
    _offerAfterSignIn = false;
    return offer;
  }

  /// Where the last sign-in link went, while it waits to be opened.
  String? get emailLinkSentTo => _emailLinkSentTo;

  /// Why the last sign-in link didn't work (expired, another phone), once.
  String? get emailLinkError => _emailLinkError;

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

  /// Signs in with Apple or Google. Returns what to tell the traveller, or
  /// null when they backed out. Throws [AuthFailure] with a message to show.
  /// [openTripId]: the onboarding holiday to open if this phone switches to
  /// an existing account, after its pass desk when [offer].
  Future<String?> signIn(SignInMethod method, {String? openTripId, bool offer = false}) => _run(() async {
    try {
      final result = await auth!.signIn(method);
      return _signedIn(result, method, openTripId: openTripId, offer: offer);
    } on AuthFailure catch (e) {
      if (e.cancelled) return null;
      rethrow;
    }
  });

  /// Emails [email] a sign-in link. Opening it on this phone finishes
  /// signing in (see [AppSession.new]'s links). Throws [AuthFailure].
  Future<void> sendEmailLink(String email, {String? openTripId, bool offer = false}) => _run(() async {
    _emailLinkError = null;
    await auth!.sendSignInLink(email);
    _emailLinkSentTo = email.trim();
    _linkHandoff = (tripId: openTripId, offer: offer);
    track('email_link_sent');
  });

  /// Forgets the link that's on its way (to use another address).
  void cancelEmailLink() {
    _emailLinkSentTo = null;
    _emailLinkError = null;
    _notify();
  }

  /// The invite code from a link that opened the app
  /// (`travary.app/join/ABC234`), until the home screen takes it to join.
  String? get pendingInviteCode => _pendingInviteCode;
  String? _pendingInviteCode;

  String? takeInviteCode() {
    final code = _pendingInviteCode;
    _pendingInviteCode = null;
    return code;
  }

  Future<void> _openLink(Uri link) async {
    if (inviteCodeFrom(link) case final code?) {
      track('invite_link_opened');
      _pendingInviteCode = code;
      _notify();
      return;
    }
    final text = link.toString();
    if (auth == null || !auth!.isSignInLink(text)) return;
    try {
      await _run(() async {
        _emailLinkError = null;
        final result = await auth!.signInWithLink(text);
        final handoff = _linkHandoff;
        _linkHandoff = null;
        _emailLinkSentTo = null;
        _signedIn(result, SignInMethod.email, openTripId: handoff?.tripId, offer: handoff?.offer ?? false);
      });
    } on AuthFailure catch (e) {
      _emailLinkError = e.message;
      track('email_link_failed');
      _notify();
    } catch (_) {
      _emailLinkError = 'That link didn\'t work. Send a new one and try again.';
      track('email_link_failed');
      _notify();
    }
  }

  String _signedIn(SignInResult result, SignInMethod method, {String? openTripId, bool offer = false}) {
    track('sign_in', {'method': method.name, 'switched': result.switched, 'moved': result.movedTrips});
    _account = result.account;
    // Whoever has signed in skips onboarding on their next phone.
    unawaited(onboardingRecord?.markCompleted(result.account.uid));
    final moved = result.movedTrips;
    final label = method == SignInMethod.email ? 'your email' : method.label;
    final message = result.switched
        ? 'Signed in with $label.${moved > 0 ? ' $moved ${moved == 1 ? 'trip' : 'trips'} from this phone moved to your account.' : ''}'
        : 'Signed in with $label. Your trips are saved to your account.';
    if (result.account.uid != _uid) {
      _tripToOpenAfterSignIn = openTripId;
      _offerAfterSignIn = openTripId != null && offer;
      _notice = message;
      _uid = result.account.uid;
    }
    return message;
  }

  Future<void> signOut() => _run(() async {
    _tripToOpenAfterSignIn = null;
    _offerAfterSignIn = false;
    track('sign_out');
    _notice = 'Signed out. Sign in again to see your trips.';
    await auth!.signOut();
    _syncUid();
  });

  Future<void> deleteAccount() => _run(() async {
    _tripToOpenAfterSignIn = null;
    _offerAfterSignIn = false;
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
    _links?.cancel();
    super.dispose();
  }
}
