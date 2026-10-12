import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/local_date.dart';
import 'package:travary/logic/onboarding_films.dart';
import 'package:travary/logic/travi_cameos.dart';

void main() {
  test('each moment has its pose: reading, the folio open, the oops, the wave', () {
    expect(
      {for (final moment in TraviMoment.values) moment: moment.pose},
      {
        TraviMoment.reading: TraviPose.reading,
        TraviMoment.waiting: TraviPose.folioOpen,
        TraviMoment.oops: TraviPose.oops,
        TraviMoment.hello: TraviPose.hello,
      },
    );
  });

  test('every cameo has its key frame on disk', () {
    for (final moment in TraviMoment.values) {
      expect(traviStills, contains(moment.pose), reason: moment.name);
      expect(File(traviStillAsset(moment.pose)).existsSync(), isTrue, reason: moment.name);
    }
  });

  test('he moves only while something is happening, on a pose with an idle loop', () {
    expect(
      [
        for (final moment in TraviMoment.values)
          if (moment.moves) moment,
      ],
      [TraviMoment.reading],
    );
    expect(traviIdles, contains(TraviMoment.reading.pose));
  });

  group('peeks', () {
    test('tapping the countdown\'s tag: how he feels about the days left', () {
      expect(countdownReactionFor(1), TraviPeek.today);
      expect(countdownReactionFor(2), TraviPeek.ready);
      expect(countdownReactionFor(3), TraviPeek.ready);
      expect(countdownReactionFor(4), TraviPeek.packing);
      expect(countdownReactionFor(14), TraviPeek.packing);
      expect(countdownReactionFor(15), TraviPeek.cheer);
      expect(countdownReactionFor(200), TraviPeek.cheer);
    });

    test('on his own he greets at most once a day', () {
      const today = LocalDate(2026, 10, 10);
      expect(greetsToday(today: today), isTrue);
      expect(greetsToday(today: today, lastGreeted: const LocalDate(2026, 10, 9)), isTrue);
      expect(greetsToday(today: today, lastGreeted: today), isFalse);
    });

    test('every peek and the lounge have their films and stills on disk', () {
      expect(traviPeeks.keys, TraviPeek.values);
      for (final reel in traviPeeks.values) {
        for (final asset in [reel.still.asset, reel.up.asset, reel.down.asset]) {
          expect(File(asset).existsSync(), isTrue, reason: asset);
        }
        // Up into the pose, and down again quicker.
        expect(reel.down.seconds, lessThan(reel.up.seconds));
      }
      expect(File(traviLoungeStill.asset).existsSync(), isTrue);
      expect(File(traviLoungeSip.asset).existsSync(), isTrue);
    });

    test('every clip and still fits the square canvas', () {
      final boxes = [
        for (final reel in traviPeeks.values) ...[reel.still.box, reel.up.box, reel.down.box],
        traviLoungeStill.box,
        traviLoungeSip.box,
      ];
      for (final box in boxes) {
        expect(box.left + box.width, lessThanOrEqualTo(traviCameoCanvas));
        expect(box.top + box.height, lessThanOrEqualTo(traviCameoCanvas));
      }
      // A peek is cut off by the edge he hides behind: his pose runs into it.
      for (final reel in traviPeeks.values) {
        expect(reel.still.box.top + reel.still.box.height, traviCameoCanvas);
      }
    });
  });
}
