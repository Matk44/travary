import 'package:flutter/widgets.dart';

import '../domain/domain.dart';
import 'art/art_catalog.dart';
import 'art/art_slots.dart';

/// A trip palette's UI tokens as Flutter colours. Chrome (the selected home
/// tab, the day's time rail, focus rings, category labels) uses only these;
/// full-colour artwork is never tinted.
class TripColors {
  const TripColors({
    required this.ink,
    required this.paper,
    required this.primary,
    required this.secondary,
    required this.highlight,
    required this.onPrimary,
    required this.paletteId,
  });

  factory TripColors.of(DestinationPalette palette) => TripColors(
    ink: Color(palette.ink),
    paper: Color(palette.paper),
    primary: Color(palette.primary),
    secondary: Color(palette.secondary),
    highlight: Color(palette.highlight),
    onPrimary: Color(palette.onPrimary),
    paletteId: palette.id,
  );

  static final bundled = TripColors.of(DestinationPalette.bundled);

  final Color ink;
  final Color paper;

  /// Selected states: the raised home tab.
  final Color primary;

  /// Part of every pack's palette, but nothing draws with it at the moment:
  /// packs chose strong accents (often red) for it, too loud for the time
  /// rail, which uses [ink].
  final Color secondary;

  /// What matters now: category labels, the current stop, focus rings.
  final Color highlight;

  /// Text and icons on [primary].
  final Color onPrimary;

  final String paletteId;

  @override
  bool operator ==(Object other) =>
      other is TripColors &&
      other.ink == ink &&
      other.paper == paper &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.highlight == highlight &&
      other.onPrimary == onPrimary &&
      other.paletteId == paletteId;

  @override
  int get hashCode => Object.hash(ink, paper, primary, secondary, highlight, onPrimary, paletteId);
}

/// The focused trip's palette and interface art, for everything outside
/// the booking cards (which get theirs through `ArtChoice`). One palette
/// for the whole screen, so neighbouring elements never disagree.
class TravaryChrome extends InheritedWidget {
  const TravaryChrome({super.key, required this.colors, required this.slots, required super.child});

  final TripColors colors;
  final ArtSlots slots;

  static final _fallback = ArtSlots.bundled(const ArtCatalog.empty());

  /// The nearest chrome, or Travary's own palette with no raster art (card
  /// gallery, previews, tests).
  static ({TripColors colors, ArtSlots slots}) of(BuildContext context) {
    final chrome = context.dependOnInheritedWidgetOfExactType<TravaryChrome>();
    return chrome == null
        ? (colors: TripColors.bundled, slots: _fallback)
        : (colors: chrome.colors, slots: chrome.slots);
  }

  @override
  bool updateShouldNotify(TravaryChrome oldWidget) =>
      oldWidget.colors != colors ||
      oldWidget.slots.catalog != slots.catalog ||
      oldWidget.slots.context != slots.context;
}
