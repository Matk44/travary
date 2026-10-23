import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/tokens.dart';
import '../../design/widgets/onboarding_stage.dart';
import '../../design/widgets/onboarding_words.dart';
import '../../logic/onboarding_journey.dart';

/// Every onboarding beat laid out the same way over the one stage: the
/// wordmark and headline in the sky, the controls on the floor just under
/// Travi's wheels. Words re-enter when [wordsKey] changes; controls swap
/// when [floorKey] does. The stage never moves; the controls scroll above
/// the keyboard and large type. The floor's controls can read how much room
/// they have ([OnboardingFloorSpace]) to fit it rather than scroll.
class OnboardingStageLayout extends StatefulWidget {
  const OnboardingStageLayout({
    super.key,
    required this.scene,
    required this.words,
    required this.floor,
    this.wordsKey,
    this.floorKey,
    this.floorTop,
    this.snugFloor = false,
    this.onBack,
    this.backEnabled = true,
    this.backTooltip,
    this.backKey,
    this.topRight,
  });

  final Widget scene;
  final OnboardingWords words;
  final Widget floor;
  final Object? wordsKey;
  final Object? floorKey;

  /// Where the controls start, as a share of the screen's height, when
  /// that's lower than the stage's floor (the workshop's bigger Travi).
  final double? floorTop;

  /// Controls that need all the floor there is (the pass desk) start right
  /// under Travi's shadow, with less margin round them.
  final bool snugFloor;
  final VoidCallback? onBack;

  /// False while something can't be left (a purchase under way).
  final bool backEnabled;
  final String? backTooltip;
  final String? backKey;
  final Widget? topRight;

  @override
  State<OnboardingStageLayout> createState() => _OnboardingStageLayoutState();
}

class _OnboardingStageLayoutState extends State<OnboardingStageLayout> {
  /// Beside Travi, the controls' floor is at most this tall, so a column
  /// that fits it (the pass desk) stays together rather than spreading out.
  static const _besideFloor = 460.0;

  /// The controls keep their state (what's typed) when a turned tablet
  /// moves them from under Travi to beside him.
  final _floorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final OnboardingStageLayout(
      :scene,
      :words,
      :floor,
      :wordsKey,
      :floorKey,
      :floorTop,
      :snugFloor,
      :onBack,
      :backEnabled,
      :backTooltip,
      :backKey,
      :topRight,
    ) = widget;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    // Large type grows over Travi, so it gets the sky behind it.
    final largeType = MediaQuery.textScalerOf(context).scale(16) > 17.6;
    // Where Travi stands and the controls go: on a phone, just under his
    // wheels (1.25 frame widths; his shadow ends at 1.26), or lower if
    // asked; wider screens fit it all in (`OnboardingStageGeometry`).
    final geometry = OnboardingStageGeometry.forWindow(size, padding, snugFloor: snugFloor, floorTop: floorTop);
    final frame = geometry.frame;
    final bottom = math.max(padding.bottom, MediaQuery.viewInsetsOf(context).bottom) + (snugFloor ? 6 : 16);
    final floorPadding = snugFloor ? 4.0 : 8.0;
    final subtitle = words.subtitle;
    final wordsBlock = OnboardingSky(
      enabled: largeType,
      child: Column(
        children: [
          Text(
            'Travary',
            style: TravaryText.title.copyWith(color: OnboardingColors.paper, shadows: PaperWords.shadows),
          ),
          const SizedBox(height: 2),
          PaperWords(key: ValueKey(wordsKey), text: words.text, accent: words.accent, size: .108, lifted: true),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TravaryText.body.copyWith(
                color: OnboardingColors.paper,
                fontWeight: FontWeight.w600,
                shadows: PaperWords.shadows,
              ),
            ),
          ],
        ],
      ),
    );
    Widget floorFor(double height) => KeyedSubtree(
      key: _floorKey,
      child: AnimatedSwitcher(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(floorKey),
          child: OnboardingFloorSpace(
            height: math.max(0, height - 2 * (floorPadding + (geometry.beside ? OnboardingFloor.raisedInset - 8 : 0))),
            child: OnboardingFloor(padding: floorPadding, raised: geometry.beside, child: floor),
          ),
        ),
      ),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: TravarySystemBars.onStage,
      child: Scaffold(
        backgroundColor: OnboardingColors.floor,
        // The stage stays put; the controls scroll above the keyboard.
        resizeToAvoidBottomInset: false,
        body: OnboardingFrame(
          geometry: geometry,
          child: Stack(
            children: [
              Positioned.fill(child: scene),
              // A little evening over busy scenery, so the words read.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: frame.top + frame.width * .78,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, .6, 1],
                        colors: [
                          OnboardingColors.sky.withValues(alpha: .5),
                          OnboardingColors.sky.withValues(alpha: .32),
                          OnboardingColors.sky.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (geometry.beside)
                // Travi to one side, the words and controls together in the
                // sky beside him.
                Positioned.fromRect(
                  rect: geometry.column,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final room = math.max(0.0, box.maxHeight - padding.top - 12 - bottom);
                      final wordsRoom = OnboardingStageGeometry.wordsHeight(geometry.wordsWidth) + TravarySpace.xl;
                      return SingleChildScrollView(
                        key: const ValueKey('onboarding-scroll'),
                        padding: EdgeInsets.fromLTRB(0, padding.top + 12, 0, bottom),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: room),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              wordsBlock,
                              const SizedBox(height: TravarySpace.xl),
                              floorFor(math.min(_besideFloor, room - wordsRoom)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                SingleChildScrollView(
                  key: const ValueKey('onboarding-scroll'),
                  padding: EdgeInsets.fromLTRB(TravarySpace.gutter, padding.top + 12, TravarySpace.gutter, bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: math.max(0, geometry.controlsTop - padding.top - 12)),
                        // A phone's words run the width; wider, they keep to
                        // a readable column over the stage.
                        child: geometry.controlsWidth.isFinite
                            ? Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: ScreenLayout.readableWidth),
                                  child: wordsBlock,
                                ),
                              )
                            : wordsBlock,
                      ),
                      if (geometry.controlsWidth.isFinite)
                        Center(
                          child: SizedBox(
                            width: geometry.controlsWidth,
                            child: floorFor(size.height - geometry.controlsTop - bottom),
                          ),
                        )
                      else
                        floorFor(size.height - geometry.controlsTop - bottom),
                    ],
                  ),
                ),
              if (onBack case final back?)
                Positioned(
                  left: 4 + padding.left,
                  top: padding.top,
                  child: IconButton(
                    key: backKey == null ? null : ValueKey<String>(backKey),
                    tooltip: backTooltip ?? 'Back',
                    onPressed: backEnabled ? back : null,
                    icon: const Icon(Icons.arrow_back_rounded, color: OnboardingColors.paper, size: 20),
                  ),
                ),
              if (topRight case final topRight?)
                Positioned(right: 8 + padding.right, top: padding.top + 4, child: topRight),
            ],
          ),
        ),
      ),
    );
  }
}

/// The petrol sky behind the words when large type would cover Travi.
class OnboardingSky extends StatelessWidget {
  const OnboardingSky({super.key, required this.enabled, required this.child});
  final bool enabled;
  final Widget child;
  @override
  Widget build(BuildContext context) => !enabled
      ? child
      : DecoratedBox(
          decoration: BoxDecoration(
            color: OnboardingColors.sky.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        );
}

/// Keeps the controls readable when they scroll up over the scenery (the
/// keyboard, large type); on the floor it matches the floor. Beside Travi,
/// on the wall, it's a card of the floor's paper ([raised]).
class OnboardingFloor extends StatelessWidget {
  const OnboardingFloor({super.key, this.padding = 8, this.raised = false, required this.child});
  final double padding;
  final bool raised;
  final Widget child;

  /// A raised card's margin round its controls.
  static const raisedInset = 16.0;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: OnboardingColors.floor.withValues(alpha: raised ? 1 : .92),
      borderRadius: BorderRadius.circular(raised ? TravaryRadius.card : 12),
      boxShadow: raised ? const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 6))] : null,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        vertical: padding + (raised ? raisedInset - 8 : 0),
        horizontal: raised ? raisedInset : 0,
      ),
      child: child,
    ),
  );
}

/// The height the floor's controls have between Travi's wheels and the
/// bottom of the screen, for controls that fit it instead of scrolling
/// (`FitColumn`). More than they need on a tall phone; less with the
/// keyboard up or large type, when the screen scrolls.
class OnboardingFloorSpace extends InheritedWidget {
  const OnboardingFloorSpace({super.key, required this.height, required super.child});
  final double height;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnboardingFloorSpace>()?.height;

  @override
  bool updateShouldNotify(OnboardingFloorSpace oldWidget) => oldWidget.height != height;
}
