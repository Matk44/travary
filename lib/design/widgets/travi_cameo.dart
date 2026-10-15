import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../logic/onboarding_films.dart';
import '../../logic/travi_cameos.dart';
import '../tokens.dart';
import 'travi_clip_player.dart';
import 'travi_player.dart';

/// Travi making a cameo outside onboarding ([TraviMoment]): his key frame
/// on the onboarding camera, cropped to where he stands, so he's on the
/// same mark in every pose. He loops his idle only where the moment moves.
class TraviCameo extends StatelessWidget {
  const TraviCameo({super.key, required this.moment, this.height, this.close = false});

  final TraviMoment moment;

  /// Null: as tall as the screen allows, smaller on a short phone so what
  /// he sits above still fits.
  final double? height;

  /// Closer in, on him alone (the folio beside him left out): for small
  /// places like a snackbar.
  final bool close;

  /// Where he stands on [traviCanvas] (canvas px): handle to floor shadow,
  /// with the folio beside him.
  static const _window = Rect.fromLTRB(0, 296, 540, 700);
  static const _closeWindow = Rect.fromLTRB(180, 296, 490, 700);

  /// [height] when it's null: 72 points on a 568-point screen up to 132 on
  /// an 844-point one and taller.
  static double fittedHeight(Size screen) => lerpDouble(72, 132, ((screen.height - 568) / (844 - 568)).clamp(0, 1))!;

  @override
  Widget build(BuildContext context) {
    final window = close ? _closeWindow : _window;
    final height = this.height ?? fittedHeight(MediaQuery.sizeOf(context));
    final k = height / window.height;
    return SizedBox(
      width: window.width * k,
      height: height,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -window.left * k,
              top: -window.top * k,
              width: traviCanvas.width * k,
              height: traviCanvas.height * k,
              child: TraviPlayer(cues: [(pose: moment.pose, hold: Duration.zero, direct: false)], moves: moment.moves),
            ),
          ],
        ),
      ),
    );
  }
}

/// A short message with Travi beside it, for a snackbar: "Couldn't sync a
/// change" with his sheepish shrug.
class TraviMessage extends StatelessWidget {
  const TraviMessage({super.key, required this.moment, required this.text});

  final TraviMoment moment;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      TraviCameo(moment: moment, height: 52, close: true),
      const SizedBox(width: TravarySpace.md),
      Expanded(child: Text(text)),
    ],
  );
}

/// A free day: Travi lounging in his deckchair. He takes one slow sip when
/// [greet] says he may (at most once a day, never with reduced motion), and
/// another whenever he's tapped; otherwise he holds still.
class TraviLounge extends StatefulWidget {
  const TraviLounge({super.key, this.greet, this.height});

  final Future<bool> Function()? greet;

  /// Null: as for [TraviCameo], a little larger.
  final double? height;

  @override
  State<TraviLounge> createState() => _TraviLoungeState();
}

class _TraviLoungeState extends State<TraviLounge> {
  static const _sip = [TraviPlay(traviLoungeSip)];
  int _cue = 0;
  bool _sipping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.greet == null || MediaQuery.disableAnimationsOf(context)) return;
      if (await widget.greet!() && mounted) _sipAgain();
    });
  }

  void _sipAgain() {
    if (_sipping) return;
    setState(() {
      _sipping = true;
      _cue++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.height ?? TraviCameo.fittedHeight(MediaQuery.sizeOf(context)) * 1.25;
    return GestureDetector(
      key: const ValueKey('travi-lounge'),
      onTap: _sipAgain,
      child: SizedBox.square(
        dimension: size,
        child: TraviClipPlayer(script: _sip, cue: _cue, rest: traviLoungeStill, onDone: () => _sipping = false),
      ),
    );
  }
}

/// Travi popping up once from behind whatever lies under his square's
/// bottom edge (a sheet's top, a panel), as soon as he's shown: [peek], then
/// he stays up, or ducks back down if [duck].
///
/// With [sign] ([TraviPeek.today], staying up), the blank card he holds
/// carries those words once he's up: the prop becomes live UI, as in
/// onboarding.
class TraviPopUp extends StatefulWidget {
  const TraviPopUp({super.key, required this.peek, this.duck = false, this.sign});

  final TraviPeek peek;
  final bool duck;
  final String? sign;

  @override
  State<TraviPopUp> createState() => _TraviPopUpState();
}

class _TraviPopUpState extends State<TraviPopUp> {
  bool _up = false;

  @override
  Widget build(BuildContext context) {
    final sign = widget.sign;
    final player = TraviClipPlayer(
      playOnStart: true,
      script: traviPeekScript(widget.peek, duck: widget.duck, delay: TraviCameoLayout.popUpDelay),
      onDone: sign == null
          ? null
          : () {
              if (mounted) setState(() => _up = true);
            },
    );
    if (sign == null) return IgnorePointer(child: player);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final k = box.maxWidth / traviCameoCanvas;
          const card = traviTodayCard;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: player),
              Positioned(
                left: (card.x - card.width / 2) * k,
                top: (card.y - card.height / 2) * k,
                width: card.width * k,
                height: card.height * k,
                child: Transform.rotate(
                  angle: card.turnDegrees * math.pi / 180,
                  child: AnimatedOpacity(
                    opacity: _up ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: FittedBox(
                      key: const ValueKey('travi-sign'),
                      fit: BoxFit.scaleDown,
                      child: Text(sign, style: TravaryText.traviSign),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
