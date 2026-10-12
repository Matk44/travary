import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/travi_cameo.dart';
import 'package:travary/design/widgets/travi_player.dart';
import 'package:travary/logic/onboarding_films.dart';
import 'package:travary/logic/travi_cameos.dart';

/// Travi's cameos: his key frame cropped to where he stands, the same size
/// in every pose.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  Widget app(Widget child) => MaterialApp(
    theme: buildTravaryTheme(),
    home: Scaffold(body: Center(child: child)),
  );

  String? shownStill(WidgetTester tester) =>
      tester.widgetList<Image>(find.byType(Image)).map((i) => (i.image as AssetImage).assetName).lastOrNull;

  testWidgets('shows the moment\'s key frame at once, the same size whatever the pose', (tester) async {
    final sizes = <Size>{};
    for (final moment in TraviMoment.values) {
      await tester.pumpWidget(app(TraviCameo(key: ValueKey(moment), moment: moment, height: 120)));
      await tester.pump();
      expect(shownStill(tester), traviStillAsset(moment.pose), reason: moment.name);
      sizes.add(tester.getSize(find.byType(TraviCameo)));
    }
    expect(sizes, hasLength(1));
    expect(sizes.single.height, 120);
  });

  test('smaller on a short phone, so what he sits above still fits', () {
    expect(TraviCameo.fittedHeight(const Size(320, 568)), 72);
    expect(TraviCameo.fittedHeight(const Size(375, 667)), closeTo(93.5, .1));
    expect(TraviCameo.fittedHeight(const Size(390, 844)), 132);
    expect(TraviCameo.fittedHeight(const Size(430, 932)), 132);
  });

  testWidgets('holds still where the moment doesn\'t move, even with films on', (tester) async {
    TraviPlayer.playback = true;
    addTearDown(() => TraviPlayer.playback = false);
    await tester.pumpWidget(app(const TraviCameo(moment: TraviMoment.waiting)));
    await tester.pumpAndSettle();
    expect(shownStill(tester), traviStillAsset(TraviPose.folioOpen));
  });

  testWidgets('a message beside him wraps on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        const TraviMessage(
          moment: TraviMoment.oops,
          text: 'Couldn\'t load your bookings (permission-denied). Try again shortly.',
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(shownStill(tester), traviStillAsset(TraviPose.oops));
  });
}
