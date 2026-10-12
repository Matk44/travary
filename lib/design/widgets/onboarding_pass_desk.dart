import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../tokens.dart';

const _deskArt = 'assets/onboarding/pass-desk-art-v2.png';
const _referenceWidth = 851.0;

/// Runtime atlas slicing preserves the approved illustration without baking
/// any product, amount, title or selection into a ticket image.
class _ArtRegion extends StatelessWidget {
  const _ArtRegion(this.region);
  final Rect region;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (_, box) {
        final sx = box.maxWidth / region.width;
        final sy = box.maxHeight / region.height;
        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: -region.left * sx,
                top: -region.top * sy,
                width: 851 * sx,
                height: 1848 * sy,
                child: Image.asset(_deskArt, fit: BoxFit.fill),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// The palm stubs, brass eyelets and notches come from the exact reference.
/// All text and the coral selection seal are native, independently updatable.
class OnboardingPaperPass extends StatelessWidget {
  const OnboardingPaperPass({
    super.key,
    required this.annual,
    required this.selected,
    required this.title,
    required this.scope,
    required this.price,
    required this.onTap,
  });
  final bool annual;
  final bool selected;
  final String title;
  final String scope;
  final String price;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, box) {
            final s = box.maxWidth / _referenceWidth;
            final serif = TravaryText.title.copyWith(color: OnboardingColors.navy, height: 1.06);
            final copy = TravaryText.onboardingCopy;
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: 204 * s),
              child: Stack(
                children: [
                  Positioned.fill(child: _ArtRegion(Rect.fromLTWH(0, annual ? 1304 : 1100, 851, 204))),
                  Padding(
                    padding: EdgeInsets.fromLTRB(270 * s, 21 * s, 220 * s, 28 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title.toUpperCase(), style: serif.copyWith(fontSize: 36 * s)),
                        SizedBox(height: 3 * s),
                        Text(scope, style: copy.copyWith(fontSize: 28 * s)),
                        Text.rich(
                          TextSpan(
                            text: price,
                            children: [
                              TextSpan(
                                text: annual ? ' / year' : ' once',
                                style: serif.copyWith(fontSize: 28 * s),
                              ),
                            ],
                          ),
                          style: serif.copyWith(fontSize: 46 * s),
                        ),
                        SizedBox(height: 3 * s),
                        Text(
                          annual ? 'Renews yearly. Cancel anytime.' : 'One payment. No renewal.',
                          style: copy.copyWith(fontSize: 23 * s),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 100 * s,
                    top: 0,
                    bottom: 0,
                    width: 76 * s,
                    child: ExcludeSemantics(
                      child: Center(
                        child: Container(
                          width: 76 * s,
                          height: 76 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? const Color(0xFFE86031) : Colors.transparent,
                            border: Border.all(
                              color: selected ? OnboardingColors.coral : OnboardingColors.navy,
                              width: 3 * s,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(0x25B85132),
                                      blurRadius: 5 * s,
                                      offset: Offset(0, 2 * s),
                                    ),
                                  ]
                                : null,
                          ),
                          child: selected
                              ? Icon(Icons.check_rounded, color: OnboardingColors.paper, size: 58 * s)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

class PassDeskButton extends StatelessWidget {
  const PassDeskButton({super.key, required this.label, required this.busy, required this.onPressed});
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) {
      final s = box.maxWidth / 851;
      return Semantics(
        button: true,
        enabled: onPressed != null && !busy,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(48, 110 * s)),
          child: Stack(
            children: [
              const Positioned.fill(child: _ArtRegion(Rect.fromLTWH(0, 1557, 851, 110))),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: busy ? null : onPressed,
                  style: TextButton.styleFrom(
                    minimumSize: Size.fromHeight(math.max(48, 110 * s)),
                    foregroundColor: OnboardingColors.paper,
                    padding: EdgeInsets.symmetric(horizontal: 75 * s, vertical: 8 * s),
                    textStyle: TravaryText.title.copyWith(fontSize: 44 * s),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: OnboardingColors.paper),
                        )
                      : Text(label, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
