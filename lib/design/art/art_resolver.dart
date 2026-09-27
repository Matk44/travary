import '../../domain/domain.dart';
import '../../logic/art_subjects.dart';
import 'art_catalog.dart';

/// The artwork decision for one card.
class ArtChoice {
  const ArtChoice({
    required this.kind,
    required this.theme,
    required this.variant,
    this.subject,
    this.scene,
    this.vignette,
  });

  final BookingKind kind;
  final TripTheme theme;

  /// What the picture shows ("pizza"), or null when nothing specific fits.
  final String? subject;

  /// The full scene (featured cards) and the corner vignette (normal cards)
  /// of the chosen picture. Either may be missing; cards fall back to the
  /// other, then to a drawn placeholder.
  final ArtAsset? scene;
  final ArtAsset? vignette;

  /// A stable number per booking. Use it for any variety that isn't an image
  /// (placeholder palettes, tag angles, stamp positions): `variant % n`.
  final int variant;

  ArtAsset? get asset => scene ?? vignette;

  ArtAsset? preferring(ArtFormat format) =>
      format == ArtFormat.scene ? (scene ?? vignette) : (vignette ?? scene);

  String? get group => asset?.group;
}

/// Picks artwork for bookings.
///
/// 1. Artwork the traveller picked.
/// 2. The booking's subject (from Smart Import, or its name's keywords):
///    same theme, then theme-free/classic, then any theme.
/// 3. A generic picture for the trip's theme, then anything for that theme.
/// 4. Generic theme-free/classic, then anything of the kind, then nothing
///    (the card draws a placeholder).
///
/// Within the best tier, the same booking always gets the same picture, and
/// neighbouring cards of the same kind are nudged apart.
class ArtResolver {
  const ArtResolver(this.catalog);

  final ArtCatalog catalog;

  ArtChoice resolve(Booking booking, TripTheme theme) {
    final variant = stableHash(booking.id);
    final subject = artSubjectFor(booking);
    final picked = booking.artKey == null ? const <ArtAsset>[] : catalog.group(booking.kind, booking.artKey!);
    final groups = picked.isNotEmpty ? [booking.artKey!] : _candidateGroups(booking.kind, theme, subject);
    final group = groups.isEmpty ? null : groups[variant % groups.length];
    return _choice(booking.kind, theme, subject, variant, group);
  }

  /// Resolves a run of cards shown together, avoiding repeats side by side.
  List<ArtChoice> resolveAll(List<Booking> bookings, TripTheme Function(Booking) themeOf) {
    final choices = <ArtChoice>[];
    for (final booking in bookings) {
      final theme = themeOf(booking);
      var choice = resolve(booking, theme);
      final previous = choices.isEmpty ? null : choices.last;
      if (previous != null && previous.kind == choice.kind && booking.artKey == null) {
        choice = _differentFrom(previous, choice, booking, theme);
      }
      choices.add(choice);
    }
    return choices;
  }

  List<String> _candidateGroups(BookingKind kind, TripTheme theme, String? subject) {
    final all = catalog.allFor(kind);
    if (all.isEmpty) return const [];
    bool themeIs(ArtAsset a) => a.theme == theme;
    bool themeFree(ArtAsset a) => a.theme == null || a.theme == TripTheme.classic;
    bool isSubject(ArtAsset a) => subject != null && a.subject == subject;
    bool isGeneric(ArtAsset a) => a.subject == genericSubject;

    final tiers = <bool Function(ArtAsset)>[
      (a) => isSubject(a) && themeIs(a),
      (a) => isSubject(a) && themeFree(a),
      isSubject,
      (a) => isGeneric(a) && themeIs(a),
      themeIs,
      (a) => isGeneric(a) && themeFree(a),
      (_) => true,
    ];
    for (final tier in tiers) {
      final groups = {for (final a in all) if (tier(a)) a.group}.toList()..sort();
      if (groups.isNotEmpty) return groups;
    }
    return const [];
  }

  ArtChoice _choice(BookingKind kind, TripTheme theme, String? subject, int variant, String? group) {
    final assets = group == null ? const <ArtAsset>[] : catalog.group(kind, group);
    ArtAsset? scene;
    ArtAsset? vignette;
    for (final asset in assets) {
      if (asset.format == ArtFormat.vignette) {
        vignette = asset;
      } else if (asset.format == ArtFormat.scene) {
        scene = asset;
      } else {
        scene ??= asset;
        vignette ??= asset;
      }
    }
    return ArtChoice(
      kind: kind,
      theme: theme,
      subject: subject,
      variant: variant,
      scene: scene,
      vignette: vignette,
    );
  }

  ArtChoice _differentFrom(ArtChoice previous, ArtChoice choice, Booking booking, TripTheme theme) {
    if (choice.asset == null) {
      // previous.variant + 1 lands on a different placeholder look for any
      // number of looks greater than one.
      return ArtChoice(kind: choice.kind, theme: theme, subject: choice.subject, variant: previous.variant + 1);
    }
    if (choice.group != previous.group) return choice;
    final groups = _candidateGroups(booking.kind, theme, choice.subject);
    if (groups.length < 2) return choice;
    final next = groups[(groups.indexOf(choice.group!) + 1) % groups.length];
    return _choice(booking.kind, theme, choice.subject, choice.variant, next);
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
