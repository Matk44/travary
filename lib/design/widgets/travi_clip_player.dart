import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../logic/onboarding_films.dart' show TraviBox;
import '../../logic/travi_cameos.dart';
import 'travi_player.dart';

/// One step of a cameo: a film played once, or a pose held.
sealed class TraviShot {
  const TraviShot();
}

class TraviPlay extends TraviShot {
  const TraviPlay(this.clip);
  final TraviClip clip;
}

/// Holds where the last film ended (its last frame is [still]'s picture);
/// without films, shows [still]. With no still and no film before it, a
/// pause with nothing showing.
class TraviHold extends TraviShot {
  const TraviHold(this.still, this.duration);
  final TraviStill? still;
  final Duration duration;
}

/// A peek reaction: up from behind the edge, a moment, and back down.
/// Without [duck] he stays up (his last frame is the pose's still).
List<TraviShot> traviPeekScript(TraviPeek peek, {bool duck = true, Duration delay = Duration.zero}) {
  final reel = traviPeeks[peek]!;
  return [
    if (delay > Duration.zero) TraviHold(null, delay),
    TraviPlay(reel.up),
    if (duck) ...[TraviHold(reel.still, traviPeekHold), TraviPlay(reel.down)] else TraviHold(reel.still, Duration.zero),
  ];
}

/// Plays a cameo's [script] (`logic/travi_cameos.dart`) on the square
/// cameo canvas, laid across its width: films once each, holds between.
/// Otherwise [rest] shows (nothing when null: he's ducked out of sight);
/// a script that ends on a hold keeps showing that pose. It plays when
/// first shown if [playOnStart], and again whenever [cue] changes;
/// [onDone] says it ended.
///
/// Reduced motion (and tests, [TraviPlayer.playback]) plays no films: the
/// holds show their stills.
class TraviClipPlayer extends StatefulWidget {
  const TraviClipPlayer({
    super.key,
    this.script = const [],
    this.cue = 0,
    this.rest,
    this.playOnStart = false,
    this.onDone,
  });

  final List<TraviShot> script;
  final int cue;
  final TraviStill? rest;
  final bool playOnStart;
  final VoidCallback? onDone;

  @override
  State<TraviClipPlayer> createState() => _TraviClipPlayerState();
}

class _TraviClipPlayerState extends State<TraviClipPlayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  ui.Image? _frame;
  TraviBox? _frameBox;
  TraviStill? _still;
  int _token = 0;
  Timer? _hold;
  final _loads = <String, Future<ui.Codec>>{};

  // The film playing: frames decoded just ahead of its clock.
  ui.Codec? _codec;
  Completer<void>? _played;
  final _ready = <ui.FrameInfo>[];
  int _decoded = 0;
  bool _decoding = false;
  Duration _clock = Duration.zero;
  Duration _due = Duration.zero;
  Duration? _last;

  bool get _films => TraviPlayer.playback && !MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    if (widget.playOnStart && widget.script.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    } else {
      _still = widget.rest;
    }
  }

  @override
  void didUpdateWidget(TraviClipPlayer old) {
    super.didUpdateWidget(old);
    if (old.cue != widget.cue && widget.script.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    } else if (old.rest != widget.rest && _token == 0) {
      setState(() => _still = widget.rest);
    }
  }

  @override
  void dispose() {
    _token = -1;
    _hold?.cancel();
    _ticker.dispose();
    _stopFilm();
    _frame?.dispose();
    for (final load in _loads.values) {
      load.then((codec) => codec.dispose(), onError: (_) {});
    }
    super.dispose();
  }

  Future<ui.Codec> _load(String asset) =>
      _loads.remove(asset) ??
      rootBundle.load(asset).then((data) => ui.instantiateImageCodec(data.buffer.asUint8List()));

  Future<void> _run() async {
    if (!mounted) return;
    final token = ++_token;
    _hold?.cancel();
    final films = _films;
    final script = widget.script;
    for (final shot in script) {
      if (shot case TraviHold(still: final still?)) precacheImage(AssetImage(still.asset), context);
    }
    if (films) {
      // Every film of the script loads up front, so they join without a gap.
      for (final shot in script) {
        if (shot case TraviPlay(:final clip)) _loads[clip.asset] ??= _load(clip.asset);
      }
    }
    for (final shot in script) {
      if (!mounted || token != _token) return;
      switch (shot) {
        case TraviPlay(:final clip):
          if (films) await _play(clip, token);
        case TraviHold(:final still, :final duration):
          if (!films || _frame == null) _show(still);
          if (duration == Duration.zero) continue;
          final held = Completer<void>();
          _hold = Timer(duration, held.complete);
          await held.future;
      }
    }
    if (!mounted || token != _token) return;
    // Ending on a hold, he stays in that pose; else he rests.
    if (script.last is! TraviHold) {
      setState(() {
        _frame?.dispose();
        _frame = null;
        _still = widget.rest;
      });
    }
    _token = 0;
    widget.onDone?.call();
  }

  void _show(TraviStill? still) {
    setState(() {
      _frame?.dispose();
      _frame = null;
      _still = still;
    });
  }

  Future<void> _play(TraviClip clip, int token) async {
    ui.Codec codec;
    try {
      codec = await _load(clip.asset);
    } catch (_) {
      return;
    }
    if (!mounted || token != _token) {
      codec.dispose();
      return;
    }
    _stopFilm();
    _codec = codec;
    _frameBox = clip.box;
    _decoded = 0;
    _clock = _due = Duration.zero;
    _last = null;
    final played = _played = Completer<void>();
    _ticker.start();
    await played.future;
  }

  void _stopFilm() {
    if (_ticker.isActive) _ticker.stop();
    for (final info in _ready) {
      info.image.dispose();
    }
    _ready.clear();
    _codec?.dispose();
    _codec = null;
    final played = _played;
    _played = null;
    if (played != null && !played.isCompleted) played.complete();
  }

  void _tick(Duration elapsed) {
    final codec = _codec;
    if (codec == null) return;
    if (!_decoding && _ready.length < 2 && _decoded < codec.frameCount) {
      _decoding = true;
      codec.getNextFrame().then(
        (info) {
          _decoding = false;
          if (_codec != codec) return info.image.dispose();
          _ready.add(info);
          _decoded += 1;
        },
        onError: (Object _) {
          _decoding = false;
          if (_codec == codec) _stopFilm();
        },
      );
    }
    final last = _last;
    _last = elapsed;
    // The clock starts with the first frame on screen.
    if (_due > Duration.zero && last != null) _clock += elapsed - last;
    if (_clock < _due) return;
    if (_ready.isNotEmpty) {
      final info = _ready.removeAt(0);
      setState(() {
        _frame?.dispose();
        _frame = info.image;
        _still = null;
      });
      _due += info.duration;
    } else if (_decoded >= codec.frameCount && !_decoding) {
      _stopFilm();
    }
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, box) {
        final k = box.maxWidth / traviCameoCanvas;
        Rect place(TraviBox b) => Rect.fromLTWH(b.left * k, b.top * k, b.width * k, b.height * k);
        final frame = _frame;
        final still = _still;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (frame != null)
              Positioned.fromRect(
                rect: place(_frameBox!),
                // The render object owns (and disposes) its clone.
                child: RawImage(image: frame.clone(), fit: BoxFit.fill, filterQuality: FilterQuality.medium),
              )
            else if (still != null)
              Positioned.fromRect(
                rect: place(still.box),
                child: Image.asset(
                  still.asset,
                  key: ValueKey('travi-still-${still.id}'),
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
          ],
        );
      },
    ),
  );
}
