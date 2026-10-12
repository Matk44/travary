import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/logic/onboarding_films.dart';
import 'package:travary/logic/onboarding_journey.dart';

void main() {
  const box = (left: 0, top: 0, width: 10, height: 10);
  TraviFilm film(String id, TraviPose from, TraviPose to) => TraviFilm(id, from, to, box, seconds: 1);

  test('every pose has a bundled still, and every film and idle is bundled', () {
    for (final pose in TraviPose.values) {
      expect(traviStills, contains(pose), reason: pose.name);
      expect(File(traviStillAsset(pose)).existsSync(), isTrue, reason: pose.name);
    }
    for (final film in [...traviFilms, ...traviIdles.values]) {
      expect(File(film.asset).existsSync(), isTrue, reason: film.id);
      final b = film.box;
      expect(b.left + b.width, lessThanOrEqualTo(traviCanvas.width), reason: film.id);
      expect(b.top + b.height, lessThanOrEqualTo(traviCanvas.height), reason: film.id);
    }
    for (final MapEntry(key: pose, value: idle) in traviIdles.entries) {
      expect((idle.from, idle.to), (pose, pose), reason: idle.id);
    }
  });

  test('the story plays through without a cut where its films exist', () {
    // Arrival → dates → booking → a saved booking → sign-in → passes.
    expect(traviRoute(TraviPose.empty, TraviPose.hello)!.map((f) => f.id), ['roll-in']);
    expect(traviRoute(TraviPose.hello, TraviPose.tag)!.map((f) => f.id), ['world', 'tag-out']);
    expect(traviRoute(TraviPose.tag, TraviPose.folioOpen)!.map((f) => f.id), ['tag-toss', 'folio-up']);
    expect(traviRoute(TraviPose.folioOpen, TraviPose.card)!.map((f) => f.id), ['card-out']);
    expect(traviRoute(TraviPose.card, TraviPose.proud)!.map((f) => f.id), ['card-toss', 'proud']);
    expect(traviRoute(TraviPose.proud, TraviPose.idTag)!.map((f) => f.id), ['id-tag']);
    expect(traviRoute(TraviPose.idTag, TraviPose.present)!.map((f) => f.id), ['guest']);
    // The form opens out of the folio and drops back into it.
    expect(traviRoute(TraviPose.folioOpen, TraviPose.folioFull)!.map((f) => f.id), ['folio-in']);
    expect(traviRoute(TraviPose.folioFull, TraviPose.card)!.map((f) => f.id), ['folio-out', 'card-out']);
  });

  test('routes take the fewest films, and nothing connects to nowhere', () {
    final films = [
      film('a', TraviPose.hello, TraviPose.wow),
      film('b', TraviPose.wow, TraviPose.tag),
      film('c', TraviPose.hello, TraviPose.tag),
      film('d', TraviPose.tag, TraviPose.toss),
    ];
    expect(traviRoute(TraviPose.hello, TraviPose.tag, films: films)!.map((f) => f.id), ['c']);
    expect(traviRoute(TraviPose.hello, TraviPose.toss, films: films)!.map((f) => f.id), ['c', 'd']);
    expect(traviRoute(TraviPose.tag, TraviPose.tag, films: films), isEmpty);
    expect(traviRoute(TraviPose.toss, TraviPose.hello, films: films), isNull);
  });

  test('each beat cues the pose its words go with', () {
    for (final beat in OnboardingBeat.values) {
      expect(traviCuesFor(beat), isNotEmpty, reason: beat.name);
    }
    expect(traviCuesFor(OnboardingBeat.arrival).single.pose, TraviPose.hello);
    expect(traviCuesFor(OnboardingBeat.reading).single.pose, TraviPose.reading);
    // A booking saved just now: its card first, then tossed into the plan.
    final fresh = traviCuesFor(OnboardingBeat.proof, fresh: true);
    expect(fresh.map((c) => c.pose), [TraviPose.card, TraviPose.proud]);
    expect(fresh.first.hold, greaterThan(Duration.zero));
    expect(traviCuesFor(OnboardingBeat.proof).single.pose, TraviPose.proud);
    // The goodbye ends on the open folio either way; a purchase gets a cheer.
    expect(traviCuesFor(OnboardingBeat.sendoff).map((c) => c.pose), [TraviPose.wave, TraviPose.folioFull]);
    expect(traviCuesFor(OnboardingBeat.sendoff, bought: true).map((c) => c.pose), [
      TraviPose.cheer,
      TraviPose.wave,
      TraviPose.folioFull,
    ]);
  });

  test('the booking beat says which day it sorted', () {
    expect(onboardingWordsFor(OnboardingBeat.proof, day: 1).text, 'Day 1,\n');
    expect(onboardingWordsFor(OnboardingBeat.proof).accent, 'handled.');
    expect(onboardingWordsFor(OnboardingBeat.misread, problem: 'Use a photo.').subtitle, 'Use a photo.');
  });
}
