import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/sign_in_buttons.dart';
import '../../domain/domain.dart';
import '../../state/app_session.dart';

/// The account on Profile. A guest is invited to sign in with Apple or
/// Google so their trips follow them to any phone; someone signed in sees
/// who they are, and can sign out or delete the account.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final account = session.account;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TravaryColors.paper,
          borderRadius: BorderRadius.circular(TravaryRadius.card),
          boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(TravarySpace.lg),
          child: !session.canSignIn
              ? const _DemoNotice()
              : account == null || account.isGuest
              ? _SignIn(session: session)
              : _SignedIn(session: session, account: account),
        ),
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Your account', style: TravaryText.title),
      const SizedBox(height: TravarySpace.xs),
      Text(
        'Signing in with Apple or Google works with trips saved to the cloud. This is the demo version.',
        style: TravaryText.bodySoft,
      ),
    ],
  );
}

class _SignIn extends StatefulWidget {
  const _SignIn({required this.session});

  final AppSession session;

  @override
  State<_SignIn> createState() => _SignInState();
}

class _SignInState extends State<_SignIn> {
  SignInMethod? _pending;

  Future<void> _signIn(SignInMethod method) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _pending = method);
    try {
      final message = await widget.session.signIn(method);
      // Switching accounts rebuilds the app; the home screen says so.
      if (message != null && mounted) messenger.showSnackBar(SnackBar(content: Text(message)));
    } on AuthFailure catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.session.isBusy;
    final apple = widget.session.supports(SignInMethod.apple)
        ? AppleSignInButton(
            busy: _pending == SignInMethod.apple,
            onPressed: busy ? null : () => _signIn(SignInMethod.apple),
          )
        : null;
    final google = widget.session.supports(SignInMethod.google)
        ? GoogleSignInButton(
            busy: _pending == SignInMethod.google,
            onPressed: busy ? null : () => _signIn(SignInMethod.google),
          )
        : null;
    // Each platform's own sign-in first.
    final buttons = defaultTargetPlatform == TargetPlatform.android ? [?google, ?apple] : [?apple, ?google];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Keep your trips safe', style: TravaryText.title),
        const SizedBox(height: TravarySpace.xs),
        Text(
          'Sign in and your trips and tickets are saved to your account, ready on any phone. '
          'Everything you\'ve added stays as it is.',
          style: TravaryText.bodySoft,
        ),
        const SizedBox(height: TravarySpace.lg),
        for (final (i, button) in buttons.indexed) ...[if (i > 0) const SizedBox(height: TravarySpace.sm), button],
      ],
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.session, required this.account});

  final AppSession session;
  final Account account;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final method = account.methods.contains(SignInMethod.apple) ? SignInMethod.apple : SignInMethod.google;
    final title = account.name ?? account.email ?? 'Signed in';
    final initial = title.characters.first.toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
              child: Text(initial, style: TravaryText.title.copyWith(color: colors.onPrimary)),
            ),
            const SizedBox(width: TravarySpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TravaryText.label.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    [
                      'Signed in with ${method.label}',
                      if (account.email != null && account.email != title) account.email!,
                    ].join(' · '),
                    style: TravaryText.small,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TravarySpace.sm),
        Text('Your trips and tickets are saved to your account.', style: TravaryText.bodySoft),
        const SizedBox(height: TravarySpace.md),
        Wrap(
          spacing: TravarySpace.sm,
          runSpacing: TravarySpace.xs,
          children: [
            OutlinedButton(
              key: const ValueKey('sign-out'),
              onPressed: session.isBusy ? null : () => _signOut(context),
              child: const Text('Sign out'),
            ),
            TextButton(
              key: const ValueKey('delete-account'),
              onPressed: session.isBusy ? null : () => _delete(context),
              style: TextButton.styleFrom(foregroundColor: TravaryColors.coral),
              child: const Text('Delete account'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your trips stay in your account. This phone starts afresh until you sign in again. '
          'Travel documents stay on this phone either way.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) await session.signOut();
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'Trips only you are on are deleted, with their bookings and tickets. Trips you share stay with '
          'the others. This can\'t be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: TravaryColors.coral),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await session.deleteAccount();
    } on AuthFailure catch (e) {
      if (!e.cancelled) messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
