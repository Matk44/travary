import 'package:flutter/material.dart';

import '../art/art_catalog.dart';
import '../art/art_slots.dart';
import '../art/document_stamps.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';

/// The focused trip's destination stamp beside the Documents heading, with
/// the place's name printed live on its blank label band and the date
/// postmark cancelling its left edge. Only ever the trip's own place's
/// stamp (`TravelStore.destinationStampFor`).
class DestinationStamp extends StatelessWidget {
  const DestinationStamp({super.key, required this.image, required this.place});

  final ArtImageRef image;

  /// "Orlando": printed in capitals on the label.
  final String place;

  /// The stamp's width, and how far its postmark reaches out to its left.
  static const width = DocumentStampLayout.headerStampWidth;
  static const reach = width * DocumentStampLayout.headerRing / 2;

  @override
  Widget build(BuildContext context) {
    const height = width * DestinationStampGeometry.height / DestinationStampGeometry.width;
    const ring = width * DocumentStampLayout.headerRing;
    const label = DestinationStampGeometry.label;
    final postmark = TravaryChrome.of(context).slots.surface(SurfaceSlot.documentsPostmark);
    final ringImage = ring / SurfaceSlot.documentsPostmark.body!.width;

    return Semantics(
      image: true,
      label: place,
      child: SizedBox(
        width: reach + width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: reach,
              top: 0,
              width: width,
              height: height,
              child: Image(
                key: const ValueKey('destination-stamp'),
                image: artImageProvider(image),
                fit: BoxFit.fill,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                // A damaged pack file: no stamp rather than a broken one.
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            Positioned(
              left: reach + label.left * width,
              top: label.top * height,
              width: label.width * width,
              height: label.height * height,
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  // Capitals are the label's typography; the name is as given.
                  child: Text(place.toUpperCase(), style: TravaryText.destinationLabel, maxLines: 1),
                ),
              ),
            ),
            if (postmark != null)
              Positioned.fromRect(
                rect: Rect.fromCenter(
                  center: Offset(reach + DestinationStampGeometry.body.left * width, height * 0.3),
                  width: ringImage,
                  height: ringImage,
                ),
                child: ExcludeSemantics(
                  child: Image(
                    image: artImageProvider(postmark),
                    color: TravaryColors.inkSoft.withValues(alpha: 0.7),
                    colorBlendMode: BlendMode.srcIn,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
