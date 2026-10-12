import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/sharing_service.dart';
import '../../design/tokens.dart';
import '../../logic/invite_link.dart';
import '../../state/analytics.dart';
import '../../state/app_session.dart';
import '../../state/travel_store.dart';
import '../trips/trip_screen.dart';

/// The trip someone joined.
typedef JoinedTrip = ({String tripId, String title});

/// Join a trip someone shared: their invite code (filled in from an invite
/// link) plus your name. Returns the trip once joined.
Future<JoinedTrip?> showJoinTripSheet(BuildContext context, {String? code}) => showModalBottomSheet<JoinedTrip>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: JoinTripSheet(code: code),
  ),
);

/// Asks for an invite code (or uses [code], from a link), joins, says so
/// and opens the trip.
Future<void> startJoinTrip(BuildContext context, {String? code}) async {
  final joined = await showJoinTripSheet(context, code: code);
  if (joined == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You\'ve joined ${joined.title}')));
  openJoinedTrip(context, joined.tripId);
}

/// Opens the trip just joined once it has arrived on this phone (its
/// bookings come down a moment after joining).
Future<void> openJoinedTrip(BuildContext context, String tripId) async {
  final store = context.read<TravelStore>();
  for (var wait = 0; wait < 20 && store.plan(tripId) == null; wait++) {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!context.mounted) return;
  }
  if (store.plan(tripId) == null || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: tripId)));
}

class JoinTripSheet extends StatefulWidget {
  const JoinTripSheet({super.key, this.code});

  /// From an invite link: filled in, so joining is one tap.
  final String? code;

  @override
  State<JoinTripSheet> createState() => _JoinTripSheetState();
}

class _JoinTripSheetState extends State<JoinTripSheet> {
  late final _code = TextEditingController(text: widget.code);
  // The account's name, when signed in.
  late final _name = TextEditingController(text: context.read<AppSession>().account?.name);
  String? _error;
  bool _busy = false;

  String get _cleanCode => normaliseInviteCode(_code.text);
  bool get _ready => _cleanCode.length == inviteCodeLength && _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final joined = await context.read<TravelStore>().joinTrip(_cleanCode, name: _name.text.trim());
      track('trip_joined');
      if (mounted) Navigator.of(context).pop((tripId: joined.tripId, title: joined.title));
    } on SharingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = context.read<TravelStore>().sharingAvailable;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Join a trip', style: TravaryText.headline),
            const SizedBox(height: TravarySpace.xs),
            Text(
              available
                  ? 'Enter the code from your invite to get the plan and tickets on this phone.'
                  : 'Family sharing works with trips saved to the cloud. This is the demo version.',
              style: TravaryText.bodySoft,
            ),
            const SizedBox(height: TravarySpace.lg),
            TextField(
              controller: _code,
              enabled: available,
              // From a link the code is in already: the name is what's left.
              autofocus: available && widget.code == null,
              textCapitalization: TextCapitalization.characters,
              style: TravaryText.title.copyWith(letterSpacing: 4),
              decoration: const InputDecoration(labelText: 'Invite code', hintText: 'ABC 234'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: TravarySpace.md),
            TextField(
              controller: _name,
              enabled: available,
              autofocus: available && widget.code != null && _name.text.isEmpty,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name', hintText: 'How the family will see you'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_ready && !_busy) _join();
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: TravarySpace.md),
              Text(_error!, style: TravaryText.small.copyWith(color: TravaryColors.coral)),
            ],
            const SizedBox(height: TravarySpace.lg),
            FilledButton(
              onPressed: available && _ready && !_busy ? _join : null,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Join trip'),
            ),
          ],
        ),
      ),
    );
  }
}
