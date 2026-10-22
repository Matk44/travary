import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_service.dart';
import '../data/onboarding_record.dart';
import '../domain/domain.dart';
import '../logic/countdown_widget.dart';
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
    _links = links?.listen((link) => unawaited(_openLink(link)));
    _askIfConfirmed();
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
  bool _askedIfConfirmed = false;
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
    final confirmed =
        _account?.unconfirmedEmail != null &&
        _account!.uid == account.uid &&
        account.methods.contains(SignInMethod.email);
    _account = account;
    if (confirmed) _emailConfirmed(account);
    _askIfConfirmed();
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

  /// Signs in with an email and password, or [create]s an account with
  /// them. Returns what to tell the traveller, or null while a new address
  /// waits to be confirmed ([Account.unconfirmedEmail]: the account stays a
  /// guest until its link is opened, see [checkEmailConfirmed]). Throws
  /// [AuthFailure]. [openTripId] and [offer] as for [signIn].
  Future<String?> signInWithEmail(
    String email,
    String password, {
    bool create = false,
    String? openTripId,
    bool offer = false,
  }) => _run(() async {
    final result = create
        ? await auth!.createWithPassword(email.trim(), password)
        : await auth!.signInWithPassword(email.trim(), password);
    if (create) track('email_account_created', {'switched': result.switched});
    if (!result.switched && result.account.isGuest) return null;
    return _signedIn(result, SignInMethod.email, openTripId: openTripId, offer: offer);
  });

  /// Whether the address waiting to be confirmed has been (its link opened,
  /// on this phone or any other). Cheap enough to ask every few seconds
  /// while the traveller waits.
  Future<bool> checkEmailConfirmed() async {
    if (auth == null || _account?.unconfirmedEmail == null) return false;
    final account = await auth!.refresh();
    if (account != null) _changed(account);
    return account?.methods.contains(SignInMethod.email) ?? false;
  }

  /// Emails the link that confirms the address again. Throws [AuthFailure].
  Future<void> resendEmailConfirmation() => _run(() async {
    await auth!.sendEmailConfirmation();
    track('email_confirmation_sent');
  });

  /// Emails [email] a link to choose a new password. Throws [AuthFailure].
  Future<void> sendPasswordReset(String email) => _run(() async {
    await auth!.sendPasswordReset(email.trim());
    track('password_reset_sent');
  });

  /// An address may have been confirmed while the app was closed: asked
  /// once, when the account is first known.
  void _askIfConfirmed() {
    if (_askedIfConfirmed || _account?.unconfirmedEmail == null) return;
    _askedIfConfirmed = true;
    unawaited(checkEmailConfirmed());
  }

  /// The address was confirmed: now it's a sign-in, on every phone.
  void _emailConfirmed(Account account) {
    track('sign_in', {'method': SignInMethod.email.name, 'switched': false, 'moved': 0});
    unawaited(onboardingRecord?.markCompleted(account.uid));
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

  /// What a tap on the home-screen countdown widget opens, until the home
  /// screen takes it: the trip it showed, or `''` for Today.
  String? get pendingWidgetTarget => _pendingWidgetTarget;
  String? _pendingWidgetTarget;

  String? takeWidgetTarget() {
    final target = _pendingWidgetTarget;
    _pendingWidgetTarget = null;
    return target;
  }

  Future<void> _openLink(Uri link) async {
    if (countdownWidgetTarget(link) case final target?) {
      track('countdown_widget_opened');
      _pendingWidgetTarget = target;
      _notify();
      return;
    }
    // Invites need an account (cloud mode).
    if (auth == null) return;
    if (inviteCodeFrom(link) case final code?) {
      track('invite_link_opened');
      _pendingInviteCode = code;
      _notify();
    }
  }

  String _signedIn(SignInResult result, SignInMethod method, {String? openTripId, bool offer = false}) {
    track('sign_in', {'method': method.name, 'switched': result.switched, 'moved': result.movedTrips});
    _account = result.account;
    // Whoever has signed in skips onboarding on their next phone; an email
    // counts once it's confirmed (see [_emailConfirmed]).
    final waiting = result.account.unconfirmedEmail;
    if (waiting == null) unawaited(onboardingRecord?.markCompleted(result.account.uid));
    final moved = result.movedTrips;
    final label = method == SignInMethod.email ? 'your email' : method.label;
    final trips = moved > 0 ? ' $moved ${moved == 1 ? 'trip' : 'trips'} from this phone moved to your account.' : '';
    final message = waiting != null
        ? 'Nearly there: tap the link we sent to $waiting to finish signing in.$trips'
        : result.switched
        ? 'Signed in with $label.$trips'
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
