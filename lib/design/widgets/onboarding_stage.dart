import 'package:flutter/material.dart';

import '../../logic/onboarding_art.dart';
import '../tokens.dart';

/// A destination's stage across the width, raised or lowered so its floor
/// meets [floor] (in widths from the top) wherever Travi stands in the
/// scene. Sky fills above a lowered stage and floor below a short one; the
/// artwork itself is never stretched or tinted.
class OnboardingStagePlate extends StatelessWidget {
  const OnboardingStagePlate({super.key, required this.stage, required this.floor});
  final OnboardingStage stage;
  final double floor;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final top = (floor - stage.floor) * w;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: ColoredBox(color: OnboardingColors.floor)),
            if (top > 0)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: top + 2,
                child: const ColoredBox(color: OnboardingColors.sky),
              ),
            Positioned(
              left: 0,
              top: top,
              width: w,
              child: Image.asset(
                stage.asset,
                width: w,
                fit: BoxFit.fitWidth,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    ),
  );
}
