import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/art_bounds.dart';
import '../art/art_catalog.dart';
import '../art/art_resolver.dart';
import '../art/art_slots.dart';
import '../kind_style.dart';

/// Draws a card's artwork: the chosen picture (bundled or from an installed
/// art pack) when there is one, otherwise a simple placeholder in the
/// card's palette. A picture that can't be loaded (a deleted or corrupt
/// pack file) shows the placeholder too.
class ArtPanel extends StatelessWidget {
  const ArtPanel({super.key, required this.art, this.format = ArtFormat.scene, this.alignment = Alignment.centerRight});

  final ArtChoice art;

  /// Which shape this spot wants. Falls back to the other if missing.
  final ArtFormat format;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final style = KindStyle.of(art.kind);
    final palette = style.palette(art.variant);
    final asset = art.preferring(format);
    if (asset == null) return ArtPlaceholder(art: art);
    // Vignettes are transparent corner prints: they sit on the card's
    // paper. Scenes fill the space.
    final isVignette = asset.format == ArtFormat.vignette;
    return ColoredBox(
      color: isVignette ? palette.background : Colors.transparent,
      child: Image(
        image: artImageProvider(asset.image),
        fit: isVignette ? BoxFit.contain : BoxFit.cover,
        alignment: isVignette ? Alignment.bottomRight : alignment,
        errorBuilder: (context, error, stackTrace) => ArtPlaceholder(art: art),
      ),
    );
  }
}

/// The image provider for a picture: bundled art from the asset bundle,
/// pack art from its installed file.
ImageProvider artImageProvider(ArtImageRef image) => switch (image) {
  BundledArtImage(:final path) => AssetImage(path),
  FileArtImage(:final path) => FileImage(File(path)),
};

/// The drawn stand-in for a missing picture: the kind's icon under a low
/// "sun", in the card's palette.
class ArtPlaceholder extends StatelessWidget {
  const ArtPlaceholder({super.key, required this.art});

  final ArtChoice art;

  @override
  Widget build(BuildContext context) {
    final style = KindStyle.of(art.kind);
    final palette = style.palette(art.variant);
    return ColoredBox(
      color: palette.background,
      child: LayoutBuilder(
        builder: (context, box) {
          final height = box.maxHeight.isFinite ? box.maxHeight : 120.0;
          final width = box.maxWidth.isFinite ? box.maxWidth : height;
          // Decorations sit in the bottom-right corner, where card text never
          // goes. On wide cards they use only the right half.
          final size = math.min(height, width > height * 1.2 ? width * 0.5 : width);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // A low "sun" so placeholders feel like a scene, not a box.
              Positioned(
                right: size * 0.1,
                bottom: -size * 0.3,
                child: Container(
                  width: size * 0.78,
                  height: size * 0.78,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: palette.accent.withValues(alpha: 0.9)),
                ),
              ),
              Positioned(
                right: size * 0.3,
                bottom: size * 0.2,
                child: Icon(style.icon, size: size * 0.3, color: palette.foreground.withValues(alpha: 0.35)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A booking kind's icon: the raster file for its kind (a pack's version
/// when one suits the trip), tinted to [color], or the kind's glyph while
/// that file is missing. Fills the space it's given.
class KindIcon extends StatelessWidget {
  const KindIcon({super.key, required this.art, required this.color});

  final ArtChoice art;
  final Color color;

  @override
  Widget build(BuildContext context) => SlotIcon(
    icon: art.icon ?? IconArt(slot: IconSlot.forKind(art.kind)),
    color: color,
  );
}

/// A resolved raster icon, tinted to [color] (icons are one-colour ink
/// prints) unless [tinted] is off for full-colour art, or its stand-in
/// glyph in [color]. Scales to fill the space it's given, or [size] when set.
class SlotIcon extends StatelessWidget {
  const SlotIcon({super.key, required this.icon, required this.color, this.size, this.tinted = true});

  final IconArt icon;
  final Color color;
  final double? size;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final image = icon.image;
    if (image != null && !tinted) {
      final picture = Image(
        image: artImageProvider(image),
        fit: BoxFit.contain,
        key: ValueKey('icon-raster-${icon.slot.key}'),
      );
      return size == null ? SizedBox.expand(child: picture) : SizedBox.square(dimension: size, child: picture);
    }
    final Widget glyph = image == null
        // Raster icons leave a margin round the ink; the glyph matches it.
        ? SizedBox.square(
            dimension: 100,
            child: Center(
              child: Icon(icon.slot.fallback, color: color, size: 58, key: ValueKey('icon-fallback-${icon.slot.key}')),
            ),
          )
        : ImageIcon(artImageProvider(image), color: color, size: 100, key: ValueKey('icon-raster-${icon.slot.key}'));
    final fitted = FittedBox(fit: BoxFit.contain, child: glyph);
    return size == null ? SizedBox.expand(child: fitted) : SizedBox.square(dimension: size, child: fitted);
  }
}

/// A transparent picture trimmed to its visible part (see
/// [ArtContentBounds]) and fitted into the space it's given, never
/// stretched, at [alignment]. For vignettes in small panels: the art fills
/// the panel instead of its empty canvas margin. Draws nothing until the
/// picture has loaded, and nothing if it can't be loaded.
class TrimmedArt extends StatefulWidget {
  const TrimmedArt({super.key, required this.image, this.alignment = Alignment.center});

  final ArtImageRef image;
  final Alignment alignment;

  @override
  State<TrimmedArt> createState() => _TrimmedArtState();
}

class _TrimmedArtState extends State<TrimmedArt> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;
  Rect? _bounds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(TrimmedArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _resolve();
  }

  void _resolve() {
    final stream = artImageProvider(widget.image).resolve(createLocalImageConfiguration(context));
    if (_stream?.key != null && stream.key == _stream?.key) return;
    _stopListening();
    _stream = stream;
    _listener = ImageStreamListener(_onImage, onError: (error, stackTrace) => _replace(null, null));
    stream.addListener(_listener!);
  }

  void _onImage(ImageInfo info, bool synchronousCall) {
    final image = info.image.clone();
    info.dispose();
    final key = widget.image;
    final known = ArtContentBounds.cached(key);
    _replace(image, known);
    if (known == null) {
      ArtContentBounds.measure(key, image).then((bounds) {
        if (mounted && identical(_image, image)) setState(() => _bounds = bounds);
      });
    }
  }

  void _replace(ui.Image? image, Rect? bounds) {
    final old = _image;
    if (!mounted) {
      image?.dispose();
      return;
    }
    setState(() {
      _image = image;
      _bounds = bounds;
    });
    old?.dispose();
  }

  void _stopListening() {
    if (_stream != null && _listener != null) _stream!.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stopListening();
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final bounds = _bounds;
    return SizedBox.expand(
      child: image == null || bounds == null
          ? null
          : CustomPaint(painter: _TrimmedPainter(image, bounds, widget.alignment)),
    );
  }
}

class _TrimmedPainter extends CustomPainter {
  _TrimmedPainter(this.image, this.bounds, this.alignment);

  final ui.Image image;
  final Rect bounds;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTRB(
      bounds.left * image.width,
      bounds.top * image.height,
      bounds.right * image.width,
      bounds.bottom * image.height,
    );
    if (source.isEmpty || size.isEmpty) return;
    final fitted = applyBoxFit(BoxFit.contain, source.size, size);
    final destination = alignment.inscribe(fitted.destination, Offset.zero & size);
    canvas.drawImageRect(image, source, destination, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(_TrimmedPainter oldDelegate) =>
      !identical(oldDelegate.image, image) || oldDelegate.bounds != bounds || oldDelegate.alignment != alignment;
}
