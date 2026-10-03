import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../logic/card_text.dart';
import '../../logic/day_plan.dart';
import '../art/art_catalog.dart';
import '../art/art_resolver.dart';
import '../art/art_slots.dart';
import '../art/card_shells.dart' show FractionRect;
import '../art/document_stamps.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'card_parts.dart';
import 'shell_frame.dart';

/// A booking in the Documents list: a paper row with the date in a
/// postmark, the booking's scene in a perforated stamp (its kind's icon on
/// a small badge in the corner), then the title, one line of detail and a
/// chevron (or the "Show tickets" button when it has ticket files).
///
/// The stamp frame is one of three, the same for a booking every time
/// (`DocumentArt.stampFor`). The scene is drawn beneath the frame, so the
/// perforations and keyline stay crisp. Without a scene the window shows a
/// calm placeholder with the kind's icon; without a frame, a plain paper
/// mount stands in. The row is drawn in Flutter and grows with larger text.
class DocumentStampCard extends StatelessWidget {
  const DocumentStampCard({
    super.key,
    required this.text,
    required this.art,
    this.status = EntryStatus.upcoming,
    this.onTap,
    this.onShowTickets,
  });

  final CardText text;
  final ArtChoice art;
  final EntryStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onShowTickets;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final summary = text.summary;
    final radius = BorderRadius.circular(DocumentStampLayout.radius);
    final trailing = onShowTickets == null ? DocumentStampLayout.chevron : DocumentStampLayout.ticketsButton;

    return Opacity(
      opacity: status == EntryStatus.done ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(color: TravaryColors.ink.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Material(
          color: TravaryColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: TravaryColors.paperEdge.withValues(alpha: 0.9)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            focusColor: colors.highlight.withValues(alpha: 0.18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: DocumentStampLayout.rowHeight),
              child: LayoutBuilder(
                builder: (context, box) {
                  final fit = fitDocumentRow(box.maxWidth, trailing: trailing);
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: DocumentStampLayout.paddingStart,
                      end: DocumentStampLayout.paddingEnd,
                    ),
                    child: Row(
                      children: [
                        _PostmarkedStamp(text: text, art: art, fit: fit),
                        const SizedBox(width: DocumentStampLayout.stampGap),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FitTitle(
                                  text.title,
                                  key: const ValueKey('document-title'),
                                  style: TravaryText.documentTitle,
                                  minScale: DocumentStampLayout.titleMinScale,
                                  maxLines: 1,
                                ),
                                if (summary != null) ...[
                                  const SizedBox(height: DocumentStampLayout.lineGap),
                                  Text(
                                    summary,
                                    style: TravaryText.documentLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: trailing,
                          height: 48,
                          child: onShowTickets == null
                              ? const Icon(Icons.chevron_right_rounded, color: TravaryColors.ink, size: 22)
                              : IconButton(
                                  onPressed: onShowTickets,
                                  tooltip: 'Show tickets',
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.confirmation_number_outlined, color: TravaryColors.inkSoft),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How a Documents row lays out [width] points wide, with a chevron or
/// button [trailing] points wide: the scale of its postmark and stamp, and
/// whether the cancellation lines show. Full size while the text keeps
/// [DocumentStampLayout.minTextWidth]; on a narrower phone the lines go
/// first, then the art shrinks (down to [DocumentStampLayout.minArtScale]).
({double scale, bool lines}) fitDocumentRow(double width, {double trailing = DocumentStampLayout.chevron}) {
  final forText =
      width -
      DocumentStampLayout.paddingStart -
      DocumentStampLayout.paddingEnd -
      DocumentStampLayout.stampGap -
      trailing -
      DocumentStampLayout.minTextWidth;
  const art = DocumentStampLayout.ringDiameter + DocumentStampLayout.stampWidth;
  if (forText >= art + DocumentStampLayout.ringGap) return (scale: 1.0, lines: true);
  final withLines = (forText / (art + DocumentStampLayout.ringGap)).clamp(0.0, 1.0);
  if (withLines >= DocumentStampLayout.linesMinScale) return (scale: withLines, lines: true);
  return (
    scale: ((forText - DocumentStampLayout.ringGapTight) / art).clamp(DocumentStampLayout.minArtScale, 1.0),
    lines: false,
  );
}

/// The postmark (with the live date), its cancellation lines and the
/// stamp, as one group sized by [fit].
class _PostmarkedStamp extends StatelessWidget {
  const _PostmarkedStamp({required this.text, required this.art, required this.fit});

  final CardText text;
  final ArtChoice art;
  final ({double scale, bool lines}) fit;

  @override
  Widget build(BuildContext context) {
    final documents = art.documents;
    final stamp = documents.stampFor(art.variant);
    final geometry = (stamp?.design ?? StampDesign.classic).geometry;
    final ring = DocumentStampLayout.ringDiameter * fit.scale;
    final gap = fit.lines ? DocumentStampLayout.ringGap * fit.scale : DocumentStampLayout.ringGapTight;
    // The stamp's whole image, placed so its body starts after the gap.
    final imageWidth = DocumentStampLayout.stampWidth * fit.scale / geometry.body.width;
    final imageHeight = imageWidth * StampDesign.height / StampDesign.width;
    final stampLeft = ring + gap - geometry.body.left * imageWidth;
    final height = math.max(imageHeight, ring);
    final ringTop = (height - ring) / 2;
    final ringRect = Rect.fromLTWH(0, ringTop, ring, ring);
    final ink = TravaryColors.inkSoft;

    final postmark = documents.postmark;
    final lines = documents.cancelLines;
    final linesBody = SurfaceSlot.documentsCancelLines.body!;
    final linesHeight = ring * DocumentStampLayout.linesHeight / linesBody.height;
    final linesWidth = linesHeight * 4;
    final ringBody = SurfaceSlot.documentsPostmark.body!;
    final ringImage = ring / ringBody.width;

    return SizedBox(
      width: ring + gap + DocumentStampLayout.stampWidth * fit.scale,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (fit.lines && lines != null)
            Positioned(
              key: const ValueKey('document-cancel-lines'),
              left: ring / 2 + ring / 2 * DocumentStampLayout.linesStart - linesBody.left * linesWidth,
              top: height / 2 - linesHeight / 2,
              width: linesWidth,
              height: linesHeight,
              child: _Ink(image: lines, color: ink.withValues(alpha: 0.75)),
            ),
          if (postmark != null)
            Positioned.fromRect(
              rect: Rect.fromCenter(center: ringRect.center, width: ringImage, height: ringImage),
              child: _Ink(key: const ValueKey('document-postmark'), image: postmark, color: ink),
            ),
          Positioned.fromRect(
            rect: Rect.fromCenter(
              center: ringRect.center,
              width: ring * DocumentStampLayout.dateSize,
              height: ring * DocumentStampLayout.dateSize,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: text.day != null && text.month != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(text.day!, style: TravaryText.documentDay),
                          Text(text.month!, style: TravaryText.documentMonth),
                        ],
                      )
                    : Text(text.when ?? '', style: TravaryText.documentMonth),
              ),
            ),
          ),
          Positioned(
            left: stampLeft,
            top: (height - imageHeight) / 2,
            width: imageWidth,
            height: imageHeight,
            child: _Stamp(art: art, stamp: stamp, geometry: geometry, scale: fit.scale),
          ),
        ],
      ),
    );
  }
}

/// A stamp's whole image box: the scene under the window, the frame over
/// it, and the kind's badge in the window's corner.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.art, required this.stamp, required this.geometry, required this.scale});

  final ArtChoice art;
  final StampArt? stamp;
  final StampGeometry geometry;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        Rect place(FractionRect r) => Rect.fromLTRB(
          r.left * box.maxWidth,
          r.top * box.maxHeight,
          r.right * box.maxWidth,
          r.bottom * box.maxHeight,
        );
        final window = place(geometry.window);
        final badge = DocumentStampLayout.badge * scale;
        final inset = DocumentStampLayout.badgeInset * scale;
        final frame = stamp;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Without a frame, a plain paper mount (no perforations) holds
            // the picture.
            if (frame == null)
              Positioned.fromRect(
                rect: place(geometry.body),
                child: DecoratedBox(
                  key: const ValueKey('document-stamp-fallback'),
                  decoration: BoxDecoration(
                    color: TravaryColors.paper,
                    border: Border.all(color: TravaryColors.paperEdge),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Positioned.fromRect(
              rect: frame == null ? window : place(geometry.scene),
              child: ExcludeSemantics(
                child: _Window(art: art, size: window.size),
              ),
            ),
            if (frame != null)
              Positioned.fill(
                child: ExcludeSemantics(
                  child: Image(
                    key: ValueKey('document-stamp-${frame.design.name}'),
                    image: artImageProvider(frame.image),
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    // A frame that can't load leaves the picture unframed.
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Positioned(
              right: box.maxWidth - window.right + inset,
              top: window.top + inset,
              width: badge,
              height: badge,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  key: const ValueKey('document-kind-badge'),
                  decoration: BoxDecoration(
                    color: TravaryColors.paper,
                    borderRadius: BorderRadius.circular(badge * 0.22),
                    border: Border.all(color: TravaryColors.paperEdge, width: 0.8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(badge * 0.14),
                    child: KindIcon(art: art, color: TravaryColors.ink),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The stamp's window: the booking's scene cropped to fill it (a little
/// right of centre, where the scenes keep their subject), over a linen
/// backing so nothing behind the row ever shows through. Without a scene,
/// or if it can't load, a calm placeholder in the trip's colours with the
/// kind's icon.
class _Window extends StatelessWidget {
  const _Window({required this.art, required this.size});

  final ArtChoice art;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final scene = art.scene;
    if (scene == null) return _WindowPlaceholder(art: art);
    // Decoded at the size it's shown (a 3:2 scene covering a near-square
    // window is as wide as 1.5 × its height), not the full picture.
    final decodeWidth = (math.max(size.width, size.height * 1.5) * MediaQuery.devicePixelRatioOf(context)).ceil();
    return ColoredBox(
      color: TravaryColors.linen,
      child: Image(
        key: const ValueKey('document-scene'),
        image: ResizeImage.resizeIfNeeded(decodeWidth, null, artImageProvider(scene.image)),
        fit: BoxFit.cover,
        alignment: const Alignment(0.6, 0),
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => _WindowPlaceholder(art: art),
      ),
    );
  }
}

class _WindowPlaceholder extends StatelessWidget {
  const _WindowPlaceholder({required this.art});

  final ArtChoice art;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    return ColoredBox(
      key: const ValueKey('document-window-placeholder'),
      color: TravaryColors.linen,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = math.min(box.maxWidth, box.maxHeight);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // A low sun, so the window reads as a quiet scene.
              Positioned(
                left: box.maxWidth * 0.2,
                bottom: -size * 0.4,
                child: Container(
                  width: size * 0.9,
                  height: size * 0.9,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primary.withValues(alpha: 0.12)),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.25),
                child: SizedBox.square(
                  dimension: size * 0.42,
                  child: KindIcon(art: art, color: colors.primary.withValues(alpha: 0.7)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A one-colour ink picture (postmark, cancellation lines) tinted [color].
class _Ink extends StatelessWidget {
  const _Ink({super.key, required this.image, required this.color});

  final ArtImageRef image;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image(
      image: artImageProvider(image),
      color: color,
      colorBlendMode: BlendMode.srcIn,
      fit: BoxFit.fill,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    ),
  );
}
