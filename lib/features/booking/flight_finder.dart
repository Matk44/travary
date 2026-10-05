import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/flight_status_service.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/departure_board.dart';
import '../../design/widgets/ledger.dart';
import '../../domain/domain.dart';
import '../../logic/flight_fill.dart';
import '../../logic/formatters.dart';
import '../../state/analytics.dart';

/// Adding a flight starts here: the flight number and the day it leaves,
/// typed into a departures board. Once typing pauses on a whole flight
/// number the board looks it up and flips the flight into place (number,
/// route, departure time); "Use this flight" fills in the ticket from the
/// airline's schedule. "Enter flight manually" goes straight to the ticket.
class FlightFinder extends StatefulWidget {
  const FlightFinder({
    super.key,
    required this.service,
    required this.number,
    required this.date,
    required this.onPickDate,
    required this.onUse,
    required this.onManual,
  });

  final FlightStatusService service;

  /// The form's flight number field.
  final TextEditingController number;

  /// The day it leaves (the form's start date).
  final LocalDate date;
  final VoidCallback onPickDate;
  final ValueChanged<FlightFill> onUse;
  final VoidCallback onManual;

  @override
  State<FlightFinder> createState() => _FlightFinderState();
}

/// Waits for typing to pause before asking the server.
const _typingPause = Duration(milliseconds: 700);

class _FlightFinderState extends State<FlightFinder> {
  Timer? _timer;

  /// "BA283|2026-11-08": the search shown (or under way).
  String? _key;
  bool _searching = false;
  List<FlightStatus>? _legs;
  String? _error;

  /// Which leg is chosen when one number flies several that day.
  int _chosen = 0;

  String? get _number => cleanFlightNumber(widget.number.text);
  String? _keyFor(String? number) => number == null ? null : '$number|${widget.date.toIso()}';

  @override
  void initState() {
    super.initState();
    widget.number.addListener(_changed);
    _changed();
  }

  @override
  void didUpdateWidget(FlightFinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      oldWidget.number.removeListener(_changed);
      widget.number.addListener(_changed);
    }
    if (oldWidget.date != widget.date) _changed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.number.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final number = _number;
    final key = _keyFor(number);
    if (key == _key) return;
    _timer?.cancel();
    setState(() {
      _key = key;
      _legs = null;
      _error = null;
      _chosen = 0;
      _searching = number != null;
    });
    if (number != null) _timer = Timer(_typingPause, () => _search(number, widget.date, key!));
  }

  Future<void> _search(String number, LocalDate date, String key) async {
    try {
      final legs = await widget.service.find(flightNumber: number, date: date);
      if (!mounted || key != _key) return;
      setState(() => _legs = legs);
    } on FlightStatusException catch (e) {
      if (mounted && key == _key) setState(() => _error = e.message);
    } finally {
      if (mounted && key == _key) setState(() => _searching = false);
    }
  }

  FlightStatus? get _found {
    final legs = _legs;
    if (_searching || legs == null || legs.isEmpty) return null;
    return legs[_chosen.clamp(0, legs.length - 1)];
  }

  void _use() {
    final leg = _found;
    if (leg == null) return;
    final fill = flightFill(leg, typedNumber: widget.number.text.trim());
    if (fill == null) return;
    track('flight_filled');
    widget.onUse(fill);
  }

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final found = _found;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DepartureBoard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const BoardLabel('FLIGHT NUMBER'),
                        const SizedBox(height: 6),
                        BoardInput(
                          child: TextField(
                            key: const ValueKey('flight-number-field'),
                            controller: widget.number,
                            autofocus: true,
                            textCapitalization: TextCapitalization.characters,
                            style: TravaryText.ticketDate.copyWith(fontSize: 19, color: colors.ink),
                            decoration: const InputDecoration(
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: 'BA 283',
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TravarySpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const BoardLabel('DEPARTURE DATE'),
                        const SizedBox(height: 6),
                        BoardInput(
                          key: const ValueKey('flight-date'),
                          onTap: widget.onPickDate,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatDate(widget.date),
                              style: TravaryText.ticketDate.copyWith(fontSize: 17, color: colors.ink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TravarySpace.lg),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: TravarySpace.lg),
              _status(found),
            ],
          ),
        ),
        const SizedBox(height: TravarySpace.md),
        if (found != null)
          Padding(
            padding: const EdgeInsets.only(bottom: TravarySpace.sm),
            child: Text('Details stay editable', textAlign: TextAlign.center, style: TravaryText.small),
          ),
        TicketButton(
          key: const ValueKey('use-flight'),
          label: 'Use this flight',
          onPressed: found == null ? null : _use,
        ),
        const SizedBox(height: TravarySpace.xs),
        Center(
          child: TextButton(
            key: const ValueKey('enter-flight-manually'),
            onPressed: widget.onManual,
            style: TextButton.styleFrom(foregroundColor: colors.ink, textStyle: TravaryText.body),
            child: const Text('Enter flight manually'),
          ),
        ),
      ],
    );
  }

  Widget _status(FlightStatus? found) {
    final typed = _number;
    final day = formatDayShort(widget.date);
    final caption = TravaryText.small.copyWith(color: Colors.white.withValues(alpha: 0.78));
    Widget column(List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);

    if (typed == null) {
      return column([
        const BoardLabel('FLIGHT'),
        const SizedBox(height: 10),
        FlapText('------', color: Colors.white.withValues(alpha: 0.35)),
        const SizedBox(height: 10),
        Text('Type the flight number from your booking and the day it leaves.', style: caption),
      ]);
    }
    if (_searching) {
      return column([
        const BoardLabel('SEARCHING'),
        const SizedBox(height: 10),
        FlapText(typed),
        const SizedBox(height: 10),
        Text('Looking for $typed on $day…', style: caption),
      ]);
    }
    if (_error != null) {
      return column([const BoardLabel('BOARD UNAVAILABLE'), const SizedBox(height: 10), Text(_error!, style: caption)]);
    }
    final legs = _legs ?? const [];
    if (found == null) {
      return column([
        const BoardLabel('NOT FOUND', color: TravaryColors.coral),
        const SizedBox(height: 10),
        const FlapText('NO FLIGHT', color: TravaryColors.coral),
        const SizedBox(height: 10),
        Text('No $typed found on $day. Check the number and date, or enter it yourself.', style: caption),
      ]);
    }
    final board = boardTextFor(found, typedNumber: typed);
    Widget route(BoardText text, {double size = 24}) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text.from, style: TravaryText.boardRoute.copyWith(fontSize: size)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: size),
          ),
          Text(text.to, style: TravaryText.boardRoute.copyWith(fontSize: size)),
        ],
      ),
    );
    return column([
      const BoardLabel('FLIGHT FOUND'),
      const SizedBox(height: 10),
      FlapText(board.flight),
      const SizedBox(height: 14),
      if (legs.length > 1)
        for (final (index, leg) in legs.take(3).indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: TravarySpace.sm),
            child: BoardStrip(
              key: ValueKey('flight-leg-$index'),
              selected: index == _chosen,
              onTap: () => setState(() => _chosen = index),
              child: route(boardTextFor(leg, typedNumber: typed), size: 18),
            ),
          )
      else
        BoardStrip(child: route(board)),
      if (board.departs != null) ...[const SizedBox(height: 14), FlapText(board.departs!)],
      if (board.lands != null) ...[const SizedBox(height: 10), Text(board.lands!, style: caption)],
    ]);
  }
}
