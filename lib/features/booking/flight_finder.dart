import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/flight_status_service.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/departure_board.dart';
import '../../domain/domain.dart';
import '../../logic/flight_fill.dart';
import '../../logic/formatters.dart';
import '../../state/analytics.dart';

/// The top of a new flight's ticket: the flight number and the day it
/// leaves, typed into a departures board. Once typing pauses on a whole
/// flight number the board looks it up, flips the flight into place
/// (number, route, departure time) and hands it to the ticket below
/// ([onFound]), which fills in what the traveller hasn't typed. Nothing
/// waits on it: the ticket can be filled in by hand all along.
class FlightFinder extends StatefulWidget {
  const FlightFinder({
    super.key,
    required this.service,
    required this.number,
    required this.date,
    required this.today,
    required this.onPickDate,
    required this.onFound,
  });

  final FlightStatusService service;

  /// The form's flight number field.
  final TextEditingController number;

  /// The day it leaves, as searched.
  final LocalDate date;

  /// Today, to tell a date the schedule doesn't reach yet ([flightLookupDaysAhead]).
  final LocalDate today;
  final VoidCallback onPickDate;

  /// The flight on the board for the ticket: the chosen leg once found,
  /// null once it's gone (another number, nothing found). Never called
  /// while building, and not for a new date: whoever changed it knows.
  final ValueChanged<FlightFill?> onFound;

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

  /// The date is further ahead than the schedule goes: nothing was asked.
  bool _tooFar = false;
  List<FlightStatus>? _legs;
  String? _error;

  /// Which leg is chosen when one number flies several that day.
  int _chosen = 0;

  /// A flight was handed to the ticket and is still on the board.
  bool _handed = false;

  String? get _number => cleanFlightNumber(widget.number.text);
  String? _keyFor(String? number) => number == null ? null : '$number|${widget.date.toIso()}';

  @override
  void initState() {
    super.initState();
    widget.number.addListener(_typed);
    _changed();
  }

  @override
  void didUpdateWidget(FlightFinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      oldWidget.number.removeListener(_typed);
      widget.number.addListener(_typed);
    }
    if (oldWidget.date != widget.date || oldWidget.today != widget.today) _changed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.number.removeListener(_typed);
    super.dispose();
  }

  /// A new number takes the last flight off the ticket.
  void _typed() {
    final handed = _handed;
    if (_changed() && handed) _hand(null);
  }

  void _hand(FlightFill? fill) {
    _handed = fill != null;
    widget.onFound(fill);
  }

  /// Starts a new search when the number or date changed; true if so.
  bool _changed() {
    final number = _number;
    final key = _keyFor(number);
    if (key == _key) return false;
    _timer?.cancel();
    _handed = false;
    final reaches = flightLookupReaches(widget.date, today: widget.today);
    setState(() {
      _key = key;
      _legs = null;
      _error = null;
      _chosen = 0;
      _tooFar = number != null && !reaches;
      _searching = number != null && reaches;
    });
    if (number != null && reaches) _timer = Timer(_typingPause, () => _search(number, widget.date, key!));
    return true;
  }

  Future<void> _search(String number, LocalDate date, String key) async {
    try {
      final legs = await widget.service.find(flightNumber: number, date: date);
      if (!mounted || key != _key) return;
      setState(() {
        _legs = legs;
        _searching = false;
      });
      _handFound();
    } on FlightStatusException catch (e) {
      if (mounted && key == _key) setState(() => _error = e.message);
    } finally {
      if (mounted && key == _key && _searching) setState(() => _searching = false);
    }
  }

  FlightStatus? get _found {
    final legs = _legs;
    if (_searching || legs == null || legs.isEmpty) return null;
    return legs[_chosen.clamp(0, legs.length - 1)];
  }

  /// The chosen leg to the ticket, worded as the airline's schedule has it.
  void _handFound() {
    final leg = _found;
    final fill = leg == null ? null : flightFill(leg, typedNumber: widget.number.text.trim());
    if (fill == null && !_handed) return;
    if (fill != null) track('flight_filled');
    _hand(fill);
  }

  void _choose(int index) {
    if (index == _chosen) return;
    setState(() => _chosen = index);
    _handFound();
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
        Text('Type the flight number from your booking and we\'ll fill in the ticket below.', style: caption),
      ]);
    }
    if (_tooFar) {
      return column([
        const BoardLabel('SCHEDULE NOT OUT YET'),
        const SizedBox(height: 10),
        FlapText(typed),
        const SizedBox(height: 10),
        Text(flightTooFarAheadText(typed, day), style: caption),
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
        Text('No $typed found on $day. Check the number and date, or fill in the ticket yourself.', style: caption),
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
              onTap: () => _choose(index),
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
