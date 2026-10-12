import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../design/tokens.dart';
import '../../design/widgets/ledger.dart';
import '../../state/app_session.dart';

final _address = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Passwordless email sign-in: one address, a link sent to it, then waiting
/// for that link to open the app on this phone ([AppSession] finishes it).
/// Sending a link isn't signing in, so nothing here claims it has.
class EmailLinkForm extends StatefulWidget {
  const EmailLinkForm({super.key, this.openTripId, this.offer = false, this.actions = const []});

  /// The onboarding holiday, carried across a switch to an existing account
  /// (see [AppSession.signIn]).
  final String? openTripId;
  final bool offer;

  /// Ways out under the form ("Back to sign-in options", "Continue as a guest").
  final List<Widget> actions;

  @override
  State<EmailLinkForm> createState() => _EmailLinkFormState();
}

class _EmailLinkFormState extends State<EmailLinkForm> {
  final _email = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send(String email) async {
    if (_sending || !_address.hasMatch(email.trim())) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context.read<AppSession>().sendEmailLink(email, openTripId: widget.openTripId, offer: widget.offer);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn’t send the link. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final sentTo = session.emailLinkSentTo;
    final error = _error ?? (sentTo == null ? null : session.emailLinkError);
    final valid = _address.hasMatch(_email.text.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sentTo == null) ...[
          Text('Email address', style: TravaryText.label.copyWith(color: OnboardingColors.navy)),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('email-link-field'),
            controller: _email,
            enabled: !_sending,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.send,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            onSubmitted: _send,
            style: TravaryText.body.copyWith(color: OnboardingColors.navy),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              filled: true,
              fillColor: OnboardingColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TravaryRadius.small),
                borderSide: const BorderSide(color: OnboardingColors.navy, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TravaryRadius.small),
                borderSide: const BorderSide(color: OnboardingColors.navy, width: 1.5),
              ),
            ),
          ),
          if (error != null) ...[const SizedBox(height: 10), _Message(error)],
          const SizedBox(height: 14),
          TicketButton(
            key: const ValueKey('email-link-send'),
            label: 'Email me a sign-in link',
            busy: _sending,
            onPressed: valid ? () => _send(_email.text) : null,
          ),
          const SizedBox(height: 8),
          Text(
            'No password to remember.',
            textAlign: TextAlign.center,
            style: TravaryText.small.copyWith(color: OnboardingColors.navy),
          ),
        ] else ...[
          Text(
            'We sent a link to $sentTo. Open it on this phone and you’re in.',
            key: const ValueKey('email-link-sent'),
            textAlign: TextAlign.center,
            style: TravaryText.body.copyWith(color: OnboardingColors.navy),
          ),
          if (session.isBusy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ],
          if (error != null) ...[const SizedBox(height: 10), _Message(error)],
          const SizedBox(height: 14),
          OutlinedButton(
            key: const ValueKey('email-link-resend'),
            onPressed: _sending || session.isBusy ? null : () => _send(sentTo),
            style: OutlinedButton.styleFrom(
              foregroundColor: OnboardingColors.navy,
              side: const BorderSide(color: OnboardingColors.navy, width: 1.5),
              minimumSize: const Size.fromHeight(48),
            ),
            child: _sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Send it again'),
          ),
          TextButton(
            key: const ValueKey('email-link-change'),
            onPressed: _sending || session.isBusy ? null : session.cancelEmailLink,
            style: TextButton.styleFrom(foregroundColor: OnboardingColors.navy),
            child: const Text('Use a different email'),
          ),
        ],
        ...widget.actions,
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: OnboardingColors.cream, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TravaryText.small.copyWith(color: OnboardingColors.coralInk)),
    ),
  );
}
