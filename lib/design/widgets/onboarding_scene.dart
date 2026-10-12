import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../../logic/onboarding_art.dart';
import '../../logic/onboarding_films.dart';
import '../tokens.dart';
import 'onboarding_stage.dart';
import 'travi_player.dart';

/// A rectangle in the key frames' canvas (941 × 1672 px), laid onto a
/// frame [width] wide.
Rect onboardingCanvasRect(Rect canvas, double width) {
  final k = width / OnboardingCamera.canvasWidth;
  return Rect.fromLTRB(canvas.left * k, canvas.top * k, canvas.right * k, canvas.bottom * k);
}

/// Onboarding's one stage, behind every beat: the [stage] (the paper
/// workshop, then the chosen place), and Travi on its floor in the same spot
/// with the same camera throughout, acting out [cues] (`TraviPlayer`). Only
/// he, the words over him and the controls below change, so the journey
/// never cuts.
///
/// A new stage folds up over the old one like a pop-up page: the workshop
/// folds away and the destination stands up from the floor line. Reduced
/// motion shows each state settled.
class OnboardingScene extends StatefulWidget {
  const OnboardingScene({
    super.key,
    required this.stage,
    required this.cues,
    this.start,
    this.active = true,
    this.onPose,
    this.onHandoff,
    this.overlay,
  });

  final OnboardingStage stage;
  final List<TraviCue> cues;

  /// Where Travi is when first shown (see [TraviPlayer.start]).
  final TraviPose? start;

  /// False while a sheet or another screen is on top (he holds still).
  final bool active;
  final ValueChanged<TraviPose?>? onPose;
  final ValueChanged<TraviFilm>? onHandoff;

  /// Live words on what Travi holds, laid out over the frame ([width] wide;
  /// see [onboardingCanvasRect]).
  final Widget Function(BuildContext context, double width)? overlay;

  @override
  State<OnboardingScene> createState() => _OnboardingSceneState();
}

class _OnboardingSceneState extends State<OnboardingScene> with SingleTickerProviderStateMixin {
  late final _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250), value: 1);
  OnboardingStage? _from;

  @override
  void didUpdateWidget(OnboardingScene old) {
    super.didUpdateWidget(old);
    if (old.stage.asset == widget.stage.asset || MediaQuery.disableAnimationsOf(context)) return;
    _from = old.stage;
    _reveal.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _from = null);
    });
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final frame = Rect.fromLTWH(0, 0, width, width / OnboardingCamera.aspect);
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (context, _) => _PopUp(stage: widget.stage, t: _reveal.value, from: _from),
              ),
            ),
            Positioned.fromRect(
              rect: frame,
              child: TraviPlayer(
                cues: widget.cues,
                start: widget.start,
                active: widget.active,
                onPose: widget.onPose,
                onHandoff: widget.onHandoff,
              ),
            ),
            if (widget.overlay case final overlay?) Positioned.fromRect(rect: frame, child: overlay(context, width)),
          ],
        );
      },
    ),
  );
}

/// The stage: [stage] standing up from the floor line over [from], which
/// folds away first, [t] of the way.
class _PopUp extends StatelessWidget {
  const _PopUp({required this.stage, required this.t, required this.from});
  final OnboardingStage stage;
  final double t;
  final OnboardingStage? from;

  @override
  Widget build(BuildContext context) {
    final plate = OnboardingStagePlate(stage: stage, floor: OnboardingCamera.floor);
    final old = from;
    if (t >= 1 || old == null) return plate;
    return LayoutBuilder(
      builder: (context, box) {
        final floorY = OnboardingCamera.floor * box.maxWidth;
        final hinge = Alignment(0, floorY / box.maxHeight * 2 - 1);
        final oldPlate = OnboardingStagePlate(stage: old, floor: OnboardingCamera.floor);
        // The old scenery folds back flat, then the new one stands up.
        final fold = Curves.easeInCubic.transform(const Interval(0, .4).transform(t));
        final rise = Curves.easeOutBack.transform(const Interval(.28, 1).transform(t));
        return Stack(
          fit: StackFit.expand,
          children: [
            // Sky behind both pages.
            const ColoredBox(color: OnboardingColors.sky),
            // The floors: the new one settles in over the old.
            ClipRect(
              clipper: _Band(top: floorY),
              child: oldPlate,
            ),
            Opacity(
              opacity: const Interval(.2, .7).transform(t),
              child: ClipRect(
                clipper: _Band(top: floorY),
                child: plate,
              ),
            ),
            if (fold < 1)
              Transform(
                alignment: hinge,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, .0012)
                  ..rotateX(fold * math.pi / 2),
                child: ClipRect(
                  clipper: _Band(bottom: floorY),
                  child: oldPlate,
                ),
              ),
            if (t > .28)
              Transform(
                alignment: hinge,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, .0012)
                  ..rotateX(-(1 - rise) * math.pi / 2),
                child: ClipRect(
                  clipper: _Band(bottom: floorY),
                  child: plate,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Band extends CustomClipper<Rect> {
  const _Band({this.top, this.bottom});
  final double? top;
  final double? bottom;
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, top ?? 0, size.width, bottom ?? size.height);
  @override
  bool shouldReclip(_Band old) => old.top != top || old.bottom != bottom;
}

/// The saved booking written on the blank card Travi holds up (his "card"
/// key frame): the card's clear middle, tilted with it.
class ProofCardWords extends StatelessWidget {
  const ProofCardWords({super.key, required this.text, required this.width});
  final CardText text;
  final double width;

  // The card's clear middle in the card key frame (canvas px), and its tilt.
  static const _area = Rect.fromLTWH(418, 900, 186, 116);
  static const _tilt = 6.6 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final area = onboardingCanvasRect(_area, width);
    final k = width / OnboardingCamera.canvasWidth;
    // Lettering on the artwork scales with it, not with the text size
    // setting (the floor's words carry the booking for screen readers).
    return MediaQuery.withNoTextScaling(
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: area,
            child: Transform.rotate(
              angle: _tilt,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: area.width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TravaryText.title.copyWith(color: OnboardingColors.navy, fontSize: 30 * k, height: 1.05),
                      ),
                      if (text.when case final days?) ...[
                        SizedBox(height: 8 * k),
                        Text(
                          days,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TravaryText.body.copyWith(color: OnboardingColors.navy, fontSize: 21 * k),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
