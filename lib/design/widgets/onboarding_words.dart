import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// The approved "Paper words": a cream headline ending in coral, settling
/// into place once. Reduced motion shows it settled.
class PaperWords extends StatelessWidget {
  const PaperWords({super.key, required this.text, required this.accent, this.size = .125, this.lifted = false});
  final String text;
  final String accent;

  /// Font size as a share of the screen's width (at most 52).
  final double size;

  /// A soft shadow keeps the words readable over busy scenery.
  final bool lifted;

  /// The shadow under [lifted] words, for their neighbours too.
  static const shadows = [
    Shadow(color: Color(0xB3012F44), blurRadius: 14),
    Shadow(color: Color(0x80012F44), blurRadius: 3, offset: Offset(0, 1)),
  ];
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 450),
    builder: (context, value, _) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, (1 - value) * 12),
        child: Text.rich(
          TextSpan(
            text: text,
            children: [
              TextSpan(
                text: accent,
                style: const TextStyle(color: OnboardingColors.coral),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TravaryText.display.copyWith(
            fontSize: math.min(52, MediaQuery.sizeOf(context).width * size),
            color: OnboardingColors.paper,
            shadows: lifted ? shadows : null,
          ),
        ),
      ),
    ),
  );
}
