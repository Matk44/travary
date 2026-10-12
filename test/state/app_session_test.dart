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

  group('email links', () {
    late StreamController<Uri> links;
    late AppSession linked;
    late MemoryOnboardingRecord record;

    setUp(() {
      links = StreamController<Uri>();
      record = MemoryOnboardingRecord();
      linked = AppSession(auth: auth, uid: 'me', links: links.stream, onboardingRecord: record);
    });

    tearDown(() {
      linked.dispose();
      links.close();
    });

    test('an invite link waits for the home screen to join it, once', () async {
      links.add(Uri.parse('https://travary.app/join/abc-234'));
      await pumpEventQueue();
      expect(linked.pendingInviteCode, 'ABC234');
      expect(auth.calls, isNot(contains('signInWithLink')), reason: 'not a sign-in link');
      expect(linked.takeInviteCode(), 'ABC234');
      expect(linked.takeInviteCode(), isNull);
    });

    test('sending a link waits for it; opening it on this phone signs in', () async {
      await linked.sendEmailLink(' sam@example.com', openTripId: 'holiday', offer: true);
      expect(linked.emailLinkSentTo, 'sam@example.com');
      expect(linked.account!.isGuest, isTrue, reason: 'a sent link isn\'t a sign-in');
      // Links that aren't sign-in links are ignored.
      links.add(Uri.parse('https://elsewhere.test/'));
      await pumpEventQueue();
      expect(auth.calls, isNot(contains('signInWithLink')));
      links.add(Uri.parse('https://links.test/sign-in?oobCode=abc'));
      await pumpEventQueue();
      expect(linked.account!.methods, {SignInMethod.email});
      expect(linked.uid, 'me', reason: 'the guest was linked, so nothing rebuilds');
      expect(linked.emailLinkSentTo, isNull);
      expect(record.completed, {'me'});
    });

    test('a link to an existing account switches to it and carries the holiday to its desk', () async {
      auth.existing[SignInMethod.email] = 'other';
      await linked.sendEmailLink('sam@example.com', openTripId: 'holiday', offer: true);
      links.add(Uri.parse('https://links.test/sign-in?oobCode=abc'));
      await pumpEventQueue();
      expect(linked.uid, 'other');
      expect(linked.takeTripToOpenAfterSignIn(), 'holiday');
      expect(linked.takeOfferAfterSignIn(), isTrue);
      expect(linked.takeNotice(), 'Signed in with your email.');
    });

    test('an expired link, or one from another phone, says so and stays a guest', () async {
      await linked.sendEmailLink('sam@example.com');
      auth.failNext = const AuthFailure('That sign-in link has expired or was already used. Send a new one.');
      links.add(Uri.parse('https://links.test/sign-in?oobCode=old'));
      await pumpEventQueue();
      expect(linked.emailLinkError, contains('expired'));
      expect(linked.account!.isGuest, isTrue);
      expect(linked.emailLinkSentTo, 'sam@example.com', reason: 'they can send it again');
      linked.cancelEmailLink();
      expect(linked.emailLinkSentTo, isNull);
      expect(linked.emailLinkError, isNull);
    });
  });
}
