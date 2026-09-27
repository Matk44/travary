import '../../domain/domain.dart';
import 'art_catalog.dart';

/// The artwork decision for one card.
class ArtChoice {
  const ArtChoice({
    required this.kind,
    required this.theme,
    required this.variant,
    this.asset,
  });

  final BookingKind kind;
  final TripTheme theme;

  /// The image to draw, or null to draw a placeholder.
  final ArtAsset? asset;

  /// A stable number per booking. Use it for any variety that isn't an image
  /// (placeholder palettes, tag angles, stamp positions): `variant % n`.
  final int variant;
}

/// Picks artwork for bookings.
///
/// The choice is stable: the same booking always gets the same artwork, on
/// every device, until the traveller picks a different one. Neighbouring
/// cards of the same kind are nudged apart so a day never shows the same
/// picture twice in a row.
class ArtResolver {
  const ArtResolver(this.catalog);

  final ArtCatalog catalog;

  ArtChoice resolve(Booking booking, TripTheme theme) {
    final variant = stableHash(booking.id);
    final picked = catalog.byKey(booking.artKey);
    if (picked != null) {
      return ArtChoice(
        kind: booking.kind,
        theme: theme,
        variant: variant,
        asset: picked,
      );
    }
    final options = catalog.assetsFor(booking.kind, theme);
    return ArtChoice(
      kind: booking.kind,
      theme: theme,
      variant: variant,
      asset: options.isEmpty ? null : options[variant % options.length],
    );
  }

  /// Resolves a run of cards shown together, avoiding repeats side by side.
  List<ArtChoice> resolveAll(
    List<Booking> bookings,
    TripTheme Function(Booking) themeOf,
  ) {
    final choices = <ArtChoice>[];
    for (final booking in bookings) {
      final theme = themeOf(booking);
      var choice = resolve(booking, theme);
      final previous = choices.isEmpty ? null : choices.last;
      if (previous != null &&
          previous.kind == choice.kind &&
          booking.artKey == null) {
        choice = _differentFrom(previous, choice, theme);
      }
      choices.add(choice);
    }
    return choices;
  }

  ArtChoice _differentFrom(ArtChoice previous, ArtChoice choice, TripTheme theme) {
    if (choice.asset == null) {
      // previous.variant + 1 lands on a different placeholder look for any
      // number of looks greater than one.
      return ArtChoice(
        kind: choice.kind,
        theme: theme,
        variant: previous.variant + 1,
      );
    }
    if (choice.asset!.path != previous.asset?.path) return choice;
    final options = catalog.assetsFor(choice.kind, theme);
    final index = options.indexWhere((a) => a.path == previous.asset!.path);
    return ArtChoice(
      kind: choice.kind,
      theme: theme,
      variant: choice.variant,
      asset: options[(index + 1) % options.length],
    );
  }
}

/// FNV-1a: a hash that is identical on every run and platform, unlike
/// `String.hashCode`.
int stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
