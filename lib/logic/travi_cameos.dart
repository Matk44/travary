/// Travi's cameos around the app (docs/onboarding/HANDOVER_2026-10-10.md):
/// small, quick and never in the way. Which key frame suits each moment,
/// whether he moves there, and when he greets the traveller on his own.
/// Pure rules; `TraviCameo`, `TraviPeekStage` and `TraviClipPlayer` draw
/// them.
///
/// Never on tickets, boarding passes, flight status, travel documents, a
/// busy Today, or paywalls outside onboarding.
library;

import '../domain/local_date.dart';
import 'onboarding_films.dart';

part 'travi_cameo_assets.dart';

/// Where Travi turns up outside onboarding, in one of onboarding's poses.
enum TraviMoment {
  /// Smart Import reading a file: he studies it instead of a spinner.
  reading(TraviPose.reading, moves: true),

  /// Nothing planned (no trips yet, nothing coming up): his folio open,
  /// ready for a booking.
  waiting(TraviPose.folioOpen),

  /// Something went wrong (a file he couldn't read, a change that didn't
  /// sync): a sheepish shrug.
  oops(TraviPose.oops),

  /// Offering a hand (reminders, on a trip's page): a wave.
  hello(TraviPose.hello);

  const TraviMoment(this.pose, {this.moves = false});

  final TraviPose pose;

  /// He loops his idle only while he shows that something's happening;
  /// elsewhere he holds the key frame, so a screen someone stays on never
  /// fidgets. Reduced motion holds every still.
  final bool moves;
}

/// Travi popping up from behind something (the countdown postcard, the New
/// trip sheet, a new trip's plan) with a reaction, then ducking back down
/// (docs/mockups/travi-cameos-v1/).
enum TraviPeek {
  /// Hello: the first time Today counts down on a new day, and a new trip.
  wave,

  /// A new trip saved, and a trip still weeks away.
  cheer,

  /// Holding up a swimsuit and sunhat: a trip a week or two away.
  packing,

  /// Sunglasses, sunhat, thumbs up: a trip a few days away.
  ready,

  /// Waving a (blank) boarding pass: off tomorrow.
  today,
}

/// Tapping the countdown's luggage tag: how he feels about the days left.
/// The countdown shows from the day before a trip (on the day itself, Today
/// shows the trip), so the boarding pass comes out then.
TraviPeek countdownReactionFor(int daysLeft) => switch (daysLeft) {
  <= 1 => TraviPeek.today,
  <= 3 => TraviPeek.ready,
  <= 14 => TraviPeek.packing,
  _ => TraviPeek.cheer,
};

/// Whether Travi greets the traveller on his own today: the first time
/// Today counts down to a trip, or shows a free day, on a new day. On his
/// own he moves at most once a day; otherwise only when tapped.
bool greetsToday({required LocalDate today, LocalDate? lastGreeted}) => lastGreeted != today;

/// How long a reaction holds before he ducks back down.
const traviPeekHold = Duration(milliseconds: 700);

/// A cameo film (`assets/travi/cameos/films/`), played once, at its [box]
/// on the square [traviCameoCanvas].
class TraviClip {
  const TraviClip(this.id, this.box, {required this.seconds});
  final String id;
  final TraviBox box;
  final double seconds;

  String get asset => 'assets/travi/cameos/films/$id.webp';
}

/// A cameo pose as a still (reduced motion, and where he rests).
class TraviStill {
  const TraviStill(this.id, this.box);
  final String id;
  final TraviBox box;

  String get asset => 'assets/travi/cameos/stills/$id.webp';
}

/// A peek reaction: its pose, and the films up into it and back down.
class TraviPeekReel {
  const TraviPeekReel({required this.still, required this.up, required this.down});
  final TraviStill still;
  final TraviClip up;
  final TraviClip down;
}
