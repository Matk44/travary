import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/pricing.dart';
import '../../logic/trip_postcard_text.dart';
import '../art/art_catalog.dart';
import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'countdown_trip_hero.dart' show CountdownGeometry;
import 'fitted_place_name.dart';
import 'pass_badge.dart';

/// A coming trip on the Trips tab: its destination's landscape postcard
/// with the countdown luggage tag (the same blank tag as Today's) hung on
/// its right edge, carrying the days to go, name, dates and facts.
///
/// The postcard and tag are raster material; every word is live text.
/// The whole row is one button that opens the trip. Nothing animates: a
/// list shouldn't move as it scrolls.
class UpcomingTripPostcard extends StatelessWidget {
  const UpcomingTripPostcard({
    super.key,
    required this.text,
    required this.postcard,
    required this.onOpen,
    this.tag,
    this.variant = 0,
    this.pass,
  });

  final TripPostcardText text;
  final OfferKind? pass;

  /// The trip's landscape postcard (`TravelStore.tripPostcardFor`).
  final ArtImageRef postcard;

  /// The blank tag for the trip (`SurfaceSlot.countdownTag`); a plain card
  /// stands in while it's missing.
  final ArtImageRef? tag;

  /// Stable per trip (`stableHash` of its ID): tilts the tag a little more
  /// or less, so a list of postcards doesn't look stamped out.
  final int variant;
  final VoidCallback onOpen;

  /// Every `common/trip_postcard.webp` is 1536 × 1024: the card and its
  /// deckled edge inside a transparent margin with its shadow.
  static const postcardAspect = 1536 / 1024;

  /// The tag's angle for [variant], in degrees clockwise.
  static double tagDegrees(int variant) =>
      TripPostcardLayout.tagAngleDegrees + TripPostcardLayout.tagAngleSpread * (variant % 3 - 1);

  @override
  Widget build(BuildContext context) {
    final pixels = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final width = math.min(box.maxWidth - 2 * TripPostcardLayout.inset, TripPostcardLayout.maxWidth);
        final height = width / postcardAspect;
        final left = (box.maxWidth - width) / 2;
        // The top of the postcard's clear margin tucks under the row above.
        final rise = height * TripPostcardLayout.rise;

        // The tag's card is a share of the postcard's width; the image
        // round it (cord and shadow) scales with it.
        final body = SurfaceSlot.countdownTag.body!;
        final tagWidth = width * TripPostcardLayout.tagWidth / body.width;
        final tagHeight = tagWidth / CountdownGeometry.tagAspect;
        const eyelet = CountdownGeometry.eyelet;

        return Semantics(
          button: true,
          label:
              '${text.semanticLabel}${pass == null ? '' : ', ${pass == OfferKind.tripPass ? 'Holiday Pass' : 'Annual Pass'} active'}',
          excludeSemantics: true,
          onTap: onOpen,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: Column(
              children: [
                if (pass case final kind?)
                  Padding(
                    padding: const EdgeInsets.only(right: TravarySpace.gutter, bottom: TravarySpace.sm),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PassBadge(kind: kind),
                    ),
                  ),
                SizedBox(
                  height: height - rise,
                  child: Stack(
                    // The cord runs up and out past the postcard.
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: left,
                        top: -rise,
                        width: width,
                        height: height,
                        child: Image(
                          key: const ValueKey('trip-postcard-art'),
                          // Decoded at the size it's shown, once for every row.
                          image: ResizeImage(artImageProvider(postcard), width: (width * pixels).round()),
                          // The whole card, deckled edge and all: never cropped.
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                          errorBuilder: (context, error, stackTrace) => const _PostcardStandIn(),
                        ),
                      ),
                      Positioned(
                        left: left + width * TripPostcardLayout.tagRight - body.right * tagWidth,
                        top: -rise + width * TripPostcardLayout.tagTop - body.top * tagHeight,
                        width: tagWidth,
                        height: tagHeight,
                        // The whole stack turns, shell and words together, from
                        // the eyelet.
                        child: Transform.rotate(
                          key: const ValueKey('trip-tag-swing'),
                          angle: tagDegrees(variant) * math.pi / 180,
                          alignment: Alignment(eyelet.dx * 2 - 1, eyelet.dy * 2 - 1),
                          child: HangingTag(
                            image: tag,
                            decodeWidth: (tagWidth * pixels).round(),
                            copy: _TagCopy(text: text, ink: TravaryChrome.of(context).colors.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The blank countdown tag with words written on it: [copy], laid out at
/// [TripPostcardLayout.tagCopyWidth] and scaled as a block to the tag.
/// Hung on a coming trip's postcard (Trips) and on a trip's own (the trip
/// screen).
class HangingTag extends StatelessWidget {
  const HangingTag({super.key, required this.image, required this.decodeWidth, required this.copy});

  /// The blank tag (`SurfaceSlot.countdownTag`); a plain card stands in.
  final ArtImageRef? image;
  final int decodeWidth;
  final Widget copy;

  @override
  Widget build(BuildContext context) {
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
        // Below the eyelet and cord, inside the card's margins.
        final words = Rect.fromLTRB(
          card.left + card.width * CountdownGeometry.copySide,
          card.top + card.height * CountdownGeometry.copyTop,
          card.right - card.width * CountdownGeometry.copySide,
          card.bottom - card.height * CountdownGeometry.copyBottom,
        );
        final standIn = Stack(
          children: [Positioned.fromRect(rect: card, child: const _TagStandIn())],
        );
        final raster = image;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: raster == null
                  ? standIn
                  : Image(
                      key: const ValueKey('trip-tag-raster'),
                      image: ResizeImage(artImageProvider(raster), width: decodeWidth),
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stackTrace) => standIn,
                    ),
            ),
            Positioned.fromRect(
              rect: words,
              // The words wrap at one width, then the block scales as a
              // unit to the tag: every tag reads the same, and enlarged
              // text still fits.
              child: FittedBox(
                child: SizedBox(width: TripPostcardLayout.tagCopyWidth, child: copy),
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

  final TripPostcardText text;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    Widget line(String value, TextStyle style) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        value,
        style: style.copyWith(color: ink),
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
    final facts = TravaryText.tripTagFacts.copyWith(color: ink);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(text.days, TravaryText.tripTagNumber),
        const SizedBox(height: 2),
        line(text.daysLabel, TravaryText.tripTagLabel),
        const SizedBox(height: 9),
        Container(height: 1.2, width: TripPostcardLayout.tagCopyWidth * 0.8, color: ink.withValues(alpha: 0.35)),
        const SizedBox(height: 9),
        FittedPlaceName(
          text.place,
          style: TravaryText.tripTagPlace.copyWith(color: ink),
          width: TripPostcardLayout.tagCopyWidth,
          oneLineMinSize: TravaryText.tripTagPlaceOneLineMinSize,
          minSize: TravaryText.tripTagPlaceMinSize,
        ),
        const SizedBox(height: 4),
        line(text.dates, TravaryText.tripTagDates),
        const SizedBox(height: 10),
        // One line when it fits, else a fact per line: never split mid-fact.
        if (_fitsOnOneLine(context, text.factsLine, facts))
          Text(text.factsLine, style: facts, textAlign: TextAlign.center)
        else
          for (final fact in text.facts) Text(fact, style: facts, textAlign: TextAlign.center),
      ],
    );
  }

  static bool _fitsOnOneLine(BuildContext context, String value, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: TripPostcardLayout.tagCopyWidth);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }
}

/// The postcard's plain stand-in, if its file can't be read.
class _PostcardStandIn extends StatelessWidget {
  const _PostcardStandIn();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      key: const ValueKey('trip-postcard-fallback'),
      widthFactor: 0.95,
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
      key: const ValueKey('trip-tag-fallback'),
      decoration: BoxDecoration(
        color: TravaryChrome.of(context).colors.paper,
        borderRadius: BorderRadius.circular(TravaryRadius.small),
        boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
    );
  }
}
