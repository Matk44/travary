import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../logic/onboarding_films.dart';

/// Travi on the onboarding stage. He works through [cues] by playing the
/// films between his key frames (`logic/onboarding_films.dart`), holds where
/// a cue asks, then loops the last pose's idle until the cues change. A move
/// with no film yet (or reduced motion) dissolves instead. Every film starts
/// and ends on a key frame, so he never jumps.
///
/// New cues never cut a move short: the move in progress (or the idle's
/// cycle) speeds up to its end and he carries on from there. Laid across
/// the camera's frame: its width is [traviCanvas]'s.
class TraviPlayer extends StatefulWidget {
  const TraviPlayer({
    super.key,
    required this.cues,
    this.start,
    this.active = true,
    this.moves = true,
    this.onPose,
    this.onHandoff,
  });

  final List<TraviCue> cues;

  /// Where he is when first shown ([TraviPose.empty]: he rolls in). By
  /// default, already on the last cue.
  final TraviPose? start;

  /// False while something covers the stage: he holds still.
  final bool active;

  /// False: key frames only, and no films loaded (a cameo that holds still).
  final bool moves;

  /// He's come to rest on a pose (arrived, holding or idling), or set off
  /// (null).
  final ValueChanged<TraviPose?>? onPose;

  /// What he threw in this film has left the frame: the live tag or card
  /// takes over.
  final ValueChanged<TraviFilm>? onHandoff;

  /// Films play. Tests that pump until settled turn this off: key frames
  /// only, no holds.
  static bool playback = true;

  @override
  State<TraviPlayer> createState() => _TraviPlayerState();
}

sealed class _Step {}

class _Play extends _Step {
  _Play(this.film);
  final TraviFilm film;
}

class _Dissolve extends _Step {
  _Dissolve(this.pose);
  final TraviPose pose;
}

class _Rest extends _Step {
  _Rest(this.pose, this.hold);
  final TraviPose pose;

  /// Null on the last cue: he idles there.
  final Duration? hold;
}

/// A film being played: frames decoded a little ahead of the clock.
class _Reel {
  _Reel(this.film, this.codec, {required this.loop});
  final TraviFilm film;
  final ui.Codec codec;
  bool loop;
  double speed = 1;
  final ready = <ui.FrameInfo>[];
  int decoded = 0;
  int shown = 0;
  int? stopAt;
  bool decoding = false;
  bool handedOff = false;
  Duration clock = Duration.zero;
  Duration due = Duration.zero;
  Duration? last;

  bool get exhausted => stopAt != null ? decoded >= stopAt! : !loop && decoded >= codec.frameCount;

  /// Ends an idle at the end of its current cycle, quickly.
  void wrapUp() {
    loop = false;
    speed = 3;
    stopAt = (decoded ~/ codec.frameCount + (decoded % codec.frameCount == 0 ? 0 : 1)) * codec.frameCount;
  }

  void dispose() {
    for (final info in ready) {
      info.image.dispose();
    }
    ready.clear();
    codec.dispose();
  }
}

class _TraviPlayerState extends State<TraviPlayer> with SingleTickerProviderStateMixin {
  // His wheels on the floor (canvas px): the shadow under them.
  static const _shadow = Rect.fromLTRB(212, 664, 430, 684);
  static const _fade = Duration(milliseconds: 320);

  late final Ticker _ticker;
  late TraviPose _pose;
  late TraviPose _still;
  List<_Step> _plan = [];
  _Reel? _reel;
  ui.Image? _frame;
  TraviBox? _frameBox;
  Timer? _hold;
  Timer? _fadeTimer;
  bool _replan = false;
  bool _dissolving = false;
  bool _instant = false;
  int _token = 0;
  final _prefetched = <String, Future<ui.Codec>>{};

  bool get _reduced => MediaQuery.disableAnimationsOf(context);
  bool get _films => TraviPlayer.playback && widget.moves && !_reduced;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _pose = _still = widget.start ?? widget.cues.last.pose;
    WidgetsBinding.instance.addPostFrameCallback((_) => _cue());
  }

  @override
  void didUpdateWidget(TraviPlayer old) {
    super.didUpdateWidget(old);
    if (!_sameCues(old.cues, widget.cues)) {
      // Never during the parent's build: callbacks may set its state.
      WidgetsBinding.instance.addPostFrameCallback((_) => _cue());
    }
    if (old.active != widget.active) {
      if (widget.active) {
        _reel?.last = null;
        if (_reel != null) {
          if (!_ticker.isActive) _ticker.start();
        } else if (_plan.isEmpty && !_dissolving) {
          _idle();
        }
      } else if (_ticker.isActive) {
        _ticker.stop();
      }
    }
  }

  static bool _sameCues(List<TraviCue> a, List<TraviCue> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _hold?.cancel();
    _fadeTimer?.cancel();
    _ticker.dispose();
    _reel?.dispose();
    _frame?.dispose();
    for (final codec in _prefetched.values) {
      codec.then((c) => c.dispose(), onError: (_) {});
    }
    super.dispose();
  }

  /// New cues: carry on from wherever he'll next be at rest.
  void _cue() {
    if (!mounted) return;
    _hold?.cancel();
    final reel = _reel;
    if (reel != null) {
      _replan = true;
      if (reel.loop) {
        reel.wrapUp();
      } else {
        reel.speed = 2;
      }
      return;
    }
    if (_dissolving) {
      _replan = true;
      return;
    }
    _plan = _planFrom(_pose);
    _precache();
    _next();
  }

  List<_Step> _planFrom(TraviPose from) {
    final steps = <_Step>[];
    var at = from;
    for (final (i, cue) in widget.cues.indexed) {
      if (at != cue.pose) {
        final route = _films ? traviRoute(at, cue.pose) : null;
        // A long way round would keep the traveller waiting: dissolve.
        if (cue.direct || route == null || route.length > 2) {
          steps.add(_Dissolve(cue.pose));
        } else {
          steps.addAll(route.map(_Play.new));
        }
      }
      final last = i == widget.cues.length - 1;
      steps.add(_Rest(cue.pose, last ? null : (TraviPlayer.playback ? cue.hold : Duration.zero)));
      at = cue.pose;
    }
    return steps;
  }

  void _precache() {
    for (final step in _plan) {
      if (step case _Rest(:final pose) || _Dissolve(:final pose)) {
        precacheImage(AssetImage(traviStillAsset(pose)), context);
      }
    }
    final films = [
      for (final step in _plan)
        if (step case _Play(:final film)) film,
    ];
    _prefetch(films.take(2));
  }

  /// Loads films about to play, so they start without a gap.
  void _prefetch(Iterable<TraviFilm> films) {
    if (!_films) return;
    final keep = {for (final film in films) film.asset};
    for (final asset in _prefetched.keys.where((a) => !keep.contains(a)).toList()) {
      _prefetched.remove(asset)!.then((c) => c.dispose(), onError: (_) {});
    }
    for (final asset in keep) {
      _prefetched[asset] ??= _load(asset);
    }
  }

  static Future<ui.Codec> _load(String asset) async {
    final data = await rootBundle.load(asset);
    return ui.instantiateImageCodec(data.buffer.asUint8List());
  }

  void _next() {
    if (!mounted) return;
    if (_plan.isEmpty) return _idle();
    switch (_plan.removeAt(0)) {
      case _Play(:final film):
        widget.onPose?.call(null);
        _start(film, loop: false);
      case _Dissolve(:final pose):
        widget.onPose?.call(null);
        _dissolve(pose);
      case _Rest(:final pose, :final hold):
        _pose = pose;
        widget.onPose?.call(pose);
        if (hold == null) {
          _idle();
        } else if (hold == Duration.zero) {
          _next();
        } else {
          // A hold shows the key frame itself (lettering sits on it exactly).
          _showStill(pose);
          _hold = Timer(hold, _next);
        }
    }
  }

  void _showStill(TraviPose pose) {
    if (_frame == null && _still == pose) return;
    setState(() {
      // From a film's last frame (the same picture) the swap is instant.
      _instant = _frame != null;
      _frame?.dispose();
      _frame = null;
      _still = pose;
    });
  }

  void _dissolve(TraviPose pose) {
    // The film's last frame is this key frame: swap to its still unseen,
    // then fade to the next one.
    _showStill(_pose);
    if (_reduced || !TraviPlayer.playback) {
      setState(() => _still = _pose = pose);
      return _afterMove();
    }
    _dissolving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _instant = false;
        _still = pose;
      });
      _fadeTimer = Timer(_fade, () {
        _dissolving = false;
        _pose = pose;
        _afterMove();
      });
    });
  }

  void _afterMove() {
    if (_replan) {
      _replan = false;
      _plan = _planFrom(_pose);
      _precache();
    }
    _next();
  }

  void _idle() {
    _prefetch(traviFilms.where((film) => film.from == _pose).take(3));
    final idle = traviIdles[_pose];
    if (!_films || !widget.active || idle == null) {
      if (_frame == null) _showStill(_pose);
      return;
    }
    _start(idle, loop: true);
  }

  Future<void> _start(TraviFilm film, {required bool loop}) async {
    final token = ++_token;
    ui.Codec codec;
    try {
      codec = await (_prefetched.remove(film.asset) ?? _load(film.asset));
    } catch (_) {
      // Missing or unreadable: dissolve to where the film would end.
      if (mounted && token == _token && !loop) _dissolve(film.to);
      return;
    }
    if (!mounted || token != _token) {
      codec.dispose();
      return;
    }
    _reel = _Reel(film, codec, loop: loop);
    if (_replan) {
      // Cued again while it loaded.
      if (loop) {
        _reel!.wrapUp();
      } else {
        _reel!.speed = 2;
      }
    }
    if (widget.active && !_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    final reel = _reel;
    if (reel == null) return;
    _fill(reel);
    final last = reel.last;
    reel.last = elapsed;
    if (reel.shown == 0) {
      // Hold the last picture until the film's first frame is ready (an
      // idle wrapped up before it showed anything simply ends).
      if (reel.ready.isNotEmpty) {
        _show(reel, reel.ready.removeAt(0));
      } else if (reel.exhausted && !reel.decoding) {
        _finish(reel);
      }
      return;
    }
    if (last != null) reel.clock += (elapsed - last) * reel.speed;
    final handoff = reel.film.handoff;
    if (!reel.handedOff && handoff != null && reel.clock.inMilliseconds >= handoff * 1000) {
      reel.handedOff = true;
      widget.onHandoff?.call(reel.film);
    }
    if (reel.clock < reel.due) return;
    if (reel.ready.isNotEmpty) {
      _show(reel, reel.ready.removeAt(0));
    } else if (reel.exhausted && !reel.decoding) {
      _finish(reel);
    }
  }

  void _fill(_Reel reel) {
    if (reel.decoding || reel.ready.length >= 2 || reel.exhausted) return;
    reel.decoding = true;
    reel.codec.getNextFrame().then(
      (info) {
        reel.decoding = false;
        if (_reel != reel) return info.image.dispose();
        reel
          ..ready.add(info)
          ..decoded += 1;
      },
      onError: (Object _) {
        reel.decoding = false;
        if (_reel == reel) _finish(reel);
      },
    );
  }

  void _show(_Reel reel, ui.FrameInfo info) {
    setState(() {
      _frame?.dispose();
      _frame = info.image;
      _frameBox = reel.film.box;
    });
    reel
      ..shown += 1
      ..due += info.duration;
  }

  void _finish(_Reel reel) {
    _reel = null;
    _ticker.stop();
    reel.dispose();
    if (reel.film.handoff != null && !reel.handedOff) widget.onHandoff?.call(reel.film);
    _pose = reel.film.to;
    if (reel.film.from == reel.film.to && !_replan) return _idle();
    _afterMove();
  }

  bool get _grounded {
    const off = {TraviPose.empty, TraviPose.folioFull};
    final film = _reel?.film;
    if (film != null) return !off.contains(film.from) && !off.contains(film.to);
    return !off.contains(_still);
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, box) {
        final k = box.maxWidth / traviCanvas.width;
        Rect place(TraviBox b) => Rect.fromLTWH(b.left * k, b.top * k, b.width * k, b.height * k);
        final frame = _frame;
        return Stack(
          children: [
            Positioned.fromRect(
              rect: Rect.fromLTRB(_shadow.left * k, _shadow.top * k, _shadow.right * k, _shadow.bottom * k),
              child: AnimatedOpacity(
                opacity: _grounded ? 1 : 0,
                duration: _reduced ? Duration.zero : const Duration(milliseconds: 400),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical((_shadow.width * k) / 2, (_shadow.height * k) / 2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x55442A14),
                        blurRadius: _shadow.height * k * .9,
                        spreadRadius: -_shadow.height * k * .15,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (frame != null)
              Positioned.fromRect(
                rect: place(_frameBox!),
                // The render object owns (and disposes) its clone.
                child: RawImage(image: frame.clone(), fit: BoxFit.fill, filterQuality: FilterQuality.medium),
              )
            else
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: _reduced || _instant ? Duration.zero : _fade,
                  layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
                  child: Stack(
                    key: ValueKey(_still),
                    children: [
                      if (traviStills[_still] case final still?)
                        Positioned.fromRect(
                          rect: place(still),
                          child: Image.asset(
                            traviStillAsset(_still),
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) => const SizedBox(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
