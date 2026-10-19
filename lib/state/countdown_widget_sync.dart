import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../data/countdown_widget_art.dart';
import '../data/countdown_widget_bridge.dart';
import '../design/art/art_catalog.dart';
import '../design/art/art_slots.dart';
import '../logic/countdown_widget.dart';
import '../logic/travi_cameos.dart';
import '../logic/trip_plan.dart';
import 'travel_store.dart';

/// Keeps the home-screen countdown widget in step with the trips: what it
/// shows each day ahead (`logic/countdown_widget.dart`), drawn with the
/// same postcard, tag, linen and ink as Today, and Travi's stills. Free
/// for everyone, like Today. Without a bridge (tests, web) it does
/// nothing.
///
/// Trips change in bursts and the clock ticks every minute, so it waits
/// for things to settle and only writes when what the widget would show
/// has changed.
class CountdownWidgetSync {
  CountdownWidgetSync({
    required CountdownWidgetBridge? bridge,
    required TravelStore travel,
    Future<ByteData> Function(String key)? loadAsset,
  }) : _bridge = bridge,
       _travel = travel,
       _loadAsset = loadAsset ?? rootBundle.load {
    if (bridge == null) return;
    _travel.addListener(_travelChanged);
    _travelChanged();
  }

  final CountdownWidgetBridge? _bridge;
  final TravelStore _travel;
  final Future<ByteData> Function(String key) _loadAsset;

  Timer? _settle;
  bool _disposed = false;
  Future<void>? _running;
  bool _again = false;

  /// What was last written, without the time it was written: the same
  /// trips and art write nothing.
  String? _published;

  /// The fonts the tag is written in: the app's own (Source Serif 4 and
  /// Inter, the files google_fonts downloads), so the widget reads the same.
  static const fonts = {
    'serif': 'assets/widget/fonts/widget_serif_bold.ttf',
    'sans': 'assets/widget/fonts/widget_sans_semibold.ttf',
    'sansMedium': 'assets/widget/fonts/widget_sans_medium.ttf',
  };

  /// Back in the app: the phone may be in another time zone, so the
  /// widget works out its days again on the phone's clock.
  Future<void> refresh() async {
    await publish();
    try {
      await _bridge?.reload();
    } catch (error) {
      if (kDebugMode) debugPrint('Countdown widget not reloaded: $error');
    }
  }

  void _travelChanged() {
    _settle?.cancel();
    _settle = Timer(const Duration(seconds: 2), () => unawaited(publish()));
  }

  /// Writes the widget's folder if what it shows has changed, then asks
  /// the phone to draw it again. One at a time; a change meanwhile runs
  /// once more after.
  Future<void> publish() async {
    if (_running != null) {
      _again = true;
      return _running;
    }
    _running = _publish();
    try {
      await _running;
    } finally {
      _running = null;
    }
    if (_again && !_disposed) {
      _again = false;
      await publish();
    }
  }

  Future<void> _publish() async {
    final bridge = _bridge;
    // "Preview a different time" (Design tools) isn't the phone's clock.
    if (bridge == null || _disposed || _travel.isLoading || _travel.previewNow != null) return;
    final today = _travel.today;
    final plans = _travel.plans;
    final days = countdownWidgetDays(plans, today);
    final idle = countdownWidgetIdle(plans, today);
    final shown = {for (final day in days) day.tripId, ?idle.tripId};
    final art = {
      for (final id in shown)
        if (_travel.plan(id) case final plan?) id: _artFor(plan),
    };
    final idleArt = idle.tripId == null ? _artFor(null) : art[idle.tripId] ?? _artFor(null);
    final moods = {for (final day in days) day.travi, TraviPeek.wave};

    // Cheap to work out, so the minute's tick costs nothing when nothing
    // has changed; the files are only read when it has.
    final signature = jsonEncode({
      'days': [for (final day in days) day.toJson()..['date'] = day.date.toIso()],
      'idle': idle.toJson(),
      'art': {for (final entry in art.entries) entry.key: entry.value.describe()},
      'idleArt': idleArt.describe(),
      'travi': [for (final mood in moods) mood.name],
    });
    if (signature == _published) return;

    try {
      final folder = await bridge.folder();
      if (folder == null || _disposed) return;
      final keep = <String>{};
      // [longestSide]: pictures are written no larger than the widget draws
      // them (see CountdownWidgetArtSize); fonts are copied as they are.
      Future<String?> put(String kind, ArtImageRef? image, {int? longestSide}) async {
        if (image == null) return null;
        final name = await _copy(folder, kind, image, longestSide: longestSide);
        if (name != null) keep.add(name);
        return name;
      }

      Future<CountdownWidgetArt> files(_TripArt source) async => (
        portrait: await put('art', source.portrait, longestSide: CountdownWidgetArtSize.portrait),
        landscape: await put('art', source.landscape, longestSide: CountdownWidgetArtSize.landscape),
        tag: await put('art', source.tag, longestSide: CountdownWidgetArtSize.tag),
        linen: await put('art', source.linen, longestSide: CountdownWidgetArtSize.linen),
        ink: source.ink,
        paper: source.paper,
      );

      final json = countdownWidgetJson(
        days: days,
        idle: idle,
        trips: {for (final entry in art.entries) entry.key: await files(entry.value)},
        idleArt: await files(idleArt),
        travi: {
          for (final mood in moods)
            if (await put(
                  'travi',
                  BundledArtImage(traviPeeks[mood]!.still.asset),
                  longestSide: CountdownWidgetArtSize.travi,
                )
                case final name?)
              mood: name,
        },
        fonts: {
          for (final entry in fonts.entries)
            if (await put('fonts', BundledArtImage(entry.value)) case final name?) entry.key: name,
        },
        generated: DateTime.now(),
      );
      if (_disposed) return;
      await folder.writeJson(json);
      await folder.prune(keep);
      _published = signature;
      await bridge.reload();
    } catch (error) {
      // Tried again on the next change or return to the app.
      if (kDebugMode) debugPrint('Countdown widget not written: $error');
    }
  }

  /// The art Today draws [plan]'s countdown with ([plan] null: the neutral
  /// postcards on Travary's own look). The landscape postcard is the
  /// Trips tab's; without one the medium widget crops the portrait, as a
  /// trip's own screen does.
  _TripArt _artFor(TripPlan? plan) {
    final own = plan == null ? null : _travel.countdownPostcardFor(plan);
    final landscape = plan == null ? null : _travel.tripPostcardFor(plan);
    final slots = _travel.chromeArtFor(plan);
    final palette = _travel.paletteFor(plan);
    return _TripArt(
      portrait: (own ?? _travel.neutralCountdownPostcard)?.image,
      landscape: (landscape ?? (own == null ? _travel.neutralTripPostcard : null))?.image,
      tag: slots.surface(SurfaceSlot.countdownTag),
      linen: slots.surface(SurfaceSlot.linen),
      ink: palette.ink,
      paper: palette.paper,
    );
  }

  /// Copies [image] into the widget's folder, as a PNG no longer than
  /// [longestSide] when that's given (a picture the engine can't read is
  /// copied as it is); null if it can't be read at all (the widget then
  /// draws its stand-in).
  Future<String?> _copy(CountdownWidgetFolder folder, String kind, ArtImageRef image, {int? longestSide}) async {
    try {
      final bytes = switch (image) {
        BundledArtImage(:final path) => (await _loadAsset(path)).buffer.asUint8List(),
        FileArtImage(:final path) => await File(path).readAsBytes(),
      };
      if (longestSide != null) {
        final shrunk = await shrinkForWidget(bytes, longestSide: longestSide);
        if (shrunk != null) return folder.put(kind, shrunk, extension: '.png');
      }
      return folder.put(kind, bytes, extension: p.extension(image.path).toLowerCase());
    } catch (error) {
      if (kDebugMode) debugPrint('Countdown widget: ${image.path} not copied: $error');
      return null;
    }
  }

  void dispose() {
    _disposed = true;
    _settle?.cancel();
    _travel.removeListener(_travelChanged);
  }
}

/// One trip's widget art, before it's copied.
class _TripArt {
  const _TripArt({
    required this.portrait,
    required this.landscape,
    required this.tag,
    required this.linen,
    required this.ink,
    required this.paper,
  });

  final ArtImageRef? portrait;
  final ArtImageRef? landscape;
  final ArtImageRef? tag;
  final ArtImageRef? linen;
  final int ink;
  final int paper;

  /// Which pictures, for spotting a change without reading them.
  List<Object?> describe() => [
    portrait?.toString(),
    landscape?.toString(),
    tag?.toString(),
    linen?.toString(),
    ink,
    paper,
  ];
}
