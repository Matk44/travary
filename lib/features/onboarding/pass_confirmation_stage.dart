import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/widgets/onboarding_scene.dart';
import '../../design/widgets/travi_player.dart';
import '../../logic/onboarding_films.dart';
import '../../logic/onboarding_journey.dart';
import '../../logic/pass_confirmation.dart';

/// The stage's side of a bought pass, for the screens that put the pass desk
/// on it (the paywall and both onboarding desks): Travi lifts a blank ticket
/// (`traviCuesForPassConfirmed`), the bought pass shows on it while he holds
/// it ([passOverlay]), and the desk's badge lands ([passLanded]) as he
/// flicks it down: the `pass-toss` handoff. Without films (reduced motion,
/// tests) it lands at once; should a film not load, after [_landingAtLatest].
mixin PassConfirmationStage<T extends StatefulWidget> on State<T> {
  /// The pass just bought or restored here.
  PassConfirmation? confirmed;

  /// The desk's badge is down.
  bool passLanded = true;

  TraviPose? _resting;
  Timer? _landing;

  static const _landingAtLatest = Duration(seconds: 7);

  void confirmPass(PassConfirmation confirmation) {
    final acting = TraviPlayer.playback && !MediaQuery.disableAnimationsOf(context);
    setState(() {
      confirmed = confirmation;
      passLanded = !acting;
    });
    if (acting) _landing = Timer(_landingAtLatest, _land);
  }

  void _land() {
    _landing?.cancel();
    if (mounted && !passLanded) setState(() => passLanded = true);
  }

  /// For the scene's `onPose`.
  void passPose(TraviPose? pose) {
    if (mounted && confirmed != null && pose != _resting) setState(() => _resting = pose);
  }

  /// For the scene's `onHandoff`.
  void passHandoff(TraviFilm film) {
    if (film.id == passTossFilm) _land();
  }

  /// Travi's cues: [otherwise], or the bought pass's once there is one.
  List<TraviCue> passCues(List<TraviCue> otherwise) => confirmed == null ? otherwise : traviCuesForPassConfirmed();

  /// The stage's words: [otherwise], or the bought pass's.
  OnboardingWords passWords(OnboardingWords otherwise) => switch (confirmed) {
    final c? => passConfirmedWords(c.kind, restored: c.restored),
    null => otherwise,
  };

  /// The bought pass on the ticket he holds, fading as he winds up the flick.
  Widget Function(BuildContext context, double width)? get passOverlay => switch (confirmed) {
    final c? => (context, width) => AnimatedOpacity(
      opacity: _resting == TraviPose.passHold ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      child: HeldPassBadge(kind: c.kind, width: width),
    ),
    null => null,
  };

  @override
  void dispose() {
    _landing?.cancel();
    super.dispose();
  }
}
