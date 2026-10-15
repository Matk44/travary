import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/onboarding.dart';
import '../../logic/formatters.dart';
import '../tokens.dart';
import 'ledger.dart';

/// The folio is a flat full-screen surface. Body owns its scroll/keyboard
/// handling; live type is never transformed onto an angled illustration.
class OnboardingFolio extends StatelessWidget {
  const OnboardingFolio({super.key, required this.body, this.onBack});
  final Widget body;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: OnboardingColors.binding,
      body: SafeArea(
        child: CustomPaint(
          painter: const _BindingStitches(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 68,
                  child: Row(
                    children: [
                      BackButton(color: OnboardingColors.paper, onPressed: onBack),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Travary', style: TravaryText.title.copyWith(color: OnboardingColors.paper)),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ExcludeSemantics(
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: .65,
                              widthFactor: 1,
                              child: Image.asset(
                                'assets/onboarding/travi-receiving-v1.webp',
                                width: 88,
                                errorBuilder: (_, _, _) => const SizedBox(width: 88),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [OnboardingColors.cream, OnboardingColors.paper],
                      ),
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(10), child: body),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class OnboardingFolioHeading extends StatelessWidget {
  const OnboardingFolioHeading({
    super.key,
    required this.holiday,
    required this.title,
    required this.accent,
    required this.subtitle,
  });
  final OnboardingHoliday holiday;
  final String title;
  final String accent;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HolidayKeepsake(holiday: holiday),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            text: '$title\n',
            children: [
              TextSpan(
                text: accent,
                style: const TextStyle(color: OnboardingColors.coralInk),
              ),
            ],
          ),
          style: TravaryText.display.copyWith(color: OnboardingColors.navy),
        ),
        const SizedBox(height: 10),
        Text(subtitle, style: TravaryText.bodySoft.copyWith(color: OnboardingColors.secondary)),
      ],
    ),
  );
}

class HolidayKeepsake extends StatelessWidget {
  const HolidayKeepsake({super.key, required this.holiday});
  final OnboardingHoliday holiday;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: ShapeDecoration(
      color: OnboardingColors.paper,
      shape: const NotchedTicketBorder(radius: 5, notchRadius: 4),
    ),
    child: Row(
      children: [
        const Icon(Icons.circle_outlined, size: 13, color: OnboardingColors.brass),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(holiday.name, style: TravaryText.label.copyWith(color: OnboardingColors.navy)),
              Text(
                holiday.start == null
                    ? 'Dates to come'
                    : '${formatDate(holiday.start!)}${holiday.end == null || holiday.end == holiday.start ? '' : ' – ${formatDate(holiday.end!)}'}',
                style: TravaryText.small.copyWith(color: OnboardingColors.secondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A readable itinerary-day stamp over a colourful scenic stage.
class OnboardingDayStamp extends StatelessWidget {
  const OnboardingDayStamp({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: const ShapeDecoration(
      color: OnboardingColors.paper,
      shape: NotchedTicketBorder(radius: 5, notchRadius: 3),
    ),
    child: Text(label, style: TravaryText.label.copyWith(color: OnboardingColors.navy)),
  );
}

class _BindingStitches extends CustomPainter {
  const _BindingStitches();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)));
    final paint = Paint()
      ..color = OnboardingColors.brass.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double at = 0; at < metric.length; at += 6) {
        canvas.drawPath(metric.extractPath(at, math.min(at + 3, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BindingStitches oldDelegate) => false;
}
