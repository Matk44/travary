import '../../domain/domain.dart';
import '../../logic/art_pack_selection.dart';
import '../../logic/art_subjects.dart';
import 'art_catalog.dart';
import 'art_slots.dart';
import 'card_shells.dart';
import 'document_stamps.dart';

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
    this.documents = DocumentArt.none,
  });

  final BookingKind kind;
  final ExperienceTheme theme;

  /// What the picture shows ("pizza"), or null when nothing specific fits.
  final String? subject;

  /// The full scene (featured cards, Documents) and the corner vignette
  /// (normal cards), each the best of its format by the same rules: usually
  /// the two halves of one picture, but where a picture comes in one format
  /// only, the other format's best stands in. Either may be missing; cards
  /// fall back to the other, then to a drawn placeholder.
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

  /// The trip's stamp frames and postmark for a Documents row; the row's
  /// own frame is `documents.stampFor(variant)`.
  final DocumentArt documents;

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
/// Scenes and vignettes are chosen separately, by the same steps, so a
/// picture drawn only as a scene (for featured cards) never leaves a
/// normal card showing a scene where its vignette goes.
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
    if (picked.isNotEmpty) return _choice(booking.kind, context, subject, variant, booking.artKey, booking.artKey);
    String? pick(ArtFormat format) {
      final keys = _candidateKeys(booking.kind, context, subject, format);
      return keys.isEmpty ? null : keys[variant % keys.length];
    }

    return _choice(booking.kind, context, subject, variant, pick(ArtFormat.scene), pick(ArtFormat.vignette));
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

  /// The best tier's keys among pictures that come in [format].
  List<String> _candidateKeys(BookingKind kind, TripArtContext context, String? subject, ArtFormat format) {
    final all = [
      for (final asset in catalog.allFor(kind))
        if (asset.format == null || asset.format == format) asset,
    ];
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

  ArtChoice _choice(
    BookingKind kind,
    TripArtContext context,
    String? subject,
    int variant,
    String? sceneKey,
    String? vignetteKey,
  ) {
    /// The picture's image in [format], or its one image for both.
    ArtAsset? find(String? key, ArtFormat format) {
      final assets = key == null ? const <ArtAsset>[] : catalog.byKey(kind, key);
      return assets.where((a) => a.format == format).firstOrNull ?? assets.where((a) => a.format == null).firstOrNull;
    }

    return ArtChoice(
      kind: kind,
      theme: context.theme,
      subject: subject,
      variant: variant,
      scene: find(sceneKey, ArtFormat.scene),
      vignette: find(vignetteKey, ArtFormat.vignette),
      shells: ShellResolver(catalog).resolve(context),
      icon: ArtSlots(catalog, context).icon(IconSlot.forKind(kind)),
      documents: ArtSlots(catalog, context).documentArt(),
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
        documents: choice.documents,
      );
    }

    /// The key for [format], moved on to the next candidate if it's the
    /// neighbour's.
    String? apart(ArtAsset? mine, ArtAsset? theirs, ArtFormat format) {
      if (mine == null || mine.key != theirs?.key) return mine?.key;
      final keys = _candidateKeys(booking.kind, context, choice.subject, format);
      if (keys.length < 2) return mine.key;
      return keys[(keys.indexOf(mine.key) + 1) % keys.length];
    }

    final sceneKey = apart(choice.scene, previous.scene, ArtFormat.scene);
    final vignetteKey = apart(choice.vignette, previous.vignette, ArtFormat.vignette);
    if (sceneKey == choice.scene?.key && vignetteKey == choice.vignette?.key) return choice;
    return _choice(booking.kind, context, choice.subject, choice.variant, sceneKey, vignetteKey);
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
