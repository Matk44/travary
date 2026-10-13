import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/widgets/travi_player.dart';
import 'package:travary/logic/onboarding_films.dart';

/// Without films (tests, reduced motion) Travi goes straight to each cue's
/// key frame and reports where he rests, so the story never waits on him.
void main() {
  Widget player(List<TraviCue> cues, {TraviPose? start, ValueChanged<TraviPose?>? onPose}) => MaterialApp(
    home: SizedBox(
      width: 390,
      height: 694,
      child: TraviPlayer(cues: cues, start: start, onPose: onPose),
    ),
  );

  String? shownStill(WidgetTester tester) {
    final images = tester.widgetList<Image>(find.byType(Image));
    return images.map((i) => (i.image as AssetImage).assetName).lastOrNull;
  }

  testWidgets('rests on the last cue and reports each pose on the way', (tester) async {
    final poses = <TraviPose?>[];
    await tester.pumpWidget(
      player(
        const [
          (pose: TraviPose.card, hold: Duration(seconds: 2), direct: false),
          (pose: TraviPose.proud, hold: Duration.zero, direct: false),
        ],
        start: TraviPose.folioOpen,
        onPose: poses.add,
      ),
    );
    await tester.pumpAndSettle();
    expect(poses.whereType<TraviPose>(), [TraviPose.card, TraviPose.proud]);
    expect(shownStill(tester), traviStillAsset(TraviPose.proud));
  });

  testWidgets('new cues carry on from where he is', (tester) async {
    final poses = <TraviPose?>[];
    await tester.pumpWidget(
      player(const [(pose: TraviPose.tag, hold: Duration.zero, direct: false)], onPose: poses.add),
    );
    await tester.pumpAndSettle();
    expect(shownStill(tester), traviStillAsset(TraviPose.tag));
    await tester.pumpWidget(
      player(const [(pose: TraviPose.folioOpen, hold: Duration.zero, direct: false)], onPose: poses.add),
    );
    await tester.pumpAndSettle();
    expect(shownStill(tester), traviStillAsset(TraviPose.folioOpen));
    expect(poses.whereType<TraviPose>().last, TraviPose.folioOpen);
  });
}
