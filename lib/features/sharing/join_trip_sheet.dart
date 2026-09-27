import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/sharing_service.dart';
import '../../design/tokens.dart';
import '../../state/analytics.dart';
import '../../state/travel_store.dart';

/// Join a trip someone shared: their invite code plus your name.
/// Returns the trip's title once joined.
Future<String?> showJoinTripSheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const JoinTripSheet(),
      ),
    );

class JoinTripSheet extends StatefulWidget {
  const JoinTripSheet({super.key});

  @override
  State<JoinTripSheet> createState() => _JoinTripSheetState();
}

class _JoinTripSheetState extends State<JoinTripSheet> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  String? _error;
  bool _busy = false;

  String get _cleanCode =>
      _code.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  bool get _ready => _cleanCode.length == 6 && _name.text.trim().isNotEmpty;

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
      final joined = await context.read<TravelStore>().joinTrip(
        _cleanCode,
        name: _name.text.trim(),
      );
      track('trip_joined');
      if (mounted) Navigator.of(context).pop(joined.title);
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
              autofocus: available,
              textCapitalization: TextCapitalization.characters,
              style: TravaryText.title.copyWith(letterSpacing: 4),
              decoration: const InputDecoration(
                labelText: 'Invite code',
                hintText: 'ABC 234',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: TravarySpace.md),
            TextField(
              controller: _name,
              enabled: available,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your name',
                hintText: 'How the family will see you',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_ready && !_busy) _join();
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: TravarySpace.md),
              Text(
                _error!,
                style: TravaryText.small.copyWith(color: TravaryColors.coral),
              ),
            ],
            const SizedBox(height: TravarySpace.lg),
            FilledButton(
              onPressed: available && _ready && !_busy ? _join : null,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join trip'),
            ),
          ],
        ),
      ),
    );
  }
}
