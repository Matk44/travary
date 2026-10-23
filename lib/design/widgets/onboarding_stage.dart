import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../logic/onboarding_art.dart';
import '../tokens.dart';

/// Where onboarding's one stage sits in a window, and where its words and
/// controls go round it.
///
/// A phone held upright (up to [ScreenLayout.phoneWidth] wide) keeps the
/// approved layout exactly: Travi's frame the screen's width from the top,
/// the words in the sky over him, the controls on the floor just under his
/// wheels (scrolling on an iPhone SE). Anything wider (a tablet, an iPad
/// window, a foldable, the iPhone Duo folded or open) is shorter for its
/// width, where a frame the whole width wide would push the controls off
/// the screen: there the frame is as large as leaves the controls a
/// phone's floor, centred, the scenery's wall and floor running on to
/// either side, and the words still clear of Travi. A landscape screen
/// stands Travi beside the words and controls instead, when that shows him
/// larger.
@immutable
class OnboardingStageGeometry {
  const OnboardingStageGeometry._({
    required this.size,
    required this.frame,
    required this.beside,
    required this.controlsTop,
    required this.column,
    required this.controlsWidth,
    required this.wordsWidth,
  });

  /// The approved phone layout on a screen [width] wide.
  factory OnboardingStageGeometry.phone(Size size, {bool snugFloor = false, double? floorTop}) {
    final width = size.width;
    return OnboardingStageGeometry._(
      size: size,
      frame: Rect.fromLTWH(0, 0, width, width / OnboardingCamera.aspect),
      beside: false,
      controlsTop: math.max(width * _reach(snugFloor), (floorTop ?? 0) * size.height),
      column: Offset.zero & size,
      controlsWidth: double.infinity,
      wordsWidth: width,
    );
  }

  /// The stage for a window [size] with the safe area [padding] (never the
  /// keyboard: the stage stays put while the controls scroll above it).
  factory OnboardingStageGeometry.forWindow(Size size, EdgeInsets padding, {bool snugFloor = false, double? floorTop}) {
    if (ScreenLayout.isPhoneWidth(size.width)) {
      return OnboardingStageGeometry.phone(size, snugFloor: snugFloor, floorTop: floorTop);
    }
    final stacked = _stacked(size, padding, snugFloor: snugFloor, floorTop: floorTop);
    if (size.width <= size.height) return stacked;
    final beside = _beside(size, padding);
    return beside != null && beside.frame.width > stacked.frame.width ? beside : stacked;
  }

  /// Travi's top in his films, in frame widths (the roll-in reaches 286 of
  /// the 540-pixel camera), and the words' clearance above him.
  static const traviTop = .53;
  static const _wordsClearance = 8.0;

  /// Where the controls start under Travi's wheels (1.25 frame widths; his
  /// shadow ends at 1.26), in frame widths.
  static double _reach(bool snug) => snug ? 1.275 : 1.3;

  /// The headline's size, as a share of [wordsWidth], and at most.
  static const wordsSize = .108;
  static const wordsMaxSize = 52.0;

  /// Off a phone, the stage is never wider than this (Travi's films are
  /// drawn for a phone; past this they'd soften).
  static const maxFrameWidth = 680.0;

  /// The controls are never wider than on the largest phone, so passes and
  /// buttons stay the size they were drawn for, nor wider than this share
  /// of a short screen's height (the iPhone Duo folded), so they leave Travi
  /// room.
  static const maxControlsWidth = 400.0;
  static const _controlsPerHeight = .52;

  /// Under the stage, the controls get at least a phone's floor: the pass
  /// desk's, as a share of their width (299 points for 350 on a 390-point
  /// phone). Every beat keeps the same room, so the stage never moves.
  static const _floorPerWidth = .86;

  /// Travi and the controls side by side: the gap between them.
  static const _besideGap = 32.0;

  /// The words over the stage are laid out for a phone at least this wide.
  static const _phoneWords = 390.0;

  final Size size;

  /// Travi's 9:16 camera in the window: the stage art is this wide, its
  /// floor on [OnboardingCamera.floor] frame widths down.
  final Rect frame;

  /// Travi stands beside the words and controls ([column]), not under them.
  final bool beside;

  /// Where the controls start (stacked under the stage).
  final double controlsTop;

  /// Where the words and controls go: the whole window when they're stacked
  /// over and under the stage, the column beside it otherwise.
  final Rect column;

  /// The controls at most this wide, centred.
  final double controlsWidth;

  /// The headline is sized for words laid out this wide ([wordsSize]).
  final double wordsWidth;

  /// The headline's font size.
  double get wordsFontSize => math.min(wordsMaxSize, wordsWidth * wordsSize);

  /// Where the scenery meets the floor, from the window's top.
  double get floorLine => frame.top + OnboardingCamera.floor * frame.width;

  /// The scenery runs to the window's edges on its own (a phone).
  bool get fillsWidth => frame.left <= 0 && frame.right >= size.width;

  /// A rough height for the wordmark, a two-line headline and a subtitle,
  /// to keep them clear of Travi before they're laid out.
  static double wordsHeight(double wordsWidth) =>
      56 + 2 * 1.05 * math.min(wordsMaxSize, wordsWidth * wordsSize) + _wordsClearance;

  static OnboardingStageGeometry _stacked(Size size, EdgeInsets padding, {required bool snugFloor, double? floorTop}) {
    final controls = [
      maxControlsWidth,
      size.width - 2 * TravarySpace.gutter,
      size.height * _controlsPerHeight,
    ].reduce(math.min);
    final top = padding.top + 12;
    // The furthest down the stage may reach and still leave the controls
    // their floor; the same for every beat (the desk's controls start a
    // little higher, under his shadow).
    final reach = _reach(false);
    final stageBy = size.height - padding.bottom - 16 - controls * _floorPerWidth;
    double wordsWidthFor(double frame) => math.max(frame, math.min(size.width, _phoneWords));
    var width = [size.width, maxFrameWidth, stageBy / reach].reduce(math.min);
    var frameTop = 0.0;
    // Lowered under the words if they'd reach his head, and smaller to keep
    // the floor: a few rounds settle it.
    for (var i = 0; i < 6; i++) {
      frameTop = math.max(0, top + wordsHeight(wordsWidthFor(width)) - traviTop * width);
      if (frameTop + reach * width <= stageBy + .5) break;
      width = (stageBy - frameTop) / reach;
    }
    // Never so small he's lost: a window that short scrolls instead.
    width = math.max(width, math.min(size.width, 160.0));
    final frame = Rect.fromLTWH((size.width - width) / 2, frameTop, width, width / OnboardingCamera.aspect);
    return OnboardingStageGeometry._(
      size: size,
      frame: frame,
      beside: false,
      controlsTop: math.max(frameTop + _reach(snugFloor) * width, (floorTop ?? 0) * size.height),
      column: Offset.zero & size,
      controlsWidth: controls,
      wordsWidth: wordsWidthFor(width),
    );
  }

  static OnboardingStageGeometry? _beside(Size size, EdgeInsets padding) {
    final left = math.max(padding.left, TravarySpace.gutter);
    final right = math.max(padding.right, TravarySpace.gutter);
    final controls = math.min(maxControlsWidth, (size.width - left - right) * .45);
    // His shadow just above the bottom edge (1.26 frame widths), his
    // floor in front of him.
    final width = [
      maxFrameWidth,
      (size.height - padding.bottom) / _reach(false),
      size.width - left - right - _besideGap - controls,
    ].reduce(math.min);
    if (width <= 0) return null;
    final start = left + (size.width - left - right - width - _besideGap - controls) / 2;
    final frameTop = size.height - padding.bottom - _reach(false) * width;
    return OnboardingStageGeometry._(
      size: size,
      frame: Rect.fromLTWH(start, frameTop, width, width / OnboardingCamera.aspect),
      beside: true,
      controlsTop: 0,
      column: Rect.fromLTWH(start + width + _besideGap, 0, controls, size.height),
      controlsWidth: controls,
      wordsWidth: math.max(controls, math.min(width, _phoneWords)),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OnboardingStageGeometry &&
      other.size == size &&
      other.frame == frame &&
      other.beside == beside &&
      other.controlsTop == controlsTop &&
      other.column == column &&
      other.controlsWidth == controlsWidth &&
      other.wordsWidth == wordsWidth;

  @override
  int get hashCode => Object.hash(size, frame, beside, controlsTop, column, controlsWidth, wordsWidth);
}

/// The stage's geometry for everything drawn on it: the scenery, Travi and
/// what he holds ([OnboardingScene]), and the headline's size.
class OnboardingFrame extends InheritedWidget {
  const OnboardingFrame({super.key, required this.geometry, required super.child});

  final OnboardingStageGeometry geometry;

  static OnboardingStageGeometry? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnboardingFrame>()?.geometry;

  @override
  bool updateShouldNotify(OnboardingFrame oldWidget) => oldWidget.geometry != geometry;
}

/// A destination's stage, [frame]'s width, raised or lowered so its floor
/// meets [floor] (in frame widths from the frame's top) wherever Travi
/// stands in the scene. Sky fills above the floor line and floor below it,
/// wherever the artwork doesn't reach: above a lowered stage, below a short
/// one, and either side of a stage narrower than the window, where the
/// artwork's edges fade into them so the wall and floor run on. The
/// artwork itself is never stretched or tinted. Without a [frame] it spans
/// the box from the top.
class OnboardingStagePlate extends StatelessWidget {
  const OnboardingStagePlate({super.key, required this.stage, required this.floor, this.frame});
  final OnboardingStage stage;
  final double floor;
  final Rect? frame;

  /// How far the artwork's edges fade, as a share of its width, where the
  /// wall and floor run on past it.
  static const feather = .05;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, box) {
        final frame = this.frame ?? Rect.fromLTWH(0, 0, box.maxWidth, box.maxWidth / OnboardingCamera.aspect);
        final w = frame.width;
        final top = frame.top + (floor - stage.floor) * w;
        final floorLine = frame.top + floor * w;
        final fadeLeft = frame.left > .5;
        final fadeRight = frame.right < box.maxWidth - .5;
        final fadeTop = top > .5;
        Widget art = Image.asset(
          stage.asset,
          width: w,
          fit: BoxFit.fitWidth,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
        if (fadeLeft || fadeRight) {
          art = _Feather(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            start: fadeLeft,
            finish: fadeRight,
            child: art,
          );
        }
        if (fadeTop) {
          art = _Feather(begin: Alignment.topCenter, end: Alignment.bottomCenter, start: true, scale: w, child: art);
        }
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: ColoredBox(color: OnboardingColors.floor)),
            if (top > 0 || fadeLeft || fadeRight)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: math.max(0, (fadeLeft || fadeRight ? floorLine : top) + 2),
                child: const ColoredBox(color: OnboardingColors.sky),
              ),
            Positioned(left: frame.left, top: top, width: w, child: art),
          ],
        );
      },
    ),
  );
}

/// Fades a picture's edges to nothing along [begin]→[end]: at the [start]
/// and/or the [finish], over [OnboardingStagePlate.feather] of [scale] (its
/// own extent along the way, when not given).
class _Feather extends StatelessWidget {
  const _Feather({
    required this.begin,
    required this.end,
    required this.child,
    this.start = false,
    this.finish = false,
    this.scale,
  });
  final Alignment begin;
  final Alignment end;
  final bool start;
  final bool finish;
  final double? scale;
  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) {
      final extent = begin.x != end.x ? bounds.width : bounds.height;
      final share = extent <= 0 ? 0.0 : (OnboardingStagePlate.feather * (scale ?? extent) / extent).clamp(0.0, .5);
      return LinearGradient(
        begin: begin,
        end: end,
        colors: [
          start ? Colors.transparent : Colors.white,
          Colors.white,
          Colors.white,
          finish ? Colors.transparent : Colors.white,
        ],
        stops: [0, share, 1 - share, 1],
      ).createShader(bounds);
    },
    child: child,
  );
}
