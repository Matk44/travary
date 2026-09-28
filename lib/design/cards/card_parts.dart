import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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
