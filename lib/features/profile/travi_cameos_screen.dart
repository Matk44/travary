import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../design/widgets/travi_cameo.dart';
import '../../design/widgets/travi_clip_player.dart';
import '../../logic/travi_cameos.dart';

/// Design tools (debug builds): every Travi cameo as the app shows it, live,
/// to judge them without reaching each screen (a real Smart Import, an
/// empty account, a sync error, the right number of days to go).
class TraviCameosScreen extends StatefulWidget {
  const TraviCameosScreen({super.key});

  @override
  State<TraviCameosScreen> createState() => _TraviCameosScreenState();
}

class _TraviCameosScreenState extends State<TraviCameosScreen> {
  static const _where = {
    TraviMoment.reading: 'Smart Import, while it reads',
    TraviMoment.waiting: 'Empty Today and Trips',
    TraviMoment.oops: 'Smart Import failed, nothing found',
  };

  static const _peeks = {
    TraviPeek.wave: 'The first countdown of the day; the New trip sheet',
    TraviPeek.cheer: 'Tag tapped 15+ days out; a new trip saved',
    TraviPeek.packing: 'Tag tapped 4 to 14 days out',
    TraviPeek.ready: 'Tag tapped 2 or 3 days out',
    TraviPeek.today: 'Tag tapped the day before',
  };

  TraviPeek _peek = TraviPeek.wave;
  int _cue = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Travi cameos')),
    body: ListView(
      padding: const EdgeInsets.only(bottom: TravarySpace.xxl),
      children: [
        const SectionLabel('Peeks'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
          child: Wrap(
            spacing: TravarySpace.sm,
            runSpacing: TravarySpace.sm,
            children: [
              for (final peek in TraviPeek.values)
                ChoiceChip(
                  label: Text(peek.name),
                  selected: peek == _peek,
                  onSelected: (_) => setState(() {
                    _peek = peek;
                    _cue++;
                  }),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, TravarySpace.sm, TravarySpace.gutter, 0),
          child: Text(_peeks[_peek]!, style: TravaryText.bodySoft),
        ),
        // From behind a paper card, as on the countdown.
        Padding(
          padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 120, TravarySpace.gutter, 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: TravarySpace.xl,
                top: TraviCameoLayout.planSink - TraviCameoLayout.peekSize,
                width: TraviCameoLayout.peekSize,
                height: TraviCameoLayout.peekSize,
                child: TraviClipPlayer(script: traviPeekScript(_peek), cue: _cue),
              ),
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: TravaryColors.paper,
                  borderRadius: BorderRadius.circular(TravaryRadius.card),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))],
                ),
                alignment: Alignment.center,
                child: Text('Tap a peek above', style: TravaryText.bodySoft),
              ),
            ],
          ),
        ),
        const SectionLabel('Free day · tap him to sip'),
        const Center(child: TraviLounge()),
        for (final moment in TraviMoment.values) ...[
          SectionLabel('${moment.name} · ${moment.moves ? 'moves' : 'still'}'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
            child: Text(_where[moment]!, style: TravaryText.bodySoft),
          ),
          const SizedBox(height: TravarySpace.md),
          Center(child: TraviCameo(moment: moment)),
        ],
        const SectionLabel('Sync error'),
        Center(
          child: OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: TraviMessage(moment: TraviMoment.oops, text: 'Couldn\'t sync a change (unavailable).'),
              ),
            ),
            child: const Text('Show the snackbar'),
          ),
        ),
      ],
    ),
  );
}
