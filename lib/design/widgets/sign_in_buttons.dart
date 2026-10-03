import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// "Continue with Apple": black, the Apple logo, as Apple's guidelines ask.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({super.key, required this.onPressed, this.busy = false});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => _SignInButton(
    key: const ValueKey('sign-in-apple'),
    label: 'Continue with Apple',
    background: Colors.black,
    foreground: Colors.white,
    logo: const Icon(Icons.apple, size: 22, color: Colors.white),
    onPressed: onPressed,
    busy: busy,
  );
}

/// "Continue with Google": white with a light outline and Google's "G".
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed, this.busy = false});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => _SignInButton(
    key: const ValueKey('sign-in-google'),
    label: 'Continue with Google',
    background: Colors.white,
    foreground: const Color(0xFF1F1F1F),
    border: const Color(0xFF747775),
    logo: const SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleGPainter())),
    onPressed: onPressed,
    busy: busy,
  );
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.logo,
    required this.onPressed,
    required this.busy,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final Widget logo;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TravaryRadius.small),
      side: border == null ? BorderSide.none : BorderSide(color: border!),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null && !busy ? 0.5 : 1,
        child: Material(
          color: background,
          shape: shape,
          child: InkWell(
            onTap: busy ? null : onPressed,
            customBorder: shape,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: TravarySpace.lg, vertical: TravarySpace.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (busy)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                      )
                    else
                      logo,
                    const SizedBox(width: TravarySpace.md),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TravaryText.label.copyWith(color: foreground, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Google's four-colour "G", drawn (an official raster can replace it:
/// docs/ART_ASSET_GAPS.md).
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double deg(double d) => d * math.pi / 180;
    // Clockwise from the right: blue (bar side), green, yellow, red.
    canvas.drawArc(rect, deg(-15), deg(60), false, arc(const Color(0xFF4285F4)));
    canvas.drawArc(rect, deg(45), deg(90), false, arc(const Color(0xFF34A853)));
    canvas.drawArc(rect, deg(135), deg(80), false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, deg(215), deg(100), false, arc(const Color(0xFFEA4335)));
    // The bar into the middle.
    canvas.drawRect(
      Rect.fromLTRB(
        size.width * 0.5,
        size.height * 0.5 - stroke / 2,
        size.width - stroke * 0.05,
        size.height * 0.5 + stroke / 2,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(_GoogleGPainter oldDelegate) => false;
}
