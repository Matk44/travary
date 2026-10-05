import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../logic/trip_hero_text.dart';
import '../art/art_catalog.dart';
import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'countdown_trip_hero.dart' show CountdownGeometry;
import 'fitted_place_name.dart';
import 'upcoming_trip_postcard.dart';

/// The top of a trip's own screen: its landscape postcard with the luggage
/// tag hung on its right edge, carrying the trip's name, dates and where it
/// stands ("6 days to go", "Day 3 of 20"). Laid out like a coming trip on
/// the Trips tab, so opening one feels like picking up the same card.
///
/// The picture is the place's `trip_postcard`, else Travary's neutral one,
/// else (until that's made) the picture from the trip's portrait countdown
/// postcard, cropped to landscape inside a plain paper print. Tapping the tag
/// edits the trip.
class TripHero extends StatelessWidget {
  const TripHero({super.key, required this.text, this.postcard, this.portrait, this.tag, this.onTag, this.variant = 0});

  final TripHeroText text;

  /// A landscape postcard (1536 × 1024, the card inside a transparent
  /// margin), drawn whole.
  final ArtImageRef? postcard;

  /// A portrait countdown postcard (1122 × 1402) to crop while there's no
  /// landscape one.
  final ArtImageRef? portrait;

  /// The blank tag (`SurfaceSlot.countdownTag`).
  final ArtImageRef? tag;
  final VoidCallback? onTag;

  /// Stable per trip: tilts the tag a little more or less.
  final int variant;

  /// Room above the postcard for the tag's cord, so it doesn't run into
  /// the top bar, and the tag hung a little lower than on the Trips tab.
  static const _cordRoom = 28.0;
  static const _tagTop = 0.10;

  @override
  Widget build(BuildContext context) {
    final pixels = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final width = math.min(box.maxWidth - 2 * TripPostcardLayout.inset, TripPostcardLayout.maxWidth);
        final height = width / UpcomingTripPostcard.postcardAspect;
        final left = (box.maxWidth - width) / 2;
        final body = SurfaceSlot.countdownTag.body!;
        final tagWidth = width * TripPostcardLayout.tagWidth / body.width;
        final tagHeight = tagWidth / CountdownGeometry.tagAspect;
        const eyelet = CountdownGeometry.eyelet;

        final Widget picture;
        if (postcard case final landscape?) {
          picture = Image(
            key: const ValueKey('trip-hero-postcard'),
            image: ResizeImage(artImageProvider(landscape), width: (width * pixels).round()),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) => const _PlainPrint(),
          );
        } else if (portrait case final card?) {
          picture = _CroppedPrint(image: card, decodeWidth: (width * 1.4 * pixels).round());
        } else {
          picture = const _PlainPrint();
        }

        return Semantics(
          label: text.semanticLabel,
          button: onTag != null,
          onTap: onTag,
          excludeSemantics: true,
          child: SizedBox(
            height: _cordRoom + height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: left, top: _cordRoom, width: width, height: height, child: picture),
                Positioned(
                  left: left + width * TripPostcardLayout.tagRight - body.right * tagWidth,
                  top: _cordRoom + width * _tagTop - body.top * tagHeight,
                  width: tagWidth,
                  height: tagHeight,
                  child: GestureDetector(
                    key: const ValueKey('trip-hero-tag'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onTag,
                    child: Transform.rotate(
                      angle: UpcomingTripPostcard.tagDegrees(variant) * math.pi / 180,
                      alignment: Alignment(eyelet.dx * 2 - 1, eyelet.dy * 2 - 1),
                      child: HangingTag(
                        image: tag,
                        decodeWidth: (tagWidth * pixels).round(),
                        copy: _HeroTagCopy(text: text, ink: TravaryChrome.of(context).colors.ink),
                      ),
                    ),
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

/// The trip's own tag: its name, dates, a rule, and where it stands.
class _HeroTagCopy extends StatelessWidget {
  const _HeroTagCopy({required this.text, required this.ink});

  final TripHeroText text;
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (text.place != null) ...[line(text.place!, TravaryText.tripTagLabel), const SizedBox(height: 4)],
        FittedPlaceName(
          text.title,
          style: TravaryText.tripTagPlace.copyWith(color: ink, fontSize: 26),
          width: TripPostcardLayout.tagCopyWidth,
          oneLineMinSize: TravaryText.tripTagPlaceOneLineMinSize,
          minSize: TravaryText.tripTagPlaceMinSize,
        ),
        const SizedBox(height: 6),
        line(text.dates, TravaryText.tripTagDates),
        const SizedBox(height: 12),
        Container(height: 1.2, width: TripPostcardLayout.tagCopyWidth * 0.7, color: ink.withValues(alpha: 0.35)),
        const SizedBox(height: 12),
        line(text.status, TravaryText.tripTagDates.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// The picture from a portrait countdown postcard, shown as a landscape
/// print: its middle cropped from the upper part of the scene (where the
/// landmarks are), in a plain paper border, so no deckled edge is cut.
class _CroppedPrint extends StatelessWidget {
  const _CroppedPrint({required this.image, required this.decodeWidth});

  final ArtImageRef image;
  final int decodeWidth;

  /// The share of the portrait's width shown across the print, keeping
  /// clear of its deckled edges, and how far down the crop starts.
  static const _shownWidth = 0.80;
  static const _left = 0.10;
  static const _top = 0.12;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Inside the transparent margin a postcard file would have.
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: DecoratedBox(
        key: const ValueKey('trip-hero-cropped'),
        decoration: BoxDecoration(
          color: TravaryChrome.of(context).colors.paper,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth / _shownWidth;
                final height = width / CountdownGeometry.postcardAspect;
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: -width * _left,
                      top: -height * _top,
                      width: width,
                      height: height,
                      child: Image(
                        image: ResizeImage(artImageProvider(image), width: decodeWidth),
                        fit: BoxFit.fill,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A blank paper print, when there's no picture at all.
class _PlainPrint extends StatelessWidget {
  const _PlainPrint();

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: DecoratedBox(
        key: const ValueKey('trip-hero-plain'),
        decoration: BoxDecoration(
          color: Color.lerp(colors.primary, colors.paper, 0.82),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.paper, width: 7),
          boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
      ),
    );
  }
}
