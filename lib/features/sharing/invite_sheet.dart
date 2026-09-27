import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/sharing_service.dart';
import '../../design/tokens.dart';
import '../../domain/domain.dart';
import '../../logic/formatters.dart';
import '../../logic/trip_plan.dart';
import '../../state/analytics.dart';
import '../../state/travel_store.dart';

/// Invite the family: a six-character code to share by message. Asks for
/// the inviter's name first time, so the family knows who it's from.
Future<void> showInviteSheet(BuildContext context, TripPlan plan) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: InviteSheet(plan: plan),
      ),
    );

class InviteSheet extends StatefulWidget {
  const InviteSheet({super.key, required this.plan});

  final TripPlan plan;

  @override
  State<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<InviteSheet> {
  late final TravelStore _store = context.read<TravelStore>();
  late final _name = TextEditingController(
    text: widget.plan.trip.memberNames[_store.userId],
  );
  TripInvite? _invite;
  String? _error;
  bool _busy = false;

  bool get _needsName => widget.plan.trip.memberNames[_store.userId] == null;

  @override
  void initState() {
    super.initState();
    if (!_needsName) _create();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final name = _name.text.trim();
      final invite = await _store.createInvite(
        widget.plan,
        name: name.isEmpty ? null : name,
      );
      track('invite_created', {'members': widget.plan.trip.memberIds.length});
      if (mounted) setState(() => _invite = invite);
    } on SharingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(TripInvite invite) async {
    track('invite_shared');
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Join our ${widget.plan.trip.title} trip',
        text:
            'Join our ${widget.plan.trip.title} trip on Travary! '
            'Open Travary, tap Trips, then "Join a trip", and enter the code ${invite.code}. '
            'You\'ll have the plan and tickets on your phone.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invite = _invite;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TravarySpace.gutter,
          0,
          TravarySpace.gutter,
          TravarySpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Invite the family', style: TravaryText.headline),
            const SizedBox(height: TravarySpace.xs),
            Text(
              'Everyone gets ${widget.plan.trip.title} on their own phone: the plan, the updates and their tickets.',
              style: TravaryText.bodySoft,
            ),
            const SizedBox(height: TravarySpace.lg),
            if (invite == null && _needsName) ...[
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  hintText: 'So the family knows who invited them',
                ),
                onSubmitted: (_) => _create(),
              ),
              const SizedBox(height: TravarySpace.md),
              FilledButton(
                onPressed: _busy ? null : _create,
                child: const Text('Create invite'),
              ),
            ] else if (invite == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(TravarySpace.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _CodeCard(code: invite.code),
              const SizedBox(height: TravarySpace.sm),
              Text(
                'Works until ${formatDate(LocalDate.fromDateTime(invite.expiresAt))}. '
                'Anyone with the code can see this trip and its tickets.',
                style: TravaryText.small,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TravarySpace.lg),
              FilledButton.icon(
                onPressed: () => _share(invite),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share invite'),
              ),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: invite.code));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Code copied')));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy code'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: TravarySpace.md),
              Text(
                _error!,
                style: TravaryText.small.copyWith(color: TravaryColors.coral),
                textAlign: TextAlign.center,
              ),
              if (!_needsName)
                TextButton(
                  onPressed: _busy ? null : _create,
                  child: const Text('Try again'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The code, big and spaced like a ticket number.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Invite code ${code.split('').join(' ')}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: TravarySpace.xl),
        decoration: BoxDecoration(
          color: TravaryColors.paper,
          borderRadius: BorderRadius.circular(TravaryRadius.card),
          border: Border.all(color: TravaryColors.line),
        ),
        child: Column(
          children: [
            Text('INVITE CODE', style: TravaryText.eyebrow),
            const SizedBox(height: TravarySpace.sm),
            Text(
              '${code.substring(0, 3)} ${code.substring(3)}',
              style: TravaryText.display.copyWith(letterSpacing: 6),
            ),
          ],
        ),
      ),
    );
  }
}
