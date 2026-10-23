import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/app/orientation_policy.dart';
import 'package:travary/design/widgets/onboarding_stage.dart';
import 'package:travary/design/widgets/readable_width.dart';
import 'package:travary/logic/onboarding_art.dart';

/// Travary on screens other than a phone held upright: onboarding's stage
/// fits the window (`OnboardingStageGeometry`), content keeps a readable
/// width, and only phones stay upright.
void main() {
  const phones = [
    (Size(320, 568), EdgeInsets.only(top: 20)),
    (Size(375, 667), EdgeInsets.only(top: 20)),
    (Size(375, 812), EdgeInsets.only(top: 47, bottom: 34)),
    (Size(390, 844), EdgeInsets.only(top: 47, bottom: 34)),
    (Size(412, 915), EdgeInsets.only(top: 24, bottom: 24)),
    (Size(440, 956), EdgeInsets.only(top: 62, bottom: 34)),
  ];
  const portrait = [
    ('iPhone Duo folded', Size(466, 678), EdgeInsets.only(top: 44, bottom: 21)),
    ('iPhone Duo open', Size(626, 890), EdgeInsets.only(top: 24, bottom: 20)),
    ('iPad 9th generation', Size(810, 1080), EdgeInsets.only(top: 20)),
    ('iPad mini', Size(744, 1133), EdgeInsets.only(top: 24, bottom: 20)),
    ('iPad 11-inch', Size(820, 1180), EdgeInsets.only(top: 24, bottom: 20)),
    ('iPad 13-inch', Size(1032, 1376), EdgeInsets.only(top: 24, bottom: 20)),
    ('half an iPad turned', Size(590, 820), EdgeInsets.only(top: 24, bottom: 20)),
    ('Galaxy Fold open', Size(707, 823), EdgeInsets.only(top: 32, bottom: 24)),
    ('Android tablet', Size(800, 1280), EdgeInsets.only(top: 24, bottom: 48)),
  ];
  const landscape = [
    ('iPhone Duo open, turned', Size(890, 626), EdgeInsets.only(top: 24, bottom: 20)),
    ('iPad 11-inch, turned', Size(1180, 820), EdgeInsets.only(top: 24, bottom: 20)),
    ('iPad 13-inch, turned', Size(1376, 1032), EdgeInsets.only(top: 24, bottom: 20)),
    ('Pixel Tablet', Size(1280, 800), EdgeInsets.only(top: 24, bottom: 48)),
  ];

  group('onboarding stage', () {
    test('a phone keeps the approved layout exactly', () {
      for (final (size, padding) in phones) {
        for (final snug in [false, true]) {
          final stage = OnboardingStageGeometry.forWindow(size, padding, snugFloor: snug);
          expect(stage.frame, Rect.fromLTWH(0, 0, size.width, size.width * 16 / 9), reason: '$size');
          expect(stage.controlsTop, size.width * (snug ? 1.275 : 1.3), reason: '$size');
          expect(stage.beside, isFalse);
          expect(stage.controlsWidth, double.infinity);
          expect(stage.wordsWidth, size.width);
        }
      }
    });

    for (final (name, size, padding) in [...portrait, ...landscape]) {
      test('$name: Travi whole, on the same mark every beat, the controls a phone\'s room', () {
        final stage = OnboardingStageGeometry.forWindow(size, padding);
        final desk = OnboardingStageGeometry.forWindow(size, padding, snugFloor: true);
        // The camera never moves between beats.
        expect(desk.frame, stage.frame);
        expect(desk.beside, stage.beside);
        final frame = stage.frame;
        expect(frame.width, lessThanOrEqualTo(OnboardingStageGeometry.maxFrameWidth));
        expect(frame.left, greaterThanOrEqualTo(0));
        expect(frame.right, lessThanOrEqualTo(size.width));
        // His shadow (1.26 frame widths) above the bottom edge.
        expect(frame.top + 1.26 * frame.width, lessThanOrEqualTo(size.height - padding.bottom + .5));
        expect(stage.controlsWidth, lessThanOrEqualTo(OnboardingStageGeometry.maxControlsWidth));
        if (stage.beside) {
          // Beside him, never over him.
          expect(stage.column.left, greaterThanOrEqualTo(frame.right));
          expect(stage.column.right, lessThanOrEqualTo(size.width));
        } else {
          // The words clear of his head, the controls a phone's floor under him.
          final words = padding.top + 12 + OnboardingStageGeometry.wordsHeight(stage.wordsWidth);
          expect(words, lessThanOrEqualTo(frame.top + OnboardingStageGeometry.traviTop * frame.width + .5));
          final floor = size.height - padding.bottom - 16 - stage.controlsTop;
          expect(floor, greaterThanOrEqualTo(stage.controlsWidth * .86 - .5), reason: 'room for the pass desk');
          expect((frame.center.dx - size.width / 2).abs(), lessThan(.5), reason: 'centred');
        }
      });
    }

    test('a turned tablet stands Travi beside the words, larger than he would be under them', () {
      for (final (name, size, padding) in landscape) {
        final stage = OnboardingStageGeometry.forWindow(size, padding);
        expect(stage.beside, isTrue, reason: name);
        // Upright, the same screen stacks.
        final upright = OnboardingStageGeometry.forWindow(size.flipped, padding);
        expect(upright.beside, isFalse, reason: name);
      }
    });

    test('a tall phone-wide window keeps the phone layout', () {
      final slideOver = OnboardingStageGeometry.forWindow(const Size(375, 1180), EdgeInsets.zero);
      expect(slideOver.frame, Rect.fromLTWH(0, 0, 375, 375 / OnboardingCamera.aspect));
    });
  });

  group('readable width', () {
    test('a phone keeps its margins; wider screens centre the content', () {
      for (final (size, _) in phones) {
        expect(readableInsetFor(size.width), 0, reason: '$size');
      }
      expect(readableInsetFor(820), 124);
      expect(readableInsetFor(1180), 304);
      expect(readableInsetFor(820, maxWidth: 600), 110);
    });
  });

  group('orientation', () {
    test('a phone stays upright, a folded iPhone Duo included', () {
      for (final (size, _) in phones) {
        expect(OrientationPolicy.orientationsFor(size), [DeviceOrientation.portraitUp], reason: '$size');
      }
      expect(OrientationPolicy.orientationsFor(const Size(466, 678)), [DeviceOrientation.portraitUp]);
    });

    test('a tablet or an open foldable turns, either way up', () {
      for (final (name, size, _) in [...portrait, ...landscape]) {
        if (size.shortestSide < 600) continue;
        expect(OrientationPolicy.orientationsFor(size), isEmpty, reason: name);
      }
    });
  });
}
