import 'package:flutter/widgets.dart';

import 'travi_player.dart';

/// The owner's pleading pose, with a small hands/eyes idle and a quiet hold.
/// Image pauses its codec under HomeShell's TickerMode when Profile is hidden.
/// Reduced motion uses the approved still without loading the animation.
class ProfileTravi extends StatelessWidget {
  const ProfileTravi({super.key});

  static const stillAsset = 'assets/travi/cameos/stills/profile-plea.webp';
  static const animationAsset = 'assets/travi/cameos/films/profile-plea.webp';

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Image.asset(
        TraviPlayer.playback && !MediaQuery.disableAnimationsOf(context) ? animationAsset : stillAsset,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}
