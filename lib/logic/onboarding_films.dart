/// Travi's films (docs/onboarding/STORYBOARD_V2.md): the key frames he
/// holds, the moves between them, and the way through them from one
/// onboarding beat to the next. Pure rules; `TraviPlayer` plays them.
library;

import 'onboarding_journey.dart';

part 'onboarding_film_assets.dart';

/// The key frames (docs/mockups/onboarding-keyframes-v1/): every film starts
/// and ends on one, so any chain of films is seamless.
enum TraviPose {
  empty,
  hello,
  wow,
  tag,
  toss,
  folioOpen,
  folioFull,
  reading,
  card,
  proud,
  idTag,
  envelope,
  linked,
  present,
  cheer,
  wave,
  oops,
}

/// Where a clip sits on [traviCanvas], in pixels.
typedef TraviBox = ({int left, int top, int width, int height});

/// A move from one key frame to another (or an idle loop on one).
class TraviFilm {
  const TraviFilm(this.id, this.from, this.to, this.box, {required this.seconds, this.handoff});
  final String id;
  final TraviPose from;
  final TraviPose to;
  final TraviBox box;
  final double seconds;

  /// Seconds in, when what he throws has left the frame: the live tag or
  /// card takes over there.
  final double? handoff;

  String get asset => 'assets/onboarding/travi/films/$id.webp';
}

/// A pose's still (`assets/onboarding/travi/stills/`).
String traviStillAsset(TraviPose pose) => 'assets/onboarding/travi/stills/${pose.name}.webp';

/// A pose to reach and how long to hold it before the next one. The last
/// cue holds until the beat changes, looping its idle. [direct]: dissolve
/// there instead of playing the films between, when they'd act out
/// something that isn't happening (the ID tag, with no sign-in offered).
typedef TraviCue = ({TraviPose pose, Duration hold, bool direct});

TraviCue _cue(TraviPose pose, [Duration hold = Duration.zero, bool direct = false]) =>
    (pose: pose, hold: hold, direct: direct);

/// What Travi does at [beat]. [bought]: a pass was just bought (he cheers
/// first). [fresh]: the booking was saved just now, so he shows its card
/// before tossing it into the plan; coming back to it, he's simply proud.
/// [signInSkipped]: the desk comes straight after the booking, with no
/// sign-in offered, so he doesn't take out the ID tag on the way.
List<TraviCue> traviCuesFor(
  OnboardingBeat beat, {
  bool bought = false,
  bool fresh = false,
  bool signInSkipped = false,
}) => switch (beat) {
  OnboardingBeat.arrival => [_cue(TraviPose.hello)],
  OnboardingBeat.dates => [_cue(TraviPose.tag)],
  OnboardingBeat.booking => [_cue(TraviPose.folioOpen)],
  OnboardingBeat.reading => [_cue(TraviPose.reading)],
  OnboardingBeat.misread => [_cue(TraviPose.oops)],
  OnboardingBeat.proof when fresh => [_cue(TraviPose.card, const Duration(milliseconds: 1800)), _cue(TraviPose.proud)],
  OnboardingBeat.proof => [_cue(TraviPose.proud)],
  OnboardingBeat.account => [_cue(TraviPose.idTag)],
  OnboardingBeat.email => [_cue(TraviPose.envelope)],
  OnboardingBeat.signedIn => [_cue(TraviPose.linked)],
  OnboardingBeat.desk when signInSkipped => [_cue(TraviPose.present, Duration.zero, true)],
  OnboardingBeat.desk => [_cue(TraviPose.present)],
  OnboardingBeat.sendoff when bought => [_cue(TraviPose.cheer), _cue(TraviPose.wave), _cue(TraviPose.folioFull)],
  OnboardingBeat.sendoff => [_cue(TraviPose.wave), _cue(TraviPose.folioFull)],
};

/// What Travi does once a pass is bought (or restored) on the pass desk:
/// he cheers, from the desk's present (the `cheer` film).
List<TraviCue> traviCuesForPassConfirmed() => [_cue(TraviPose.cheer)];

/// The films from [from] to [to], fewest first; empty when he's there, and
/// null when no chain of films connects them (he dissolves instead).
List<TraviFilm>? traviRoute(TraviPose from, TraviPose to, {List<TraviFilm> films = traviFilms}) {
  if (from == to) return const [];
  final via = <TraviPose, TraviFilm>{};
  final queue = [from];
  final seen = {from};
  while (queue.isNotEmpty) {
    final pose = queue.removeAt(0);
    for (final film in films.where((f) => f.from == pose && !seen.contains(f.to))) {
      seen.add(film.to);
      via[film.to] = film;
      if (film.to == to) {
        final route = <TraviFilm>[];
        for (var at = to; at != from; at = route.first.from) {
          route.insert(0, via[at]!);
        }
        return route;
      }
      queue.add(film.to);
    }
  }
  return null;
}
