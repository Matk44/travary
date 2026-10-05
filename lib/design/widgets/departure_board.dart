import 'package:flutter/material.dart';

import '../tokens.dart';
import '../trip_chrome.dart';

/// Finding a flight as an airport's departures board (C2): a panel in the
/// trip's ink with rivets in its corners, white boxes to type into, and
/// split-flap characters that flip into place when the flight is found.
/// Drawn, so text stays crisp and takes the trip's palette.
class DepartureBoard extends StatelessWidget {
  const DepartureBoard({super.key, required this.child});

  final Widget child;

  /// The board's panel: the trip's ink, a shade deeper.
  static Color panelColor(Color ink) => Color.lerp(ink, Colors.black, 0.18)!;

  /// A split-flap tile: deeper again.
  static Color tileColor(Color ink) => Color.lerp(ink, Colors.black, 0.5)!;

  @override
  Widget build(BuildContext context) {
    final ink = TravaryChrome.of(context).colors.ink;
    return DecoratedBox(
      key: const ValueKey('departure-board'),
      decoration: BoxDecoration(
        color: panelColor(ink),
        borderRadius: BorderRadius.circular(LedgerLayout.panelRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.35), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Stack(
        children: [
          // An inner bevel, just inside the edge.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LedgerLayout.panelRadius - 4),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
              ),
            ),
          ),
          for (final corner in [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
            Positioned.fill(
              child: Align(
                alignment: corner,
                child: const Padding(padding: EdgeInsets.all(9), child: _Rivet()),
              ),
            ),
          Padding(padding: const EdgeInsets.fromLTRB(22, 20, 22, 22), child: child),
        ],
      ),
    );
  }
}

class _Rivet extends StatelessWidget {
  const _Rivet();

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: [Colors.white.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.4)],
      ),
    ),
  );
}

/// A board's small-caps label: "FLIGHT NUMBER", "FLIGHT FOUND".
class BoardLabel extends StatelessWidget {
  const BoardLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TravaryText.boardLabel.copyWith(color: color ?? Colors.white.withValues(alpha: 0.72)));
}

/// A white box on the board to type into, or to tap (the date).
class BoardInput extends StatelessWidget {
  const BoardInput({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: TravaryChrome.of(context).colors.paper,
    borderRadius: BorderRadius.circular(6),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ),
    ),
  );
}

/// A ruled strip on the board: the route, "Sydney → Tokyo".
class BoardStrip extends StatelessWidget {
  const BoardStrip({super.key, required this.child, this.selected = false, this.onTap});

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: selected ? 0.10 : 0.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: BorderSide(color: Colors.white.withValues(alpha: selected ? 0.55 : 0.22)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: child),
    ),
  );
}

/// Characters on split-flap tiles: "QF 25", "20:55". When the text changes
/// each tile flips to its new character, a moment after its left-hand
/// neighbour. A space is a gap, a colon a narrow tile. Scales down to fit.
class FlapText extends StatelessWidget {
  const FlapText(this.text, {super.key, this.color, this.tile = LedgerLayout.flapTile});

  final String text;

  /// The characters' colour (white by default; coral for "NO FLIGHT").
  final Color? color;
  final Size tile;

  @override
  Widget build(BuildContext context) {
    final ink = TravaryChrome.of(context).colors.ink;
    final characters = text.characters.toList();
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, character) in characters.indexed)
              if (character == ' ')
                SizedBox(width: tile.width * 0.45)
              else
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _FlapTile(
                    character: character,
                    delay: LedgerLayout.flapStagger * index,
                    size: character == ':' ? Size(tile.width * 0.5, tile.height) : tile,
                    tileColor: DepartureBoard.tileColor(ink),
                    color: color ?? Colors.white,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _FlapTile extends StatefulWidget {
  const _FlapTile({
    required this.character,
    required this.delay,
    required this.size,
    required this.tileColor,
    required this.color,
  });

  final String character;
  final Duration delay;
  final Size size;
  final Color tileColor;
  final Color color;

  @override
  State<_FlapTile> createState() => _FlapTileState();
}

class _FlapTileState extends State<_FlapTile> {
  late String _shown = widget.character;

  @override
  void didUpdateWidget(_FlapTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character == widget.character) return;
    final reduced = MediaQuery.of(context).disableAnimations;
    if (reduced || widget.delay == Duration.zero) {
      _shown = widget.character;
    } else {
      final next = widget.character;
      Future.delayed(widget.delay, () {
        if (mounted && widget.character == next) setState(() => _shown = next);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    final face = SizedBox(
      key: ValueKey(_shown),
      width: widget.size.width,
      height: widget.size.height,
      child: Center(
        child: Text(
          _shown,
          style: TravaryText.boardFlap.copyWith(color: widget.color, fontSize: widget.size.height * 0.62),
        ),
      ),
    );
    return Container(
      width: widget.size.width,
      height: widget.size.height,
      decoration: BoxDecoration(
        color: _shown == ':' ? Colors.transparent : widget.tileColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: _shown == ':'
            ? null
            : const [BoxShadow(color: Color(0x40000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: reduced ? Duration.zero : LedgerLayout.flapDuration,
            // The new character drops down over the old, like a flap.
            transitionBuilder: (child, animation) =>
                SizeTransition(sizeFactor: animation, axisAlignment: -1, child: child),
            child: face,
          ),
          if (_shown != ':') Container(height: 1, color: Colors.black.withValues(alpha: 0.45)),
        ],
      ),
    );
  }
}
