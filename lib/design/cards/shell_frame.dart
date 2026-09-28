import 'package:flutter/material.dart';

import '../art/card_shells.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'card_parts.dart';

/// Something placed on a shell at one of its anchors.
class ShellOverlay {
  const ShellOverlay(this.rect, this.child, {this.interactive = false});

  /// Where, as fractions of the shell image.
  final FractionRect rect;
  final Widget child;

  /// Receives taps itself (a button); everything else lets taps through
  /// to the card. Interactive overlays grow around their anchor to at
  /// least [minTarget] points each way.
  final bool interactive;

  static const minTarget = 48.0;
}

/// Draws a raster shell at the width it's given, never stretched: the
/// physical card (its [ShellGeometry.body]) fills the box, and shadows or a
/// hanging tag spill outside it. Overlays sit at fractional anchors, so the
/// same layout works at any width.
///
/// [underlays] are drawn *beneath* the shell: a windowed shell's scene, so
/// the shell's own window frame, keyline and rounded corners sit on top of
/// the picture and nothing has to be clipped or drawn to match them.
///
/// The whole card is one tap target with a focus ring in the trip's
/// highlight colour. If the image can't be drawn (a damaged pack file) a
/// plain panel stands in so the text stays readable.
class ShellFrame extends StatelessWidget {
  const ShellFrame({
    super.key,
    required this.shell,
    required this.overlays,
    required this.fallbackColor,
    this.underlays = const [],
    this.onTap,
    this.semanticLabel,
  });

  final ShellArt shell;
  final List<ShellOverlay> overlays;
  final List<ShellOverlay> underlays;

  /// The stand-in panel's colour if the image fails.
  final Color fallbackColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final body = shell.geometry.body;
    final bodyAspect = shell.role.aspectRatio * body.width / body.height;
    final colors = TravaryChrome.of(context).colors;

    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: AspectRatio(
        aspectRatio: bodyAspect,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, box) {
                  final imageWidth = box.maxWidth / body.width;
                  final imageHeight = box.maxHeight / body.height;
                  Rect place(FractionRect r) => Rect.fromLTWH(
                    (r.left - body.left) * imageWidth,
                    (r.top - body.top) * imageHeight,
                    r.width * imageWidth,
                    r.height * imageHeight,
                  );

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final underlay in underlays)
                        Positioned.fromRect(
                          rect: place(underlay.rect),
                          child: IgnorePointer(child: ExcludeSemantics(child: underlay.child)),
                        ),
                      Positioned.fromRect(
                        rect: place(const FractionRect(0, 0, 1, 1)),
                        child: ExcludeSemantics(
                          child: Image(
                            image: artImageProvider(shell.image),
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (context, error, stackTrace) => Padding(
                              padding: EdgeInsets.fromLTRB(
                                body.left * imageWidth,
                                body.top * imageHeight,
                                (1 - body.right) * imageWidth,
                                (1 - body.bottom) * imageHeight,
                              ),
                              child: DecoratedBox(
                                key: const ValueKey('shell-fallback'),
                                decoration: BoxDecoration(
                                  color: fallbackColor,
                                  borderRadius: BorderRadius.circular(TravaryRadius.card),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (onTap != null)
                        Positioned.fill(
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: onTap,
                              borderRadius: BorderRadius.circular(TravaryRadius.card),
                              focusColor: colors.highlight.withValues(alpha: 0.18),
                              highlightColor: Colors.black.withValues(alpha: 0.04),
                              splashColor: Colors.black.withValues(alpha: 0.05),
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      for (final overlay in overlays)
                        Positioned.fromRect(
                          rect: overlay.interactive ? _atLeastTarget(place(overlay.rect)) : place(overlay.rect),
                          child: overlay.interactive ? overlay.child : IgnorePointer(child: overlay.child),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Rect _atLeastTarget(Rect rect) => Rect.fromCenter(
  center: rect.center,
  width: rect.width < ShellOverlay.minTarget ? ShellOverlay.minTarget : rect.width,
  height: rect.height < ShellOverlay.minTarget ? ShellOverlay.minTarget : rect.height,
);

/// A column of card text that always fits its anchor: laid out at the
/// anchor's width and, only if it's still too tall (very large text sizes),
/// scaled down as a whole rather than overflowing the card.
class ShellTextBlock extends StatelessWidget {
  const ShellTextBlock({super.key, required this.children, this.alignment = Alignment.topLeft});

  final List<Widget> children;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: SizedBox(
          width: box.maxWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A card title that keeps to one line when shrinking it a little is
/// enough (down to [minScale] of its size), and otherwise wraps onto two
/// lines at that smaller size, ending with an ellipsis if even that is too
/// long.
class FitTitle extends StatelessWidget {
  const FitTitle(this.text, {super.key, required this.style, this.minScale = 0.66});

  final String text;
  final TextStyle style;
  final double minScale;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final width = painter.width;
        painter.dispose();
        final available = box.maxWidth;
        final scale = width <= available ? 1.0 : available / width;
        if (scale >= minScale) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(text, style: style, maxLines: 1, softWrap: false),
          );
        }
        return Text(
          text,
          style: style.copyWith(fontSize: style.fontSize! * minScale),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// A short rule under a card title, like the reference's printed dividers.
class ShellRule extends StatelessWidget {
  const ShellRule({super.key, required this.color, this.width = 0.5});

  final Color color;

  /// Fraction of the text column.
  final double width;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: width,
      alignment: Alignment.centerLeft,
      child: Container(height: 1.2, color: color),
    );
  }
}
