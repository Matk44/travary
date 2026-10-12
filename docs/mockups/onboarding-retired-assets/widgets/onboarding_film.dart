import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// One of Travi's films over its stills: [once] plays first, then [loop]
/// repeats until the scene changes. Interaction never waits for it. Reduced
/// motion and a missing decoder show [settled] instead; [onFinished] still
/// fires (straight away), so nothing depends on playback.
class OnboardingFilm extends StatefulWidget {
  const OnboardingFilm({
    super.key,
    required this.poster,
    String? settled,
    this.once,
    this.loop,
    this.onFinished,
    this.active = true,
  }) : settled = settled ?? poster;

  /// The first frame, shown until playback starts.
  final String poster;

  /// The last frame, shown when the film can't play.
  final String settled;
  final String? once;
  final String? loop;

  /// After [once] ends, or at once when it can't play.
  final VoidCallback? onFinished;

  /// False while another screen or a system sheet (sign-in) is on top.
  final bool active;

  @override
  State<OnboardingFilm> createState() => _OnboardingFilmState();
}

class _OnboardingFilmState extends State<OnboardingFilm> with WidgetsBindingObserver {
  VideoPlayerController? _once;
  VideoPlayerController? _loop;
  bool _ready = false;
  bool _looping = false;
  bool _failed = false;
  bool _finished = false;
  bool _foreground = true;
  bool _reduced = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      if (_reduced || (widget.once == null && widget.loop == null)) {
        _finish();
      } else {
        unawaited(_initialize());
      }
    }
    _playback();
  }

  Future<void> _initialize() async {
    final once = widget.once == null ? null : _once = VideoPlayerController.asset(widget.once!);
    final loop = widget.loop == null ? null : _loop = VideoPlayerController.asset(widget.loop!);
    try {
      await Future.wait([?once?.initialize(), ?loop?.initialize()]);
      if (!mounted) return;
      await once?.setVolume(0);
      await loop?.setVolume(0);
      await loop?.setLooping(true);
      if (!mounted) return;
      once?.addListener(_ended);
      loop?.addListener(_loopError);
      _looping = once == null;
      setState(() => _ready = true);
      _playback();
    } catch (_) {
      _fail();
    }
  }

  void _ended() {
    final value = _once?.value;
    if (!mounted || _looping || _failed || _finished || value == null) return;
    if (value.hasError) return _fail();
    if (value.isInitialized && value.duration > Duration.zero && value.position >= value.duration) {
      setState(() => _looping = _loop != null);
      _finish();
      _playback();
    }
  }

  void _loopError() {
    if ((_loop?.value.hasError ?? false)) _fail();
  }

  void _fail() {
    if (!mounted || _failed) return;
    setState(() => _failed = true);
    _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    final done = widget.onFinished;
    if (done != null) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? done() : null);
  }

  void _playback() {
    if (!_ready) return;
    final play = widget.active && _foreground && !_reduced && !_failed;
    final current = _looping ? _loop : _once;
    final other = _looping ? _once : _loop;
    if (other != null) unawaited(_control(other, play: false));
    if (current != null) unawaited(_control(current, play: play));
  }

  Future<void> _control(VideoPlayerController controller, {required bool play}) async {
    try {
      if (play) {
        await controller.play();
      } else {
        await controller.pause();
      }
    } catch (_) {
      // A decoder can fail after initialising. Keep the still.
      _fail();
    }
  }

  @override
  void didUpdateWidget(OnboardingFilm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _playback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _playback();
  }

  @override
  Widget build(BuildContext context) {
    final current = _looping ? _loop : _once;
    final showFilm = _ready && !_failed && !_reduced && current != null && current.value.isInitialized;
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _finished || _failed || _reduced ? widget.settled : widget.poster,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            gaplessPlayback: true,
          ),
          if (showFilm)
            FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: current.value.size.width,
                height: current.value.size.height,
                child: VideoPlayer(current),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _once?.removeListener(_ended);
    _loop?.removeListener(_loopError);
    unawaited(_once?.dispose());
    unawaited(_loop?.dispose());
    super.dispose();
  }
}
