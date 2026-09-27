import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art_catalog.dart';
import '../art/art_resolver.dart';
import '../kind_style.dart';
import '../tokens.dart';

/// Draws a card's artwork: the image from `assets/art/` when there is one,
/// otherwise a simple placeholder in the card's palette.
class ArtPanel extends StatelessWidget {
  const ArtPanel({
    super.key,
    required this.art,
    this.format = ArtFormat.scene,
    this.alignment = Alignment.centerRight,
  });

  final ArtChoice art;

  /// Which shape this spot wants. Falls back to the other if missing.
  final ArtFormat format;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final style = KindStyle.of(art.kind);
    final palette = style.palette(art.variant);
    final asset = art.preferring(format);
    if (asset != null) {
      // Vignettes are transparent corner prints: they sit on the card's
      // paper. Scenes fill the space.
      final isVignette = asset.format == ArtFormat.vignette;
      return ColoredBox(
        color: isVignette ? palette.background : Colors.transparent,
        child: Image.asset(
          asset.path,
          fit: isVignette ? BoxFit.contain : BoxFit.cover,
          alignment: isVignette ? Alignment.bottomRight : alignment,
        ),
      );
    }
    return ColoredBox(
      color: palette.background,
      child: LayoutBuilder(
        builder: (context, box) {
          final height = box.maxHeight.isFinite ? box.maxHeight : 120.0;
          final width = box.maxWidth.isFinite ? box.maxWidth : height;
          // Decorations sit in the bottom-right corner, where card text never
          // goes. On wide cards they use only the right half.
          final size = math.min(height, width > height * 1.2 ? width * 0.5 : width);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // A low "sun" so placeholders feel like a scene, not a box.
              Positioned(
                right: size * 0.1,
                bottom: -size * 0.3,
                child: Container(
                  width: size * 0.78,
                  height: size * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.accent.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Positioned(
                right: size * 0.3,
                bottom: size * 0.2,
                child: Icon(
                  style.icon,
                  size: size * 0.3,
                  color: palette.foreground.withValues(alpha: 0.35),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A rounded card outline with ticket notches cut out.
///
/// [stubAt] cuts a pair of half-circle notches in the top and bottom edges at
/// that fraction of the width (the tear line of a ticket). [sideNotches]
/// cuts notches in the middle of the left and right edges instead.
class TicketClipper extends CustomClipper<Path> {
  const TicketClipper({this.stubAt, this.sideNotches = false, this.radius = TravaryRadius.card});

  final double? stubAt;
  final bool sideNotches;
  final double radius;

  static const notch = 9.0;

  @override
  Path getClip(Size size) {
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final cuts = Path();
    if (stubAt != null) {
      final x = size.width * stubAt!;
      cuts
        ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: notch))
        ..addOval(Rect.fromCircle(center: Offset(x, size.height), radius: notch));
    }
    if (sideNotches) {
      final y = size.height / 2;
      cuts
        ..addOval(Rect.fromCircle(center: Offset(0, y), radius: notch))
        ..addOval(Rect.fromCircle(center: Offset(size.width, y), radius: notch));
    }
    return Path.combine(PathOperation.difference, outline, cuts);
  }

  @override
  bool shouldReclip(TicketClipper oldClipper) =>
      oldClipper.stubAt != stubAt || oldClipper.sideNotches != sideNotches;
}

/// A vertical dashed tear line.
class TearLine extends StatelessWidget {
  const TearLine({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(1, double.infinity), painter: _DashPainter(color));
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (var y = 12.0; y < size.height - 12; y += 7) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 3.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}

/// A fake barcode for ticket stubs, drawn from a seed so it's stable.
class StubBarcode extends StatelessWidget {
  const StubBarcode({super.key, required this.seed, required this.color});

  final int seed;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(22, 72), painter: _BarcodePainter(seed, color));
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.seed, this.color);

  final int seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    var y = 0.0;
    var bits = seed | 1;
    while (y < size.height) {
      final thick = 1.0 + (bits & 3);
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, thick), paint);
      y += thick + 1.5 + ((bits >> 2) & 1) * 1.5;
      bits = (bits * 1103515245 + 12345) & 0x7fffffff;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.color != color;
}

/// A kraft-paper luggage tag with an icon (reservation cards).
class LuggageTag extends StatelessWidget {
  const LuggageTag({super.key, required this.icon, required this.variant});

  final IconData icon;
  final int variant;

  @override
  Widget build(BuildContext context) {
    // A slight, stable tilt per card so a stack of tags looks hand-placed.
    final tilt = ((variant % 5) - 2) * 0.02;
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: 52,
        height: 70,
        decoration: BoxDecoration(
          color: TravaryColors.kraft,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            const SizedBox(height: 7),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TravaryColors.linen,
                border: Border.all(color: const Color(0xFF9C7C55), width: 2),
              ),
            ),
            const Spacer(),
            Icon(icon, color: TravaryColors.ink, size: 24),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// The "Show tickets" button, styled like an inked rubber stamp.
class StampButton extends StatelessWidget {
  const StampButton({super.key, required this.label, required this.onPressed, required this.color});

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: TravaryColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 2),
            ),
            child: Text(label, style: TravaryText.label.copyWith(color: color, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}
