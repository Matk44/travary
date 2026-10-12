import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Finite roll-in followed by the approved idle. Interaction is immediate;
/// unavailable playback and reduced motion both keep the settled still.
class OnboardingArrival extends StatefulWidget {
  const OnboardingArrival({super.key, required this.active});
  final bool active;
  @override
  State<OnboardingArrival> createState() => _OnboardingArrivalState();
}

class _OnboardingArrivalState extends State<OnboardingArrival> with WidgetsBindingObserver {
  VideoPlayerController? _entrance;
  VideoPlayerController? _idle;
  bool _ready = false;
  bool _waiting = false;
  bool _started = false;
  bool _failed = false;
  bool _foreground = true;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (!_started && !_reduced && widget.active) {
      _started = true;
      unawaited(_initialize());
    }
    _playback();
  }

  Future<void> _initialize() async {
    final entrance = _entrance = VideoPlayerController.asset('assets/onboarding/travi-entrance-playback-v1.mp4');
    final idle = _idle = VideoPlayerController.asset('assets/onboarding/travi-idle-loop-v1.mp4');
    try {
      await Future.wait([entrance.initialize(), idle.initialize()]);
      if (!mounted) return;
      await entrance.setVolume(0);
      await idle.setVolume(0);
      await idle.setLooping(true);
      if (!mounted) return;
      entrance.addListener(_arrived);
      idle.addListener(_idleError);
      setState(() => _ready = true);
      _playback();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _arrived() {
    final value = _entrance?.value;
    if (!mounted || _waiting || _failed || value == null) return;
    if (value.hasError) {
      setState(() => _failed = true);
      return;
    }
    if (value.isInitialized && value.position >= value.duration) {
      setState(() => _waiting = true);
      _playback();
    }
  }

  void _playback() {
    if (!_ready) return;
    final shouldPlay = widget.active && _foreground && !_reduced && !_failed;
    final active = _waiting ? _idle : _entrance;
    final inactive = _waiting ? _entrance : _idle;
    unawaited(_control(inactive!, play: false));
    unawaited(_control(active!, play: shouldPlay));
  }

  void _idleError() {
    if (mounted && !_failed && (_idle?.value.hasError ?? false)) {
      setState(() => _failed = true);
    }
  }

  Future<void> _control(VideoPlayerController controller, {required bool play}) async {
    try {
      if (play) {
        await controller.play();
      } else {
        await controller.pause();
      }
    } catch (_) {
      // A decoder can fail after initialization. Keep the still actionable.
      if (mounted && !_failed) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(OnboardingArrival oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_started && widget.active && !_reduced) {
      _started = true;
      unawaited(_initialize());
    }
    _playback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _playback();
  }

  @override
  Widget build(BuildContext context) {
    final active = _waiting ? _idle : _entrance;
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _ready || _waiting || _failed || _reduced
                ? 'assets/onboarding/travi-settled-v1.png'
                : 'assets/onboarding/entrance-start-v1.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          if (_ready && !_failed && !_reduced && active != null)
            FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: active.value.size.width,
                height: active.value.size.height,
                child: VideoPlayer(active),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entrance?.removeListener(_arrived);
    _idle?.removeListener(_idleError);
    unawaited(_entrance?.dispose());
    unawaited(_idle?.dispose());
    super.dispose();
  }
}
