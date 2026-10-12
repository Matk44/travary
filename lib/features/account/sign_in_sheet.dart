import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../design/tokens.dart';
import '../../design/widgets/sign_in_buttons.dart';
import '../../domain/domain.dart';
import '../../state/app_session.dart';
import 'email_link_form.dart';

/// Signing in from a sheet: Apple, Google or an email link. Returns what to
/// tell the traveller once this guest is linked, or null if they backed out.
/// Switching to an existing account rebuilds the app instead, so nothing
/// comes back here then.
Future<String?> showSignInSheet(BuildContext context, {bool email = false}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: OnboardingColors.floor,
  builder: (_) => _SignInSheet(startWithEmail: email),
);

class _SignInSheet extends StatefulWidget {
  const _SignInSheet({required this.startWithEmail});
  final bool startWithEmail;
  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  late final AppSession _session;
  late bool _email = widget.startWithEmail;
  SignInMethod? _pending;
  String? _error;

  @override
  void initState() {
    super.initState();
    _session = context.read<AppSession>()..addListener(_sessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    super.dispose();
  }

  /// The email link was opened while the sheet waited.
  void _sessionChanged() {
    if (mounted && _pending == null && _session.account?.isGuest == false) {
      Navigator.of(context).pop('Signed in with your email.');
    }
  }

  Future<void> _signIn(SignInMethod method) async {
    if (_pending != null || _session.isBusy) return;
    setState(() {
      _pending = method;
      _error = null;
    });
    try {
      final message = await _session.signIn(method);
      if (message != null && mounted) Navigator.of(context).pop(message);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn’t sign in. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final busy = _pending != null || session.isBusy;
    final apple = session.supports(SignInMethod.apple)
        ? AppleSignInButton(
            busy: _pending == SignInMethod.apple,
            onPressed: busy ? null : () => _signIn(SignInMethod.apple),
          )
        : null;
    final google = session.supports(SignInMethod.google)
        ? GoogleSignInButton(
            busy: _pending == SignInMethod.google,
            onPressed: busy ? null : () => _signIn(SignInMethod.google),
          )
        : null;
    final email = session.supports(SignInMethod.email)
        ? EmailSignInButton(onPressed: busy ? null : () => setState(() => _email = true))
        : null;
    final providers = defaultTargetPlatform == TargetPlatform.android ? [?google, ?apple] : [?apple, ?google];
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _email ? 'Sign in with email' : 'Welcome back',
              textAlign: TextAlign.center,
              style: TravaryText.title.copyWith(color: OnboardingColors.navy),
            ),
            const SizedBox(height: 6),
            Text(
              _email
                  ? 'We’ll email you a link. Open it on this phone.'
                  : 'Sign in the way you did before, and your plans come with you.',
              textAlign: TextAlign.center,
              style: TravaryText.body.copyWith(color: OnboardingColors.navy),
            ),
            const SizedBox(height: 20),
            if (_email)
              EmailLinkForm(
                actions: [
                  if (!widget.startWithEmail)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              session.cancelEmailLink();
                              setState(() => _email = false);
                            },
                      style: TextButton.styleFrom(foregroundColor: OnboardingColors.navy),
                      child: const Text('Back to sign-in options'),
                    ),
                ],
              )
            else ...[
              if (_error != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TravaryText.body.copyWith(color: OnboardingColors.coralInk),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              for (final button in [...providers, ?email]) ...[button, const SizedBox(height: 10)],
            ],
          ],
        ),
      ),
    );
  }
}
