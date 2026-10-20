import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/onboarding_scene.dart';
import 'package:travary/design/widgets/pass_badge.dart';
import 'package:travary/design/widgets/travi_player.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/features/onboarding/pass_confirmation_stage.dart';
import 'package:travary/logic/onboarding_films.dart';

/// A bought pass on the stage: the desk's badge lands when Travi flicks it
/// down, and the pass shows on the ticket while he holds it.
void main() {
  late _StageState stage;

  Future<void> pump(WidgetTester tester, {bool reduced = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: _Stage(onState: (state) => stage = state),
        ),
      ),
    );
  }

  const holiday = (kind: OfferKind.tripPass, restored: false);
  TraviFilm film(String id) =>
      TraviFilm(id, TraviPose.passHold, TraviPose.cheer, (left: 0, top: 0, width: 1, height: 1), seconds: 1);

  group('with films playing', () {
    setUp(() => TraviPlayer.playback = true);
    tearDown(() => TraviPlayer.playback = false);

    testWidgets('the badge lands at the toss\'s handoff, not before', (tester) async {
      await pump(tester);
      stage.confirmPass(holiday);
      await tester.pump();
      expect(stage.passLanded, isFalse);
      stage.passHandoff(film('tag-toss'));
      expect(stage.passLanded, isFalse, reason: 'another film\'s handoff');
      stage.passHandoff(film(passTossFilm));
      await tester.pump();
      expect(stage.passLanded, isTrue);
    });

    testWidgets('should the film never hand over, it lands anyway', (tester) async {
      await pump(tester);
      stage.confirmPass(holiday);
      await tester.pump(const Duration(seconds: 6));
      expect(stage.passLanded, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(stage.passLanded, isTrue);
    });

    testWidgets('reduced motion: it\'s simply there', (tester) async {
      await pump(tester, reduced: true);
      stage.confirmPass(holiday);
      await tester.pump();
      expect(stage.passLanded, isTrue);
    });

    testWidgets('the pass shows on the ticket only while he holds it', (tester) async {
      await pump(tester);
      expect(stage.passOverlay, isNull, reason: 'nothing bought yet');
      stage.confirmPass(holiday);
      expect(stage.passCues(const []), traviCuesForPassConfirmed());
      Future<double> opacity() async {
        await tester.pumpAndSettle();
        return tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
      }

      stage.passPose(null);
      expect(await opacity(), 0, reason: 'lifting it');
      stage.passPose(TraviPose.passHold);
      expect(await opacity(), 1);
      stage.passPose(null);
      expect(await opacity(), 0, reason: 'winding up the flick');
    });
  });

  testWidgets('without films (tests, previews) the badge is down at once', (tester) async {
    await pump(tester);
    stage.confirmPass(holiday);
    await tester.pump();
    expect(stage.passLanded, isTrue);
  });

  testWidgets('on the ticket: fitted to its width, centred on it', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 941, height: 1672, child: HeldPassBadge(kind: OfferKind.plusAnnual, width: 941)),
      ),
    );
    final badge = tester.getRect(find.byKey(const ValueKey('held-pass-badge')));
    const art = PassBadgeLayout.artTicket;
    final ticket = Rect.fromLTRB(
      badge.left + art.left * badge.width,
      badge.top + art.top * badge.height,
      badge.left + art.right * badge.width,
      badge.top + art.bottom * badge.height,
    );
    expect(ticket.left, closeTo(402, 0.5));
    expect(ticket.right, closeTo(640, 0.5));
    expect(ticket.center.dy, closeTo((892 + 989) / 2, 0.5));
    expect(tester.widget<PassBadge>(find.byType(PassBadge)).kind, OfferKind.plusAnnual);
  });
}

class _Stage extends StatefulWidget {
  const _Stage({required this.onState});
  final ValueChanged<_StageState> onState;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> with PassConfirmationStage {
  @override
  void initState() {
    super.initState();
    widget.onState(this);
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 941, height: 1672, child: passOverlay?.call(context, 941) ?? const SizedBox());
}
