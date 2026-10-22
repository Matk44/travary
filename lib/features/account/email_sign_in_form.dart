import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../design/tokens.dart';
import '../../design/widgets/ledger.dart';
import '../../state/app_session.dart';

final _address = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// The shortest password a new account takes, as Firebase's password policy
/// asks (docs/EMAIL_SIGN_IN.md).
const minPasswordLength = 8;

enum _Mode { signIn, create, reset }

/// Email sign-in: an address and password for an existing account, a new
/// account, or a link to choose a new password. A new account's address is
/// confirmed by the link Firebase emails, opened on any device; until then
/// the account is still a guest, so nothing here says it's signed in.
class EmailSignInForm extends StatefulWidget {
  const EmailSignInForm({super.key, this.create = false, this.openTripId, this.offer = false, this.actions = const []});

  /// Starts on a new account rather than signing in.
  final bool create;

  /// The onboarding holiday, carried across a switch to an existing account
  /// (see [AppSession.signIn]).
  final String? openTripId;
  final bool offer;

  /// Ways out under the form ("Back to sign-in options", "Continue as a guest").
  final List<Widget> actions;

  @override
  State<EmailSignInForm> createState() => _EmailSignInFormState();
}

class _EmailSignInFormState extends State<EmailSignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late var _mode = widget.create ? _Mode.create : _Mode.signIn;
  bool _sending = false;
  bool _hidden = true;

  /// "Use a different email" while one waits to be confirmed.
  bool _changing = false;
  String? _error;
  String? _resetSentTo;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _valid =>
      _address.hasMatch(_email.text.trim()) &&
      (_mode == _Mode.reset ||
          (_mode == _Mode.create ? _password.text.length >= minPasswordLength : _password.text.isNotEmpty));

  void _setMode(_Mode mode) => setState(() {
    _mode = mode;
    _error = null;
    _resetSentTo = null;
  });

  /// Runs [action], showing what went wrong under the form.
  Future<void> _send(Future<void> Function(AppSession session) action, String fallback) async {
    if (_sending || !_valid) return;
    final session = context.read<AppSession>();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await action(session);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = fallback);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() => _send((session) async {
    await session.signInWithEmail(
      _email.text,
      _password.text,
      create: _mode == _Mode.create,
      openTripId: widget.openTripId,
      offer: widget.offer,
    );
    // The phone offers to save the password (and, new, suggested a strong one).
    TextInput.finishAutofillContext();
    if (mounted) {
      setState(() {
        _changing = false;
        _password.clear();
      });
    }
  }, 'Couldn’t sign in. Check your connection and try again.');

  Future<void> _reset() => _send((session) async {
    await session.sendPasswordReset(_email.text);
    if (mounted) setState(() => _resetSentTo = _email.text.trim());
  }, 'Couldn’t send the link. Check your connection and try again.');

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final waiting = session.account?.unconfirmedEmail;
    final body = waiting != null && !_changing
        ? _Confirming(
            email: waiting,
            onChange: () => setState(() {
              _changing = true;
              _mode = _Mode.create;
              _error = null;
              _email.clear();
              _password.clear();
            }),
          )
        : _mode == _Mode.reset
        ? _resetForm()
        : _form(session);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [body, ...widget.actions]);
  }

  Widget _form(AppSession session) {
    final create = _mode == _Mode.create;
    final busy = _sending || session.isBusy;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Label('Email address'),
          const SizedBox(height: 8),
          _Field(
            key: const ValueKey('email-field'),
            controller: _email,
            enabled: !busy,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _Label(create ? 'Choose a password' : 'Password'),
          const SizedBox(height: 8),
          _Field(
            key: const ValueKey('password-field'),
            controller: _password,
            enabled: !busy,
            obscure: _hidden,
            autofillHints: [create ? AutofillHints.newPassword : AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              key: const ValueKey('password-show'),
              tooltip: _hidden ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _hidden = !_hidden),
              icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              color: OnboardingColors.navy,
            ),
          ),
          if (create) ...[
            const SizedBox(height: 6),
            Text(
              'At least $minPasswordLength characters.',
              style: TravaryText.small.copyWith(color: OnboardingColors.navy),
            ),
          ],
          if (_error != null) ...[const SizedBox(height: 10), _Message(_error!)],
          const SizedBox(height: 14),
          TicketButton(
            key: const ValueKey('email-submit'),
            label: create ? 'Create account' : 'Sign in',
            busy: _sending,
            onPressed: _valid && !busy ? _submit : null,
          ),
          if (!create)
            _Link(
              key: const ValueKey('email-forgot'),
              label: 'Forgot your password?',
              onPressed: busy ? null : () => _setMode(_Mode.reset),
            ),
          _Link(
            key: const ValueKey('email-mode'),
            label: create ? 'Have an account? Sign in' : 'New here? Create an account',
            onPressed: busy ? null : () => _setMode(create ? _Mode.signIn : _Mode.create),
          ),
        ],
      ),
    );
  }

  Widget _resetForm() {
    final sentTo = _resetSentTo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sentTo == null) ...[
          Text(
            'Enter your email and we’ll send a link to choose a new password.',
            textAlign: TextAlign.center,
            style: TravaryText.body.copyWith(color: OnboardingColors.navy),
          ),
          const SizedBox(height: 14),
          _Label('Email address'),
          const SizedBox(height: 8),
          _Field(
            key: const ValueKey('email-field'),
            controller: _email,
            enabled: !_sending,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _reset(),
          ),
          if (_error != null) ...[const SizedBox(height: 10), _Message(_error!)],
          const SizedBox(height: 14),
          TicketButton(
            key: const ValueKey('email-reset-send'),
            label: 'Email me a link',
            busy: _sending,
            onPressed: _valid && !_sending ? _reset : null,
          ),
        ] else ...[
          Text(
            'If $sentTo has a Travary account, a link to choose a new password is on its way. '
            'Then sign in here with the new one.',
            key: const ValueKey('email-reset-sent'),
            textAlign: TextAlign.center,
            style: TravaryText.body.copyWith(color: OnboardingColors.navy),
          ),
          const SizedBox(height: 8),
          const _SpamHint(),
        ],
        _Link(
          key: const ValueKey('email-reset-back'),
          label: 'Back to sign in',
          onPressed: _sending ? null : () => _setMode(_Mode.signIn),
        ),
      ],
    );
  }
}

/// A new account waiting for its address to be confirmed: it checks by
/// itself while shown (and as the app comes back from Mail), and on a tap.
class _Confirming extends StatefulWidget {
  const _Confirming({required this.email, required this.onChange});

  final String email;
  final VoidCallback onChange;

  @override
  State<_Confirming> createState() => _ConfirmingState();
}

class _ConfirmingState extends State<_Confirming> {
  bool _checking = false;
  bool _sending = false;
  String? _message;

  /// [_message] says it was sent again, not what went wrong.
  bool _sent = false;

  Future<void> _check() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _message = null;
      _sent = false;
    });
    final confirmed = await context.read<AppSession>().checkEmailConfirmed();
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (!confirmed) _message = 'Not confirmed yet. Tap the link in the email first, then come back.';
    });
  }

  Future<void> _resend() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _message = null;
      _sent = false;
    });
    try {
      await context.read<AppSession>().resendEmailConfirmation();
      if (mounted) {
        setState(() {
          _message = 'Sent again to ${widget.email}.';
          _sent = true;
        });
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'Couldn’t send it. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _checking || _sending || context.watch<AppSession>().isBusy;
    return EmailConfirmationWatch(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'We sent a link to ${widget.email}. Tap it to confirm it’s you, then come back: you’ll be signed in.',
            key: const ValueKey('email-confirm-sent'),
            textAlign: TextAlign.center,
            style: TravaryText.body.copyWith(color: OnboardingColors.navy),
          ),
          const SizedBox(height: 8),
          const _SpamHint(),
          if (_message != null) ...[const SizedBox(height: 10), _Message(_message!, error: !_sent)],
          const SizedBox(height: 14),
          TicketButton(
            key: const ValueKey('email-confirm-check'),
            label: 'I’ve tapped the link',
            busy: _checking,
            onPressed: busy ? null : _check,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('email-confirm-resend'),
            onPressed: busy ? null : _resend,
            style: OutlinedButton.styleFrom(
              foregroundColor: OnboardingColors.navy,
              side: const BorderSide(color: OnboardingColors.navy, width: 1.5),
              minimumSize: const Size.fromHeight(48),
            ),
            child: _sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Send it again'),
          ),
          _Link(
            key: const ValueKey('email-confirm-change'),
            label: 'Use a different email',
            onPressed: busy ? null : widget.onChange,
          ),
        ],
      ),
    );
  }
}

/// Asks whether the waiting address has been confirmed while [child] is
/// shown: every few seconds for a while, and whenever the app comes back
/// (from Mail, most likely).
class EmailConfirmationWatch extends StatefulWidget {
  const EmailConfirmationWatch({super.key, required this.child});

  final Widget child;

  /// How often it asks, and for how long after it's shown.
  static const every = Duration(seconds: 5);
  static const asks = 120;

  @override
  State<EmailConfirmationWatch> createState() => _EmailConfirmationWatchState();
}

class _EmailConfirmationWatchState extends State<EmailConfirmationWatch> with WidgetsBindingObserver {
  late final AppSession _session;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _session = context.read<AppSession>();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(EmailConfirmationWatch.every, (timer) {
      if (timer.tick >= EmailConfirmationWatch.asks) timer.cancel();
      unawaited(_session.checkEmailConfirmed());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_session.checkEmailConfirmed());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: TravaryText.label.copyWith(color: OnboardingColors.navy));
}

class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.enabled,
    required this.autofillHints,
    required this.textInputAction,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final List<String> autofillHints;
  final TextInputAction textInputAction;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(TravaryRadius.small),
      borderSide: const BorderSide(color: OnboardingColors.navy, width: 1.5),
    );
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: obscure ? TextInputType.visiblePassword : keyboardType,
      obscureText: obscure,
      autofillHints: autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: textInputAction,
      inputFormatters: obscure ? null : [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      onSubmitted: onSubmitted,
      style: TravaryText.body.copyWith(color: OnboardingColors.navy),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: OnboardingColors.cream,
        suffixIcon: suffix,
        border: border,
        enabledBorder: border,
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(foregroundColor: OnboardingColors.navy),
    child: Text(label),
  );
}

class _SpamHint extends StatelessWidget {
  const _SpamHint();
  @override
  Widget build(BuildContext context) => Text(
    'Can’t find it? It can take a minute. Look in spam or junk too.',
    textAlign: TextAlign.center,
    style: TravaryText.small.copyWith(color: OnboardingColors.navy),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.error = true});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: OnboardingColors.cream, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TravaryText.small.copyWith(color: error ? OnboardingColors.coralInk : OnboardingColors.navy),
      ),
    ),
  );
}
