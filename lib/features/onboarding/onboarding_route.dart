import 'package:flutter/material.dart';

/// A short forward move into the flat folio; reduced motion is immediate.
Route<T> onboardingFolioRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  pageBuilder: (context, _, _) => builder(context),
  transitionDuration: const Duration(milliseconds: 550),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  transitionsBuilder: (context, animation, _, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: const Interval(0, .55)),
      child: ScaleTransition(
        scale: Tween(begin: .88, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  },
);

/// A fade, immediate with reduced motion (the pass desk on its own).
Route<T> onboardingFadeRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  pageBuilder: (context, _, _) => builder(context),
  transitionDuration: const Duration(milliseconds: 450),
  reverseTransitionDuration: const Duration(milliseconds: 250),
  transitionsBuilder: (context, animation, _, child) =>
      MediaQuery.disableAnimationsOf(context) ? child : FadeTransition(opacity: animation, child: child),
);
