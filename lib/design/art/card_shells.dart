import '../../domain/domain.dart';
import '../../logic/art_pack_selection.dart';
import 'art_catalog.dart';

/// A rectangle as fractions of an image, measured from its top-left corner.
class FractionRect {
  const FractionRect(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  @override
  bool operator ==(Object other) =>
      other is FractionRect && other.left == left && other.top == top && other.right == right && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'FractionRect($left, $top, $right, $bottom)';
}

/// The complete raster objects a booking card is drawn on. Each role has a
/// shared-art name (`common/<key>.png` in a pack, or bundled with a look
/// prefix: `coastal_resort_featured_ticket.png`) and a fixed pixel size
/// every shell of that role is made at.
enum ShellRole {
  /// The featured "next up" admission ticket with its tear-off stub.
  featuredTicket('featured_ticket', 1774, 887),

  /// The hotel key card.
  roomCard('room_card', 1774, 887),

  /// A tagged reservation card whose illustration is part of the shell.
  reservationCard('reservation_card', 1983, 793),

  /// The neutral tagged reservation card: blank, so the booking's own
  /// vignette sits in its right-hand panel.
  reservationBlank('reservation_card_blank', 1983, 793);

  const ShellRole(this.key, this.width, this.height);

  final String key;
  final int width;
  final int height;

  double get aspectRatio => width / height;
}

/// What colour an icon printed on a shell's luggage tag should be.
enum TagInk {
  /// Navy ink on a light kraft or coral tag.
  dark,

  /// Paper-coloured ink on a dark dyed tag.
  light,
}

/// Where live text, buttons and icons go on a shell, as fractions of the
/// whole image (shadow and transparent margin included), measured from the
/// supplied PNGs. Nothing here is drawn: these are anchors for real text.
class ShellGeometry {
  const ShellGeometry({
    required this.body,
    required this.text,
    this.action,
    this.actionAngle = 0,
    this.actionFramed = false,
    this.stubLabel,
    this.footnote,
    this.tagIcon,
    this.tagAngle = 0,
    this.tagInk = TagInk.dark,
    this.vignette,
  });

  /// The physical card itself (for a tagged card, without the tag and
  /// twine that hang off its left edge). Cards lay out to this rectangle;
  /// shadows and the tag spill outside it.
  final FractionRect body;

  /// The calm area for the eyebrow, title and details.
  final FractionRect text;

  /// Featured tickets: the "Show tickets" button, rotated by [actionAngle]
  /// radians. [actionFramed]: the shell already prints the stamp frame, so
  /// only the words are added.
  final FractionRect? action;
  final double actionAngle;
  final bool actionFramed;

  /// Featured tickets: the stub strip between the security band and the
  /// barcode, where "ADMIT TWO" runs upwards.
  final FractionRect? stubLabel;

  /// Room cards: a small supporting line near the bottom ("CHECK-OUT IN
  /// 4 DAYS").
  final FractionRect? footnote;

  /// Tagged cards: the blank face of the luggage tag, for the category
  /// icon, tilted like the tag by [tagAngle] radians.
  final FractionRect? tagIcon;
  final double tagAngle;
  final TagInk tagInk;

  /// Blank tagged cards: the panel right of the rule, for the booking's
  /// vignette.
  final FractionRect? vignette;

  /// The geometry for a shell: measured values for each bundled file, the
  /// role's template for pack shells (which are made to the same template).
  static ShellGeometry of(ShellRole role, SharedArtRef art) =>
      (art.isBundled ? _bundled[art.fileKey] : null) ?? _templates[role]!;

  /// Every bundled shell file with measured geometry.
  static Iterable<String> get measuredFiles => _bundled.keys;

  static const _templates = <ShellRole, ShellGeometry>{
    ShellRole.featuredTicket: ShellGeometry(
      body: FractionRect(0.030, 0.120, 0.970, 0.890),
      text: FractionRect(0.090, 0.180, 0.560, 0.620),
      action: FractionRect(0.090, 0.640, 0.360, 0.800),
      stubLabel: FractionRect(0.822, 0.260, 0.868, 0.760),
    ),
    ShellRole.roomCard: ShellGeometry(
      body: FractionRect(0.035, 0.100, 0.970, 0.920),
      text: FractionRect(0.090, 0.220, 0.600, 0.700),
      footnote: FractionRect(0.090, 0.745, 0.380, 0.815),
    ),
    ShellRole.reservationCard: ShellGeometry(
      body: _reservationBody,
      text: _completeText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
      // Destination packs dye their tags (navy, green): light ink reads.
      tagInk: TagInk.light,
    ),
    ShellRole.reservationBlank: ShellGeometry(
      body: _reservationBody,
      text: _blankText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
      vignette: _blankVignette,
    ),
  };

  static const _reservationBody = FractionRect(0.104, 0.204, 0.978, 0.906);
  static const _blankText = FractionRect(0.272, 0.305, 0.815, 0.865);
  static const _completeText = FractionRect(0.272, 0.305, 0.690, 0.865);
  static const _blankVignette = FractionRect(0.838, 0.270, 0.968, 0.880);
  static const _tagIcon = FractionRect(0.117, 0.455, 0.229, 0.735);
  static const _tagAngle = -0.07;

  static const _bundled = <String, ShellGeometry>{
    // The theme-park anchor: castle ticket with a printed stamp frame.
    'featured_ticket': ShellGeometry(
      body: FractionRect(0.046, 0.130, 0.951, 0.884),
      text: FractionRect(0.100, 0.180, 0.620, 0.620),
      action: FractionRect(0.103, 0.628, 0.372, 0.792),
      actionAngle: -0.075,
      actionFramed: true,
      stubLabel: FractionRect(0.805, 0.260, 0.860, 0.760),
    ),
    'coastal_resort_featured_ticket': ShellGeometry(
      body: FractionRect(0.040, 0.123, 0.970, 0.893),
      text: FractionRect(0.090, 0.180, 0.550, 0.620),
      action: FractionRect(0.090, 0.640, 0.360, 0.800),
      stubLabel: FractionRect(0.805, 0.260, 0.865, 0.760),
    ),
    'urban_heritage_featured_ticket': ShellGeometry(
      body: FractionRect(0.025, 0.117, 0.976, 0.890),
      text: FractionRect(0.075, 0.180, 0.580, 0.620),
      action: FractionRect(0.075, 0.640, 0.345, 0.800),
      stubLabel: FractionRect(0.835, 0.260, 0.880, 0.760),
    ),
    'alpine_adventure_featured_ticket': ShellGeometry(
      body: FractionRect(0.033, 0.125, 0.968, 0.876),
      text: FractionRect(0.085, 0.180, 0.550, 0.620),
      action: FractionRect(0.085, 0.640, 0.355, 0.800),
      stubLabel: FractionRect(0.828, 0.260, 0.875, 0.760),
    ),
    'countryside_escape_featured_ticket': ShellGeometry(
      body: FractionRect(0.026, 0.121, 0.974, 0.890),
      text: FractionRect(0.075, 0.180, 0.580, 0.620),
      action: FractionRect(0.075, 0.640, 0.345, 0.800),
      stubLabel: FractionRect(0.832, 0.260, 0.870, 0.760),
    ),
    // The theme-park anchor key card prints a small palm bottom-left; the
    // footnote starts after it.
    'room_card': ShellGeometry(
      body: FractionRect(0.057, 0.114, 0.944, 0.912),
      text: FractionRect(0.110, 0.245, 0.760, 0.720),
      footnote: FractionRect(0.180, 0.745, 0.580, 0.815),
    ),
    'coastal_resort_room_card': ShellGeometry(
      body: FractionRect(0.049, 0.112, 0.965, 0.917),
      text: FractionRect(0.100, 0.220, 0.660, 0.700),
      footnote: FractionRect(0.100, 0.745, 0.340, 0.815),
    ),
    'urban_heritage_room_card': ShellGeometry(
      body: FractionRect(0.029, 0.094, 0.975, 0.927),
      text: FractionRect(0.080, 0.220, 0.600, 0.700),
      footnote: FractionRect(0.080, 0.745, 0.450, 0.815),
    ),
    'alpine_adventure_room_card': ShellGeometry(
      body: FractionRect(0.034, 0.097, 0.971, 0.931),
      text: FractionRect(0.085, 0.220, 0.620, 0.700),
      footnote: FractionRect(0.085, 0.745, 0.380, 0.815),
    ),
    'countryside_escape_room_card': ShellGeometry(
      body: FractionRect(0.029, 0.103, 0.971, 0.901),
      text: FractionRect(0.080, 0.220, 0.600, 0.700),
      footnote: FractionRect(0.080, 0.745, 0.380, 0.815),
    ),
    'reservation_card_blank': ShellGeometry(
      body: _reservationBody,
      text: _blankText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
      vignette: _blankVignette,
    ),
    'coastal_resort_reservation_card': ShellGeometry(
      body: _reservationBody,
      text: _completeText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
    ),
    'urban_heritage_reservation_card': ShellGeometry(
      body: _reservationBody,
      text: _completeText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
    ),
    'alpine_adventure_reservation_card': ShellGeometry(
      body: _reservationBody,
      text: _completeText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
      tagInk: TagInk.light,
    ),
    'countryside_escape_reservation_card': ShellGeometry(
      body: _reservationBody,
      text: _completeText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
    ),
  };
}

/// A resolved shell: the picture, its role and where things go on it.
class ShellArt {
  const ShellArt({required this.art, required this.role, required this.geometry, this.standInFor});

  final SharedArtRef art;
  final ShellRole role;
  final ShellGeometry geometry;

  /// Set when the trip's look has no shells of its own yet and another
  /// look's stand in (see [shellStandIns] and docs/ART_ASSET_GAPS.md).
  final ExperienceTheme? standInFor;

  ArtImageRef get image => art.image;

  /// Whether the shell already carries an illustration (every role but the
  /// blank reservation card). No second picture is layered on top.
  bool get isComplete => role != ShellRole.reservationBlank;
}

/// The shells for one booking's cards.
class CardShells {
  const CardShells({this.featured, this.room, this.reservation});

  static const none = CardShells();

  /// The featured "next up" ticket.
  final ShellArt? featured;

  /// The hotel key card (stays).
  final ShellArt? room;

  /// The tagged reservation card: the look's complete one, else blank.
  final ShellArt? reservation;
}

/// Looks without their own shell family borrow the nearest one until theirs
/// is made (listed in docs/ART_ASSET_GAPS.md). Only featured tickets and
/// room cards stand in: a tagged card falls back to the neutral blank shell
/// with the booking's own vignette, which always fits.
const shellStandIns = <ExperienceTheme, ExperienceTheme>{
  ExperienceTheme.classicTravel: ExperienceTheme.urbanHeritage,
  ExperienceTheme.urbanModern: ExperienceTheme.urbanHeritage,
  ExperienceTheme.outdoorAdventure: ExperienceTheme.alpine,
  ExperienceTheme.cruise: ExperienceTheme.coastalResort,
  ExperienceTheme.roadtrip: ExperienceTheme.countryside,
  ExperienceTheme.wellnessRetreat: ExperienceTheme.coastalResort,
};

/// Picks card shells for a trip, the one place shell art is chosen.
///
/// Order, per role: the trip's city, region and country packs; its look
/// (pack, then bundled `<look>_<role>`); a secondary look; then the core: a
/// classic pack, the stand-in look's bundled shell, and the unthemed
/// bundled anchor (`featured_ticket.png`, `room_card.png`). A tagged card
/// uses a complete `reservation_card` from the trip's own look or place
/// only; otherwise the neutral `reservation_card_blank` plus the booking's
/// vignette. A pack shell whose pixel size doesn't match its role's
/// template is skipped (its anchors wouldn't line up).
class ShellResolver {
  const ShellResolver(this.catalog);

  final ArtCatalog catalog;

  CardShells resolve(TripArtContext context) => CardShells(
    featured: shell(ShellRole.featuredTicket, context),
    room: shell(ShellRole.roomCard, context),
    reservation: shell(ShellRole.reservationCard, context) ?? shell(ShellRole.reservationBlank, context),
  );

  ShellArt? shell(ShellRole role, TripArtContext context) {
    final standIn = role == ShellRole.featuredTicket || role == ShellRole.roomCard
        ? shellStandIns[context.theme]
        : null;
    var ranked = context;
    SharedArtRef? art;
    while (true) {
      art = catalog.commonArt(role.key, context: ranked, fallbackThemes: [?standIn]);
      if (art == null || art.isBundled || _fitsTemplate(role, art)) break;
      // A pack shell made to another size: skip that pack for this role.
      ranked = TripArtContext(
        theme: ranked.theme,
        secondaryThemes: ranked.secondaryThemes,
        packRanks: {...ranked.packRanks}..remove(art.pack!.id),
        rankOrder: ranked.rankOrder,
      );
    }
    if (art == null) return null;
    if (role == ShellRole.reservationCard && art.isBundled && art.theme == null) {
      // An unthemed complete reservation card would be some other place's
      // illustration; the blank shell suits every booking.
      return null;
    }
    return ShellArt(
      art: art,
      role: role,
      geometry: ShellGeometry.of(role, art),
      standInFor: art.isBundled && standIn != null && art.theme == standIn ? context.theme : null,
    );
  }

  static bool _fitsTemplate(ShellRole role, SharedArtRef art) {
    final width = art.width;
    final height = art.height;
    if (width == null || height == null || height == 0) return false;
    return ((width / height) - role.aspectRatio).abs() / role.aspectRatio < 0.02;
  }
}
