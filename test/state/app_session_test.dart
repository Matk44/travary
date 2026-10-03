import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/auth_service.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/state/app_session.dart';

import '../support/session.dart';

void main() {
  late FakeAuthService auth;
  late AppSession session;

  setUp(() {
    auth = FakeAuthService(email: 'sam@example.com');
    session = AppSession(auth: auth, uid: 'me');
  });

  tearDown(() => session.dispose());

  test('a guest who signs in keeps the same account: nothing to rebuild', () async {
    expect(session.account!.isGuest, isTrue);
    final message = await session.signIn(SignInMethod.apple);
    expect(message, 'Signed in with Apple. Your trips are saved to your account.');
    expect(session.uid, 'me');
    expect(session.account!.methods, {SignInMethod.apple});
    expect(session.takeNotice(), isNull, reason: 'no rebuild, so the card says it');
  });

  test('signing in to an existing account switches to it, bringing the guest\'s trips', () async {
    auth.existing[SignInMethod.google] = 'other';
    auth.guestTrips = 2;
    final message = await session.signIn(SignInMethod.google);
    expect(session.uid, 'other');
    expect(message, 'Signed in with Google. 2 trips from this phone moved to your account.');
    expect(session.takeNotice(), message, reason: 'shown after the app rebuilds');
    expect(session.takeNotice(), isNull, reason: 'once');
  });

  test('backing out says nothing; a failure is shown as is', () async {
    auth.failNext = const AuthFailure.cancelled();
    expect(await session.signIn(SignInMethod.apple), isNull);
    auth.failNext = const AuthFailure('You\'re offline. Connect and try again.');
    await expectLater(session.signIn(SignInMethod.apple), throwsA(isA<AuthFailure>()));
    expect(session.isBusy, isFalse);
    expect(session.account!.isGuest, isTrue);
  });

  test('signing out and deleting start afresh as a new guest', () async {
    await session.signIn(SignInMethod.apple);
    await session.signOut();
    expect(session.uid, 'guest1');
    expect(session.account!.isGuest, isTrue);
    expect(session.takeNotice(), 'Signed out. Sign in again to see your trips.');

    await session.signIn(SignInMethod.google);
    await session.deleteAccount();
    expect(session.uid, 'guest2');
    expect(session.takeNotice(), 'Your account has been deleted.');
    expect(auth.calls, ['signIn:apple', 'signOut', 'signIn:google', 'deleteAccount']);
  });

  test('demo mode has no sign-in', () {
    final demo = AppSession(auth: null, uid: 'demo');
    addTearDown(demo.dispose);
    expect(demo.canSignIn, isFalse);
    expect(demo.supports(SignInMethod.apple), isFalse);
  });
}
