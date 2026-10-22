import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/auth_service.dart';
import 'package:travary/data/onboarding_record.dart';
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

  test('an adopted onboarding holiday crosses the navigator rebuild only once', () async {
    auth.existing[SignInMethod.google] = 'other';
    await session.signIn(SignInMethod.google, openTripId: 'actual-holiday');
    expect(session.tripToOpenAfterSignIn, 'actual-holiday');
    expect(session.takeTripToOpenAfterSignIn(), 'actual-holiday');
    expect(session.takeTripToOpenAfterSignIn(), isNull);
  });

  test('linking a guest or cancelling auth never queues a different-account holiday', () async {
    auth.failNext = const AuthFailure.cancelled();
    await session.signIn(SignInMethod.apple, openTripId: 'holiday');
    expect(session.tripToOpenAfterSignIn, isNull);
    await session.signIn(SignInMethod.apple, openTripId: 'holiday');
    expect(session.uid, 'me');
    expect(session.tripToOpenAfterSignIn, isNull);
  });

  test('signing out clears an unconsumed onboarding holiday', () async {
    auth.existing[SignInMethod.google] = 'other';
    await session.signIn(SignInMethod.google, openTripId: 'holiday');
    await session.signOut();
    expect(session.tripToOpenAfterSignIn, isNull);
  });

  test('signing in, linked or switched, means onboarding is done for that account everywhere', () async {
    final record = MemoryOnboardingRecord();
    final recorded = AppSession(auth: auth, uid: 'me', onboardingRecord: record);
    addTearDown(recorded.dispose);
    auth.failNext = const AuthFailure.cancelled();
    await recorded.signIn(SignInMethod.apple);
    expect(record.completed, isEmpty, reason: 'backing out isn\'t signing in');
    await recorded.signIn(SignInMethod.apple);
    expect(record.completed, {'me'});
    auth.existing[SignInMethod.google] = 'other';
    await recorded.signIn(SignInMethod.google);
    expect(record.completed, {'me', 'other'});
  });

  test('onboarding\'s sign-in queues its holiday\'s pass desk across a switch, once', () async {
    auth.existing[SignInMethod.google] = 'other';
    await session.signIn(SignInMethod.google, openTripId: 'holiday', offer: true);
    expect(session.offerAfterSignIn, isTrue);
    expect(session.takeOfferAfterSignIn(), isTrue);
    expect(session.takeOfferAfterSignIn(), isFalse);
    expect(session.takeTripToOpenAfterSignIn(), 'holiday');
  });

  group('links', () {
    late StreamController<Uri> links;
    late AppSession linked;

    setUp(() {
      links = StreamController<Uri>();
      linked = AppSession(auth: auth, uid: 'me', links: links.stream);
    });

    tearDown(() {
      linked.dispose();
      links.close();
    });

    test('an invite link waits for the home screen to join it, once', () async {
      links.add(Uri.parse('https://travary.app/join/abc-234'));
      await pumpEventQueue();
      expect(linked.pendingInviteCode, 'ABC234');
      expect(linked.takeInviteCode(), 'ABC234');
      expect(linked.takeInviteCode(), isNull);
    });
  });

  group('email and password', () {
    late MemoryOnboardingRecord record;
    late AppSession emailed;

    setUp(() {
      record = MemoryOnboardingRecord();
      emailed = AppSession(auth: auth, uid: 'me', onboardingRecord: record);
    });

    tearDown(() => emailed.dispose());

    test('a new account waits for its address to be confirmed; then it signs in, once', () async {
      final message = await emailed.signInWithEmail(' sam@example.com', 'long enough', create: true);
      expect(message, isNull, reason: 'not signed in until the address is confirmed');
      expect(emailed.account!.isGuest, isTrue);
      expect(emailed.account!.unconfirmedEmail, 'sam@example.com');
      expect(emailed.uid, 'me', reason: 'the guest itself gets the email: nothing rebuilds');
      expect(record.completed, isEmpty);

      expect(await emailed.checkEmailConfirmed(), isFalse, reason: 'the link isn\'t opened yet');
      expect(emailed.account!.isGuest, isTrue);

      auth.linkOpened = true;
      expect(await emailed.checkEmailConfirmed(), isTrue);
      expect(emailed.account!.methods, {SignInMethod.email});
      expect(emailed.account!.email, 'sam@example.com');
      expect(emailed.account!.unconfirmedEmail, isNull);
      expect(record.completed, {'me'}, reason: 'confirmed, it skips onboarding on another phone');
      expect(await emailed.checkEmailConfirmed(), isFalse, reason: 'nothing waits any more');
    });

    test('an address confirmed while the app was closed is noticed when it starts', () async {
      await emailed.signInWithEmail('sam@example.com', 'long enough', create: true);
      auth.linkOpened = true;
      final reopened = AppSession(auth: auth, uid: 'me', onboardingRecord: record);
      addTearDown(reopened.dispose);
      await pumpEventQueue();
      expect(reopened.account!.methods, {SignInMethod.email});
      expect(record.completed, {'me'});
    });

    test('signing in to an existing account switches to it and carries the holiday to its desk', () async {
      auth.emailAccounts['sam@example.com'] = (uid: 'other', password: 'secret', confirmed: true);
      auth.guestTrips = 2;
      final message = await emailed.signInWithEmail('sam@example.com', 'secret', openTripId: 'holiday', offer: true);
      expect(message, 'Signed in with your email. 2 trips from this phone moved to your account.');
      expect(emailed.uid, 'other');
      expect(emailed.takeTripToOpenAfterSignIn(), 'holiday');
      expect(emailed.takeOfferAfterSignIn(), isTrue);
      expect(emailed.takeNotice(), message);
      expect(record.completed, {'other'});
    });

    test('creating an account for an address that has one signs in with its password', () async {
      auth.emailAccounts['sam@example.com'] = (uid: 'other', password: 'secret', confirmed: true);
      await expectLater(
        emailed.signInWithEmail('sam@example.com', 'not the one', create: true),
        throwsA(isA<AuthFailure>().having((e) => e.message, 'message', contains('already has a Travary account'))),
      );
      expect(emailed.uid, 'me');
      await emailed.signInWithEmail('sam@example.com', 'secret', create: true);
      expect(emailed.uid, 'other');
    });

    test('an account never confirmed switches, but is still a guest until its link is opened', () async {
      auth.emailAccounts['sam@example.com'] = (uid: 'other', password: 'secret', confirmed: false);
      final message = await emailed.signInWithEmail('sam@example.com', 'secret');
      expect(message, 'Nearly there: tap the link we sent to sam@example.com to finish signing in.');
      expect(emailed.uid, 'other', reason: 'the phone is on that account now, so the app rebuilds');
      expect(emailed.account!.isGuest, isTrue);
      expect(record.completed, isEmpty);
    });

    test('a wrong password says so and leaves the guest as it was', () async {
      await expectLater(emailed.signInWithEmail('sam@example.com', 'guess'), throwsA(isA<AuthFailure>()));
      expect(emailed.uid, 'me');
      expect(emailed.account!.isGuest, isTrue);
      expect(emailed.isBusy, isFalse);
    });

    test('a new link and a password reset are only ever asked for', () async {
      await emailed.resendEmailConfirmation();
      await emailed.sendPasswordReset('sam@example.com');
      expect(auth.calls, containsAll(['sendEmailConfirmation', 'sendPasswordReset:sam@example.com']));
      expect(emailed.account!.isGuest, isTrue);
    });
  });
}
