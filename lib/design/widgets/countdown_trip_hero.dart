import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../logic/countdown_text.dart';
import '../art/art_catalog.dart';
import '../art/art_slots.dart';
import '../art/card_shells.dart' show FractionRect;
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';

/// Measured on the supplied rasters (docs/COUNTDOWN_HANGING_TAG_HANDOFF.md).
abstract final class CountdownGeometry {
  /// Every `common/countdown_postcard.png` is 1122 × 1402, the card and its
  /// deckled edge inside a transparent margin with its shadow.
  static const postcardAspect = 1122 / 1402;

  /// Share of the postcard's height pulled up under the heading: the top
  /// of its transparent margin.
  static const postcardRise = 0.04;

  /// `common/countdown_luggage_tag.png` is 1024 × 1536. Its card is
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

  /// `common/countdown_fact_tag.png` template: 1024 × 512, eyelet and
  /// string in the left fifth, words in [factCopy].
  static const factAspect = 1024 / 512;
  static const factCopy = FractionRect(0.24, 0.12, 0.94, 0.88);

  /// `common/countdown_button.png` template: 1536 × 460, notched ends,
  /// words in [buttonCopy].
  static const buttonAspect = 1536 / 460;
  static const buttonCopy = FractionRect(0.12, 0.16, 0.88, 0.84);
}

/// Today between trips: the next trip's destination postcard with a
/// luggage tag hung on its corner counting the days, three facts on small
/// tags, and a ticket-shaped "View trip" button.
///
/// The postcard, tag, fact tags and button are raster material (resolved
/// for the trip like every other surface); every word is live text over
/// them. The whole postcard and the button both open the trip.
class CountdownTripHero extends StatefulWidget {
  const CountdownTripHero({super.key, required this.text, required this.postcard, required this.onOpen});

  final CountdownText text;

  /// The trip's destination postcard (`TravelStore.countdownPostcardFor`).
  final ArtImageRef postcard;
  final VoidCallback onOpen;

  /// As wide as [available] allows, up to [CountdownLayout.postcardMaxWidth],
  /// and no taller than [CountdownLayout.postcardMaxHeight] of the screen,
  /// so the whole countdown fits a phone without scrolling.
  static double postcardWidth(double available, double screenHeight) => [
    available - 2 * CountdownLayout.postcardInset,
    CountdownLayout.postcardMaxWidth,
    screenHeight * CountdownLayout.postcardMaxHeight * CountdownGeometry.postcardAspect,
  ].reduce(math.min);

  @override
  State<CountdownTripHero> createState() => _CountdownTripHeroState();
}

class _CountdownTripHeroState extends State<CountdownTripHero> with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(vsync: this, duration: CountdownLayout.entryDuration);
  bool _started = false;

  static const _postcardIn = Interval(0, 0.55, curve: Curves.easeOutCubic);
  static const _tagFade = Interval(0.35, 0.55, curve: Curves.easeOut);

  /// easeOutBack swings just past the resting angle and back.
  static const _tagSettle = Interval(0.35, 1, curve: Curves.easeOutBack);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entry.value = 1;
    } else if (!_started) {
      _entry.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
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
          child: SizedBox(width: column, child: _content(text, colors, column, width)),
        );
      },
    );
  }

  Widget _content(CountdownText text, TripColors colors, double column, double width) {
    return Column(
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
        const SizedBox(height: CountdownLayout.factsGap),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TodayLayout.cardInset),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _FactTag(icon: IconSlot.calendar, color: colors.highlight, label: text.duration),
                ),
                const SizedBox(width: CountdownLayout.factSpacing),
                Expanded(
                  child: _FactTag(icon: IconSlot.navTrips, color: colors.primary, label: text.bookings),
                ),
                const SizedBox(width: CountdownLayout.factSpacing),
                Expanded(
                  child: _FactTag(icon: IconSlot.attraction, color: colors.secondary, label: text.opens),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: CountdownLayout.buttonGap),
        Center(
          child: _TicketButton(label: text.action, onPressed: widget.onOpen),
        ),
      ],
    );
  }

  /// The postcard, [width] wide and centred in [column], with the tag hung
  /// on its upper-right corner. Nothing here clips: the cord runs up and
  /// out past the postcard's edges.
  Widget _stage(double column, double width) {
    final left = (column - width) / 2;
    final height = width / CountdownGeometry.postcardAspect;
    final rise = height * CountdownGeometry.postcardRise;

    // The tag's card is a share of the postcard's width; the image
    // round it (cord and shadow) scales with it.
    final body = SurfaceSlot.countdownTag.body!;
    final tagWidth = width * CountdownLayout.tagWidth / body.width;
    final tagHeight = tagWidth / CountdownGeometry.tagAspect;
    final tagLeft = left + width * CountdownLayout.tagRight - body.right * tagWidth;
    final tagTop = -rise + width * CountdownLayout.tagTop - body.top * tagHeight;
    const eyelet = CountdownGeometry.eyelet;

    return Semantics(
      button: true,
      label: widget.text.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onOpen,
      child: GestureDetector(
        key: const ValueKey('countdown-hero'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: SizedBox(
          height: height - rise,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: left,
                top: -rise,
                width: width,
                height: height,
                child: AnimatedBuilder(
                  animation: _entry,
                  builder: (context, child) {
                    final t = _postcardIn.transform(_entry.value);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        key: const ValueKey('countdown-postcard-motion'),
                        offset: Offset(0, CountdownLayout.postcardLift * (1 - t)),
                        child: child,
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
                    final settle = _tagSettle.transform(_entry.value);
                    final degrees = CountdownLayout.tagAngleDegrees + CountdownLayout.tagSettleDegrees * (1 - settle);
                    return Opacity(
                      opacity: _tagFade.transform(_entry.value),
                      // The whole stack turns: shell and words together.
                      child: Transform.rotate(
                        key: const ValueKey('countdown-tag-swing'),
                        angle: degrees * math.pi / 180,
                        alignment: Alignment(eyelet.dx * 2 - 1, eyelet.dy * 2 - 1),
                        child: child,
                      ),
                    );
                  },
                  child: _CountdownTag(text: widget.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The luggage tag with the countdown written on it: the raster (or a
/// plain card while it's missing) with live words in its copy area.
class _CountdownTag extends StatelessWidget {
  const _CountdownTag({required this.text});

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

/// One fact under the postcard: an icon over a few words, on its tag.
class _FactTag extends StatelessWidget {
  const _FactTag({required this.icon, required this.color, required this.label});

  final IconSlot icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final chrome = TravaryChrome.of(context);
    final surface = chrome.slots.surface(SurfaceSlot.countdownFact);
    final style = TravaryText.countdownFact.copyWith(color: chrome.colors.ink);
    Widget content({required bool wrap}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SlotIcon(icon: chrome.slots.icon(icon), color: color, size: CountdownLayout.factIconSize),
        const SizedBox(height: TravarySpace.xs),
        Text(label, style: style, textAlign: TextAlign.center, maxLines: wrap ? null : 1),
      ],
    );

    // A plain paper label: the stand-in until the raster exists (it grows
    // with the text), and behind the words if the raster can't be read.
    final paper = BoxDecoration(
      color: chrome.colors.paper,
      borderRadius: BorderRadius.circular(TravaryRadius.small),
      boxShadow: const [
        BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 3)),
        BoxShadow(color: Color(0x0F000000), blurRadius: 1, offset: Offset(0, 1)),
      ],
    );
    if (surface == null) {
      return Container(
        key: const ValueKey('countdown-fact-fallback'),
        constraints: const BoxConstraints(minHeight: CountdownLayout.factMinHeight),
        padding: const EdgeInsets.symmetric(horizontal: TravarySpace.xs + 2, vertical: TravarySpace.sm),
        decoration: paper,
        child: Center(child: content(wrap: true)),
      );
    }
    const copy = CountdownGeometry.factCopy;
    return AspectRatio(
      aspectRatio: CountdownGeometry.factAspect,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          fit: StackFit.expand,
          children: [
            Image(
              key: const ValueKey('countdown-fact-raster'),
              image: artImageProvider(surface),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => DecoratedBox(decoration: paper),
            ),
            Positioned(
              left: copy.left * box.maxWidth,
              top: copy.top * box.maxHeight,
              width: copy.width * box.maxWidth,
              height: copy.height * box.maxHeight,
              child: FittedBox(fit: BoxFit.scaleDown, child: content(wrap: false)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "View trip" on a ticket: the raster when it exists, else a flat ticket
/// in the trip's primary colour with notched ends.
class _TicketButton extends StatelessWidget {
  const _TicketButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  static const _shape = _TicketBorder(notch: CountdownLayout.buttonNotch);

  @override
  Widget build(BuildContext context) {
    final chrome = TravaryChrome.of(context);
    final colors = chrome.colors;
    final surface = chrome.slots.surface(SurfaceSlot.countdownButton);
    final width = math.min(
      MediaQuery.sizeOf(context).width * CountdownLayout.buttonWidth,
      CountdownLayout.buttonMaxWidth,
    );
    Widget content({required bool wrap}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            label,
            style: TravaryText.countdownAction.copyWith(color: colors.onPrimary),
            textAlign: TextAlign.center,
            maxLines: wrap ? null : 1,
          ),
        ),
        const SizedBox(width: TravarySpace.sm),
        Icon(Icons.chevron_right_rounded, color: colors.onPrimary, size: 28),
      ],
    );

    final Widget button;
    if (surface == null) {
      button = Material(
        key: const ValueKey('countdown-button-fallback'),
        color: colors.primary,
        shape: _shape,
        elevation: 2,
        shadowColor: const Color(0x66000000),
        child: InkWell(
          customBorder: _shape,
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CountdownLayout.buttonMinHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TravarySpace.xl, vertical: TravarySpace.sm),
              child: Center(child: content(wrap: true)),
            ),
          ),
        ),
      );
    } else {
      const copy = CountdownGeometry.buttonCopy;
      button = AspectRatio(
        aspectRatio: CountdownGeometry.buttonAspect,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            fit: StackFit.expand,
            children: [
              Image(
                key: const ValueKey('countdown-button-raster'),
                image: artImageProvider(surface),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => DecoratedBox(
                  decoration: ShapeDecoration(color: colors.primary, shape: _shape),
                ),
              ),
              Positioned(
                left: copy.left * box.maxWidth,
                top: copy.top * box.maxHeight,
                width: copy.width * box.maxWidth,
                height: copy.height * box.maxHeight,
                child: FittedBox(fit: BoxFit.scaleDown, child: content(wrap: false)),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(customBorder: _shape, onTap: onPressed),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox(key: const ValueKey('countdown-view-trip'), width: width, child: button),
    );
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

/// A ticket's outline: a rounded rectangle with a half-round notch in the
/// middle of each end.
class _TicketBorder extends ShapeBorder {
  const _TicketBorder({required this.notch, this.radius = 6});

  final double notch;
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final corner = math.min(radius, rect.shortestSide / 4);
    final cut = math.min(notch, rect.height / 3);
    final ticket = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(corner)));
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(rect.left, rect.center.dy), radius: cut))
      ..addOval(Rect.fromCircle(center: Offset(rect.right, rect.center.dy), radius: cut));
    return Path.combine(PathOperation.difference, ticket, notches);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => _TicketBorder(notch: notch * t, radius: radius * t);
}
