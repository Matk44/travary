import 'package:flutter/material.dart';

import '../../logic/flight_status_text.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'departure_board.dart';

/// The colour of a flight's status dot: fine, worth a look, bad, or quiet.
Color flightToneColour(FlightTone tone) => switch (tone) {
  FlightTone.good => TravaryColors.sage,
  FlightTone.notice => TravaryColors.mustard,
  FlightTone.bad => TravaryColors.coral,
  FlightTone.neutral => Colors.white54,
};

/// A flight's live state under its card on Today, while flight alerts
/// watch it: a slip of the departures board tucked under the ticket, its
/// status dot and the line ("Delayed 45 min · Leaves 10:15am · Gate 12").
class LiveFlightStrip extends StatelessWidget {
  const LiveFlightStrip({super.key, required this.line});

  final LiveFlightLine line;

  /// How far in from the card's sides the slip sits.
  static const inset = 14.0;

  @override
  Widget build(BuildContext context) {
    final ink = TravaryChrome.of(context).colors.ink;
    return Semantics(
      label: 'Flight status: ${line.text}',
      excludeSemantics: true,
      child: Padding(
        key: const ValueKey('live-flight-strip'),
        padding: const EdgeInsets.symmetric(horizontal: inset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DepartureBoard.panelColor(ink),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10), top: Radius.circular(3)),
            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Centred on the first line.
                Padding(
                  padding: const EdgeInsets.only(top: 3.5),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: flightToneColour(line.tone), shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 8),
                // A long delay with a gate takes a second line on a small phone.
                Expanded(
                  child: Text(line.text, style: TravaryText.liveLine, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
