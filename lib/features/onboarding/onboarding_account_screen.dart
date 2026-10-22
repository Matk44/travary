import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../design/tokens.dart';
import '../../design/widgets/sign_in_buttons.dart';
import '../../domain/domain.dart';
import '../../state/analytics.dart';
import '../../state/app_session.dart';
import '../account/email_sign_in_form.dart';

/// The optional sign-in just before the pass desk ("Keep your holiday with
/// you."), as controls on the stage's floor: Apple, Google or an email and
/// password, or carry on as a guest. The stage shows Travi and the words
/// ([onEmail] switches them to the email branch).
///
/// Signing in links the guest, so the holiday stays as it is
/// ([onSignedIn]). If that account already exists, the app rebuilds for it
/// and `OnboardingGate` opens the same holiday's pass desk instead (see
/// [AppSession.signIn]).
class OnboardingAccountPanel extends StatefulWidget {
  const OnboardingAccountPanel({
    super.key,
    required this.onSignedIn,
    required this.onGuest,
    this.onEmail,
    this.tripId,
    this.hasBooking = false,
  });

  final String? tripId;
  final bool hasBooking;
  final VoidCallback onSignedIn;
  final VoidCallback onGuest;

  /// The email branch opened (true) or closed.
  final ValueChanged<bool>? onEmail;

  @override
  State<OnboardingAccountPanel> createState() => _OnboardingAccountPanelState();
}

class _OnboardingAccountPanelState extends State<OnboardingAccountPanel> {
  late final AppSession _session;
  SignInMethod? _pending;
  String? _error;
  bool _email = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _session = context.read<AppSession>()..addListener(_sessionChanged);
    track('onboarding_account_shown', {'has_booking': widget.hasBooking});
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    super.dispose();
  }

  /// An email confirmed (or an email account signed in to) while the panel
  /// waits (Apple and Google answer through [_signIn] instead).
  void _sessionChanged() {
    if (mounted && !_done && _pending == null && _session.account?.isGuest == false) {
      track('onboarding_account_linked', {'method': SignInMethod.email.name});
      _finish(widget.onSignedIn);
    }
  }

  void _finish(VoidCallback then) {
    _done = true;
    // Never during a build: the stage moves on to the passes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) then();
    });
  }

  void _setEmail(bool email) {
    setState(() => _email = email);
    widget.onEmail?.call(email);
  }

  Future<void> _signIn(SignInMethod method) async {
    if (_pending != null || _session.isBusy || _done) return;
    setState(() {
      _pending = method;
      _error = null;
    });
    track('onboarding_account_started', {'method': method.name});
    try {
      final message = await _session.signIn(method, openTripId: widget.tripId, offer: true);
      if (message == null) {
        track('onboarding_account_cancelled', {'method': method.name});
      } else {
        track('onboarding_account_linked', {'method': method.name});
        // An existing account rebuilds the app, so this panel is gone.
        if (mounted) _finish(widget.onSignedIn);
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
      track('onboarding_account_failed', {'method': method.name});
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Couldn’t sign in. Try again or continue as a guest. Your holiday is saved.');
      }
      track('onboarding_account_failed', {'method': method.name});
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  void _guest() {
    if (_done) return;
    track('onboarding_account_skipped');
    _finish(widget.onGuest);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final busy = _pending != null || session.isBusy || _done;
    final guest = TextButton(
      key: const ValueKey('onboarding-account-skip'),
      onPressed: busy ? null : _guest,
      style: TextButton.styleFrom(
        foregroundColor: OnboardingColors.navy,
        textStyle: TravaryText.body.copyWith(decoration: TextDecoration.underline),
      ),
      child: const Text('Continue as a guest'),
    );
    if (_email) {
      return EmailSignInForm(
        create: true,
        openTripId: widget.tripId,
        offer: true,
        actions: [
          const SizedBox(height: 4),
          TextButton(
            key: const ValueKey('onboarding-account-options'),
            onPressed: busy ? null : () => _setEmail(false),
            style: TextButton.styleFrom(
              foregroundColor: OnboardingColors.navy,
              textStyle: TravaryText.body.copyWith(decoration: TextDecoration.underline),
            ),
            child: const Text('Back to sign-in options'),
          ),
          guest,
        ],
      );
    }
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
        ? EmailSignInButton(onPressed: busy ? null : () => _setEmail(true))
        : null;
    // Each platform's own sign-in comes first.
    final providers = defaultTargetPlatform == TargetPlatform.android ? [?google, ?apple] : [?apple, ?google];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        guest,
        Text(
          'Signing in is free. Your bookings stay with you either way.',
          textAlign: TextAlign.center,
          style: TravaryText.small.copyWith(color: OnboardingColors.navy),
        ),
      ],
    );
  }
}
