import '../../domain/domain.dart';
import '../../logic/art_pack_selection.dart';
import '../../logic/art_subjects.dart';
import 'art_catalog.dart';
import 'art_slots.dart';
import 'card_shells.dart';

/// The artwork decision for one card.
class ArtChoice {
  const ArtChoice({
    required this.kind,
    required this.theme,
    required this.variant,
    this.subject,
    this.scene,
    this.vignette,
    this.shells = CardShells.none,
    this.icon,
  });

  final BookingKind kind;
  final ExperienceTheme theme;

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

  /// The raster shells for this booking's trip: featured ticket, key card
  /// and tagged card (see `ShellResolver`).
  final CardShells shells;

  /// The kind's icon (printed on tags and compact rows).
  final IconArt? icon;

  ArtAsset? get asset => scene ?? vignette;

  ArtAsset? preferring(ArtFormat format) => format == ArtFormat.scene ? (scene ?? vignette) : (vignette ?? scene);

  /// The picture's name, for design tools.
  String? get group => asset?.group;

  /// The picture's unique key (see [ArtAsset.key]).
  String? get key => asset?.key;
}

/// Picks artwork for bookings, in this order:
///
/// 1. Artwork the traveller picked.
/// 2. The booking's subject (from Smart Import, or its name's keywords)
///    from, in turn: the city pack, region pack, country pack, the trip's
///    experience (packs and bundled art for its look), a secondary theme,
///    then the always-bundled core (theme-free and classic art).
///    An unverified destination ranks after the experience art.
/// 3. A generic picture: destination packs, then the trip's look, then a
///    secondary theme.
/// 4. A generic classic picture.
/// 5. So sparse art never regresses to placeholders: anything that suits
///    the trip, then anything bundled (or from a pack that suits the trip)
///    for the kind. Another destination's pack is never used.
/// 6. Nothing: the card draws its placeholder.
///
/// A destination pack places its pictures at its own rank (the place is
/// the point), except pictures drawn for a look the trip doesn't have. An experience pack's pictures are ranked by their own theme
/// exactly like bundled art, so bundled and downloaded pictures follow
/// identical rules. Within the best tier the same booking always gets the
/// same picture, and neighbouring cards of the same kind are nudged apart.
class ArtResolver {
  const ArtResolver(this.catalog);

  final ArtCatalog catalog;

  ArtChoice resolve(Booking booking, TripArtContext context) {
    final variant = stableHash(booking.id);
    final subject = artSubjectFor(booking);
    final picked = booking.artKey == null ? const <ArtAsset>[] : catalog.byKey(booking.kind, booking.artKey!);
    final keys = picked.isNotEmpty ? [booking.artKey!] : _candidateKeys(booking.kind, context, subject);
    final key = keys.isEmpty ? null : keys[variant % keys.length];
    return _choice(booking.kind, context, subject, variant, key);
  }

  /// Resolves a run of cards shown together, avoiding repeats side by side.
  List<ArtChoice> resolveAll(List<Booking> bookings, TripArtContext Function(Booking) contextOf) {
    final choices = <ArtChoice>[];
    for (final booking in bookings) {
      final context = contextOf(booking);
      var choice = resolve(booking, context);
      final previous = choices.isEmpty ? null : choices.last;
      if (previous != null && previous.kind == choice.kind && booking.artKey == null) {
        choice = _differentFrom(previous, choice, booking, context);
      }
      choices.add(choice);
    }
    return choices;
  }

  List<String> _candidateKeys(BookingKind kind, TripArtContext context, String? subject) {
    final all = catalog.allFor(kind);
    if (all.isEmpty) return const [];
    final looks = {context.theme, ...context.secondaryThemes};
    ArtRank? rankOf(ArtAsset a) {
      final pack = a.pack;
      if (pack == null) return context.rankOfBundledTheme(a.theme);
      final packRank = context.packRanks[pack.id];
      if (packRank == null) return null;
      if (packRank.index > ArtRank.country.index) return context.rankOfBundledTheme(a.theme);
      // A destination picture drawn for one look (a Kyoto temple for
      // historic-city trips) isn't used on a trip with another look in the
      // same place (an Okinawa beach week): a country isn't a style.
      // Pictures marked `any` suit every trip there.
      if (a.theme != null && !looks.contains(a.theme)) return null;
      return packRank;
    }

    bool suitsTrip(ArtAsset a) => a.pack == null || context.packRanks.containsKey(a.pack!.id);
    bool isGeneric(ArtAsset a) => a.subject == genericSubject;

    final tiers = <bool Function(ArtAsset)>[
      if (subject != null)
        for (final rank in context.rankOrder) (a) => a.subject == subject && rankOf(a) == rank,
      for (final rank in context.rankOrder)
        if (rank != ArtRank.core) (a) => isGeneric(a) && rankOf(a) == rank,
      (a) => isGeneric(a) && rankOf(a) == ArtRank.core,
      (a) => rankOf(a) != null,
      suitsTrip,
    ];
    for (final tier in tiers) {
      final keys = {
        for (final a in all)
          if (tier(a)) a.key,
      }.toList()..sort();
      if (keys.isNotEmpty) return keys;
    }
    return const [];
  }

  ArtChoice _choice(BookingKind kind, TripArtContext context, String? subject, int variant, String? key) {
    final assets = key == null ? const <ArtAsset>[] : catalog.byKey(kind, key);
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
      theme: context.theme,
      subject: subject,
      variant: variant,
      scene: scene,
      vignette: vignette,
      shells: ShellResolver(catalog).resolve(context),
      icon: ArtSlots(catalog, context).icon(IconSlot.forKind(kind)),
    );
  }

  ArtChoice _differentFrom(ArtChoice previous, ArtChoice choice, Booking booking, TripArtContext context) {
    if (choice.asset == null) {
      // previous.variant + 1 lands on a different placeholder look for any
      // number of looks greater than one.
      return ArtChoice(
        kind: choice.kind,
        theme: context.theme,
        subject: choice.subject,
        variant: previous.variant + 1,
        shells: choice.shells,
        icon: choice.icon,
      );
    }
    if (choice.key != previous.key) return choice;
    final keys = _candidateKeys(booking.kind, context, choice.subject);
    if (keys.length < 2) return choice;
    final next = keys[(keys.indexOf(choice.key!) + 1) % keys.length];
    return _choice(booking.kind, context, choice.subject, choice.variant, next);
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
