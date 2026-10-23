import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

// Wider than a phone (a tablet, an iPad window, a foldable), a screen's
// content keeps to [ScreenLayout.readableWidth], centred, at the size its
// cards and rows were drawn for, while the screen's scroll view, linen and
// bars still run the whole width, so a thumb at a tablet's edge scrolls it.
// On a phone none of this changes anything: the inset is zero.

/// How far content moves in from each side of a screen [width] wide.
double readableInsetFor(double width, {double maxWidth = ScreenLayout.readableWidth}) =>
    math.max(0, (width - maxWidth) / 2);

/// How far content moves in from each side of the screen [context] fills
/// (a page or a tab, not a sheet or a dialog).
double readableInset(BuildContext context, {double maxWidth = ScreenLayout.readableWidth}) =>
    readableInsetFor(MediaQuery.sizeOf(context).width, maxWidth: maxWidth);

/// A full-width scroll view's [padding], with its content kept to the
/// readable width.
EdgeInsets readablePadding(BuildContext context, EdgeInsets padding) {
  final inset = readableInset(context);
  return padding.copyWith(left: padding.left + inset, right: padding.right + inset);
}

/// A full-width scroll view's [slivers], each kept to the readable width.
List<Widget> readableSlivers(BuildContext context, List<Widget> slivers) {
  final inset = EdgeInsets.symmetric(horizontal: readableInset(context));
  return [for (final sliver in slivers) SliverPadding(padding: inset, sliver: sliver)];
}

/// Keeps [child] to [maxWidth], centred, in whatever room it's given (a
/// bar, a panel); the room either side stays the parent's. The child keeps
/// its place in the tree at every width, so turning a tablet keeps
/// whatever was typed.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, this.maxWidth = ScreenLayout.readableWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Padding(
      padding: EdgeInsets.symmetric(
        horizontal: box.maxWidth.isFinite ? readableInsetFor(box.maxWidth, maxWidth: maxWidth) : 0,
      ),
      child: child,
    ),
  );
}

/// Messages along the bottom (snack bars) keep to the readable width on a
/// tablet rather than running the width of the screen; on a phone they're
/// as they were. The theme is always there, so the screens under it keep
/// their place when a foldable opens.
class ReadableSnackBars extends StatelessWidget {
  const ReadableSnackBars({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = !ScreenLayout.isPhoneWidth(MediaQuery.sizeOf(context).width);
    return Theme(
      data: theme.copyWith(
        snackBarTheme: theme.snackBarTheme.copyWith(
          width: wide ? ScreenLayout.readableWidth - 2 * TravarySpace.gutter : null,
        ),
      ),
      child: child,
    );
  }
}
