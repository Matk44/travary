import 'package:flutter_test/flutter_test.dart';
import 'package:travary/logic/invite_link.dart';

void main() {
  test('an invite is a link with its code', () {
    expect(inviteLinkFor('abc 234').toString(), 'https://travary.app/join/ABC234');
  });

  test('the code comes out of an invite link, however it was typed or shared', () {
    expect(inviteCodeFrom(Uri.parse('https://travary.app/join/ABC234')), 'ABC234');
    expect(inviteCodeFrom(Uri.parse('https://www.travary.app/join/abc234/')), 'ABC234');
    expect(inviteCodeFrom(Uri.parse('https://travary.app/join/ABC-234?utm=x')), 'ABC234');
  });

  test('anything else isn\'t an invite', () {
    expect(inviteCodeFrom(Uri.parse('https://travary.app/guides/')), isNull);
    expect(inviteCodeFrom(Uri.parse('https://travary.app/join/ABC')), isNull, reason: 'too short');
    expect(inviteCodeFrom(Uri.parse('https://elsewhere.test/join/ABC234')), isNull);
    expect(inviteCodeFrom(Uri.parse('https://travary.app/join/ABC234/extra')), isNull);
    expect(inviteCodeFrom(Uri.parse('https://travary-444.firebaseapp.com/__/auth/action?oobCode=x')), isNull);
  });

  test('the message carries the link and the code', () {
    final message = inviteMessage(tripTitle: 'Orlando', code: 'ABC234');
    expect(message, contains('https://travary.app/join/ABC234'));
    expect(message, contains('ABC234'));
    expect(message, startsWith('Join our Orlando trip on Travary'));
  });
}
