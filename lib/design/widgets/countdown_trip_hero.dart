import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/countdown_text.dart';
import '../../logic/travi_cameos.dart';
import '../art/art_catalog.dart';
import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'travi_clip_player.dart';

/// Measured on the supplied rasters (docs/COUNTDOWN_HANGING_TAG_HANDOFF.md).
abstract final class CountdownGeometry {
  /// Every `common/countdown_postcard.webp` is 1122 × 1402, the card and its
  /// deckled edge inside a transparent margin with its shadow.
  static const postcardAspect = 1122 / 1402;

  /// Share of the postcard's height pulled up under the heading: the top
  /// of its transparent margin.
  static const postcardRise = 0.04;

  /// Where the card itself ends inside the image (inside its transparent
  /// margin and shadow), as shares of the image's width and height: the
  /// typical value over the 30 drawn postcards (right 0.95–0.98, bottom
  /// 0.93–0.98).
  static const postcardCardRight = 0.966;
  static const postcardCardBottom = 0.96;

  /// The card's left edge, the margin mirrored.
  static const postcardCardLeft = 1 - postcardCardRight;

  /// Where the card's top edge is inside the image, as a share of its
  /// height (0.05 to 0.06 over the drawn postcards).
  static const postcardCardTop = 0.05;

  /// `common/countdown_luggage_tag.webp` is 1024 × 1536. Its card is
  /// `SurfaceSlot.countdownTag.body`.
  static const tagAspect = 1024 / 1536;

  /// The eyelet's centre, as fractions of the tag image: the tag hangs
  /// and swings from here.
  static const eyelet = Offset(0.593, 0.342);

  /// Inside the tag's card: the top share kept clear for the eyelet and
  /// cord, and the side and bottom margins round the words.
  static const copyTop = 0.22;
  static const copySide = 0.11;
  static const copyBottom = 0.06;
}

/// Today between trips: the next trip's destination postcard, as large as
/// the screen allows, with a luggage tag hung over its lower right corner
/// (about half of it below the card) counting the days. Tapping the
/// postcard opens the trip.
///
/// Each time it comes into view ([replay]) the postcard lifts in, the tag
/// is slapped onto its corner (the card gives a little under it), swings
/// left and right from its eyelet, and comes to rest. The postcard and tag
/// are raster material, resolved for the trip like every other surface;
/// every word is live text over them.
///
/// Travi hides behind the postcard's top right corner. Once the entry has
/// settled he may pop up to wave ([greet], at most once a day), and tapping
/// the tag brings him up with how he feels about the days left
/// ([reaction]); he ducks back down after each.
class CountdownTripHero extends StatefulWidget {
  const CountdownTripHero({
    super.key,
    required this.text,
    required this.postcard,
    required this.onOpen,
    this.replay,
    this.reaction,
    this.greet,
    this.notes = const [],
  });

  final CountdownText text;

  /// The trip's destination postcard (`TravelStore.countdownPostcardFor`),
  /// else the neutral one.
  final ArtImageRef postcard;
  final VoidCallback onOpen;

  /// Notifies when Today comes back into view (its tab, the app, a screen
  /// closed over it): the entry plays again.
  final Listenable? replay;

  /// Travi's reaction to a tap on the tag (`countdownReactionFor`). Without
  /// one, the tag opens the trip like the rest of the postcard.
  final TraviPeek? reaction;

  /// Asked once the entry settles: true if Travi pops up to wave.
  final Future<bool> Function()? greet;

  /// Lines under the postcard, beside the tag (the packing list, the home
  /// screen widget), each with a tap of its own.
  final List<CountdownNote> notes;

  /// As wide as [available] allows, up to [CountdownLayout.postcardMaxWidth],
  /// with the postcard and the tag hanging below it no taller than
  /// [CountdownLayout.stageMaxHeight] of the screen, so the whole countdown
  /// fits a phone without scrolling.
  static double postcardWidth(double available, double screenHeight) => [
    available - 2 * CountdownLayout.postcardInset,
    CountdownLayout.postcardMaxWidth,
    screenHeight * CountdownLayout.stageMaxHeight / _Stage(1).height,
  ].reduce(math.min);

  /// The tag's angle, in degrees clockwise, [t] of the way through the
  /// entry: coming down turned a little the other way, then a damped swing
  /// either side of its resting angle, ending exactly at rest.
  static double tagDegrees(double t) {
    const rest = CountdownLayout.tagAngleDegrees;
    if (t < _swing.begin) return rest - CountdownLayout.tagSlapTurnDegrees * (1 - _slap.transform(t));
    final x = _swing.transform(t);
    final envelope = CountdownLayout.tagSwingDegrees * math.exp(-CountdownLayout.tagSwingDamping * x);
    return rest + envelope * math.sin(2 * math.pi * CountdownLayout.tagSwingCycles * x);
  }

  // The entry's phases, as shares of [CountdownLayout.entryDuration].
  static const _postcardIn = Interval(0, 0.24, curve: Curves.easeOutCubic);

  /// The tag comes down onto the card, faster and faster, like a hand.
  static const _slap = Interval(0.24, 0.33, curve: Curves.easeInCubic);
  static const _tagAppear = Interval(0.24, 0.28);

  /// The postcard gives a little under the slap, and springs back.
  static const _thud = Interval(0.33, 0.43);
  static const _swing = Interval(0.33, 1);

  @override
  State<CountdownTripHero> createState() => _CountdownTripHeroState();
}

class _CountdownTripHeroState extends State<CountdownTripHero> with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(vsync: this, duration: CountdownLayout.entryDuration)
    ..addStatusListener(_settled);
  bool _started = false;
  bool _pressed = false;

  // Travi's peek: what he plays, and a count that starts it.
  List<TraviShot> _peek = const [];
  int _cue = 0;
  bool _peeking = false;

  @override
  void initState() {
    super.initState();
    widget.replay?.addListener(_play);
  }

  /// The entry has settled: he may wave (never with reduced motion).
  Future<void> _settled(AnimationStatus status) async {
    if (status != AnimationStatus.completed || _peeking || widget.greet == null) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (await widget.greet!() && mounted) _popUp(TraviPeek.wave);
  }

  void _react() {
    HapticFeedback.selectionClick();
    _popUp(widget.reaction!);
  }

  /// Up, a moment, and back down; a tap while he's up waits for him.
  void _popUp(TraviPeek peek) {
    if (_peeking) return;
    setState(() {
      _peeking = true;
      _peek = traviPeekScript(peek);
      _cue++;
    });
  }

  @override
  void didUpdateWidget(CountdownTripHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replay != widget.replay) {
      oldWidget.replay?.removeListener(_play);
      widget.replay?.addListener(_play);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _play();
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _entry.value = 1;
    }
  }

  /// From the start, or straight to rest with reduced motion.
  void _play() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entry.value = 1;
    } else {
      _entry.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.replay?.removeListener(_play);
    _entry.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final colors = TravaryChrome.of(context).colors;
    return LayoutBuilder(
      builder: (context, box) {
        // Wide screens centre the countdown at the postcard's widest.
        final column = math.min(box.maxWidth, CountdownLayout.postcardMaxWidth + 2 * CountdownLayout.postcardInset);
        final width = CountdownTripHero.postcardWidth(box.maxWidth, MediaQuery.sizeOf(context).height);
        return Center(
          child: SizedBox(
            width: column,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TodayLayout.headerInset,
                    TodayLayout.headerGap,
                    TodayLayout.headerInset,
                    TravarySpace.xs,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(text.heading, style: TravaryText.eyebrow.copyWith(color: colors.ink)),
                  ),
                ),
                _stage(column, width),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The postcard, [width] wide and centred in [column], with the tag hung
  /// over its lower right corner. Nothing here clips: the cord runs up and
  /// out past the postcard's edge.
  Widget _stage(double column, double width) {
    final left = (column - width) / 2;
    final stage = _Stage(width);
    final height = stage.postcardHeight;
    final rise = stage.rise;
    final tagWidth = stage.tagWidth;
    final tagHeight = stage.tagHeight;
    final tagLeft = left + stage.tagLeft;
    final tagTop = stage.tagTop;
    final travi = stage.traviSize;
    final body = SurfaceSlot.countdownTag.body!;
    const eyelet = CountdownGeometry.eyelet;
    final cardCentre = Alignment(body.left + body.right - 1, body.top + body.bottom - 1);

    final hero = Semantics(
      button: true,
      label: widget.text.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onOpen,
      child: GestureDetector(
        key: const ValueKey('countdown-hero'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        child: AnimatedScale(
          key: const ValueKey('countdown-press'),
          scale: _pressed ? CountdownLayout.pressScale : 1,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            height: stage.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Behind the postcard: it covers him below its top edge.
                Positioned(
                  left: left + stage.traviLeft,
                  top: stage.traviTop,
                  width: travi,
                  height: travi,
                  child: IgnorePointer(
                    child: TraviClipPlayer(
                      key: const ValueKey('countdown-travi'),
                      script: _peek,
                      cue: _cue,
                      onDone: () => setState(() => _peeking = false),
                    ),
                  ),
                ),
                Positioned(
                  left: left,
                  top: -rise,
                  width: width,
                  height: height,
                  child: AnimatedBuilder(
                    animation: _entry,
                    builder: (context, child) {
                      final t = CountdownTripHero._postcardIn.transform(_entry.value);
                      final give = math.sin(math.pi * CountdownTripHero._thud.transform(_entry.value));
                      final scale =
                          (CountdownLayout.postcardStartScale + (1 - CountdownLayout.postcardStartScale) * t) *
                          (1 - CountdownLayout.postcardGive * give);
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          key: const ValueKey('countdown-postcard-motion'),
                          offset: Offset(0, CountdownLayout.postcardLift * (1 - t)),
                          child: Transform.scale(scale: scale, child: child),
                        ),
                      );
                    },
                    child: Image(
                      key: const ValueKey('countdown-postcard'),
                      image: artImageProvider(widget.postcard),
                      // The whole card, deckled edge and all: never cropped.
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const _PostcardStandIn(),
                    ),
                  ),
                ),
                Positioned(
                  left: tagLeft,
                  top: tagTop,
                  width: tagWidth,
                  height: tagHeight,
                  child: AnimatedBuilder(
                    animation: _entry,
                    builder: (context, child) {
                      final value = _entry.value;
                      final slap = CountdownTripHero._slap.transform(value);
                      return Opacity(
                        opacity: CountdownTripHero._tagAppear.transform(value),
                        child: Transform.translate(
                          offset: Offset(0, -CountdownLayout.tagSlapDrop * (1 - slap)),
                          child: Transform.scale(
                            key: const ValueKey('countdown-tag-slap'),
                            scale: CountdownLayout.tagSlapScale - (CountdownLayout.tagSlapScale - 1) * slap,
                            alignment: cardCentre,
                            // The whole stack turns: shell and words together.
                            child: Transform.rotate(
                              key: const ValueKey('countdown-tag-swing'),
                              angle: CountdownTripHero.tagDegrees(value) * math.pi / 180,
                              alignment: Alignment(eyelet.dx * 2 - 1, eyelet.dy * 2 - 1),
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                    child: widget.reaction == null
                        ? CountdownLuggageTag(text: widget.text)
                        : GestureDetector(
                            key: const ValueKey('countdown-tag'),
                            behavior: HitTestBehavior.opaque,
                            onTap: _react,
                            child: CountdownLuggageTag(text: widget.text),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final notes = widget.notes;
    if (notes.isEmpty) return hero;
    // Under the card's bottom left, clear of the tag even as it swings.
    final noteLeft = left + width * CountdownGeometry.postcardCardLeft + CountdownLayout.noteInset;
    final tagCardLeft = tagLeft + body.left * tagWidth;
    final tagLean = body.height * tagHeight * math.sin(CountdownLayout.noteClearDegrees * math.pi / 180);
    final noteRight = tagCardLeft - tagLean - TravarySpace.sm;
    // Laid out in the stack (not positioned), so a note that wraps on a
    // small phone with large text makes the countdown taller rather than
    // hanging out of it.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        hero,
        Padding(
          padding: EdgeInsets.only(
            left: noteLeft,
            top: -rise + height * CountdownGeometry.postcardCardBottom + TravarySpace.sm,
          ),
          child: SizedBox(
            width: math.max(0, noteRight - noteLeft),
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _entry, curve: CountdownTripHero._postcardIn),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final note in notes) _CountdownNoteLink(note: note)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A line written under the countdown postcard (the packing list: "Packing
/// list · Start yours"), already worded. [icon] draws a Material icon where
/// the packing list has the palette's suitcase.
class CountdownNote {
  const CountdownNote({
    required this.title,
    required this.detail,
    required this.semanticLabel,
    required this.onTap,
    this.id = 'countdown-note',
    this.icon,
  });

  final String title;
  final String detail;
  final String semanticLabel;
  final VoidCallback onTap;

  /// Its widget's key suffix: notes under one postcard need different ones.
  final String id;
  final IconData? icon;
}

/// The note as a small link: a suitcase, its title in ink, its state
/// underneath with an arrow.
class _CountdownNoteLink extends StatelessWidget {
  const _CountdownNoteLink({required this.note});

  final CountdownNote note;

  @override
  Widget build(BuildContext context) {
    final chrome = TravaryChrome.of(context);
    final ink = chrome.colors.ink;
    return Semantics(
      button: true,
      label: note.semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey(note.id),
        onTap: note.onTap,
        borderRadius: BorderRadius.circular(TravaryRadius.small),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: TravarySpace.xs),
            child: Row(
              children: [
                if (note.icon case final icon?)
                  SizedBox.square(dimension: 28, child: Icon(icon, color: ink, size: 26))
                else
                  SlotIcon(icon: chrome.slots.icon(IconSlot.countdownBookings), color: ink, size: 28),
                const SizedBox(width: TravarySpace.sm),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: TravaryText.label.copyWith(color: ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text.rich(
                        TextSpan(
                          text: note.detail,
                          children: const [TextSpan(text: ' \u203A')],
                        ),
                        style: TravaryText.small.copyWith(color: ink.withValues(alpha: 0.75)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where everything sits for a postcard [width] wide, measured from the
/// stage's top left (the postcard's image starts [rise] above it, inside
/// its transparent margin).
class _Stage {
  _Stage(this.width);

  final double width;

  static final _body = SurfaceSlot.countdownTag.body!;

  double get postcardHeight => width / CountdownGeometry.postcardAspect;
  double get rise => postcardHeight * CountdownGeometry.postcardRise;

  /// The tag's image (its card is [CountdownLayout.tagWidth] of the
  /// postcard; the cord and shadow round it scale with it).
  double get tagWidth => width * CountdownLayout.tagWidth / _body.width;
  double get tagHeight => tagWidth / CountdownGeometry.tagAspect;

  /// The tag's card just past the card's right edge, and
  /// [CountdownLayout.tagBelow] of it below the card's bottom edge.
  double get tagLeft =>
      width * (CountdownGeometry.postcardCardRight + CountdownLayout.tagPastEdge) - _body.right * tagWidth;
  double get tagTop {
    final cardBottom = -rise + postcardHeight * CountdownGeometry.postcardCardBottom;
    final tagCard = _body.height * tagHeight;
    return cardBottom - tagCard * (1 - CountdownLayout.tagBelow) - _body.top * tagHeight;
  }

  /// Down to the postcard's bottom, or the tag's if it hangs lower.
  double get height => math.max(postcardHeight - rise, tagTop + tagHeight);

  /// Travi's square, behind the card's top right: he stands
  /// [CountdownLayout.traviSink] of it below the card's top edge, so the
  /// card covers where he's cut off.
  double get traviSize => width * CountdownLayout.traviWidth;
  double get traviLeft => width * CountdownLayout.traviRight - traviSize;
  double get traviTop =>
      -rise + postcardHeight * CountdownGeometry.postcardCardTop + traviSize * CountdownLayout.traviSink - traviSize;
}

/// The luggage tag with the countdown written on it: the raster (or a
/// plain card while it's missing) with live words in its copy area.
/// The countdown's luggage tag: its shell with the trip's countdown written
/// on it. Today hangs it on the postcard; onboarding hangs it on the stage.
class CountdownLuggageTag extends StatelessWidget {
  const CountdownLuggageTag({super.key, required this.text});

  final CountdownText text;

  @override
  Widget build(BuildContext context) {
    final chrome = TravaryChrome.of(context);
    final image = chrome.slots.surface(SurfaceSlot.countdownTag);
    final body = SurfaceSlot.countdownTag.body!;
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final card = Rect.fromLTRB(
          body.left * size.width,
          body.top * size.height,
          body.right * size.width,
          body.bottom * size.height,
        );
        final copy = Rect.fromLTRB(
          card.left + card.width * CountdownGeometry.copySide,
          card.top + card.height * CountdownGeometry.copyTop,
          card.right - card.width * CountdownGeometry.copySide,
          card.bottom - card.height * CountdownGeometry.copyBottom,
        );
        final standIn = Stack(
          children: [Positioned.fromRect(rect: card, child: const _TagStandIn())],
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: image == null
                  ? standIn
                  : Image(
                      key: const ValueKey('countdown-tag-raster'),
                      image: artImageProvider(image),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => standIn,
                    ),
            ),
            Positioned.fromRect(
              rect: copy,
              // Laid out at one width, then scaled to the tag: every size
              // of tag reads the same, and enlarged text still fits.
              child: FittedBox(
                child: SizedBox(
                  width: CountdownLayout.tagCopyWidth,
                  child: _TagCopy(text: text, ink: chrome.colors.ink),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TagCopy extends StatelessWidget {
  const _TagCopy({required this.text, required this.ink});

  final CountdownText text;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final eyebrow = TravaryText.tagEyebrow.copyWith(color: ink);
    Widget line(String value, TextStyle style) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(value, style: style, maxLines: 1, textAlign: TextAlign.center),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(text.eyebrow, eyebrow),
        const SizedBox(height: 6),
        line(text.days, TravaryText.tagNumber.copyWith(color: ink)),
        const SizedBox(height: 4),
        line(text.daysLabel, eyebrow),
        const SizedBox(height: 12),
        Container(height: 1.2, width: CountdownLayout.tagCopyWidth * 0.72, color: ink.withValues(alpha: 0.35)),
        const SizedBox(height: 12),
        _PlaceName(text.place, style: TravaryText.tagPlace.copyWith(color: ink)),
        const SizedBox(height: 6),
        line(text.dates, TravaryText.tagDates.copyWith(color: ink)),
      ],
    );
  }
}

/// The trip's name: on one line if it fits at a comfortable size, else on
/// two, stepping down in size until no word breaks. Never cut short: a
/// name too long even at the smallest size wraps further, and the tag
/// scales it all to fit.
class _PlaceName extends StatelessWidget {
  const _PlaceName(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double? sizeFor(int lines, double smallest) {
      for (var size = style.fontSize!; size >= smallest; size -= 1) {
        if (_fits(style.copyWith(fontSize: size), lines, scaler, direction)) return size;
      }
      return null;
    }

    final size =
        sizeFor(1, TravaryText.tagPlaceOneLineMinSize) ??
        sizeFor(2, TravaryText.tagPlaceMinSize) ??
        TravaryText.tagPlaceMinSize;
    return Text(
      text,
      style: style.copyWith(fontSize: size),
      textAlign: TextAlign.center,
    );
  }

  /// Whether [text] fits the tag in [lines] lines without breaking a word.
  bool _fits(TextStyle style, int lines, TextScaler scaler, TextDirection direction) {
    TextPainter measure(String value, {int? maxLines}) => TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: maxLines,
    )..layout(maxWidth: CountdownLayout.tagCopyWidth);

    final whole = measure(text, maxLines: lines);
    final fits = !whole.didExceedMaxLines;
    whole.dispose();
    if (!fits) return false;
    for (final word in text.split(RegExp(r'\s+'))) {
      final painter = measure(word);
      final wordFits = painter.computeLineMetrics().length <= 1;
      painter.dispose();
      if (!wordFits) return false;
    }
    return true;
  }
}

/// The postcard's plain stand-in, if its file can't be read: a cream card
/// where the picture would be.
class _PostcardStandIn extends StatelessWidget {
  const _PostcardStandIn();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      key: const ValueKey('countdown-postcard-fallback'),
      widthFactor: 0.92,
      heightFactor: 0.9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TravaryChrome.of(context).colors.paper,
          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
      ),
    );
  }
}

/// The tag's plain stand-in while its raster is missing.
class _TagStandIn extends StatelessWidget {
  const _TagStandIn();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('countdown-tag-fallback'),
      decoration: BoxDecoration(
        color: TravaryChrome.of(context).colors.paper,
        borderRadius: BorderRadius.circular(TravaryRadius.small),
        boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
    );
  }
}
