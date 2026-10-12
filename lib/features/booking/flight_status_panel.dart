import 'package:flutter/material.dart';

import '../../data/flight_status_service.dart';
import '../../design/tokens.dart';
import '../../design/widgets/departure_board.dart';
import '../../design/widgets/live_flight_strip.dart';
import '../../domain/domain.dart';
import '../../logic/flight_status_text.dart';

/// A flight's live status on its own page: gate, terminal, check-in desk,
/// baggage belt and delays, checked when the page opens and on refresh.
class FlightStatusPanel extends StatefulWidget {
  const FlightStatusPanel({super.key, required this.service, required this.lookup, required this.now});

  final FlightStatusService service;
  final FlightLookup lookup;
  final DateTime Function() now;

  @override
  State<FlightStatusPanel> createState() => _FlightStatusPanelState();
}

class _FlightStatusPanelState extends State<FlightStatusPanel> {
  FlightStatus? _status;
  bool _notFound = false;
  String? _error;
  bool _loading = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FlightStatusPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lookup != widget.lookup) {
      _status = null;
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lookup = widget.lookup;
      final status = await widget.service.lookUp(
        flightNumber: lookup.flightNumber,
        date: lookup.date,
        from: lookup.from,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _status = status;
        _notFound = status == null;
      });
    } on FlightStatusException catch (e) {
      if (mounted && request == _request) setState(() => _error = e.message);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final text = status == null ? null : describeFlightStatus(status, widget.now());
    final caption = TravaryText.small.copyWith(color: Colors.white.withValues(alpha: 0.78));
    return Padding(
      key: const ValueKey('flight-status'),
      padding: const EdgeInsets.only(top: TravarySpace.md),
      child: DepartureBoard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: BoardLabel((text?.title ?? 'Live status · ${widget.lookup.flightNumber}').toUpperCase()),
                ),
                SizedBox(
                  width: 40,
                  height: 32,
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Check again',
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          onPressed: _load,
                        ),
                ),
              ],
            ),
            const SizedBox(height: TravarySpace.sm),
            switch ((text, _error)) {
              (final FlightStatusText text, _) => _Status(text: text, gate: status!.departure.gate),
              (null, final String error) => Text(error, style: caption),
              _ when _notFound => Text(
                '${widget.lookup.flightNumber} isn\'t showing yet. The airline usually adds the gate and '
                'times on the day.',
                style: caption,
              ),
              _ => Text('Checking ${widget.lookup.flightNumber}…', style: caption),
            },
            if (text != null && _error != null) ...[
              const SizedBox(height: TravarySpace.sm),
              Text(_error!, style: caption),
            ],
          ],
        ),
      ),
    );
  }
}

/// The status on the board: the headline with its colour dot, the gate on
/// flap tiles when there is one, then both ends and how fresh it is.
class _Status extends StatelessWidget {
  const _Status({required this.text, this.gate});

  final FlightStatusText text;
  final String? gate;

  @override
  Widget build(BuildContext context) {
    final caption = TravaryText.small.copyWith(color: Colors.white.withValues(alpha: 0.78));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BoardLabel('STATUS'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: flightToneColour(text.tone), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: TravarySpace.sm),
                      Flexible(child: Text(text.headline, style: TravaryText.boardRoute.copyWith(fontSize: 22))),
                    ],
                  ),
                ],
              ),
            ),
            if (gate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BoardLabel('GATE'),
                  const SizedBox(height: 6),
                  FlapText(gate!, tile: const Size(28, 40)),
                ],
              ),
          ],
        ),
        const SizedBox(height: TravarySpace.lg),
        _End(text: text.departure),
        const SizedBox(height: TravarySpace.md),
        _End(text: text.arrival),
        const SizedBox(height: TravarySpace.md),
        Text(text.checked, style: caption),
      ],
    );
  }
}

class _End extends StatelessWidget {
  const _End({required this.text});

  final FlightEndText text;

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.72);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.title, style: TravaryText.small.copyWith(color: soft)),
        if (text.time != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: text.time,
                  style: TravaryText.label.copyWith(fontSize: 17, color: Colors.white),
                ),
                if (text.was != null)
                  TextSpan(
                    text: '  ${text.was}',
                    style: TravaryText.small.copyWith(color: soft, decoration: TextDecoration.lineThrough),
                  ),
              ],
            ),
          ),
        if (text.details != null) Text(text.details!, style: TravaryText.body.copyWith(color: Colors.white)),
      ],
    );
  }
}
