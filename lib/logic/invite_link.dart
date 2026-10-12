// Family invites as links: `https://travary.app/join/ABC234`. Tapping one
// opens Travary straight onto joining that trip (a universal link on iOS,
// an App Link on Android); without the app, the page shows the code and
// how to get the app. The six-character code still works on its own.

/// Where invite links live (the site's `/join` page and the app's link
/// association files are built by `website/build.py`).
const inviteLinkHost = 'travary.app';

/// The link that invites someone with [code].
Uri inviteLinkFor(String code) => Uri.https(inviteLinkHost, '/join/${normaliseInviteCode(code)}');

/// The invite code in [link], or null when it isn't an invite link.
String? inviteCodeFrom(Uri link) {
  if (link.scheme != 'https' && link.scheme != 'http') return null;
  if (link.host != inviteLinkHost && link.host != 'www.$inviteLinkHost') return null;
  final segments = link.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 2 || segments.first != 'join') return null;
  final code = normaliseInviteCode(segments.last);
  return code.length == inviteCodeLength ? code : null;
}

const inviteCodeLength = 6;

/// A code as typed or pasted ("abc 234", "ABC-234"): letters and digits,
/// upper case.
String normaliseInviteCode(String text) => text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// The invite message to send: the link, and the code for anyone who
/// already has the app open.
String inviteMessage({required String tripTitle, required String code}) =>
    'Join our $tripTitle trip on Travary, with the plan and your tickets on your phone: '
    '${inviteLinkFor(code)} (invite code $code)';
